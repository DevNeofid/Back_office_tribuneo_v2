import 'package:back_office_tribuneo_v2/domain/models/entity_model.dart';
import 'package:back_office_tribuneo_v2/domain/repositories/partner_repository.dart';

class PartnerUseCase {
  final PartnerRepository partnerRepository = PartnerRepository();

  PartnerUseCase();

  Future addPartner(EntityModel partner) async {
    dynamic res = await partnerRepository.addPartner(partner);
    return res;
  }

  Future<Map<int, dynamic>> getPartners() async {
    return await partnerRepository.getPartners();
  }

  Future<EntityModel?> getPartnerBySiret(String siret) async {
    return await partnerRepository.getPartnerBySiret(siret);
  }

  Future updatePartner(EntityModel partner) async {
    dynamic res = await partnerRepository.updatePartner(partner);
    return res;
  }

  Future<bool> deletePartner(int id, String type) async {
    bool res = await partnerRepository.deletePartner(id, type);
    return res;
  }

  Future getSectors() async {
    return await partnerRepository.getSectors();
  }

  Future addNewSector(String sectorName) async {
    return await partnerRepository.addNewSector(sectorName);
  }

  Future deleteSector(int id) async {
    return await partnerRepository.deleteSector(id);
  }

  Future updateSectorPartner(Map data) async {
    return await partnerRepository.updateSectorPartner(data);
  }

  Future createQRCodeReceipt(int id) async {
    return await partnerRepository.createQRCodeReceipt(id);
  }

  Future createQRCode(int id) async {
    return await partnerRepository.createQRCode(id);
  }

  Future createLink(int id, {bool sendMail = false}) async {
    return await partnerRepository.createLink(id, sendMail: sendMail);
  }

  Future addEntityType(int id) async {
    await partnerRepository.addEntityType(id);
  }
}
