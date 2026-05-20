class FormValidator {
  static bool isEmpty(String value) {
    return value.trim().isEmpty;
  }

  static String? validateText(String value) {
    if (value.trim().isEmpty) {
      return '🚩 Texte non valide';
    }
    return null;
  }

  static String? validateMail(String? value) {
    if (value == null || value.isEmpty) {
      return '🚩 Please enter an email address.';
    }
    Pattern pattern =
        r"^[a-zA-Z0-9.!#$%&'+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:.[a-zA-Z0-9-]+)$";
    RegExp regex = RegExp(pattern as String);
    if (!regex.hasMatch(value)) {
      return '🚩 Please enter a valid email address.';
    } else {
      return null;
    }
  }

  static String? validatePhoneNumber(String value) {
    RegExp regex = RegExp(r'^0[1-9]\d{8}$');
    if (!regex.hasMatch(value.trim())) {
      return '🚩 Numéro de mobile non valide';
    }
    return null;
  }

  static String? validatePassword(String value) {
    Pattern pattern = r'^.{4,}$';
    RegExp regex = RegExp(pattern as String);
    if (!regex.hasMatch(value)) {
      return '🚩 Mot de passe non valide';
    }
    return null;
  }

  static String? validateOrderNumber(String value) {
    if (value.trim().length < 10) {
      return '🚩 Numéro de commande non valide';
    }
    return null;
  }

  static String? validateNumberOfFunds(int value) {
    if (value < 1) {
      return '🚩 Le nombre de fond non valide';
    }
    return null;
  }

  static String? validateValueByFund(double value) {
    if (value <= 0) {
      return '🚩 Le montant des fonds non valide';
    }
    return null;
  }

  static String? validateTotalValue(int value) {
    if (value < 1) {
      return '🚩 Le montant total des fonds non valide';
    }
    return null;
  }

  static String? validateOrderDate(String value) {
    RegExp regex = RegExp(r'^\d{2}/\d{2}/\d{4}$');
    if (!regex.hasMatch(value.trim())) {
      return '🚩 Date de commande non valide';
    }
    return null;
  }

  static String? validateSiret(String? value) {
    if (value == null || value.isEmpty) {
      return '🚩 Numéro SIRET incorrect';
    } else if (value.length != 14 || !RegExp(r'^\d{14}$').hasMatch(value)) {
      return '🚩 Numéro SIRET invalide';
    } else {
      return null;
    }
  }

  static String? validateCode(String value) {
    if (value.trim().isEmpty) {
      return '🚩 Code non valide';
    }
    return null;
  }

  static String? validateAccounting(String value) {
    if (value.trim().isEmpty) {
      return '🚩 Code comptable non valide';
    }
    return null;
  }

  static String? validateIntraComNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '🚩 Numéro Intra-Com requis';
    }

    final cleanValue = value.replaceAll(' ', '').toUpperCase();

    final regex = RegExp(r'^FR[A-Z0-9]{2}\d{9}$');

    if (cleanValue.length < 13) {
      return '🚩 Numéro de Intra-Com invalide';
    }
    if (!regex.hasMatch(cleanValue)) {
      return '🚩 Numéro Intra-Com invalide';
    }

    return null;
  }

  static String? validateInt(String value) {
    RegExp regex = RegExp(r'^\d{5}$');
    if (value.trim().isEmpty) {
      return 'Entrez un code postal';
    } else if (!regex.hasMatch(value.trim())) {
      return 'Entrez un code postal valide';
    }
    return null;
  }

  static String? validatePosition(String value) {
    RegExp regex = RegExp(r'^\d+(\.\d+)?$');
    if (value.trim().isEmpty) {
      return 'Entrez une position';
    } else if (!regex.hasMatch(value.trim())) {
      return '🚩 Entrez une position valide';
    }
    return null;
  }

  static String? validateIban(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '🚩 IBAN requis';
    }
    final cleanValue = value.replaceAll(' ', '').toUpperCase();

    final regex = RegExp(r'^[A-Z]{2}\d{2}[A-Z0-9]{1,30}$');

    if (cleanValue.length < 34) {
      return '🚩 Numéro d\'Iban invalide';
    }
    if (!regex.hasMatch(cleanValue)) {
      return '🚩 Numéro IBAN invalide';
    }

    return null;
  }

  static String? validateBic(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '🚩 BIC requis';
    }
    final cleanValue = value.replaceAll(' ', '').toUpperCase();

    final regex = RegExp(r'^[A-Z]{4}[A-Z]{2}[A-Z0-9]{2}([A-Z0-9]{3})?$');

    if (cleanValue.length < 11) {
      return '🚩 Numéro de BIC invalide';
    }
    if (!regex.hasMatch(cleanValue)) {
      return '🚩 Code BIC invalide';
    }

    return null;
  }
}
