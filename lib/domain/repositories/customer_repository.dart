import 'dart:convert';
import 'package:back_office_tribuneo_v2/domain/repositories/_base_repository.dart';
import 'package:back_office_tribuneo_v2/data/remote/api_client.dart';
import 'package:back_office_tribuneo_v2/domain/models/entity_model.dart';

class CustomerRepository extends BaseRepository {
  final ApiClient _remoteData = ApiClient();
  final String suffixe = 'entity';

  static const int allCustomersKey = 0;
  static const int mapEntitiesKey = 1;

  Future<Map<int, dynamic>> getCustomers() async {
    String tenant = await getTenantForCurrentNetwork();
    dynamic response = await _remoteData.get(suffixe,
        queryParams: {
          'entity_type': 'customer',
          'full_infos': 'true',
          'sorted_by_letter': 'true'
        },
        overrideTenant: tenant);

    if (response.statusCode != 200) {
      throw Exception(
          'Erreur lors de la récupération des clients (Code ${response.statusCode})');
    }

    Map<String, List<EntityModel>> mapEntities = {};
    List<EntityModel> allCustomers = [];
    Map<String, dynamic> itemsMap = response.data['data']['items'];

    itemsMap.forEach((letterKey, customersList) {
      List<EntityModel> letterCustomers = [];
      for (var customerJson in customersList) {
        EntityModel p = EntityModel.fromJson(customerJson);
        letterCustomers.add(p);
        allCustomers.add(p);
      }
      mapEntities[letterKey] = letterCustomers;
    });

    return {
      allCustomersKey: allCustomers,
      mapEntitiesKey: mapEntities,
    };
  }

  Future addCustomer(EntityModel customer) async {
    String data = jsonEncode(customer.toJson());
    String tenant = await getTenantForCurrentNetwork();
    dynamic response =
        await _remoteData.post(suffixe, data, overrideTenant: tenant);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
          'Erreur lors de l\'ajout du client (Code ${response.statusCode}) : ${response.data}');
    }
    return response.data;
  }

  Future updateCustomer(EntityModel customer) async {
    String data = jsonEncode(customer.toJson());
    String tenant = await getTenantForCurrentNetwork();
    dynamic response = await _remoteData.put(suffixe, data,
        id: customer.id, overrideTenant: tenant);

    if (response.statusCode != 200) {
      throw Exception(
          'Erreur lors de la mise à jour du client (Code ${response.statusCode}) : ${response.data}');
    }
    return response.data;
  }

  Future<bool> deleteCustomer(int id, String type) async {
    String suffixeD = 'entity/customer';
    String tenant = await getTenantForCurrentNetwork();
    dynamic response =
        await _remoteData.delete(suffixeD, id, overrideTenant: tenant);

    if (response.statusCode != 200) {
      return false;
    }
    return true;
  }

  Future addEntityType(int id) async {
    const String suffixeET = 'entity/add-type';
    String tenant = await getTenantForCurrentNetwork();
    String data = jsonEncode({'id_entity': id, 'type': 'partner'});

    dynamic response =
        await _remoteData.post(suffixeET, data, overrideTenant: tenant);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
          'Erreur lors du changement de type (Code ${response.statusCode}) : ${response.data}');
    }
    return response.data;
  }
}
