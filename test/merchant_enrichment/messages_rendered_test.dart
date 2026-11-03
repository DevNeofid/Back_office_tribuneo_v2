import 'package:back_office_tribuneo_v2/domain/errors/merchant_enrichment_messages.dart';
import 'package:back_office_tribuneo_v2/domain/models/merchant_enrichment/enrichment_models.dart';
import 'package:back_office_tribuneo_v2/domain/models/merchant_import_batch_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/merchant_import_row_model.dart';
import 'package:back_office_tribuneo_v2/domain/repositories/merchant_enrichment/enrichment_repository.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/merchant_enrichment/enrichment_usecase.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/merchant_import_usecase.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/merchant_enrichment/enrichment_panel.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/merchant_import/merchant_import_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'fixtures.dart';

typedef M = MerchantEnrichmentMessages;

/// Ce que l'utilisateur voit réellement : textes, textes sélectionnables, infobulles.
List<String> visible(WidgetTester tester) => [
      for (final w in tester.widgetList<Text>(find.byType(Text)))
        w.data ?? w.textSpan?.toPlainText() ?? '',
      for (final w
          in tester.widgetList<SelectableText>(find.byType(SelectableText)))
        w.data ?? w.textSpan?.toPlainText() ?? '',
      for (final w in tester.widgetList<Tooltip>(find.byType(Tooltip)))
        w.message ?? '',
    ];

/// Codes, valeurs brutes et descriptions techniques injectés par le faux transport.
final leaks = RegExp(
    r'NAME_MATCH|ADDRESS_NOT_CORROBORATED|MULTIPLE_CANDIDATES|SYNTHETIC_ADDRESS|'
    r'LEASE_ATTEMPTS_EXHAUSTED|ENRICHMENT_[A-Z_]+|IDEMPOTENCY_|SQLSTATE|PDOException|'
    r'Conflict|Integrity|Luhn|checksum|Unexpected|ign_geocodage|recherche_entreprises|'
    r'\baddress_only\b|\bambiguous\b|\bunknown\b|\bpending\b|\bstreet\b|\bhousenumber\b|'
    r'2026-11-02T10:00:00Z|\bzip\b|\bnot_checked\b');

void expectNoLeak(WidgetTester tester) {
  for (final text in visible(tester)) {
    expect(leaks.hasMatch(text), isFalse, reason: 'texte brut affiché : $text');
  }
}

bool shows(WidgetTester tester, String text) =>
    visible(tester).any((t) => t.contains(text));

/// Ajoute la recherche ciblée et un 404 « pas de critères historiques ».
class _Transport extends FakeEnrichmentTransport {
  bool targeted = false;
  @override
  Future<EnrichmentResponse> send(String method, String path,
      {required String tenant,
      Json? body,
      Map<String, String>? headers}) async {
    if (targeted && path.endsWith('enrichment-capabilities')) {
      calls.add((
        method: method,
        path: path,
        tenant: tenant,
        body: body,
        headers: headers
      ));
      return const EnrichmentResponse(200, {
        'data': {
          'enabled': true,
          'registry': true,
          'geocoding': true,
          'vat': false,
          'chat_resolution': false,
          'targeted_research': true,
          'max_rows': 2000
        }
      });
    }
    if (method == 'GET' && path.contains('enrichment-research-jobs/')) {
      calls.add((
        method: method,
        path: path,
        tenant: tenant,
        body: body,
        headers: headers
      ));
      return const EnrichmentResponse(404, {
        'error': {
          'type': 'RESOURCE_NOT_FOUND',
          'description': 'Not found',
          'details': {'code': 'ENRICHMENT_NOT_FOUND'}
        }
      });
    }
    return super
        .send(method, path, tenant: tenant, body: body, headers: headers);
  }
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  late _Transport transport;
  late Map<int, MerchantImportRow> rows;
  late EnrichmentUseCase session;
  setUp(() {
    transport = _Transport()
      ..currentJob = jobJson(status: 'completed', done: 1, total: 1);
    rows = {1: row(1)};
    session = EnrichmentUseCase(
        repository: EnrichmentRepository(transport),
        batchId: 12,
        enabled: true,
        currentRow: (id) => rows[id],
        batchEditable: () => true,
        replaceRows: (next) {
          for (final r in next) {
            rows[r.id] = r;
          }
        },
        reloadRows: () async => rows.values.toList());
  });
  tearDown(() => session.dispose());

