import 'package:back_office_tribuneo_v2/domain/models/merchant_import_batch_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/merchant_import_row_model.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _rowJson({
  String status = 'pending',
  Map<String, dynamic>? fields,
  Map<String, dynamic>? suggested,
  Map<String, dynamic>? sources,
  List<Map<String, dynamic>> issues = const [],
}) =>
    {
      'id': 1043,
      'id_batch': 12,
      'position': 7,
      'status': status,
      'fields': fields ??
          {
            'name': 'Boulangerie Paul',
            'type': 'partner',
            'siret': '40305211102616',
            'phone': '0320000000',
            'lat': 50.63,
            'city': null,
          },
      'suggested': {
        'values': suggested ??
            {
              'name': 'Boulangerie Paul',
              'type': 'partner',
              'siret': '40305211102616',
              'phone': '03 20 00 00 00',
              'lat': '50.63',
            },
        'sources': sources ?? {'name': 'fichier', 'siret': 'fichier'},
      },
      'issues': issues,
      'id_entity_match': null,
      'id_entity_created': null,
      'error': null,
      'version': 3,
      'updated_date': '2026-10-20 10:30:41',
    };

void main() {
  group('MerchantImportRow.fromJson', () {
    test('champs, version et anomalies', () {
      final MerchantImportRow row = MerchantImportRow.fromJson(_rowJson(
        issues: [
          {
            'field': 'phone',
            'level': 'warning',
            'code': 'PHONE_MISSING',
            'message': 'Téléphone absent.'
          },
          {
            'field': null,
            'level': 'info',
            'code': 'X',
            'message': 'Ligne entière.'
          },
        ],
      ));
      expect(row.id, 1043);
      expect(row.idBatch, 12);
      expect(row.position, 7);
      expect(row.version, 3);
      expect(row.textOf('name'), 'Boulangerie Paul');
      expect(row.textOf('city'), '');
      expect(row.issues, hasLength(2));
      expect(row.issuesFor('phone').single.code, 'PHONE_MISSING');
      expect(row.issuesFor('phone').single.isWarning, isTrue);
      expect(row.issues.last.field, isNull);
    });

    test('corps incomplet : valeurs par défaut', () {
      final MerchantImportRow row = MerchantImportRow.fromJson({'id': '5'});
      expect(row.id, 5);
      expect(row.status, MerchantImportRow.statusPending);
      expect(row.fields, isEmpty);
      expect(row.issues, isEmpty);
      expect(row.hasBlockingIssue, isFalse);
    });
  });

  group('hasBlockingIssue', () {
    test('warning et info ne bloquent pas', () {
      final MerchantImportRow row =
          MerchantImportRow.fromJson(_rowJson(issues: [
        {'field': 'phone', 'level': 'warning', 'message': 'a'},
        {'field': 'email', 'level': 'info', 'message': 'b'},
      ]));
      expect(row.hasBlockingIssue, isFalse);
      expect(row.blockingIssues, isEmpty);
    });

    test('une anomalie error bloque', () {
      final MerchantImportRow row =
          MerchantImportRow.fromJson(_rowJson(issues: [
        {'field': 'siret', 'level': 'error', 'message': 'SIRET invalide.'},
        {'field': 'phone', 'level': 'warning', 'message': 'a'},
      ]));
      expect(row.hasBlockingIssue, isTrue);
      expect(row.blockingIssues.single.message, 'SIRET invalide.');
    });
  });

  group('isModified', () {
    final MerchantImportRow row = MerchantImportRow.fromJson(_rowJson());

    test('valeur identique à l\'origine', () {
      expect(row.isModified('name'), isFalse);
    });

    test('valeur normalisée différente de l\'origine', () {
      expect(row.isModified('phone'), isTrue);
    });

    test('nombre et texte de même valeur', () {
      expect(row.isModified('lat'), isFalse);
    });

    test('absent des deux côtés', () {
      expect(row.isModified('city'), isFalse);
      expect(row.isModified('iban'), isFalse);
    });
  });

  group('provenance', () {
    test('source connue ou inconnue', () {
      final MerchantImportRow row = MerchantImportRow.fromJson(_rowJson());
      expect(row.sourceOf('name'), 'fichier');
      expect(row.sourceOf('phone'), isNull);
      expect(row.isAiValue('name'), isFalse);
    });

    test('valeur de l\'IA non modifiée', () {
      final MerchantImportRow row =
          MerchantImportRow.fromJson(_rowJson(sources: {'name': 'ia'}));
      expect(row.isAiValue('name'), isTrue);
    });
  });

  test('isLocked', () {
    expect(MerchantImportRow.fromJson(_rowJson(status: 'imported')).isLocked,
        isTrue);
    expect(MerchantImportRow.fromJson(_rowJson(status: 'rejected')).isLocked,
        isTrue);
    expect(MerchantImportRow.fromJson(_rowJson(status: 'failed')).isLocked,
        isFalse);
    expect(MerchantImportRow.fromJson(_rowJson(status: 'validated')).isLocked,
        isFalse);
  });

  test('MerchantImportPatchResult : ligne et related', () {
    final MerchantImportPatchResult result =
        MerchantImportPatchResult.fromJson({
      'row': _rowJson(),
      'related': [
        {..._rowJson(), 'id': 1044, 'version': 9},
      ],
    });
    expect(result.row.id, 1043);
    expect(result.related.single.id, 1044);
    expect(result.related.single.version, 9);
  });

  group('MerchantImportBatch', () {
    test('statuts', () {
      MerchantImportBatch batch(String status) =>
          MerchantImportBatch.fromJson({'id': 1, 'status': status});
      expect(batch('review').isEditable, isTrue);
      expect(batch('done').isEditable, isFalse);
      expect(batch('queued').isProcessing, isTrue);
      expect(batch('running').isProcessing, isTrue);
      expect(batch('review').isProcessing, isFalse);
      expect(batch('running').statusLabel, 'Recherche en cours');
    });

    test('avancement', () {
      final MerchantImportBatch batch = MerchantImportBatch.fromJson({
        'id': 12,
        'status': 'review',
        'rows_pending': 120,
        'rows_validated': 15,
        'rows_imported': 0,
        'rows_with_errors': 31,
      });
      expect(batch.progressLabel,
          '15 validées · 31 en anomalie · 120 à relire · 0 importées');
    });

    test('résultat d\'import', () {
      final MerchantImportResult result = MerchantImportResult.fromJson({
        'batch': {'id': 12, 'status': 'review'},
        'imported': 14,
        'created': 12,
        'failed': [
          {'id': 1050, 'error': 'SIRET déjà utilisé.'}
        ],
        'skipped': [1061],
      });
      expect(result.batch?.id, 12);
      expect(result.imported, 14);
      expect(result.created, 12);
      expect(result.failed.single.id, 1050);
      expect(result.skipped, [1061]);
    });
  });
}
