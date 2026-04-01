import 'package:tribuneo_backoffice/domain/models/user_model.dart';
import 'package:tribuneo_backoffice/domain/repositories/login_repository.dart';

class LoginUsecase {
  final LoginRepository _loginRepository = LoginRepository();

  Future<UserModel> login(String username, String password) async {
    return await _loginRepository.login(username, password);
  }
}
