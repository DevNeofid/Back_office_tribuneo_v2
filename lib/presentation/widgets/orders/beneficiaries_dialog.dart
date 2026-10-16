import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:back_office_tribuneo_v2/domain/errors/api_exception.dart';
import 'package:back_office_tribuneo_v2/domain/errors/order_error_messages.dart';
import 'package:back_office_tribuneo_v2/domain/models/order_beneficiaries_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/order_model.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/orders_usecase.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/_global.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/formatters.dart';

/// Bénéficiaires d'une commande importée par fichier : un bon par ligne.
///
/// Les drapeaux `can_*` de l'API décident de ce qui est modifiable ; une ligne
/// attribuée est entièrement en lecture seule. L'enregistrement envoie la liste
/// complète affichée. Retourne `true` si quelque chose a été enregistré.
class BeneficiariesDialog extends StatefulWidget {
  final OrderModel order;

  const BeneficiariesDialog({super.key, required this.order});

  @override
  State<BeneficiariesDialog> createState() => _BeneficiariesDialogState();
}

class _BeneficiariesDialogState extends State<BeneficiariesDialog> {
  final OrderUseCase _orderUseCase = OrderUseCase();

  OrderBeneficiariesModel? _data;
  List<_BeneficiaryRow> _rows = [];
  bool _isLoading = true;
  String? _loadError;
  bool _isSaving = false;
  bool _hasSaved = false;
  int? _resendingQrcode;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _disposeRows();
    super.dispose();
  }

  void _disposeRows() {
    for (final row in _rows) {
      row.dispose();
    }
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final OrderBeneficiariesModel data =
          await _orderUseCase.getBeneficiaries(widget.order.id!);
      if (!mounted) return;
      setState(() {
        _disposeRows();
        _data = data;
        _rows = data.beneficiaries.map(_BeneficiaryRow.existing).toList();
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.message;
        _isLoading = false;
      });
    }
  }

  /// Seules les commandes importées par fichier sont modifiables ici.
  bool get _editable => _data?.isImported ?? false;

  int get _modifiedCount =>
      _rows.where((r) => !r.isNew && !r.removed && r.isModified).length;
  int get _addedCount => _rows.where((r) => r.isNew).length;
  int get _removedCount => _rows.where((r) => !r.isNew && r.removed).length;
  bool get _isDirty =>
      _modifiedCount > 0 || _addedCount > 0 || _removedCount > 0;

  void _addRow() {
    setState(() => _rows.add(_BeneficiaryRow.created()));
  }

  void _removeRow(_BeneficiaryRow row) {
    setState(() {
      if (row.isNew) {
        _rows.remove(row);
        row.dispose();
      } else {
        row.removed = true;
        row.error = null;
      }
    });
  }

  void _restoreRow(_BeneficiaryRow row) {
    setState(() => row.removed = false);
  }

  /// Contrôles côté écran (l'API les refait) : montant > 0, e-mail ou mobile,
  /// format d'e-mail. Seules les lignes nouvelles ou modifiées sont contrôlées.
  bool _validate() {
    bool valid = true;
    for (final row in _rows) {
      row.error = null;
      if (row.removed || (!row.isNew && !row.isModified)) continue;
      row.error = row.validate();
      if (row.error != null) valid = false;
    }
    return valid;
  }

  Future<void> _save() async {
    if (_isSaving || !_editable) return;
    if (!_isDirty) {
      _snack('Aucune modification à enregistrer.', kBlue);
      return;
    }
    final bool valid = _validate();
    setState(() {});
    if (!valid) {
      _snack('Corrigez les lignes signalées avant d\'enregistrer.', kRed);
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enregistrer les bénéficiaires'),
        content: SizedBox(
          width: 480,
          child: Text('$_modifiedCount modification(s), $_addedCount ajout(s), '
              '$_removedCount retrait(s). Un e-mail sera envoyé aux nouveaux '
              'bénéficiaires et à ceux dont l\'adresse a changé.'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: kOrange, foregroundColor: kPWhite),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isSaving = true);
    try {
      final result = await _orderUseCase.updateBeneficiaries(
        widget.order.id!,
        _rows.where((r) => !r.removed).map((r) => r.toPayload()).toList(),
      );
      _hasSaved = true;
      _snack(
          'Enregistré. E-mails envoyés : ${result.mailsSent} '
          '(échecs : ${result.mailsFailed}).',
          kGreen);
      if (!mounted) return;
      setState(() => _isSaving = false);
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _snack(e.message, kRed);
    }
  }

  Future<void> _resendMail(_BeneficiaryRow row) async {
    final int? idQrcode = row.original?.idQrcode;
    if (idQrcode == null || _resendingQrcode != null) return;
    setState(() => _resendingQrcode = idQrcode);
    try {
      final String? email = await _orderUseCase.resendGiftMail(idQrcode);
      _snack('E-mail renvoyé à ${email ?? row.original?.email ?? ''}.', kGreen);
    } on ApiException catch (e) {
      _snack(e.message, kRed);
    } finally {
      if (mounted) setState(() => _resendingQrcode = null);
    }
  }

  Future<void> _close() async {
    if (_isDirty && _editable) {
      final bool? discard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Modifications non enregistrées'),
          content: const Text(
              'Fermer sans enregistrer ? Les modifications seront perdues.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Continuer la saisie')),
            TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Fermer sans enregistrer',
                    style: TextStyle(color: kRed))),
          ],
        ),
      );
      if (discard != true) return;
    }
    if (mounted) Navigator.of(context).pop(_hasSaved);
  }

  void _snack(String message, Color color) {
    snackbarKey.currentState?.showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 6)));
  }

  // ---------------------------------------------------------------------------
  // Affichage
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: AlertDialog(
        title: SelectableText(
            'Bénéficiaires - Commande ${_data?.orderNumber ?? widget.order.orderNumber ?? ''}'),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          child: _buildContent(),
        ),
        actions: [
          TextButton.icon(
            onPressed: _isLoading || _isSaving ? null : _load,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Recharger'),
          ),
          if (_editable && (_data?.canAdd ?? false))
            TextButton.icon(
              onPressed: _isSaving ? null : _addRow,
              icon: const Icon(Icons.person_add_alt, size: 18),
              label: const Text('Ajouter un bénéficiaire'),
            ),
          TextButton(
              onPressed: _isSaving ? null : _close,
              child: const Text('Fermer')),
          if (_editable)
            _isSaving
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
                    onPressed: _isLoading ? null : _save,
                    child: const Text('Enregistrer'),
                  ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: kBlue));
    }
    if (_loadError != null) {
      return Center(
          child: SelectableText(_loadError!,
              style: GoogleFonts.poppins(color: kRed)));
    }

    final OrderBeneficiariesModel data = _data!;
    final List<String> notices = [
      if (!data.isImported)
        OrderErrorMessages.forCode('NOT_AN_IMPORTED_ORDER', const {})!,
      if (data.isImported && data.invoiced)
        'Commande facturée : seuls le nom, l\'e-mail et le mobile des '
            'bénéficiaires non attribués peuvent encore être modifiés.',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...notices.map((notice) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kOrange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: kOrange, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(notice,
                          style: GoogleFonts.poppins(
                              fontSize: 13, color: kBlueEnd))),
                ],
              ),
            )),
        if (_rows.isEmpty)
          const Expanded(
              child: Center(child: Text('Aucun bénéficiaire pour cette commande.')))
        else
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: _buildTable(),
                ),
              ),
            ),
          ),
        if (_editable && _isDirty) ...[
          const SizedBox(height: 10),
          Text(
              'Non enregistré : $_modifiedCount modification(s), $_addedCount '
              'ajout(s), $_removedCount retrait(s).',
              style: GoogleFonts.poppins(fontSize: 13, color: kOrange)),
        ],
      ],
    );
  }

  static const Map<int, TableColumnWidth> _columnWidths = {
    0: FixedColumnWidth(150),
    1: FixedColumnWidth(150),
    2: FixedColumnWidth(250),
    3: FixedColumnWidth(140),
    4: FixedColumnWidth(110),
    5: FixedColumnWidth(100),
    6: FixedColumnWidth(220),
    7: FixedColumnWidth(110),
  };

  Widget _buildTable() {
    return Table(
      columnWidths: _columnWidths,
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      border: TableBorder(
          horizontalInside: BorderSide(color: kLBlue.withValues(alpha: 0.5))),
      children: [
        TableRow(
          decoration: const BoxDecoration(color: kBlue),
          children: const [
            'Prénom',
            'Nom',
            'E-mail',
            'Mobile',
            'Montant',
            'Reste',
            'Statut',
            'Actions',
          ]
              .map((label) => Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 8),
                    child: Text(label,
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: kWhite)),
                  ))
              .toList(),
        ),
        for (int i = 0; i < _rows.length; i++) _buildRow(_rows[i], i),
      ],
    );
  }

  TableRow _buildRow(_BeneficiaryRow row, int index) {
    final OrderBeneficiaryModel? original = row.original;
    final bool assigned = original?.assigned ?? false;
    final bool canEditContact = _editable && !row.removed && row.canEditContact;
    final bool canEditAmount = _editable && !row.removed && row.canEditAmount;

    // Une ligne attribuée est entièrement en lecture seule, avec l'explication.
    final String? lockedTooltip = assigned
        ? 'Ce bon est déjà attribué au compte de '
            '${original?.assignedTo ?? 'un consommateur'} : il ne peut plus '
            'être modifié.'
        : null;

    Color? background;
    if (row.error != null) {
      background = kRed.withValues(alpha: 0.08);
    } else if (row.removed) {
      background = Colors.grey.withValues(alpha: 0.12);
    } else if (row.isNew) {
      background = kGreen.withValues(alpha: 0.06);
    } else if (index.isOdd) {
      background = kLBlue.withValues(alpha: 0.10);
    }

    final String status = row.isNew
        ? 'Nouveau'
        : assigned
            ? 'Attribué à ${original?.assignedTo ?? ''}'
            : 'En attente';

    return TableRow(
      decoration: BoxDecoration(color: background),
      children: [
        _field(row.firstname, canEditContact, row.removed, lockedTooltip),
        _field(row.lastname, canEditContact, row.removed, lockedTooltip),
        _field(row.email, canEditContact, row.removed, lockedTooltip,
            keyboardType: TextInputType.emailAddress),
        _field(row.mobile, canEditContact, row.removed, lockedTooltip,
            keyboardType: TextInputType.phone),
        _field(row.amount, canEditAmount, row.removed, lockedTooltip,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            formatter: FilteringTextInputFormatter.allow(
                RegExp(r'^\d*[.,]?\d{0,2}'))),
        _text(row.isNew ? '—' : formatEuro(original!.remainingAmount),
            row.removed, lockedTooltip),
        _text(status, row.removed, lockedTooltip),
        _actions(row),
      ],
    );
  }

  Widget _withTooltip(String? tooltip, Widget child) =>
      tooltip == null ? child : Tooltip(message: tooltip, child: child);

  Widget _text(String text, bool removed, String? tooltip) {
    return _withTooltip(
      tooltip,
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Text(text,
            style: GoogleFonts.poppins(
                fontSize: 13,
                color: removed ? kGrey : kBlueEnd,
                decoration: removed ? TextDecoration.lineThrough : null)),
      ),
    );
  }

  Widget _field(TextEditingController controller, bool editable, bool removed,
      String? tooltip,
      {TextInputType? keyboardType, TextInputFormatter? formatter}) {
    if (!editable) return _text(controller.text, removed, tooltip);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: formatter == null ? null : [formatter],
        onChanged: (_) => setState(() {}),
        style: GoogleFonts.poppins(fontSize: 13, color: kBlueEnd),
        decoration: const InputDecoration(
          isDense: true,
          filled: true,
          fillColor: kPWhite,
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          border: OutlineInputBorder(),
          focusedBorder:
              OutlineInputBorder(borderSide: BorderSide(color: kBlue)),
        ),
      ),
    );
  }

  Widget _actions(_BeneficiaryRow row) {
    final OrderBeneficiaryModel? original = row.original;
    final bool resending =
        original?.idQrcode != null && _resendingQrcode == original!.idQrcode;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (row.error != null)
          Tooltip(
            message: row.error!,
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.error, color: kRed, size: 20),
            ),
          ),
        if (_editable && row.removed)
          IconButton(
            tooltip: 'Annuler le retrait',
            icon: const Icon(Icons.undo, color: kBlue, size: 20),
            onPressed: _isSaving ? null : () => _restoreRow(row),
          )
        else if (_editable && row.canRemove)
          IconButton(
            tooltip: 'Retirer',
            icon: const Icon(Icons.person_remove_alt_1_outlined,
                color: kRed, size: 20),
            onPressed: _isSaving ? null : () => _removeRow(row),
          ),
        if (!row.isNew && !row.removed && (original?.canResendMail ?? false))
          resending
              ? const Padding(
                  padding: EdgeInsets.all(10),
                  child: SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: kBlue)),
                )
              : IconButton(
                  tooltip: row.isModified
                      ? "Renvoyer l'e-mail (à l'adresse enregistrée)"
                      : "Renvoyer l'e-mail",
                  icon: const Icon(Icons.forward_to_inbox,
                      color: kBlue, size: 20),
                  onPressed: _isSaving || _resendingQrcode != null
                      ? null
                      : () => _resendMail(row),
                ),
      ],
    );
  }
}

