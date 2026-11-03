import 'package:back_office_tribuneo_v2/domain/errors/merchant_enrichment_messages.dart';
import 'package:flutter_test/flutter_test.dart';

typedef M = MerchantEnrichmentMessages;

/// Entrées inconnues, hostiles ou techniques : aucune ne doit ressortir telle quelle.
const hostile = [
  '<script>alert(1)</script>',
  'SQLSTATE[23000]: Integrity constraint violation: 1062 Duplicate entry',
  'PDOException: SQLSTATE[HY000] [2002] Connection refused',
  'TypeError: null is not a subtype of type String in EnrichmentRepository.request',
  '#0 EnrichmentRepository.request (package:back_office/x.dart:42:7)',
  'java.lang.NullPointerException',
  '{"error":{"type":"BAD_REQUEST","description":"Unknown"}}',
  'ENRICHMENT_SOMETHING_NEW',
  'APPLIED_FIELD_PASSWORD',
  'unknown',
  'pending',
];

final _unknownNeutral = {
  M.reason('ZZZ_NOT_A_CODE'),
  M.field('zzz_not_a_field'),
  M.proposalState('zzz'),
  M.jobStatus('zzz'),
  M.matchLevel('zzz'),
  M.establishmentStatus('zzz'),
  M.provider('zzz'),
  M.geoPrecision('zzz'),
  M.vatStatus('zzz', capability: true),
  M.importIssue('ZZZ'),
  M.importFailure('zzz'),
};

/// Codes réels lus dans l'API (lecture seule) et le BO, lot 04.
const enrichmentErrorCodes = [
  'ENRICHMENT_DISABLED',
  'ENRICHMENT_INVALID_REQUEST',
  'ENRICHMENT_NOT_FOUND',
  'ENRICHMENT_ALREADY_RUNNING',
  'ENRICHMENT_BATCH_NOT_EDITABLE',
  'ENRICHMENT_ROW_NOT_EDITABLE',
  'ENRICHMENT_VERSION_CONFLICT',
  'ENRICHMENT_PROPOSAL_STALE',
  'ENRICHMENT_FIELD_NOT_EMPTY',
  'ENRICHMENT_IDENTITY_CONFLICT',
  'ENRICHMENT_ADDRESS_CONTEXT_CONFLICT',
  'ENRICHMENT_PRECISION_CONFIRMATION_REQUIRED',
  'ENRICHMENT_UNAVAILABLE',
  'ENRICHMENT_RESEARCH_DISABLED',
  'ENRICHMENT_RESEARCH_UNSUPPORTED_COUNTRY',
  'ENRICHMENT_SEARCH_INSUFFICIENT_INPUT',
  'ENRICHMENT_RESEARCH_RATE_LIMITED',
  'IDEMPOTENCY_REQUEST_IN_PROGRESS',
  'IDEMPOTENCY_KEY_RETRY',
  'IDEMPOTENCY_KEY_REUSED',
  'IDEMPOTENCY_KEY_INVALID',
  'UNKNOWN_TENANT',
  'TENANT_FORBIDDEN',
  'ACCESS_DENIED',
  'AUTH_REQUIRED',
  'SESSION_NOT_FOUND',
  'SESSION_REVOKED',
  'MISSING_TOKEN',
  // job.error_code
  'BATCH_NOT_EDITABLE',
  'LEASE_ATTEMPTS_EXHAUSTED',
  'RESEARCH_MARKER_INVALID',
];

