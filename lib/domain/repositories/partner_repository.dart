import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:tribuneo_backoffice/data/local/local_data_helper.dart';
import 'package:tribuneo_backoffice/data/remote/remote_data_source.dart';
import 'package:tribuneo_backoffice/domain/models/entity_model.dart';
import 'package:tribuneo_backoffice/domain/models/sector_model.dart';
import 'package:http/http.dart' as http;

class PartnerRepository {
  final RemoteDataSource _remoteData = RemoteDataSource();
  LocalDataHelper localDataHelper = LocalDataHelper();

  final String suffixe = 'entity';

  static const int allPartnersKey = 0;
  static const int mapEntitiesKey = 1;

  Future<Map<int, dynamic>> getPartners() async {
    Map<int, dynamic> result = {};
    Map<String, List<EntityModel>> mapEntities = {};
    List<EntityModel> allPartners = [];
    try {
      dynamic response = await _remoteData.get(suffixe, queryParams: {
        'entity_type': 'partner',
        'full_infos': 'true',
        'sorted_by_letter': 'true'
      });
      if (response.statusCode == 200) {
        if (kDebugMode) {
          //print('###DEBUG### date after response: ${DateTime.now()}');
        }
        List<dynamic> responseBody = jsonDecode(response.data);
        for (var data in responseBody) {
          List<EntityModel> partners = [];
          data.forEach((key, value) {
            for (var partner in value) {
              EntityModel p = EntityModel.fromJson(partner);
              partners.add(p);
              mapEntities[key] = partners;
              allPartners.add(p);
            }
          });
        }
      } else {
        if (kDebugMode) {
          print('Error getting partners: ${response.statusCode}');
        }
      }

      result.addAll(
        {
          allPartnersKey: allPartners,
          mapEntitiesKey: mapEntities,
        },
      );
    } catch (e) {
      result = {};
    }
    return result;
  }

  Future addPartner(EntityModel partner) async {
    String data = jsonEncode(partner.toJson());
    try {
      return await _remoteData.post(suffixe, data);
    } catch (e) {
      return http.Response('Error: $e', 500);
    }
  }

  Future updatePartner(EntityModel partner) async {
    String data = jsonEncode(partner.toJson());
    try {
      return await _remoteData.put(suffixe, data, id: partner.id);
    } catch (e) {
      return http.Response('Error: $e', 500);
    }
  }

  Future deletePartner(int id, String type) async {
    const String suffixeD = 'entity_delete';
    String data = jsonEncode({'type': type});
    try {
      return await _remoteData.softDelete(suffixeD, id, data: data);
    } catch (e) {
      return http.Response('Error: $e', 500);
    }
  }

  Future<List<Sector>> getSectors() async {
    List<Sector> result = [];
    const String suffixeAS = 'activity_sectors';
    try {
      dynamic response = await _remoteData.get(suffixeAS);
      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = jsonDecode(response.data);
        result = jsonResponse
            .map((sectorJson) => Sector.fromJson(sectorJson))
            .toList();
      }
    } catch (e) {
      result = [];
    }
    return result;
  }

  Future<http.Response> addNewSector(String sectorName) async {
    const String suffixeAS = 'activity_sectors';
    try {
      dynamic res = await _remoteData.post(
          suffixeAS, jsonEncode({'name': sectorName, 'description': ''}));
      return res;
    } catch (e) {
      return http.Response('Error: $e', 500);
    }
  }

  Future deleteSector(int id) async {
    const String suffixeAS = 'activity_sectors';
    try {
      return await _remoteData.delete(suffixeAS, id);
    } catch (e) {
      return http.Response('Error: $e', 500);
    }
  }

  Future updateSectorPartner(Map data) async {
    String dataJson = jsonEncode(data);
    const String suffixeSAS = 'set_activity_sectors';
    try {
      return await _remoteData.post(suffixeSAS, dataJson);
    } catch (e) {
      return http.Response('Error: $e', 500);
    }
  }

  Future createQRCodeReceipt(int id) async {
    const String suffixeQR = 'qrcgen_receipt';
    Map<String, dynamic> data = {'id_entity': id};
    String dataJson = jsonEncode(data);
    try {
      dynamic response =
          await _remoteData.post(suffixeQR, dataJson, bytesType: true);
      return response.data;
    } catch (e) {
      return http.Response('Error: $e', 500);
    }
  }

  Future createQRCode(int id) async {
    const String suffixeQR = 'entity_first_login_gen';
    try {
      dynamic response =
          await _remoteData.get(suffixeQR, id: id, bytesType: true);
      return response.data;
    } catch (e) {
      return http.Response('Error: $e', 500);
    }
  }

  Future createLink(int id) async {
    const String suffixeL = 'entity_first_login_link';
    try {
      dynamic response = await _remoteData.get(suffixeL, id: id);
      return jsonDecode(response.data);
    } catch (e) {
      return http.Response('Error: $e', 500);
    }
  }

  Future addEntityType(int id) async {
    const String suffixeET = 'entity_add_type';
    try {
      dynamic response = await _remoteData.post(
          suffixeET, jsonEncode({'id_entity': id, 'type': 'customer'}));
      return response;
    } catch (e) {
      return http.Response('Error: $e', 500);
    }
  }
}
