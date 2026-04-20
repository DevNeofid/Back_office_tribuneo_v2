import 'package:back_office_tribuneo_v2/domain/models/user_model.dart';
import 'package:back_office_tribuneo_v2/domain/repositories/login_repository.dart';

class LoginUsecase {
  final LoginRepository _loginRepository = LoginRepository();

  Future<UserModel> login(String username, String password) async {
    return await _loginRepository.login(username, password);
  }
}
