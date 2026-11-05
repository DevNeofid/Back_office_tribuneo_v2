import 'package:back_office_tribuneo_v2/domain/models/paginated_result.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/initial_route.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/local_search.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/arc/arc.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/assistant/neo_ai_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(
    theme: ArcTheme.light(),
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    supportedLocales: const [Locale('en', 'US'), Locale('fr', 'FR')],
    home: Scaffold(body: Center(child: child)),
  ));
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('recherche locale', () {
    test('searchKey : minuscules, sans accents, espaces réduits', () {
      expect(searchKey('  Écritures   Été  '), 'ecritures ete');
      expect(searchKey(null), '');
    });

    test('matchesSearch : chaque mot dans l\'un des champs', () {
      final fields = ['FAC-2026-0042', 'Boulangerie Dupré', '13/10/2026'];
      expect(matchesSearch('', fields), isTrue);
      expect(matchesSearch('dupre 0042', fields), isTrue);
      expect(matchesSearch('BOULANGERIE', fields), isTrue);
      expect(matchesSearch('dupre 0043', fields), isFalse);
      expect(matchesSearch('x', [null, '']), isFalse);
    });

    test('fetchAllPages : enchaîne les pages jusqu\'à la dernière', () async {
      final List<int> source = List.generate(450, (i) => i);
      final List<int> offsets = [];
      final all = await fetchAllPages<int>((limit, offset) async {
        offsets.add(offset);
        return PaginatedResult(
            items: source.skip(offset).take(limit).toList(),
            total: source.length);
      });
      expect(all, source);
      expect(offsets, [0, 200, 400]);
    });

    test('fetchAllPages : total inconnu, s\'arrête sur une page incomplète',
        () async {
      int calls = 0;
      final all = await fetchAllPages<int>((limit, offset) async {
        calls++;
        return PaginatedResult(
            items: offset == 0 ? List.filled(limit, 1) : [2], total: 0);
      });
      expect(all.length, 201);
      expect(calls, 2);
    });
  });

  testWidgets('showArcDatePicker : libellés français, date initiale bornée',
      (tester) async {
    DateTime? picked;
    await _pump(
        tester,
        Builder(
            builder: (context) => TextButton(
                onPressed: () async => picked = await showArcDatePicker(
                      context,
                      helpText: 'Date de validité',
                      // Avant la borne : ramenée au 10/11/2026.
                      initialDate: DateTime(2020, 1, 1),
                      firstDate: DateTime(2026, 11, 10),
                      lastDate: DateTime(2030),
                    ),
                child: const Text('ouvrir'))));
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();

    expect(find.text('Date de validité'), findsOneWidget);
    expect(find.text('Annuler'), findsOneWidget);
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();
    expect(picked, DateTime(2026, 11, 10));
  });

  testWidgets('ArcLetterBar : une lettre par bouton, lettre active signalée',
      (tester) async {
    String? tapped;
    await _pump(
        tester,
        ArcLetterBar(
            letters: const ['a', 'b', 'c'],
            selected: 'b',
            onSelected: (l) => tapped = l));
    expect(find.text('A'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
    await tester.tap(find.text('C'));
    expect(tapped, 'c');
  });

  testWidgets('menu latéral : toute la carte du compte déconnecte',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    int signOuts = 0;
    await _pump(
        tester,
        ArcSidebar(
          groups: const [],
          selected: '',
          onSelect: (_) {},
          userName: 'Réseau Test',
          onSignOut: () => signOuts++,
        ));
    // Un clic sur le nom (et non sur l'icône) suffit.
    await tester.tap(find.text('Réseau Test'));
    expect(signOuts, 1);
  });

  testWidgets('NeoAiButton : anneau arc-en-ciel fin', (tester) async {
    await _pump(
        tester, NeoAiButton(label: 'Comparer avec Néo', onPressed: () {}));
    final ring =
        tester.widget<Container>(find.byKey(const ValueKey('neo-ai-ring')));
    expect(ring.padding, const EdgeInsets.all(NeoAiButton.ringWidth));
    expect(NeoAiButton.ringWidth, lessThan(2));
  });

  group('démarrage sur la connexion (comme MyApp sans session)', () {
    Widget app({required bool singleStack}) => MaterialApp(
          initialRoute: '/login',
          onGenerateInitialRoutes: singleStack
              ? (_) => singleInitialRoute('/login', (_) => const Text('login'))
              : null,
          routes: {
            '/': (_) => const Text('back-office'),
            '/login': (_) => const Text('login'),
          },
        );

    testWidgets('sans correctif : le back-office est empilé sous la connexion',
        (tester) async {
      await tester.pumpWidget(app(singleStack: false));
      final NavigatorState navigator = tester.state(find.byType(Navigator));
      expect(navigator.canPop(), isTrue);
    });

    testWidgets('retour navigateur : le back-office ne s\'affiche pas',
        (tester) async {
      await tester.pumpWidget(app(singleStack: true));
      expect(find.text('login'), findsOneWidget);
      final NavigatorState navigator = tester.state(find.byType(Navigator));
      expect(navigator.canPop(), isFalse);
      // Rien à dépiler : Flutter laisse le navigateur quitter la page.
      expect(await navigator.maybePop(), isFalse);
      await tester.pumpAndSettle();
      expect(find.text('login'), findsOneWidget);
      expect(find.text('back-office', skipOffstage: false), findsNothing);
    });
  });

  testWidgets('ArcSearchField : cadre de 40 px même si le texte est plus bas',
      (tester) async {
    // Texte réduit : contenu < 40 px, comme Poppins dans le navigateur
    // (le cadre ne faisait alors que 31–34 px, plus bas que les listes).
    await tester.pumpWidget(MaterialApp(
      theme: ArcTheme.light(),
      home: const MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(0.5)),
        child: Scaffold(body: Wrap(children: [ArcSearchField(width: 300)])),
      ),
    ));
    final RenderBox border = tester.renderObject(find
        .descendant(
            of: find.byType(InputDecorator), matching: find.byType(CustomPaint))
        .last);
    expect(border.size.height, 40);
  });

  group('ArcTableCard scrollable (liste des clients)', () {
    // Même structure que l'écran Clients : carte bornée + fiche à droite.
    Widget layout(int rows) => MaterialApp(
          theme: ArcTheme.light(),
          home: Scaffold(
            body: SizedBox(
              height: 700,
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: ArcTableCard(
                    scrollable: true,
                    toolbar: const Text('barre'),
                    footer: const Text('pied'),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Text('en-tête'),
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: rows,
                          itemBuilder: (_, i) =>
                              SizedBox(height: 60, child: Text('client $i')),
                        ),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(width: 380, height: 300, child: Text('fiche')),
              ]),
            ),
          ),
        );

    testWidgets('longue liste : défile dans la carte, la fiche ne bouge pas',
        (tester) async {
      await tester.pumpWidget(layout(100));
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(ArcTableCard)).height,
          lessThanOrEqualTo(700));
      final Offset sheet = tester.getTopLeft(find.text('fiche'));
      await tester.drag(find.text('client 3'), const Offset(0, -1500));
      await tester.pumpAndSettle();
      expect(find.text('client 3'), findsNothing);
      expect(find.text('barre'), findsOneWidget);
      expect(find.text('pied'), findsOneWidget);
      expect(tester.getTopLeft(find.text('fiche')), sheet);
    });

    testWidgets('liste courte : la carte garde sa hauteur naturelle',
        (tester) async {
      await tester.pumpWidget(layout(3));
      expect(tester.getSize(find.byType(ArcTableCard)).height, lessThan(400));
    });
  });

  test('thème : barres de défilement toujours visibles et interactives', () {
    final ScrollbarThemeData theme = ArcTheme.light().scrollbarTheme;
    expect(theme.thumbVisibility?.resolve({}), isTrue);
    expect(theme.interactive, isTrue);
    expect(theme.thickness?.resolve({})!, greaterThanOrEqualTo(8));
  });
}
