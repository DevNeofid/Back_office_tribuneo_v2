import 'package:back_office_tribuneo_v2/data/local/merchant_import_view_store.dart';
import 'package:back_office_tribuneo_v2/domain/models/merchant_import_batch_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/merchant_import_row_model.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/merchant_import_usecase.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/merchant_import/merchant_import_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

const MerchantImportBatch _batch = MerchantImportBatch(
    id: 12,
    source: 'commercants.csv',
    status: 'review',
    createdDate: '2026-10-20 10:12:03');

/// API simulée : applique les PATCH en mémoire.
class _FakeUseCase extends MerchantImportUseCase {
  final Map<int, MerchantImportRow> rows;
  final List<Map<String, dynamic>> patches = [];

  _FakeUseCase(List<MerchantImportRow> rows)
      : rows = {for (final row in rows) row.id: row};

  @override
  Future<MerchantImportBatch> getBatch(int id) async => _batch;

  @override
  Future<List<MerchantImportRow>> getRows(int id, {String? status}) async =>
      rows.values.toList();

  @override
  Future<MerchantImportPatchResult> patchRow(
      int id, int rowId, Map<String, dynamic> body) async {
    patches.add({'row': rowId, ...body});
    final MerchantImportRow current = rows[rowId]!;
    final MerchantImportRow updated = MerchantImportRow(
      id: rowId,
      position: current.position,
      status: body['status'] as String? ?? current.status,
      fields: body.containsKey('field')
          ? {...current.fields, body['field'] as String: body['value']}
          : current.fields,
      suggestedValues: current.suggestedValues,
      // Le serveur recalcule les anomalies : SIRET renseigné → plus d'erreur.
      issues: body['field'] == 'siret' ? const [] : current.issues,
      version: current.version + 1,
    );
    rows[rowId] = updated;
    return MerchantImportPatchResult(row: updated);
  }
}

MerchantImportRow _row(int id, String name,
        {List<MerchantImportIssue> issues = const [],
        Map<String, String> sources = const {}}) =>
    MerchantImportRow(
      id: id,
      position: id,
      status: 'pending',
      fields: {'name': name, 'type': 'partner', 'city': 'Lille'},
      suggestedValues: {'name': name, 'type': 'partner', 'city': 'Lille'},
      suggestedSources: sources,
      issues: issues,
      version: 1,
    );

const MerchantImportIssue _noSiret = MerchantImportIssue(
    field: 'siret', level: 'error', message: 'SIRET absent.');

/// Vue mémorisée en mémoire.
class _MemoryViewStore implements MerchantImportViewStore {
  Map<String, dynamic>? saved;
  _MemoryViewStore([this.saved]);
  @override
  Future<Map<String, dynamic>?> read(int batchId) async => saved;
  @override
  Future<void> save(int batchId, Map<String, dynamic> state) async =>
      saved = state;
}

