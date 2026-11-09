// Commandes restreintes à une liste de commerçants (spec du 28/10/2026) : une
// commande a au plus une liste (un nom et des commerçants) ; sans liste, ses
// chèques sont valables chez tous les commerçants du réseau.

/// Nombre maximal de caractères du nom d'une liste (contrôlé aussi par l'API).
const int kRestrictionLabelMaxLength = 60;

/// Restriction telle que la renvoient `GET /order`, `GET /order/{id}` et
/// `POST /order` : `{id, label, nb_commercants}`.
class OrderRestrictionSummary {
  final int? id;
  final String label;
  final int nbCommercants;

  const OrderRestrictionSummary({
    this.id,
    required this.label,
    required this.nbCommercants,
  });

  /// `null` si [value] n'est pas une restriction (champ absent ou `null`).
  static OrderRestrictionSummary? tryParse(dynamic value) {
    if (value is! Map) return null;
    return OrderRestrictionSummary(
      id: _intOrNull(value['id']),
      label: value['label']?.toString() ?? '',
      nbCommercants: _intOrNull(value['nb_commercants']) ?? 0,
    );
  }

  Map<String, dynamic> toJson() =>
      {'id': id, 'label': label, 'nb_commercants': nbCommercants};
}

/// Liste complète d'une commande (`GET` / `PUT /order/{id}/restriction`).
class OrderRestrictionModel {
  final int? id;
  final String label;
  final List<int> entityIds;
  final int nbCommercants;

  /// `false` quand tous les chèques de la commande ont expiré : la liste n'est
  /// plus affichée sur le site ni dans l'application.
  final bool active;
  final String? updatedDate;

  const OrderRestrictionModel({
    this.id,
    required this.label,
    required this.entityIds,
    required this.nbCommercants,
    this.active = true,
    this.updatedDate,
  });

  /// Lit `data` de la réponse : `{"restriction": {…}}` ou `{"restriction": null}`.
  /// Retourne `null` quand la commande n'a pas de liste.
  static OrderRestrictionModel? fromData(Map<String, dynamic> data) {
    final dynamic value = data['restriction'];
    if (value is! Map) return null;
    final List<int> ids = (value['entity_ids'] is List)
        ? (value['entity_ids'] as List)
            .map(_intOrNull)
            .whereType<int>()
            .toList()
        : <int>[];
    return OrderRestrictionModel(
      id: _intOrNull(value['id']),
      label: value['label']?.toString() ?? '',
      entityIds: ids,
      nbCommercants: _intOrNull(value['nb_commercants']) ?? ids.length,
      active: value['active'] == null ? true : _bool(value['active']),
      updatedDate: value['updated_date']?.toString(),
    );
  }

  OrderRestrictionSummary get summary =>
      OrderRestrictionSummary(id: id, label: label, nbCommercants: nbCommercants);
}

/// Corps envoyé à l'API : `{label, entity_ids}` (création de commande et
/// `PUT /order/{id}/restriction`, remplacement complet).
class OrderRestrictionInput {
  final String label;
  final List<int> entityIds;

  const OrderRestrictionInput({required this.label, required this.entityIds});

  Map<String, dynamic> toJson() => {'label': label, 'entity_ids': entityIds};
}

int? _intOrNull(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

bool _bool(dynamic value) => value == true || value == 1 || value == '1';