const reasonCodes = [
  'SEARCH_SIRET',
  'SEARCH_NAME',
  'SIRET_EXACT',
  'SIRET_INVALID',
  'SIRET_NOT_FOUND',
  'ESTABLISHMENT_NOT_FOUND',
  'NO_CANDIDATE',
  'PROVIDER_RESULTS_NOT_EXHAUSTIVE',
  'INPUT_INSUFFICIENT_FOR_REGISTRY',
  'MULTIPLE_CANDIDATES',
  'CANDIDATES_TRUNCATED',
  'REGISTRY_UNAVAILABLE',
  'REGISTRY_RATE_LIMITED',
  'GEOCODING_UNAVAILABLE',
  'GEOCODING_RATE_LIMITED',
  'BUDGET_EXHAUSTED',
  'INTERNAL_ERROR',
  'NAME_MATCH',
  'NAME_NOT_CORROBORATED',
  'ADDRESS_MATCH',
  'ADDRESS_NOT_CORROBORATED',
  'ADDRESS_CONFLICT',
  'ADDRESS_IMPRECISE_INPUT',
  'ADDRESS_FROM_ROW',
  'ESTABLISHMENT_CLOSED',
  'DIFFUSION_PARTIAL',
  'HEADQUARTERS',
  'COORDINATES_ALREADY_PRESENT',
  'GEOCODE_NOT_FOUND',
  'GEOCODE_ADDRESS_MISMATCH',
  'GEOCODE_IMPRECISE',
  'VAT_ALREADY_PRESENT',
  'VAT_NOT_ELIGIBLE',
  'VAT_FOUND_IN_SOURCE',
  'VAT_NOT_FOUND_IN_SOURCE',
  'VAT_MULTIPLE_NUMBERS',
  'VAT_UNAVAILABLE',
  'VAT_RATE_LIMITED',
  'VAT_BUDGET_EXHAUSTED',
  'VAT_INVALID_RESPONSE',
  'VAT_RESULTS_INCOMPLETE',
  'ROW_VERSION_CHANGED',
  'ROW_NOT_PENDING',
  'ROW_NOT_PARTNER',
  'APPLIED',
];

const issueCodes = [
  'NAME_REQUIRED',
  'TYPE_INVALID',
  'EMAIL_REQUIRED',
  'EMAIL_INVALID',
  'SIRET_REQUIRED',
  'SIRET_INVALID',
  'SIRET_DUPLICATE',
  'REMOVED_FROM_NETWORK',
  'ALREADY_IN_NETWORK',
  'EXISTS_ELSEWHERE',
  'PHONE_MISSING',
  'ADDRESS_INCOMPLETE',
  'LAT_INVALID',
  'LNG_INVALID',
  'COORDINATES_INCOMPLETE',
  'COORDINATES_MISSING',
  'IBAN_INVALID',
  'VAT_INVALID',
  'SECTOR_UNKNOWN',
];

/// Indices d'une fuite technique dans un texte destiné à l'utilisateur.
final technical = RegExp(
    r'[A-Z]{2,}_[A-Z_]+|SQL|Exception|Error\b|stack|null|undefined|\{|\}|'
    r'<|>|\bunknown\b|\bpending\b|\bLuhn\b|\boctets?\b|\bbytes?\b|\bzip\b|'
    r'\bstreet\b|\bHTTP\b|\b[45]\d\d\b');

void expectClean(String text, {String? input}) {
  expect(text.trim(), isNotEmpty);
  expect(technical.hasMatch(text), isFalse, reason: text);
  if (input != null && input.length > 3) {
    expect(text.contains(input), isFalse, reason: 'fuite de « $input »');
  }
}

