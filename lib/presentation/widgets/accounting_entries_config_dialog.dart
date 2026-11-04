import 'package:flutter/material.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/arc/arc.dart';

/// Affiche les comptes bancaires qui empêchent la génération des écritures comptables
/// (journal ou compte 512 manquant). Ce paramétrage est géré par Neofid.
class AccountingEntriesConfigDialog extends StatelessWidget {
  /// Manques renvoyés par l'API, affichés tels quels.
  final List<String> errors;

  const AccountingEntriesConfigDialog({super.key, required this.errors});

  @override
  Widget build(BuildContext context) {
    final double maxListHeight = MediaQuery.of(context).size.height * 0.4;

    return ArcDialog(
      icon: Icons.error_outline_rounded,
      tone: ArcTone.danger,
      title: 'Aucune écriture comptable générée',
      maxWidth: 540,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SelectableText(
            'Un ou plusieurs comptes bancaires utilisés sur la période n\'ont pas '
            'de journal ou de compte 512 renseigné. Contactez Neofid pour compléter '
            'leur paramétrage, puis relancez le déclenchement.',
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxListHeight),
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kBorder),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (int i = 0; i < errors.length; i++)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xffFFFBF3),
                          border: i == 0
                              ? null
                              : const Border(top: BorderSide(color: kNavy100)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 2, right: 10),
                              child: Icon(Icons.error_outline_rounded,
                                  size: 18, color: kDangerText),
                            ),
                            Expanded(
                              child: SelectableText(
                                errors[i],
                                style: ArcText.body(color: kInk)
                                    .copyWith(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
      ],
    );
  }
}
