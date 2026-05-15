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

  Future<Map<String, dynamic>?> downloadFileInvoice(int id) async {
    return await documentRepository.downloadFileInvoice(id);
  }

  Future downloadFileFees(String transactionNumber) async {
    return await documentRepository.downloadFileFees(transactionNumber);
  }
}
