import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:back_office_tribuneo_v2/config/size_config.dart';
import 'package:back_office_tribuneo_v2/domain/models/entity_model.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/customer_usecase.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';
import 'package:back_office_tribuneo_v2/presentation/views/my_single_page.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/arc/arc.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/forms/addresses/address_form.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/forms/addresses/update_address_form.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/forms/bank_informations/bank_information_form.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/forms/bank_informations/update_bank_form.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/forms/customers/customer_form.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/forms/customers/update_customers_form.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/forms/orders/order_form.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/check_siret_dialog.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/_global.dart';

/// Actions du menu « Plus d'actions » d'une ligne client.
enum _CustomerAction { editGeneral, editAddress, editBank, toPartner, disable }

class CustomersContentView extends StatefulWidget {
  const CustomersContentView({super.key});

  @override
  State<CustomersContentView> createState() => CustomersContentViewState();
}

class CustomersContentViewState extends State<CustomersContentView> {
  final CustomerUseCase _customerUseCase = CustomerUseCase();
  TextEditingController searchController = TextEditingController();
  Timer? _searchDebounce;
  bool _isLoading = false;
  List<EntityModel> _customers = [];
  late List<EntityModel> allCustomers;
  Map<String, List<EntityModel>> sortedEntities = {};
  List<String> availableFilters = [];

  /// Onglet de la fiche latérale : 0 Général, 1 Adresse, 2 Banque.
  int neoCurrentIndex = 0;

  /// Client affiché dans la fiche latérale (le premier de la liste par défaut).
  int? _selectedId;

  String _filter = 'A';
  String _lastFilter = 'A';
  String _lastSearch = '';

