import 'package:back_office_tribuneo_v2/domain/models/network_model.dart';
import 'package:back_office_tribuneo_v2/domain/repositories/_base_repository.dart';

class NetworkRepository extends BaseRepository {
  Future<List<Network>> getNetworks() async {
    try {
      final response = await apiClient.get('/network');

      if (response.statusCode == 200) {
        final List<dynamic> networkList = response.data['data'];
        return networkList.map((json) => Network.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load networks: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load networks: $e');
    }
  }
}
