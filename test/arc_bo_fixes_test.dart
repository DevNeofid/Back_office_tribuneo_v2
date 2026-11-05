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

  test('thème : barres de défilement toujours visibles et interactives', () {
    final ScrollbarThemeData theme = ArcTheme.light().scrollbarTheme;
    expect(theme.thumbVisibility?.resolve({}), isTrue);
    expect(theme.interactive, isTrue);
    expect(theme.thickness?.resolve({})!, greaterThanOrEqualTo(8));
  });
}
