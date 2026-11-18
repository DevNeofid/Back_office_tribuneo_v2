import 'dart:async';

import 'package:back_office_tribuneo_v2/presentation/widgets/loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final error in [
    Exception('Erreur QR connexion : 400'),
    Exception('Erreur QR réception : 500'),
    TimeoutException('Délai de réponse dépassé'),
  ]) {
    testWidgets('ferme le chargement après $error et permet de réessayer',
        (tester) async {
      var completion = Completer<void>();
      Object? caughtError;
      int successes = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                try {
                  await LoadingDialog.run(context, 'Génération du QR Code...',
                      () => completion.future);
                  successes++;
                } catch (error) {
                  caughtError = error;
                }
              },
              child: const Text('Générer'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Générer'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(LoadingDialog), findsOneWidget);

      completion.completeError(error);
      await tester.pumpAndSettle();
      expect(caughtError, same(error));
      expect(successes, 0);
      expect(find.byType(LoadingDialog), findsNothing);
      expect(find.text('Générer'), findsOneWidget);
      expect(tester.takeException(), isNull);

      completion = Completer<void>();
      await tester.tap(find.text('Générer'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(LoadingDialog), findsOneWidget);
      completion.complete();
      await tester.pumpAndSettle();
      expect(successes, 1);
      expect(find.byType(LoadingDialog), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
