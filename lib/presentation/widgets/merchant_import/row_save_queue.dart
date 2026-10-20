import 'dart:async';

import 'package:back_office_tribuneo_v2/domain/errors/api_exception.dart';
import 'package:back_office_tribuneo_v2/domain/errors/merchant_import_exceptions.dart';
import 'package:back_office_tribuneo_v2/domain/models/merchant_import_row_model.dart';

/// Envoie un `PATCH` de ligne (corps avec `version`).
typedef RowPatchSender = Future<MerchantImportPatchResult> Function(
    int rowId, Map<String, dynamic> body);

/// Crée le minuteur d'un nouvel essai (remplaçable dans les tests).
typedef RetryTimerFactory = Timer Function(
    Duration delay, void Function() callback);

enum RowEditState {
  /// En attente de son tour dans la file de la ligne.
  queued,

  /// Requête partie, réponse attendue.
  saving,

  /// Erreur réseau ou 5xx : nouvel essai automatique ou au clic.
  failed,
}

/// Une modification de cellule (ou de statut) pas encore enregistrée.
class RowEdit {
  final int rowId;

  /// Champ modifié, ou [RowSaveQueue.statusField] pour un changement de statut.
  final String field;

  /// Dernière valeur saisie : c'est elle qui part.
  dynamic value;

  /// Valeur que l'utilisateur voyait avant sa saisie. Sert à départager un
  /// conflit de version : si le serveur l'a encore, l'autre personne a touché
  /// un autre champ.
  dynamic previousValue;

  RowEditState state = RowEditState.queued;

  int _generation = 0;
  int _attempts = 0;
  bool _conflictRetried = false;
  Timer? _retryTimer;

  RowEdit._(this.rowId, this.field, this.value, this.previousValue);

  bool get isStatus => field == RowSaveQueue.statusField;

  String get _key => RowSaveQueue._keyOf(rowId, field);
}

/// File d'enregistrement des modifications de la grille d'import.
///
/// Chaque `PATCH` porte la `version` de la ligne et la réponse donne la
/// suivante : les modifications d'une même ligne partent donc l'une après
/// l'autre (une `Future` de chaînage par ligne), celles de lignes différentes
/// en parallèle. Une saisie n'est jamais perdue en silence : en cas d'erreur
/// réseau ou 5xx, la cellule passe en échec et l'envoi est retenté.
///
/// Sans dépendance à Flutter, pour être testée seule.
class RowSaveQueue {
  /// Clé d'un changement de statut (aucun champ de ligne ne porte ce nom).
  static const String statusField = '#status';

  /// Nouveaux essais automatiques après une erreur réseau ou 5xx ; au-delà, on
  /// attend un clic ([retry]).
  static const List<Duration> defaultRetryDelays = [
    Duration(seconds: 2),
    Duration(seconds: 5),
    Duration(seconds: 10),
  ];

  final RowPatchSender send;

  /// Ligne actuellement connue de la grille (sa `version` part avec le PATCH).
  final MerchantImportRow? Function(int rowId) currentRow;

  /// Lignes à remplacer dans la grille : ligne enregistrée et `related`, ou
  /// ligne serveur reçue avec un conflit.
  final void Function(List<MerchantImportRow> rows) onRowsUpdated;

  /// Une cellule modifiée par quelqu'un d'autre a été rechargée sans renvoi.
  final void Function(RowEdit edit)? onConflict;

  /// Refus définitif de l'API (anomalies, lot non modifiable…) : la
  /// modification est abandonnée.
  final void Function(RowEdit edit, ApiException error)? onRejected;

  /// Une ligne cochée a été décochée par le serveur suite à une modification
  /// de cellule.
  final void Function(int rowId)? onUnvalidated;

  /// L'état de la file a changé (compteurs, cellules en cours ou en échec).
  final void Function()? onChanged;

  final List<Duration> retryDelays;
  final RetryTimerFactory _timerFactory;

  final Map<String, RowEdit> _edits = {};
  final Map<int, Future<void>> _chains = {};
  final List<Completer<void>> _idleWaiters = [];
  bool _disposed = false;

  RowSaveQueue({
    required this.send,
    required this.currentRow,
    required this.onRowsUpdated,
    this.onConflict,
    this.onRejected,
    this.onUnvalidated,
    this.onChanged,
    this.retryDelays = defaultRetryDelays,
    RetryTimerFactory? timerFactory,
  }) : _timerFactory =
            timerFactory ?? ((delay, callback) => Timer(delay, callback));

