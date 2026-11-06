import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/tribuneo_loader.dart';

Future<List<int>> pixels(WidgetTester tester, double size) async {
  final painter = tester
      .widget<CustomPaint>(
        find.descendant(
          of: find.byType(TribuneoLoader),
          matching: find.byType(CustomPaint),
        ),
      )
      .painter!;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..scale(4);
  painter.paint(canvas, Size.square(size));
  final picture = recorder.endRecording();
  final result = await tester.runAsync(() async {
    final image = await picture.toImage((size * 4).round(), (size * 4).round());
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    return data!.buffer.asUint8List().toList();
  });
  picture.dispose();
  return result!;
}

int colorCount(List<int> data, List<int> color) {
  int count = 0;
  for (int i = 0; i < data.length; i += 4) {
    if (data[i] == color[0] &&
        data[i + 1] == color[1] &&
        data[i + 2] == color[2] &&
        data[i + 3] > 240) {
      count++;
    }
  }
  return count;
}

Future<void> pumpLoader(
  WidgetTester tester, {
  double size = 48,
  bool reduced = false,
}) async {
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: MediaQueryData(disableAnimations: reduced),
        child: Center(child: TribuneoLoader(size: size)),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  for (final size in [14.0, 18.0, 48.0]) {
    testWidgets(
      'les deux points restent visibles aux changements de sens à $size px',
      (tester) async {
        await pumpLoader(tester, size: size);
        int previous = 0;
        // Début/fin de boucle, voisinage des anciens clignotements bleu et orange.
        for (final frame in [
          0,
          1,
          59,
          60,
          61,
          119,
          120,
          121,
          123,
          124,
          125,
          179,
          180,
          239,
          240,
        ]) {
          await tester.pump(
            Duration(microseconds: ((frame - previous) * 1000000 / 60).round()),
          );
          previous = frame;
          final data = await pixels(tester, size);
          expect(
            colorCount(data, [58, 66, 118]),
            greaterThan(10),
            reason: 'point bleu, image $frame',
          );
          expect(
            colorCount(data, [247, 169, 53]),
            greaterThan(10),
            reason: 'point orange, image $frame',
          );
          expect(tester.takeException(), isNull);
        }
        await tester.pumpWidget(const SizedBox.shrink());
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'le cycle revient à la même image après exactement quatre secondes',
    (tester) async {
      await pumpLoader(tester);
      final first = await pixels(tester, 48);
      await tester.pump(const Duration(seconds: 4));
      expect(await pixels(tester, 48), orderedEquals(first));
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('réduire les animations affiche le logo complet sans ticker', (
    tester,
  ) async {
    await pumpLoader(tester, reduced: true);
    final first = await pixels(tester, 48);
    expect(colorCount(first, [58, 66, 118]), greaterThan(1000));
    expect(colorCount(first, [247, 169, 53]), greaterThan(1000));
    await tester.pump(const Duration(seconds: 2));
    expect(await pixels(tester, 48), orderedEquals(first));
    expect(tester.binding.hasScheduledFrame, isFalse);
    // Réactiver l'animation sur le même widget reprend le mouvement.
    await pumpLoader(tester);
    await tester.pump(const Duration(milliseconds: 400));
    expect(await pixels(tester, 48), isNot(orderedEquals(first)));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('progression déterminée : pourcentage visible et accessible', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: TribuneoLoadingProgress(value: 0.42)),
      ),
    );
    expect(find.text('42 %'), findsOneWidget);
    expect(find.byType(TribuneoLoader), findsOneWidget);
    expect(find.bySemanticsLabel('Chargement'), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Chargement')).value,
      '42 %',
    );
    await tester.pumpWidget(const SizedBox.shrink());
    semantics.dispose();
  });

  testWidgets('une tâche terminée conserve son pourcentage sans animation',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: TribuneoLoadingProgress(value: 0.5, animate: false))));
    await tester.pumpAndSettle();
    expect(find.text('50 %'), findsOneWidget);
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: TribuneoLoadingProgress(value: 0.5))));
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('capture du rendu Flutter du loader', (tester) async {
    const directory = String.fromEnvironment('TRIBUNEO_LOADER_CAPTURE_DIR');
    if (directory.isEmpty) return;
    await pumpLoader(tester, size: 160);
    await tester.pump(const Duration(milliseconds: 2017));
    final painter = tester
        .widget<CustomPaint>(
          find.descendant(
            of: find.byType(TribuneoLoader),
            matching: find.byType(CustomPaint),
          ),
        )
        .painter!;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawColor(Colors.white, BlendMode.src);
    canvas.translate(40, 40);
    painter.paint(canvas, const Size.square(160));
    final picture = recorder.endRecording();
    await tester.runAsync(() async {
      final image = await picture.toImage(240, 240);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory(directory).create(recursive: true);
      await File(
        '$directory/loader-back_office_tribuneo_v2.png',
      ).writeAsBytes(data!.buffer.asUint8List());
      image.dispose();
    });
    picture.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
