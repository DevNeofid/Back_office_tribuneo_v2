import 'package:back_office_tribuneo_v2/domain/models/accounting_entries_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/paginated_result.dart';
import 'package:back_office_tribuneo_v2/domain/repositories/accounting_entries_repository.dart';

class AccountingEntriesUseCase {
  final AccountingEntriesRepository accountingEntriesRepository =
      AccountingEntriesRepository();

  Future createAccountingEntries() async {
    return await accountingEntriesRepository.createAccountingEntries();
  }

  Future<PaginatedResult<AccountingEntriesModel>> getAccountingEntries({
    int limit = 10,
    int offset = 0,
  }) async {
    return await accountingEntriesRepository.getAccountingEntries(
      limit: limit,
      offset: offset,
    );
  }

  Future downloadFile(int id) async {
    return await accountingEntriesRepository.downloadFile(id);
  }
}
