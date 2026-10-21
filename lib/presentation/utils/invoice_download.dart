import 'package:flutter/material.dart';

import 'package:back_office_tribuneo_v2/domain/usecases/document_usecase.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/_global.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/file_downloader.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/loading.dart';

/// Télécharge la facture PDF d'une commande, avec la session de l'utilisateur.
///
/// [fallbackName] : nom du fichier si l'API n'en annonce pas.
Future<void> downloadOrderInvoice(BuildContext context, int idOrder,
    {required String fallbackName}) async {
  try {
    await LoadingDialog.run(context, 'Génération de la facture...', () async {
      final Map<String, dynamic>? result =
          await DocumentUseCase().downloadFileInvoice(idOrder);
      if (result == null) throw Exception('Download failed');
      final List<dynamic> data = result['data'];
      FileDownloader.downloadLargeFile(
          data, result['filename'] ?? fallbackName, 'application/pdf',
          fileExtension: 'pdf');
    });
  } catch (_) {
    snackbarKey.currentState?.showSnackBar(const SnackBar(
        content: Text('Erreur lors de la génération du fichier.')));
  }
}
