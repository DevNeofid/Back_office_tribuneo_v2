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

  static String? validateValueByFund(int value) {
    if (value < 1) {
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

  static String? validateSiret(String value) {
    RegExp regex = RegExp(r'^\d{14}$');
    if (!regex.hasMatch(value.trim())) {
      return '🚩 Numéro Siret non valide';
    }
    return null;
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
}