Future<void> _pumpGrid(WidgetTester tester, _FakeUseCase useCase,
    {MerchantImportViewStore? store}) async {
  tester.view.physicalSize = const Size(1600, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: MerchantImportGrid(
        batch: _batch,
        onBack: () {},
        onImported: () {},
        useCase: useCase,
        viewStore: store ?? _MemoryViewStore(),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('affiche les lignes, les filtres et le bouton d\'import',
      (tester) async {
    await _pumpGrid(
        tester,
        _FakeUseCase([
          _row(1, 'Boulangerie Paul'),
          _row(2, 'Fleuriste', issues: const [
            MerchantImportIssue(
                field: 'siret', level: 'error', message: 'SIRET absent.')
          ]),
        ]));

    expect(find.text('Boulangerie Paul'), findsOneWidget);
    expect(find.text('Fleuriste'), findsOneWidget);
    expect(find.text('Commerçant'), findsNWidgets(2));
    expect(find.text('Toutes (2)'), findsOneWidget);
    expect(find.text('En anomalie (1)'), findsOneWidget);
    expect(find.text('Importer les lignes validées (0)'), findsOneWidget);
    expect(find.text('Enregistré'), findsOneWidget);
  });

  testWidgets('le nom reste visible pendant le défilement horizontal',
      (tester) async {
    await _pumpGrid(tester, _FakeUseCase([_row(1, 'Boulangerie Paul')]));

    final double cityBefore =
        tester.getTopLeft(find.byKey(const ValueKey('cell-1-city'))).dx;
    final double nameBefore =
        tester.getTopLeft(find.text('Boulangerie Paul')).dx;

    await tester.drag(
        find.byKey(const ValueKey('cell-1-city')), const Offset(-600, 0));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(find.byKey(const ValueKey('cell-1-city'))).dx,
        lessThan(cityBefore));
    expect(tester.getTopLeft(find.text('Boulangerie Paul')).dx, nameBefore);
  });

  testWidgets('modifier une cellule l\'enregistre aussitôt', (tester) async {
    final _FakeUseCase useCase = _FakeUseCase([_row(1, 'Boulangerie Paul')]);
    await _pumpGrid(tester, useCase);

    await tester.tap(find.text('Lille'));
    await tester.pump();
    expect(find.byType(TextField), findsNWidgets(2)); // recherche + cellule

    await tester.enterText(find.byType(TextField).last, 'Roubaix');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(useCase.patches.single,
        {'row': 1, 'version': 1, 'field': 'city', 'value': 'Roubaix'});
    expect(find.text('Roubaix'), findsOneWidget);
    expect(find.text('Enregistré'), findsOneWidget);
  });

  testWidgets('Tab passe à la cellule voisine, Échap annule', (tester) async {
    final _FakeUseCase useCase = _FakeUseCase([_row(1, 'Boulangerie Paul')]);
    await _pumpGrid(tester, useCase);

    await tester.tap(find.text('Boulangerie Paul'));
    await tester.pumpAndSettle();
    // Le clic rend la ligne courante pour le clavier, mais la saisie va bien
    // au champ ouvert.
    expect(
        tester
            .widget<TextField>(find.byType(TextField).last)
            .focusNode!
            .hasFocus,
        isTrue);
    await tester.enterText(find.byType(TextField).last, 'Paul & Fils');
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();

    // Le nom est enregistré, la cellule suivante (SIRET, le type étant une
    // liste) est en édition.
    expect(useCase.patches.single['field'], 'name');
    expect(find.byType(TextField), findsNWidgets(2));

    await tester.enterText(find.byType(TextField).last, '123');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(useCase.patches, hasLength(1));
  });

  testWidgets('case désactivée tant qu\'il reste une anomalie bloquante',
      (tester) async {
    final _FakeUseCase useCase = _FakeUseCase([
      _row(1, 'Fleuriste', issues: const [
        MerchantImportIssue(
            field: 'siret', level: 'error', message: 'SIRET absent.')
      ]),
    ]);
    await _pumpGrid(tester, useCase);

    Checkbox checkbox() => tester.widget<Checkbox>(find.byType(Checkbox));
    expect(checkbox().onChanged, isNull);

    // Correction du SIRET : la case devient active sans recharger.
    // Le statut dit ce qu'il reste à faire, la cellule vide est signalée.
    expect(find.text('1 à corriger'), findsOneWidget);
    expect(find.text('À renseigner'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('cell-1-siret')));
    await tester.pump();
    await tester.enterText(find.byType(TextField).last, '40305211102616');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(checkbox().onChanged, isNotNull);
    expect(find.text('Prête à valider'), findsOneWidget);
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(
        useCase.patches.last, {'row': 1, 'version': 2, 'status': 'validated'});
    expect(find.text('Importer les lignes validées (1)'), findsOneWidget);
  });

  testWidgets(
      'clavier : ↑ ↓ ligne, Espace valide, E écarte, Entrée modifie, Échap rend la main',
      (tester) async {
    final _FakeUseCase useCase = _FakeUseCase([
      _row(1, 'Boulangerie Paul'),
      _row(2, 'Fleuriste', issues: const [
        MerchantImportIssue(
            field: 'siret', level: 'error', message: 'SIRET absent.')
      ]),
      _row(3, 'Primeur'),
    ]);
    await _pumpGrid(tester, useCase);
    expect(find.text('Raccourcis clavier'), findsOneWidget);

    // Un clic sur une ligne en fait la ligne courante.
    await tester.tap(find.text('Prête à valider').first);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(
        useCase.patches.last, {'row': 1, 'version': 1, 'status': 'validated'});

    // Ligne bloquante : rien n'est envoyé, un message l'explique.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(useCase.patches, hasLength(1));
    expect(find.text('Ligne 2 : à corriger avant validation.'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyE);
    await tester.pumpAndSettle();
    expect(
        useCase.patches.last, {'row': 3, 'version': 1, 'status': 'rejected'});

    // Entrée : édition du nom ; Échap : retour au clavier de la grille.
    final int fields = tester.widgetList(find.byType(TextField)).length;
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNWidgets(fields + 1));
    expect(
        tester.widget<TextField>(find.byType(TextField).last).controller!.text,
        'Boulangerie Paul');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNWidgets(fields));
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(useCase.patches.last, {'row': 1, 'version': 2, 'status': 'pending'});
  });

  testWidgets(
      'avancement, prochaine à corriger (bouton puis N, en boucle), filtre « Complétées par la recherche »',
      (tester) async {
    final _FakeUseCase useCase = _FakeUseCase([
      _row(1, 'Boulangerie Paul'),
      _row(2, 'Fleuriste', issues: const [_noSiret]),
      _row(3, 'Primeur', issues: const [_noSiret]),
      _row(4, 'Caviste', sources: const {'city': 'ia'}),
    ]);
    await _pumpGrid(tester, useCase);
    expect(find.text('Avancement : 0 / 4 lignes traitées'), findsOneWidget);
    expect(find.text('4 à relire'), findsOneWidget);

    Finder editing(int row) => find.descendant(
        of: find.byKey(ValueKey('cell-$row-siret')),
        matching: find.byType(TextField));

    await tester.tap(find.byKey(const ValueKey('next-issue')));
    await tester.pumpAndSettle();
    expect(editing(2), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
    await tester.pumpAndSettle();
    expect(editing(3), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
    await tester.pumpAndSettle();
    expect(editing(2), findsOneWidget, reason: 'retour à la première');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    // Une ligne validée fait avancer la barre.
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    expect(find.text('Avancement : 1 / 4 lignes traitées'), findsOneWidget);

    await tester.tap(find.text('Complétées par la recherche (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Caviste'), findsOneWidget);
    expect(find.text('Boulangerie Paul'), findsNothing);
  });

  testWidgets(
      'le filtre « Complétées par la recherche » est masqué sans valeur',
      (tester) async {
    await _pumpGrid(tester, _FakeUseCase([_row(1, 'Boulangerie Paul')]));
    expect(find.textContaining('Complétées par la recherche'), findsNothing);
    expect(find.byKey(const ValueKey('next-issue')), findsNothing);
  });

  testWidgets('la vue (filtre, recherche, page) est retrouvée et mémorisée',
      (tester) async {
    final _MemoryViewStore store =
        _MemoryViewStore({'filter': 'errors', 'search': '', 'page': 0});
    await _pumpGrid(
        tester,
        _FakeUseCase([
          _row(1, 'Boulangerie Paul'),
          _row(2, 'Fleuriste', issues: const [_noSiret]),
        ]),
        store: store);
    expect(find.text('Fleuriste'), findsOneWidget);
    expect(find.text('Boulangerie Paul'), findsNothing);

    await tester.tap(find.text('Toutes (2)'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(store.saved, {'filter': 'all', 'search': '', 'page': 0});

    await tester.enterText(find.byType(TextField).first, 'boul');
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pumpAndSettle();
    expect(store.saved!['search'], 'boul');
    expect(find.text('Fleuriste'), findsNothing);
  });
}
