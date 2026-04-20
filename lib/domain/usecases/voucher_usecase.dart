import 'package:back_office_tribuneo_v2/domain/repositories/voucher_repository.dart';

class VoucherUseCase {
  final VoucherRepository repository = VoucherRepository();

  Future getVouchers() async {
    return await repository.getVouchers();
  }

  Future putVoucher(dynamic voucher, dynamic data) async {
    return await repository.putVoucher(voucher, data);
  }
}
