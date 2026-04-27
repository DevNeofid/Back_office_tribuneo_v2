import 'package:back_office_tribuneo_v2/domain/models/network_amount_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/paginated_result.dart';
import 'package:back_office_tribuneo_v2/domain/models/partner_account_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/partner_activated_since_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/partner_total_amount_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/partner_unsettled_balance_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/user_balance_model.dart';
import 'package:back_office_tribuneo_v2/domain/repositories/stats_repository.dart';

class StatsUseCase {
  final StatsRepository statsRepository = StatsRepository();

  StatsUseCase();

  Future<List<UserBalanceModel>> getUsers() async {
    return await statsRepository.getUsers();
  }

  Future<PaginatedResult<UserBalanceModel>> getUsersPaginated({
    int limit = 10,
    int offset = 0,
  }) async {
    return await statsRepository.getUsersPaginated(
      limit: limit,
      offset: offset,
    );
  }

  Future<List<PartnerAccountModel>> getPartnerAcc() async {
    return await statsRepository.getPartnerAcc();
  }

  Future<List<PartnerUnsettledBalanceModel>> getPartnerUnBalance() async {
    return await statsRepository.getPartnerUnBalance();
  }

  Future<List<PartnerActivatedSinceModel>> getPartnerActivated(
      [DateTime? date]) async {
    return await statsRepository.getPartnerActivated(date);
  }

  Future<List<PartnerTotalAmountModel>> getPartnerTotalBalances(
      [DateTime? dateFrom, DateTime? dateTo]) async {
    return await statsRepository.getPartnerTotalBalances(dateFrom, dateTo);
  }

  Future<PaginatedResult<PartnerTotalAmountModel>>
      getPartnerTotalBalancesPaginated(
    DateTime? dateFrom,
    DateTime? dateTo, {
    int limit = 10,
    int offset = 0,
  }) async {
    return await statsRepository.getPartnerTotalBalancesPaginated(
      dateFrom,
      dateTo,
      limit: limit,
      offset: offset,
    );
  }

  Future<List<NetworkTotalAmountModel>> getNetworkTotalAmounts(
      [DateTime? dateFrom, DateTime? dateTo]) async {
    return await statsRepository.getNetworkTotalAmounts(dateFrom, dateTo);
  }
}
