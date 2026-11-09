import 'dart:convert';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:back_office_tribuneo_v2/core/utils/idempotency_key.dart';
import 'package:back_office_tribuneo_v2/domain/errors/api_exception.dart';
import 'package:back_office_tribuneo_v2/domain/errors/order_error_messages.dart';
import 'package:back_office_tribuneo_v2/domain/models/entity_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/order_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/urssaf_model.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/customer_usecase.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/orders_usecase.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/partner_usecase.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/_global.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/form_validator.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/formatters.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/arc/arc.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/forms/neo_row.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/orders/merchant_picker.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/orders/order_sheet.dart';

class OrderForm extends StatefulWidget {
  final int idEntity;
  final String entityName;

  const OrderForm({Key? key, required this.idEntity, required this.entityName})
      : super(key: key);
  @override
  State<OrderForm> createState() => _OrderFormState();
}

class _OrderFormState extends State<OrderForm> {
  TextEditingController orderDateController = TextEditingController();
  TextEditingController expiryDateController = TextEditingController();
  TextEditingController giftFromController = TextEditingController();
  TextEditingController urssafController = TextEditingController();
  late TextEditingController alternativeByController = TextEditingController();
  TextEditingController searchController = TextEditingController();
  InputDatePickerFormField orderDateControllerDP = InputDatePickerFormField(
      initialDate: DateTime.now(),
      firstDate: DateTime(
          DateTime.now().year - 1, DateTime.now().month, DateTime.now().day),
      lastDate: DateTime(
          DateTime.now().year + 4, DateTime.now().month, DateTime.now().day));

  List<NeoRow> neorow = List.empty(growable: true);
  int fundNumber = 1;

  final OrderUseCase _orderUseCase = OrderUseCase();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool changePage = false;
  bool orderNumberLabelIsVisible = false;
  final PartnerUseCase partnerUseCase = PartnerUseCase();
  final CustomerUseCase _customerUseCase = CustomerUseCase();
  List<EntityModel> customers = [];
  List<UrssafModel> _urssafEvent = [];
  String? dropdownValue;
  late ValueNotifier<String?> _selectedCustomerValue;
  UrssafModel? _selectedUrssafEvent;
  int? entityId;
  String? giftFrom;
  OrderModel modifyItem = OrderModel();
  late ValueNotifier<bool> _showHint;
  String alternativeBy = '';
  bool showImportView = false;
  bool _isLoading = false;

  /// Clé d'idempotence de la dernière saisie manuelle non aboutie : renvoyée
  /// tant que la commande saisie est identique (coupure réseau, double clic).
  final PendingIdempotencyKey _orderKey = PendingIdempotencyKey();

  /// « Seulement chez certains commerçants » : la commande part avec une liste.
  bool _restricted = false;
  final RestrictionDraft _restrictionDraft = RestrictionDraft();
  final RestrictionPartners _restrictionPartners = RestrictionPartners();

  String? fileName;
  String fileBase64 = '';

  PlatformFile? selectedFile;

  @override
  initState() {
    super.initState();

    _showHint = ValueNotifier(false);
    neorow.add(NeoRow());
    selectedDate = DateTime.now();
    selectedExpiryDate =
        DateTime(selectedDate.year + 1, selectedDate.month, selectedDate.day);
    orderDateController.text = _getDisplayableDate(selectedDate);
    expiryDateController.text = _getDisplayableDate(selectedExpiryDate);
    giftFromController.addListener(
        (() => _printLatestValue('Gift From', giftFromController)));
    urssafController.addListener(
        (() => _printLatestValue('Urssaf Controller', urssafController)));
    if (widget.entityName.isNotEmpty) {
      dropdownValue = widget.entityName;
    }
    _selectedCustomerValue = ValueNotifier<String?>(dropdownValue);
    addData();
    getUrssaf().then((v) => {
          if (globalNetworkName == "VDPC")
            {_selectedUrssafEvent = _urssafEvent.first}
        });

    if (alternativeByController.text != '') {
      _showHint.value = true;
    }

    alternativeByController.addListener(() {
      _showHint.value = alternativeByController.text.isNotEmpty;
    });
  }

