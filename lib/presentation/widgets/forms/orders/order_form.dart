import 'dart:convert';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:back_office_tribuneo_v2/config/size_config.dart';
import 'package:back_office_tribuneo_v2/domain/models/entity_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/order_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/urssaf_model.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/customer_usecase.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/orders_usecase.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/partner_usecase.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/_global.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/form_validator.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/forms/neo_input.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/forms/neo_row.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/neo_button.dart';

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
  bool isChecked = false;
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

    if (!showImportView && _selectedUrssafEvent == null) {
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
        result = await _orderUseCase.addOrder(order);
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
    super.dispose();
  }

  String date = "";
  DateTime selectedDate = DateTime.now();

  String expiryDate = "";
  DateTime selectedExpiryDate = DateTime.now().add(const Duration(days: 365));
  _selectExpiryDate(BuildContext context) async {
    final DateTime? selected = await showDatePicker(
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: kBlue,
            ),
            buttonTheme: const ButtonThemeData(
              textTheme: ButtonTextTheme.primary,
            ),
          ),
          child: child!,
        );
      },
      fieldHintText: "Jour/Mois/Année",
      locale: const Locale("fr", "FR"),
      context: context,
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

    return AlertDialog(
      backgroundColor: kTransparent,
      contentPadding: const EdgeInsets.all(0),
      content: Form(
        key: _formKey,
        child: Stack(children: [
          SizedBox(
            width: SizeConfig.screenWidth * 0.65,
            height: SizeConfig.screenHeight * 0.85,
            child: Container(
              width: SizeConfig.screenWidth * 0.85,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(20)),
                color: kPLGrey2,
              ),
              child: SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 980),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        _buildHeader(),
                        const SizedBox(height: 30),
                        _selectableDate(),
                        SizedBox(height: SizeConfig.screenHeight * 0.03),
                        _buildToggleButtons(),
                        SizedBox(height: SizeConfig.screenHeight * 0.02),
                        showImportView
                            ? _buildImportFileView()
                            : _buildAddOrderWiew(getColor),
                        const SizedBox(height: 40),
                        _groupWidgets(),
                        SizedBox(height: SizeConfig.screenHeight * 0.04),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _isLoading
                                ? const SizedBox(
                                    height: 40,
                                    width: 40,
                                    child: CircularProgressIndicator(
                                      color: kOrange,
                                    ),
                                  )
                                : NeoButton(
                                    text: "Enregistrer",
                                    onPressed: addOrder,
                                  ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildHeader() {
    return Center(
      child: SelectableText(
        "Ajouter une commande",
        style: GoogleFonts.poppins(
            fontSize: 32,
            letterSpacing: 0.3,
            fontWeight: FontWeight.w600,
            color: kOrange),
      ),
    );
  }

  Widget _selectableDate() {
    return Center(
      child: SizedBox(
        width: 500,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
              child: NeoInput(
                controller: expiryDateController,
                hintText: 'Date d\'expiration',
                fillColor: kPWhite,
                validator: (value) {
                  return FormValidator.validateOrderDate(value ?? '');
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: SizedBox(
                height: 52,
                child: NeoButton(
                  verticalPadding: 0,
                  horizontalPadding: 0,
                  fontSize: 14,
                  text: "Choisir une date",
                  backgroundColor: kBlue,
                  onPressed: () {
                    _selectExpiryDate(context);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        NeoButton(
          onPressed: () {
            setState(() {
              showImportView = false;
              _cleanFileStorage();
            });
          },
          backgroundColor: showImportView ? Colors.grey : kOrange,
          text: "Saisie manuelle",
        ),
        const SizedBox(width: 15),
        NeoButton(
          onPressed: () {
            setState(() {
              showImportView = true;
              _cleanRowStorage();
            });
          },
          backgroundColor: showImportView ? kOrange : Colors.grey,
          text: "Importer un fichier",
        ),
      ],
    );
  }

  Widget _buildAddOrderWiew(getColor) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Différents fonds ?",
                style: GoogleFonts.poppins(
                    fontSize: 16,
                    letterSpacing: 0.3,
                    fontWeight: FontWeight.w600,
                    color: kBlue),
              ),
              const SizedBox(width: 15),
              Checkbox(
                checkColor: Colors.white,
                fillColor: WidgetStateProperty.resolveWith(getColor),
                value: isChecked,
                onChanged: (bool? value) {
                  setState(() {
                    isChecked = value!;
                    if (neorow.length != 1) {
                      neorow.removeRange(1, neorow.length);
                    }
                  });
                },
              ),
            ],
          ),
        ),
        ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: neorow.length,
            itemBuilder: (_, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: neorow[index],
              );
            }),
        isChecked
            ? Column(
                children: [
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      RawMaterialButton(
                        onPressed: () {
                          setState(() {
                            neorow.add(NeoRow());
                          });
                        },
                        padding: const EdgeInsets.all(12.0),
                        shape: const CircleBorder(
                          side: BorderSide(color: kBlue, width: 1),
                        ),
                        elevation: 2.0,
                        fillColor: Colors.white,
                        child: const Icon(Icons.add, color: kBlue),
                      ),
                      if (neorow.length > 1) ...[
                        const SizedBox(width: 15),
                        RawMaterialButton(
                          onPressed: () {
                            setState(() {
                              neorow.removeLast();
                            });
                          },
                          padding: const EdgeInsets.all(12.0),
                          shape: const CircleBorder(
                            side: BorderSide(color: Colors.red, width: 1),
                          ),
                          elevation: 2.0,
                          fillColor: Colors.white,
                          child: const Icon(Icons.remove, color: Colors.red),
                        ),
                      ],
                    ],
                  ),
                ],
              )
            : const SizedBox.shrink(),
      ],
    );
  }

  Widget _buildImportFileView() {
    return Column(
      children: [
        SizedBox(height: SizeConfig.screenHeight * 0.02),
        Center(
            child: NeoButton(
                text: "Importer CSV/XLSX", onPressed: pickAndStoreFile)),
        SizedBox(height: SizeConfig.screenHeight * 0.02),
        Center(
          child: Text(
            selectedFile != null
                ? "Fichier sélectionné : ${selectedFile!.name}"
                : "Aucun fichier sélectionné",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: kGrey,
            ),
          ),
        ),
        SizedBox(height: SizeConfig.screenHeight * 0.02),
      ],
    );
  }

  Widget _groupWidgets() {
    return Center(
      child: SizedBox(
        width: 700,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: widget.idEntity == -1
                      ? DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade400),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton2<String>(
                              items: customers
                                  .map<DropdownItem<String>>((partner) {
                                return DropdownItem<String>(
                                  value: partner.name,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10, horizontal: 12),
                                    child: Text(
                                      partner.name!,
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                              hint: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  "Offert par",
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w300,
                                    color: kGrey,
                                  ),
                                ),
                              ),
                              isExpanded: true,
                              valueListenable: _selectedCustomerValue,
                              onChanged: (String? value) {
                                setState(() {
                                  dropdownValue = value;
                                  _selectedCustomerValue.value = value;
                                  entityId = customers
                                      .firstWhere((element) =>
                                          element.name == dropdownValue)
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
                                    decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                      hintText: 'Rechercher une entité...',
                                      hintStyle: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
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
                        )
                      : TextFormField(
                          controller: giftFromController,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 16,
                            ),
                            hintText: widget.entityName,
                            filled: true,
                            fillColor: Colors.white,
                            hintStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w300,
                              color: kGrey,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade400),
                            ),
                          ),
                          readOnly: true,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<UrssafModel>(
                    initialValue: _selectedUrssafEvent,
                    items: _urssafEvent
                        .map((event) => DropdownMenuItem<UrssafModel>(
                              value: event,
                              child: Text(event.name!),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedUrssafEvent = value;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: "Pour l'occasion de",
                      labelStyle: const TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade400)),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 14),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 15),
            ValueListenableBuilder<bool>(
              valueListenable: _showHint,
              builder: (context, showHint, child) {
                return showHint
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            "Ceci va remplacer \"Offert par\" sur le chèque",
                            style:
                                GoogleFonts.poppins(color: kBlue, fontSize: 13),
                          ),
                        ),
                      )
                    : const SizedBox.shrink();
              },
            ),
            Center(
              child: SizedBox(
                width: 342,
                child: NeoInput(
                  controller: alternativeByController,
                  hintText: 'Personnalisation offert par (optionnel)',
                  fillColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
