/// Motif pour lequel la vue Paiements refuse localement une saisie, avant toute
/// confirmation ou requête.
enum PaymentSubmissionRefusal {
  paymentMethodMissing('Choisissez une méthode de paiement.'),
  exceedsOrderTotal(
      'Le montant saisi dépasse le montant total de la commande.');

  const PaymentSubmissionRefusal(this.message);

  final String message;
}

/// Contrôles locaux de la méthode et du montant d'un paiement saisi. [send]
/// n'est appelé que si la saisie est recevable ; sinon le motif est renvoyé.
///
/// Le plafond est inchangé : somme des paiements + montant <= total de la
/// commande, sans arrondi ni tolérance (l'API refait le contrôle en centimes).
/// Il reste écrit `<=` : un montant `NaN` (« NaN » est lisible par
/// `double.parse`) échoue à la comparaison et reste refusé.
PaymentSubmissionRefusal? submitPaymentIfAcceptable({
  required bool hasPaymentMethod,
  required num sumOfPayments,
  required double amount,
  required num orderTotal,
  required void Function(double amount) send,
}) {
  if (!hasPaymentMethod) return PaymentSubmissionRefusal.paymentMethodMissing;
  if (!((sumOfPayments + amount) <= orderTotal)) {
    return PaymentSubmissionRefusal.exceedsOrderTotal;
  }
  send(amount);
  return null;
}
