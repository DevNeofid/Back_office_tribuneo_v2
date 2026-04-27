import 'package:back_office_tribuneo_v2/domain/models/invoice_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/paginated_result.dart';
import 'package:back_office_tribuneo_v2/domain/repositories/document_repository.dart';

class DocumentUseCase {
  final DocumentRepository documentRepository = DocumentRepository();

  Future<PaginatedResult<InvoiceModel>> getInvoices(
    String type, {
    int limit = 10,
    int offset = 0,
  }) async {
    return await documentRepository.getInvoices(
      type,
      limit: limit,
      offset: offset,
    );
  }

  Future downloadFileInvoice(int id, {String? prefixe}) async {
    return await documentRepository.downloadFileInvoice(id, prefixe: prefixe);
  }

  Future downloadFileFees(String transactionNumber, {String? prefixe}) async {
    return await documentRepository.downloadFileFees(transactionNumber,
        prefixe: prefixe);
  }
}
