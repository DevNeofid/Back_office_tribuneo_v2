import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:back_office_tribuneo_v2/config/size_config.dart';
import 'package:back_office_tribuneo_v2/domain/errors/blocked_refunds_exception.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/neo_button.dart';

/// Affiche les remboursements qui empêchent la génération de l'ordre de virement,
/// avec pour chacun ce qu'il reste à compléter.
///
/// L'API ne génère rien tant que la liste n'est pas vide : c'est volontaire, un
/// partenaire incomplet serait sinon exclu du fichier SEPA sans que personne ne le voie.
class BlockedRefundsDialog extends StatelessWidget {
  final List<BlockedRefund> refunds;

  const BlockedRefundsDialog({super.key, required this.refunds});

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);

    final bool plural = refunds.length > 1;

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
                'Aucun ordre de virement généré',
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
              plural
                  ? '${refunds.length} remboursements ne peuvent pas être traités. '
                      'Complétez les informations ci-dessous, puis relancez le déclenchement.'
                  : 'Un remboursement ne peut pas être traité. '
                      'Complétez les informations ci-dessous, puis relancez le déclenchement.',
              style: GoogleFonts.poppins(fontSize: 14, color: kBlack),
            ),
            const SizedBox(height: 20),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: refunds
                      .map((refund) => _RefundTile(refund: refund))
                      .toList(),
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

class _RefundTile extends StatelessWidget {
  final BlockedRefund refund;

  const _RefundTile({required this.refund});

  @override
  Widget build(BuildContext context) {
    final String title = refund.entityCode == null || refund.entityCode!.isEmpty
        ? refund.entityName
        : '${refund.entityName} (${refund.entityCode})';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: kPWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kRed.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(
            title,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: kBlueEnd,
            ),
          ),
          if (refund.transactionNumber.isNotEmpty) ...[
            const SizedBox(height: 2),
            SelectableText(
              'Transaction ${refund.transactionNumber}',
              style: GoogleFonts.poppins(fontSize: 12, color: kGrey),
            ),
          ],
          const SizedBox(height: 8),
          ...refund.reasonLabels.map(
            (label) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2, right: 8),
                    child: Icon(Icons.error_outline, size: 16, color: kRed),
                  ),
                  Expanded(
                    child: SelectableText(
                      label,
                      style: GoogleFonts.poppins(fontSize: 13, color: kBlack),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
