import 'dart:convert';
import 'package:back_office_tribuneo_v2/data/remote/api_client.dart';
import 'package:back_office_tribuneo_v2/domain/models/entity_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/sector_model.dart';
import 'package:back_office_tribuneo_v2/domain/repositories/_base_repository.dart';

class PartnerRepository extends BaseRepository {
  final ApiClient _remoteData = ApiClient();
  final String suffixe = 'entity';

  static const int allPartnersKey = 0;
  static const int mapEntitiesKey = 1;

  Future<Map<int, dynamic>> getPartners() async {
    Map<String, List<EntityModel>> mapEntities = {};
    List<EntityModel> allPartners = [];
    String tenant = await getTenantForCurrentNetwork();

    dynamic response = await _remoteData.get(suffixe,
        overrideTenant: tenant,
        queryParams: {
          'entity_type': 'partner',
          'full_infos': 'true',
          'sorted_by_letter': 'true'
        });

    if (response.statusCode != 200) {
      throw Exception(
          'Erreur API (Code ${response.statusCode}) : ${response.data}');
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

    return {
      allPartnersKey: allPartners,
      mapEntitiesKey: mapEntities,
    };
  }

  Future addPartner(EntityModel partner) async {
    String data = jsonEncode(partner.toJson());
    String tenant = await getTenantForCurrentNetwork();
    dynamic response =
        await _remoteData.post(suffixe, data, overrideTenant: tenant);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
          'Erreur ajout partenaire (Code ${response.statusCode}) : ${response.data}');
    }
    return response.data;
  }

  Future updatePartner(EntityModel partner) async {
    String data = jsonEncode(partner.toJson());
    dynamic response = await _remoteData.put(suffixe, data, id: partner.id);

    if (response.statusCode != 200) {
      throw Exception(
          'Erreur mise à jour partenaire (Code ${response.statusCode}) : ${response.data}');
    }
    return response.data;
  }

  Future<bool> deletePartner(int id, String type) async {
    String tenant = await getTenantForCurrentNetwork();
    dynamic response =
        await _remoteData.delete(suffixe, id, overrideTenant: tenant);

    if (response.statusCode != 200) {
      return false;
    }
    return true;
  }

  Future<List<Sector>> getSectors() async {
    const String suffixeAS = 'activity-sectors';
    dynamic response = await _remoteData.get(suffixeAS);

    if (response.statusCode != 200) {
      throw Exception('Erreur récupération secteurs : ${response.statusCode}');
    }

    final Map<String, dynamic> responseMap = response.data;
    final List<dynamic> sectorsList = responseMap['data'];

    return sectorsList
        .map(
            (sectorJson) => Sector.fromJson(sectorJson as Map<String, dynamic>))
        .toList();
  }

  Future addNewSector(String sectorName) async {
    const String suffixeAS = 'activity-sectors';
    dynamic response =
        await _remoteData.post(suffixeAS, jsonEncode({'name': sectorName}));

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Erreur ajout secteur : ${response.data}');
    }
    return response.data;
  }

  Future deleteSector(int id) async {
    const String suffixeAS = 'activity-sectors';
    dynamic response = await _remoteData.delete(suffixeAS, id);

    if (response.statusCode != 200) {
      throw Exception('Erreur suppression secteur : ${response.data}');
    }
    return response.data;
  }

  Future updateSectorPartner(Map data) async {
    String dataJson = jsonEncode(data);
    const String suffixeSAS = 'activity-sectors/set';
    dynamic response = await _remoteData.post(suffixeSAS, dataJson);

    if (response.statusCode != 200) {
      throw Exception('Erreur mise à jour secteur : ${response.data}');
    }
    return response.data;
  }

  Future createQRCodeReceipt(int id) async {
    const String suffixeQR = 'qrcode/receipt';
    String tenant = await getTenantForCurrentNetwork();
    dynamic response = await _remoteData.get(suffixeQR,
        id: id, overrideTenant: tenant, bytesType: true);

    if (response.statusCode != 200) {
      throw Exception('Erreur QR réception : ${response.statusCode}');
    }
    return response.data;
  }

  Future createQRCode(int id) async {
    const String suffixeQR = 'qrcode/first-login';
    String tenant = await getTenantForCurrentNetwork();
    dynamic response = await _remoteData.get(suffixeQR,
        id: id, overrideTenant: tenant, bytesType: true);

    if (response.statusCode != 200) {
      throw Exception('Erreur QR connexion : ${response.statusCode}');
    }
    return response.data;
  }

  Future<String> createLink(int id, {bool sendMail = false}) async {
    const String suffixeL = 'entity/first-login-link';
    String tenant = await getTenantForCurrentNetwork();

    Map<String, dynamic>? queryParams =
        sendMail ? {'sending_email': true} : null;

    dynamic response = await _remoteData.get(
      suffixeL,
      id: id,
      overrideTenant: tenant,
      queryParams: queryParams,
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur lien connexion : ${response.statusCode}');
    }
    return response.data['data']['first_login_link'];
  }

  Future addEntityType(int id) async {
    const String suffixeET = 'entity/add-type';
    String tenant = await getTenantForCurrentNetwork();
    String data = jsonEncode({'id_entity': id, 'type': 'customer'});

    dynamic response =
        await _remoteData.post(suffixeET, data, overrideTenant: tenant);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Erreur changement type : ${response.data}');
    }
    return response.data;
  }

  Future<EntityModel?> getPartnerBySiret(String siret) async {
    String tenant = await getTenantForCurrentNetwork();
    dynamic response = await _remoteData.get(
      '$suffixe/siret',
      overrideTenant: tenant,
      queryParams: {'siret': siret},
    );

    if (response.statusCode == 404) return null;

    if (response.statusCode != 200) {
      throw Exception('Erreur recherche SIRET : ${response.data}');
    }

    Map<String, dynamic> jsonResponse = response.data;
    if (jsonResponse.containsKey('data') && jsonResponse['data'] != null) {
      return EntityModel.fromJson(jsonResponse['data']);
    }
    return null;
  }
}