  @override
  void initState() {
    super.initState();
    _refreshCustomers();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String text) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () => search(text));
  }

  Future<void> _refreshCustomers({bool withDelay = false}) async {
    if (withDelay) await Future.delayed(const Duration(milliseconds: 700));
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

  Future<void> _askCustomerType() async {
    final bool? isIndividual = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return ArcDialog(
          icon: Icons.person_add_alt_1_outlined,
          title: 'Ajouter un client',
          content: const Text('Ce client est-il un particulier ?'),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Non, une entreprise'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Oui, un particulier'),
            ),
          ],
        );
      },
    );

    if (isIndividual == true) {
      _addCustomer(isIndividual: true);
    } else if (isIndividual == false) {
      _checkSiretAndAddCustomer();
    }
  }

  Future<void> _checkSiretAndAddCustomer() async {
    await showDialog(
      useSafeArea: true,
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return CheckSiretDialog(
          onPartnerNotFound: (siret) {
            _addCustomer(initialSiret: siret, isIndividual: false);
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
          onPartnerAccepted: (customer) async {
            try {
              EntityModel cleanCustomer = EntityModel.fromJson({
                "name": customer.name,
                "email": customer.email,
                "siret": customer.siret,
                "phone": customer.phone,
                "accept_demat": customer.acceptDemat ?? false,
                "type": "customer",
              });

              await _customerUseCase.addCustomer(cleanCustomer);
              if (!mounted) return;

              snackbarKey.currentState?.showSnackBar(
                SnackBar(
                  content: Text(
                    'Client ajouté avec succès !',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                  backgroundColor: kSuccessText,
                ),
              );
              _refreshCustomers(withDelay: true);
            } catch (e) {
              if (!mounted) return;

              snackbarKey.currentState?.showSnackBar(
                SnackBar(
                  content: Text(
                    'Erreur lors de l\'ajout du client : $e',
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

  Future<void> _addCustomer({String? initialSiret, bool? isIndividual}) async {
    final bool? shouldRefresh = await showDialog<bool>(
        useSafeArea: true,
        context: context,
        builder: (context) {
          return CustomerForm(
              initialSiret: initialSiret, isIndividual: isIndividual);
        });
    if (shouldRefresh == true) {
      _refreshCustomers(withDelay: true);
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
      _refreshCustomers(withDelay: true);
    }
  }

  Future<void> _addAddress(EntityModel customers) async {
    final bool? shouldRefresh = await showDialog<bool>(
        useSafeArea: true,
        context: context,
        builder: (context) {
          return AddressForm(entity: customers);
        });
    if (shouldRefresh == true) {
      _refreshCustomers(withDelay: true);
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
      _refreshCustomers(withDelay: true);
    }
  }

  Future<void> _addEntityType(EntityModel customer) async {
    final bool? shouldRefresh = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return ArcDialog(
            icon: Icons.storefront_outlined,
            title: 'Ajouter ce client comme Partenaire',
            content: const Text(
                'Vous allez ajouter ce client comme partenaire. Êtes-vous sûr de vouloir continuer ?'),
            actions: <Widget>[
              OutlinedButton(
                child: const Text('Annuler'),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
              FilledButton(
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
      snackbarKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            'Client dupliqué en partenaire avec succès !',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: kSuccessText,
        ),
      );
      _refreshCustomers(withDelay: true);
    }
  }

  Future<void> _deleteCustomer(EntityModel customer) async {
    final bool? shouldRefresh = await showDialog<bool>(
        context: context,
        builder: (BuildContext dialogContext) {
          return ArcDialog(
            icon: Icons.person_off_outlined,
            tone: ArcTone.danger,
            title: 'Désactiver le client',
            content:
                const Text('Êtes-vous sûr de vouloir désactiver ce client ?'),
            actions: <Widget>[
              OutlinedButton(
                child: const Text('Annuler'),
                onPressed: () {
                  Navigator.of(dialogContext).pop(false);
                },
              ),
              FilledButton(
                style: arcDangerButtonStyle(),
                child: const Text('Désactiver'),
                onPressed: () async {
                  try {
                    bool deleted = await _customerUseCase.deleteCustomer(
                        customer.id!, customer.type!);
                    Navigator.of(dialogContext).pop(true);
                    if (deleted) {
                      snackbarKey.currentState?.showSnackBar(
                        SnackBar(
                          content: Text(
                            'Client désactivé avec succès !',
                            style: GoogleFonts.poppins(color: Colors.white),
                          ),
                          backgroundColor: kSuccessText,
                        ),
                      );
                    } else {
                      snackbarKey.currentState?.showSnackBar(
                        SnackBar(
                          content: Text(
                            "Erreur lors de la désactivation du client, au moins une commande associée n'est pas totalement payée.",
                            style: GoogleFonts.poppins(color: Colors.white),
                          ),
                          backgroundColor: kDangerText,
                        ),
                      );
                    }
                  } catch (e) {
                    Navigator.of(dialogContext).pop(true);
                    snackbarKey.currentState?.showSnackBar(
                      SnackBar(
                        content: Text(
                          'Erreur lors de la désactivation : $e',
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
      _refreshCustomers(withDelay: true);
    }
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
    final searchLower = text.toLowerCase();
    final List<EntityModel> suggestions = allCustomers.where((element) {
      return element.name!.toLowerCase().contains(searchLower);
    }).toList();
    setState(() {
      _lastSearch = text;
      _customers = suggestions;
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
      _refreshCustomers(withDelay: true);
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
      _refreshCustomers(withDelay: true);
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
      _refreshCustomers(withDelay: true);
    }
  }

  void _setNeoInitialIndex(int index) {
    setState(() {
      neoCurrentIndex = index;
    });
  }

  void _editAddress(EntityModel customer) {
    customer.address != null ? _addressUpdate(customer) : _addAddress(customer);
  }

  void _editBank(EntityModel customer) {
    customer.bankInformations != null
        ? _bankInformationsUpdate(customer)
        : _addBankInformations(customer);
  }

  void _onAction(EntityModel customer, _CustomerAction action) {
    switch (action) {
      case _CustomerAction.editGeneral:
        _genUpdate(customer);
        break;
      case _CustomerAction.editAddress:
        _editAddress(customer);
        break;
      case _CustomerAction.editBank:
        _editBank(customer);
        break;
      case _CustomerAction.toPartner:
        _addEntityType(customer);
        break;
      case _CustomerAction.disable:
        _deleteCustomer(customer);
        break;
    }
  }

  void _pickLetter(String letter) {
    setState(() {
      _lastSearch = '';
      searchController.clear();
      _filter = letter;
      _lastFilter = letter;
      _customers = sortedEntities[_filter] as List<EntityModel>;
    });
  }

  EntityModel? get _selected {
    if (_customers.isEmpty) return null;
    return _customers.where((c) => c.id == _selectedId).firstOrNull ??
        _customers.first;
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    final EntityModel? selected = _isLoading ? null : _selected;
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ArcPageHeader(
            eyebrow: 'Réseau',
            title: 'Clients',
            actions: [
              OutlinedButton.icon(
                onPressed: () =>
                    MySinglePage.maybeOf(context)?.openMenu('merchantImport'),
                icon: const Icon(Icons.upload_file_outlined, size: 18),
                label: const Text('Importer'),
              ),
              FilledButton.icon(
                onPressed: () => _askCustomerType(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Ajouter un client'),
              ),
            ],
          ),
          LayoutBuilder(builder: (context, constraints) {
            final Widget table = _buildTableCard();
            if (selected == null) return table;
            final Widget sheet = _buildSheet(selected);
            if (constraints.maxWidth >= 920) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: table),
                  const SizedBox(width: 20),
                  SizedBox(width: 380, child: sheet),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [table, const SizedBox(height: 20), sheet],
            );
          }),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tableau

  Widget _buildTableCard() {
    final int count = _customers.length;
    return ArcTableCard(
      toolbar: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ArcSearchField(
            controller: searchController,
            hint: 'Nom du client…',
            semanticLabel: 'Rechercher un client',
            width: 280,
            onChanged: _onSearchChanged,
          ),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              for (final letter in availableFilters) _letterButton(letter),
            ],
          ),
        ],
      ),
      footer: ArcPagination(
        leading: Text(
          _lastSearch.isNotEmpty
              ? 'Recherche « $_lastSearch »'
              : 'Lettre ${_filter.toUpperCase()}',
          overflow: TextOverflow.ellipsis,
          style: ArcText.small(),
        ),
        label: count == 0 ? '0 sur 0' : '1–$count sur $count',
      ),
      child: _isLoading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          : _customers.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(20),
                  child: ArcEmptyState(
                    icon: Icons.people_alt_outlined,
                    title: 'Aucun client',
                    message: _lastSearch.isNotEmpty
                        ? 'Aucun client ne correspond à « $_lastSearch ».'
                        : null,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _tableHeader(),
                    for (final customer in _customers) _tableRow(customer),
                  ],
                ),
    );
  }

  Widget _letterButton(String letter) {
    final bool on = _lastSearch.isEmpty && _filter == letter;
    return Tooltip(
      message: 'Lettre ${letter.toUpperCase()}',
      child: Material(
        color: on ? kNavy600 : kSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: on ? kNavy600 : kBorder),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _pickLetter(letter),
          child: SizedBox(
            width: 28,
            height: 28,
            child: Center(
              child: Text(
                letter.toUpperCase(),
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: on ? Colors.white : kText2),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static TextStyle get _headStyle => GoogleFonts.poppins(
      fontSize: 12, fontWeight: FontWeight.w600, color: kText2);

  Widget _tableHeader() {
    return Container(
      color: kSurface2,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(children: [
        Expanded(flex: 5, child: Text('Client', style: _headStyle)),
        const SizedBox(width: 12),
        Expanded(flex: 4, child: Text('Contact', style: _headStyle)),
        const SizedBox(width: 76),
      ]),
    );
  }

  Widget _tableRow(EntityModel customer) {
    final bool selected = _selected?.id == customer.id;
    final String siret = customer.siret ?? '';
    final String phone = customer.phone ?? '';
    return Material(
      color: selected ? kNavy50 : kSurface,
      child: InkWell(
        onTap: () => setState(() => _selectedId = customer.id),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: kNavy100)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
          child: Row(children: [
            Expanded(
              flex: 5,
              child: Row(children: [
                ArcAvatar(customer.name ?? '', size: 34),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.name ?? '',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: kNavy900),
                      ),
                      if (siret.isNotEmpty)
                        Text(siret, style: ArcText.dataSmall(color: kText3)),
                    ],
                  ),
                ),
              ]),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.email ?? '',
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(fontSize: 13, color: kInk),
                  ),
                  if (phone.isNotEmpty)
                    Text(phone, style: ArcText.dataSmall(color: kText3)),
                ],
              ),
            ),
            SizedBox(
              width: 76,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: IconButton(
                      tooltip: 'Créer une commande',
                      padding: EdgeInsets.zero,
                      iconSize: 18,
                      style: IconButton.styleFrom(
                          minimumSize: const Size(32, 32),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8))),
                      onPressed: () =>
                          _addOrder(customer.id!, customer.name!),
                      icon: const Icon(Icons.post_add_rounded),
                    ),
                  ),
                  const SizedBox(width: 4),
                  _actionsMenu(customer),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _actionsMenu(EntityModel customer) {
    return PopupMenuButton<_CustomerAction>(
      tooltip: "Plus d'actions",
      onSelected: (action) => _onAction(customer, action),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<_CustomerAction>>[
        const PopupMenuItem<_CustomerAction>(
          value: _CustomerAction.editGeneral,
          child: Text('Editer informations générales'),
        ),
        const PopupMenuItem<_CustomerAction>(
          value: _CustomerAction.editAddress,
          child: Text('Editer l\'adresse'),
        ),
        const PopupMenuItem<_CustomerAction>(
          value: _CustomerAction.editBank,
          child: Text('Editer informations bancaires'),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<_CustomerAction>(
          value: _CustomerAction.toPartner,
          child: Text('Dupliquer ce Client en Partenaire'),
        ),
        PopupMenuItem<_CustomerAction>(
          value: _CustomerAction.disable,
          child: Text('Désactiver ce client',
              style: GoogleFonts.poppins(fontSize: 13, color: kDangerText)),
        ),
      ],
      child: const SizedBox(
        width: 32,
        height: 32,
        child: Icon(Icons.more_horiz_rounded, size: 20, color: kNavy600),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Fiche latérale

  Widget _buildSheet(EntityModel customer) {
    final String siret = customer.siret ?? '';
    final String editLabel = switch (neoCurrentIndex) {
      1 => customer.address != null ? 'Modifier l\'adresse' : 'Ajouter l\'adresse',
      2 => customer.bankInformations != null ? 'Modifier' : 'Ajouter',
      _ => 'Modifier',
    };
    final VoidCallback onEdit = switch (neoCurrentIndex) {
      1 => () => _editAddress(customer),
      2 => () => _editBank(customer),
      _ => () => _genUpdate(customer),
    };
    final ButtonStyle compact = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(0, 40)),
      padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 12)),
      textStyle: WidgetStatePropertyAll(
          GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
    );

    return Semantics(
      container: true,
      label: 'Fiche client',
      child: ArcCard(
        padding: const EdgeInsets.all(22),
        shadow: ArcCard.raised,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ArcAvatar(customer.name ?? '', size: 48, dark: true),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        customer.name ?? '',
                        style: ArcText.dialogTitle()
                            .copyWith(fontSize: 20, height: 1.15),
                      ),
                      if (siret.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text('SIRET $siret',
                            style: ArcText.dataSmall(color: kText3)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ArcIconAction(
                  icon: Icons.edit_outlined,
                  tooltip: 'Modifier le client',
                  onPressed: () => _genUpdate(customer),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ArcSegmented<int>(
              segments: const [
                ArcSegment(0, 'Général'),
                ArcSegment(1, 'Adresse'),
                ArcSegment(2, 'Banque'),
              ],
              selected: neoCurrentIndex,
              onChanged: _setNeoInitialIndex,
              expand: true,
            ),
            const SizedBox(height: 12),
            switch (neoCurrentIndex) {
              1 => _addressDetails(customer),
              2 => _bankDetails(customer),
              _ => _generalDetails(customer),
            },
            const SizedBox(height: 12),
            const Divider(color: kNavy100),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(
                child: ElevatedButton(
                  style: compact,
                  onPressed: () => _addOrder(customer.id!, customer.name!),
                  child: const Text('Nouvelle commande'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  style: compact,
                  onPressed: onEdit,
                  child: Text(editLabel),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _generalDetails(EntityModel customer) {
    return ArcDefinitionList([
      ('Email', _value(customer.email)),
      ('Téléphone', _value(customer.phone, mono: true)),
      ('SIRET', _value(customer.siret, mono: true)),
      if ((customer.code ?? '').trim().isNotEmpty)
        ('Code', _value(customer.code, mono: true)),
    ]);
  }

  Widget _addressDetails(EntityModel customer) {
    final address = customer.address;
    if (address == null) {
      return const _SheetEmpty('Aucune adresse enregistrée pour le moment');
    }
    return ArcDefinitionList([
      ('Rue', _value(address.street)),
      ('Code postal', _value(address.zip, mono: true)),
      ('Ville', _value(address.city)),
      ('Pays', _value(address.country)),
      if (address.lat != null) ('Latitude', _value('${address.lat}', mono: true)),
      if (address.lng != null) ('Longitude', _value('${address.lng}', mono: true)),
    ]);
  }

  Widget _bankDetails(EntityModel customer) {
    final bank = customer.bankInformations;
    if (bank == null) {
      return const _SheetEmpty(
          'Aucune information bancaire enregistrée pour le moment');
    }
    return ArcDefinitionList([
      if ((bank.iban ?? '').isNotEmpty)
        ('IBAN', _value(_groupBy4(bank.iban!), mono: true)),
      if ((bank.bic ?? '').isNotEmpty) ('BIC', _value(bank.bic, mono: true)),
      ('N° comptabilité', _value(bank.accountingNumber, mono: true)),
      ('N° TVA intracom.', _value(bank.intraCommunityVat, mono: true)),
    ]);
  }

  /// Valeur de la fiche ; « Non renseigné » en gris si elle est absente.
  Widget _value(String? value, {bool mono = false}) {
    if (value == null || value.trim().isEmpty || value == 'null') {
      return Text('Non renseigné', style: ArcText.small(color: kText3));
    }
    return SelectableText(value, style: mono ? ArcText.data() : null);
  }
}

/// IBAN groupé par 4 caractères.
String _groupBy4(String value) {
  final String raw = value.replaceAll(' ', '');
  final List<String> parts = [];
  for (int i = 0; i < raw.length; i += 4) {
    parts.add(raw.substring(i, i + 4 > raw.length ? raw.length : i + 4));
  }
  return parts.join(' ');
}

/// Message d'onglet vide de la fiche client.
class _SheetEmpty extends StatelessWidget {
  final String message;
  const _SheetEmpty(this.message);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        const Icon(Icons.info_outline_rounded, size: 16, color: kText3),
        const SizedBox(width: 8),
        Expanded(child: Text(message, style: ArcText.small(color: kText3))),
      ]),
    );
  }
}
