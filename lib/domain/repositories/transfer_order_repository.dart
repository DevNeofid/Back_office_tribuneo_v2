import 'dart:convert';

import 'package:tribuneo_backoffice/data/remote/remote_data_source.dart';
import 'package:tribuneo_backoffice/domain/models/refund_shop_model.dart';
import 'package:tribuneo_backoffice/domain/models/transfer_order_model.dart';

class TransferOrderRepository {
  final RemoteDataSource _remoteData = RemoteDataSource();

  final String suffixe = 'bank_transfer_order';

  Future<List<TransferOrderModel>> getTOrders() async {
    List<TransferOrderModel> transferOrders = [];
    try {
      dynamic response = await _remoteData.get(suffixe);
      if (response.statusCode == 200) {
        response = jsonDecode(response.data);
        for (var transferOrder in response) {
          transferOrders.add(TransferOrderModel.fromJson(transferOrder));
        }
      } else {
        transferOrders = [];
      }
    } catch (e) {
      transferOrders = [];
    }
    return transferOrders;
  }

  Future downloadFile(int id) async {
    try {
      dynamic response =
          await _remoteData.get(suffixe, id: id, bytesType: true);
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
    String suffixe = 'transaction_refund';
    List<RefundShopModel> refunds = [];
    try {
      dynamic response = await _remoteData.get(suffixe);
      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = jsonDecode(response.data);
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
    String suffixe = 'bank_transfer_order_gen';
    try {
      dynamic response = await _remoteData.get(suffixe, bytesType: true);
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
    String suffixe = 'proof_of_receipt';

    try {
      dynamic response = await _remoteData.get(suffixe,
          queryParams: {'transaction_number': transactionNumber},
          bytesType: true);
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
