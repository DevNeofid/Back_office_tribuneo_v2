import 'dart:convert';
import '../../errors/merchant_enrichment_messages.dart';
import 'chat_context_reference.dart';
import 'enrichment_models.dart';

class ResearchCriteria {
  static const limits = {
    'name': 512,
    'siret': 14,
    'street': 512,
    'zip': 20,
    'city': 128,
    'country': 80
  };
  final Map<String, String> values;
  final bool invalidRaw;
  ResearchCriteria(Map<String, String> input)
      : invalidRaw = input.entries.any((e) =>
            !limits.containsKey(e.key) ||
            e.value.runes.length > (limits[e.key] ?? 0) ||
            RegExp(r'[\x00-\x1f\x7f-\x9f]').hasMatch(e.value)),
        values = Map.unmodifiable(
            {for (final k in limits.keys) k: (input[k] ?? '').trim()});

  factory ResearchCriteria.fromJson(Json json) {
    if (json.length != 6 || limits.keys.any((k) => json[k] is! String)) {
      throw const EnrichmentException();
    }
    final result = ResearchCriteria(json.cast<String, String>());
    if (result.error != null) throw const EnrichmentException();
    return result;
  }
  Json toJson() => {...values, 'country': 'FR'};
  String? get error {
    if (invalidRaw)
      return 'Un critère est trop long ou contient un caractère non autorisé. Corrigez-le, puis relancez.';
    for (final entry in values.entries) {
      if (entry.value.runes.length > limits[entry.key]! ||
          RegExp(r'[\x00-\x1f\x7f-\x9f]|(?:[a-z][a-z0-9+.-]*://|www\.|javascript:|data:|mailto:|file:|ftp:)',
                  caseSensitive: false)
              .hasMatch(entry.value))
        return 'Le champ « ${MerchantEnrichmentMessages.field(entry.key)} » est trop long ou contient un lien ou un caractère non autorisé. Corrigez-le, puis relancez.';
    }
    final siret = values['siret']!;
    if (siret.isNotEmpty) {
      if (!RegExp(r'^\d{14}$').hasMatch(siret))
        return 'Le SIRET doit contenir exactement 14 chiffres, sans espace ni lettre.';
      var sum = 0;
      for (var i = 0; i < 14; i++) {
        var n = int.parse(siret[i]) * (i.isEven ? 2 : 1);
        sum += n > 9 ? n - 9 : n;
      }
      if (sum % 10 != 0)
        return 'Ce SIRET n’est pas valide : vérifiez les 14 chiffres saisis.';
    }
    final zip = values['zip']!;
    if (zip.isNotEmpty && !RegExp(r'^\d{5}$').hasMatch(zip))
      return 'Le code postal doit contenir 5 chiffres.';
    if (!{'', 'fr', 'france'}.contains(values['country']!.toLowerCase()))
      return 'La recherche ne couvre que la France : indiquez « France » ou laissez le pays vide.';
    if (utf8.encode(jsonEncode(toJson())).length > 4096)
      return 'Les critères sont trop longs. Raccourcissez le nom ou l’adresse, puis relancez.';
    if (siret.isEmpty &&
        ((values['name']!.isEmpty && values['street']!.isEmpty) ||
            (zip.isEmpty && values['city']!.isEmpty)))
      return 'Indiquez un SIRET, ou un nom ou une adresse avec le code postal ou la ville.';
    return null;
  }
}

class ResearchMetadata {
  final EnrichmentJob job;
  final int rowId, baseVersion;
  final String sourceProposalId;
  final ResearchCriteria criteria;
  ResearchMetadata.fromJson(Json json)
      : job = EnrichmentJob.fromJson(object(json['job'])),
        rowId = json['row_id'] as int,
        baseVersion = json['base_version'] as int,
        sourceProposalId = json['source_proposal_id'] as String,
        criteria = ResearchCriteria.fromJson(object(json['criteria'])) {
    if (rowId < 1 ||
        baseVersion < 1 ||
        !ChatContextReference.uuid.hasMatch(sourceProposalId)) {
      throw const EnrichmentException();
    }
  }
}
