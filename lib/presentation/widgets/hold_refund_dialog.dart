import 'package:back_office_tribuneo_v2/presentation/widgets/tribuneo_loader.dart';
import 'package:flutter/material.dart';
import 'package:back_office_tribuneo_v2/domain/errors/api_exception.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/transfer_order_usecase.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/_global.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/arc/arc.dart';

/// Met une demande de remboursement en attente, avec un motif facultatif.
///
/// Retourne `true` dès qu'un appel a eu lieu (succès, ou erreur déjà affichée) :
/// l'appelant recharge alors l'aperçu. `null` si l'admin annule.
class HoldRefundDialog extends StatefulWidget {
  final String transactionNumber;
  final String merchantLabel;

  /// Date de la demande, déjà formatée (affichage seulement).
  final String? requestDate;

  /// Montant de la demande, déjà formaté (affichage seulement).
  final String? amount;

  const HoldRefundDialog({
    super.key,
    required this.transactionNumber,
    required this.merchantLabel,
    this.requestDate,
    this.amount,
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
      snackbarKey.currentState?.showSnackBar(arcStatusSnackBar(
          'Demande ${widget.transactionNumber} mise en attente.'));
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
      snackbarKey.currentState
          ?.showSnackBar(arcStatusSnackBar(e.message, error: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ArcDialog(
      icon: Icons.pause_rounded,
      tone: ArcTone.warning,
      title: 'Mettre en attente',
      maxWidth: 480,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
              "Cette demande ne sera pas payée tant qu'elle n'aura pas été libérée."),
          const SizedBox(height: 16),
          RefundRequestSummary(
            title: widget.merchantLabel,
            transactionNumber: widget.transactionNumber,
            date: widget.requestDate,
            amount: widget.amount,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _reasonController,
            enabled: !_isSubmitting,
            autofocus: true,
            maxLength: _maxReasonLength,
            maxLines: 3,
            minLines: 1,
            style: ArcText.body(),
            decoration: InputDecoration(
              labelText: 'Motif (facultatif)',
              hintText: 'Ex. justificatif à vérifier',
              errorText: _fieldError,
            ),
          ),
        ],
      ),
      actions: [
        OutlinedButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        _isSubmitting
            ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 11),
                child: SizedBox(
                    height: 22,
                    width: 22,
                    child: TribuneoLoader()),
              )
            : FilledButton(
                onPressed: _submit,
                child: const Text('Mettre en attente'),
              ),
      ],
    );
  }
}

/// Rappel de la demande concernée dans les dialogues « Mettre en attente » et
/// « Libérer » : commerçant, n° de demande et date, montant.
class RefundRequestSummary extends StatelessWidget {
  final String title;
  final String transactionNumber;
  final String? date;
  final String? amount;

  const RefundRequestSummary({
    super.key,
    required this.title,
    required this.transactionNumber,
    this.date,
    this.amount,
  });

  @override
  Widget build(BuildContext context) {
    final String? shownDate = (date?.isEmpty ?? true) ? null : date;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: kNavy50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(title,
                  style: ArcText.body(color: kNavy900)
                      .copyWith(fontWeight: FontWeight.w600)),
              SelectableText(
                  [
                    'Demande $transactionNumber',
                    if (shownDate != null) shownDate,
                  ].join(' · '),
                  style: ArcText.dataSmall(color: kText3)),
            ],
          ),
        ),
        if (amount != null) ...[
          const SizedBox(width: 12),
          Text(amount!,
              style: ArcText.data(color: kInk, fontWeight: FontWeight.w500)
                  .copyWith(fontSize: 15)),
        ],
      ]),
    );
  }
}

/// Notification « Arc » : navy avec coche verte (succès), blanche bordée de
/// framboise (erreur, affichée plus longtemps).
SnackBar arcStatusSnackBar(String message, {bool error = false}) {
  return SnackBar(
    duration: Duration(seconds: error ? 8 : 4),
    backgroundColor: error ? kSurface : null,
    shape: error
        ? RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xffF7B9CB)))
        : null,
    content: Row(children: [
      Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
            color: error ? kDangerBg : kSuccess, shape: BoxShape.circle),
        child: Icon(error ? Icons.priority_high_rounded : Icons.check_rounded,
            size: 15, color: error ? kDangerText : kNavy900),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(message,
            style: ArcText.small(color: error ? kInk : Colors.white)
                .copyWith(fontSize: 13)),
      ),
    ]),
  );
}
