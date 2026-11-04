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

  group('EnrichmentMapDialog', () {
    test('projection round trip', () {
      const GeoPoint p = (lat: 44.0925, lng: 6.2356);
      for (final z in [5, 13, 17, 19]) {
        final GeoPoint back = IgnTiles.unproject(IgnTiles.project(p, z), z);
        expect(back.lat, closeTo(p.lat, 1e-9));
        expect(back.lng, closeTo(p.lng, 1e-9));
      }
    });

    /// Ouvre la grande carte ; [result] reçoit son retour.
    Future<void> open(WidgetTester tester, void Function(MapPick?) result,
        {bool editable = true}) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: Builder(
                  builder: (context) => TextButton(
                      onPressed: () async => result(await showDialog<MapPick>(
                          context: context,
                          builder: (_) => EnrichmentMapDialog(
                              proposed: (lat: 44.0925, lng: 6.2356),
                              precision: 'street',
                              editable: editable))),
                      child: const Text('Carte'))))));
      await tester.tap(find.text('Carte'));
      await tester.pumpAndSettle();
    }

    Finder surface() => find.byKey(const ValueKey('map-surface'));

    testWidgets('zoom, drag, recenter, then a tap at the centre picks the spot',
        (tester) async {
      MapPick? result;
      await open(tester, (r) => result = r);
      expect(find.byKey(const ValueKey('mini-map-marker')), findsOneWidget);
      bool zoomShown(int z) =>
          tester.widgetList<Positioned>(find.byType(Positioned)).any((w) =>
              w.key is ValueKey<String> &&
              (w.key as ValueKey<String>).value.startsWith('tile-$z-'));
      expect(zoomShown(17), isTrue);
      await tester.tap(find.byKey(const ValueKey('map-zoom-in')));
      await tester.pumpAndSettle();
      expect(zoomShown(18), isTrue);
      await tester.tap(find.byKey(const ValueKey('map-zoom-out')));
      await tester.pumpAndSettle();

      // Glisser déplace la carte ; « Recentrer » ramène sur la proposition.
      await tester.drag(surface(), const Offset(120, 60));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('map-recenter')));
      await tester.pumpAndSettle();

      final FilledButton use =
          tester.widget(find.widgetWithText(FilledButton, 'Utiliser ce point'));
      expect(use.onPressed, isNull, reason: 'aucun point posé');
      await tester.tapAt(tester.getCenter(surface()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Utiliser ce point'));
      await tester.pumpAndSettle();
      expect(result!.point!.lat, closeTo(44.0925, 1e-4));
      expect(result!.point!.lng, closeTo(6.2356, 1e-4));
    });

    testWidgets('read-only map: no placement', (tester) async {
      await open(tester, (_) {}, editable: false);
      expect(find.text('Position proposée'), findsOneWidget);
      await tester.tapAt(tester.getCenter(surface()));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('map-chosen-marker')), findsNothing);
      expect(find.text('Utiliser ce point'), findsNothing);
    });
  });
}
