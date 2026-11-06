import 'package:back_office_tribuneo_v2/presentation/widgets/tribuneo_loader.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:back_office_tribuneo_v2/config/size_config.dart';
import 'package:back_office_tribuneo_v2/core/notifiers/screen_open_requests.dart';
import 'package:back_office_tribuneo_v2/domain/models/entity_model.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/partner_usecase.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/file_downloader.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/formatters.dart';
import 'package:back_office_tribuneo_v2/presentation/views/my_single_page.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/arc/arc.dart';
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

/// Filtre d'affichage « Dématérialisation » de la barre d'outils.
enum _DematFilter { all, demat, paper }

class PartnersContentView extends StatefulWidget {
  const PartnersContentView({super.key});

  @override
  State<PartnersContentView> createState() => PartnersContentViewState();
}

class PartnersContentViewState extends State<PartnersContentView> {
  final PartnerUseCase _partnerUseCase = PartnerUseCase();
  TextEditingController searchController = TextEditingController();
  Timer? _searchDebounce;

  List<EntityModel> _partners = [];
  late List<EntityModel> allPartners;
  Map<String, List<EntityModel>> sortedEntities = {};
  List<String> availableFilters = [];
  bool _isLoading = false;
  String _filter = 'A';
  String _lastFilter = 'A';
  String _lastSearch = '';

  /// Fiche dépliée (une seule à la fois).
  int? _expandedId;

  /// Filtres d'affichage appliqués à la liste chargée.
  String? _sectorFilter;
  _DematFilter _dematFilter = _DematFilter.all;

  ScreenOpenRequests? _openRequests;
  bool _partnersLoaded = false;

  @override
  void initState() {
    super.initState();
    _openRequests = ScreenOpenRequests.maybeOf(context)
      ?..addListener(_handleOpenRequest);
    _refreshPartners();
  }

