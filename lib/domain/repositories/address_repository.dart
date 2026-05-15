import 'dart:convert';
import 'package:back_office_tribuneo_v2/data/remote/api_client.dart';
import 'package:back_office_tribuneo_v2/domain/models/address_model.dart';

class AddressRepository {
  final ApiClient _remoteData = ApiClient();
  final String suffixe = 'address';

  Future<void> addAddress(AddressModel address) async {
    try {
      final String data = jsonEncode(address.toJson());
      final dynamic response = await _remoteData.post(suffixe, data);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return response;
      } else {
        throw Exception(
            "Erreur lors de l'ajout de l'adresse : ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Erreur lors de l'ajout de l'adresse : $e");
    }
  }

  Future<void> updateAddress(AddressModel address) async {
    try {
      final String data = jsonEncode(address.toJson());
      final dynamic response =
          await _remoteData.put(suffixe, data, id: address.id);
      if (response.statusCode == 200) {
        return response;
      } else {
        throw Exception(
            "Erreur lors de la mise à jour de l'adresse : ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Erreur lors de la mise à jour de l'adresse : $e");
    }
  }
}
