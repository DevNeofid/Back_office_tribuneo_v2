import 'package:back_office_tribuneo_v2/domain/models/bank_informations_model.dart';
import 'package:back_office_tribuneo_v2/domain/repositories/bank_informations_repository.dart';

class BankInformationsUseCase {
  final BankInformationsRepository bankInfoRepository =
      BankInformationsRepository();

  BankInformationsUseCase();

  Future<void> addBankInfo(BankInformationsModel bankInfo) async {
    await bankInfoRepository.addBankInfo(bankInfo);
  }

  Future<void> updateBankInfo(BankInformationsModel bankInfo) async {
    await bankInfoRepository.updateBankInfo(bankInfo);
  }
}
