import 'package:back_office_tribuneo_v2/presentation/widgets/assistant/neo_ai_button.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/merchant_enrichment/ui/enrichment_mini_map.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, Widget child,
    {bool reduceMotion = false}) async {
  await tester.pumpWidget(MaterialApp(
      builder: (context, app) => MediaQuery(
          data:
              MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
          child: app!),
      home: Scaffold(body: Center(child: child))));
  await tester.pumpAndSettle();
}

double _rotation(WidgetTester tester) {
  final decoration = tester
      .widget<Container>(find.byKey(const ValueKey('neo-ai-ring')))
      .decoration as BoxDecoration;
  final gradient = decoration.gradient as SweepGradient;
  return (gradient.transform as GradientRotation).radians;
}

void main() {
  group('NeoAiButton', () {
    testWidgets('rainbow ring turns only while hovered', (tester) async {
      var taps = 0;
      await _pump(tester,
          NeoAiButton(label: 'Comparer avec Néo', onPressed: () => taps++));
      expect(find.widgetWithText(OutlinedButton, 'Comparer avec Néo'),
          findsOneWidget);
      expect(_rotation(tester), 0);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.byType(NeoAiButton)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      final double turning = _rotation(tester);
      expect(turning, greaterThan(0));

      await mouse.moveTo(Offset.zero);
      await tester.pumpAndSettle(); // L'animation s'arrête.
      final double stopped = _rotation(tester);
      await tester.pump(const Duration(seconds: 1));
      expect(_rotation(tester), stopped);

      await tester.tap(find.byType(OutlinedButton));
      expect(taps, 1);
    });

    testWidgets('reduced motion: no spin; disabled: plain grey ring',
        (tester) async {
      await _pump(tester, NeoAiButton(label: 'Néo', onPressed: () {}),
          reduceMotion: true);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.byType(NeoAiButton)));
      await tester.pump(const Duration(milliseconds: 600));
      expect(_rotation(tester), 0);

      await _pump(tester, const NeoAiButton(label: 'Néo'));
      final decoration = tester
          .widget<Container>(find.byKey(const ValueKey('neo-ai-ring')))
          .decoration as BoxDecoration;
      expect(decoration.gradient, isNull);
    });
  });

  group('EnrichmentMiniMap', () {
    testWidgets('approximate position: marker, tolerance circle, attribution',
        (tester) async {
      await _pump(
          tester,
          const SizedBox(
              width: 500,
              child: EnrichmentMiniMap(
                  lat: 44.0925, lng: 6.2356, precision: 'street')));
      expect(find.byKey(const ValueKey('mini-map-marker')), findsOneWidget);
      expect(find.byKey(const ValueKey('mini-map-tolerance')), findsOneWidget);
      expect(find.text('© IGN – Plan IGN'), findsOneWidget);
      expect(find.textContaining('environ 150 m'), findsOneWidget);
      expect(find.text('www.geoportail.gouv.fr'), findsOneWidget);
      // Tuiles IGN demandées autour du point, sans erreur si hors ligne.
      final urls = tester
          .widgetList<Image>(find.byType(Image))
          .map((i) => (i.image as NetworkImage).url)
          .toList();
      expect(urls, isNotEmpty);
      expect(urls.every((u) => u.startsWith('https://data.geopf.fr/wmts?')),
          isTrue);
      expect(urls.every((u) => u.contains('TILEMATRIX=16&')), isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('exact address: no tolerance circle', (tester) async {
      await _pump(
          tester,
          const SizedBox(
              width: 400,
              child: EnrichmentMiniMap(
                  lat: 48.8566, lng: 2.3522, precision: 'housenumber')));
      expect(find.byKey(const ValueKey('mini-map-tolerance')), findsNothing);
      expect(find.textContaining('environ'), findsNothing);
    });

    test('displayable coordinates only', () {
      expect(EnrichmentMiniMap.displayable(44.1, 6.2), isTrue);
      expect(EnrichmentMiniMap.displayable(null, 6.2), isFalse);
      expect(EnrichmentMiniMap.displayable('44', 6.2), isFalse);
      expect(EnrichmentMiniMap.displayable(89.9, 6.2), isFalse);
      expect(EnrichmentMiniMap.displayable(double.nan, 6.2), isFalse);
    });
  });
}
