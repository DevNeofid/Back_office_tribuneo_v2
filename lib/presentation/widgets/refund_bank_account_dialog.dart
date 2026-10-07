import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:back_office_tribuneo_v2/config/size_config.dart';
import 'package:back_office_tribuneo_v2/domain/models/bank_account_model.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/neo_button.dart';

/// Fait choisir le compte depuis lequel les partenaires seront remboursés, avant la
/// génération de l'ordre de virement. Présélectionné sur le compte `is_refund`.
///
/// Retourne le compte choisi, ou `null` si l'admin annule.
/// À n'ouvrir qu'avec plusieurs comptes (`refundSelectRequired`).
class RefundBankAccountDialog extends StatefulWidget {
  final BankAccountsModel bankAccounts;

  const RefundBankAccountDialog({super.key, required this.bankAccounts});

  @override
  State<RefundBankAccountDialog> createState() =>
      _RefundBankAccountDialogState();
}

class _RefundBankAccountDialogState extends State<RefundBankAccountDialog> {
  late BankAccountModel _selected;

  @override
  void initState() {
    super.initState();
    // Le dialogue n'est ouvert qu'avec plusieurs comptes : la liste n'est pas vide.
    _selected =
        widget.bankAccounts.refundAccount ?? widget.bankAccounts.accounts.first;
  }

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
                'Compte payeur',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  letterSpacing: 0.3,
                  fontWeight: FontWeight.w600,
                  color: kBlueEnd,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SelectableText(
              "Choisissez le compte depuis lequel les partenaires seront remboursés. "
              "Le fichier SEPA de l'ordre de virement portera son IBAN et son BIC.",
              style: GoogleFonts.poppins(fontSize: 14, color: kBlack),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: kPWhite,
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButton<BankAccountModel>(
                isExpanded: true,
                underline: const SizedBox(),
                value: _selected,
                onChanged: (BankAccountModel? account) {
                  if (account != null) setState(() => _selected = account);
                },
                items: widget.bankAccounts.accounts
                    .map((account) => DropdownMenuItem<BankAccountModel>(
                          value: account,
                          child: Text(account.selectLabel,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                  fontSize: 13, color: kBlueEnd)),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                const SizedBox(width: 12),
                NeoButton(
                  text: 'Générer',
                  onPressed: () => Navigator.pop(context, _selected),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
