import 'package:back_office_tribuneo_v2/presentation/utils/payment_submission_validation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Envoi simulé : remplace l'ouverture de la confirmation, aucune requête.
  late List<double> sent;
  void send(double amount) => sent.add(amount);

  setUp(() => sent = []);

  PaymentSubmissionRefusal? submit({
    bool hasPaymentMethod = true,
    num sumOfPayments = 0,
    required String amount,
    num orderTotal = 100,
  }) =>
      submitPaymentIfAcceptable(
        hasPaymentMethod: hasPaymentMethod,
        sumOfPayments: sumOfPayments,
        amountText: amount,
        orderTotal: orderTotal,
        send: send,
      );

  group('méthode de paiement absente', () {
    test('montant recevable : refus pour la méthode, rien n\'est envoyé', () {
      expect(submit(hasPaymentMethod: false, amount: '40'),
          PaymentSubmissionRefusal.paymentMethodMissing);
      expect(sent, isEmpty);
    });

    test('montant aussi en dépassement : la méthode est signalée d\'abord',
        () {
      expect(submit(hasPaymentMethod: false, sumOfPayments: 80, amount: '40'),
          PaymentSubmissionRefusal.paymentMethodMissing);
      expect(sent, isEmpty);
    });
  });

  group('dépassement du total de la commande', () {
    test('paiements existants + montant > total : refusé, rien n\'est envoyé',
        () {
      expect(submit(sumOfPayments: 60, amount: '40.01'),
          PaymentSubmissionRefusal.exceedsOrderTotal);
      expect(sent, isEmpty);
    });

    test('aucune tolérance ajoutée sur un léger dépassement', () {
      expect(submit(amount: '100.001'),
          PaymentSubmissionRefusal.exceedsOrderTotal);
      expect(sent, isEmpty);
    });

    test('montant NaN : toujours refusé, comme montant invalide (lot 10)', () {
      expect(submit(amount: 'NaN'), PaymentSubmissionRefusal.invalidAmount);
      expect(sent, isEmpty);
    });
  });

  group('paiement recevable', () {
    test('sous le total : envoyé une fois vers la confirmation, sans motif',
        () {
      expect(submit(sumOfPayments: 20, amount: '30'), isNull);
      expect(sent, [30]);
    });

    test('solde exact du total : toujours accepté', () {
      expect(submit(sumOfPayments: 60, amount: '40'), isNull);
      expect(sent, [40]);
    });
  });
}
