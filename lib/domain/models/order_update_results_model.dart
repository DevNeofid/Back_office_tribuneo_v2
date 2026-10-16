/// Réponses des routes de modification de commande et de date de validité
/// (corrections du 15/10/2026).

/// `PUT /order/{id}` : les bons ne sont plus recréés, seul l'écart est appliqué.
class OrderUpdateResult {
  final int qrcodesCreated;
  final int qrcodesRemoved;

  OrderUpdateResult({this.qrcodesCreated = 0, this.qrcodesRemoved = 0});

  factory OrderUpdateResult.fromJson(Map<String, dynamic> json) {
    return OrderUpdateResult(
      qrcodesCreated: _count(json['qrcodes_created']),
      qrcodesRemoved: _count(json['qrcodes_removed']),
    );
  }
}

/// `PUT /order/{id}/expiry-date`.
class OrderExpiryUpdateResult {
  final String? expiryDate;
  final int vouchersUpdated;
  final int walletsUpdated;

  OrderExpiryUpdateResult(
      {this.expiryDate, this.vouchersUpdated = 0, this.walletsUpdated = 0});

  factory OrderExpiryUpdateResult.fromJson(Map<String, dynamic> json) {
    return OrderExpiryUpdateResult(
      expiryDate: json['expiry_date']?.toString(),
      vouchersUpdated: _count(json['vouchers_updated']),
      walletsUpdated: _count(json['wallets_updated']),
    );
  }
}

/// `PUT /qrcode/{id}`.
class VoucherExpiryUpdateResult {
  final String? previousExpiryDate;
  final String? expiryDate;

  /// Solde du consommateur recalculé : non nul quand on prolonge un bon déjà
  /// expiré et attribué.
  final VoucherWalletUpdate? wallet;

  VoucherExpiryUpdateResult(
      {this.previousExpiryDate, this.expiryDate, this.wallet});

  factory VoucherExpiryUpdateResult.fromJson(Map<String, dynamic> json) {
    final dynamic wallet = json['wallet'];
    return VoucherExpiryUpdateResult(
      previousExpiryDate: json['previous_expiry_date']?.toString(),
      expiryDate: json['expiry_date']?.toString(),
      wallet: wallet is Map
          ? VoucherWalletUpdate.fromJson(Map<String, dynamic>.from(wallet))
          : null,
    );
  }
}

class VoucherWalletUpdate {
  final num oldAmount;
  final num newAmount;

  VoucherWalletUpdate({required this.oldAmount, required this.newAmount});

  factory VoucherWalletUpdate.fromJson(Map<String, dynamic> json) {
    return VoucherWalletUpdate(
      oldAmount: _amount(json['old_amount']),
      newAmount: _amount(json['new_amount']),
    );
  }
}

/// Un compteur (`3`) ou une liste d'identifiants (`[12, 13, 14]`).
int _count(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is List) return value.length;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

num _amount(dynamic value) {
  if (value is num) return value;
  return num.tryParse(value?.toString() ?? '') ?? 0;
}
