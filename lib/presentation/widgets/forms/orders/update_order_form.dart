import 'package:flutter/material.dart';
import 'package:back_office_tribuneo_v2/domain/errors/api_exception.dart';
import 'package:back_office_tribuneo_v2/domain/errors/order_error_messages.dart';
import 'package:back_office_tribuneo_v2/domain/models/order_beneficiaries_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/order_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/order_restriction_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/order_update_results_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/urssaf_model.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/orders_usecase.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/_global.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/formatters.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/arc/arc.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/forms/neo_row.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/orders/beneficiaries_dialog.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/orders/order_expiry_date.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/orders/order_restriction_section.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/orders/order_sheet.dart';

/// Modification d'une commande (`PUT /order/{id}`).
///
/// Les bons ne sont plus recréés : l'API applique l'écart de quantité par montant.
/// Selon [orderStatus] (lu via `GET /order/{id}/beneficiaries`) :
/// - commande facturée : lecture seule, seule la date de validité reste modifiable ;
/// - commande importée : lignes non modifiables, bouton « Bénéficiaires » ;
/// - commande de la boutique : lignes non modifiables.
///
/// Retourne `true` si la commande a été modifiée.
class UpdateOrderForm extends StatefulWidget {
  final OrderModel orderItem;

  /// `null` si le statut n'a pas pu être lu : le formulaire est alors modifiable et
  /// l'API tranche (ses refus sont affichés).
  final OrderBeneficiariesModel? orderStatus;

  /// Ouvert depuis « Commerçants acceptés » : la section de la liste est
  /// amenée à l'écran.
  final bool focusRestriction;

  const UpdateOrderForm(
      {Key? key,
      required this.orderItem,
      this.orderStatus,
      this.focusRestriction = false})
      : super(key: key);

  @override
  State<UpdateOrderForm> createState() => _UpdateOrderFormState();
}

class _UpdateOrderFormState extends State<UpdateOrderForm> {
  final TextEditingController expiryDateController = TextEditingController();
  final TextEditingController giftFromController = TextEditingController();

  List<NeoRow> neorow = List.empty(growable: true);
  List<UrssafModel> _urssafEvent = [];
  final OrderUseCase _orderUseCase = OrderUseCase();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late OrderModel modifyItem;
  UrssafModel? _selectedUrssafEvent;

  /// Date enregistrée : `fund_expiry_date` n'est envoyée que si elle change.
  DateTime? _initialExpiryDate;
  DateTime? _selectedExpiryDate;
  bool _isSaving = false;
  bool _hasChanged = false;

  late bool _invoiced;
  late bool _imported;
  late bool _fromShop;

  /// Liste de commerçants de la commande (badge), `null` : valable partout.
  OrderRestrictionSummary? _restriction;
  final GlobalKey _restrictionKey = GlobalKey();

  /// Montants et quantités non modifiables : on renvoie les lignes telles quelles.
  bool get _linesLocked => _invoiced || _imported || _fromShop;

