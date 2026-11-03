import 'package:back_office_tribuneo_v2/domain/errors/merchant_enrichment_messages.dart';
import 'package:back_office_tribuneo_v2/domain/models/merchant_enrichment/enrichment_models.dart';
import 'package:back_office_tribuneo_v2/domain/models/merchant_enrichment/research_models.dart';
import 'package:back_office_tribuneo_v2/domain/repositories/merchant_enrichment/enrichment_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'fixtures.dart';

Map<String, String> criteria([Map<String, String> delta = const {}]) => {
      'name': 'Atelier Synthétique',
      'siret': '',
      'street': '12 rue du Test',
      'zip': '04000',
      'city': 'Ville Synthétique',
      'country': 'France',
      ...delta,
    };

final technical = RegExp(
    r'[A-Z]{2,}_[A-Z_]+|\bLuhn\b|\boctets?\b|\bbytes?\b|\b4096\b|\bzip\b|'
    r'\bstreet\b|\bname\b|\bcity\b|\bsiret\b|contrôle\)|Exception|null');

void main() {
  group('EnrichmentException', () {
    test('code, status and row are untouched; only toString uses the catalogue',
        () {
      final synthetic = row(1);
      for (final (code, status) in [
        ('ENRICHMENT_VERSION_CONFLICT', 409),
        ('IDEMPOTENCY_REQUEST_IN_PROGRESS', 409),
        ('ENRICHMENT_RESEARCH_RATE_LIMITED', 429),
        ('SQLSTATE[42S22]: Column not found', 500),
        (null, 0),
      ]) {
        final e =
            EnrichmentException(code: code, status: status, row: synthetic);
        expect(e.code, code);
        expect(e.status, status);
        expect(identical(e.row, synthetic), isTrue);
        expect(e.toString(), M.error(code: code, status: status));
        if (code != null && code.length > 3) {
          expect(e.toString(), isNot(contains(code)));
        }
      }
    });

    test('conflict flag (control decision) is unchanged', () {
      expect(
          const EnrichmentException(
                  code: 'ENRICHMENT_VERSION_CONFLICT', status: 409)
              .conflict,
          isTrue);
      expect(
          const EnrichmentException(code: 'X', status: 409).conflict, isTrue);
      expect(const EnrichmentException(status: 409).conflict, isTrue);
      expect(
          const EnrichmentException(code: 'IDEMPOTENCY_KEY_RETRY', status: 409)
              .conflict,
          isFalse);
      expect(
          const EnrichmentException(
                  code: 'IDEMPOTENCY_REQUEST_IN_PROGRESS', status: 409)
              .conflict,
          isFalse);
      expect(
          const EnrichmentException(
                  code: 'ENRICHMENT_VERSION_CONFLICT', status: 422)
              .conflict,
          isFalse);
    });

    test('messages still carry the words existing flows rely on', () {
      // enrichment_usecase_test / enrichment_panel_test : « précision », « Relisez ».
      expect(
          const EnrichmentException(
                  code: 'ENRICHMENT_PRECISION_CONFIRMATION_REQUIRED',
                  status: 422)
              .toString(),
          contains('précision'));
      expect(
          const EnrichmentException(
                  code: 'ENRICHMENT_VERSION_CONFLICT', status: 409)
              .toString(),
          contains('Relisez'));
      expect(
          const EnrichmentException(code: 'SOMETHING', status: 409).toString(),
          contains('Relisez'));
    });

    test('repository: English/SQL description never reaches the message',
        () async {
      final transport = FakeEnrichmentTransport()
        ..handler = (method, path, body) async => EnrichmentResponse(500, {
              'error': {
                'type': 'SERVER_ERROR',
                'description':
                    'PDOException: SQLSTATE[HY000] at /var/www/app/src/Infrastructure/Repo.php:42',
                'details': {
                  'code': 'SQLSTATE_HY000',
                  'row': rowJson(1, version: 7)
                }
              }
            });
      final repository = EnrichmentRepository(transport);
      try {
        await repository.capabilities('synthetic_tenant');
        fail('must throw');
      } on EnrichmentException catch (e) {
        expect(e.code, 'SQLSTATE_HY000');
        expect(e.status, 500);
        expect(e.row?.version, 7);
        expect(e.toString(), M.error(status: 500));
        expect(e.toString(), isNot(contains('SQL')));
        expect(e.toString(), isNot(contains('PDOException')));
      }
      transport.handler = null;
      transport.offline = true;
      try {
        await repository.capabilities('synthetic_tenant');
        fail('must throw');
      } on EnrichmentException catch (e) {
        expect(e.status, 0);
        expect(e.toString(), M.error());
        expect(e.toString(), isNot(contains('StateError')));
      }
    });
  });

  group('ResearchCriteria.error', () {
    test('same accept/refuse decisions; French text with readable field', () {
      expect(ResearchCriteria(criteria()).error, isNull);
      expect(ResearchCriteria(criteria({'siret': '73282932000074'})).error,
          isNull);
      final cases = <Map<String, String>, Pattern>{
        {'zip': '4000'}: 'Le code postal doit contenir 5 chiffres.',
        {'siret': '1234567890123'}: 'exactement 14 chiffres',
        {'siret': '12345678901234'}: 'Ce SIRET n’est pas valide',
        {'country': 'BE'}: 'ne couvre que la France',
        {'name': 'https://evil.invalid'}: 'Le champ « Nom »',
        {'name': 'javascript:launch'}: 'Le champ « Nom »',
        {'street': 'mailto:test@example.invalid'}: 'Le champ « Adresse »',
        {'city': 'data:text/plain,forged'}: 'Le champ « Ville »',
        {'name': 'x' * 513}: 'un caractère non autorisé',
        {'name': '\nAtelier'}: 'un caractère non autorisé',
        {'name': '', 'zip': '', 'city': '', 'street': ''}:
            'Indiquez un SIRET, ou un nom ou une adresse',
        {'name': '😀' * 512, 'street': '😀' * 512, 'city': '😀' * 128}:
            'Les critères sont trop longs',
      };
      for (final entry in cases.entries) {
        final error = ResearchCriteria(criteria(entry.key)).error;
        expect(error, isNotNull, reason: '${entry.key}');
        expect(error, contains(entry.value), reason: '${entry.key}');
        expect(technical.hasMatch(error!), isFalse, reason: error);
      }
    });

    test('unknown key / raw control still refused, without the technical key',
        () {
      final error = ResearchCriteria({...criteria(), 'password': 'x'}).error;
      expect(error, isNotNull);
      expect(error, isNot(contains('password')));
      expect(technical.hasMatch(error!), isFalse, reason: error);
      expect(
          () => ResearchCriteria.fromJson(
              <String, dynamic>{...criteria(), 'city': null}),
          throwsA(isA<EnrichmentException>()));
    });

    test('lat/lng/SIRET/TVA are named explicitly where they matter', () {
      expect(M.importIssue('LAT_INVALID'), contains('Latitude'));
      expect(M.importIssue('LNG_INVALID'), contains('Longitude'));
      expect(M.importIssue('SIRET_INVALID'), contains('SIRET'));
      expect(M.importIssue('VAT_INVALID'), contains('TVA'));
      expect(M.reason('APPLIED_FIELD_LNG'), contains('Longitude'));
      expect(ResearchCriteria(criteria({'siret': '12345678901234'})).error,
          contains('SIRET'));
    });
  });
}

typedef M = MerchantEnrichmentMessages;
