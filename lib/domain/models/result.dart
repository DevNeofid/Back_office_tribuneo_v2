class Result<T> {
  final bool error;
  final T? data;
  final String? errorMessage;
  

  Result({this.error = false, this.data, this.errorMessage});

  // Constructeur pour un résultat réussi
  Result.success({required this.data})
      : error = false,
        errorMessage = null;

  // Constructeur pour une erreur
  Result.error({required this.errorMessage})
      : error = true,
        data = null;
}