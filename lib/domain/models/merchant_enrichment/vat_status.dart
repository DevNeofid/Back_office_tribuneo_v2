import 'enrichment_models.dart';

/// Statut TVA d'un candidat (contrat v1.1). `found` = présent dans la source datée,
/// jamais une validation VIES en temps réel ni une garantie d'assujettissement.
class VatStatus {
  static const notChecked = 'not_checked',
      found = 'found',
      notFound = 'not_found',
      unavailable = 'unavailable',
      ambiguous = 'ambiguous';
  static const values = {notChecked, found, notFound, unavailable, ambiguous};

  static String parse(dynamic value) =>
      value is String && values.contains(value) ? value : notChecked;
}

/// Règles BO de la TVA sourcée. Le serveur reste juge (flag, SIREN, SIRET effectif,
/// version) ; le BO n'offre le choix que lorsque le serveur pourrait l'accepter.
class VatRules {
  static const field = 'intracommunity_vat_number';
  static const provider = 'dgfip_tva';
  static final _number = RegExp(r'^FR[0-9A-Z]{2}[0-9]{9}$');

  /// Numéro proposé, seulement s'il est trouvé, bien formé, sourcé DGFiP et rattaché
  /// au SIREN (et donc au SIRET) du candidat. Sinon null : rien à appliquer.
  static String? proposedNumber(EnrichmentCandidate candidate) {
    final value = candidate.fields[field];
    final siren = candidate.siren ?? '';
    if (candidate.vatStatus != VatStatus.found ||
        candidate.kind != 'establishment' ||
        value is! String ||
        !_number.hasMatch(value) ||
        value.substring(4) != siren ||
        !(candidate.siret ?? '').startsWith(siren) ||
        candidate.sources[field]?.provider != provider) return null;
    return value;
  }

  /// La TVA est applicable si la capability est active, la valeur trouvée, la TVA de la
  /// ligne vide, et le SIRET effectif après application est celui du candidat : déjà
  /// saisi, ou applicable dans la même opération (`others` contient alors `siret`).
  static bool applicable(
      {required bool capability,
      required EnrichmentCandidate candidate,
      required String rowSiret,
      required bool rowVatEmpty,
      required Set<String> others}) {
    if (!capability || !rowVatEmpty || proposedNumber(candidate) == null) {
      return false;
    }
    return rowSiret.isEmpty
        ? others.contains('siret')
        : rowSiret == candidate.siret;
  }

  /// Sur une ligne sans SIRET, cocher la TVA coche aussi le SIRET du candidat, et
  /// décocher le SIRET décoche la TVA : jamais de TVA seule sans lien d'identité.
  static void select(Set<String> selection, String key, bool value,
      {required bool rowSiretEmpty}) {
    if (value) {
      selection.add(key);
      if (key == field && rowSiretEmpty) selection.add('siret');
    } else {
      selection.remove(key);
      if (key == 'siret' && rowSiretEmpty) selection.remove(field);
    }
  }

  /// Sélection envoyable : une TVA sur ligne sans SIRET exige le SIRET choisi avec elle.
  static bool selectionValid(Set<String> selection,
          {required bool rowSiretEmpty}) =>
      !selection.contains(field) ||
      !rowSiretEmpty ||
      selection.contains('siret');
}
