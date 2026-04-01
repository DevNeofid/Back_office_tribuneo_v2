import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:tribuneo_backoffice/data/remote/remote_data_source.dart';
import 'package:tribuneo_backoffice/domain/models/user_model.dart';

class UserRepository {
  UserModel? userModel;

  RemoteDataSource remoteDataSource = RemoteDataSource();

  Future<UserModel?> login(String login, String password) async {
    try {
      String route = 'login';

      String mobile = login.substring(1);
      mobile = '+33$mobile';

      String data = jsonEncode(<String, String>{
        'mobile': mobile,
        'password': password,
      });

      // print("### DEBUG ### -> mobile: $mobile");
      // print("### DEBUG ### -> password: $password");
      // print("### DEBUG ### -> data: $data");

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
