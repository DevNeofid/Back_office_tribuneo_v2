import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:back_office_tribuneo_v2/config/size_config.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/neo_button.dart';

/// Affiche les comptes bancaires qui empêchent la génération des écritures comptables
/// (journal ou compte 512 manquant). Ce paramétrage est géré par Neofid.
class AccountingEntriesConfigDialog extends StatelessWidget {
  /// Manques renvoyés par l'API, affichés tels quels.
  final List<String> errors;

  const AccountingEntriesConfigDialog({super.key, required this.errors});

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);

    return AlertDialog(
      backgroundColor: Colors.transparent,
      contentPadding: const EdgeInsets.all(0),
      content: Container(
        width: SizeConfig.screenWidth * 0.45,
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          color: kPLGrey2,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: SelectableText(
                'Aucune écriture comptable générée',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  letterSpacing: 0.3,
                  fontWeight: FontWeight.w600,
                  color: kRed,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SelectableText(
              'Un ou plusieurs comptes bancaires utilisés sur la période n\'ont pas '
              'de journal ou de compte 512 renseigné. Contactez Neofid pour compléter '
              'leur paramétrage, puis relancez le déclenchement.',
              style: GoogleFonts.poppins(fontSize: 14, color: kBlack),
            ),
            const SizedBox(height: 20),
            Flexible(
              child: SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: kPWhite,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: kRed.withValues(alpha: 0.35)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: errors
                        .map(
                          (error) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.only(top: 2, right: 8),
                                  child: Icon(Icons.error_outline,
                                      size: 16, color: kRed),
                                ),
                                Expanded(
                                  child: SelectableText(
                                    error,
                                    style: GoogleFonts.poppins(
                                        fontSize: 13, color: kBlack),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Align(
              alignment: Alignment.centerRight,
              child: NeoButton(
                text: 'Fermer',
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
