import 'package:back_office_tribuneo_v2/domain/models/merchant_import_batch_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/merchant_import_row_model.dart';
import 'package:back_office_tribuneo_v2/domain/repositories/merchant_import_repository.dart';

class MerchantImportUseCase {
  final MerchantImportRepository merchantImportRepository =
      MerchantImportRepository();

  Future<MerchantImportBatch> createFromFile({
    required String fileName,
    required String fileBase64,
    String? idempotencyKey,
  }) async {
    return await merchantImportRepository.createFromFile(
        fileName: fileName,
        fileBase64: fileBase64,
        idempotencyKey: idempotencyKey);
  }

  Future<List<MerchantImportBatch>> getBatches(
      {int limit = 20, int offset = 0}) async {
    return await merchantImportRepository.getBatches(
        limit: limit, offset: offset);
  }

  Future<MerchantImportBatch> getBatch(int id) async {
    return await merchantImportRepository.getBatch(id);
  }

  Future<List<MerchantImportRow>> getRows(int id, {String? status}) async {
    return await merchantImportRepository.getRows(id, status: status);
  }

  Future<MerchantImportPatchResult> patchRow(
      int id, int rowId, Map<String, dynamic> body) async {
    return await merchantImportRepository.patchRow(id, rowId, body);
  }

  Future<MerchantImportResult> importValidated(int id,
      {String? idempotencyKey}) async {
    return await merchantImportRepository.importValidated(id,
        idempotencyKey: idempotencyKey);
  }

  Future<void> cancel(int id) async {
    return await merchantImportRepository.cancel(id);
  }
}
