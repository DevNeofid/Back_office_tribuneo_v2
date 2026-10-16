import 'package:back_office_tribuneo_v2/domain/models/bto_preview_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/downloaded_file.dart';
import 'package:back_office_tribuneo_v2/domain/models/transfer_order_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/paginated_result.dart';
import 'package:back_office_tribuneo_v2/domain/repositories/transfer_order_repository.dart';

class TransferOrderUseCase {
  final TransferOrderRepository transferOrderRepository =
      TransferOrderRepository();

  Future<PaginatedResult<TransferOrderModel>> getOrders({
    int limit = 10,
    int offset = 0,
  }) async {
    return await transferOrderRepository.getOrders(
        limit: limit, offset: offset);
  }

  Future downloadFile(int id) async {
    return await transferOrderRepository.downloadFile(id);
  }

  Future<BtoPreviewModel> getPreview({String? bankAccountCode}) async {
    return await transferOrderRepository.getPreview(
        bankAccountCode: bankAccountCode);
  }

  /// Pastille du menu : vrai s'il y a au moins une demande prête à être payée.
  Future<bool> hasRefundsToPay() async {
    final BtoPreviewModel preview = await transferOrderRepository.getPreview();
    return preview.totals.requestsToPay > 0;
  }

  Future<void> holdRefund(String transactionNumber, {String? reason}) async {
    return await transferOrderRepository.holdRefund(transactionNumber,
        reason: reason);
  }

  Future<void> releaseRefund(String transactionNumber) async {
    return await transferOrderRepository.releaseRefund(transactionNumber);
  }

  Future<BtoGenerationResult> generate({String? bankAccountCode}) async {
    return await transferOrderRepository.generate(
        bankAccountCode: bankAccountCode);
  }

  Future<DownloadedFile> downloadDocuments(int id) async {
    return await transferOrderRepository.downloadDocuments(id);
  }
}
