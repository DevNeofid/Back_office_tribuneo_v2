import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:back_office_tribuneo_v2/config/size_config.dart';
import 'package:back_office_tribuneo_v2/domain/models/entity_model.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/customer_usecase.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/forms/addresses/address_form.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/forms/addresses/update_address_form.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/forms/bank_informations/bank_information_form.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/forms/bank_informations/update_bank_form.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/forms/customers/customer_form.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/forms/customers/update_customers_form.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/forms/orders/order_form.dart';

enum SampleItem { itemOne, itemTwo }

enum FirstBoxItem { itemOne, itemTwo, itemThree }

class CustomersContentView extends StatefulWidget {
  CustomersContentView({super.key});

  @override
  State<CustomersContentView> createState() => CustomersContentViewState();
}

class CustomersContentViewState extends State<CustomersContentView>
    with SingleTickerProviderStateMixin {
  late final TabController tabController;
  final CustomerUseCase _customerUseCase = CustomerUseCase();
  final DateFormat dateFormat = DateFormat('dd/MM/yyyy');
  TextEditingController searchController = TextEditingController();
  bool _isLoading = false;
  List<EntityModel> _customers = [];
  late List<EntityModel> allCustomers;
  Map<String, List<EntityModel>> sortedEntities = {};
  List<String> availableFilters = [];
  int neoInitialIndex = 0;
  late int neoCurrentIndex;

  String _filter = 'A';
  String _lastFilter = 'A';
  String _lastSearch = '';
  SampleItem? selectedMenu;
  FirstBoxItem? firstBoxSelectedMenu;

  bool _button1Selected = false;
  bool _button2Selected = false;
  bool _button3Selected = false;

  Color _buttonColor1 = kBlue;
  Color _buttonColor2 = kBlue;
  Color _buttonColor3 = kBlue;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 3, vsync: this);
    neoCurrentIndex = neoInitialIndex;
    _refreshCustomers();
  }

  @override
  void dispose() {
    searchController.dispose();
    tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshCustomers() async {
    setState(() {
      _isLoading = true;
    });
    await _customerUseCase.getCustomers().then((value) {
      if (!mounted) return;

      Map<String, List<EntityModel>> sEntities =
          value[1] as Map<String, List<EntityModel>>;
      availableFilters = sEntities.keys.toList();
      sortedEntities = sEntities;
      allCustomers = value[0];

      setState(() {
        if (_lastSearch.isNotEmpty) {
          search(_lastSearch);
        } else {
          _filter = availableFilters.contains(_lastFilter)
              ? _lastFilter
              : availableFilters[0];
          _customers = sortedEntities[_filter] ?? [];
        }
        _isLoading = false;
      });
    }).catchError((error) {
      setState(() {
        _isLoading = false;
      });
    });
  }

  Future<void> _addCustomer() async {
    final bool? shouldRefresh = await showDialog<bool>(
        useSafeArea: true,
        context: context,
        builder: (context) {
          return const CustomerForm();
        });
    if (shouldRefresh == true) {
      _refreshCustomers();
    }
  }

  Future<void> _addOrder(int entityId, String entityName) async {
    final bool? shouldRefresh = await showDialog<bool>(
        useSafeArea: true,
        context: context,
        builder: (context) {
          return OrderForm(idEntity: entityId, entityName: entityName);
        });
    if (shouldRefresh == true) {
      _refreshCustomers();
    }
  }

  Future<void> _addAddress(int id) async {
    final bool? shouldRefresh = await showDialog<bool>(
        useSafeArea: true,
        context: context,
        builder: (context) {
          return AddressForm(idPartner: id);
        });
    if (shouldRefresh == true) {
      _refreshCustomers();
    }
  }

  Future<void> _addBankInformations(EntityModel customer) async {
    final bool? shouldRefresh = await showDialog<bool>(
        useSafeArea: true,
        context: context,
        builder: (context) {
          return BankInformationsForm(entity: customer);
        });
    if (shouldRefresh == true) {
      _refreshCustomers();
    }
  }

  Future<void> _addEntityType(EntityModel customer) async {
    final bool? shouldRefresh = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Ajouter ce client comme Partenaire'),
            content: const Text(
                'Vous allez ajouter ce client comme partenaire. Êtes-vous sûr de vouloir continuer ?'),
            actions: <Widget>[
              TextButton(
                child: const Text('Annuler'),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
              TextButton(
                child: const Text('Valider'),
                onPressed: () {
                  _customerUseCase.addEntityType(customer.id!);
                  Navigator.of(context).pop(true);
                },
              ),
            ],
          );
        });
    if (shouldRefresh == true) {
      _refreshCustomers();
    }
  }

  Future<void> _deleteCustomer(EntityModel customer) async {
    // final bool? shouldRefresh =
    await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Désactiver le partenaire'),
            content:
                const Text('Êtes-vous sûr de vouloir désactiver ce client ?'),
            actions: <Widget>[
              TextButton(
                child: const Text('Annuler'),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
              TextButton(
                child: const Text('Désactiver'),
                onPressed: () async {
                  await _customerUseCase.deleteCustomer(
                      customer.id!, customer.type!);
                  Navigator.of(context).pop(true);
                },
              ),
            ],
          );
        }).then((value) {
      if (value == true) {
        _refreshCustomers();
      }
    });
  }

  void search(String text) {
    _lastSearch = text;
    if (text.isEmpty) {
      setState(() {
        _filter = _lastFilter;
        _customers = sortedEntities[_filter] as List<EntityModel>;
      });
      return;
    }
    String firstLetter = text.substring(0, 1).toUpperCase();
    final List<EntityModel> suggestions =
        (sortedEntities[firstLetter] as List<EntityModel>).where((element) {
      final nameLower = element.name!.toLowerCase();
      final searchLower = text.toLowerCase();
      return nameLower.startsWith(searchLower);
    }).toList();
    setState(() {
      _lastSearch = text;
      _customers = suggestions;
      _filter = firstLetter;
    });
  }

  Future<void> _genUpdate(EntityModel customer) async {
    final bool? shouldRefresh = await showDialog<bool>(
        useSafeArea: true,
        context: context,
        builder: (context) {
          return UpdateCustomerForm(
            entity: customer,
          );
        });
    if (shouldRefresh == true) {
      _refreshCustomers();
    }
  }

  Future<void> _addressUpdate(EntityModel partner) async {
    final bool? shouldRefresh = await showDialog<bool>(
        useSafeArea: true,
        context: context,
        builder: (context) {
          return UpdateAddressForm(
            entity: partner,
          );
        });
    if (shouldRefresh == true) {
      _refreshCustomers();
    }
  }

  Future<void> _bankInformationsUpdate(EntityModel partner) async {
    final bool? shouldRefresh = await showDialog<bool>(
        useSafeArea: true,
        context: context,
        builder: (context) {
          return UpadateBankInformationsForm(
            entity: partner,
          );
        });
    if (shouldRefresh == true) {
      _refreshCustomers();
    }
  }

  _setNeoInitialIndex(int index) {
    tabController.animateTo(index);
    setState(() {
      neoCurrentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Column(
      children: [
        SelectableText('Ajouter un client',
            style: GoogleFonts.roboto(fontSize: 20)),
        Center(
          child: ElevatedButton(
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(kOrange),
                iconColor: WidgetStateProperty.all(kWhite),
              ),
              onPressed: () => _addCustomer(),
              child: const Icon(Icons.add)),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                SelectableText(
                  'Filtres : ',
                  style: GoogleFonts.roboto(fontSize: 20),
                ),
                InkResponse(
                  onHighlightChanged: (isHighlighted) {
                    if (isHighlighted) {
                      setState(() {
                        _buttonColor1 = kOrange;
                        _button1Selected = true;
                        _button2Selected = false;
                        _button3Selected = false;
                      });
                    } else {
                      setState(() {
                        _buttonColor1 = _button1Selected ? kOrange : kBlue;
                      });
                    }
                  },
                  child: FloatingActionButton(
                    onPressed: () {
                      _setNeoInitialIndex(0);
                    },
                    backgroundColor: _buttonColor1,
                    child: const Icon(Icons.people, color: Colors.white),
                  ),
                ),
                InkResponse(
                  onHighlightChanged: (isHighlighted) {
                    if (isHighlighted) {
                      setState(() {
                        _buttonColor2 = kOrange;
                        _button1Selected = false;
                        _button2Selected = true;
                        _button3Selected = false;
                      });
                    } else {
                      setState(() {
                        _buttonColor2 = _button2Selected ? kOrange : kBlue;
                      });
                    }
                  },
                  child: FloatingActionButton(
                    onPressed: () {
                      _setNeoInitialIndex(1);
                    },
                    backgroundColor: _buttonColor2,
                    child: const Icon(Icons.gps_fixed, color: Colors.white),
                  ),
                ),
                InkResponse(
                  onHighlightChanged: (isHighlighted) {
                    if (isHighlighted) {
                      setState(() {
                        _buttonColor3 = kOrange;
                        _button1Selected = false;
                        _button2Selected = false;
                        _button3Selected = true;
                      });
                    } else {
                      setState(() {
                        _buttonColor3 = _button3Selected ? kOrange : kBlue;
                      });
                    }
                  },
                  child: FloatingActionButton(
                    onPressed: () {
                      _setNeoInitialIndex(2);
                    },
                    backgroundColor: _buttonColor3,
                    child: const Icon(Icons.money, color: Colors.white),
                  ),
                ),
              ],
            ),
            SizedBox(
              width: SizeConfig.screenWidth * 0.1,
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  iconColor: kBlue,
                  focusColor: kGrey,
                  hintText: 'Rechercher...',
                  hintStyle: GoogleFonts.roboto(fontSize: 20),
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: kBlue, width: 2.0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: search,
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: SizeConfig.screenWidth * 0.8,
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 4.0,
            runSpacing: 8.0,
            children: availableFilters.map((letter) {
              return Container(
                padding: const EdgeInsets.all(0),
                width: 35,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _lastSearch = '';
                      searchController.clear();
                      _filter = letter;
                      _lastFilter = letter;
                      _customers = sortedEntities[_filter] as List<EntityModel>;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(5),
                    backgroundColor: _filter == letter ? kOrange : kBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      letter.toUpperCase(),
                      style: const TextStyle(color: kWhite),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _customers.length,
                  itemBuilder: (BuildContext context, int index) {
                    return DefaultTabController(
                      initialIndex: neoCurrentIndex,
                      length: 3,
                      child: Container(
                        decoration: BoxDecoration(
                          color: kLGrey,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: kBlack.withValues(alpha: 0.1),
                              spreadRadius: 1,
                              blurRadius: 1,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        margin: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 20),
                        child: Column(
                          children: [
                            Container(
                              height: 50,
                              decoration: const BoxDecoration(
                                color: kLBlue,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(10),
                                  topRight: Radius.circular(10),
                                ),
                              ),
                              child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20),
                                        child: SelectableText(
                                          _customers[index].name!,
                                          style:
                                              GoogleFonts.roboto(fontSize: 20),
                                        ),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          onPressed: () {
                                            _addOrder(_customers[index].id!,
                                                _customers[index].name!);
                                          },
                                          hoverColor: Colors.transparent
                                              .withValues(alpha: 0),
                                          icon: const Icon(Icons.list_alt,
                                              color: kBlack),
                                        ),
                                        const SizedBox(
                                          width: 25,
                                        ),
                                        PopupMenuButton<FirstBoxItem>(
                                          initialValue: firstBoxSelectedMenu,
                                          icon: const Icon(
                                              Icons.call_to_action_outlined),
                                          onSelected: (FirstBoxItem item) {
                                            switch (item) {
                                              case FirstBoxItem.itemOne:
                                                _genUpdate(_customers[index]);
                                                break;
                                              case FirstBoxItem.itemTwo:
                                                _customers[index].address !=
                                                        null
                                                    ? _addressUpdate(
                                                        _customers[index])
                                                    : _addAddress(
                                                        _customers[index].id!);
                                                break;
                                              case FirstBoxItem.itemThree:
                                                _customers[index]
                                                            .bankInformations !=
                                                        null
                                                    ? _bankInformationsUpdate(
                                                        _customers[index])
                                                    : _addBankInformations(
                                                        _customers[index]);
                                                break;
                                            }
                                          },
                                          itemBuilder: (BuildContext context) =>
                                              <PopupMenuEntry<FirstBoxItem>>[
                                            const PopupMenuItem<FirstBoxItem>(
                                              value: FirstBoxItem.itemOne,
                                              child: Text(
                                                  'Editer informations générales'),
                                            ),
                                            const PopupMenuDivider(),
                                            const PopupMenuItem<FirstBoxItem>(
                                              value: FirstBoxItem.itemTwo,
                                              child: Text('Editer l\'adresse'),
                                            ),
                                            const PopupMenuDivider(),
                                            const PopupMenuItem<FirstBoxItem>(
                                              value: FirstBoxItem.itemThree,
                                              child: Text(
                                                  'Editer informations bancaires'),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(
                                          width: 25,
                                        ),
                                        PopupMenuButton<SampleItem>(
                                          initialValue: selectedMenu,
                                          onSelected: (SampleItem item) {
                                            switch (item) {
                                              case SampleItem.itemOne:
                                                _addEntityType(
                                                    _customers[index]);
                                                break;
                                              case SampleItem.itemTwo:
                                                _deleteCustomer(
                                                    _customers[index]);
                                                break;
                                            }
                                            setState(() {
                                              selectedMenu = item;
                                            });
                                          },
                                          itemBuilder: (BuildContext context) =>
                                              <PopupMenuEntry<SampleItem>>[
                                            const PopupMenuItem<SampleItem>(
                                              value: SampleItem.itemOne,
                                              child: Text(
                                                  'Dupliquer ce Client en Partenaire'),
                                            ),
                                            const PopupMenuItem<SampleItem>(
                                              value: SampleItem.itemTwo,
                                              child:
                                                  Text('Désactiver ce client'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ]),
                            ),
                            const Divider(
                              height: 0,
                              color: Colors.white,
                              thickness: 1,
                            ),
                            TabBar(
                              controller: tabController,
                              indicatorColor: kLBlue,
                              indicator: const BoxDecoration(
                                color: kLBlue,
                              ),
                              tabs: [
                                Tab(
                                  child: Text(
                                    'Informations générales',
                                    style: GoogleFonts.roboto(
                                      fontSize: 16,
                                      color: kBlack,
                                    ),
                                  ),
                                ),
                                Tab(
                                  child: Text(
                                    'Adresse',
                                    style: GoogleFonts.roboto(
                                      fontSize: 16,
                                      color: kBlack,
                                    ),
                                  ),
                                ),
                                Tab(
                                  child: Text(
                                    'Informations bancaires',
                                    style: GoogleFonts.roboto(
                                      fontSize: 16,
                                      color: kBlack,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(
                              height: 0,
                              color: kLBlue,
                              thickness: 1,
                            ),
                            SizedBox(
                              height: 140,
                              child: TabBarView(
                                controller: tabController,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 15),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              SelectableText(
                                                'Informations personnelles:',
                                                style: GoogleFonts.poppins(
                                                  color: kBlack,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              SelectableText(
                                                'email: ${_customers[index].email}',
                                                style: GoogleFonts.poppins(
                                                    color: kBlack,
                                                    fontSize: 16,
                                                    fontWeight:
                                                        FontWeight.w400),
                                              ),
                                              SelectableText(
                                                'phone: ${_customers[index].phone}',
                                                style: GoogleFonts.poppins(
                                                    color: kBlack,
                                                    fontSize: 16,
                                                    fontWeight:
                                                        FontWeight.w400),
                                              ),
                                              SelectableText(
                                                'siret: ${_customers[index].siret}',
                                                style: GoogleFonts.poppins(
                                                    color: kBlack,
                                                    fontSize: 16,
                                                    fontWeight:
                                                        FontWeight.w400),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  _customers[index].address != null
                                      ? Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 15),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    SelectableText(
                                                      'Localisation:',
                                                      style:
                                                          GoogleFonts.poppins(
                                                        color: kBlack,
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    SelectableText(
                                                      'Adresse: ${_customers[index].address!.street}',
                                                      style:
                                                          GoogleFonts.poppins(
                                                              color: kBlack,
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w400),
                                                    ),
                                                    SelectableText(
                                                      'Code Postal: ${_customers[index].address!.zip}',
                                                      style:
                                                          GoogleFonts.poppins(
                                                              color: kBlack,
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w400),
                                                    ),
                                                    SelectableText(
                                                      'Ville: ${_customers[index].address!.city}',
                                                      style:
                                                          GoogleFonts.poppins(
                                                              color: kBlack,
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w400),
                                                    ),
                                                    SelectableText(
                                                      'Pays: ${_customers[index].address!.country}',
                                                      style:
                                                          GoogleFonts.poppins(
                                                              color: kBlack,
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w400),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const VerticalDivider(
                                              width: 1,
                                              color: kGrey,
                                              thickness: 1,
                                              indent: 10,
                                              endIndent: 10,
                                            ),
                                            Expanded(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 15),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    SelectableText(
                                                      'Coordonnées GPS:',
                                                      style:
                                                          GoogleFonts.poppins(
                                                        color: kBlack,
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    SelectableText(
                                                      'lat: ${_customers[index].address!.lat}',
                                                      style:
                                                          GoogleFonts.poppins(
                                                              color: kBlack,
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w400),
                                                    ),
                                                    SelectableText(
                                                      'long: ${_customers[index].address!.lng}',
                                                      style:
                                                          GoogleFonts.poppins(
                                                              color: kBlack,
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w400),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                      : Center(
                                          child: SelectableText(
                                            'Aucune adresse enregistrée pour le moment',
                                            style: GoogleFonts.poppins(
                                                color: kBlack,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w400),
                                          ),
                                        ),
                                  _customers[index].bankInformations != null
                                      ? Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  SelectableText(
                                                    'Numéro de compte comptabilité: ${_customers[index].bankInformations!.accountingNumber}',
                                                    style: GoogleFonts.poppins(
                                                        color: kBlack,
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w400),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        )
                                      : Center(
                                          child: SelectableText(
                                            'Aucune information bancaire enregistrée pour le moment',
                                            style: GoogleFonts.poppins(
                                                color: kBlack,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w400),
                                          ),
                                        ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        )
      ],
    );
  }
}
