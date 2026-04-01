import 'package:tribuneo_backoffice/domain/models/entity_model.dart';
import 'package:tribuneo_backoffice/domain/repositories/partner_repository.dart';

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

  Future updatePartner(EntityModel partner) async {
    dynamic res = await partnerRepository.updatePartner(partner);
    return res;
  }

  Future deletePartner(int id, String type) async {
    dynamic res = await partnerRepository.deletePartner(id, type);
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

  Future createLink(int id) async {
    return await partnerRepository.createLink(id);
  }

  Future addEntityType(int id) async {
    await partnerRepository.addEntityType(id);
  }
}
