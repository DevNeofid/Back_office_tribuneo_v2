import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:tribuneo_backoffice/data/local/local_data_helper.dart';
import 'package:tribuneo_backoffice/data/remote/remote_data_source.dart';
import 'package:tribuneo_backoffice/domain/models/entity_model.dart';

class CustomerRepository {
  final RemoteDataSource _remoteData = RemoteDataSource();
  LocalDataHelper localDataHelper = LocalDataHelper();

  final String suffixe = 'entity';

  // Define constants for result keys
  static const int allCustomersKey = 0;
  static const int mapEntitiesKey = 1;

  Future<Map<int, dynamic>> getCustomers() async {
    Map<int, dynamic> result = {};
    Map<String, List<EntityModel>> mapEntities = {};
    List<EntityModel> allCustomers = [];
    try {
      dynamic response = await _remoteData.get(suffixe, queryParams: {
        'entity_type': 'customer',
        'full_infos': 'true',
        'sorted_by_letter': 'true'
      });
      if (response.statusCode == 200) {
        if (kDebugMode) {
          //print('###DEBUG### date after response: ${DateTime.now()}');
        }
        List<dynamic> responseBody = jsonDecode(response.data);
        for (var data in responseBody) {
          List<EntityModel> customers = [];
          data.forEach((key, value) {
            for (var customer in value) {
              EntityModel p = EntityModel.fromJson(customer);
              customers.add(p);
              mapEntities[key] = customers;
              allCustomers.add(p);
            }
          });
        }
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
      return await _remoteData.put(suffixe, id: customer.id, data);
    } catch (e) {
      // Handle exceptions or log errors as appropriate
      return http.Response(
          'Error: $e', 500); // Return a response with a 500 status code
    }
  }

  Future deleteCustomer(int id, String type) async {
    const String suffixeD = 'entity_delete';
    String data = jsonEncode({'type': type});
    try {
      return await _remoteData.softDelete(suffixeD, id, data: data);
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
      // Handle exceptions or log errors as appropriate
      return http.Response(
          'Error: $e', 500); // Return a response with a 500 status code
    }
  }
}