void main() {
  group('error()', () {
    test('every known code has its own French sentence, never the code', () {
      final fallbacks = {
        for (final s in [0, 400, 401, 403, 404, 409, 422, 429, 500, 503])
          M.error(status: s)
      };
      for (final code in enrichmentErrorCodes) {
        final text = M.error(code: code, status: 409);
        expectClean(text, input: code);
        if (code == 'ENRICHMENT_INVALID_REQUEST') {
          // Même sens que le 400 générique : texte partagé, volontairement.
          expect(text, M.error(status: 400));
          continue;
        }
        if ({
          'AUTH_REQUIRED',
          'MISSING_TOKEN',
          'SESSION_NOT_FOUND',
          'SESSION_REVOKED'
        }.contains(code)) {
          // Session absente ou expirée : même phrase que le 401 générique.
          expect(text, M.error(status: 401));
          continue;
        }
        expect(fallbacks.contains(text), isFalse,
            reason: '$code doit avoir un texte dédié');
      }
    });

    test('status classes keep their nuance', () {
      final s401 = M.error(status: 401), s403 = M.error(status: 403);
      final s404 = M.error(status: 404), s409 = M.error(status: 409);
      final s422 = M.error(status: 422), s429 = M.error(status: 429);
      final s500 = M.error(status: 500), s503 = M.error(status: 503);
      final s0 = M.error();
      expect(s401, contains('session'));
      expect(s403, contains('droits'));
      expect(s404, contains('indisponible'));
      expect(s409, contains('Relisez'));
      expect(s422, contains('Reprenez la lecture'));
      expect(s429, contains('trop de demandes'));
      expect(s500, s503);
      expect(s500, contains('indisponible'));
      expect(s0, contains('indisponible'));
      // Accès refusé, conflit, source indisponible et absence restent distincts.
      expect({s401, s403, s404, s409, s422, s429, s500, s0}.length, 8);
      for (final t in [s401, s403, s404, s409, s422, s429, s500, s0]) {
        expectClean(t);
        expect(t, isNot(contains('introuvable')),
            reason: 'une panne ou un refus ne devient pas une absence');
      }
    });

    test('unknown, malicious and technical codes never leak', () {
      for (final code in hostile) {
        for (final status in [0, 400, 409, 500, 599, 600, -1]) {
          expectClean(M.error(code: code, status: status), input: code);
        }
      }
      expect(M.error(code: '', status: 0), M.error());
      expect(M.error(code: null, status: 503), M.error(status: 500));
    });

    test(
        'refusal semantics kept: stale, identity, address, access, idempotency',
        () {
      expect(
          M.error(code: 'ENRICHMENT_PROPOSAL_STALE'), contains('plus à jour'));
      expect(M.error(code: 'ENRICHMENT_IDENTITY_CONFLICT'),
          'Le SIRET proposé diffère de celui de la ligne. Vérifiez le commerçant sélectionné.');
      expect(M.error(code: 'ENRICHMENT_ADDRESS_CONTEXT_CONFLICT'),
          contains('adresse'));
      expect(M.error(code: 'TENANT_FORBIDDEN'), contains('accès'));
      expect(M.error(code: 'ENRICHMENT_PRECISION_CONFIRMATION_REQUIRED'),
          contains('précision'));
      expect(M.error(code: 'IDEMPOTENCY_REQUEST_IN_PROGRESS'),
          contains('encore en cours'));
      expect(M.error(code: 'IDEMPOTENCY_KEY_RETRY'), contains('réessayer'));
      // Une indisponibilité n'est jamais présentée comme une absence.
      expect(M.error(code: 'ENRICHMENT_UNAVAILABLE'), contains('indisponible'));
      expect(M.error(code: 'ENRICHMENT_UNAVAILABLE'),
          isNot(contains('introuvable')));
    });

    test('suggested next actions exist in the real UI', () {
      // Libellés réels : « Reprendre la lecture », « Relancer la recherche »,
      // « Rechercher sur ces N lignes » (nouvelle recherche), reconnexion.
      expect(M.error(code: 'ENRICHMENT_ALREADY_RUNNING'),
          contains('Reprenez la lecture'));
      expect(M.error(code: 'ENRICHMENT_NOT_FOUND'),
          contains('Reprenez la lecture'));
      expect(M.error(status: 401), contains('Reconnectez-vous'));
      for (final code in enrichmentErrorCodes) {
        expect(M.error(code: code), isNot(contains('Actualisez')),
            reason: 'aucun bouton « Actualiser » dans ces dialogues');
      }
    });
  });

  group('reasons', () {
    test('contract examples', () {
      expect(M.reason('NAME_MATCH'), 'Le nom correspond à la recherche.');
      expect(
          M.reason('ADDRESS_NOT_CORROBORATED'), 'L’adresse reste à vérifier.');
      expect(M.reason('MULTIPLE_CANDIDATES'),
          'Plusieurs établissements sont possibles. Comparez les propositions.');
      expect(M.reason('REGISTRY_RATE_LIMITED'),
          'Le service de recherche reçoit trop de demandes. Réessayez dans un instant.');
      expect(M.reason('GEOCODING_UNAVAILABLE'),
          'Les coordonnées n’ont pas pu être recherchées pour le moment.');
      expect(M.reason('NOT_A_REAL_CODE'),
          'Une vérification complémentaire est nécessaire.');
    });

    test('every inventoried reason is translated and clean', () {
      for (final code in reasonCodes) {
        final text = M.reason(code);
        expect(_unknownNeutral.contains(text), isFalse, reason: code);
        expectClean(text, input: code);
      }
    });

    test('outages are never an absence; published VAT is not a validation', () {
      for (final code in [
        'REGISTRY_UNAVAILABLE',
        'VAT_UNAVAILABLE',
        'VAT_RATE_LIMITED',
        'VAT_BUDGET_EXHAUSTED',
        'VAT_INVALID_RESPONSE',
        'VAT_RESULTS_INCOMPLETE'
      ]) {
        expect(M.reason(code), contains('pas une absence'), reason: code);
      }
      expect(M.reason('VAT_FOUND_IN_SOURCE'),
          contains('pas une vérification VIES'));
      expect(M.reason('VAT_NOT_FOUND_IN_SOURCE'), contains('n’exclut pas'));
      expect(M.reason('GEOCODE_IMPRECISE'), contains('approximative'));
    });

    test('APPLIED_FIELD_<field> only for known fields', () {
      expect(M.reason('APPLIED_FIELD_SIRET'),
          'Champ appliqué au brouillon : SIRET.');
      expect(M.reason('APPLIED_FIELD_LAT'),
          'Champ appliqué au brouillon : Latitude.');
      expect(M.reason('APPLIED_FIELD_INTRACOMMUNITY_VAT_NUMBER'),
          'Champ appliqué au brouillon : TVA intracommunautaire.');
      for (final code in [
        'APPLIED_FIELD_',
        'APPLIED_FIELD_PASSWORD',
        'APPLIED_FIELD_<b>X</b>',
        'APPLIED_FIELD_ZZZ_NOT_A_FIELD'
      ]) {
        expect(
            M.reason(code), 'Une vérification complémentaire est nécessaire.',
            reason: code);
      }
    });

    test(
        'reasons(): useful order, deduplication, one neutral line for unknowns',
        () {
      final out = M.reasons([
        'SIRET_EXACT',
        'FOO',
        'VAT_UNAVAILABLE',
        'NAME_MATCH',
        'VAT_RATE_LIMITED', // même libellé que VAT_UNAVAILABLE
        'BAR',
        'SIRET_EXACT',
        '<script>',
      ]);
      expect(out, [
        M.reason('SIRET_EXACT'),
        M.reason('VAT_UNAVAILABLE'),
        M.reason('NAME_MATCH'),
        'Une vérification complémentaire est nécessaire.',
      ]);
      expect(M.reasons(const []), isEmpty);
      expect(M.reasons(['X', 'Y']),
          ['Une vérification complémentaire est nécessaire.']);
      for (final line in out) {
        expectClean(line);
      }
    });
  });

  group('labels', () {
    test('French field names, neutral fallback without the key', () {
      expect(M.field('name'), 'Nom');
      expect(M.field('siret'), 'SIRET');
      expect(M.field('street'), 'Adresse');
      expect(M.field('zip'), 'Code postal');
      expect(M.field('city'), 'Ville');
      expect(M.field('country'), 'Pays');
      expect(M.field('lat'), 'Latitude');
      expect(M.field('lng'), 'Longitude');
      expect(M.field('intracommunity_vat_number'), 'TVA intracommunautaire');
      expect(M.field('naf'), 'Code NAF');
      expect(M.field('phone'), 'Téléphone');
      expect(M.field('email'), 'Email');
      for (final key in ['zzz_secret', 'password', '<b>', 'SIRET', '']) {
        expect(M.field(key), 'Autre information', reason: key);
      }
    });

    test('states, levels, statuses, providers and precision', () {
      expect(M.proposalState('ambiguous'), 'Choix manuel requis');
      expect(M.proposalState('provider_unavailable'), 'Source indisponible');
      expect(M.proposalState('not_found'), 'Aucun résultat');
      expect(M.jobStatus('queued'), 'En attente');
      expect(M.jobStatus('completed_with_errors'), isNot(contains('errors')));
      expect(M.matchLevel('exact_identifier'), 'SIRET identique');
      expect(M.matchLevel('address_only'), 'Adresse seule');
      expect(M.establishmentStatus('active'), 'Établissement actif');
      expect(M.establishmentStatus('closed'), 'Établissement fermé');
      expect(
          M.establishmentStatus(null), 'État de l’établissement non renseigné');
      expect(M.provider('recherche_entreprises'), 'Recherche d’entreprises');
      expect(M.provider('ign_geocodage'), 'Géocodage IGN');
      expect(M.provider('dgfip_tva'), 'DGFiP');
      expect(M.geoPrecision('housenumber'), 'Adresse précise');
      expect(M.geoPrecision('street'), 'Rue');
      expect(M.geoPrecision('municipality'), 'Commune');
      expect(M.geoPrecision(null), 'Précision non renseignée');
      for (final s in [
        M.geoPrecision('housenumber'),
        M.geoPrecision('street'),
        M.geoPrecision(null)
      ]) {
        expect(s.toLowerCase(), isNot(contains('certifi')));
      }
    });

    test('unknown values give neutral labels, never the raw value', () {
      for (final value in hostile) {
        for (final text in [
          M.proposalState(value),
          M.jobStatus(value),
          M.matchLevel(value),
          M.establishmentStatus(value),
          M.provider(value),
          M.geoPrecision(value),
          M.vatStatus(value, capability: true),
          M.field(value),
        ]) {
          expectClean(text, input: value);
        }
      }
    });

    test('vatStatus: capability off is « Non vérifiée », nuances kept', () {
      for (final s in [
        'found',
        'not_found',
        'ambiguous',
        'unavailable',
        'not_checked'
      ]) {
        expect(M.vatStatus(s, capability: false), 'Non vérifiée');
      }
      expect(M.vatStatus('found', capability: true),
          'Trouvée dans la source DGFiP datée');
      expect(M.vatStatus('not_found', capability: true),
          contains('n’exclut pas un numéro hors de cette source'));
      expect(M.vatStatus('ambiguous', capability: true),
          contains('Plusieurs numéros'));
      expect(M.vatStatus('unavailable', capability: true),
          contains('ce n’est pas une absence'));
      expect(M.vatStatus('not_checked', capability: true), 'Non vérifiée');
      for (final s in ['found', 'not_found', 'ambiguous', 'unavailable']) {
        final t = M.vatStatus(s, capability: true).toLowerCase();
        expect(t, isNot(contains('validée')));
        expect(t, isNot(contains('vies')));
      }
    });
  });

  group('sourceDate()', () {
    const months = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre'
    ];
    String expected(DateTime utc) {
      final l = utc.toLocal();
      String two(int n) => n.toString().padLeft(2, '0');
      return '${l.day == 1 ? '1er' : l.day} ${months[l.month - 1]} ${l.year} à '
          '${two(l.hour)}:${two(l.minute)}';
    }

    test('real ISO instants become French local date and time', () {
      expect(M.sourceDate('2026-11-03T08:00:00Z'),
          expected(DateTime.utc(2026, 11, 3, 8)));
      expect(M.sourceDate('2026-11-02T10:00:00.123456Z'),
          expected(DateTime.utc(2026, 11, 2, 10)));
      expect(M.sourceDate('2026-07-14T23:30:00+02:00'),
          expected(DateTime.utc(2026, 7, 14, 21, 30)));
      expect(M.sourceDate('2026-01-01 12:00:00Z'),
          expected(DateTime.utc(2026, 1, 1, 12)));
    });

    test('date only: no invented time, « 1er »', () {
      expect(M.sourceDate('2026-11-03'), '3 novembre 2026');
      expect(M.sourceDate('2026-11-01'), '1er novembre 2026');
      expect(M.sourceDate('2028-02-29'), '29 février 2028');
    });

    test('invalid or missing: « Date non disponible », never the value', () {
      for (final value in [
        null,
        '',
        '   ',
        'hier',
        '2026-02-30',
        '2026-13-01',
        '2026-00-10',
        '2027-02-29',
        '2026-11-03T25:00:00Z',
        '2026-11-03T10:61:00Z',
        '2026-11-03T10:00:00+25:00',
        '20261103',
        '03/11/2026',
        '2026-11-03T10:00:00Z<script>',
        ...hostile
      ]) {
        expect(M.sourceDate(value), 'Date non disponible', reason: '$value');
      }
    });

    test('the model instant is not altered', () {
      const raw = '2026-11-03T08:00:00Z';
      final before = DateTime.parse(raw);
      M.sourceDate(raw);
      expect(DateTime.parse(raw), before);
      expect(raw, '2026-11-03T08:00:00Z');
    });
  });

  group('grid', () {
    test('validator codes translated, free API message never needed', () {
      for (final code in issueCodes) {
        final text = M.importIssue(code, field: 'siret');
        expect(text, isNot(startsWith('Vérifiez le champ')), reason: code);
        expectClean(text, input: code);
      }
      expect(M.importIssue('SIRET_REQUIRED'),
          'Le SIRET est obligatoire pour un commerçant.');
      expect(M.importIssue('COORDINATES_INCOMPLETE', field: 'lat'),
          contains('Latitude et longitude'));
    });

    test('unknown code: check the known field, nothing invented', () {
      expect(M.importIssue('NEW_RULE', field: 'zip'),
          'Vérifiez le champ « Code postal ».');
      expect(
          M.importIssue('', field: 'lng'), 'Vérifiez le champ « Longitude ».');
      expect(M.importIssue('NEW_RULE', field: 'zzz_secret'),
          'Vérifiez les informations de cette ligne.');
      expect(M.importIssue('NEW_RULE'),
          'Vérifiez les informations de cette ligne.');
      for (final code in hostile) {
        expectClean(M.importIssue(code, field: code), input: code);
      }
    });

    test('import failure: exact local codes only, otherwise a safe sentence',
        () {
      expect(
          M.importFailure('ROW_IMPORTED'), 'Cette ligne a déjà été importée.');
      expect(M.importFailure(' ROW_NOT_FOUND '), contains('n’existe plus'));
      final safe = M.importFailure(null);
      expect(safe, startsWith('Impossible d’importer cette ligne'));
      for (final raw in [
        '',
        'Ligne 4 : échec de la création de l\'entité "Boulangerie".',
        'Unknown tenant (no network matching db_name).',
        'Duplicate entry for key siret — ROW_IMPORTED',
        'row_imported',
        ...hostile
      ]) {
        expect(M.importFailure(raw), safe, reason: raw);
      }
    });
  });

  test('every catalogue output is free of technical tokens', () {
    for (final text in _unknownNeutral) {
      expectClean(text);
    }
  });
}