/// Une ligne de l'écran : un bon existant ([original] non nul) ou un ajout.
class _BeneficiaryRow {
  final OrderBeneficiaryModel? original;
  final TextEditingController firstname;
  final TextEditingController lastname;
  final TextEditingController email;
  final TextEditingController mobile;
  final TextEditingController amount;
  bool removed = false;
  String? error;

  _BeneficiaryRow._(this.original,
      {String? firstname,
      String? lastname,
      String? email,
      String? mobile,
      String? amount})
      : firstname = TextEditingController(text: firstname ?? ''),
        lastname = TextEditingController(text: lastname ?? ''),
        email = TextEditingController(text: email ?? ''),
        mobile = TextEditingController(text: mobile ?? ''),
        amount = TextEditingController(text: amount ?? '');

  factory _BeneficiaryRow.existing(OrderBeneficiaryModel beneficiary) {
    return _BeneficiaryRow._(
      beneficiary,
      firstname: beneficiary.firstname,
      lastname: beneficiary.lastname,
      email: beneficiary.email,
      mobile: beneficiary.mobile,
      amount: _formatAmount(beneficiary.amount),
    );
  }

  factory _BeneficiaryRow.created() => _BeneficiaryRow._(null);

  bool get isNew => original == null;
  bool get canEditContact => isNew || original!.canEditContact;
  bool get canEditAmount => isNew || original!.canEditAmount;
  bool get canRemove => isNew || original!.canRemove;

