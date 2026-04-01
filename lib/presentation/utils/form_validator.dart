class FormValidator {
  static bool isEmpty(String value) {
    if (value != '' && value.isNotEmpty) {
      return false;
    } else {
      return true;
    }
  }

  /// Validate Text
  static String? validateText(String value) {
    if (value.isEmpty) {
      return '🚩 Texte non valide';
    } else {
      return null;
    }
  }

  /// Validate Phone Number
  static String? validatePhoneNumber(String value) {
    if (value.length != 10) {
      return '🚩 Numéro de mobile non valide';
    } else {
      return null;
    }
  }

  /// Validate Password
  static String? validatePassword(String value) {
    Pattern pattern = r'^.{4,}$';
    RegExp regex = RegExp(pattern as String);
    if (!regex.hasMatch(value)) {
      return '🚩 Mot de passe non valide';
    } else {
      return null;
    }
  }

  static String validateOrderNumber(String value) {
    if (value.length < 10) {
      return '🚩 Numéro de commande non valide';
    } else {
      return '';
    }
  }

  static String validateNumberOfFunds(int value) {
    // check if the vale

    if (value < 1) {
      return '🚩 Le nombre de fond non valide';
    } else {
      return '';
    }
  }

  static String validateValueByFund(int value) {
    // check if the vale

    if (value < 1) {
      return '🚩 Le montant des fonds non valide';
    } else {
      return '';
    }
  }

  static String validateTotalValue(int value) {
    // check if the vale

    if (value < 1) {
      return '🚩 Le montant total des fonds non valide';
    } else {
      return '';
    }
  }

  static String validateOrderDate(String value) {
    if (value.length != 10) {
      return '🚩 Date de commande non valide';
    } else {
      return '';
    }
  }

  static String validateSiret(String value) {
    if (value.length != 13) {
      return '🚩 Numéro Siret non valide';
    } else {
      return '';
    }
  }

  static String validateCode(String value) {
    if (value.isNotEmpty) {
      return '🚩 Numéro Siret non valide';
    } else {
      return '';
    }
  }

  static String validateAccounting(String value) {
    if (value.isNotEmpty) {
      return '🚩 Numéro Siret non valide';
    } else {
      return '';
    }
  }
  
  static String? validateInt(String value) {
    String pattern = '^[0-9]';
    RegExp regExp = RegExp(pattern);
    if (value.isEmpty) {
          return 'Entrez un code postal';
    }
    else if (!regExp.hasMatch(value)) {
      return 'Entrez un code postal valide';
    }
    return null;
  }

  //validator position
  static String? validatePosition(String value) {
    String pattern = '^[0-9]+(.[0-9]+)?';
    RegExp regExp = RegExp(pattern);
    if (value.isEmpty) {
      return 'Entrez une position';
    }
    else if (!regExp.hasMatch(value)) {
      return '🚩 Entrez une position valide';
    }
    return null;
  }
}
