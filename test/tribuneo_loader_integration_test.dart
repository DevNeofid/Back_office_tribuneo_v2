import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/loading.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/orders/order_sheet.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/forms/customers/arc_form_panel.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/tribuneo_loader.dart';

void main() {
  testWidgets(
    'boutons : loader compact, actions bloquées pendant la sauvegarde',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const OrderButtonSpinner(),
                ArcSubmitButton(
                  label: 'Enregistrer',
                  busy: true,
                  onPressed: () => fail('action lancée pendant le chargement'),
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.byType(TribuneoLoader), findsNWidgets(2));
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'dialogue : logo présent pendant la tâche et fermeture à sa fin',
    (tester) async {
      final completion = Completer<void>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => LoadingDialog.run(
                  context,
                  'Téléchargement…',
                  () => completion.future,
                ),
                child: const Text('ouvrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('ouvrir'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(TribuneoLoader), findsOneWidget);
      expect(find.text('Téléchargement…'), findsOneWidget);
      completion.complete();
      await tester.pumpAndSettle();
      expect(find.byType(TribuneoLoader), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