  num? get parsedAmount =>
      num.tryParse(amount.text.trim().replaceAll(',', '.'));

  bool get isModified {
    final OrderBeneficiaryModel? o = original;
    if (o == null) return false;
    return _differs(firstname, o.firstname) ||
        _differs(lastname, o.lastname) ||
        _differs(email, o.email) ||
        _differs(mobile, o.mobile) ||
        parsedAmount != o.amount;
  }

  static bool _differs(TextEditingController controller, String? value) =>
      controller.text.trim() != (value ?? '').trim();

  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  String? validate() {
    final num? value = parsedAmount;
    if (value == null || value <= 0) {
      return 'Le montant doit être supérieur à 0.';
    }
    final String mail = email.text.trim();
    if (mail.isEmpty && mobile.text.trim().isEmpty) {
      return "Renseignez l'e-mail ou le mobile.";
    }
    if (mail.isNotEmpty && !_emailRegex.hasMatch(mail)) {
      return "Format d'e-mail invalide.";
    }
    return null;
  }

  Map<String, dynamic> toPayload() {
    String? text(TextEditingController controller) {
      final String value = controller.text.trim();
      return value.isEmpty ? null : value;
    }

    return {
      if (original?.idQrcode != null) 'id_qrcode': original!.idQrcode,
      'amount': parsedAmount ?? original?.amount,
      'email': text(email),
      'mobile': text(mobile),
      'firstname': text(firstname),
      'lastname': text(lastname),
    };
  }

  void dispose() {
    firstname.dispose();
    lastname.dispose();
    email.dispose();
    mobile.dispose();
    amount.dispose();
  }

  static String _formatAmount(num value) =>
      value == value.roundToDouble() ? value.toInt().toString() : '$value';
}
