import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:back_office_tribuneo_v2/config/size_config.dart';
import 'package:back_office_tribuneo_v2/domain/models/entity_model.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/partner_usecase.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/file_downloader.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/forms/addresses/address_form.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/forms/addresses/update_address_form.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/forms/bank_informations/bank_information_form.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/forms/bank_informations/update_bank_form.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/forms/partners/partner_form.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/forms/partners/sector_activity_form.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/forms/partners/update_partner_info_form.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/loading.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/_global.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/check_siret_dialog.dart';

enum QrBoxItem { itemOne, itemTwo, itemThree }

enum EditBoxItem { itemOne, itemTwo, itemThree, itemFour }

enum MenuBoxItem { itemOne, itemTwo }

class PartnersContentView extends StatefulWidget {
  const PartnersContentView({super.key});

  @override
  State<PartnersContentView> createState() => PartnersContentViewState();
}

class PartnersContentViewState extends State<PartnersContentView>
    with TickerProviderStateMixin {
  late final TabController tabController;
  final PartnerUseCase _partnerUseCase = PartnerUseCase();
  final DateFormat dateFormat = DateFormat('dd/MM/yyyy');
  TextEditingController searchController = TextEditingController();

  List<EntityModel> _partners = [];
  late List<EntityModel> allPartners;
  Map<String, List<EntityModel>> sortedEntities = {};
  List<String> availableFilters = [];
  late int neoInitialIndex = 0;
  late int neoCurrentIndex;
  bool _isLoading = false;
  String _filter = 'A';
  String _lastFilter = 'A';
  String _lastSearch = '';
  QrBoxItem? selectedMenuQr;
  EditBoxItem? selectedMenuEdit;
  MenuBoxItem? selectedMenu;

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
    _refreshPartners();
  }

  @override
  void dispose() {
    searchController.dispose();
    tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshPartners({bool withDelay = false}) async {
    if (withDelay) await Future.delayed(const Duration(milliseconds: 700));
    setState(() {
      _isLoading = true;
    });
    await _partnerUseCase.getPartners().then((value) {
      if (!mounted) return;

      Map<String, List<EntityModel>> sEntities =
          value[1] as Map<String, List<EntityModel>>;
      availableFilters = sEntities.keys.toList();
      sortedEntities = sEntities;
      allPartners = value[0];

      setState(() {
        if (_lastSearch.isNotEmpty) {
          search(_lastSearch);
        } else {
          _filter = availableFilters.contains(_lastFilter)
              ? _lastFilter
              : availableFilters[0];
          _partners = sortedEntities[_filter] ?? [];
        }
        _isLoading = false;
      });
    }).catchError((error) {
      setState(() {
        _isLoading = false;
      });
    });
  }

  void search(String text) {
    if (text.isEmpty) {
      setState(() {
        _filter = _lastFilter;
        _partners = sortedEntities[_filter] as List<EntityModel>;
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
      _partners = suggestions;
      _filter = firstLetter;
    });
  }

  String formatIban(String iban) {
    List<String> parts = [];
    for (int i = 0; i < iban.length; i += 4) {
      int end = i + 4;
      if (end > iban.length) {
        end = iban.length;
      }
      parts.add(iban.substring(i, end));
    }
    return parts.join(' ');
  }

  Future<void> _getPartnerReceiptQR(EntityModel partner) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const LoadingDialog(loadingText: 'Génération du QR Code...');
      },
    );
    String? name = partner.name;
    name = name!.replaceAll(' ', '_');
    await _partnerUseCase.createQRCodeReceipt(partner.id!).then((value) {
      List<dynamic> listDynamic = value;
      FileDownloader.downloadLargeFile(
          listDynamic, '${name}_qr_code', 'application/pdf',
          fileExtension: 'pdf');
      Navigator.of(context, rootNavigator: true).pop();
    });
  }

  Future<void> _getPartnerQR(EntityModel partner) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const LoadingDialog(loadingText: 'Génération du QR Code...');
      },
    );
    String? name = partner.name;
    name = name!.replaceAll(' ', '_');
    await _partnerUseCase.createQRCode(partner.id!).then((value) {
      List<dynamic> listDynamic = value;
      FileDownloader.downloadLargeFile(
          listDynamic, '${name}_qr_code', 'application/pdf',
          fileExtension: 'pdf');
      Navigator.of(context, rootNavigator: true).pop();
    });
  }

  Future<void> _getPartnerLink(EntityModel partner) async {
    String name = partner.name!;

    await _partnerUseCase.createLink(partner.id!, sendMail: false).then((link) {
      showDialog(
          context: context,
          builder: (BuildContext dialogContext) {
            bool isChecked = false;
            return StatefulBuilder(builder: (context, setState) {
              return AlertDialog(
                title: Text('Votre lien pour $name'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(child: SelectableText(link)),
                        IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: link));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Lien copié !'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Checkbox(
                          value: isChecked,
                          onChanged: (bool? value) {
                            setState(() {
                              isChecked = value ?? false;
                            });
                          },
                        ),
                        const Text('Envoyé par mail'),
                      ],
                    ),
                  ],
                ),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Fermer'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                    onPressed: isChecked
                        ? () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final navigator = Navigator.of(context);

                            try {
                              await _partnerUseCase.createLink(partner.id!,
                                  sendMail: true);

                              navigator.pop();

                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Lien envoyé par mail avec succès !'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } catch (e) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Erreur lors de l\'envoi : $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        : null,
                    child: const Text('Envoyer'),
                  ),
                ],
              );
            });
          });
    });
  }

  Future<void> _checkSiretAndAddPartner() async {
    await showDialog(
      useSafeArea: true,
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return CheckSiretDialog(
          onPartnerNotFound: (siret) {
            _addPartner(initialSiret: siret);
          },
          onPartnerRejected: () {
            snackbarKey.currentState?.showSnackBar(
              SnackBar(
                content: Text(
                  'Ajout annulé',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
                backgroundColor: Colors.red,
              ),
            );
          },
          onPartnerAccepted: (partner) async {
            try {
              EntityModel cleanPartner = EntityModel.fromJson({
                "name": partner.name,
                "email": partner.email,
                "siret": partner.siret,
                "phone": partner.phone,
                "accept_demat": partner.acceptDemat ?? false,
                "type": "partner",
              });

              dynamic response = await _partnerUseCase.addPartner(cleanPartner);

              if (response != null && response.toString().contains('error')) {
                throw Exception('L\'API a refusé les données du partenaire');
              }

              if (!mounted) return;

              snackbarKey.currentState?.showSnackBar(
                SnackBar(
                  content: Text(
                    'Partenaire ajouté avec succès !',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                  backgroundColor: Colors.green,
                ),
              );
              _refreshPartners(withDelay: true);
            } catch (e) {
              if (!mounted) return;

              snackbarKey.currentState?.showSnackBar(
                SnackBar(
                  content: Text(
                    'Erreur lors de l\'ajout du partenaire : $e',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        );
      },
    );
  }

  Future<void> _addPartner({String? initialSiret}) async {
    final bool? shouldRefresh = await showDialog<bool>(
        useSafeArea: true,
        context: context,
        builder: (context) {
          return PartnerForm(initialSiret: initialSiret);
        });
    if (shouldRefresh == true) {
      _refreshPartners(withDelay: true);
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
      _refreshPartners(withDelay: true);
    }
  }

  Future<void> _addBankInformations(EntityModel partner) async {
    final bool? shouldRefresh = await showDialog<bool>(
        useSafeArea: true,
        context: context,
        builder: (context) {
          return BankInformationsForm(entity: partner);
        });
    if (shouldRefresh == true) {
      _refreshPartners(withDelay: true);
    }
  }

  Future<void> _addActivity(EntityModel partner) async {
    final bool? shouldRefresh = await showDialog<bool>(
        useSafeArea: true,
        context: context,
        builder: (context) {
          return SectorCreationForm(partner: partner);
        });
    if (shouldRefresh == true) {
      _refreshPartners(withDelay: true);
    }
  }

  Future<void> _addEntityType(EntityModel partner) async {
    final bool? shouldRefresh = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Ajouter ce Partenaire comme Client'),
            content: const Text(
                'Vous allez ajouter ce Partenaire comme Client. Êtes-vous sûr de vouloir continuer ?'),
            actions: <Widget>[
              TextButton(
                child: const Text('Annuler'),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
              TextButton(
                child: const Text('Valider'),
                onPressed: () async {
                  await _partnerUseCase.addEntityType(partner.id!);
                  Navigator.of(context).pop(true);
                },
              ),
            ],
          );
        });
    if (shouldRefresh == true) {
      snackbarKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            'Partenaire dupliqué en client avec succès !',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Colors.green,
        ),
      );
      _refreshPartners(withDelay: true);
    }
  }

  Future<void> _genUpdate(EntityModel partner) async {
    final bool? shouldRefresh = await showDialog<bool>(
        useSafeArea: true,
        context: context,
        builder: (context) {
          return UpdatePartnerInfo(
            partner: partner,
          );
        });
    if (shouldRefresh == true) {
      _refreshPartners(withDelay: true);
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
      _refreshPartners(withDelay: true);
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
      _refreshPartners(withDelay: true);
    }
  }

  Future<void> _deletePartner(EntityModel partner) async {
    final bool? shouldRefresh = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Désactiver le partenaire'),
            content: const Text(
                'Êtes-vous sûr de vouloir désactiver ce partenaire ?'),
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
                  try {
                    bool deleted = await _partnerUseCase.deletePartner(
                        partner.id!);
                    Navigator.of(context).pop(true);
                    if (deleted) {
                      snackbarKey.currentState?.showSnackBar(
                        SnackBar(
                          content: Text(
                            'Partenaire désactivé avec succès !',
                            style: GoogleFonts.poppins(color: Colors.white),
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      snackbarKey.currentState?.showSnackBar(
                        SnackBar(
                          content: Text(
                            'Erreur lors de la désactivation du partenaire.',
                            style: GoogleFonts.poppins(color: Colors.white),
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } catch (e) {
                    snackbarKey.currentState?.showSnackBar(
                      SnackBar(
                        content: Text(
                          'Erreur lors de la désactivation du partenaire : $e',
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
            ],
          );
        });
    if (shouldRefresh == true) {
      _refreshPartners(withDelay: true);
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
        SelectableText('Ajouter un partenaire',
            style: GoogleFonts.roboto(fontSize: 20)),
        const SizedBox(
          height: 10,
        ),
        Center(
          child: ElevatedButton(
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(kOrange),
                iconColor: WidgetStateProperty.all(kWhite),
              ),
              onPressed: () => _checkSiretAndAddPartner(),
              child: const Icon(Icons.add)),
        ),
        const SizedBox(
          height: 20,
        ),
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
                      setState(() {
                        _setNeoInitialIndex(0);
                      });
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
                      setState(() {
                        _setNeoInitialIndex(1);
                      });
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
                      setState(() {
                        _setNeoInitialIndex(2);
                      });
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
        const SizedBox(
          height: 40,
        ),
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
                      _partners = sortedEntities[_filter] as List<EntityModel>;
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
        const SizedBox(
          height: 20,
        ),
        SizedBox(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _partners.length,
                  itemBuilder: (BuildContext context, int index) {
                    if (_partners[index]
                        .name!
                        .toLowerCase()
                        .startsWith(_filter.toLowerCase())) {
                      return DefaultTabController(
                        key: ValueKey(neoCurrentIndex),
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
                                          _partners[index].name!,
                                          style:
                                              GoogleFonts.roboto(fontSize: 20),
                                        ),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 40),
                                          child: Row(
                                            children: [
                                              Text(
                                                style: GoogleFonts.roboto(
                                                    fontSize: 15),
                                                'Accepte la dématérialisation : ',
                                              ),
                                              Text(
                                                style: GoogleFonts.roboto(
                                                    fontSize: 15,
                                                    fontWeight:
                                                        FontWeight.bold),
                                                _partners[index].acceptDemat ==
                                                        true
                                                    ? 'Oui'
                                                    : 'Non',
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 25,
                                        ),
                                        PopupMenuButton<QrBoxItem>(
                                          initialValue: selectedMenuQr,
                                          icon: const Icon(Icons.qr_code),
                                          tooltip: 'Menu Qrcode',
                                          onSelected: (QrBoxItem item) {
                                            switch (item) {
                                              case QrBoxItem.itemOne:
                                                _getPartnerReceiptQR(
                                                    _partners[index]);
                                                break;
                                              case QrBoxItem.itemTwo:
                                                _getPartnerQR(_partners[index]);
                                                break;
                                              case QrBoxItem.itemThree:
                                                _getPartnerLink(
                                                    _partners[index]);
                                                break;
                                            }
                                          },
                                          itemBuilder: (BuildContext context) =>
                                              <PopupMenuEntry<QrBoxItem>>[
                                            const PopupMenuItem<QrBoxItem>(
                                              value: QrBoxItem.itemOne,
                                              child: Text(
                                                  'Générer le QR Code de réception'),
                                            ),
                                            const PopupMenuDivider(),
                                            const PopupMenuItem<QrBoxItem>(
                                              value: QrBoxItem.itemTwo,
                                              child: Text(
                                                  'Générer le QR Code de première connexion'),
                                            ),
                                            const PopupMenuDivider(),
                                            const PopupMenuItem<QrBoxItem>(
                                              value: QrBoxItem.itemThree,
                                              child: Text(
                                                  'Générer le lien de première connexion'),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(
                                          width: 25,
                                        ),
                                        PopupMenuButton<EditBoxItem>(
                                          tooltip: 'Menu Edition',
                                          initialValue: selectedMenuEdit,
                                          icon: const Icon(
                                              Icons.call_to_action_outlined),
                                          onSelected: (EditBoxItem item) {
                                            switch (item) {
                                              case EditBoxItem.itemOne:
                                                _genUpdate(_partners[index]);
                                                break;
                                              case EditBoxItem.itemTwo:
                                                _addActivity(_partners[index]);
                                                break;
                                              case EditBoxItem.itemThree:
                                                _partners[index].address != null
                                                    ? _addressUpdate(
                                                        _partners[index])
                                                    : _addAddress(
                                                        _partners[index].id!);
                                                break;
                                              case EditBoxItem.itemFour:
                                                _partners[index]
                                                            .bankInformations !=
                                                        null
                                                    ? _bankInformationsUpdate(
                                                        _partners[index])
                                                    : _addBankInformations(
                                                        _partners[index]);
                                                break;
                                            }
                                          },
                                          itemBuilder: (BuildContext context) =>
                                              <PopupMenuEntry<EditBoxItem>>[
                                            const PopupMenuItem<EditBoxItem>(
                                              value: EditBoxItem.itemOne,
                                              child: Text(
                                                  'Editer informations générales'),
                                            ),
                                            const PopupMenuDivider(),
                                            const PopupMenuItem<EditBoxItem>(
                                              value: EditBoxItem.itemTwo,
                                              child: Text(
                                                  'Editer secteurs d\'activité'),
                                            ),
                                            const PopupMenuDivider(),
                                            const PopupMenuItem<EditBoxItem>(
                                              value: EditBoxItem.itemThree,
                                              child: Text('Editer l\'adresse'),
                                            ),
                                            const PopupMenuDivider(),
                                            const PopupMenuItem<EditBoxItem>(
                                              value: EditBoxItem.itemFour,
                                              child: Text(
                                                  'Editer informations bancaires'),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(
                                          width: 25,
                                        ),
                                        PopupMenuButton<MenuBoxItem>(
                                          tooltip: 'Afficher le Menu',
                                          initialValue: selectedMenu,
                                          onSelected: (MenuBoxItem item) {
                                            switch (item) {
                                              case MenuBoxItem.itemOne:
                                                _addEntityType(
                                                    _partners[index]);
                                                break;
                                              case MenuBoxItem.itemTwo:
                                                _deletePartner(
                                                    _partners[index]);
                                                break;
                                            }
                                            setState(() {
                                              selectedMenu = item;
                                            });
                                          },
                                          itemBuilder: (BuildContext context) =>
                                              <PopupMenuEntry<MenuBoxItem>>[
                                            const PopupMenuItem<MenuBoxItem>(
                                              value: MenuBoxItem.itemOne,
                                              child: Text(
                                                  'Dupliquer ce Partenaire en Client'),
                                            ),
                                            const PopupMenuItem<MenuBoxItem>(
                                              value: MenuBoxItem.itemTwo,
                                              child: Text(
                                                  'Désactiver ce partenaire'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(
                                height: 0,
                                color: Colors.white,
                                thickness: 1,
                              ),
                              TabBar(
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
                                                  'email: ${_partners[index].email}',
                                                  style: GoogleFonts.poppins(
                                                      color: kBlack,
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w400),
                                                ),
                                                SelectableText(
                                                  'phone: ${_partners[index].phone}',
                                                  style: GoogleFonts.poppins(
                                                      color: kBlack,
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w400),
                                                ),
                                                SelectableText(
                                                  'siret: ${_partners[index].siret}',
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
                                        const VerticalDivider(
                                          width: 1,
                                          color: kGrey,
                                          thickness: 1,
                                          indent: 10,
                                          endIndent: 10,
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 15),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                SelectableText(
                                                  'Secteurs d\'activité:',
                                                  style: GoogleFonts.poppins(
                                                    color: kBlack,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                if (_partners[index]
                                                        .activitySectors !=
                                                    null)
                                                  ..._partners[index]
                                                      .activitySectors!
                                                      .map((sector) {
                                                    return SelectableText(
                                                      '- ${sector.name}',
                                                      style:
                                                          GoogleFonts.poppins(
                                                              color: kBlack,
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w400),
                                                    );
                                                  }).toList()
                                                else
                                                  SelectableText(
                                                    'Pas de secteur d\'activité pour le moment',
                                                    style: GoogleFonts.poppins(
                                                        color: kBlack,
                                                        fontSize: 16,
                                                        fontStyle:
                                                            FontStyle.italic),
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
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 10, horizontal: 15),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                SelectableText(
                                                  'Solde Tribuneo actuel:',
                                                  style: GoogleFonts.poppins(
                                                    color: kBlack,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Center(
                                                    child: RichText(
                                                      text: TextSpan(
                                                        children: [
                                                          TextSpan(
                                                            text:
                                                                '${_partners[index].fundAmount}',
                                                            style: GoogleFonts
                                                                .poppins(
                                                              color: kBlack,
                                                              fontSize: 24,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                          TextSpan(
                                                            text: ' €',
                                                            style: GoogleFonts
                                                                .poppins(
                                                              color: kBlack,
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w400,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    _partners[index].address != null
                                        ? Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 15),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
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
                                                        'Adresse: ${_partners[index].address!.street}',
                                                        style:
                                                            GoogleFonts.poppins(
                                                                color: kBlack,
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w400),
                                                      ),
                                                      SelectableText(
                                                        'Code Postal: ${_partners[index].address!.zip}',
                                                        style:
                                                            GoogleFonts.poppins(
                                                                color: kBlack,
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w400),
                                                      ),
                                                      SelectableText(
                                                        'Ville: ${_partners[index].address!.city}',
                                                        style:
                                                            GoogleFonts.poppins(
                                                                color: kBlack,
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w400),
                                                      ),
                                                      SelectableText(
                                                        'Pays: ${_partners[index].address!.country}',
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
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 15),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
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
                                                        'lat: ${_partners[index].address!.lat}',
                                                        style:
                                                            GoogleFonts.poppins(
                                                                color: kBlack,
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w400),
                                                      ),
                                                      SelectableText(
                                                        'long: ${_partners[index].address!.lng}',
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
                                    _partners[index].bankInformations != null
                                        ? Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      vertical: 10,
                                                      horizontal: 15),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      SelectableText(
                                                        'Iban: ${formatIban(_partners[index].bankInformations!.iban!)}',
                                                        style:
                                                            GoogleFonts.poppins(
                                                                color: kBlack,
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w400),
                                                      ),
                                                      SelectableText(
                                                        'BIC: ${_partners[index].bankInformations!.bic}',
                                                        style:
                                                            GoogleFonts.poppins(
                                                                color: kBlack,
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w400),
                                                      ),
                                                      SelectableText(
                                                        'Clé RIB: ${_partners[index].bankInformations!.key}',
                                                        style:
                                                            GoogleFonts.poppins(
                                                                color: kBlack,
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w400),
                                                      ),
                                                      SelectableText(
                                                        'Code établissement: ${_partners[index].bankInformations!.bankCode}',
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
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      vertical: 10,
                                                      horizontal: 15),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      SelectableText(
                                                        'Code Guichet: ${_partners[index].bankInformations!.officeCode}',
                                                        style:
                                                            GoogleFonts.poppins(
                                                                color: kBlack,
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w400),
                                                      ),
                                                      SelectableText(
                                                        'Numéro de compte: ${_partners[index].bankInformations!.accountNumber}',
                                                        style:
                                                            GoogleFonts.poppins(
                                                                color: kBlack,
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w400),
                                                      ),
                                                      SelectableText(
                                                        'Numéro de comptabilité: ${_partners[index].bankInformations!.accountingNumber}',
                                                        style:
                                                            GoogleFonts.poppins(
                                                                color: kBlack,
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w400),
                                                      ),
                                                      SelectableText(
                                                        'Numéro intracommunautaire: ${_partners[index].bankInformations!.intraCommunityVat}',
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
                    } else {
                      return Container();
                    }
                  },
                ),
        ),
      ],
    );
  }
}
