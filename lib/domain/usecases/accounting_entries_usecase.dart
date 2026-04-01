import 'package:tribuneo_backoffice/domain/models/accounting_entries_model.dart';
import 'package:tribuneo_backoffice/domain/repositories/accounting_entries_repository.dart';

class AccountingEntriesUseCase {
  final AccountingEntriesRepository accountingEntriesRepository = AccountingEntriesRepository();

  Future createAccountingEntries() async {
    return await accountingEntriesRepository.createAccountingEntries();
  }

  Future<List<AccountingEntriesModel>> getAccountingEntries() async {
    return await accountingEntriesRepository.getAccountingEntries();
  }

  Future downloadFile(int id) async {
    return await accountingEntriesRepository.downloadFile(id);
  }
}