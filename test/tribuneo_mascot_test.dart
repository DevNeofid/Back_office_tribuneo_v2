import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/assistant/tribuneo_mascot.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/assistant/assistant_avatar.dart';

void main() {
  testWidgets('avatars lisibles aux trois tailles et sans animation continue',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Center(
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          AssistantAvatar(size: 24),
          AssistantAvatar(size: 32),
          AssistantAvatar(size: 56),
        ]),
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(tester.binding.hasScheduledFrame, isFalse);
    for (final mascot
        in tester.widgetList<TribuneoMascot>(find.byType(TribuneoMascot))) {
      expect(mascot.showHand, isFalse);
    }
    for (var i = 0; i < 3; i++) {
      final size = [24.0, 32.0, 56.0][i];
      expect(tester.getSize(find.byType(AssistantAvatar).at(i)),
          Size.square(size));
    }
  });

  testWidgets('anime les trois états et libère le ticker au démontage',
      (tester) async {
    for (final mood in TribuneoMascotMood.values) {
      await tester.pumpWidget(MaterialApp(
        home: Center(child: TribuneoMascot(mood: mood)),
      ));
      await tester.pump(const Duration(milliseconds: 750));
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(TribuneoMascot)), const Size(240, 200));
      expect(tester.binding.hasScheduledFrame, isTrue);
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('respecte la réduction des animations et reprend si désactivée',
      (tester) async {
    Future<void> show(bool reduceMotion) => tester.pumpWidget(MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduceMotion),
            child: const Center(
                child: TribuneoMascot(mood: TribuneoMascotMood.thinking)),
          ),
        ));
    await show(true);
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
    await show(false);
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.binding.hasScheduledFrame, isTrue);
    await show(true);
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(tester.takeException(), isNull);
  });
}
