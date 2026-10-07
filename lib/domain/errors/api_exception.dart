class ApiException implements Exception {
  final String message;

  /// Code machine de l'API (`error.details.code`), quand la vue doit réagir
  /// autrement qu'en affichant le message (ex. recharger les comptes bancaires).
  final String? code;

  ApiException(this.message, {this.code});

  @override
  String toString() => message;
}
