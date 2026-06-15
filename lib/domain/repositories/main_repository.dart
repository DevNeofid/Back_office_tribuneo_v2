import 'package:back_office_tribuneo_v2/data/local/storage_model.dart';
import 'package:back_office_tribuneo_v2/domain/repositories/_base_repository.dart';

class MainRepository extends BaseRepository {
  String suffixe = 'auth/token';

  Future<bool> checkToken() async {
    try {
      var response = await apiClient.post(suffixe, null);
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['access_exp'] != null) {
          await storage.writeSecureData(
            StorageItem('jwt_exp', data['access_exp'].toString()),
          );
        }
        return true;
      } else {
        await storageFunction.clearUser();
        return false;
      }
    } catch (e) {
      await storageFunction.clearUser();
      return false;
    }
  }
}
