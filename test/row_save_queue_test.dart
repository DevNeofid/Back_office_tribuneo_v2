import 'dart:async';

import 'package:back_office_tribuneo_v2/domain/errors/api_exception.dart';
import 'package:back_office_tribuneo_v2/domain/errors/merchant_import_exceptions.dart';
import 'package:back_office_tribuneo_v2/domain/models/merchant_import_row_model.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/merchant_import/row_save_queue.dart';
import 'package:flutter_test/flutter_test.dart';

MerchantImportRow _row(int id,
        {int version = 3,
        String status = 'pending',
        Map<String, dynamic> fields = const {
          'name': 'Boulangerie Paul',
          'phone': '0320000000',
          'city': 'Lille',
        }}) =>
    MerchantImportRow(id: id, status: status, fields: fields, version: version);

/// Copie de [row] avec un champ modifié et la version suivante.
MerchantImportRow _withField(MerchantImportRow row, String field, dynamic value,
        {String? status}) =>
    MerchantImportRow(
      id: row.id,
      status: status ?? row.status,
      fields: {...row.fields, field: value},
      version: row.version + 1,
    );

class _FakeTimer implements Timer {
  final Duration duration;
  final void Function() callback;
  bool _cancelled = false;

  _FakeTimer(this.duration, this.callback);

  void fire() {
    if (!_cancelled) callback();
  }

  @override
  void cancel() => _cancelled = true;

  @override
  bool get isActive => !_cancelled;

  @override
  int get tick => 0;
}

/// Grille et serveur simulés autour d'une [RowSaveQueue].
class _Harness {
  /// Lignes de la grille (mises à jour par la file).
  final Map<int, MerchantImportRow> grid = {};

  /// Lignes en base. Par défaut, le serveur applique le PATCH si la version
  /// correspond, sinon répond `VERSION_CONFLICT`.
  final Map<int, MerchantImportRow> server = {};

  final List<(int, Map<String, dynamic>)> sent = [];
  final List<_FakeTimer> timers = [];
  final List<RowEdit> conflicts = [];
  final List<ApiException> rejected = [];
  final List<int> unvalidated = [];

  /// Remplace le serveur simulé (réponses manuelles, pannes…).
  Future<MerchantImportPatchResult> Function(int, Map<String, dynamic>)?
      handler;

  late final RowSaveQueue queue = RowSaveQueue(
    send: (rowId, body) {
      sent.add((rowId, Map.of(body)));
      return (handler ?? _serve)(rowId, body);
    },
    currentRow: (rowId) => grid[rowId],
    onRowsUpdated: (rows) {
      for (final row in rows) {
        grid[row.id] = row;
      }
    },
    onConflict: conflicts.add,
    onRejected: (_, error) => rejected.add(error),
    onUnvalidated: unvalidated.add,
    timerFactory: (delay, callback) {
      final _FakeTimer timer = _FakeTimer(delay, callback);
      timers.add(timer);
      return timer;
    },
  );

  void add(MerchantImportRow row) {
    grid[row.id] = row;
    server[row.id] = row;
  }

  Future<MerchantImportPatchResult> _serve(
      int rowId, Map<String, dynamic> body) async {
    final MerchantImportRow current = server[rowId]!;
    if (body['version'] != current.version) {
      throw MerchantImportConflict('conflit',
          code: 'VERSION_CONFLICT', row: current);
    }
    final MerchantImportRow updated = body.containsKey('status')
        ? MerchantImportRow(
            id: rowId,
            status: body['status'] as String,
            fields: current.fields,
            version: current.version + 1)
        : _withField(current, body['field'] as String, body['value'],
            // Modifier une ligne cochée la remet à relire.
            status: current.isValidated ? 'pending' : null);
    server[rowId] = updated;
    return MerchantImportPatchResult(row: updated);
  }
}

