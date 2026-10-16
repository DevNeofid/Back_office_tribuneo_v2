import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:back_office_tribuneo_v2/domain/errors/api_exception.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/transfer_order_usecase.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/_global.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';

/// Met une demande de remboursement en attente, avec un motif facultatif.
///
/// Retourne `true` dès qu'un appel a eu lieu (succès, ou erreur déjà affichée) :
/// l'appelant recharge alors l'aperçu. `null` si l'admin annule.
class HoldRefundDialog extends StatefulWidget {
  final String transactionNumber;
  final String merchantLabel;

  const HoldRefundDialog({
    super.key,
    required this.transactionNumber,
    required this.merchantLabel,
  });

  @override
  State<HoldRefundDialog> createState() => _HoldRefundDialogState();
}

class _HoldRefundDialogState extends State<HoldRefundDialog> {
  static const int _maxReasonLength = 255;

  final TransferOrderUseCase _transferOrderUseCase = TransferOrderUseCase();
  final TextEditingController _reasonController = TextEditingController();
  bool _isSubmitting = false;
  String? _fieldError;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() {
      _isSubmitting = true;
      _fieldError = null;
    });
    try {
      await _transferOrderUseCase.holdRefund(widget.transactionNumber,
          reason: _reasonController.text);
      if (!mounted) return;
      Navigator.of(context).pop(true);
      snackbarKey.currentState?.showSnackBar(SnackBar(
          content: Text('Demande ${widget.transactionNumber} mise en attente.'),
          backgroundColor: kGreen));
    } on ApiException catch (e) {
      if (!mounted) return;
      // Motif refusé : on reste sur le dialogue, message sous le champ.
      if (e.code == 'VALIDATION_ERROR') {
        setState(() {
          _fieldError = e.message;
          _isSubmitting = false;
        });
        return;
      }
      Navigator.of(context).pop(true);
      snackbarKey.currentState?.showSnackBar(SnackBar(
          content: Text(e.message),
          backgroundColor: kRed,
          duration: const Duration(seconds: 8)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Mettre en attente',
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600, color: kBlueEnd)),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              'Demande ${widget.transactionNumber} — ${widget.merchantLabel}',
              style: GoogleFonts.poppins(fontSize: 13, color: kGrey),
            ),
            const SizedBox(height: 8),
            Text(
              "Cette demande ne sera pas payée tant qu'elle n'aura pas été libérée.",
              style: GoogleFonts.poppins(fontSize: 13, color: kBlack),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              enabled: !_isSubmitting,
              autofocus: true,
              maxLength: _maxReasonLength,
              maxLines: 3,
              minLines: 1,
              decoration: InputDecoration(
                labelText: 'Motif (facultatif)',
                floatingLabelStyle: const TextStyle(color: kBlue),
                errorText: _fieldError,
                border: const OutlineInputBorder(),
                focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: kBlue)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        _isSubmitting
            ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: kOrange)),
              )
            : ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: kOrange, foregroundColor: kPWhite),
                onPressed: _submit,
                child: const Text('Mettre en attente'),
              ),
      ],
    );
  }
}
