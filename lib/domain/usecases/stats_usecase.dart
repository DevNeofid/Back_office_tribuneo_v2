import 'package:tribuneo_backoffice/domain/models/partner_account_model.dart';
import 'package:tribuneo_backoffice/domain/models/partner_activated_since_model.dart';
import 'package:tribuneo_backoffice/domain/models/partner_unsettled_balance_model.dart';
import 'package:tribuneo_backoffice/domain/models/user_balance_model.dart';
import 'package:tribuneo_backoffice/domain/repositories/stats_repository.dart';

class StatsUseCase {
  final StatsRepository addressRepository = StatsRepository();

  StatsUseCase();

  Future<List<UserBalanceModel>> getUsers() async {
    return await addressRepository.getUsers();
  }

  Future<List<PartnerAccountModel>> getPartnerAcc() async {
    return await addressRepository.getPartnerAcc();
  }

  Future<List<PartnerUnsettledBalanceModel>> getPartnerUnBalance() async {
    return await addressRepository.getPartnerUnBalance();
  }

  Future<List<PartnerActivatedSinceModel>> getPartnerActivated(
      [DateTime? date]) async {
    return await addressRepository.getPartnerActivated(date);
  }
}
