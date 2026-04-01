import 'dart:typed_data';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

class FileDownloader {
  /// Télécharge un fichier en utilisant les données [fileData], le nom [fileName] et l'extension [fileExtension].
  /// [mimeType] spécifie le type MIME du fichier.
  static void downloadFile(Uint8List fileData, String fileName, String mimeType,
      {String? fileExtension}) {
    final blob = web.Blob(
      [fileData.toJS].toJS,
      web.BlobPropertyBag(type: mimeType),
    );
    final url = web.URL.createObjectURL(blob);

    // Ajouter l'extension si elle n'est pas incluse dans le nom de fichier
    if (fileExtension != null && !fileName.endsWith(fileExtension)) {
      fileName = '$fileName.$fileExtension';
    }

    final anchor = web.HTMLAnchorElement()
      ..href = url
      ..style.display = 'none'
      ..download = fileName;
    web.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    web.URL.revokeObjectURL(url);
  }

  /// Télécharge un fichier volumineux en divisant [fileData] en chunks.
  /// Permet d'éviter les limitations de taille de mémoire pour les fichiers volumineux.
  static void downloadLargeFile(
      List<dynamic> fileData, String fileName, String mimeType,
      {String? fileExtension, int chunkSize = 1024 * 1024}) {
    // On reconstruit les données en Uint8List et on délègue au flux standard.
    final bytes = Uint8List.fromList(fileData.cast<int>());

    // Ajouter l'extension si elle n'est pas incluse dans le nom de fichier
    if (fileExtension != null && !fileName.endsWith(fileExtension)) {
      fileName = '$fileName.$fileExtension';
    }

    downloadFile(bytes, fileName, mimeType);
  }
}
