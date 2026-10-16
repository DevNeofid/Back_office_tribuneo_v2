import 'package:flutter/material.dart';
import 'package:back_office_tribuneo_v2/config/responsive.dart';
import 'package:back_office_tribuneo_v2/config/size_config.dart';
import 'package:back_office_tribuneo_v2/domain/errors/api_exception.dart';
import 'package:back_office_tribuneo_v2/domain/errors/order_error_messages.dart';
import 'package:back_office_tribuneo_v2/domain/models/order_beneficiaries_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/order_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/order_update_results_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/urssaf_model.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/orders_usecase.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/_global.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/formatters.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/forms/neo_input.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/forms/neo_row.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/neo_button.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/orders/beneficiaries_dialog.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/orders/order_expiry_date.dart';

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

  const UpdateOrderForm({Key? key, required this.orderItem, this.orderStatus})
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
  bool isChecked = false;
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

  /// Montants et quantités non modifiables : on renvoie les lignes telles quelles.
  bool get _linesLocked => _invoiced || _imported || _fromShop;

  @override
  initState() {
    super.initState();
    modifyItem = widget.orderItem;
    _invoiced = widget.orderStatus?.invoiced ?? false;
    _imported = widget.orderStatus?.isImported ?? false;
    _fromShop = widget.orderStatus?.isFromShop ?? false;

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
    isChecked = items.length > 1;
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
        final bool? confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Retrait de bons'),
            content: const SizedBox(
              width: 480,
              child: Text(
                  'Les bons retirés seront les derniers créés parmi ceux qui ne '
                  'sont pas encore attribués. Si leurs QR ont déjà été imprimés et '
                  'distribués, ils ne seront plus valables. Continuer ?'),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Annuler')),
              TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Continuer',
                      style:
                          TextStyle(color: kRed, fontWeight: FontWeight.bold))),
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

  Widget _notice(String text, {Widget? action}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: kOrange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: kOrange),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: GoogleFonts.poppins(fontSize: 14, color: kBlueEnd)),
          ),
          if (action != null) ...[const SizedBox(width: 12), action],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color getColor(Set<WidgetState> states) {
      const Set<WidgetState> interactiveStates = <WidgetState>{
        WidgetState.pressed,
        WidgetState.hovered,
        WidgetState.focused,
      };
      if (states.any(interactiveStates.contains)) {
        return kOrange;
      }
      return kBlue;
    }

    SizeConfig().init(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _hasChanged);
      },
      child: AlertDialog(
        backgroundColor: kTransparent,
        contentPadding: const EdgeInsets.all(0),
        content: Form(
          key: _formKey,
          child: SizedBox(
            width: SizeConfig.screenWidth * 0.7,
            height: SizeConfig.screenHeight * 0.8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(20)),
                color: kPLGrey2,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Center(
                      child: SelectableText(
                        "Modifier la commande ${modifyItem.orderNumber ?? ''}",
                        style: GoogleFonts.poppins(
                            fontSize: 32,
                            letterSpacing: 0.3,
                            fontWeight: FontWeight.w600,
                            color: kOrange),
                      ),
                    ),
                    const SizedBox(height: 40),
                    if (_invoiced)
                      _notice(
                          OrderErrorMessages.forCode('ORDER_INVOICED', const {})!),
                    if (!_invoiced && _imported)
                      _notice(
                        'Commande importée par fichier : les montants et les '
                        'quantités se modifient depuis l\'écran Bénéficiaires.',
                        action: NeoButton(
                          width: 160,
                          height: 40,
                          fontSize: 13,
                          verticalPadding: 0,
                          horizontalPadding: 0,
                          backgroundColor: kBlue,
                          text: 'Bénéficiaires',
                          onPressed: _openBeneficiaries,
                        ),
                      ),
                    if (!_invoiced && _fromShop)
                      _notice(OrderErrorMessages.forCode(
                          'SHOP_ORDER_LINES', const {})!),
                    SizedBox(
                      height: 60,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 2,
                            child: GestureDetector(
                              onTap: _invoiced
                                  ? null
                                  : () => _selectExpiryDate(context),
                              child: AbsorbPointer(
                                child: NeoInput(
                                  controller: expiryDateController,
                                  hintText: 'Date d\'expiration',
                                  fillColor: kPWhite,
                                  readOnly: true,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            flex: 2,
                            child: NeoButton(
                              width: 100,
                              height: 40,
                              verticalPadding: 0,
                              horizontalPadding: 0,
                              fontSize: 12,
                              text: _invoiced
                                  ? 'Changer la date de validité'
                                  : 'Choisir une date',
                              backgroundColor: kBlue,
                              onPressed: () {
                                _invoiced
                                    ? _changeExpiryDateOfInvoicedOrder()
                                    : _selectExpiryDate(context);
                              },
                            ),
                          ),
                          !Responsive.isMobile(context)
                              ? Expanded(
                                  flex: Responsive.isDesktop(context) ? 4 : 2,
                                  child: const SizedBox(height: 10),
                                )
                              : const SizedBox(height: 10),
                        ],
                      ),
                    ),
                    SizedBox(height: SizeConfig.screenHeight * 0.01),
                    if (!_linesLocked)
                      SizedBox(
                        height: 60,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 1,
                              child: Text(
                                "Différents fonds ?",
                                style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    letterSpacing: 0.3,
                                    fontWeight: FontWeight.w600,
                                    color: kBlue),
                              ),
                            ),
                            Expanded(
                                flex: 0,
                                child: Checkbox(
                                  checkColor: Colors.white,
                                  fillColor:
                                      WidgetStateProperty.resolveWith(getColor),
                                  value: isChecked,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      isChecked = value!;
                                      if (neorow.length != 1) {
                                        neorow.removeRange(1, neorow.length);
                                      }
                                    });
                                  },
                                )),
                            !Responsive.isMobile(context)
                                ? Expanded(
                                    flex: Responsive.isDesktop(context) ? 3 : 1,
                                    child: const SizedBox(height: 10),
                                  )
                                : const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    SizedBox(height: SizeConfig.screenHeight * 0.01),
                    ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: neorow.length,
                        itemBuilder: (_, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: neorow[index],
                          );
                        }),
                    if (isChecked && !_linesLocked)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            child: RawMaterialButton(
                              onPressed: () {
                                setState(() {
                                  neorow.add(NeoRow(key: UniqueKey()));
                                });
                              },
                              padding: const EdgeInsets.all(15.0),
                              shape: const CircleBorder(
                                side: BorderSide(
                                  color: kBlue,
                                  width: 1,
                                ),
                              ),
                              elevation: 2.0,
                              child: const Icon(
                                Icons.add,
                                color: kBlue,
                              ),
                            ),
                          ),
                          if (neorow.length > 1)
                            SizedBox(
                                child: RawMaterialButton(
                              onPressed: () {
                                setState(() {
                                  neorow.removeLast();
                                });
                              },
                              padding: const EdgeInsets.all(15.0),
                              shape: const CircleBorder(
                                side: BorderSide(
                                  color: kBlue,
                                  width: 1,
                                ),
                              ),
                              elevation: 2.0,
                              child: const Icon(
                                Icons.remove,
                                color: kBlue,
                              ),
                            )),
                        ],
                      ),
                    SizedBox(height: SizeConfig.screenHeight * 0.01),
                    SizedBox(
                      height: 60,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: giftFromController,
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 18,
                                ),
                                labelText: 'Offert par',
                                filled: true,
                                hintStyle: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w300,
                                  color: kGrey,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              readOnly: true,
                            ),
                          ),
                          !Responsive.isMobile(context)
                              ? Expanded(
                                  flex: Responsive.isDesktop(context) ? 3 : 1,
                                  child: const SizedBox(height: 10),
                                )
                              : const SizedBox(height: 10),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<UrssafModel>(
                              // Recréé une fois la liste chargée : la valeur
                              // initiale n'est lue qu'à la création du champ.
                              key: ValueKey(
                                  'urssaf-${_urssafEvent.length}-${_selectedUrssafEvent?.id}'),
                              items: _urssafEvent
                                  .map((event) => DropdownMenuItem<UrssafModel>(
                                        value: event,
                                        child: Text(event.name ?? ''),
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
                              decoration: InputDecoration(
                                labelText: "Pour l'occasion de",
                                labelStyle:
                                    const TextStyle(color: Colors.grey),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 16),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    SizedBox(height: SizeConfig.screenHeight * 0.04),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: _isSaving
                              ? null
                              : () => Navigator.pop(context, _hasChanged),
                          child: const Text('Fermer'),
                        ),
                        const SizedBox(width: 20),
                        if (!_invoiced)
                          _isSaving
                              ? const SizedBox(
                                  height: 40,
                                  width: 40,
                                  child: CircularProgressIndicator(
                                    color: kOrange,
                                  ),
                                )
                              : NeoButton(
                                  text: "Enregistrer",
                                  onPressed: sendModifiedOrder),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
