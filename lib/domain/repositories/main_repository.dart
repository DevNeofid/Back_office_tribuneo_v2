import 'package:back_office_tribuneo_v2/data/local/storage_model.dart';
import 'package:back_office_tribuneo_v2/domain/repositories/_base_repository.dart';

class MainRepository extends BaseRepository {
  String suffixe = 'auth/token';

  Future<void> logout() async {
    try {
      await apiClient.post('auth/logout', null);
    } catch (_) {}
    await storageFunction.clearUser();
  }

  Future<bool> checkToken() async {
    try {
      // Si user_id absent, l'utilisateur s'est déconnecté explicitement :
      // on refuse même si les cookies HTTP sont encore valides côté serveur.
      final userId = await storage.readSecureData('user_id');
      if (userId == null || userId.isEmpty) {
        return false;
      }

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
