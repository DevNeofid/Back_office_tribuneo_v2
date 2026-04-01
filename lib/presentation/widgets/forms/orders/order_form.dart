import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:excel/excel.dart' as ex;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tribuneo_backoffice/config/responsive.dart';
import 'package:tribuneo_backoffice/config/size_config.dart';
import 'package:tribuneo_backoffice/domain/models/entity_model.dart';
import 'package:tribuneo_backoffice/domain/models/order_model.dart';
import 'package:tribuneo_backoffice/domain/models/urssaf_model.dart';
import 'package:tribuneo_backoffice/domain/usecases/customer_usecase.dart';
import 'package:tribuneo_backoffice/domain/usecases/orders_usecase.dart';
import 'package:tribuneo_backoffice/domain/usecases/partner_usecase.dart';
import 'package:tribuneo_backoffice/env/env.dart';
import 'package:tribuneo_backoffice/presentation/utils/_global.dart';
import 'package:tribuneo_backoffice/presentation/utils/form_validator.dart';
import 'package:tribuneo_backoffice/presentation/utils/common.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tribuneo_backoffice/presentation/widgets/forms/neo_input.dart';
import 'package:tribuneo_backoffice/presentation/widgets/forms/neo_row.dart';
import 'package:tribuneo_backoffice/presentation/widgets/neo_button.dart';

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
  InputDatePickerFormField orderDateControllerDP = InputDatePickerFormField(
      initialDate: DateTime.now(),
      // Date now - one year
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
  OrderRecModel modifyItem = OrderRecModel();
  late ValueNotifier<bool> _showHint;
  String alternativeBy = '';
  bool showImportView = false;

  List<List<dynamic>>? csvData;
  List<List<dynamic>>? xlsxData;
  String? fileName;
  String fileBase64 = '';

  PlatformFile? selectedFile;

  @override
  initState() {
    super.initState();

    _showHint = ValueNotifier(false);
    // get entityId from parent
    neorow.add(NeoRow());
    selectedDate = DateTime.now();
    orderDateController.text =
        "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}";
    expiryDateController.text =
        "${selectedDate.day}/${selectedDate.month}/${selectedDate.year + 1}";
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
          if (Env.kNetworkName == "VDPC")
            {_selectedUrssafEvent = _urssafEvent.first}
        });

    if (alternativeByController.text != '') {
      _showHint.value = true;
    }

    alternativeByController.addListener(() {
      _showHint.value = alternativeByController.text.isNotEmpty;
    });
  }

  /* For debug */
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
    int fundQuantity = 0;
    selectedFile = showImportView ? selectedFile : null;

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
    }

    if (widget.idEntity != -1) {
      entityId = widget.idEntity;
      setState(() {
        giftFromController.text = widget.entityName;
      });
    }

    int giftId = _selectedUrssafEvent!.id!;
    String giftReason = _selectedUrssafEvent!.name!;

    // Gestion du CSV/XLSX
    if (showImportView) {
      if (selectedFile == null) {
        snackbarKey.currentState?.showSnackBar(const SnackBar(
          content: Text('Veuillez importer un fichier'),
          backgroundColor: Colors.red,
        ));
        return;
      }

      // Valider le fichier CSV ou XLSX
      if (selectedFile!.extension == 'csv' && csvData == null) {
        snackbarKey.currentState?.showSnackBar(const SnackBar(
          content: Text('Veuillez importer un fichier CSV valide'),
          backgroundColor: Colors.red,
        ));
        return;
      } else if (selectedFile!.extension == 'xlsx' && xlsxData == null) {
        snackbarKey.currentState?.showSnackBar(const SnackBar(
          content: Text('Veuillez importer un fichier XLSX valide'),
          backgroundColor: Colors.red,
        ));
        return;
      }
    } else {
      // Gestion des rows
      for (var i = 0; i < neorow.length; i++) {
        int tmpQuantity = int.parse(neorow[i].fundNumberController.text);
        fundQuantity += tmpQuantity;
        String persoMsg = neorow[i].persoMsgController.text;
        funds.add({
          "amount": int.parse(neorow[i].fundValueController.text),
          "quantity": tmpQuantity,
          "perso_msg": persoMsg.isEmpty ? giftReason : persoMsg,
        });
      }
    }

    // Gérer la personnalisation "Offert par"
    String persoGiftFrom = alternativeByController.text;
    giftFrom = dropdownValue!;
    if (persoGiftFrom.isNotEmpty) {
      // replace '/' and '\' in string by '-'
      persoGiftFrom = persoGiftFrom.replaceAll(RegExp(r'[\\/]'), '-');
      giftFrom = persoGiftFrom;
    }

    // Formater la date
    var inputFormat = DateFormat('dd/MM/yyyy');
    var inputDate = inputFormat.parse(expiryDateController.text);
    String dateFormated = DateFormat('yyyy-MM-dd').format(inputDate);

    if (showImportView) fileBase64 = base64Encode(selectedFile!.bytes!);

    // Création du modèle
    OrderSendModel o = OrderSendModel(
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

    try {
      if (showImportView) {
        await _orderUseCase.addOrder(o, fileName: fileName, file: fileBase64);
      } else {
        await _orderUseCase.addOrder(o);
        ;
      }
      navigatorKey.currentState?.pop();
      snackbarKey.currentState?.showSnackBar(const SnackBar(
        content: Text('Ajout de la commande réussi'),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      snackbarKey.currentState?.showSnackBar(const SnackBar(
        content: Text('Erreur lors de l’ajout de la commande'),
        backgroundColor: Colors.red,
      ));
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
    );

    if (result != null) {
      selectedFile = result.files.first;
      fileName = selectedFile?.name;

      if (selectedFile!.name.endsWith('.csv')) {
        final csvContent = utf8.decode(selectedFile!.bytes!);
        setState(() {
          csvData = const CsvDecoder().convert(csvContent);
        });
        print("Données CSV stockées : $csvData");
      } else if (selectedFile!.name.endsWith('.xlsx')) {
        var excel = ex.Excel.decodeBytes(selectedFile!.bytes!);
        setState(() {
          xlsxData = excel.tables[excel.tables.keys.first]?.rows;
        });
        print("Données XLSX stockées : $xlsxData");
      }

      print("Fichier sélectionné : $fileName");
    }
  }

  void _cleanRowStorage() {
    setState(() {
      neorow = [NeoRow()]; // Réinitialise les rows
    });
    print("Les rows ont été nettoyées.");
  }

  void _cleanFileStorage() {
    setState(() {
      selectedFile = null;
      fileName = null;
      csvData = null;
      xlsxData = null;
    });
    print("Stockage du fichier nettoyé.");
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
    // return DateFormat.yMd('fr').format(date);
    String day = date.day > 9 ? date.day.toString() : "0${date.day.toString()}";
    String month =
        date.month > 9 ? date.month.toString() : "0${date.month.toString()}";
    return "$day/$month/${date.year}";
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
            width: SizeConfig.screenWidth * 0.7,
            height: SizeConfig.screenHeight * 0.85,
            child: Container(
              width: SizeConfig.screenWidth * 0.85,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(20)),
                color: kPLGrey2,
              ),
              child: SingleChildScrollView(
                child: Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      _buildHeader(),
                      const SizedBox(height: 20),
                      _selectableDate(),
                      SizedBox(height: SizeConfig.screenHeight * 0.04),
                      _buildToggleButtons(),
                      SizedBox(height: SizeConfig.screenHeight * 0.01),
                      showImportView
                          ? _buildImportFileView()
                          : _buildAddOrderWiew(getColor),
                      SizedBox(height: SizeConfig.screenHeight * 0.01),
                      _groupWidgets(),
                      SizedBox(height: SizeConfig.screenHeight * 0.01),
                      SizedBox(height: SizeConfig.screenHeight * 0.01),
                      SizedBox(height: SizeConfig.screenHeight * 0.04),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          NeoButton(text: "Enregistrer", onPressed: addOrder),
                        ],
                      ),
                    ],
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
    return SizedBox(
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: NeoInput(
              controller: expiryDateController,
              hintText: 'Date d\'expiration',
              fillColor: kPWhite,
              validator: (value) {
                return FormValidator.validateOrderDate(value ?? '');
              },
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
              fontSize: 14,
              text: "Choisir une date",
              backgroundColor: kBlue,
              onPressed: () {
                _selectExpiryDate(context);
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
        const SizedBox(width: 10),
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
        ListView.builder(
            shrinkWrap: true,
            itemCount: neorow.length,
            itemBuilder: (_, index) {
              return neorow[index];
            }),
        isChecked
            ? Column(
                children: [
                  SizedBox(height: SizeConfig.screenHeight * 0.01),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        child: RawMaterialButton(
                          onPressed: () {
                            setState(() {
                              neorow.add(NeoRow());
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
                      neorow.length > 1
                          ? SizedBox(
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
                            ))
                          : const SizedBox(width: 0, height: 0),
                    ],
                  ),
                ],
              )
            : const SizedBox(height: 0),
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
              fontSize: 20,
              fontWeight: FontWeight.w300,
              color: kGrey,
            ),
          ),
        ),
        SizedBox(height: SizeConfig.screenHeight * 0.02),
      ],
    );
  }

  Widget _groupWidgets() {
    return Column(
      children: [
        SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              widget.idEntity == -1
                  ? Expanded(
                      flex: 2,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: kGrey),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton2<String>(
                            items:
                                customers.map<DropdownItem<String>>((partner) {
                              return DropdownItem<String>(
                                value: partner.name,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    left: 12,
                                    right: 0,
                                    top: 10,
                                    bottom: 10,
                                  ),
                                  child: Text(
                                    partner.name!,
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w300,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                            hint: SelectableText(
                              "Offert par",
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w300,
                                color: kGrey,
                              ),
                            ),
                            isExpanded: true,
                            valueListenable: _selectedCustomerValue,
                            onChanged: (String? value) {
                              // This is called when the user selects an item.
                              setState(() {
                                dropdownValue = value;
                                _selectedCustomerValue.value = value;
                                entityId = customers
                                    .firstWhere((element) =>
                                        element.name == dropdownValue)
                                    .id;
                              });
                            },
                            onMenuStateChange: (isOpen) {
                              if (!isOpen) {
                                giftFromController.clear();
                              }
                            },
                          ),
                        ),
                      ),
                    )
                  : Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: giftFromController,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 18,
                          ),
                          hintText: widget.entityName,
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
                  items: _urssafEvent
                      .map((event) => DropdownMenuItem<UrssafModel>(
                            value: event,
                            child: Text(event.name!),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedUrssafEvent = value!;
                    });
                  },
                  initialValue: _selectedUrssafEvent,
                  decoration: InputDecoration(
                    labelText: "Pour l'occasion de",
                    labelStyle: const TextStyle(color: Colors.grey),
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
        SizedBox(height: SizeConfig.screenHeight * 0.01),
        SizedBox(
          height: 70,
          child: Column(
            children: [
              Row(
                children: [
                  ValueListenableBuilder<bool>(
                    valueListenable: _showHint,
                    builder: (context, showHint, child) {
                      return showHint
                          ? const Text(
                              "Ceci va remplacer \"Offert par\" sur le chèque",
                              style: TextStyle(color: Colors.red),
                            )
                          : const SizedBox.shrink();
                    },
                  ),
                  const Expanded(child: SizedBox())
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 2,
                    child: NeoInput(
                      controller: alternativeByController,
                      hintText: 'Personnalisation offert par',
                      fillColor: kPWhite,
                      validator: (value) {
                        return FormValidator.validateText(value ?? '');
                      },
                    ),
                  ),
                  !Responsive.isMobile(context)
                      ? Expanded(
                          flex: Responsive.isDesktop(context) ? 3 : 1,
                          child: const SizedBox(height: 10),
                        )
                      : const SizedBox(height: 10),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