  Future<void> openPanel(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await session.initialize();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: EnrichmentButton(
                session: session,
                rows: () => rows.values.toList(),
                prepare: () async => true))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Compléter les informations'));
    await tester.pumpAndSettle();
  }

  Future<void> openProposals(WidgetTester tester) async {
    await tester.tap(find.text('Propositions / historique'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('proposal-$proposalId')));
    await tester.pumpAndSettle();
  }

  testWidgets('proposal and candidate: readable reasons, states and levels',
      (tester) async {
    transport.proposals = [
      {
        ...proposalJson(state: 'ambiguous', candidates: [
          {
            ...candidateJson(),
            'match_level': 'ambiguous',
            'reason_codes': [
              'NAME_MATCH',
              'ADDRESS_NOT_CORROBORATED',
              'SYNTHETIC_ADDRESS'
            ],
          }
        ]),
        'reason_codes': [
          'MULTIPLE_CANDIDATES',
          'SYNTHETIC_ADDRESS',
          'MULTIPLE_CANDIDATES'
        ],
      }
    ];
    await openPanel(tester);
    await openProposals(tester);

    expect(shows(tester, 'Ligne 1 · Choix manuel requis'), isTrue);
    expect(
        shows(
            tester,
            'Plusieurs établissements sont possibles. Comparez les propositions. · '
            'Une vérification complémentaire est nécessaire.'),
        isTrue,
        reason:
            'raisons traduites, dédupliquées, inconnu en une phrase neutre');
    expect(
        shows(
            tester,
            'Correspondance à confirmer · Le nom correspond à la recherche. · '
            'L’adresse reste à vérifier. · Une vérification complémentaire est nécessaire.'),
        isTrue);
    expect(shows(tester, 'Précision : Rue'), isTrue);
    expect(shows(tester, 'État de l’établissement non renseigné'), isTrue);
    expectNoLeak(tester);

    await tester.tap(find.text('Comparer / choisir'));
    await tester.pumpAndSettle();
    expect(shows(tester, 'Précision géographique : Rue'), isTrue);
    expect(find.text('Adresse'), findsOneWidget,
        reason: 'nom de champ français');
    expect(find.text('Code postal'), findsOneWidget);
    expect(find.text('Latitude'), findsOneWidget);
    expect(find.text('Longitude'), findsOneWidget);
    // Source : attribution lisible, date française, URL et référence conservées.
    expect(shows(tester, 'Latitude · Géocodage IGN · ${M.sourceDate(date)}'),
        isTrue);
    expect(M.sourceDate(date), isNot('Date non disponible'));
    expect(
        shows(tester,
            'https://example.invalid/synthetic-source · Référence : synthetic-address'),
        isTrue);
    expect(shows(tester, 'J’accepte des coordonnées approximatives (Rue)'),
        isTrue);
    expectNoLeak(tester);
  });

  testWidgets(
      'longer French copy keeps the manual choice and the precision consent gate',
      (tester) async {
    // Même scénario que enrichment_panel_test « ambiguous candidates… » ; seul
    // ensureVisible est ajouté, le texte traduit étant plus long (écart M12).
    transport.proposals = [
      proposalJson(state: 'ambiguous', candidates: [
        candidateJson(),
        {
          ...candidateJson(id: '00000000-0000-4000-8000-000000000004'),
          'label': 'Autre adresse synthétique'
        }
      ])
    ];
    await openPanel(tester);
    await openProposals(tester);
    expect(find.text('Comparer / choisir'), findsNWidgets(2));
    await tester.ensureVisible(find.text('Comparer / choisir').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Comparer / choisir').last);
    await tester.pumpAndSettle();
    expect(find.text('Choisir : Autre adresse synthétique'), findsOneWidget);
    await tester.tap(find.byType(Checkbox).at(4));
    await tester.pumpAndSettle();
    final apply = find.widgetWithText(FilledButton, 'Appliquer au brouillon');
    expect(tester.widget<FilledButton>(apply).onPressed, isNull,
        reason: 'coordonnées approximatives : accord explicite obligatoire');
    final consent = find.textContaining('J’accepte des coordonnées');
    await tester.ensureVisible(consent);
    await tester.pumpAndSettle();
    await tester.tap(consent);
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(apply).onPressed, isNotNull);
    await tester.tap(apply);
    await tester.pumpAndSettle();
    final write = transport.calls.singleWhere((c) => c.path.endsWith('/apply'));
    expect(write.body!['fields'], ['lat', 'lng']);
    expect(write.body!['acknowledge_approximate_coordinates'], true);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('job error code is explained, unknown code is neutral',
      (tester) async {
    transport.currentJob = {
      ...jobJson(status: 'failed', done: 0, total: 1),
      'error_code': 'LEASE_ATTEMPTS_EXHAUSTED'
    };
    transport.proposals = [];
    await openPanel(tester);
    expect(shows(tester, 'Échec · 0/1 lignes'), isTrue);
    expect(shows(tester, M.error(code: 'LEASE_ATTEMPTS_EXHAUSTED')), isTrue);
    await tester.ensureVisible(find.text('Historique des recherches'));
    await tester.tap(find.text('Historique des recherches'));
    await tester.pumpAndSettle();
    expect(shows(tester, 'Échec · ${M.sourceDate(date)}'), isTrue,
        reason: 'historique : statut et date, pas l’UUID');
    expect(shows(tester, jobId.substring(0, 8)), isFalse);
    expectNoLeak(tester);
    await tester.pumpWidget(const SizedBox());

    session.dispose();
    transport.currentJob = {
      ...jobJson(status: 'failed', done: 0, total: 1),
      'error_code': 'SQLSTATE[HY000]: General error'
    };
    session = EnrichmentUseCase(
        repository: EnrichmentRepository(transport),
        batchId: 12,
        enabled: true,
        currentRow: (id) => rows[id],
        batchEditable: () => true,
        replaceRows: (_) {},
        reloadRows: () async => rows.values.toList());
    await openPanel(tester);
    expect(shows(tester, M.error()), isTrue);
    expectNoLeak(tester);
  });

  testWidgets(
      'apply refusal: English description never shown, French refusal kept',
      (tester) async {
    transport.applyError = {
      'code': 'ENRICHMENT_PROPOSAL_STALE',
      'row': rowJson(1)
    };
    transport.applyErrorStatus = 409;
    await openPanel(tester);
    await openProposals(tester);
    await tester.tap(find.text('Comparer / choisir'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox).at(2)); // ville, sans coordonnées
    await tester.pumpAndSettle();
    await tester
        .tap(find.widgetWithText(FilledButton, 'Appliquer au brouillon'));
    await tester.pumpAndSettle();
    expect(shows(tester, M.error(code: 'ENRICHMENT_PROPOSAL_STALE')), isTrue);
    // Le refus reste un refus : plus aucune application possible sur ce candidat.
    expect(
        tester
            .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Appliquer au brouillon'))
            .onPressed,
        isNull);
    expect(transport.calls.where((c) => c.path.endsWith('/apply')).length, 1);
    expectNoLeak(tester);
  });

  testWidgets('server 5xx with an unknown code: neutral unavailable message',
      (tester) async {
    transport.applyError = {'code': 'SQLSTATE_23000_DUPLICATE'};
    transport.applyErrorStatus = 500;
    await openPanel(tester);
    await openProposals(tester);
    await tester.tap(find.text('Comparer / choisir'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox).at(2));
    await tester.pumpAndSettle();
    await tester
        .tap(find.widgetWithText(FilledButton, 'Appliquer au brouillon'));
    await tester.pumpAndSettle();
    expect(shows(tester, M.error(status: 500)), isTrue);
    expect(rows[1]!.version, 1, reason: 'brouillon inchangé');
    expectNoLeak(tester);
  });

  testWidgets('research form: French labels and validation, no POST',
      (tester) async {
    transport.targeted = true;
    await openPanel(tester);
    await tester.tap(find.text('Propositions / historique'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Préciser la recherche'));
    await tester.pumpAndSettle();
    expect(shows(tester, 'Ligne 1 · Atelier Synthétique 1'), isTrue);
    for (final label in [
      'Nom',
      'SIRET',
      'Adresse',
      'Code postal',
      'Ville',
      'Pays'
    ]) {
      expect(find.text(label), findsWidgets, reason: label);
    }
    final posts = transport.calls.where((c) => c.method == 'POST').length;

    await tester.tap(find.text('Relancer la recherche'));
    await tester.pumpAndSettle();
    expect(
        tester.widget<Text>(find.byKey(const ValueKey('research-error'))).data,
        'Indiquez un SIRET, ou un nom ou une adresse avec le code postal ou la ville.');

    await tester.enterText(
        find.byKey(const ValueKey('research-siret')), '12345678901234');
    await tester.tap(find.text('Relancer la recherche'));
    await tester.pumpAndSettle();
    expect(
        tester.widget<Text>(find.byKey(const ValueKey('research-error'))).data,
        'Ce SIRET n’est pas valide : vérifiez les 14 chiffres saisis.');

    await tester.enterText(find.byKey(const ValueKey('research-siret')), '');
    await tester.enterText(
        find.byKey(const ValueKey('research-street')), 'https://evil.invalid');
    await tester.tap(find.text('Relancer la recherche'));
    await tester.pumpAndSettle();
    expect(
        tester.widget<Text>(find.byKey(const ValueKey('research-error'))).data,
        startsWith('Le champ « Adresse »'));

    expect(transport.calls.where((c) => c.method == 'POST').length, posts,
        reason: 'aucune relance sans critères valides');
    expectNoLeak(tester);
  });

  group('import grid', () {
    const batch = MerchantImportBatch(
        id: 12,
        source: 'commercants.csv',
        status: 'review',
        createdDate: '2026-10-20 10:12:03');
    MerchantImportRow gridRow(int id, String status,
            {List<MerchantImportIssue> issues = const [], String? error}) =>
        MerchantImportRow(
          id: id,
          position: id,
          status: status,
          fields: {
            'name': 'Commerce $id',
            'type': 'partner',
            'city': 'Lille',
            'zip': '5900'
          },
          suggestedValues: const {},
          issues: issues,
          version: 1,
          error: error,
        );

    testWidgets('issues, row error and import failures are local French text',
        (tester) async {
      final useCase = _GridUseCase([
        gridRow(1, 'pending', issues: const [
          MerchantImportIssue(
              field: 'siret',
              level: 'error',
              code: 'SIRET_INVALID',
              message: 'Luhn checksum failed (SQLSTATE 22003)'),
          MerchantImportIssue(
              field: 'zip',
              level: 'warning',
              code: 'NEW_RULE_X',
              message: 'Unexpected zip format'),
        ]),
        gridRow(2, 'failed',
            error: 'SQLSTATE[23000]: Integrity constraint violation'),
        gridRow(3, 'validated'),
      ]);
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: MerchantImportGrid(
                  batch: batch,
                  onBack: () {},
                  onImported: () {},
                  useCase: useCase))));
      await tester.pumpAndSettle();

      // Sévérité inchangée : une erreur bloque, l'avertissement reste un avertissement.
      expect(find.text('1 à corriger'), findsOneWidget);
      expect(shows(tester, M.importIssue('SIRET_INVALID', field: 'siret')),
          isTrue);
      expect(shows(tester, 'Vérifiez le champ « Code postal ».'), isTrue);
      expect(shows(tester, 'Échec de l\'import : ${M.importFailure(null)}'),
          isTrue);
      expect(useCase.rows[1]!.issues.first.message,
          'Luhn checksum failed (SQLSTATE 22003)',
          reason: 'le modèle garde le message et le code d’origine');
      expect(useCase.rows[1]!.issues.first.code, 'SIRET_INVALID');
      expectNoLeak(tester);

      await tester.tap(find.text('Importer les lignes validées (1)'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Importer'));
      await tester.pumpAndSettle();
      expect(find.text("Résultat de l'import"), findsOneWidget);
      expect(shows(tester, 'Commerce 3 : ${M.importFailure(null)}'), isTrue);
      expectNoLeak(tester);
    });
  });
}

class _GridUseCase extends MerchantImportUseCase {
  final Map<int, MerchantImportRow> rows;
  _GridUseCase(List<MerchantImportRow> rows)
      : rows = {for (final r in rows) r.id: r};

  @override
  Future<MerchantImportBatch> getBatch(int id) async =>
      const MerchantImportBatch(
          id: 12,
          source: 'commercants.csv',
          status: 'review',
          createdDate: '2026-10-20 10:12:03');

  @override
  Future<List<MerchantImportRow>> getRows(int id, {String? status}) async =>
      rows.values.toList();

  @override
  Future<MerchantImportResult> importValidated(int id,
          {String? idempotencyKey}) async =>
      const MerchantImportResult(imported: 0, failed: [
        MerchantImportFailure(
            id: 3,
            error:
                'PDOException: SQLSTATE[23000]: Integrity constraint violation'),
      ]);
}
