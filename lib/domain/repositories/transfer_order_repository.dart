
import 'package:back_office_tribuneo_v2/data/remote/api_client.dart';
import 'package:back_office_tribuneo_v2/domain/errors/api_exception.dart';
import 'package:back_office_tribuneo_v2/domain/errors/blocked_refunds_exception.dart';
import 'package:back_office_tribuneo_v2/domain/models/bank_account_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/paginated_result.dart';
import 'package:back_office_tribuneo_v2/domain/models/refund_shop_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/transfer_order_model.dart';
import 'package:back_office_tribuneo_v2/domain/repositories/_base_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class TransferOrderRepository extends BaseRepository {
  final ApiClient _remoteData = ApiClient();

  final String suffixe = 'bto';

  Future<PaginatedResult<TransferOrderModel>> getOrders({
    int limit = 10,
    int offset = 0,
  }) async {
    List<TransferOrderModel> transferOrders = [];
    int total = 0;
    String tenant = await getTenantForCurrentNetwork();
    try {
      dynamic response = await _remoteData.get(
        suffixe,
        overrideTenant: tenant,
        queryParams: {
          'limit': limit,
          'offset': offset,
        },
      );
      if (response.statusCode == 200) {
        final dynamic responseMap = response.data;
        final List<dynamic> items =
            (responseMap['data']?['items'] as List<dynamic>?) ?? [];
        total = _extractTotal(responseMap, items.length);
        for (var transferOrder in items) {
          transferOrders.add(TransferOrderModel.fromJson(transferOrder));
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('###DEBUG### Error: $e');
      }
      transferOrders = [];
      total = 0;
    }
    return PaginatedResult<TransferOrderModel>(
        items: transferOrders, total: total);
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

    return fallback;
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

  /// Génère l'ordre de virement. [bankAccountCode] est le compte payeur choisi ;
  /// `null` quand aucun select n'est affiché, l'API prend alors le compte `is_refund`.
  /// [bankAccounts] ne sert qu'à nommer le compte dans les messages d'erreur.
  Future refundShop(
      {String? bankAccountCode, BankAccountsModel? bankAccounts}) async {
    String tenant = await getTenantForCurrentNetwork();
    dynamic response;
    try {
      response = await _remoteData.get('$suffixe/gen',
          queryParams:
              bankAccountCode == null ? null : {'bank_account': bankAccountCode},
          bytesType: true,
          overrideTenant: tenant);
    } catch (e) {
      if (kDebugMode) {
        print('###DEBUG### Error: $e');
      }
      throw ApiException(
          "Erreur lors de la génération de l'ordre de virement.");
    }

    if (response.statusCode == 200) {
      return response.data;
    }

    final Map<String, dynamic>? error = decodeApiError(response.data);
    final dynamic details = error?['details'];

    // L'API refuse de générer tant qu'un remboursement de la période est incomplet :
    // elle renvoie la liste, on la remonte telle quelle pour l'afficher.
    if (details is Map && details['code'] == 'BLOCKED_REFUNDS') {
      final List<BlockedRefund> blocked = (details['items'] as List<dynamic>? ??
              [])
          .whereType<Map>()
          .map(
              (item) => BlockedRefund.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      if (blocked.isNotEmpty) {
        throw BlockedRefundsException(blocked);
      }
    }

    throw ApiException(
        _refundShopMessage(details, error?['description'], bankAccounts));
  }

  Future editProof(String transactionNumber) async {
    String suffixe = 'accounting/proof-of-receipt';
    String tenant = await getTenantForCurrentNetwork();
    dynamic response;
    try {
      response = await _remoteData.get('$suffixe/$transactionNumber',
          bytesType: true, overrideTenant: tenant);
    } catch (e) {
      if (kDebugMode) {
        print('###DEBUG### Error: $e');
      }
      throw ApiException('Erreur lors de la génération des justificatifs.');
    }

    if (response.statusCode == 200) {
      return response.data;
    }

    final Map<String, dynamic>? error = decodeApiError(response.data);
    final dynamic details = error?['details'];

    // Fiche partenaire incomplète : rien n'a été écrit côté API, on dit quoi compléter.
    if (details is Map && details['code'] == 'INCOMPLETE_ENTITY') {
      throw ApiException(_incompleteEntityMessage(details));
    }

    if (kDebugMode) {
      print('###DEBUG### ${error?['description']}');
    }
    throw ApiException('Erreur lors de la génération des justificatifs.');
  }

  /// Traduit les refus attendus de l'API. Un code inconnu retombe sur un message
  /// générique plutôt que sur la description anglaise de l'API.
  String _refundShopMessage(
      dynamic details, dynamic description, BankAccountsModel? bankAccounts) {
    final String? code = details is Map ? details['code']?.toString() : null;
    final String period = details is Map
        ? _periodLabel(details['period_from'], details['period_to'])
        : '';

    switch (code) {
      case 'MISSING_XML_PARAMS':
        return _missingXmlParamsMessage(details as Map, bankAccounts);
      case 'UNKNOWN_BANK_ACCOUNT':
        return "Le compte bancaire choisi n'existe plus. "
            'Relancez le déclenchement pour choisir à nouveau le compte.';
      case 'BANK_ACCOUNT_LOCKED':
        // Ne devrait pas arriver si le front respecte les verrous : on affiche la
        // description telle quelle pour diagnostiquer le désalignement.
        final String text = description?.toString() ?? '';
        return text.isNotEmpty
            ? text
            : 'Ce réseau impose le compte payeur des ordres de virement.';
      case 'NO_DEFAULT_BANK_ACCOUNT':
        return "Aucun compte bancaire de remboursement n'est configuré pour ce réseau. "
            'Contactez Neofid.';
      case 'NO_NEW_PERIOD':
        return 'Aucune nouvelle donnée depuis le dernier ordre de virement.';
      case 'NO_REFUND_IN_PERIOD':
        return 'Aucun remboursement à traiter$period.';
      case 'ZERO_TOTAL_AMOUNT':
        return 'Le total des remboursements$period est de 0,00 €, '
            "aucun ordre de virement n'a été généré.";
      default:
        return "Erreur lors de la génération de l'ordre de virement.";
    }
  }

  static const Map<String, String> _missingXmlParamLabels = {
    'holder': "le titulaire (donneur d'ordre)",
    'iban': "l'IBAN",
    'bic': 'le BIC',
  };

  /// Les paramètres SEPA sont portés par le compte bancaire, géré par Neofid.
  String _missingXmlParamsMessage(
      Map<dynamic, dynamic> details, BankAccountsModel? bankAccounts) {
    final String? code = details['bank_account']?.toString();
    final List<String> missing = (details['missing'] as List<dynamic>? ?? [])
        .map((item) =>
            _missingXmlParamLabels[item.toString()] ?? item.toString())
        .toList();

    final String account = code == null
        ? 'du compte bancaire'
        : 'du compte « ${bankAccounts?.labelForCode(code) ?? code} »';
    final String what = missing.isEmpty
        ? '(titulaire, IBAN, BIC)'
        : ': il manque ${_joinFrench(missing)}';

    return 'Les paramètres SEPA $account sont incomplets $what. '
        'Contactez Neofid.';
  }

  String _joinFrench(List<String> items) {
    if (items.length <= 1) return items.join();
    return '${items.sublist(0, items.length - 1).join(', ')} et ${items.last}';
  }

  /// ' du 01/09/2026 au 15/09/2026', ou '' si l'API n'a pas fourni la période.
  String _periodLabel(dynamic from, dynamic to) {
    final String start = _frenchDate(from);
    final String end = _frenchDate(to);
    if (start.isEmpty || end.isEmpty) return '';
    return ' du $start au $end';
  }

  String _frenchDate(dynamic isoDate) {
    final DateTime? parsed = DateTime.tryParse(isoDate?.toString() ?? '');
    if (parsed == null) return '';
    return DateFormat('dd/MM/yyyy').format(parsed);
  }

  static const Map<String, String> _missingEntityDataLabels = {
    'MISSING_ADDRESS': "l'adresse postale",
    'MISSING_BANK_DETAILS': 'les coordonnées bancaires (IBAN, BIC)',
  };

  String _incompleteEntityMessage(Map<dynamic, dynamic> details) {
    final String name = details['entity_name']?.toString() ?? 'ce partenaire';
    final String? code = details['entity_code']?.toString();
    final List<String> missing = (details['missing'] as List<dynamic>? ?? [])
        .map((item) =>
            _missingEntityDataLabels[item.toString()] ?? item.toString())
        .toList();

    final String target = code == null || code.isEmpty ? name : '$name ($code)';
    final String what = missing.isEmpty
        ? 'des informations obligatoires'
        : missing.join(' et ');

    return 'Impossible de générer les justificatifs pour $target : '
        '$what non renseignée(s). Complétez la fiche du partenaire puis réessayez.';
  }
}
