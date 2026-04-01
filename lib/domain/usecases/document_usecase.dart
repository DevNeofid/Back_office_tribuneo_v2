import 'package:tribuneo_backoffice/domain/models/invoice_model.dart';
import 'package:tribuneo_backoffice/domain/repositories/document_repository.dart';

class DocumentUseCase {
  final DocumentRepository documentRepository = DocumentRepository();

  Future<List<InvoiceModel>> getInvoices(String type) async {
    return await documentRepository.getInvoices(type);
  }

  Future downloadFileInvoice(int id ,{String? prefixe}) async {
    return await documentRepository.downloadFileInvoice(id, prefixe: prefixe);
  }

  Future downloadFileFees(String transactionNumber ,{String? prefixe}) async {
    return await documentRepository.downloadFileFees(transactionNumber, prefixe: prefixe);
  }
}
