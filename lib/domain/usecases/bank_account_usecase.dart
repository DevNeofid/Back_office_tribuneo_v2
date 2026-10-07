import 'package:back_office_tribuneo_v2/domain/models/bank_account_model.dart';
import 'package:back_office_tribuneo_v2/domain/repositories/bank_account_repository.dart';

class BankAccountUseCase {
  final BankAccountRepository bankAccountRepository = BankAccountRepository();

  Future<BankAccountsModel> getBankAccounts() async {
    return await bankAccountRepository.getBankAccounts();
  }
}
