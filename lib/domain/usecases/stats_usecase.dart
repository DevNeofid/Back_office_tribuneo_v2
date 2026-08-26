import 'package:back_office_tribuneo_v2/domain/models/all_infos_customer_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/all_infos_partner_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/digital_partner_no_activity_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/network_amount_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/paginated_result.dart';
import 'package:back_office_tribuneo_v2/domain/models/partner_account_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/partner_activated_since_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/partner_digital_never_open_session_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/partner_total_amount_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/partner_unsettled_balance_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/qr_code_status_by_user_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/sum_expired_vouchers_consumer_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/technical_support_order_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/user_balance_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/voucher_total_balance_per_customer_model.dart';
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

  Future<String?> getUsersPaginatedCsv({
    int limit = 10,
    int offset = 0,
  }) async {
    return await statsRepository.getUsersPaginatedCsv(
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

  Future<String?> getPartnerTotalBalancesCsv(
    DateTime? dateFrom,
    DateTime? dateTo, {
    int limit = 10,
    int offset = 0,
  }) async {
    return await statsRepository.getPartnerTotalBalancesCsv(
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

  Future<String?> getNetworkTotalAmountsCsv(
      [DateTime? dateFrom, DateTime? dateTo]) async {
    return await statsRepository.getNetworkTotalAmountsCsv(
      dateFrom,
      dateTo,
    );
  }

  Future<PaginatedResult<VoucherTotalBalancePerCustomerModel>>
      getVoucherTotalBalancesPerCustomerPaginated({
    int limit = 10,
    int offset = 0,
  }) async {
    return await statsRepository.getVoucherTotalBalancesPerCustomerPaginated(
      limit: limit,
      offset: offset,
    );
  }

  Future<String?> getVoucherTotalBalancesPerCustomerCsv({
    int limit = 10,
    int offset = 0,
  }) async {
    return await statsRepository.getVoucherTotalBalancesPerCustomerCsv(
      limit: limit,
      offset: offset,
    );
  }

  Future<PaginatedResult<PartnerDigitalNeverOpenSessionModel>>
      getPartnerDigitalNeverOpenSessionPaginated({
    int limit = 10,
    int offset = 0,
  }) async {
    return await statsRepository.getPartnerDigitalNeverOpenSessionPaginated(
      limit: limit,
      offset: offset,
    );
  }

  Future<String?> getPartnerDigitalNeverOpenSessionCsv({
    int limit = 10,
    int offset = 0,
  }) async {
    return await statsRepository.getPartnerDigitalNeverOpenSessionCsv(
      limit: limit,
      offset: offset,
    );
  }

  Future<PaginatedResult<SumExpiredVouchersConsumerModel>>
      getSumExpiredVouchersConsumerPaginated({
    DateTime? dateFrom,
    DateTime? dateTo,
    int limit = 10,
    int offset = 0,
  }) async {
    return await statsRepository.getSumExpiredVouchersConsumerPaginated(
      dateFrom: dateFrom,
      dateTo: dateTo,
      limit: limit,
      offset: offset,
    );
  }

  Future<String?> getSumExpiredVouchersConsumerCsv({
    DateTime? dateFrom,
    DateTime? dateTo,
    int limit = 10,
    int offset = 0,
  }) async {
    return await statsRepository.getSumExpiredVouchersConsumerCsv(
      dateFrom: dateFrom,
      dateTo: dateTo,
      limit: limit,
      offset: offset,
    );
  }

  Future<PaginatedResult<DigitalPartnerNoActivityModel>>
      getDigitalPartnerNoActivityPaginated({
    int limit = 10,
    int offset = 0,
  }) async {
    return await statsRepository.getDigitalPartnerNoActivityPaginated(
      limit: limit,
      offset: offset,
    );
  }

  Future<String?> getDigitalPartnerNoActivityCsv({
    int limit = 10,
    int offset = 0,
  }) async {
    return await statsRepository.getDigitalPartnerNoActivityCsv(
      limit: limit,
      offset: offset,
    );
  }

  Future<PaginatedResult<AllInfosPartnerModel>> getAllInfosPartnersPaginated({
    int limit = 10,
    int offset = 0,
  }) async {
    return await statsRepository.getAllInfosPartnersPaginated(
      limit: limit,
      offset: offset,
    );
  }

  Future<String?> getAllInfosPartnersCsv({
    int limit = 10,
    int offset = 0,
  }) async {
    return await statsRepository.getAllInfosPartnersCsv(
      limit: limit,
      offset: offset,
    );
  }

  Future<PaginatedResult<AllInfosCustomerModel>>
      getAllInfosCustomersPaginated({
    int limit = 10,
    int offset = 0,
  }) async {
    return await statsRepository.getAllInfosCustomersPaginated(
      limit: limit,
      offset: offset,
    );
  }

  Future<String?> getAllInfosCustomersCsv({
    int limit = 10,
    int offset = 0,
  }) async {
    return await statsRepository.getAllInfosCustomersCsv(
      limit: limit,
      offset: offset,
    );
  }

  Future<PaginatedResult<TechnicalSupportOrderModel>>
      getTechnicalSupportOrdersPaginated(
    DateTime? dateFrom,
    DateTime? dateTo, {
    int limit = 10,
    int offset = 0,
  }) async {
    return await statsRepository.getTechnicalSupportOrdersPaginated(
      dateFrom,
      dateTo,
      limit: limit,
      offset: offset,
    );
  }

  Future<String?> getTechnicalSupportOrdersCsv(
    DateTime? dateFrom,
    DateTime? dateTo, {
    int limit = 10,
    int offset = 0,
  }) async {
    return await statsRepository.getTechnicalSupportOrdersCsv(
      dateFrom,
      dateTo,
      limit: limit,
      offset: offset,
    );
  }

  Future<PaginatedResult<QrCodeStatusByUserModel>>
      getAllQrCodeStatusByUserInfosPaginated({
    String? email,
    String? firstname,
    String? lastname,
    String? mobile,
    int limit = 10,
    int offset = 0,
  }) async {
    return await statsRepository.getAllQrCodeStatusByUserInfosPaginated(
      email: email,
      firstname: firstname,
      lastname: lastname,
      mobile: mobile,
      limit: limit,
      offset: offset,
    );
  }

  Future<String?> getAllQrCodeStatusByUserInfosCsv({
    String? email,
    String? firstname,
    String? lastname,
    String? mobile,
    int limit = 10,
    int offset = 0,
  }) async {
    return await statsRepository.getAllQrCodeStatusByUserInfosCsv(
      email: email,
      firstname: firstname,
      lastname: lastname,
      mobile: mobile,
      limit: limit,
      offset: offset,
    );
  }
}
