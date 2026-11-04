import '../../utils/common.dart';
import 'ui/enrichment_dialog.dart';
import 'package:flutter/material.dart';
import '../../../domain/errors/merchant_enrichment_messages.dart';
import '../../../domain/models/merchant_enrichment/enrichment_models.dart';
import '../../../domain/models/merchant_enrichment/vat_status.dart';

/// Libellé du statut TVA. Sans capability `vat`, toujours « Non vérifiée » (lot 01).
/// Délègue au catalogue partagé : aucune seconde copie des textes.
String vatStatusLabel(String status, {required bool capability}) =>
    MerchantEnrichmentMessages.vatStatus(status, capability: capability);

const vatDisclaimer =
    'Présence dans le jeu public DGFiP à la date de lecture indiquée. Ce n’est ni une '
    'vérification VIES en temps réel ni une garantie d’assujettissement.';

/// Section TVA de la comparaison d’un candidat : statut, valeur, source datée et, pour une
/// valeur trouvée seulement, la case de choix. Aucune action de vérification n’est proposée.
class VatCandidateSection extends StatelessWidget {
  final EnrichmentCandidate candidate;
  final bool capability, selected, applicable, busy, rowSiretEmpty;
  final String rowValue;
  final ValueChanged<bool> onChanged;
  const VatCandidateSection(
      {super.key,
      required this.candidate,
      required this.capability,
      required this.selected,
      required this.applicable,
      required this.busy,
      required this.rowSiretEmpty,
      required this.rowValue,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final number = capability ? VatRules.proposedNumber(candidate) : null;
    final source = candidate.sources[VatRules.field];
    return Container(
        key: const ValueKey('vat-section'),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: kLGrey,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kLBlue)),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('TVA intracommunautaire',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: kBlueEnd, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          SelectableText(
              'Statut : ${vatStatusLabel(candidate.vatStatus, capability: capability)}'
              '${rowValue.isEmpty ? '' : '\nValeur actuelle conservée : $rowValue'}',
              key: const ValueKey('vat-status')),
          if (number != null) ...[
            CheckboxListTile(
                key: const ValueKey('vat-choice'),
                dense: true,
                contentPadding: EdgeInsets.zero,
                value: selected,
                onChanged: !applicable || busy
                    ? null
                    : (value) => onChanged(value == true),
                title: Text('Appliquer la TVA $number'),
                subtitle: Text(rowSiretEmpty
                    ? 'La ligne n’a pas de SIRET : la TVA s’applique avec le SIRET ${candidate.siret} de ce candidat, dans la même opération.'
                    : 'Rattachée au SIREN ${candidate.siren} du SIRET de la ligne.')),
            if (source != null) ...[
              SelectableText(
                  'Source : DGFiP, numéros de TVA intracommunautaire (data.economie.gouv.fr) · '
                  'Date de lecture : ${MerchantEnrichmentMessages.sourceDate(source.retrievedAt)} · '
                  'Référence : ${source.recordId ?? '—'}',
                  key: const ValueKey('vat-source')),
              // Adresse complète de la requête au survol, pas dans le texte.
              Align(
                  alignment: Alignment.centerLeft,
                  child: EnrichmentSourceLink(source.url,
                      key: const ValueKey('vat-source-link'))),
            ],
          ],
          if (capability && candidate.vatStatus != VatStatus.notChecked)
            const Text(vatDisclaimer,
                key: ValueKey('vat-disclaimer'),
                style: TextStyle(fontStyle: FontStyle.italic)),
        ]));
  }
}
