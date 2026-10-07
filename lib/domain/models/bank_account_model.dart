/// Un compte bancaire du réseau, tel que renvoyé par `GET /network/bank-accounts`.
class BankAccountModel {
  /// Identifiant stable du compte : c'est lui qu'on renvoie à l'API.
  final String code;
  final String label;
  final String? holder;
  final String? iban;
  final String? bic;

  /// Compte 512. `null` si le réseau ne génère pas d'écritures.
  final String? accountingNumber;
  final String? journal;

  /// Compte encaisseur par défaut (paiements sans code, anciens paiements).
  final bool isDefault;

  /// Compte qui paie les partenaires.
  final bool isRefund;

  BankAccountModel({
    required this.code,
    required this.label,
    this.holder,
    this.iban,
    this.bic,
    this.accountingNumber,
    this.journal,
    this.isDefault = false,
    this.isRefund = false,
  });

  factory BankAccountModel.fromJson(Map<String, dynamic> json) {
    final String code = json['code']?.toString() ?? '';
    final String label = json['label']?.toString() ?? '';
    return BankAccountModel(
      code: code,
      label: label.isEmpty ? code : label,
      holder: json['holder']?.toString(),
      iban: json['iban']?.toString(),
      bic: json['bic']?.toString(),
      accountingNumber: json['accounting_number']?.toString(),
      journal: json['journal']?.toString(),
      isDefault: json['is_default'] == true,
      isRefund: json['is_refund'] == true,
    );
  }

  /// IBAN groupé par 4 caractères : `FR76 1680 7001 …`.
  String? get formattedIban {
    final String? raw = iban?.replaceAll(' ', '');
    if (raw == null || raw.isEmpty) return null;
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < raw.length; i += 4) {
      if (i > 0) buffer.write(' ');
      buffer.write(raw.substring(i, i + 4 > raw.length ? raw.length : i + 4));
    }
    return buffer.toString();
  }

  /// Libellé d'un select : « libellé — IBAN — compte 512 », sans les parties absentes.
  /// L'IBAN et le 512 sont affichés en clair volontairement : ce sont les comptes du
  /// réseau, vus par ses administrateurs, et les voir sert de contrôle.
  String get selectLabel => [label, formattedIban, accountingNumber]
      .whereType<String>()
      .where((part) => part.isNotEmpty)
      .join(' — ');
}

/// Réponse de `GET /network/bank-accounts` : la liste des comptes et les deux verrous.
/// Toute la logique d'affichage des selects en découle.
class BankAccountsModel {
  /// Triée par `code` par l'API. Peut être vide si le réseau est mal provisionné.
  final List<BankAccountModel> accounts;

  /// Le réseau impose le compte par défaut pour tous les paiements.
  final bool paymentLocked;

  /// Le réseau impose le compte `is_refund` pour tous les virements.
  final bool refundLocked;

  BankAccountsModel({
    required this.accounts,
    this.paymentLocked = false,
    this.refundLocked = false,
  });

  factory BankAccountsModel.fromJson(Map<String, dynamic> json) {
    return BankAccountsModel(
      accounts: (json['accounts'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((account) =>
              BankAccountModel.fromJson(Map<String, dynamic>.from(account)))
          .toList(),
      paymentLocked: json['payment_locked'] == true,
      refundLocked: json['refund_locked'] == true,
    );
  }

  bool get hasSeveralAccounts => accounts.length > 1;

  /// Select (obligatoire) sur la saisie d'un paiement. Sinon on n'envoie rien :
  /// l'API applique elle-même le compte imposé.
  bool get paymentSelectRequired => hasSeveralAccounts && !paymentLocked;

  /// Select sur la génération d'un ordre de virement. Sinon on n'envoie rien :
  /// l'API prend le compte `is_refund`.
  bool get refundSelectRequired => hasSeveralAccounts && !refundLocked;

  BankAccountModel? byCode(String? code) {
    if (code == null) return null;
    for (final account in accounts) {
      if (account.code == code) return account;
    }
    return null;
  }

  BankAccountModel? get defaultAccount {
    for (final account in accounts) {
      if (account.isDefault) return account;
    }
    return null;
  }

  BankAccountModel? get refundAccount {
    for (final account in accounts) {
      if (account.isRefund) return account;
    }
    return null;
  }

  /// Libellé à afficher pour le compte d'un paiement ou d'un ordre de virement.
  /// `null` (enregistrement antérieur à la fonctionnalité) → compte par défaut, c'est
  /// ce que l'API applique. Code absent de la liste (compte supprimé) → code brut.
  String labelForCode(String? code) {
    if (code == null) return defaultAccount?.label ?? '';
    return byCode(code)?.label ?? code;
  }
}
