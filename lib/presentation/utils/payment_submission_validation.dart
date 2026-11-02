/// Motif pour lequel la vue Paiements refuse localement une saisie, avant toute
/// confirmation ou requête.
enum PaymentSubmissionRefusal {
  invalidAmount('Saisissez un montant valide, par exemple 12,50 ou 12.50.'),
  amountNotPositive('Le montant doit être supérieur à zéro.'),
  paymentMethodMissing('Choisissez une méthode de paiement.'),
  exceedsOrderTotal(
      'Le montant saisi dépasse le montant total de la commande.');

  const PaymentSubmissionRefusal(this.message);

  final String message;
}

/// Contrôles locaux du montant saisi et de la méthode d'un paiement. [send]
/// n'est appelé que si la saisie est recevable, avec le montant lu ; sinon le
/// motif est renvoyé.
///
/// Le montant doit être lisible, fini et strictement positif (l'API exige
/// `amount > 0`). Il est contrôlé avant la méthode, comme l'était sa lecture.
///
/// Le plafond est inchangé : somme des paiements + montant <= total de la
/// commande, sans arrondi ni tolérance (l'API refait le contrôle en centimes).
PaymentSubmissionRefusal? submitPaymentIfAcceptable({
  required bool hasPaymentMethod,
  required num sumOfPayments,
  required String amountText,
  required num orderTotal,
  required void Function(double amount) send,
}) {
  // Virgule décimale française acceptée. double.tryParse ignore les espaces de
  // bord et refuse deux points : « 1.234,50 » ou « 1,234.50 » ne sont pas lus
  // plutôt que de deviner un séparateur de milliers. Il lit en revanche « NaN »
  // et « Infinity ».
  final double? amount = double.tryParse(amountText.replaceAll(',', '.'));
  if (amount == null || !amount.isFinite) {
    return PaymentSubmissionRefusal.invalidAmount;
  }
  if (amount <= 0) return PaymentSubmissionRefusal.amountNotPositive;
  if (!hasPaymentMethod) return PaymentSubmissionRefusal.paymentMethodMissing;
  if (!((sumOfPayments + amount) <= orderTotal)) {
    return PaymentSubmissionRefusal.exceedsOrderTotal;
  }
  send(amount);
  return null;
}