  static String _keyOf(int rowId, String field) => '$rowId|$field';

  // ---------------------------------------------------------------------------
  // État, pour l'affichage
  // ---------------------------------------------------------------------------

  RowEdit? editOf(int rowId, String field) => _edits[_keyOf(rowId, field)];

  /// La cellule a une valeur pas encore enregistrée (à afficher à la place de
  /// celle de la ligne).
  bool hasPending(int rowId, String field) =>
      _edits.containsKey(_keyOf(rowId, field));

  dynamic pendingValue(int rowId, String field) =>
      _edits[_keyOf(rowId, field)]?.value;

  /// Statut demandé et pas encore confirmé par le serveur.
  String? pendingStatus(int rowId) =>
      _edits[_keyOf(rowId, statusField)]?.value as String?;

  RowEditState? stateOf(int rowId, String field) =>
      _edits[_keyOf(rowId, field)]?.state;

  /// Modifications en attente ou en cours d'envoi (hors échecs).
  int get activeCount =>
      _edits.values.where((edit) => edit.state != RowEditState.failed).length;

  /// Modifications en échec (nouvel essai programmé ou attendu).
  int get failedCount =>
      _edits.values.where((edit) => edit.state == RowEditState.failed).length;

  bool get isIdle => activeCount == 0;

  /// Se termine quand plus aucun envoi n'est en attente ni en cours. Les échecs
  /// ne sont pas attendus : voir [failedCount].
  Future<void> waitUntilIdle() {
    if (isIdle || _disposed) return Future.value();
    final Completer<void> completer = Completer<void>();
    _idleWaiters.add(completer);
    return completer.future;
  }

  // ---------------------------------------------------------------------------
  // Modifications
  // ---------------------------------------------------------------------------

  /// Enregistre [value] dans la cellule [field]. Rien n'est envoyé si la valeur
  /// n'a pas changé (comparaison après `trim`) : retourne alors `false`.
  bool editField(int rowId, String field, dynamic value) {
    if (value is String) {
      value = value.trim();
      if (value.isEmpty) value = null;
    }
    final MerchantImportRow? row = currentRow(rowId);
    if (row == null) return false;
    return _enqueue(rowId, field, value, row.fields[field]);
  }

  /// Coche (`validated`), décoche ou rétablit (`pending`), écarte (`rejected`).
  bool setStatus(int rowId, String status) {
    final MerchantImportRow? row = currentRow(rowId);
    if (row == null) return false;
    return _enqueue(rowId, statusField, status, row.status);
  }

  bool _enqueue(int rowId, String field, dynamic value, dynamic serverValue) {
    if (_disposed) return false;
    final String key = _keyOf(rowId, field);
    final RowEdit? existing = _edits[key];
    final dynamic displayed = existing != null ? existing.value : serverValue;
    if (MerchantImportRow.sameValue(displayed, value)) return false;

    final RowEdit edit;
    if (existing != null) {
      edit = existing
        ..value = value
        .._generation += 1;
      if (edit.state == RowEditState.failed) {
        edit._retryTimer?.cancel();
        edit._attempts = 0;
        edit.state = RowEditState.queued;
      }
    } else {
      edit = RowEdit._(rowId, field, value, serverValue);
      _edits[key] = edit;
    }
    // En cours d'envoi : la nouvelle valeur partira juste après, avec la
    // version renvoyée par le serveur.
    _schedule(edit);
    _notify();
    return true;
  }

  /// Relance tout de suite l'envoi d'une cellule en échec (clic sur l'icône).
  void retry(int rowId, String field) {
    final RowEdit? edit = _edits[_keyOf(rowId, field)];
    if (edit == null || edit.state != RowEditState.failed) return;
    edit._retryTimer?.cancel();
    edit._attempts = 0;
    edit.state = RowEditState.queued;
    _schedule(edit);
    _notify();
  }

  /// Relance tous les envois en échec.
  void retryAll() {
    for (final RowEdit edit in _edits.values.toList()) {
      retry(edit.rowId, edit.field);
    }
  }

  /// Abandonne les échecs (fermeture de la vue confirmée par l'utilisateur).
  void discardFailed() {
    _edits.removeWhere((_, edit) {
      if (edit.state != RowEditState.failed) return false;
      edit._retryTimer?.cancel();
      return true;
    });
    _notify();
  }

  void dispose() {
    _disposed = true;
    for (final RowEdit edit in _edits.values) {
      edit._retryTimer?.cancel();
    }
    _completeIdleWaiters();
  }

