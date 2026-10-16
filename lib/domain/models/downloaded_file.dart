/// Fichier binaire renvoyé par l'API, avec le nom annoncé par `Content-Disposition`.
class DownloadedFile {
  final List<int> bytes;

  /// `null` si l'en-tête est absent ou non exposé au navigateur.
  final String? filename;

  DownloadedFile({required this.bytes, this.filename});
}
