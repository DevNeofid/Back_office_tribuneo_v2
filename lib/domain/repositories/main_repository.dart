import 'package:tribuneo_backoffice/data/local/local_data_helper.dart';
import 'package:tribuneo_backoffice/data/remote/remote_data_source.dart';
import 'package:hive_flutter/hive_flutter.dart';

class MainRepository {
  final RemoteDataSource _remoteData = RemoteDataSource();
  LocalDataHelper localDataHelper = LocalDataHelper();
  String suffixe = 'auth_check';
  // Function for adding a new order
  Future<void> syncData() async {

    // const String ordersSuffixe = 'order';
    // const String entitySuffixe = 'entity';

    // Map<String, String> qsP = {
    //   'entity_type': 'partner',
    // };
    // Map<String, String> qsC = {
    //   'entity_type': 'customer',
    // };
  }

  Future<bool> authCheck(String token) async {
    final response = await _remoteData.get(suffixe, token: token);
    try{
      if (response.statusCode == 200) {
        return true;
      } else {
        final tokenBox = await Hive.openBox('tokenBox');
        await tokenBox.delete('token');
        return false;
      }
    }
    catch(e){
      final tokenBox = await Hive.openBox('tokenBox');
      await tokenBox.delete('token');
      return false;
    }
  }
}