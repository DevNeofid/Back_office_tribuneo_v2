import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:back_office_tribuneo_v2/domain/errors/api_exception.dart';
import 'package:back_office_tribuneo_v2/domain/errors/order_error_messages.dart';
import 'package:back_office_tribuneo_v2/domain/repositories/_base_repository.dart';
import 'package:back_office_tribuneo_v2/config/neo_encrypt.dart';
import 'package:back_office_tribuneo_v2/data/remote/api_client.dart';
import 'package:back_office_tribuneo_v2/domain/models/order_beneficiaries_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/order_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/order_update_results_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/order_voucher_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/paginated_result.dart';
import 'package:back_office_tribuneo_v2/domain/models/payment_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/urssaf_model.dart';

class OrderRepository extends BaseRepository {
  final ApiClient _remoteData = ApiClient();
  NeoEncrypt encrypt = NeoEncrypt();

  String suffixe = 'order';
  final String suffixeQ = 'qrcode/gen';

  Future<PaginatedResult<OrderModel>> getOrders({
    int limit = 50,
    int offset = 0,
    String? search,
  }) async {
    String tenant = await getTenantForCurrentNetwork();
    List<OrderModel> orders = [];
    int total = 0;
    try {
      final Map<String, dynamic> queryParams = {
        'limit': limit,
        'offset': offset,
        if (search != null && search.isNotEmpty) 'search': search,
      };
      dynamic response = await _remoteData.get(
        suffixe,
        overrideTenant: tenant,
        queryParams: queryParams,
      );
      if (response.statusCode == 200) {
        final dynamic responseMap = response.data;
        final List<dynamic> items =
            (responseMap['data']?['items'] as List<dynamic>?) ?? [];
        total = _extractTotal(responseMap, items.length);
        for (var order in items) {
          orders.add(OrderModel.fromJson(order as Map<String, dynamic>));
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error: $e');
      }
      orders = [];
      total = 0;
    }
    return PaginatedResult<OrderModel>(items: orders, total: total);
  }

  /// Une commande par son id ; `null` si elle est introuvable (supprimée, autre
  /// réseau) ou en cas d'erreur.
  Future<OrderModel?> getOrder(int idOrder) async {
    try {
      final String tenant = await getTenantForCurrentNetwork();
      final dynamic response =
          await _remoteData.get(suffixe, id: idOrder, overrideTenant: tenant);
      final dynamic data =
          response.statusCode == 200 && response.data is Map
              ? response.data['data']
              : null;
      if (data is Map) {
        return OrderModel.fromJson(Map<String, dynamic>.from(data));
      }
    } catch (e) {
      if (kDebugMode) print('Error: $e');
    }
    return null;
  }

  int _extractTotal(dynamic response, int fallback) {
    if (response is! Map) return fallback;

    int? parse(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    final dynamic data = response['data'];
    if (data is Map) {
      final dynamic pagination = data['pagination'];
      final dynamic meta = data['meta'];
      final candidates = [
        data['total'],
        data['count'],
        data['total_items'],
        if (pagination is Map) pagination['total'],
        if (pagination is Map) pagination['count'],
        if (meta is Map) meta['total'],
        if (meta is Map) meta['count'],
      ];

      for (final candidate in candidates) {
        final parsed = parse(candidate);
        if (parsed != null) return parsed;
      }
    }

    return 0;
  }

  /// Crée une commande. Import par fichier : retourne `false` en cas d'échec.
  /// Saisie manuelle (JSON) : lève une [ApiException] en cas d'échec ;
  /// [idempotencyKey] y protège contre les doubles saisies (sans effet sur
  /// l'import par fichier, que l'API ne dédoublonne pas).
  Future<bool> addOrders(OrderSendModel order,
      {String? fileName, dynamic file, String? idempotencyKey}) async {
    String tenant = await getTenantForCurrentNetwork();

    if (file != null) {
      try {
        String data = jsonEncode({
          "file_name": fileName,
          "file_bytes": file,
          "other_data": order.toJson(),
        });

        dynamic response =
            await _remoteData.post("$suffixe/file", data, overrideTenant: tenant);

        if (response.statusCode == 201 || response.statusCode == 200) {
          return true;
        } else {
          return false;
        }
      } catch (e) {
        if (kDebugMode) {
          print('###DEBUG### Error: $e');
        }
        return false;
      }
    }

    const String fallback = "Erreur lors de l’ajout de la commande";
    dynamic response;
    try {
      response = await _remoteData.post(suffixe, jsonEncode(order),
          overrideTenant: tenant,
          headers: idempotencyKey == null
              ? null
              : {'Idempotency-Key': idempotencyKey});
    } catch (e) {
      if (kDebugMode) {
        print('###DEBUG### Error: $e');
      }
      throw ApiException(fallback);
    }

    if (response.statusCode == 201 || response.statusCode == 200) {
      return true;
    }

    final Map<String, dynamic>? error = decodeApiError(response.data);
    final String? code = apiErrorCode(error);
    if (kDebugMode) {
      print('###DEBUG### [${response.statusCode}] $code ${error?['description']}');
    }
    throw ApiException(
        idempotencyMessageForCode(code) ??
            tenantErrorMessageForCode(code) ??
            fallback,
        code: code);
  }

  /// Modifie une commande saisie à la main. Les bons ne sont plus recréés : l'API
  /// applique l'écart de quantité par montant (bons créés avec lien QR, ou retrait
  /// des derniers bons jamais attribués).
  ///
  /// [body] : `fund_expiry_date` seulement si la date a changé, `id_urssaf_event`
  /// absent pour le laisser inchangé.
  Future<OrderUpdateResult> updateOrder(
      int idOrder, Map<String, dynamic> body) async {
    String tenant = await getTenantForCurrentNetwork();
    dynamic response;
    try {
      response = await _remoteData.put('$suffixe/$idOrder', jsonEncode(body),
          overrideTenant: tenant);
    } catch (e) {
      if (kDebugMode) {
        print('###DEBUG### Error: $e');
      }
      throw ApiException('Erreur lors de la modification de la commande.');
    }

    if (response.statusCode == 200) {
      return OrderUpdateResult.fromJson(_dataOf(response));
    }
    _throwOrderError(response, 'Erreur lors de la modification de la commande.');
  }

  /// Change la date de validité de tous les bons non annulés de la commande.
  /// Fonctionne aussi après facture.
  Future<OrderExpiryUpdateResult> updateOrderExpiryDate(
      int idOrder, String expiryDate) async {
    String tenant = await getTenantForCurrentNetwork();
    dynamic response;
    try {
      response = await _remoteData.put('$suffixe/$idOrder/expiry-date',
          jsonEncode({'expiry_date': expiryDate}),
          overrideTenant: tenant);
    } catch (e) {
      if (kDebugMode) {
        print('###DEBUG### Error: $e');
      }
      throw ApiException('Erreur lors de la mise à jour de la date de validité.');
    }

    if (response.statusCode == 200) {
      return OrderExpiryUpdateResult.fromJson(_dataOf(response));
    }
    _throwOrderError(
        response, 'Erreur lors de la mise à jour de la date de validité.',
        // Au niveau de la commande, plusieurs bons peuvent être concernés.
        overrides: {
          'SHORTENING_ASSIGNED_VOUCHER': "Impossible d'avancer la date : des bons "
              'sont déjà attribués à des consommateurs. On peut seulement la '
              'prolonger.',
        });
  }

  Future<OrderBeneficiariesModel> getBeneficiaries(int idOrder) async {
    String tenant = await getTenantForCurrentNetwork();
    dynamic response;
    try {
      response = await _remoteData.get('$suffixe/$idOrder/beneficiaries',
          overrideTenant: tenant);
    } catch (e) {
      if (kDebugMode) {
        print('###DEBUG### Error: $e');
      }
      throw ApiException('Impossible de charger les bénéficiaires.');
    }

    if (response.statusCode == 200) {
      return OrderBeneficiariesModel.fromJson(_dataOf(response));
    }
    _throwOrderError(response, 'Impossible de charger les bénéficiaires.');
  }

  /// Enregistre la liste **complète** des bénéficiaires : bons existants avec
  /// `id_qrcode`, nouveaux sans, bons retirés absents.
  Future<BeneficiariesUpdateResult> updateBeneficiaries(
      int idOrder, List<Map<String, dynamic>> beneficiaries) async {
    String tenant = await getTenantForCurrentNetwork();
    dynamic response;
    try {
      response = await _remoteData.put('$suffixe/$idOrder/beneficiaries',
          jsonEncode({'beneficiaries': beneficiaries}),
          overrideTenant: tenant);
    } catch (e) {
      if (kDebugMode) {
        print('###DEBUG### Error: $e');
      }
      throw ApiException("Erreur lors de l'enregistrement des bénéficiaires.");
    }

    if (response.statusCode == 200) {
      return BeneficiariesUpdateResult.fromJson(_dataOf(response));
    }
    _throwOrderError(response, "Erreur lors de l'enregistrement des bénéficiaires.",
        overrides: {
          'VALIDATION_ERROR': 'Montant, e-mail ou mobile invalide : vérifiez les '
              'lignes saisies.',
        });
  }

  /// Renvoie le mail « chèque cadeau » d'un bon non attribué. Retourne l'adresse
  /// à laquelle il a été envoyé.
  Future<String?> resendGiftMail(int idQrCode) async {
    String tenant = await getTenantForCurrentNetwork();
    dynamic response;
    try {
      response = await _remoteData.post(
          'qrcode/$idQrCode/resend-gift-mail', jsonEncode({}),
          overrideTenant: tenant);
    } catch (e) {
      if (kDebugMode) {
        print('###DEBUG### Error: $e');
      }
      throw ApiException("Erreur lors de l'envoi de l'e-mail.");
    }

    if (response.statusCode == 200) {
      return _dataOf(response)['email']?.toString();
    }
    _throwOrderError(response, "Erreur lors de l'envoi de l'e-mail.");
  }

  Map<String, dynamic> _dataOf(dynamic response) {
    final dynamic body = response.data;
    if (body is Map && body['data'] is Map) {
      return Map<String, dynamic>.from(body['data'] as Map);
    }
    return body is Map ? Map<String, dynamic>.from(body) : {};
  }

  /// Lève une [ApiException] avec le message français du code d'erreur (section 6
  /// de la spec), [overrides] permettant un message propre au contexte.
  Never _throwOrderError(dynamic response, String fallback,
      {Map<String, String> overrides = const {}}) {
    final Map<String, dynamic>? error = decodeApiError(response.data);
    final String? code = apiErrorCode(error);
    if (kDebugMode) {
      print('###DEBUG### [${response.statusCode}] $code ${error?['description']}');
    }
    final String message = overrides[code] ??
        tenantErrorMessageForCode(code) ??
        OrderErrorMessages.forCode(code, apiErrorDetails(error)) ??
        (response.statusCode == 403
            ? "Vous n'avez pas accès à cette ressource."
            : fallback);
    throw ApiException(message, code: code);
  }

  Future<bool> deleteOrder(int id) async {
    String tenant = await getTenantForCurrentNetwork();

    dynamic request =
        await _remoteData.delete(suffixe, id, overrideTenant: tenant);
    if (request.statusCode == 200) {
      return true;
    }
    return false;
  }

  Future<List<UrssafModel>> getUrssaf() async {
    try {
      dynamic response = await _remoteData.get('$suffixe/events');
      if (response.statusCode == 200) {
        final List<dynamic> urssafJson = response.data['data'];
        final urssaf =
            urssafJson.map((urssaf) => UrssafModel.fromJson(urssaf)).toList();
        return urssaf;
      } else {
        return [];
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error: $e');
      }
      return [];
    }
  }

  Future createQrCode(int idOrder) async {
    String tenant = await getTenantForCurrentNetwork();
    try {
      dynamic response =
          await _remoteData.get(suffixeQ, id: idOrder, overrideTenant: tenant);

      if (response.statusCode == 200 || response.statusCode == 202) {
        String statusUrl = response.data['data']['status_url'];
        String resultUrl = response.data['data']['result_url'];

        if (statusUrl.startsWith('/')) {
          statusUrl = statusUrl.substring(1);
        }
        if (resultUrl.startsWith('/')) {
          resultUrl = resultUrl.substring(1);
        }

        bool isDone = false;

        while (!isDone) {
          await Future.delayed(const Duration(seconds: 2));
          dynamic statusResponse =
              await _remoteData.get(statusUrl, overrideTenant: tenant);

          if (statusResponse.statusCode == 200) {
            Map<String, dynamic> statusData = statusResponse.data['data'];
            if (statusData['status'] == 'done') {
              isDone = true;
            } else if (statusData['status'] == 'failed' ||
                statusData['status'] == 'error') {
              return null;
            }
          } else {
            return null;
          }
        }

        dynamic finalResponse = await _remoteData.get(resultUrl,
            bytesType: true, overrideTenant: tenant);
        if (finalResponse.statusCode == 200) {
          return finalResponse.data;
        }
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future createCsv(int idOrder) async {
    String suffixe = 'qrcode/gen/csv';
    String tenant = await getTenantForCurrentNetwork();
    try {
      dynamic response = await _remoteData.get(suffixe,
          id: idOrder, bytesType: true, overrideTenant: tenant);
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      return null;
    }
  }

  Future<List<OrderVoucherModel>> getOrderVouchers(int idOrder) async {
    String suffixe = 'qrcode';
    String tenant = await getTenantForCurrentNetwork();
    List<OrderVoucherModel> vouchers = [];
    try {
      dynamic response =
          await _remoteData.get(suffixe, id: idOrder, overrideTenant: tenant);
      if (response.statusCode == 200) {
        final List<dynamic> vouchersJson = response.data['data'] ?? [];
        for (var voucher in vouchersJson) {
          vouchers
              .add(OrderVoucherModel.fromJson(voucher as Map<String, dynamic>));
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error: $e');
      }
      vouchers = [];
    }
    return vouchers;
  }

  Future<void> disableVoucher(int idQrCode) async {
    String tenant = await getTenantForCurrentNetwork();

    dynamic response = await _remoteData.put(
        'qrcode/$idQrCode/deleted-date', jsonEncode({}),
        overrideTenant: tenant);

    if (response.statusCode == 200) {
      return;
    }

    // Format d'erreur de l'API : {"error": {"type": ..., "description": ...}}
    String description = '';
    final dynamic data = response.data;
    if (data is Map && data['error'] is Map) {
      description = data['error']['description']?.toString() ?? '';
    }

    final String? tenantMessage = tenantErrorMessage(response);
    if (tenantMessage != null) throw ApiException(tenantMessage);
    if (description.contains('assigned to a user')) {
      throw ApiException(
          'Impossible de désactiver ce bon : il est associé à un utilisateur.');
    }
    if (response.statusCode == 404) {
      throw ApiException('Bon introuvable.');
    }
    throw ApiException('Erreur lors de la désactivation du bon.');
  }

  /// Change la date d'un bon (minimum demain). Prolonger un bon déjà expiré
  /// recalcule le solde du consommateur : voir [VoucherExpiryUpdateResult.wallet].
  Future<VoucherExpiryUpdateResult> updateVoucherExpiryDate(
      int idQrCode, String expiryDate) async {
    String tenant = await getTenantForCurrentNetwork();
    // L'API attend une date au format 'yyyy-MM-dd' et y ajoute ' 23:59:59'.
    String data = jsonEncode({'expiry_date': expiryDate});

    dynamic response;
    try {
      response = await _remoteData.put('qrcode', data,
          id: idQrCode, overrideTenant: tenant);
    } catch (e) {
      if (kDebugMode) {
        print('###DEBUG### Error: $e');
      }
      throw ApiException(
          'Erreur lors de la mise à jour de la date d\'expiration.');
    }

    if (response.statusCode == 200) {
      return VoucherExpiryUpdateResult.fromJson(_dataOf(response));
    }
    _throwOrderError(
        response, 'Erreur lors de la mise à jour de la date d\'expiration.');
  }

  Future<List<PaymentModel>> getPayments(int idOrder) async {
    String suffixe = 'payment';
    String tenant = await getTenantForCurrentNetwork();
    List<PaymentModel> payments = [];
    try {
      dynamic response =
          await _remoteData.get(suffixe, id: idOrder, overrideTenant: tenant);
      if (response.statusCode == 200) {
        response = response.data['data'];
        for (var payment in response) {
          payments.add(PaymentModel.fromJson(payment as Map<String, dynamic>));
        }
      } else {
        payments = [];
      }
    } catch (e) {
      payments = [];
    }
    return payments;
  }

  /// Enregistre un paiement et retourne le paiement tel que l'API l'a enregistré
  /// (`bank_account_code` y est toujours renseigné, même si le front n'a rien envoyé).
  ///
  /// [idempotencyKey] : même clé pour un même paiement tant qu'il n'a pas réussi,
  /// l'API renvoie alors la réponse d'origine sans créer de doublon.
  Future<PaymentModel> addPayment(Map payment, {String? idempotencyKey}) async {
    String suffixe = 'payment';
    String data = jsonEncode(payment);
    String tenant = await getTenantForCurrentNetwork();
    dynamic response;
    try {
      response = await _remoteData.post(suffixe, data,
          overrideTenant: tenant,
          headers: idempotencyKey == null
              ? null
              : {'Idempotency-Key': idempotencyKey});
    } catch (e) {
      if (kDebugMode) {
        print('Error: $e');
      }
      throw ApiException("Erreur lors de l'enregistrement du paiement.");
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      final dynamic body = response.data;
      return PaymentModel.fromJson(body is Map && body['data'] is Map
          ? Map<String, dynamic>.from(body['data'] as Map)
          : <String, dynamic>{});
    }

    final Map<String, dynamic>? error = decodeApiError(response.data);
    final String? code = apiErrorCode(error);
    final String description = error?['description']?.toString() ?? '';

    if (kDebugMode) {
      print('###DEBUG### [${response.statusCode}] $code $description');
    }
    throw ApiException(_addPaymentMessage(code, description), code: code);
  }

  /// Traduit les refus de `POST /payment`. Les autres erreurs retombent sur un
  /// message générique plutôt que sur la description anglaise de l'API.
  String _addPaymentMessage(String? code, String description) {
    final String? shared =
        idempotencyMessageForCode(code) ?? tenantErrorMessageForCode(code);
    if (shared != null) return shared;
    switch (code) {
      case 'BANK_ACCOUNT_REQUIRED':
        return 'Choisissez le compte sur lequel le paiement a été encaissé.';
      case 'UNKNOWN_BANK_ACCOUNT':
        return "Le compte bancaire choisi n'existe plus. "
            'La liste des comptes a été rechargée, vérifiez le compte sélectionné.';
      case 'BANK_ACCOUNT_LOCKED':
        // Ne devrait pas arriver si le front respecte les verrous : on affiche la
        // description telle quelle pour diagnostiquer le désalignement.
        return description.isNotEmpty
            ? description
            : "Ce réseau impose le compte d'encaissement des paiements.";
      case 'NO_BANK_ACCOUNT':
        return "Aucun compte bancaire n'est configuré pour ce réseau. "
            'Contactez Neofid.';
      case 'PAYMENT_EXCEEDS_ORDER_TOTAL':
        // Même texte que le contrôle local de la vue.
        return 'Le montant saisi dépasse le montant total de la commande.';
      case 'RESOURCE_NOT_FOUND':
        return "Cette commande n'existe plus (elle a peut-être été supprimée).";
      default:
        // SERVER_ERROR compris : rien n'a été enregistré côté API.
        return "Erreur lors de l'enregistrement du paiement.";
    }
  }

  Future<void> deletePayment(int idPayment) async {
    String suffixe = 'payment';
    String tenant = await getTenantForCurrentNetwork();

    dynamic response =
        await _remoteData.delete(suffixe, idPayment, overrideTenant: tenant);

    if (response.statusCode == 200) {
      return;
    }

    // Format d'erreur de l'API : {"error": {"type": ..., "description": ...}}
    String description = '';
    final dynamic data = response.data;
    if (data is Map && data['error'] is Map) {
      description = data['error']['description']?.toString() ?? '';
    }

    final String? tenantMessage = tenantErrorMessage(response);
    if (tenantMessage != null) throw ApiException(tenantMessage);
    if (description.contains('accounting entries')) {
      throw ApiException(
          'Impossible de supprimer ce paiement : les écritures comptables ont déjà été générées.');
    }
    if (response.statusCode == 404) {
      throw ApiException('Paiement introuvable.');
    }
    throw ApiException('Erreur lors de la suppression du paiement.');
  }

  Future<String> getInvoiceInfos(int idOrder) async {
    String suffixe = 'accounting/invoice/comment';
    String tenant = await getTenantForCurrentNetwork();
    try {
      dynamic response =
          await _remoteData.get(suffixe, id: idOrder, overrideTenant: tenant);
      if (response.statusCode == 200) {
        var res = response.data;
        String invoiceInfos = res['data']['comment'] ?? '';
        return invoiceInfos;
      } else {
        throw Exception('Failed to load invoice');
      }
    } catch (e) {
      throw Exception('Failed to load invoice');
    }
  }

  Future createInvoice(Map invoice) async {
    String suffixe = 'accounting/invoice/order';
    String data = jsonEncode(invoice);
    String tenant = await getTenantForCurrentNetwork();
    try {
      dynamic response = await _remoteData.post(suffixe, data,
          overrideTenant: tenant, bytesType: true);
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to load invoice');
      }
    } catch (e) {
      return null;
    }
  }

  Future createDeliveryNote(int idOrder) async {
    String tenant = await getTenantForCurrentNetwork();
    try {
      dynamic response = await _remoteData.get('accounting/delivery-note/',
          id: idOrder, overrideTenant: tenant, bytesType: true);
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to load delivery note');
      }
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }

  Future createSummary(int idOrder) async {
    String tenant = await getTenantForCurrentNetwork();
    try {
      dynamic response = await _remoteData.get('$suffixe/$idOrder/summary',
          overrideTenant: tenant, bytesType: true);
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to load summary');
      }
    } catch (e) {
      return null;
    }
  }
}
