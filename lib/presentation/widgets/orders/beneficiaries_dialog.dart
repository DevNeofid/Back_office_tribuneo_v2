import 'package:back_office_tribuneo_v2/presentation/widgets/tribuneo_loader.dart';
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
import 'package:back_office_tribuneo_v2/presentation/widgets/arc/arc.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/orders/order_sheet.dart';

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
      builder: (context) => ArcDialog(
        icon: Icons.group_outlined,
        title: 'Enregistrer les bénéficiaires',
        maxWidth: 480,
        content: Text('$_modifiedCount modification(s), $_addedCount ajout(s), '
            '$_removedCount retrait(s). Un e-mail sera envoyé aux nouveaux '
            'bénéficiaires et à ceux dont l\'adresse a changé.'),
        actions: [
          OutlinedButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler')),
          FilledButton(
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
        builder: (context) => ArcDialog(
          icon: Icons.warning_amber_rounded,
          tone: ArcTone.warning,
          title: 'Modifications non enregistrées',
          content: const Text(
              'Fermer sans enregistrer ? Les modifications seront perdues.'),
          actions: [
            OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Continuer la saisie')),
            FilledButton(
                style: arcDangerButtonStyle(),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Fermer sans enregistrer')),
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

  /// « C202610161 · Jey · Hors évènement Urssaf », sans les parties absentes.
  String get _eyebrow => [
        _data?.orderNumber ?? widget.order.orderNumber,
        widget.order.giftFrom,
        widget.order.giftReason,
      ]
          .map((part) => part?.trim() ?? '')
          .where((part) => part.isNotEmpty)
          .join(' · ');

  @override
  Widget build(BuildContext context) {
    final String eyebrow = _eyebrow;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Dialog(
        insetPadding: const EdgeInsets.all(32),
        clipBehavior: Clip.antiAlias,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          // Assez large pour que montants, e-mails et mobiles tiennent sur
          // une ligne sans être tronqués.
          constraints: const BoxConstraints(maxWidth: 1400, maxHeight: 900),
          child: SizedBox.expand(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OrderSheetHeader(
                  eyebrow: eyebrow.isEmpty
                      ? null
                      : OrderSheetEyebrow(eyebrow, data: true),
                  title: 'Bénéficiaires',
                  trailing: [
                    TextButton.icon(
                      style: orderCompactButtonStyle(),
                      onPressed: _isLoading || _isSaving ? null : _load,
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Recharger'),
                    ),
                    if (_editable && (_data?.canAdd ?? false))
                      ElevatedButton.icon(
                        style: orderCompactButtonStyle(),
                        onPressed: _isSaving ? null : _addRow,
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Ajouter un bénéficiaire'),
                      ),
                  ],
                ),
                Expanded(child: _buildContent()),
                OrderSheetFooter(
                  leading: _editable && !_isLoading
                      ? Text(
                          '${_isDirty ? 'Non enregistré : ' : ''}'
                          '$_modifiedCount modification(s), $_addedCount '
                          'ajout(s), $_removedCount retrait(s) · le montant '
                          'doit être supérieur à 0.',
                          style: ArcText.small(
                                  color: _isDirty ? kWarningText : kText2)
                              .copyWith(fontSize: 13),
                        )
                      : null,
                  actions: [
                    OutlinedButton(
                        onPressed: _isSaving ? null : _close,
                        child: const Text('Fermer')),
                    if (_editable)
                      FilledButton(
                        onPressed: _isLoading || _isSaving ? null : _save,
                        child: _isSaving
                            ? const OrderButtonSpinner()
                            : const Text('Enregistrer'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: TribuneoLoader());
    }
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: kDangerText),
              const SizedBox(height: 8),
              SelectableText(_loadError!,
                  textAlign: TextAlign.center,
                  style: ArcText.body(color: kDangerText)),
            ],
          ),
        ),
      );
    }

    final OrderBeneficiariesModel data = _data!;
    final List<Widget> notices = [
      if (!data.isImported)
        OrderNotice(
            OrderErrorMessages.forCode('NOT_AN_IMPORTED_ORDER', const {})!),
      if (data.isImported && data.invoiced)
        const OrderNotice(
            'Commande facturée : seuls le nom, l\'e-mail et le mobile des '
            'bénéficiaires non attribués peuvent encore être modifiés.',
            warning: true),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final notice in notices)
          Padding(
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
              child: notice),
        if (notices.isNotEmpty) const SizedBox(height: 16),
        if (_rows.isEmpty)
          const Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: ArcEmptyState(
                  icon: Icons.group_outlined,
                  title: 'Aucun bénéficiaire pour cette commande.',
                ),
              ),
            ),
          )
        else
          Expanded(
            // Le tableau occupe toute la largeur disponible, sans descendre sous
            // sa largeur minimale lisible (défilement horizontal en dessous).
            child: LayoutBuilder(
              builder: (context, constraints) => Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: constraints.maxWidth > _tableMinWidth
                          ? constraints.maxWidth
                          : _tableMinWidth,
                      child: _buildTable(),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Proportions des colonnes ; leur somme est la largeur minimale du tableau.
  /// Reste : « 100 000,00 € » sur une ligne même à la largeur minimale.
  static const List<double> _columnFlex = [
    120, 120, 260, 150, 110, 130, 120, 190
  ];
  static final double _tableMinWidth =
      _columnFlex.fold<double>(0, (sum, width) => sum + width);
  static final Map<int, TableColumnWidth> _columnWidths = {
    for (int i = 0; i < _columnFlex.length; i++)
      i: FlexColumnWidth(_columnFlex[i]),
  };

  /// Marges des cellules : 28 px aux bords du tableau, 12 px entre colonnes.
  static EdgeInsets _cellPadding(int column, {double vertical = 8}) =>
      EdgeInsets.fromLTRB(column == 0 ? 28 : 12, vertical,
          column == _columnFlex.length - 1 ? 28 : 12, vertical);

  /// Colonnes de montants et d'actions, alignées à droite.
  static const Set<int> _rightAligned = {4, 5, 7};

  Widget _buildTable() {
    const List<String> labels = [
      'Prénom',
      'Nom',
      'E-mail',
      'Mobile',
      'Montant',
      'Reste',
      'Statut',
      'Actions',
    ];
    return Table(
      columnWidths: _columnWidths,
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      border: const TableBorder(
          horizontalInside: BorderSide(color: kNavy100)),
      children: [
        TableRow(
          decoration: const BoxDecoration(color: kSurface2),
          children: [
            for (int i = 0; i < labels.length; i++)
              Padding(
                padding: _cellPadding(i, vertical: 10),
                child: Text(labels[i],
                    textAlign:
                        _rightAligned.contains(i) ? TextAlign.right : null,
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: kText2)),
              ),
          ],
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
      background = kDangerBg;
    } else if (row.isNew) {
      background = const Color(0xFFFFFBF3);
    }

    // Montant manquant ou refusé : bord framboise.
    final bool amountInvalid = (row.isNew && row.amount.text.trim().isEmpty) ||
        (row.error != null && (row.parsedAmount ?? 0) <= 0);

    final Widget status = row.removed
        ? const ArcPill('Retiré', tone: ArcTone.danger)
        : row.isNew
            ? const ArcPill('Nouveau', tone: ArcTone.warning)
            : assigned
                ? const ArcPill('Attribué', tone: ArcTone.info)
                : const ArcPill('En attente', tone: ArcTone.neutral);

    final List<Widget> cells = [
      _field(row.firstname, canEditContact, row.removed, lockedTooltip),
      _field(row.lastname, canEditContact, row.removed, lockedTooltip),
      _field(row.email, canEditContact, row.removed, lockedTooltip,
          keyboardType: TextInputType.emailAddress),
      _field(row.mobile, canEditContact, row.removed, lockedTooltip,
          keyboardType: TextInputType.phone, data: true),
      _field(row.amount, canEditAmount, row.removed, lockedTooltip,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          formatter:
              FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d{0,2}')),
          data: true,
          alignRight: true,
          invalid: amountInvalid),
      _withTooltip(
        lockedTooltip,
        Text(row.isNew ? '—' : formatEuro(original!.remainingAmount),
            textAlign: TextAlign.right,
            maxLines: 1,
            softWrap: false,
            style: ArcText.data(color: kText2).copyWith(
                decoration: row.removed ? TextDecoration.lineThrough : null)),
      ),
      Align(
          alignment: Alignment.centerLeft,
          child: _withTooltip(lockedTooltip, status)),
      _actions(row),
    ];

    return TableRow(
      decoration: BoxDecoration(color: background),
      children: [
        for (int i = 0; i < cells.length; i++)
          Padding(
            padding: _cellPadding(i),
            // Ligne retirée : estompée et barrée, ses actions restent nettes.
            child: row.removed && i < cells.length - 1
                ? Opacity(opacity: 0.6, child: cells[i])
                : cells[i],
          ),
      ],
    );
  }

  Widget _withTooltip(String? tooltip, Widget child) =>
      tooltip == null ? child : Tooltip(message: tooltip, child: child);

  Widget _field(TextEditingController controller, bool editable, bool removed,
      String? tooltip,
      {TextInputType? keyboardType,
      TextInputFormatter? formatter,
      bool data = false,
      bool alignRight = false,
      bool invalid = false}) {
    final TextStyle style =
        (data ? ArcText.data() : ArcText.body().copyWith(fontSize: 13))
            .copyWith(decoration: removed ? TextDecoration.lineThrough : null);
    if (!editable) {
      // Lecture seule : même gabarit qu'un champ, fond Navy 50 (blanc bordé
      // pour une ligne retirée).
      return _withTooltip(
        tooltip,
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
          decoration: BoxDecoration(
            color: removed ? kSurface : kNavy50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: removed ? kBorder : kNavy50, width: 1.5),
          ),
          child: Text(controller.text,
              maxLines: 1, overflow: TextOverflow.ellipsis, style: style),
        ),
      );
    }
    OutlineInputBorder border(Color color, [double width = 1.5]) =>
        OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: color, width: width));
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: formatter == null ? null : [formatter],
      onChanged: (_) => setState(() {}),
      textAlign: alignRight ? TextAlign.right : TextAlign.start,
      style: style,
      decoration: InputDecoration(
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        border: border(kBorder),
        enabledBorder: border(invalid ? kDanger : kBorder),
        focusedBorder: border(invalid ? kDanger : kNavy600, 2),
      ),
    );
  }

  ButtonStyle _rowButtonStyle(Color color) => TextButton.styleFrom(
        foregroundColor: color,
        minimumSize: const Size(0, 34),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        textStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
      );

  Widget _actions(_BeneficiaryRow row) {
    final OrderBeneficiaryModel? original = row.original;
    final bool resending =
        original?.idQrcode != null && _resendingQrcode == original!.idQrcode;

    return Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      runSpacing: 4,
      children: [
        if (row.error != null)
          Tooltip(
            message: row.error!,
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.error_outline_rounded,
                  color: kDangerText, size: 20),
            ),
          ),
        if (_editable && row.removed)
          TextButton(
            style: _rowButtonStyle(kNavy600),
            onPressed: _isSaving ? null : () => _restoreRow(row),
            child: const Text('Annuler le retrait'),
          )
        else if (_editable && row.canRemove)
          Semantics(
            label: 'Retirer ce bénéficiaire',
            excludeSemantics: true,
            button: true,
            child: TextButton(
              style: _rowButtonStyle(kDangerText),
              onPressed: _isSaving ? null : () => _removeRow(row),
              child: const Text('Retirer'),
            ),
          )
        else if (original?.assigned ?? false)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline_rounded, size: 14, color: kText3),
              const SizedBox(width: 4),
              Text('Attribué', style: ArcText.small(color: kText3)),
            ],
          ),
        if (!row.isNew && !row.removed && (original?.canResendMail ?? false))
          resending
              ? const Padding(
                  padding: EdgeInsets.all(8),
                  child: SizedBox(
                      height: 18,
                      width: 18,
                      child: TribuneoLoader()),
                )
              : ArcIconAction(
                  icon: Icons.forward_to_inbox_outlined,
                  tooltip: row.isModified
                      ? "Renvoyer l'e-mail (à l'adresse enregistrée)"
                      : "Renvoyer l'e-mail",
                  background: Colors.transparent,
                  size: 34,
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
