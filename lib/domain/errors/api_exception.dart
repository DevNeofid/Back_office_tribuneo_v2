class ApiException implements Exception {
  final String message;

  /// Code machine de l'API (`error.details.code`), quand la vue doit réagir
  /// autrement qu'en affichant le message (ex. recharger les comptes bancaires).
  final String? code;

  /// `error.details` de l'API (ex. `entity_ids` refusés), vide si absent.
  final Map<String, dynamic> details;

  ApiException(this.message, {this.code, this.details = const {}});

  @override
  String toString() => message;
}