  @override
  initState() {
    super.initState();
    modifyItem = widget.orderItem;
    _invoiced = widget.orderStatus?.invoiced ?? false;
    _imported = widget.orderStatus?.isImported ?? false;
    _fromShop = widget.orderStatus?.isFromShop ?? false;
    _restriction = modifyItem.restriction;
    if (widget.focusRestriction) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final BuildContext? section = _restrictionKey.currentContext;
        if (section != null) {
          Scrollable.ensureVisible(section,
              duration: const Duration(milliseconds: 250));
        }
      });
    }

    _initialExpiryDate = DateTime.tryParse(modifyItem.fundExpiryDate?.date ?? '');
    _selectedExpiryDate = _initialExpiryDate;
    expiryDateController.text = _initialExpiryDate == null
        ? ''
        : _getDisplayableDate(_initialExpiryDate!);
    giftFromController.text = modifyItem.giftFrom ?? '';

    _buildRows();
    getUrssaf();
  }

  /// Clé unique par ligne : les contrôleurs de [NeoRow] sont créés avec le widget
  /// et lus à l'initialisation de son état, qui doit donc être recréé.
  void _buildRows() {
    neorow = [];
    final List<OrderItems> items = modifyItem.orderItems ?? [];
    for (final item in items) {
      neorow.add(NeoRow(
        key: UniqueKey(),
        initialValue: _formatAmount(item.amount),
        initialNumber: item.quantity?.toString() ?? '',
        initialPersoMsg: item.persoMsg ?? '',
        readOnly: _linesLocked,
      ));
    }
    if (neorow.isEmpty) {
      neorow.add(NeoRow(key: UniqueKey(), readOnly: _linesLocked));
    }
  }

  String _formatAmount(num? amount) {
    if (amount == null) return '';
    return amount == amount.roundToDouble()
        ? amount.toInt().toString()
        : amount.toString();
  }

  /// Quantités par montant, pour détecter une baisse (retrait de bons).
  Map<double, int> _quantitiesByAmount(Iterable<MapEntry<num, int>> lines) {
    final Map<double, int> result = {};
    for (final line in lines) {
      final double amount = line.key.toDouble();
      result[amount] = (result[amount] ?? 0) + line.value;
    }
    return result;
  }

  bool _hasQuantityDecrease(List<Map<String, dynamic>> newItems) {
    final Map<double, int> before = _quantitiesByAmount((modifyItem.orderItems ??
            [])
        .map((item) => MapEntry(item.amount ?? 0, item.quantity ?? 0)));
    final Map<double, int> after = _quantitiesByAmount(newItems.map((item) =>
        MapEntry(item['amount'] as num, item['quantity'] as int)));
    return before.entries.any((entry) => (after[entry.key] ?? 0) < entry.value);
  }

  /// Lignes enregistrées (montant, quantité).
  Iterable<MapEntry<num, int>> get _initialLines => (modifyItem.orderItems ??
          [])
      .map((item) => MapEntry(item.amount ?? 0, item.quantity ?? 0));

  /// Nombre de bons retirés par [lines] : baisse de quantité, montant par
  /// montant (affichage seulement ; l'API fait foi).
  int _removedVouchers(Iterable<MapEntry<num, int>> lines) {
    final Map<double, int> before = _quantitiesByAmount(_initialLines);
    final Map<double, int> after = _quantitiesByAmount(lines);
    int removed = 0;
    for (final entry in before.entries) {
      final int decrease = entry.value - (after[entry.key] ?? 0);
      if (decrease > 0) removed += decrease;
    }
    return removed;
  }

  Future<void> sendModifiedOrder() async {
    if (_invoiced || _isSaving) return;
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    final bool expiryChanged = _selectedExpiryDate != null &&
        _selectedExpiryDate != _initialExpiryDate;
    if (expiryChanged && _selectedExpiryDate!.isBefore(tomorrow())) {
      _showError(OrderErrorMessages.forCode('EXPIRY_DATE_TOO_EARLY', const {})!);
      return;
    }

    final String giftReason =
        _selectedUrssafEvent?.name ?? modifyItem.giftReason ?? '';

    List<Map<String, dynamic>> items;
    if (_linesLocked) {
      items = (modifyItem.orderItems ?? [])
          .map((item) => <String, dynamic>{
                "amount": item.amount,
                "quantity": item.quantity,
                "perso_msg": item.persoMsg,
              })
          .toList();
    } else {
      items = [];
      for (final row in neorow) {
        final String persoMsg = row.persoMsgController.text;
        items.add({
          "amount": num.parse(row.fundValueController.text),
          "quantity": int.parse(row.fundNumberController.text),
          "perso_msg": persoMsg.isEmpty ? giftReason : persoMsg,
        });
      }

      if (_hasQuantityDecrease(items)) {
        final int removed = _removedVouchers(items.map((item) =>
            MapEntry(item['amount'] as num, item['quantity'] as int)));
        final bool? confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => ArcDialog(
            icon: Icons.warning_amber_rounded,
            tone: ArcTone.warning,
            title: 'Retrait de $removed bon(s)',
            content: const Text(
                'Les bons retirés seront les derniers créés parmi ceux qui ne '
                'sont pas encore attribués. Si leurs QR ont déjà été imprimés et '
                'distribués, ils ne seront plus valables. Continuer ?'),
            actions: [
              OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Annuler')),
              FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Continuer')),
            ],
          ),
        );
        if (confirmed != true || !mounted) return;
      }
    }

    final Map<String, dynamic> body = {
      "gift_from": modifyItem.giftFrom,
      "id_entity": modifyItem.idEntity,
      "gift_reason": giftReason,
      "fund_quantity": items.fold<int>(
          0, (sum, item) => sum + ((item['quantity'] as int?) ?? 0)),
      "order_items": items,
      // Absent : événement inchangé.
      if (_selectedUrssafEvent?.id != null)
        "id_urssaf_event": _selectedUrssafEvent!.id,
      // Absente : date inchangée.
      if (expiryChanged)
        "fund_expiry_date": formatApiDate(_selectedExpiryDate!),
    };

    setState(() => _isSaving = true);
    try {
      final OrderUpdateResult result =
          await _orderUseCase.updateOrder(modifyItem.id!, body);
      if (!mounted) return;
      Navigator.pop(context, true);
      snackbarKey.currentState?.showSnackBar(SnackBar(
          content: Text('Commande modifiée : ${result.qrcodesCreated} bon(s) '
              'créé(s), ${result.qrcodesRemoved} bon(s) retiré(s).'),
          backgroundColor: kGreen,
          duration: const Duration(seconds: 6)));
    } on ApiException catch (e) {
      if (!mounted) return;
      _showError(e.message);
      setState(() {
        _isSaving = false;
        // L'API connaît mieux que l'écran l'état de la commande : on s'aligne.
        if (e.code == 'ORDER_INVOICED') _invoiced = true;
        if (e.code == 'IMPORTED_ORDER_LINES') _imported = true;
        if (e.code == 'SHOP_ORDER_LINES') _fromShop = true;
        if (_linesLocked) _buildRows();
      });
    }
  }

  void _showError(String message) {
    snackbarKey.currentState?.showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: kRed,
        duration: const Duration(seconds: 8)));
  }

  Future<void> _selectExpiryDate(BuildContext context) async {
    final DateTime? selected =
        await pickExpiryDate(context, current: _selectedExpiryDate);
    if (selected != null) {
      setState(() {
        _selectedExpiryDate = selected;
        expiryDateController.text = _getDisplayableDate(selected);
      });
    }
  }

  /// Commande facturée : la date se change pour toute la commande, hors formulaire.
  Future<void> _changeExpiryDateOfInvoicedOrder() async {
    final bool updated = await changeOrderExpiryDate(context, modifyItem,
        orderUseCase: _orderUseCase);
    if (updated && mounted) Navigator.pop(context, true);
  }

  Future<void> _openBeneficiaries() async {
    final bool? saved = await showDialog<bool>(
      useSafeArea: true,
      context: context,
      builder: (context) => BeneficiariesDialog(order: modifyItem),
    );
    if (saved == true) _hasChanged = true;
  }

  String _getDisplayableDate(DateTime date) {
    String day = date.day > 9 ? date.day.toString() : "0${date.day.toString()}";
    String month =
        date.month > 9 ? date.month.toString() : "0${date.month.toString()}";
    return "$day/$month/${date.year}";
  }

  Future<void> getUrssaf() async {
    final List<UrssafModel> events = await _orderUseCase.getUrssaf();
    if (!mounted) return;
    setState(() {
      _urssafEvent = events;
      // Seulement l'événement de la commande : sans lui, rien n'est présélectionné
      // et l'événement n'est pas envoyé.
      _selectedUrssafEvent ??= events
          .where((event) => event.id == modifyItem.idUrssaf)
          .firstOrNull;
    });
  }

  void _disposeRow(NeoRow row) {
    row.fundNumberController.dispose();
    row.fundValueController.dispose();
    row.persoMsgController.dispose();
  }

  @override
  void dispose() {
    for (final row in neorow) {
      _disposeRow(row);
    }
    expiryDateController.dispose();
    giftFromController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Affichage
  // ---------------------------------------------------------------------------

  void _close() => Navigator.pop(context, _hasChanged);

  /// « C202610161 · créée le 16/10/2026 », sans les parties absentes.
  String get _eyebrow {
    final String number = modifyItem.orderNumber?.trim() ?? '';
    final String created = formatFrenchDate(modifyItem.createdDate?.date);
    return [
      if (number.isNotEmpty) number,
      if (created.isNotEmpty) 'créée le $created',
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final String eyebrow = _eyebrow;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _hasChanged);
      },
      child: Form(
        key: _formKey,
        child: OrderSheet(
          semanticLabel: 'Modifier la commande',
          width: 620,
          header: OrderSheetHeader(
            eyebrow: eyebrow.isEmpty
                ? null
                : OrderSheetEyebrow(eyebrow, data: true),
            title: 'Modifier la commande',
            below: _restriction == null
                ? null
                : Align(
                    alignment: Alignment.centerLeft,
                    child: OrderRestrictionBadge(_restriction!),
                  ),
            trailing: [
              OrderSheetCloseButton(onPressed: _isSaving ? null : _close),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ..._notices(),
              _buildFields(),
              const SizedBox(height: 22),
              // Modifiable quel que soit l'état de la commande, facturée
              // comprise : enregistré à part (`PUT /order/{id}/restriction`).
              OrderRestrictionSection(
                key: _restrictionKey,
                order: modifyItem,
                orderStatus: widget.orderStatus,
                onChanged: (restriction) {
                  setState(() {
                    _restriction = restriction;
                    modifyItem.restriction = restriction;
                    _hasChanged = true;
                  });
                },
              ),
              const SizedBox(height: 22),
              _buildLines(),
            ],
          ),
          footer: OrderSheetFooter(
            actions: [
              OutlinedButton(
                onPressed: _isSaving ? null : _close,
                child: const Text('Fermer'),
              ),
              if (!_invoiced)
                FilledButton(
                  onPressed: _isSaving ? null : sendModifiedOrder,
                  child: _isSaving
                      ? const OrderButtonSpinner()
                      : const Text('Enregistrer'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _notices() {
    final List<Widget> notices = [
      if (_invoiced)
        OrderNotice(
          OrderErrorMessages.forCode('ORDER_INVOICED', const {})!,
          warning: true,
          action: FilledButton(
            style: orderCompactButtonStyle(),
            onPressed: _changeExpiryDateOfInvoicedOrder,
            child: const Text('Changer la date de validité'),
          ),
        ),
      if (!_invoiced && _imported)
        OrderNotice(
          'Commande importée par fichier : les montants et les '
          'quantités se modifient depuis l\'écran Bénéficiaires.',
          action: ElevatedButton(
            style: orderCompactButtonStyle(),
            onPressed: _openBeneficiaries,
            child: const Text('Bénéficiaires'),
          ),
        ),
      if (!_invoiced && _fromShop)
        OrderNotice(OrderErrorMessages.forCode('SHOP_ORDER_LINES', const {})!),
    ];
    return [
      for (final notice in notices) ...[notice, const SizedBox(height: 18)],
    ];
  }

  Widget _buildFields() {
    final List<Widget> fields = [
      OrderField(
        label: 'Offert par',
        child: TextFormField(
          controller: giftFromController,
          readOnly: true,
          style: ArcText.body(),
          decoration: orderReadOnlyDecoration(),
        ),
      ),
      OrderField(
        label: "Pour l'occasion de",
        child: DropdownButtonFormField<UrssafModel>(
          // Recréé une fois la liste chargée : la valeur
          // initiale n'est lue qu'à la création du champ.
          key: ValueKey(
              'urssaf-${_urssafEvent.length}-${_selectedUrssafEvent?.id}'),
          isExpanded: true,
          hint: const Text("Choisir l'occasion (URSSAF)",
              overflow: TextOverflow.ellipsis),
          items: _urssafEvent
              .map((event) => DropdownMenuItem<UrssafModel>(
                    value: event,
                    child:
                        Text(event.name ?? '', overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: _invoiced
              ? null
              : (value) {
                  setState(() {
                    _selectedUrssafEvent = value;
                  });
                },
          initialValue: _selectedUrssafEvent,
          decoration:
              _invoiced ? orderReadOnlyDecoration() : const InputDecoration(),
        ),
      ),
      OrderField(
        label: "Date d'expiration",
        child: TextFormField(
          controller: expiryDateController,
          readOnly: true,
          style: ArcText.data(),
          onTap: _invoiced ? null : () => _selectExpiryDate(context),
          decoration: _invoiced
              ? orderReadOnlyDecoration(
                  prefixIcon: const Icon(Icons.calendar_month_outlined,
                      size: 18))
              : const InputDecoration(
                  hintText: 'Jour/Mois/Année',
                  prefixIcon: Icon(Icons.calendar_month_outlined,
                      size: 18, color: kNavy600),
                ),
        ),
      ),
      OrderField(
        label: 'Paiement',
        child: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: OrderPaymentStatus.of(modifyItem).pill(detailed: true),
          ),
        ),
      ),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final bool twoColumns = constraints.maxWidth >= 420;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < fields.length; i += twoColumns ? 2 : 1) ...[
            if (i > 0) const SizedBox(height: 14),
            if (twoColumns)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: fields[i]),
                  const SizedBox(width: 16),
                  Expanded(
                      child: i + 1 < fields.length
                          ? fields[i + 1]
                          : const SizedBox.shrink()),
                ],
              )
            else
              fields[i],
          ],
        ],
      );
    });
  }

  Widget _buildLines() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Bons', style: ArcText.cardTitle()),
        const SizedBox(height: 10),
        for (int i = 0; i < neorow.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          OrderLineBox(
            trailing: !_linesLocked && neorow.length > 1
                ? IconButton(
                    tooltip: 'Retirer la ligne',
                    color: kDangerText,
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: () {
                      setState(() {
                        neorow.removeAt(i);
                      });
                    },
                  )
                : null,
            child: neorow[i],
          ),
        ],
        const SizedBox(height: 10),
        _quantityHint(),
        if (!_linesLocked) ...[
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: kNavy400, width: 1.5),
              ).merge(orderCompactButtonStyle()),
              onPressed: () {
                setState(() {
                  neorow.add(NeoRow(key: UniqueKey()));
                });
              },
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Ajouter un autre montant'),
            ),
          ),
        ],
      ],
    );
  }

  /// « Actuellement 5 bons : 2 seront retirés. », recalculé à la saisie.
  Widget _quantityHint() {
    if (_linesLocked) {
      return Text('Lignes non modifiables ici.',
          style: ArcText.small(color: kText2));
    }
    return ListenableBuilder(
      listenable: Listenable.merge([
        for (final row in neorow) ...[
          row.fundNumberController,
          row.fundValueController,
        ],
      ]),
      builder: (context, _) {
        final int current =
            _initialLines.fold<int>(0, (sum, line) => sum + line.value);
        final int removed = _removedVouchers(neorow.map((row) => MapEntry(
            num.tryParse(row.fundValueController.text) ?? 0,
            int.tryParse(row.fundNumberController.text) ?? 0)));
        return Text(
          removed > 0
              ? 'Actuellement ${plural(current, 'bon')} : $removed '
                  '${removed > 1 ? 'seront retirés' : 'sera retiré'}.'
              : 'Actuellement ${plural(current, 'bon')}.',
          style: ArcText.small(color: removed > 0 ? kWarningText : kText2),
        );
      },
    );
  }
}
