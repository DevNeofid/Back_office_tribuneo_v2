import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:back_office_tribuneo_v2/data/remote/api_client.dart';
import 'package:back_office_tribuneo_v2/domain/models/entity_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/sector_model.dart';
import 'package:back_office_tribuneo_v2/domain/repositories/_base_repository.dart';
import 'package:http/http.dart' as http;

class PartnerRepository extends BaseRepository {
  final ApiClient _remoteData = ApiClient();

  final String suffixe = 'entity';

  static const int allPartnersKey = 0;
  static const int mapEntitiesKey = 1;

  Future<Map<int, dynamic>> getPartners() async {
    Map<int, dynamic> result = {};
    Map<String, List<EntityModel>> mapEntities = {};
    List<EntityModel> allPartners = [];

    String tenant = await getTenantForCurrentNetwork();

    try {
      dynamic response = await _remoteData.get(suffixe,
          overrideTenant: tenant,
          queryParams: {
            'entity_type': 'partner',
            'full_infos': 'true',
            'sorted_by_letter': 'true'
          });

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('###DEBUG### date after response: ${DateTime.now()}');
        }
        Map<String, dynamic> responseBody = response.data;

        if (responseBody.containsKey('data') &&
            responseBody['data']['items'] != null) {
          Map<String, dynamic> items = responseBody['data']['items'];

          items.forEach((letter, partnersList) {
            List<EntityModel> partnersForLetter = [];

            if (partnersList is List) {
              for (var partnerJson in partnersList) {
                EntityModel p = EntityModel.fromJson(partnerJson);
                partnersForLetter.add(p);
                allPartners.add(p);
              }
            }

            mapEntities[letter] = partnersForLetter;
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
      if (kDebugMode) {
        print('Erreur lors du parsing des partenaires : $e');
      }
      result = {};
    }
    return result;
  }

  Future addPartner(EntityModel partner) async {
    String data = jsonEncode(partner.toJson());
    String tenant = await getTenantForCurrentNetwork();
    try {
      return await _remoteData.post(suffixe, data, overrideTenant: tenant);
    } catch (e) {
      return http.Response('Error: $e', 500);
    }
  }

  Future updatePartner(EntityModel partner) async {
    String data = jsonEncode(partner.toJson());
    try {
      return await _remoteData.put('$suffixe/${partner.id}', data);
    } catch (e) {
      return http.Response('Error: $e', 500);
    }
  }

  Future deletePartner(int id, String type) async {
    try {
      return await _remoteData.delete(suffixe, id);
    } catch (e) {
      return http.Response('Error: $e', 500);
    }
  }

  Future<List<Sector>> getSectors() async {
    List<Sector> result = [];
    const String suffixeAS = 'activity-sectors';

    try {
      dynamic response = await _remoteData.get(suffixeAS);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseMap = response.data;

        final List<dynamic> sectorsList = responseMap['data'];

        result = sectorsList
            .map((sectorJson) =>
                Sector.fromJson(sectorJson as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting sectors: $e');
      }
      result = [];
    }

    return result;
  }

  Future<http.Response> addNewSector(String sectorName) async {
    const String suffixeAS = 'activity-sectors';
    try {
      dynamic res = await _remoteData.post(
          suffixeAS, jsonEncode({'name': sectorName, 'description': ''}));
      return res;
    } catch (e) {
      return http.Response('Error: $e', 500);
    }
  }

  Future deleteSector(int id) async {
    const String suffixeAS = 'activity-sectors';
    try {
      return await _remoteData.delete(suffixeAS, id);
    } catch (e) {
      return http.Response('Error: $e', 500);
    }
  }

  Future updateSectorPartner(Map data) async {
    String dataJson = jsonEncode(data);
    const String suffixeSAS = 'activity-sectors';
    try {
      return await _remoteData.post(suffixeSAS, dataJson);
    } catch (e) {
      return http.Response('Error: $e', 500);
    }
  }

  Future createQRCodeReceipt(int id) async {
    const String suffixeQR = 'qrcode/receipt';
    String tenant = await getTenantForCurrentNetwork();
    try {
      dynamic response = await _remoteData.get(suffixeQR,
          id: id, overrideTenant: tenant, bytesType: true);
      return response.data;
    } catch (e) {
      return http.Response('Error: $e', 500);
    }
  }

  Future createQRCode(int id) async {
    const String suffixeQR = 'qrcode/first-login';
    String tenant = await getTenantForCurrentNetwork();
    try {
      dynamic response = await _remoteData.get(suffixeQR,
          id: id, overrideTenant: tenant, bytesType: true);
      return response.data;
    } catch (e) {
      return http.Response('Error: $e', 500);
    }
  }

  Future createLink(int id) async {
    const String suffixeL = 'entity/first-login-link';
    String tenant = await getTenantForCurrentNetwork();
    try {
      dynamic response =
          await _remoteData.get(suffixeL, id: id, overrideTenant: tenant);
      return jsonDecode(response.data);
    } catch (e) {
      return http.Response('Error: $e', 500);
    }
  }

  Future addEntityType(int id) async {
    const String suffixeET = 'entity/add-type';
    String tenant = await getTenantForCurrentNetwork();
    String data = jsonEncode({'id_entity': id, 'type': 'customer'});
    try {
      dynamic response =
          await _remoteData.post(suffixeET, data, overrideTenant: tenant);
      return response;
    } catch (e) {
      return http.Response('Error: $e', 500);
    }
  }
}
