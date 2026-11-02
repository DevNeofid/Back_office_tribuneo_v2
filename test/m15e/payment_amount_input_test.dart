import 'package:back_office_tribuneo_v2/presentation/utils/payment_submission_validation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Envoi simulé : remplace l'ouverture de la confirmation (puis la requête),
  // aucune vue, aucun réseau.
  late List<double> sent;
  void send(double amount) => sent.add(amount);

  setUp(() => sent = []);

  PaymentSubmissionRefusal? submit(
    String amountText, {
    bool hasPaymentMethod = true,
    num sumOfPayments = 0,
    num orderTotal = 100,
  }) =>
      submitPaymentIfAcceptable(
        hasPaymentMethod: hasPaymentMethod,
        sumOfPayments: sumOfPayments,
        amountText: amountText,
        orderTotal: orderTotal,
        send: send,
      );

  void expectRefused(String amountText, PaymentSubmissionRefusal refusal) {
    expect(submit(amountText), refusal, reason: 'saisie « $amountText »');
    expect(sent, isEmpty, reason: 'saisie « $amountText »');
  }

  group('montant invalide : refus explicite, rien n\'est envoyé', () {
    test('vide ou espaces seuls', () {
      for (final input in ['', ' ', '   ', '\t']) {
        expectRefused(input, PaymentSubmissionRefusal.invalidAmount);
      }
    });

    test('illisible', () {
      for (final input in ['abc', '12 50', '12€', '12,,5', '1.2.3']) {
        expectRefused(input, PaymentSubmissionRefusal.invalidAmount);
      }
    });

    test('virgule et point mêlés : aucun montant deviné', () {
      for (final input in ['1.234,50', '1,234.50', '12,5.0', '1.2,3']) {
        expectRefused(input, PaymentSubmissionRefusal.invalidAmount);
      }
    });

    test('pas de séparateur de milliers', () {
      for (final input in ['1,234,50', '1 234,50', '1 234,50']) {
        expectRefused(input, PaymentSubmissionRefusal.invalidAmount);
      }
    });

    test('non fini : NaN, Infinity, -Infinity, débordement', () {
      for (final input in ['NaN', 'Infinity', '-Infinity', '1e400']) {
        expectRefused(input, PaymentSubmissionRefusal.invalidAmount);
      }
    });

    test('signalé avant la méthode absente', () {
      expect(submit('abc', hasPaymentMethod: false),
          PaymentSubmissionRefusal.invalidAmount);
      expect(sent, isEmpty);
    });
  });

  group('montant non positif : refus explicite, rien n\'est envoyé', () {
    test('zéro, sous toutes ses écritures', () {
      for (final input in ['0', '0,00', '0.00', '-0', ' 0 ']) {
        expectRefused(input, PaymentSubmissionRefusal.amountNotPositive);
      }
    });

    test('négatif', () {
      for (final input in ['-5', '-0,01', '-12.50']) {
        expectRefused(input, PaymentSubmissionRefusal.amountNotPositive);
      }
    });

    test('signalé avant la méthode absente', () {
      expect(submit('-5', hasPaymentMethod: false),
          PaymentSubmissionRefusal.amountNotPositive);
      expect(sent, isEmpty);
    });
  });

  group('méthode absente et dépassement, sur des saisies lisibles', () {
    test('méthode absente avec une virgule décimale', () {
      expect(submit('12,50', hasPaymentMethod: false),
          PaymentSubmissionRefusal.paymentMethodMissing);
      expect(sent, isEmpty);
    });

    test('dépassement réel avec une virgule décimale', () {
      expect(submit('40,01', sumOfPayments: 60),
          PaymentSubmissionRefusal.exceedsOrderTotal);
      expect(sent, isEmpty);
    });

    test('les quatre motifs ont des messages distincts', () {
      final messages =
          PaymentSubmissionRefusal.values.map((r) => r.message).toSet();
      expect(messages, hasLength(PaymentSubmissionRefusal.values.length));
      expect(PaymentSubmissionRefusal.values, hasLength(4));
    });
  });

  group('saisie recevable : la valeur lue part telle quelle vers la confirmation',
      () {
    test('virgule et point donnent le même montant', () {
      expect(submit('12,50'), isNull);
      expect(submit('12.50'), isNull);
      expect(sent, [12.5, 12.5]);
    });

    test('espaces de bord ignorés', () {
      expect(submit('  12,50 '), isNull);
      expect(submit('\t12.50 '), isNull);
      expect(sent, [12.5, 12.5]);
    });

    test('une seule virgule est décimale, jamais un séparateur de milliers',
        () {
      expect(submit('1,234'), isNull);
      expect(sent, [1.234]);
    });

    test('décimales conservées, ni arrondies ni tronquées', () {
      expect(submit('12,555'), isNull);
      expect(submit('0,001'), isNull);
      expect(sent, [12.555, 0.001]);
    });

    test('solde exact du total avec une virgule', () {
      expect(submit('40,00', sumOfPayments: 60), isNull);
      expect(sent, [40]);
    });

    test('un seul envoi par saisie recevable', () {
      expect(submit('30'), isNull);
      expect(sent, hasLength(1));
      expect(sent.single, 30);
    });
  });
}
