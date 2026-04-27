import 'dart:convert';
import 'package:back_office_tribuneo_v2/domain/repositories/_base_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:back_office_tribuneo_v2/data/remote/api_client.dart';
import 'package:back_office_tribuneo_v2/domain/models/entity_model.dart';

class CustomerRepository extends BaseRepository {
  final ApiClient _remoteData = ApiClient();

  final String suffixe = 'entity';

  // Define constants for result keys
  static const int allCustomersKey = 0;
  static const int mapEntitiesKey = 1;

  Future<Map<int, dynamic>> getCustomers() async {
    Map<int, dynamic> result = {};
    Map<String, List<EntityModel>> mapEntities = {};
    List<EntityModel> allCustomers = [];
    String tenant = await getTenantForCurrentNetwork();
    try {
      dynamic response = await _remoteData.get(suffixe,
          queryParams: {
            'entity_type': 'customer',
            'full_infos': 'true',
            'sorted_by_letter': 'true'
          },
          overrideTenant: tenant);
      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('###DEBUG### date after response: ${DateTime.now()}');
        }
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
      } else {
        if (kDebugMode) {
          print('Error getting customers: ${response.statusCode}');
        }
      }
      result.addAll(
        {
          allCustomersKey: allCustomers,
          mapEntitiesKey: mapEntities,
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('###DEBUG### Error in getCustomers: $e');
      }
      result = {};
    }
    return result;
  }

  Future addCustomer(EntityModel customer) async {
    String data = jsonEncode(customer.toJson());
    try {
      return await _remoteData.post(suffixe, data);
    } catch (e) {
      // Handle exceptions or log errors as appropriate
      return http.Response(
          'Error: $e', 500); // Return a response with a 500 status code
    }
  }

  Future updateCustomer(EntityModel customer) async {
    String data = jsonEncode(customer.toJson());
    try {
      return await _remoteData.put('$suffixe/${customer.id}/update', data);
    } catch (e) {
      // Handle exceptions or log errors as appropriate
      return http.Response(
          'Error: $e', 500); // Return a response with a 500 status code
    }
  }

  Future deleteCustomer(int id, String type) async {
    try {
      return await _remoteData.delete(suffixe, id);
    } catch (e) {
      // Handle exceptions or log errors as appropriate
      return http.Response(
          'Error: $e', 500); // Return a response with a 500 status code
    }
  }

  Future addEntityType(int id) async {
    const String suffixe = 'entity_add_type';
    String data = jsonEncode({'id_entity': id, 'type': 'partner'});
    try {
      return await _remoteData.post(suffixe, data);
    } catch (e) {
      if (kDebugMode) {
        print('###DEBUG### Error adding entity type: $e');
      }
    }
  }
}
