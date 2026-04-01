import 'dart:convert';
import 'package:tribuneo_backoffice/data/local/local_data_helper.dart';
import 'package:tribuneo_backoffice/data/remote/remote_data_source.dart';
import 'package:tribuneo_backoffice/domain/models/address_model.dart';

class AddressRepository {
  final RemoteDataSource _remoteData = RemoteDataSource();
  LocalDataHelper localDataHelper = LocalDataHelper();
  final String suffixe = 'address';

  // Function to add a new customer
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