  void _printLatestValue(String cName, TextEditingController controller) {
    if (kDebugMode) {
      if (controller.text.isNotEmpty) {
        print('###DEBUG### Controller $cName text field: ${controller.text}');
      }
    }
    return;
  }

  Future<void> addOrder() async {
    List<Map<String, dynamic>> funds = [];
    double fundQuantity = 0;
    selectedFile = showImportView ? selectedFile : null;

    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    if (_selectedUrssafEvent == null) {
      snackbarKey.currentState?.showSnackBar(const SnackBar(
        content: Text('Veuillez sélectionner l\'occasion (URSSAF)'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    if (dropdownValue == null && widget.idEntity == -1) {
      snackbarKey.currentState?.showSnackBar(const SnackBar(
        content: Text('Veuillez sélectionner une entité ("Offert par")'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    if (_restricted) {
      final String? problem = _restrictionDraft.validate();
      if (problem != null) {
        snackbarKey.currentState?.showSnackBar(SnackBar(
          content: Text(problem),
          backgroundColor: Colors.red,
        ));
        return;
      }
    }

    if (widget.idEntity != -1) {
      entityId = widget.idEntity;
      setState(() {
        giftFromController.text = widget.entityName;
      });
    }

    int giftId = _selectedUrssafEvent!.id!;
    String giftReason = _selectedUrssafEvent!.name!;

    if (showImportView) {
      if (selectedFile == null) {
        snackbarKey.currentState?.showSnackBar(const SnackBar(
          content: Text('Veuillez importer un fichier'),
          backgroundColor: Colors.red,
        ));
        return;
      }

      if (selectedFile!.bytes == null || selectedFile!.bytes!.isEmpty) {
        snackbarKey.currentState?.showSnackBar(const SnackBar(
          content: Text('Veuillez importer un fichier valide'),
          backgroundColor: Colors.red,
        ));
        return;
      }
    } else {
      for (var i = 0; i < neorow.length; i++) {
        double tmpQuantity = double.parse(neorow[i].fundNumberController.text);
        fundQuantity += tmpQuantity;
        String persoMsg = neorow[i].persoMsgController.text;
        funds.add({
          "amount": double.parse(neorow[i].fundValueController.text),
          "quantity": tmpQuantity,
          "perso_msg": persoMsg.isEmpty ? giftReason : persoMsg,
        });
      }
    }

    String persoGiftFrom = alternativeByController.text;
    giftFrom = dropdownValue!;
    if (persoGiftFrom.isNotEmpty) {
      persoGiftFrom = persoGiftFrom.replaceAll(RegExp(r'[\\/]'), '-');
      giftFrom = persoGiftFrom;
    }

    var inputFormat = DateFormat('dd/MM/yyyy');
    var inputDate = inputFormat.parse(expiryDateController.text);
    String dateFormated = DateFormat('yyyy-MM-dd').format(inputDate);

    if (showImportView) fileBase64 = base64Encode(selectedFile!.bytes!);

    OrderSendModel order = OrderSendModel(
      giftFrom: giftFrom,
      idUrssaf: giftId,
      giftReason: giftReason,
      fundExpiryDate: dateFormated,
      fundQuantity: !showImportView ? fundQuantity : null,
      orderItems: !showImportView
          ? funds.map((item) => OrderSendItems.fromJson(item)).toList()
          : null,
      idEntity: entityId,
      restriction: _restricted ? _restrictionDraft.toInput() : null,
    );

    setState(() {
      _isLoading = true;
    });

    try {
      var result;
      if (showImportView) {
        result = await _orderUseCase.addOrder(order,
            fileName: fileName, file: fileBase64);
      } else {
        result = await _orderUseCase.addOrder(order,
            idempotencyKey: _orderKey.keyFor(jsonEncode(order)));
        _orderKey.clear();
      }

      if (!mounted) return;
      if (result == true) {
        Navigator.of(context).pop(true);
        snackbarKey.currentState?.showSnackBar(const SnackBar(
          content: Text("Ajout de la commande réussi"),
          backgroundColor: Colors.green,
        ));
      } else {
        throw Exception("Failed to add order");
      }
    } on ApiException catch (e) {
      _orderKey.onError(e.code);
      if (!mounted) return;
      snackbarKey.currentState?.showSnackBar(SnackBar(
        content: Text(e.message),
        backgroundColor: Colors.red,
      ));
      if (e.code == OrderErrorMessages.restrictionUnknownEntities) {
        // Commerçants sortis du réseau : décochés, et liste rechargée.
        _restrictionDraft
            .deselectAll(OrderErrorMessages.unknownEntityIds(e.details));
        _restrictionPartners.load(force: true);
      }
      if (e.code == 'IDEMPOTENCY_REQUEST_IN_PROGRESS') {
        // Le premier envoi est encore traité : on ne renvoie pas, on ferme le
        // formulaire après quelques secondes pour que la liste soit rechargée.
        await Future.delayed(const Duration(seconds: 3));
        if (!mounted) return;
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      snackbarKey.currentState?.showSnackBar(SnackBar(
        content: Text("Erreur lors de l’ajout de la commande"),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> addData() async {
    await _customerUseCase.getCustomers().then((value) {
      setState(() {
        customers = value[0] as List<EntityModel>;
      });
    });
  }

  Future<void> getUrssaf() async {
    await _orderUseCase.getUrssaf().then((value) {
      setState(() {
        _urssafEvent = value;
      });
    });
  }

  Future<void> pickAndStoreFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx'],
      withData: true,
    );

    if (result != null) {
      setState(() {
        selectedFile = result.files.first;
        fileName = selectedFile?.name;
      });
    }
  }

  void _cleanRowStorage() {
    setState(() {
      neorow = [NeoRow()];
    });
    print("Les rows ont été nettoyées.");
  }

  void _cleanFileStorage() {
    setState(() {
      selectedFile = null;
      fileName = null;
    });
  }

  @override
  void dispose() {
    _cleanRowStorage();
    _cleanFileStorage();
    for (var i = 0; i < neorow.length; i++) {
      neorow[i].fundNumberController.dispose();
      neorow[i].fundValueController.dispose();
      neorow[i].persoMsgController.dispose();
    }
    orderDateController.dispose();
    expiryDateController.dispose();
    giftFromController.dispose();
    urssafController.dispose();
    alternativeByController.dispose();
    _selectedCustomerValue.dispose();
    _showHint.dispose();
    searchController.dispose();
    _restrictionDraft.dispose();
    _restrictionPartners.dispose();
    super.dispose();
  }

  String date = "";
  DateTime selectedDate = DateTime.now();

  String expiryDate = "";
  DateTime selectedExpiryDate = DateTime.now().add(const Duration(days: 365));
  _selectExpiryDate(BuildContext context) async {
    final DateTime? selected = await showArcDatePicker(
      context,
      helpText: 'Date de validité',
      initialDate: selectedExpiryDate,
      firstDate: DateTime(2010),
      lastDate: DateTime(3000),
      initialEntryMode: DatePickerEntryMode.input,
    );
    if (selected != null && selected != selectedExpiryDate) {
      setState(() {
        selectedExpiryDate = selected;
        expiryDateController.text = _getDisplayableDate(selectedExpiryDate);
      });
    }
  }

  String _getDisplayableDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: OrderSheet(
        semanticLabel: 'Ajouter une commande',
        width: 660,
        header: OrderSheetHeader(
          eyebrow: const OrderSheetEyebrow('Nouvelle commande'),
          title: 'Ajouter une commande',
          trailing: [
            OrderSheetCloseButton(onPressed: () => Navigator.of(context).pop()),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildMainFields(),
            const SizedBox(height: 22),
            _buildRestrictionSection(),
            const SizedBox(height: 22),
            _buildVouchersSection(),
          ],
        ),
        footer: _buildFooter(),
      ),
    );
  }

  Widget _buildMainFields() {
    return LayoutBuilder(builder: (context, constraints) {
      final bool twoColumns = constraints.maxWidth >= 420;
      final Widget occasion =
          OrderField(label: "Pour l'occasion de", child: _occasionField());
      final Widget expiry =
          OrderField(label: "Date d'expiration", child: _expiryField());
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OrderField(label: 'Offert par', child: _giftFromField()),
          const SizedBox(height: 14),
          if (twoColumns)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: occasion),
                const SizedBox(width: 16),
                Expanded(child: expiry),
              ],
            )
          else ...[
            occasion,
            const SizedBox(height: 14),
            expiry,
          ],
          const SizedBox(height: 14),
          OrderField(
            label: 'Personnalisation « offert par »',
            optional: true,
            child: _alternativeByField(),
          ),
        ],
      );
    });
  }

  Widget _giftFromField() {
    if (widget.idEntity != -1) {
      return TextFormField(
        controller: giftFromController,
        readOnly: true,
        style: ArcText.body(),
        decoration: orderReadOnlyDecoration(hintText: widget.entityName),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(kRadiusSm),
        border: Border.all(color: kBorderStrong, width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton2<String>(
          items: customers.map<DropdownItem<String>>((partner) {
            return DropdownItem<String>(
              value: partner.name,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                child: Text(partner.name!, style: ArcText.body()),
              ),
            );
          }).toList(),
          hint: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, size: 18, color: kText3),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    'Rechercher une entité...',
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(fontSize: 14, color: kText3),
                  ),
                ),
              ],
            ),
          ),
          isExpanded: true,
          valueListenable: _selectedCustomerValue,
          onChanged: (String? value) {
            setState(() {
              dropdownValue = value;
              _selectedCustomerValue.value = value;
              entityId = customers
                  .firstWhere((element) => element.name == dropdownValue)
                  .id;
            });
          },
          dropdownSearchData: DropdownSearchData(
            searchController: searchController,
            searchBarWidgetHeight: 50,
            searchBarWidget: Container(
              height: 50,
              padding: const EdgeInsets.only(
                top: 8,
                bottom: 4,
                right: 8,
                left: 8,
              ),
              child: TextFormField(
                expands: true,
                maxLines: null,
                controller: searchController,
                style: ArcText.body().copyWith(fontSize: 13),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  hintText: 'Rechercher une entité...',
                ),
              ),
            ),
            searchMatchFn: (item, searchValue) {
              return item.value
                  .toString()
                  .toLowerCase()
                  .contains(searchValue.toLowerCase());
            },
          ),
          onMenuStateChange: (isOpen) {
            if (!isOpen) {
              giftFromController.clear();
              searchController.clear();
            }
          },
        ),
      ),
    );
  }

  Widget _occasionField() {
    return DropdownButtonFormField<UrssafModel>(
      initialValue: _selectedUrssafEvent,
      isExpanded: true,
      hint: const Text("Choisir l'occasion (URSSAF)",
          overflow: TextOverflow.ellipsis),
      items: _urssafEvent
          .map((event) => DropdownMenuItem<UrssafModel>(
                value: event,
                child: Text(event.name!, overflow: TextOverflow.ellipsis),
              ))
          .toList(),
      onChanged: (value) {
        setState(() {
          _selectedUrssafEvent = value;
        });
      },
      decoration: const InputDecoration(),
    );
  }

  Widget _expiryField() {
    return TextFormField(
      controller: expiryDateController,
      style: ArcText.data(),
      validator: (value) {
        return FormValidator.validateOrderDate(value ?? '');
      },
      decoration: InputDecoration(
        hintText: 'Jour/Mois/Année',
        prefixIcon: IconButton(
          tooltip: 'Choisir une date',
          icon: const Icon(Icons.calendar_month_outlined,
              size: 18, color: kNavy600),
          onPressed: () {
            _selectExpiryDate(context);
          },
        ),
      ),
    );
  }

  /// Exemple de personnalisation avec le client choisi, s'il est connu.
  String get _alternativeByHint {
    final String? name =
        widget.idEntity != -1 ? widget.entityName : dropdownValue;
    return name == null || name.trim().isEmpty
        ? "Ex. Le CSE de l'entreprise"
        : 'Ex. Le CSE de ${name.trim()}';
  }

  Widget _alternativeByField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(
          controller: alternativeByController,
          style: ArcText.body(),
          decoration: InputDecoration(hintText: _alternativeByHint),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: _showHint,
          builder: (context, showHint, child) {
            return showHint
                ? Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      "Ceci va remplacer \"Offert par\" sur le chèque",
                      style: ArcText.small(color: kNavy600),
                    ),
                  )
                : const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  /// Où les chèques sont acceptés : partout (par défaut) ou chez une liste de
  /// commerçants, en saisie manuelle comme en import par fichier.
  Widget _buildRestrictionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Où les chèques sont acceptés', style: ArcText.cardTitle()),
        const SizedBox(height: 4),
        RadioGroup<bool>(
          groupValue: _restricted,
          onChanged: (value) {
            setState(() => _restricted = value ?? false);
            if (_restricted) _restrictionPartners.load();
          },
          child: Column(
            children: [
              RadioListTile<bool>(
                value: false,
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text('Chez tous les commerçants du réseau',
                    style: ArcText.body()),
              ),
              RadioListTile<bool>(
                value: true,
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text('Seulement chez certains commerçants',
                    style: ArcText.body()),
              ),
            ],
          ),
        ),
        if (_restricted) ...[
          const SizedBox(height: 8),
          RestrictionEditor(
            draft: _restrictionDraft,
            partners: _restrictionPartners,
            enabled: !_isLoading,
          ),
        ],
      ],
    );
  }

  void _setImportView(bool importView) {
    if (importView == showImportView) return;
    setState(() {
      showImportView = importView;
      if (importView) {
        _cleanRowStorage();
      } else {
        _cleanFileStorage();
      }
    });
  }

  Widget _buildVouchersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            Text('Bons cadeaux', style: ArcText.cardTitle()),
            ArcSegmented<bool>(
              segments: const [
                ArcSegment(false, 'Saisie manuelle'),
                ArcSegment(true, 'Importer un fichier'),
              ],
              selected: showImportView,
              onChanged: _setImportView,
            ),
          ],
        ),
        const SizedBox(height: 12),
        showImportView ? _buildImportFileView() : _buildManualView(),
      ],
    );
  }

  Widget _buildManualView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < neorow.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          // La clé suit la ligne : son état reste le sien quand une ligne
          // précédente est retirée.
          KeyedSubtree(
            key: ObjectKey(neorow[i]),
            child: OrderLineBox(
              trailing: neorow.length > 1
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
          ),
        ],
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: kNavy400, width: 1.5),
            ).merge(orderCompactButtonStyle()),
            onPressed: () {
              setState(() {
                neorow.add(NeoRow());
              });
            },
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('Ajouter un autre montant'),
          ),
        ),
      ],
    );
  }

  Widget _buildImportFileView() {
    return CustomPaint(
      painter: const _DashedBorderPainter(),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: kOrange50,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.cloud_upload_outlined,
                  color: kOrange700),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: orderCompactButtonStyle(),
              onPressed: pickAndStoreFile,
              child: const Text('Importer CSV/XLSX'),
            ),
            const SizedBox(height: 10),
            Text(
              selectedFile != null
                  ? "Fichier sélectionné : ${selectedFile!.name}"
                  : "Aucun fichier sélectionné · une ligne par bénéficiaire, "
                      "montants libres",
              textAlign: TextAlign.center,
              style: ArcText.small(color: kText3).copyWith(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summary(String caption, String total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(caption, style: ArcText.small(color: kText3)),
        Text(total, style: ArcText.dialogTitle().copyWith(fontSize: 24)),
      ],
    );
  }

  Widget _buildFooter() {
    return OrderSheetFooter(
      leading: showImportView
          ? _summary('Total calculé depuis le fichier', '—')
          : ListenableBuilder(
              listenable: Listenable.merge([
                for (final row in neorow) ...[
                  row.fundNumberController,
                  row.fundValueController,
                ],
              ]),
              builder: (context, _) {
                int quantity = 0;
                double total = 0;
                for (final row in neorow) {
                  final int rowQuantity =
                      int.tryParse(row.fundNumberController.text) ?? 0;
                  quantity += rowQuantity;
                  total += (double.tryParse(row.fundValueController.text) ??
                          0) *
                      rowQuantity;
                }
                return _summary('$quantity bon(s) · total de la commande',
                    formatEuro(total));
              },
            ),
      actions: [
        OutlinedButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : addOrder,
          child: _isLoading
              ? const OrderButtonSpinner()
              : const Text('Enregistrer'),
        ),
      ],
    );
  }
}

/// Bordure en pointillés de la zone d'import (2 px, Navy 300).
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = kNavy300
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final Path path = Path()
      ..addRRect(RRect.fromRectAndRadius(
              Offset.zero & size, const Radius.circular(kRadiusMd))
          .deflate(1));
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 6), paint);
        distance += 11;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