  // ---------------------------------------------------------------------------
  // Envoi
  // ---------------------------------------------------------------------------

  void _schedule(RowEdit edit, {bool retry = false}) {
    final int rowId = edit.rowId;
    final Future<void> previous = _chains[rowId] ?? Future<void>.value();
    late final Future<void> next;
    next = previous.then((_) => _process(edit, retry: retry)).whenComplete(() {
      if (identical(_chains[rowId], next)) _chains.remove(rowId);
    });
    _chains[rowId] = next;
  }

  Future<void> _process(RowEdit edit, {bool retry = false}) async {
    if (_disposed || !identical(_edits[edit._key], edit)) return;
    // Déjà envoyée par un maillon précédent, ou en attente de son nouvel essai.
    if (edit.state == RowEditState.saving) return;
    if (edit.state == RowEditState.failed && !retry) return;

    final MerchantImportRow? row = currentRow(edit.rowId);
    if (row == null) {
      _edits.remove(edit._key);
      _notify();
      return;
    }

    final int generation = edit._generation;
    final dynamic sentValue = edit.value;
    edit.state = RowEditState.saving;
    _notify();

    try {
      final MerchantImportPatchResult result = await send(
          edit.rowId,
          edit.isStatus
              ? {'version': row.version, 'status': sentValue}
              : {
                  'version': row.version,
                  'field': edit.field,
                  'value': sentValue
                });
      if (_disposed) return;
      onRowsUpdated([result.row, ...result.related]);
      if (!edit.isStatus && row.isValidated && result.row.isPending) {
        onUnvalidated?.call(edit.rowId);
      }
      _settle(edit, generation,
          savedValue: edit.isStatus
              ? result.row.status
              : result.row.fields[edit.field]);
    } on MerchantImportConflict catch (e) {
      if (_disposed) return;
      final MerchantImportRow? serverRow = e.row;
      if (e.code == 'VERSION_CONFLICT' && serverRow != null) {
        onRowsUpdated([serverRow]);
        final dynamic serverValue =
            edit.isStatus ? serverRow.status : serverRow.fields[edit.field];
        if (!edit._conflictRetried &&
            MerchantImportRow.sameValue(serverValue, edit.previousValue)) {
          // L'autre personne a touché un autre champ : on renvoie une fois,
          // avec la nouvelle version.
          edit._conflictRetried = true;
          edit.state = RowEditState.queued;
          await _process(edit);
          return;
        }
        _drop(edit);
        onConflict?.call(edit);
        return;
      }
      _drop(edit);
      onRejected?.call(edit, e);
    } on MerchantImportTransientError {
      _fail(edit, generation);
    } on ApiException catch (e) {
      if (_disposed) return;
      _drop(edit);
      onRejected?.call(edit, e);
    } catch (_) {
      _fail(edit, generation);
    }
  }

  /// Envoi réussi : la cellule est à jour, sauf si une nouvelle saisie est
  /// arrivée entre-temps (elle part au maillon suivant).
  void _settle(RowEdit edit, int generation, {dynamic savedValue}) {
    if (edit._generation == generation) {
      _edits.remove(edit._key);
    } else {
      edit
        ..state = RowEditState.queued
        ..previousValue = savedValue
        .._attempts = 0
        .._conflictRetried = false;
    }
    _notify();
  }

  void _drop(RowEdit edit) {
    edit._retryTimer?.cancel();
    if (identical(_edits[edit._key], edit)) _edits.remove(edit._key);
    _notify();
  }

  void _fail(RowEdit edit, int generation) {
    if (_disposed) return;
    if (edit._generation != generation) {
      // Nouvelle saisie pendant l'envoi : elle part tout de suite.
      edit.state = RowEditState.queued;
      _notify();
      return;
    }
    edit.state = RowEditState.failed;
    edit._attempts += 1;
    if (edit._attempts <= retryDelays.length) {
      edit._retryTimer = _timerFactory(retryDelays[edit._attempts - 1], () {
        if (_disposed || !identical(_edits[edit._key], edit)) return;
        _schedule(edit, retry: true);
      });
    }
    _notify();
  }

  void _notify() {
    if (_disposed) return;
    if (isIdle) _completeIdleWaiters();
    onChanged?.call();
  }

  void _completeIdleWaiters() {
    final List<Completer<void>> waiters = List.of(_idleWaiters);
    _idleWaiters.clear();
    for (final Completer<void> waiter in waiters) {
      if (!waiter.isCompleted) waiter.complete();
    }
  }
}
