import 'package:intl/intl.dart';

/// Messages français des erreurs métier sur les commandes, les bons et les
/// bénéficiaires (spec corrections du 15/10/2026, section 6).
///
/// Le code est `error.details.code`, à défaut `error.type` : jamais `description`.
class OrderErrorMessages {
  static final NumberFormat _amountFormat = NumberFormat('#,##0.##', 'fr_FR');

  /// Message à afficher pour [code], ou `null` si le code n'est pas un code métier
  /// connu (l'appelant choisit alors son message générique).
  static String? forCode(String? code, Map<String, dynamic> details) {
    switch (code) {
      case 'INVALID_EXPIRY_DATE':
        return 'Date invalide.';
      case 'EXPIRY_DATE_TOO_EARLY':
        return 'La date doit être au plus tôt demain.';
      case 'SHORTENING_ASSIGNED_VOUCHER':
        return 'Ce bon est déjà attribué : sa date peut seulement être prolongée.';
      case 'VOUCHER_NOT_FOUND':
      case 'ORDER_NOT_FOUND':
        return 'Introuvable. Rechargez la page.';
      case 'VOUCHER_DELETED':
        return 'Ce bon a été annulé.';
      case 'ORDER_INVOICED':
        return 'Cette commande est facturée : seule la date de validité peut encore '
            'être modifiée (et, pour une commande importée, le contact des '
            'bénéficiaires non attribués).';
      case 'IMPORTED_ORDER_LINES':
        return 'Commande importée : modifiez les bénéficiaires depuis l\'écran '
            'Bénéficiaires.';
      case 'SHOP_ORDER_LINES':
        return 'Commande de la boutique en ligne : les lignes ne sont pas modifiables.';
      case 'NOT_ENOUGH_UNASSIGNED_VOUCHERS':
        final num? amount = _num(details['amount']);
        final num? removable = _num(details['removable']);
        return 'Impossible de retirer autant de bons de '
            '${amount == null ? '?' : _amountFormat.format(amount)} € : seuls '
            '${removable ?? 0} ne sont pas encore attribués.';
      case 'NOT_AN_IMPORTED_ORDER':
        return 'Cette commande n\'a pas été importée par fichier.';
      case 'VOUCHER_ASSIGNED':
        final List<String> ids = (details['id_qrcodes'] as List<dynamic>? ?? [])
            .map((id) => id.toString())
            .toList();
        return 'Ces bons sont déjà attribués à des consommateurs : ils ne peuvent '
            'plus être modifiés ni retirés.'
            '${ids.isEmpty ? '' : ' (bon${ids.length > 1 ? 's' : ''} n° ${ids.join(', ')})'}';
      case 'UNKNOWN_VOUCHER':
      case 'DUPLICATE_VOUCHER':
        return 'La liste a changé entre-temps. Rechargez la page.';
      case 'NO_EMAIL':
        return 'Ce bénéficiaire n\'a pas d\'adresse e-mail.';
      case 'MAIL_NOT_SENT':
        return 'L\'e-mail n\'a pas pu être envoyé. Réessayez plus tard.';
      case 'INSUFFICIENT_PRIVILEGES':
        return 'Vous n\'avez pas accès à cette ressource.';
      default:
        return restrictionMessageForCode(code);
    }
  }

  /// Codes des commerçants refusés par `RESTRICTION_UNKNOWN_ENTITIES`.
  static const String restrictionUnknownEntities =
      'RESTRICTION_UNKNOWN_ENTITIES';

  /// Messages des refus liés à la liste de commerçants d'une commande (spec
  /// commandes restreintes du 28/10/2026, section 6), `null` pour tout autre code.
  static String? restrictionMessageForCode(String? code) {
    switch (code) {
      case 'RESTRICTION_LABEL_REQUIRED':
        return 'Donnez un nom à la liste.';
      case 'RESTRICTION_LABEL_TOO_LONG':
        return 'Le nom de la liste ne doit pas dépasser 60 caractères.';
      case 'RESTRICTION_EMPTY':
        return 'Sélectionnez au moins un commerçant.';
      case restrictionUnknownEntities:
        return 'Certains commerçants ne font plus partie du réseau. Rechargez '
            'la liste et vérifiez votre sélection.';
      default:
        return null;
    }
  }

  /// Message de `ORDER_NOT_FOUND` sur les routes de la liste de commerçants.
  static const String restrictionOrderNotFound =
      "Cette commande n'existe plus.";

  /// Ids refusés par `RESTRICTION_UNKNOWN_ENTITIES` (`details.entity_ids`).
  static List<int> unknownEntityIds(Map<String, dynamic> details) {
    final dynamic ids = details['entity_ids'];
    if (ids is! List) return const [];
    return ids
        .map((id) => id is int ? id : int.tryParse(id?.toString() ?? ''))
        .whereType<int>()
        .toList();
  }

  static num? _num(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '');
  }
}
