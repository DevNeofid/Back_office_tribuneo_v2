import 'dart:convert';
import 'package:back_office_tribuneo_v2/data/remote/api_client.dart';
import 'package:back_office_tribuneo_v2/domain/models/address_model.dart';

class AddressRepository {
  final ApiClient _remoteData = ApiClient();
  final String suffixe = 'address';

  Future addAddress(AddressModel address) async {
    String data = jsonEncode(address.toJson());
    await _remoteData.post(suffixe, data);
    return;
  }

  Future updateAddress(AddressModel address) async {
    String data = jsonEncode(address.toJson());
    await _remoteData.put(suffixe, data, id: address.id);
    return;
  }
}