/// Laisse s'exécuter les `Future` en attente.
Future<void> _flush() async {
  for (int i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  group('enchaînement des versions', () {
    test('deux cellules de la même ligne partent l\'une après l\'autre',
        () async {
      final _Harness h = _Harness()..add(_row(1));
      final List<Completer<MerchantImportPatchResult>> replies = [];
      h.handler = (_, __) {
        final completer = Completer<MerchantImportPatchResult>();
        replies.add(completer);
        return completer.future;
      };

      h.queue.editField(1, 'phone', '06 12 34 56 78');
      h.queue.editField(1, 'city', 'Roubaix');
      await _flush();

      expect(h.sent, hasLength(1));
      expect(h.sent[0].$2,
          {'version': 3, 'field': 'phone', 'value': '06 12 34 56 78'});
      expect(h.queue.activeCount, 2);

      replies[0].complete(MerchantImportPatchResult(
          row: _withField(h.grid[1]!, 'phone', '0612345678')));
      await _flush();

      expect(h.sent, hasLength(2));
      expect(h.sent[1].$2, {'version': 4, 'field': 'city', 'value': 'Roubaix'});
      expect(h.grid[1]!.fields['phone'], '0612345678');

      replies[1].complete(MerchantImportPatchResult(
          row: _withField(h.grid[1]!, 'city', 'Roubaix')));
      await _flush();
      expect(h.queue.isIdle, isTrue);
      expect(h.grid[1]!.version, 5);
    });

    test('cinq modifications rapides : aucun conflit, cinq valeurs en base',
        () async {
      final _Harness h = _Harness()..add(_row(1));
      for (final field in ['name', 'phone', 'city', 'zip', 'email']) {
        h.queue.editField(1, field, 'valeur $field');
      }
      await _flush();

      expect(h.conflicts, isEmpty);
      expect(h.sent.map((s) => s.$2['version']), [3, 4, 5, 6, 7]);
      for (final field in ['name', 'phone', 'city', 'zip', 'email']) {
        expect(h.server[1]!.fields[field], 'valeur $field');
      }
      expect(h.queue.isIdle, isTrue);
    });

    test('lignes différentes en parallèle', () async {
      final _Harness h = _Harness()
        ..add(_row(1))
        ..add(_row(2));
      h.handler = (_, __) => Completer<MerchantImportPatchResult>().future;

      h.queue.editField(1, 'phone', 'a');
      h.queue.editField(2, 'phone', 'b');
      await _flush();

      expect(h.sent.map((s) => s.$1), [1, 2]);
    });

    test(
        'nouvelle saisie pendant l\'envoi : part ensuite avec la nouvelle '
        'version', () async {
      final _Harness h = _Harness()..add(_row(1));
      final List<Completer<MerchantImportPatchResult>> replies = [];
      h.handler = (_, __) {
        final completer = Completer<MerchantImportPatchResult>();
        replies.add(completer);
        return completer.future;
      };

      h.queue.editField(1, 'phone', 'a');
      await _flush();
      h.queue.editField(1, 'phone', 'b');
      expect(h.queue.pendingValue(1, 'phone'), 'b');

      replies[0].complete(
          MerchantImportPatchResult(row: _withField(h.grid[1]!, 'phone', 'a')));
      await _flush();

      expect(h.sent, hasLength(2));
      expect(h.sent[1].$2, {'version': 4, 'field': 'phone', 'value': 'b'});
    });
  });

  group('valeur inchangée', () {
    test('rien n\'est envoyé (comparaison après trim)', () async {
      final _Harness h = _Harness()..add(_row(1));
      expect(h.queue.editField(1, 'name', '  Boulangerie Paul '), isFalse);
      expect(h.queue.editField(1, 'iban', ''), isFalse);
      await _flush();
      expect(h.sent, isEmpty);
    });

    test('une cellule vidée part avec null', () async {
      final _Harness h = _Harness()..add(_row(1));
      expect(h.queue.editField(1, 'city', '   '), isTrue);
      await _flush();
      expect(h.sent.single.$2, {'version': 3, 'field': 'city', 'value': null});
    });
  });

  group('conflit de version', () {
    test('autre champ modifié ailleurs : renvoi automatique, sans message',
        () async {
      final _Harness h = _Harness()..add(_row(1));
      // Un autre poste a modifié la ville.
      h.server[1] = _withField(h.server[1]!, 'city', 'Roubaix');

      h.queue.editField(1, 'phone', '0611111111');
      await _flush();

      expect(h.sent.map((s) => s.$2['version']), [3, 4]);
      expect(h.conflicts, isEmpty);
      expect(h.server[1]!.fields['phone'], '0611111111');
      expect(h.server[1]!.fields['city'], 'Roubaix');
      expect(h.grid[1]!.version, 5);
      expect(h.queue.isIdle, isTrue);
    });

    test('même champ modifié ailleurs : valeur du serveur, pas de renvoi',
        () async {
      final _Harness h = _Harness()..add(_row(1));
      h.server[1] = _withField(h.server[1]!, 'phone', '0699999999');

      h.queue.editField(1, 'phone', '0611111111');
      await _flush();

      expect(h.sent, hasLength(1));
      expect(h.conflicts.single.field, 'phone');
      expect(h.grid[1]!.fields['phone'], '0699999999');
      expect(h.queue.hasPending(1, 'phone'), isFalse);
    });

    test('un seul renvoi automatique', () async {
      final _Harness h = _Harness()..add(_row(1));
      int calls = 0;
      h.handler = (rowId, body) async {
        calls++;
        // Le serveur change de version à chaque essai, sans toucher au champ.
        final MerchantImportRow bumped =
            _withField(h.server[1]!, 'city', 'Ville $calls');
        h.server[1] = bumped;
        throw MerchantImportConflict('conflit',
            code: 'VERSION_CONFLICT', row: bumped);
      };

      h.queue.editField(1, 'phone', '0611111111');
      await _flush();

      expect(h.sent, hasLength(2));
      expect(h.conflicts, hasLength(1));
    });
  });

  group('erreurs réseau et 5xx', () {
    test('nouveaux essais après 2 s, 5 s, 10 s, puis au clic', () async {
      final _Harness h = _Harness()..add(_row(1));
      h.handler = (_, __) async => throw MerchantImportTransientError('réseau');

      h.queue.editField(1, 'phone', '0611111111');
      await _flush();

      expect(h.sent, hasLength(1));
      expect(h.queue.failedCount, 1);
      expect(h.queue.stateOf(1, 'phone'), RowEditState.failed);
      // La saisie n'est pas perdue.
      expect(h.queue.pendingValue(1, 'phone'), '0611111111');
      expect(h.timers.single.duration, const Duration(seconds: 2));

      h.timers[0].fire();
      await _flush();
      expect(h.sent, hasLength(2));
      expect(h.timers[1].duration, const Duration(seconds: 5));

      h.timers[1].fire();
      await _flush();
      expect(h.timers[2].duration, const Duration(seconds: 10));

      h.timers[2].fire();
      await _flush();
      expect(h.sent, hasLength(4));
      // Plus de nouvel essai automatique.
      expect(h.timers, hasLength(3));
      expect(h.queue.failedCount, 1);

      // Retour du réseau, clic sur l'icône.
      h.handler = null;
      h.queue.retry(1, 'phone');
      await _flush();
      expect(h.sent, hasLength(5));
      expect(h.queue.failedCount, 0);
      expect(h.server[1]!.fields['phone'], '0611111111');
    });

    test('une erreur inattendue est aussi retentée', () async {
      final _Harness h = _Harness()..add(_row(1));
      h.handler = (_, __) async => throw Exception('tenant absent');

      h.queue.editField(1, 'phone', '0611111111');
      await _flush();

      expect(h.queue.failedCount, 1);
      expect(h.timers, hasLength(1));
    });

    test('les échecs ne bloquent pas l\'attente de fin d\'enregistrement',
        () async {
      final _Harness h = _Harness()..add(_row(1));
      h.handler = (_, __) async => throw MerchantImportTransientError('réseau');

      h.queue.editField(1, 'phone', '0611111111');
      await h.queue.waitUntilIdle();
      expect(h.queue.failedCount, 1);
    });
  });

  group('statut', () {
    test('cocher, puis modifier une cellule : la ligne est décochée', () async {
      final _Harness h = _Harness()..add(_row(1));

      h.queue.setStatus(1, MerchantImportRow.statusValidated);
      expect(h.queue.pendingStatus(1), MerchantImportRow.statusValidated);
      await _flush();
      expect(h.sent.single.$2, {'version': 3, 'status': 'validated'});
      expect(h.grid[1]!.isValidated, isTrue);
      expect(h.unvalidated, isEmpty);

      h.queue.editField(1, 'phone', '0611111111');
      await _flush();
      expect(h.grid[1]!.isPending, isTrue);
      expect(h.unvalidated, [1]);
    });

    test('ROW_HAS_ERRORS : refus remonté à la grille', () async {
      final _Harness h = _Harness()..add(_row(1));
      h.handler = (_, __) async => throw MerchantImportConflict(
            'Corrigez les anomalies de la ligne avant de la valider.',
            code: 'ROW_HAS_ERRORS',
            issues: const [
              MerchantImportIssue(
                  field: 'siret', level: 'error', message: 'SIRET invalide.')
            ],
          );

      h.queue.setStatus(1, MerchantImportRow.statusValidated);
      await _flush();

      expect(h.rejected.single.code, 'ROW_HAS_ERRORS');
      expect(h.queue.pendingStatus(1), isNull);
      expect(h.timers, isEmpty);
    });
  });

  test('waitUntilIdle attend la fin des envois', () async {
    final _Harness h = _Harness()..add(_row(1));
    final Completer<MerchantImportPatchResult> reply = Completer();
    h.handler = (_, __) => reply.future;

    h.queue.editField(1, 'phone', 'a');
    bool idle = false;
    h.queue.waitUntilIdle().then((_) => idle = true);
    await _flush();
    expect(idle, isFalse);

    reply.complete(
        MerchantImportPatchResult(row: _withField(h.grid[1]!, 'phone', 'a')));
    await _flush();
    expect(idle, isTrue);
  });
}
