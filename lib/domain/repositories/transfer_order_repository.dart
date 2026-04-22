import 'package:back_office_tribuneo_v2/data/remote/api_client.dart';
import 'package:back_office_tribuneo_v2/domain/models/refund_shop_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/transfer_order_model.dart';
import 'package:back_office_tribuneo_v2/domain/repositories/_base_repository.dart';
import 'package:flutter/foundation.dart';

class TransferOrderRepository extends BaseRepository {
  final ApiClient _remoteData = ApiClient();

  final String suffixe = 'bto';

  Future<List<TransferOrderModel>> getOrders() async {
    List<TransferOrderModel> transferOrders = [];
    String tenant = await getTenantForCurrentNetwork();
    try {
      dynamic response = await _remoteData.get(suffixe, overrideTenant: tenant);
      if (response.statusCode == 200) {
        response = response.data['data']['items'];
        for (var transferOrder in response) {
          transferOrders.add(TransferOrderModel.fromJson(transferOrder));
        }
      } else {
        transferOrders = [];
      }
    } catch (e) {
      if (kDebugMode) {
        print('###DEBUG### Error: $e');
      }
      transferOrders = [];
    }
    return transferOrders;
  }

  Future downloadFile(int id) async {
    String tenant = await getTenantForCurrentNetwork();
    try {
      dynamic response = await _remoteData.get(suffixe,
          id: id, bytesType: true, overrideTenant: tenant);
      if (response.statusCode == 200) {
        return response.data;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<List<RefundShopModel>> awaitRefund() async {
    String tenant = await getTenantForCurrentNetwork();
    List<RefundShopModel> refunds = [];
    try {
      dynamic response =
          await _remoteData.get('$suffixe/pending', overrideTenant: tenant);
      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = response.data['data'];
        for (var refund in jsonResponse) {
          refunds.add(RefundShopModel.fromJson(refund));
        }
      } else {
        refunds = [];
      }
    } catch (e) {
      refunds = [];
      throw Exception('Erreur lors du téléchargement du fichier XML');
    }
    return refunds;
  }

  Future refundShop() async {
    String tenant = await getTenantForCurrentNetwork();
    try {
      dynamic response = await _remoteData.get('$suffixe/gen',
          bytesType: true, overrideTenant: tenant);
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Erreur lors du téléchargement du fichier XML');
      }
    } catch (e) {
      throw Exception('Erreur lors du téléchargement du fichier XML');
    }
  }

  Future editProof(String transactionNumber) async {
    String suffixe = 'accounting/proof-of-receipt';
    String tenant = await getTenantForCurrentNetwork();
    try {
      dynamic response = await _remoteData.get('$suffixe/$transactionNumber',
          bytesType: true, overrideTenant: tenant);
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Erreur lors du téléchargement des documents');
      }
    } catch (e) {
      throw Exception('Erreur lors du téléchargement des documents');
    }
  }
}
