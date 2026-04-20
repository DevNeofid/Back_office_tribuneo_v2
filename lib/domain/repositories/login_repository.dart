import 'dart:convert';

import 'package:back_office_tribuneo_v2/data/remote/api_client.dart';
import 'package:back_office_tribuneo_v2/domain/models/user_model.dart';
import 'package:back_office_tribuneo_v2/domain/repositories/_base_repository.dart';
import 'package:back_office_tribuneo_v2/domain/models/login_model.dart';
import 'package:back_office_tribuneo_v2/domain/errors/api_exception.dart';
import 'package:back_office_tribuneo_v2/data/local/storage_model.dart';

class LoginRepository extends BaseRepository {
  final ApiClient _remoteData = ApiClient();
  String suffixe = 'auth/login';

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

    LoginRequestModel loginRequestModel = LoginRequestModel.fromJson({
      "username": replaceWithCountryCode(username),
      "password": password,
    });
    String data = jsonEncode(loginRequestModel);

    try {
      var response = await _remoteData.post(suffixe, data);
      if (response.statusCode == 200) {
        final Map<String, dynamic> dataMap = Map<String, dynamic>.from(
          response.data['data'] as Map,
        );
        if (dataMap['user'] is! Map) {
          throw ApiException('Profil utilisateur manquant dans la réponse');
        }

        int? idNetwork;
        if (dataMap.containsKey('userFunds') &&
            (dataMap['userFunds'] as List).isNotEmpty) {
          idNetwork = ((dataMap['userFunds'] as List)[0]['id_network'] as num?)
              ?.toInt();
        }

        final Map<String, dynamic> userData = Map<String, dynamic>.from(
          dataMap['user'] as Map,
        );

        final int? idEntity = (dataMap['id_entity'] as num?)?.toInt();
        if (idEntity != null) {
          userData['id_entity'] = idEntity;
          await storage.writeSecureData(
            StorageItem('id_entity', idEntity.toString()),
          );
        }

        if (dataMap.containsKey('role') && dataMap['role'] != null) {
          userData['role'] = dataMap['role'];
        }

        await storageFunction.saveLogin(username);
        await storageFunction.saveUser(userData);

        if (idNetwork != null) {
          await storageFunction.saveUserIdNetwork(idNetwork.toString());
        }

        return UserModel.fromJson(userData);
      } else {
        throw ApiException(
          'Connexion échouée, veuillez réessayer avec des identifiants valides',
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        'Une erreur s\'est produite lors de la connexion: ${e.toString()}',
      );
    }
  }
}