  @override
  void dispose() {
    _openRequests?.removeListener(_handleOpenRequest);
    _searchDebounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String text) {
    _searchDebounce?.cancel();
    _searchDebounce =
        Timer(const Duration(milliseconds: 500), () => search(text));
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
        _partnersLoaded = true;
      });
      _handleOpenRequest();
    }).catchError((error) {
      setState(() {
        _isLoading = false;
      });
      // Liste indisponible : une demande d'ouverture ne peut pas aboutir.
      if (_openRequests?.take(const {'bank_accounts'}) != null) {
        _showNotFound();
      }
    });
  }

  /// Deep-link de l'assistant : fiche du commerçant dépliée, avec ses
  /// informations bancaires. Attend que la liste soit chargée.
  void _handleOpenRequest() {
    if (!mounted || !_partnersLoaded) return;
    final int? idPartner = _openRequests?.take(const {'bank_accounts'})?.id;
    if (idPartner == null) return;
    final EntityModel? partner =
        allPartners.where((p) => p.id == idPartner).firstOrNull;
    if (partner == null) {
      _showNotFound();
      return;
    }
    final String name = partner.name ?? '';
    setState(() {
      _searchDebounce?.cancel();
      searchController.text = name;
      _lastSearch = name;
      _partners = [partner];
      _sectorFilter = null;
      _dematFilter = _DematFilter.all;
      _expandedId = partner.id;
    });
  }

  void _showNotFound() {
    snackbarKey.currentState
        ?.showSnackBar(const SnackBar(content: Text('Élément introuvable')));
  }

  void search(String text) {
    if (text.isEmpty) {
      setState(() {
        _filter = _lastFilter;
        _partners = sortedEntities[_filter] as List<EntityModel>;
      });
      return;
    }
    final searchLower = text.toLowerCase();
    final List<EntityModel> suggestions = allPartners.where((element) {
      return element.name!.toLowerCase().contains(searchLower);
    }).toList();
    setState(() {
      _lastSearch = text;
      _partners = suggestions;
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
              return ArcDialog(
                icon: Icons.link_rounded,
                title: 'Votre lien pour $name',
                maxWidth: 520,
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Lien de première connexion du magasin.'),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
                      decoration: BoxDecoration(
                        color: kNavy50,
                        borderRadius: BorderRadius.circular(kRadiusSm),
                        border: Border.all(color: kBorder),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                              child: SelectableText(link,
                                  style: ArcText.data(color: kNavy900))),
                          const SizedBox(width: 8),
                          ArcIconAction(
                            icon: Icons.copy_rounded,
                            tooltip: 'Copier le lien',
                            background: kSurface,
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
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      value: isChecked,
                      onChanged: (bool? value) {
                        setState(() {
                          isChecked = value ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text('Envoyer par mail',
                          style: ArcText.body(color: kInk)),
                    ),
                  ],
                ),
                actions: <Widget>[
                  OutlinedButton(
                    child: const Text('Fermer'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  FilledButton(
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
                                  backgroundColor: kSuccessText,
                                ),
                              );
                            } catch (e) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Erreur lors de l\'envoi : $e'),
                                  backgroundColor: kDangerText,
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
                backgroundColor: kDangerText,
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
                  backgroundColor: kSuccessText,
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
                  backgroundColor: kDangerText,
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

  Future<void> _addAddress(EntityModel partner) async {
    final bool? shouldRefresh = await showDialog<bool>(
        useSafeArea: true,
        context: context,
        builder: (context) {
          return AddressForm(entity: partner);
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
          return ArcDialog(
            icon: Icons.people_alt_outlined,
            title: 'Ajouter ce Partenaire comme Client',
            content: const Text(
                'Vous allez ajouter ce Partenaire comme Client. Êtes-vous sûr de vouloir continuer ?'),
            actions: <Widget>[
              OutlinedButton(
                child: const Text('Annuler'),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
              FilledButton(
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
          backgroundColor: kSuccessText,
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
          return ArcDialog(
            icon: Icons.store_mall_directory_outlined,
            tone: ArcTone.danger,
            title: 'Désactiver le partenaire',
            content: const Text(
                'Êtes-vous sûr de vouloir désactiver ce partenaire ?'),
            actions: <Widget>[
              OutlinedButton(
                child: const Text('Annuler'),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
              FilledButton(
                style: arcDangerButtonStyle(),
                child: const Text('Désactiver'),
                onPressed: () async {
                  try {
                    bool deleted =
                        await _partnerUseCase.deletePartner(partner.id!);
                    Navigator.of(context).pop(true);
                    if (deleted) {
                      snackbarKey.currentState?.showSnackBar(
                        SnackBar(
                          content: Text(
                            'Partenaire désactivé avec succès !',
                            style: GoogleFonts.poppins(color: Colors.white),
                          ),
                          backgroundColor: kSuccessText,
                        ),
                      );
                    } else {
                      snackbarKey.currentState?.showSnackBar(
                        SnackBar(
                          content: Text(
                            'Erreur lors de la désactivation du partenaire.',
                            style: GoogleFonts.poppins(color: Colors.white),
                          ),
                          backgroundColor: kDangerText,
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
                        backgroundColor: kDangerText,
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

  void _onQr(EntityModel partner, QrBoxItem item) {
    switch (item) {
      case QrBoxItem.itemOne:
        _getPartnerReceiptQR(partner);
        break;
      case QrBoxItem.itemTwo:
        _getPartnerQR(partner);
        break;
      case QrBoxItem.itemThree:
        _getPartnerLink(partner);
        break;
    }
  }

  void _onEdit(EntityModel partner, EditBoxItem item) {
    switch (item) {
      case EditBoxItem.itemOne:
        _genUpdate(partner);
        break;
      case EditBoxItem.itemTwo:
        _addActivity(partner);
        break;
      case EditBoxItem.itemThree:
        partner.address != null
            ? _addressUpdate(partner)
            : _addAddress(partner);
        break;
      case EditBoxItem.itemFour:
        partner.bankInformations != null
            ? _bankInformationsUpdate(partner)
            : _addBankInformations(partner);
        break;
    }
  }

  void _onMenu(EntityModel partner, MenuBoxItem item) {
    switch (item) {
      case MenuBoxItem.itemOne:
        _addEntityType(partner);
        break;
      case MenuBoxItem.itemTwo:
        _deletePartner(partner);
        break;
    }
  }

  void _pickLetter(String letter) {
    setState(() {
      _lastSearch = '';
      searchController.clear();
      _filter = letter;
      _lastFilter = letter;
      _partners = sortedEntities[_filter] as List<EntityModel>;
    });
  }

  /// Liste affichée : lettre (hors recherche), secteur et dématérialisation.
  List<EntityModel> get _visiblePartners => _partners.where((partner) {
        if (_lastSearch.isEmpty &&
            !(partner.name ?? '')
                .toLowerCase()
                .startsWith(_filter.toLowerCase())) {
          return false;
        }
        if (_dematFilter == _DematFilter.demat && partner.acceptDemat != true) {
          return false;
        }
        if (_dematFilter == _DematFilter.paper && partner.acceptDemat == true) {
          return false;
        }
        if (_sectorFilter != null &&
            !(partner.activitySectors ?? [])
                .any((sector) => sector.name == _sectorFilter)) {
          return false;
        }
        return true;
      }).toList();

  /// Secteurs présents dans la liste chargée.
  List<String> get _sectorNames {
    if (!_partnersLoaded) return const [];
    final Set<String> names = {
      for (final partner in allPartners)
        for (final sector in partner.activitySectors ?? const [])
          if ((sector.name ?? '').isNotEmpty) sector.name!,
    };
    return names.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    final List<EntityModel> partners = _visiblePartners;
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ArcPageHeader(
            eyebrow: 'Réseau',
            title: 'Magasins partenaires',
            actions: [
              OutlinedButton.icon(
                onPressed: () =>
                    MySinglePage.maybeOf(context)?.openMenu('merchantImport'),
                icon: const Icon(Icons.upload_file_outlined, size: 18),
                label: const Text('Importer des commerçants'),
              ),
              FilledButton.icon(
                onPressed: () => _checkSiretAndAddPartner(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Ajouter un partenaire'),
              ),
            ],
          ),
          _buildToolbar(),
          const SizedBox(height: 16),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: TribuneoLoader()),
            )
          else if (partners.isEmpty)
            ArcEmptyState(
              icon: Icons.storefront_outlined,
              title: 'Aucun partenaire',
              message: _lastSearch.isNotEmpty ||
                      _sectorFilter != null ||
                      _dematFilter != _DematFilter.all
                  ? 'Aucun partenaire ne correspond à ces critères.'
                  : null,
            )
          else
            for (int i = 0; i < partners.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              _buildPartnerCard(partners[i]),
            ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Barre d'outils

  Widget _buildToolbar() {
    final List<String> sectors = _sectorNames;
    return ArcCard(
      padding: const EdgeInsets.all(12),
      radius: 14,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ArcSearchField(
              controller: searchController,
              hint: 'Nom du partenaire…',
              semanticLabel: 'Rechercher un partenaire',
              width: 300,
              onChanged: _onSearchChanged,
            ),
            Container(
              height: 40,
              padding: const EdgeInsets.only(left: 12, right: 6),
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(kRadiusSm),
                border: Border.all(color: kBorder, width: 1.5),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: sectors.contains(_sectorFilter) ? _sectorFilter : null,
                  hint: Text('Tous les secteurs',
                      style: GoogleFonts.poppins(fontSize: 13, color: kInk)),
                  icon: const Icon(Icons.expand_more_rounded, size: 18),
                  borderRadius: BorderRadius.circular(12),
                  style: GoogleFonts.poppins(fontSize: 13, color: kInk),
                  onChanged: (value) => setState(() => _sectorFilter = value),
                  items: [
                    const DropdownMenuItem<String?>(
                        value: null, child: Text('Tous les secteurs')),
                    for (final name in sectors)
                      DropdownMenuItem<String?>(value: name, child: Text(name)),
                  ],
                ),
              ),
            ),
            ArcSegmented<_DematFilter>(
              segments: const [
                ArcSegment(_DematFilter.all, 'Tous'),
                ArcSegment(_DematFilter.demat, 'Dématérialisés'),
                ArcSegment(_DematFilter.paper, 'Papier seul'),
              ],
              selected: _dematFilter,
              onChanged: (value) => setState(() => _dematFilter = value),
            ),
          ],
        ),
        if (availableFilters.isNotEmpty) ...[
          const SizedBox(height: 12),
          // Une lettre par bouton, comme sur l'écran Clients.
          ArcLetterBar(
            letters: availableFilters,
            selected: _lastSearch.isEmpty ? _filter : null,
            onSelected: _pickLetter,
          ),
        ],
      ]),
    );
  }

  // ---------------------------------------------------------------------------
  // Fiche partenaire

  Widget _buildPartnerCard(EntityModel partner) {
    final bool open = _expandedId != null && _expandedId == partner.id;
    void toggle() => setState(() => _expandedId = open ? null : partner.id);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(kRadiusMd),
        border: Border.all(color: open ? kNavy300 : kBorder),
        boxShadow: open
            ? const [
                BoxShadow(
                    color: Color(0x401F2240),
                    blurRadius: 24,
                    spreadRadius: -10,
                    offset: Offset(0, 8)),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: kSurface,
            child: InkWell(
              onTap: toggle,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: LayoutBuilder(builder: (context, constraints) {
                  final Widget identity = Row(
                    children: [
                      ArcAvatar(partner.name ?? '', size: 44),
                      const SizedBox(width: 16),
                      Expanded(child: _identity(partner)),
                    ],
                  );
                  final Widget balance = _balance(partner);
                  final Widget actions = _actions(partner, open, toggle);
                  if (constraints.maxWidth >= 760) {
                    return Row(children: [
                      Expanded(child: identity),
                      const SizedBox(width: 16),
                      balance,
                      const SizedBox(width: 16),
                      actions,
                    ]);
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      identity,
                      const SizedBox(height: 12),
                      Row(children: [balance, const Spacer(), actions]),
                    ],
                  );
                }),
              ),
            ),
          ),
          if (open) _details(partner),
        ],
      ),
    );
  }

  Widget _identity(EntityModel partner) {
    final String code = (partner.code ?? '').trim();
    final sectors = partner.activitySectors ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(partner.name ?? '', style: ArcText.cardTitle()),
            if (code.isNotEmpty)
              Text(code, style: ArcText.dataSmall(color: kText3)),
          ],
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (sectors.isEmpty)
              const _SectorTag("Pas de secteur d'activité", muted: true)
            else
              for (final sector in sectors) _SectorTag(sector.name ?? ''),
            partner.acceptDemat == true
                ? const ArcPill('Dématérialisé',
                    tone: ArcTone.success, icon: Icons.smartphone_rounded)
                : const ArcPill('Papier seul',
                    tone: ArcTone.neutral, icon: Icons.description_outlined),
            if ((partner.username ?? '').trim().isEmpty)
              const ArcPill('Aucun compte utilisateur',
                  tone: ArcTone.warning, icon: Icons.person_off_outlined),
          ],
        ),
      ],
    );
  }

  Widget _balance(EntityModel partner) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('SOLDE TRIBUNEO',
              style: ArcText.label(color: kText3).copyWith(fontSize: 11)),
          Text(
            partner.fundAmount == null ? '—' : formatEuro(partner.fundAmount),
            style: ArcText.data(color: kNavy900, fontWeight: FontWeight.w500)
                .copyWith(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _actions(EntityModel partner, bool open, VoidCallback toggle) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _squareMenu<QrBoxItem>(
          icon: Icons.qr_code_2_rounded,
          tooltip: 'QR code du magasin',
          onSelected: (item) => _onQr(partner, item),
          items: const [
            PopupMenuItem<QrBoxItem>(
              value: QrBoxItem.itemOne,
              child: Text('Générer le QR Code de réception'),
            ),
            PopupMenuItem<QrBoxItem>(
              value: QrBoxItem.itemTwo,
              child: Text('Générer le QR Code de première connexion'),
            ),
            PopupMenuItem<QrBoxItem>(
              value: QrBoxItem.itemThree,
              child: Text('Générer le lien de première connexion'),
            ),
          ],
        ),
        const SizedBox(width: 6),
        _squareMenu<EditBoxItem>(
          icon: Icons.edit_outlined,
          tooltip: 'Modifier le partenaire',
          onSelected: (item) => _onEdit(partner, item),
          items: const [
            PopupMenuItem<EditBoxItem>(
              value: EditBoxItem.itemOne,
              child: Text('Editer informations générales'),
            ),
            PopupMenuItem<EditBoxItem>(
              value: EditBoxItem.itemTwo,
              child: Text('Editer secteurs d\'activité'),
            ),
            PopupMenuItem<EditBoxItem>(
              value: EditBoxItem.itemThree,
              child: Text('Editer l\'adresse'),
            ),
            PopupMenuItem<EditBoxItem>(
              value: EditBoxItem.itemFour,
              child: Text('Editer informations bancaires'),
            ),
          ],
        ),
        const SizedBox(width: 6),
        _squareMenu<MenuBoxItem>(
          icon: Icons.more_horiz_rounded,
          tooltip: "Plus d'actions",
          onSelected: (item) => _onMenu(partner, item),
          items: [
            const PopupMenuItem<MenuBoxItem>(
              value: MenuBoxItem.itemOne,
              child: Text('Dupliquer ce Partenaire en Client'),
            ),
            const PopupMenuDivider(),
            PopupMenuItem<MenuBoxItem>(
              value: MenuBoxItem.itemTwo,
              child: Text('Désactiver ce partenaire',
                  style: GoogleFonts.poppins(fontSize: 13, color: kDangerText)),
            ),
          ],
        ),
        const SizedBox(width: 6),
        ArcIconAction(
          icon: open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
          tooltip: open ? 'Replier la fiche' : 'Déplier la fiche',
          background: open ? kNavy600 : kNavy50,
          foreground: open ? Colors.white : kNavy600,
          onPressed: toggle,
        ),
      ],
    );
  }

  /// Bouton carré (36 px, fond Navy 50) qui ouvre un menu.
  Widget _squareMenu<T>({
    required IconData icon,
    required String tooltip,
    required ValueChanged<T> onSelected,
    required List<PopupMenuEntry<T>> items,
  }) {
    return PopupMenuButton<T>(
      tooltip: tooltip,
      onSelected: onSelected,
      itemBuilder: (BuildContext context) => items,
      child: Container(
        width: kControlHeightCompact,
        height: kControlHeightCompact,
        decoration: BoxDecoration(
          color: kNavy50,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: kNavy600),
      ),
    );
  }

  Widget _details(EntityModel partner) {
    final Widget general = _column('Informations générales', [
      ArcDefinitionList([
        ('Email', _value(partner.email)),
        ('Téléphone', _value(partner.phone, mono: true)),
        ('SIRET', _value(partner.siret, mono: true)),
        ('Utilisateur', _value(partner.username)),
      ], labelWidth: 96),
    ]);

    final address = partner.address;
    final Widget addressColumn = _column('Adresse', [
      if (address == null)
        Text('Aucune adresse enregistrée pour le moment',
            style: ArcText.small(color: kText3))
      else ...[
        SelectableText(
          [
            address.street ?? '',
            '${address.zip ?? ''} ${address.city ?? ''}'.trim(),
            address.country ?? '',
          ].where((line) => line.isNotEmpty).join('\n'),
          style: ArcText.body().copyWith(fontSize: 13),
        ),
        const SizedBox(height: 4),
        ArcDefinitionList([
          ('Latitude', _value(address.lat?.toString(), mono: true)),
          ('Longitude', _value(address.lng?.toString(), mono: true)),
        ], labelWidth: 96),
      ],
    ]);

    final bank = partner.bankInformations;
    final Widget bankColumn = _column('Informations bancaires', [
      if (bank == null)
        Text('Aucune information bancaire enregistrée pour le moment',
            style: ArcText.small(color: kText3))
      else
        ArcDefinitionList([
          (
            'IBAN',
            _value(bank.iban == null ? null : formatIban(bank.iban!),
                mono: true)
          ),
          ('BIC', _value(bank.bic, mono: true)),
          ('Clé RIB', _value(bank.key, mono: true)),
          ('Code établ.', _value(bank.bankCode, mono: true)),
          ('Code guichet', _value(bank.officeCode, mono: true)),
          ('N° compte', _value(bank.accountNumber, mono: true)),
          ('N° compta.', _value(bank.accountingNumber, mono: true)),
          ('N° intracom.', _value(bank.intraCommunityVat, mono: true)),
        ], labelWidth: 96),
    ]);

    return Container(
      decoration: const BoxDecoration(
        color: kSurface2,
        border: Border(top: BorderSide(color: kNavy100)),
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth >= 760) {
          return Table(
            border:
                const TableBorder(verticalInside: BorderSide(color: kNavy100)),
            children: [
              TableRow(children: [general, addressColumn, bankColumn]),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            general,
            const Divider(color: kNavy100),
            addressColumn,
            const Divider(color: kNavy100),
            bankColumn,
          ],
        );
      }),
    );
  }

  Widget _column(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: ArcText.label(color: kText2)),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  /// Valeur de fiche ; « Non renseigné » en gris si elle est absente.
  Widget _value(String? value, {bool mono = false}) {
    if (value == null || value.trim().isEmpty || value == 'null') {
      return Text('Non renseigné', style: ArcText.small(color: kText3));
    }
    return SelectableText(value, style: mono ? ArcText.data() : null);
  }
}

/// Étiquette de secteur d'activité (coins de 6 px, fond Navy 50).
class _SectorTag extends StatelessWidget {
  final String label;
  final bool muted;
  const _SectorTag(this.label, {this.muted = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: kNavy50,
        borderRadius: BorderRadius.circular(kRadiusXs),
        border: Border.all(color: muted ? kBorder : kNavy200),
      ),
      child: Text(label,
          style: GoogleFonts.poppins(
              fontSize: 12,
              color: muted ? kText3 : kNavy700,
              fontStyle: muted ? FontStyle.italic : FontStyle.normal)),
    );
  }
}
