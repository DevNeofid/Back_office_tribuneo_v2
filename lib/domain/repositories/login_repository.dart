import 'dart:convert';

import 'package:tribuneo_backoffice/data/local/local_data_helper.dart';
import 'package:tribuneo_backoffice/data/remote/remote_data_source.dart';
import 'package:tribuneo_backoffice/domain/models/user_model.dart';

class LoginRepository {
  final RemoteDataSource _remoteDataSource = RemoteDataSource();
  String suffixe = 'login';

  LoginRepository();

  Future<UserModel> login(String username, String password) async {
    bool containsOnlyDigits(String input) {
      return input.runes.every((char) => char >= 48 && char <= 57);
    }

    String replaceWithCountryCode(String input) {
      if (containsOnlyDigits(input)) {
        return "+33${input.substring(1)}";
      }
      return input;
    }

    String data = jsonEncode(<String, dynamic>{
      'username': replaceWithCountryCode(username),
      'password': password,
    });
    dynamic response = await _remoteDataSource.post(suffixe, data);

    if (response.statusCode == 200) {
      UserModel user = UserModel.fromJson(jsonDecode(response.data));
      // Enregistrez le token dans Hive
      LocalDataHelper localDataHelper = LocalDataHelper();
      await localDataHelper.update('token', 0, user.token!);

      return user;
    } else {
      throw Exception('Erreur lors de la connexion');
    }
  }
}
