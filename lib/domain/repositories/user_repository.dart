import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:back_office_tribuneo_v2/data/remote/api_client.dart';
import 'package:back_office_tribuneo_v2/domain/models/user_model.dart';

class UserRepository {
  UserModel? userModel;

  ApiClient remoteDataSource = ApiClient();

  Future<UserModel?> login(String login, String password) async {
    try {
      String route = 'login';

      String mobile = login.substring(1);
      mobile = '+33$mobile';

      String data = jsonEncode(<String, String>{
        'mobile': mobile,
        'password': password,
      });

      dynamic response = await remoteDataSource.post(
        route,
        data,
      );

      if (response.statusCode == 200) {
        userModel = UserModel.fromJson(json.decode(response.data));
      } else {
        String error = response.statusCode.toString();
        if (kDebugMode) {
          print("### DEBUG ### -> Error login : $error");
        }
      }
      return userModel;
    } catch (e) {
      if (kDebugMode) {
        print('### DEBUG ### -> UserRepository login : $e');
      }
      return userModel;
    }
  }
}
