import 'package:back_office_tribuneo_v2/domain/repositories/_base_repository.dart';

class MainRepository extends BaseRepository {
  String suffixe = 'auth/token';

  Future<bool> checkToken() async {
    try {
      var response = await apiClient.post(suffixe, null);
      if (response.statusCode == 200) {
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
