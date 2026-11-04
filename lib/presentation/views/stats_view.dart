import 'dart:math' as math;

import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:back_office_tribuneo_v2/domain/models/network_amount_model.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/stats_usecase.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/formatters.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/paged_total.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/arc/arc.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/export_to_csv_button.dart';

/// Rapport du catalogue : index historique (export, source de données) et
/// libellé.
typedef _Report = (int index, String label);

/// Catalogue des rapports, groupé comme dans le menu de gauche.
const List<(String, List<_Report>)> _catalog = [
  (
    'UTILISATEURS',
    [
      (0, 'Comptes utilisateurs'),
      (10, 'Statut des QR codes par client'),
    ]
  ),
  (
    'MONTANTS',
    [
      (1, 'Montant total des partenaires'),
      (2, 'Montant total du réseau'),
      (3, 'Montant total des bons par clients'),
      (5, 'Somme des coupons expirés par client'),
    ]
  ),
  (
    'PARTENAIRES',
    [
      (4, 'Partenaires jamais connectés'),
      (6, 'Partenaires sans transactions'),
      (7, 'Toutes les infos partenaires'),
    ]
  ),
  (
    'CLIENTS ET SUPPORT',
    [
      (8, 'Toutes les infos clients'),
      (9, 'Support technique - commandes'),
    ]
  ),
];

/// Rapports filtrés par période.
const Set<int> _datedReports = {1, 2, 5, 9};

/// Rapports qui affichent un numéro de téléphone (masqué par défaut).
const Set<int> _phoneReports = {0, 4, 6, 7, 8, 10};

const Map<int, String> _descriptions = {
  0: 'Montant de coupon par compte utilisateur',
  1: 'Montant total par partenaire sur la période',
  2: 'Totaux du réseau sur la période',
  3: "Montant des bons et date d'expiration par client",
  4: 'Partenaires qui ne se sont jamais connectés',
  5: 'Coupons expirés et somme non dépensée par client',
  6: 'Partenaires sans transaction',
  7: 'Coordonnées, banque et montant de chaque partenaire',
  8: 'Coordonnées de chaque client',
  9: 'Commandes créées sur la période',
  10: 'QR codes et leur statut, filtrés par client',
};

const double _headingHeight = 44;
const double _rowHeight = 52;
const int _rowsPerPage = 10;

class StatsContentView extends StatefulWidget {
  const StatsContentView({super.key});

  @override
  StatsContentViewState createState() => StatsContentViewState();
}

class StatsContentViewState extends State<StatsContentView> {
  final StatsUseCase _statsUseCase = StatsUseCase();
  final DateFormat dateFormat = DateFormat('dd/MM/yyyy');
  int _selectedButtonIndex = 0;
  DateTime _selectedStartDate = DateTime(2023, 1, 1);
  DateTime _selectedEndDate = DateTime.now();
  bool _isChangingStat = false;

  /// Numéros de téléphone masqués (affichage seulement : l'export CSV reste
  /// complet).
  bool _maskPhones = true;

  /// Pagination des tableaux, affichée dans le pied de carte.
  final PaginatorController _paginator = PaginatorController();

  final TextEditingController _qrLastnameController = TextEditingController();
  final TextEditingController _qrFirstnameController = TextEditingController();
  final TextEditingController _qrEmailController = TextEditingController();
  final TextEditingController _qrMobileController = TextEditingController();

  /// Filtres réellement envoyés à l'API : mis à jour uniquement au clic sur
  /// "Rechercher" (ou validation clavier), pas à chaque frappe.
  String _qrLastname = '';
  String _qrFirstname = '';
  String _qrEmail = '';
  String _qrMobile = '';

  String get _currentFilename {
    switch (_selectedButtonIndex) {
      case 0:
        return 'comptes_utilisateurs.csv';
      case 1:
        return 'montant_total_partenaires.csv';
      case 2:
        return 'montant_total_reseau.csv';
      case 3:
        return 'montant_total_bons_clients.csv';
      case 4:
        return 'partenaires_jamais_connectes.csv';
      case 5:
        return 'somme_coupons_expires.csv';
      case 6:
        return 'partenaires_sans_activite.csv';
      case 7:
        return 'toutes_les_infos_partenaires.csv';
      case 8:
        return 'toutes_les_infos_clients.csv';
      case 9:
        return 'support_technique_commandes.csv';
      case 10:
        return 'liste_qr_code_status.csv';
      default:
        return 'export_stats.csv';
    }
  }

  Future<String?> _getCurrentCsvDownload() async {
    switch (_selectedButtonIndex) {
      case 0:
        return _statsUseCase.getUsersPaginatedCsv();
      case 1:
        return _statsUseCase.getPartnerTotalBalancesCsv(
          _selectedStartDate,
          _selectedEndDate,
        );
      case 2:
        return _statsUseCase.getNetworkTotalAmountsCsv(
          _selectedStartDate,
          _selectedEndDate,
        );
      case 3:
        return _statsUseCase.getVoucherTotalBalancesPerCustomerCsv();
      case 4:
        return _statsUseCase.getPartnerDigitalNeverOpenSessionCsv();
      case 5:
        return _statsUseCase.getSumExpiredVouchersConsumerCsv(
          dateFrom: _selectedStartDate,
          dateTo: _selectedEndDate,
        );
      case 6:
        return _statsUseCase.getDigitalPartnerNoActivityCsv();
      case 7:
        return _statsUseCase.getAllInfosPartnersCsv();
      case 8:
        return _statsUseCase.getAllInfosCustomersCsv();
      case 9:
        return _statsUseCase.getTechnicalSupportOrdersCsv(
          _selectedStartDate,
          _selectedEndDate,
        );
      case 10:
        return _statsUseCase.getAllQrCodeStatusByUserInfosCsv(
          email: _qrEmail,
          firstname: _qrFirstname,
          lastname: _qrLastname,
          mobile: _qrMobile,
        );
      default:
        return null;
    }
  }

  @override
  void dispose() {
    _qrLastnameController.dispose();
    _qrFirstnameController.dispose();
    _qrEmailController.dispose();
    _qrMobileController.dispose();
    _paginator.dispose();
    super.dispose();
  }

  void _selectReport(int index) {
    if (index == _selectedButtonIndex) return;
    setState(() {
      _selectedButtonIndex = index;
      _isChangingStat = true;
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _isChangingStat = false;
        });
      }
    });
  }

  Future<void> _pickStartDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate,
      firstDate: DateTime(2010),
      lastDate: DateTime(3000),
      locale: const Locale('fr', 'FR'),
      fieldHintText: 'Jour/Mois/Annee',
    );
    if (picked != null) {
      setState(() {
        _selectedStartDate = picked;
        if (_selectedStartDate.isAfter(_selectedEndDate)) {
          _selectedEndDate = _selectedStartDate;
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedEndDate,
      firstDate: DateTime(2010),
      lastDate: DateTime(3000),
      locale: const Locale('fr', 'FR'),
      fieldHintText: 'Jour/Mois/Annee',
    );
    if (picked != null) {
      setState(() {
        _selectedEndDate = picked;
        if (_selectedEndDate.isBefore(_selectedStartDate)) {
          _selectedStartDate = _selectedEndDate;
        }
      });
    }
  }

  void _applyQrCodeStatusFilters() {
    setState(() {
      _qrLastname = _qrLastnameController.text.trim();
      _qrFirstname = _qrFirstnameController.text.trim();
      _qrEmail = _qrEmailController.text.trim();
      _qrMobile = _qrMobileController.text.trim();
    });
  }

  void _resetQrCodeStatusFilters() {
    _qrLastnameController.clear();
    _qrFirstnameController.clear();
    _qrEmailController.clear();
    _qrMobileController.clear();
    _applyQrCodeStatusFilters();
  }

  (String, String) get _currentReport {
    for (final (group, reports) in _catalog) {
      for (final (index, label) in reports) {
        if (index == _selectedButtonIndex) return (group, label);
      }
    }
    return ('', '');
  }

  // --- Mise en page ----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ArcPageHeader(eyebrow: 'Analyse', title: 'Statistiques'),
        LayoutBuilder(builder: (context, constraints) {
          final Widget report = _buildReport();
          if (constraints.maxWidth < 860) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [_buildCatalog(), const SizedBox(height: 20), report],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 280, child: _buildCatalog()),
              const SizedBox(width: 20),
              Expanded(child: report),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildCatalog() {
    return Semantics(
      container: true,
      label: 'Rapports',
      child: ArcCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int g = 0; g < _catalog.length; g++) ...[
              if (g > 0) const SizedBox(height: 14),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: Text(_catalog[g].$1,
                    style: ArcText.label(color: kText3)
                        .copyWith(fontSize: 11, letterSpacing: 0.7)),
              ),
              for (final (index, label) in _catalog[g].$2)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: _CatalogItem(
                    label: label,
                    selected: index == _selectedButtonIndex,
                    onTap: () => _selectReport(index),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReport() {
    final (String group, String label) = _currentReport;
    final bool dated = _datedReports.contains(_selectedButtonIndex);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ArcCard(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 16,
            runSpacing: 16,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(group,
                      style: ArcText.label(color: kOrange700)
                          .copyWith(letterSpacing: 0.7)),
                  const SizedBox(height: 4),
                  Text(label,
                      style: ArcText.dialogTitle().copyWith(fontSize: 26)),
                ],
              ),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (dated) _buildPeriod(),
                  ExportToCsvButton(
                    filename: _currentFilename,
                    fetchCsvData: _getCurrentCsvDownload,
                    externalLoading: _isChangingStat,
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_selectedButtonIndex == 10) ...[
          const SizedBox(height: 16),
          _buildQrCodeStatusFilters(),
        ],
        const SizedBox(height: 16),
        _buildSelectedContent(),
      ],
    );
  }

  /// Période « début → fin » : chaque date ouvre son calendrier.
  Widget _buildPeriod() {
    Widget date(String tooltip, DateTime value, VoidCallback onTap) => Tooltip(
          message: tooltip,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Text(dateFormat.format(value),
                  semanticsLabel: '$tooltip : ${dateFormat.format(value)}',
                  style: ArcText.data().copyWith(fontSize: 12)),
            ),
          ),
        );
    return Container(
      height: kControlHeight,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(kRadiusSm),
        border: Border.all(color: kBorderStrong, width: 1.5),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.calendar_today_rounded, size: 18, color: kNavy600),
        const SizedBox(width: 6),
        date('Date de début', _selectedStartDate, _pickStartDate),
        Text('→', style: ArcText.data(color: kText3)),
        date('Date de fin', _selectedEndDate, _pickEndDate),
      ]),
    );
  }

  Widget _buildQrCodeStatusSearchField(
      TextEditingController controller, String label) {
    return SizedBox(
      width: 200,
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _applyQrCodeStatusFilters(),
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  Widget _buildQrCodeStatusFilters() {
    return ArcCard(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: [
          _buildQrCodeStatusSearchField(_qrLastnameController, 'Nom'),
          _buildQrCodeStatusSearchField(_qrFirstnameController, 'Prénom'),
          _buildQrCodeStatusSearchField(_qrEmailController, 'Email'),
          _buildQrCodeStatusSearchField(_qrMobileController, 'Mobile'),
          ElevatedButton.icon(
            onPressed: _applyQrCodeStatusFilters,
            icon: const Icon(Icons.search_rounded, size: 18),
            label: const Text('Rechercher'),
          ),
          TextButton(
            onPressed: _resetQrCodeStatusFilters,
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );
  }

  /// Barre d'outils du tableau : description du rapport et bouton
  /// Afficher/Masquer les numéros quand le rapport en contient.
  Widget _toolbar() {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        Text(_descriptions[_selectedButtonIndex] ?? '',
            style: ArcText.body(color: kText2).copyWith(fontSize: 13)),
        if (_phoneReports.contains(_selectedButtonIndex))
          OutlinedButton.icon(
            onPressed: () => setState(() => _maskPhones = !_maskPhones),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 34),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              side: const BorderSide(color: kBorder, width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              textStyle: ArcText.small().copyWith(fontWeight: FontWeight.w600),
            ),
            icon: Icon(
                _maskPhones
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 16),
            label: Text(
                _maskPhones ? 'Afficher les numéros' : 'Masquer les numéros'),
          ),
      ],
    );
  }

  /// Pied de carte : « 1–10 sur 937 ‹ › », piloté par [_paginator].
  Widget _pagination() {
    return ListenableBuilder(
      listenable: _paginator,
      builder: (context, _) {
        if (!_paginator.isAttached) {
          return const ArcPagination(label: '');
        }
        final int count = _paginator.rowCount;
        final int start = _paginator.currentRowIndex;
        final int end = math.min(start + _paginator.rowsPerPage, count);
        return ArcPagination(
          label: count == 0 ? 'Aucun résultat' : '${start + 1}–$end sur $count',
          onPrevious: start > 0 ? _paginator.goToPreviousPage : null,
          onNext: end < count ? _paginator.goToNextPage : null,
        );
      },
    );
  }

  /// Tableau paginé du rapport courant, dans sa carte.
  Widget _pagedTable({
    required AsyncDataTableSource source,
    required List<DataColumn> columns,
    double? minWidth,
  }) {
    return ArcTableCard(
      toolbar: _toolbar(),
      footer: _pagination(),
      child: SizedBox(
        height: _headingHeight + _rowsPerPage * _rowHeight + 2,
        child: SelectionArea(
          child: AsyncPaginatedDataTable2(
            // Changer de rapport repart de la première page.
            key: ValueKey(_selectedButtonIndex),
            controller: _paginator,
            hidePaginator: true,
            wrapInCard: false,
            source: source,
            columns: columns,
            minWidth: minWidth,
            rowsPerPage: _rowsPerPage,
            headingRowHeight: _headingHeight,
            dataRowHeight: _rowHeight,
            columnSpacing: 20,
            horizontalMargin: 20,
            empty: Center(
              child: Text('Aucune donnée pour ce rapport.',
                  style: ArcText.small(color: kText3)),
            ),
            errorBuilder: (error) => Center(
              child: Wrap(
                spacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('Impossible de charger ce rapport.',
                      style: ArcText.small(color: kDangerText)),
                  TextButton.icon(
                    onPressed: source.refreshDatasource,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedContent() {
    switch (_selectedButtonIndex) {
      case 0:
        return _buildUsersContent();
      case 1:
        return _buildPartnerTotalBalanceContent();
      case 2:
        return _buildNetworkTotalAmount();
      case 3:
        return _buildVoucherTotalBalancePerCustomer();
      case 4:
        return _buildPartnerDigitalNeverOpenSession();
      case 5:
        return _buildSumExpiredVouchersConsumer();
      case 6:
        return _buildDigitalPartnerNoActivity();
      case 7:
        return _buildAllInfosPartners();
      case 8:
        return _buildAllInfosCustomers();
      case 9:
        return _buildTechnicalSupportOrders();
      case 10:
        return _buildQrCodeStatusByUserInfos();
      default:
        return Container();
    }
  }

  // --- Rapports ----------------------------------------------------------------

  Widget _buildPartnerTotalBalanceContent() {
    return _pagedTable(
      source: PartnerTotalDataSource(
        _statsUseCase,
        _selectedStartDate,
        _selectedEndDate,
      ),
      columns: const [
        DataColumn2(label: Text('Nom'), size: ColumnSize.L),
        DataColumn2(label: Text('Montant total'), numeric: true),
      ],
    );
  }

  Widget _buildUsersContent() {
    return _pagedTable(
      source: UsersDataSource(_statsUseCase, maskPhones: _maskPhones),
      columns: const [
        DataColumn2(label: Text('Téléphone'), size: ColumnSize.M),
        DataColumn2(label: Text('Initiales'), fixedWidth: 100),
        DataColumn2(label: Text('Montant coupon'), size: ColumnSize.L),
        DataColumn2(label: Text('€'), numeric: true, size: ColumnSize.S),
      ],
    );
  }

  Widget _buildNetworkTotalAmount() {
    return FutureBuilder<List<NetworkTotalAmountModel>>(
      future: StatsUseCase()
          .getNetworkTotalAmounts(_selectedStartDate, _selectedEndDate),
      builder: (context, snapshot) {
        final Widget child;
        if (snapshot.connectionState == ConnectionState.waiting) {
          child = const SizedBox(
              height: 160, child: Center(child: CircularProgressIndicator()));
        } else if (snapshot.hasError) {
          child = Padding(
            padding: const EdgeInsets.all(20),
            child: Text('Erreur : ${snapshot.error}',
                style: ArcText.small(color: kDangerText)),
          );
        } else {
          final data = snapshot.data ?? [];
          final int rowCount = data.isEmpty ? 1 : data.length;
          child = SizedBox(
            height: _headingHeight + rowCount * _rowHeight + 2,
            child: SelectionArea(
              child: DataTable2(
                headingRowHeight: _headingHeight,
                dataRowHeight: _rowHeight,
                columnSpacing: 20,
                horizontalMargin: 20,
                empty: Center(
                  child: Text('Aucune donnée pour cette période.',
                      style: ArcText.small(color: kText3)),
                ),
                columns: [
                  const DataColumn2(
                      label: Text('Frais de gestion'), numeric: true),
                  const DataColumn2(
                      label: Text('Total injecté'), numeric: true),
                  DataColumn2(
                    numeric: true,
                    label: Tooltip(
                      message: "Reste des bons dont la date d'expiration est "
                          'comprise dans la période choisie.',
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Gain expiré total'),
                          SizedBox(width: 4),
                          Icon(Icons.info_outline_rounded,
                              size: 16, color: kNavy600),
                        ],
                      ),
                    ),
                  ),
                ],
                rows: data.map((item) {
                  final double expiredGain =
                      double.tryParse(item.expiredGainTotal) ?? 0.0;
                  return DataRow(
                    cells: [
                      _amountCell(formatEuro(item.managementFees)),
                      _amountCell(formatEuro(item.injectedTotalAmount)),
                      _amountCell(formatEuro(expiredGain)),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        }
        return ArcTableCard(toolbar: _toolbar(), child: child);
      },
    );
  }

  Widget _buildVoucherTotalBalancePerCustomer() {
    return _pagedTable(
      source: VoucherTotalBalancePerCustomerDataSource(_statsUseCase),
      columns: const [
        DataColumn2(label: Text('Nom'), size: ColumnSize.L),
        DataColumn2(label: Text('Montant'), numeric: true),
        DataColumn2(label: Text("Date d'expiration")),
      ],
    );
  }

  Widget _buildPartnerDigitalNeverOpenSession() {
    return _pagedTable(
      source: PartnerDigitalNeverOpenSessionDataSource(_statsUseCase,
          maskPhones: _maskPhones),
      columns: const [
        DataColumn2(label: Text('Nom'), size: ColumnSize.L),
        DataColumn2(label: Text('Email'), size: ColumnSize.L),
        DataColumn2(label: Text('Téléphone')),
        DataColumn2(label: Text('Avec QR Code'), size: ColumnSize.S),
      ],
    );
  }

  Widget _buildSumExpiredVouchersConsumer() {
    return _pagedTable(
      source: SumExpiredVouchersConsumerDataSource(
        _statsUseCase,
        _selectedStartDate,
        _selectedEndDate,
      ),
      columns: const [
        DataColumn2(label: Text('Nom'), size: ColumnSize.L),
        DataColumn2(label: Text('Nombre de coupons'), numeric: true),
        DataColumn2(label: Text('Somme non dépensée'), numeric: true),
      ],
    );
  }

  Widget _buildDigitalPartnerNoActivity() {
    return _pagedTable(
      source: DigitalPartnerNoActivityDataSource(_statsUseCase,
          maskPhones: _maskPhones),
      columns: const [
        DataColumn2(label: Text('Nom'), size: ColumnSize.L),
        DataColumn2(label: Text('ID'), size: ColumnSize.S),
        DataColumn2(label: Text('Email'), size: ColumnSize.L),
        DataColumn2(label: Text('Téléphone')),
      ],
    );
  }

  Widget _buildAllInfosPartners() {
    return _pagedTable(
      source: ListAllPartnersDataSource(_statsUseCase, maskPhones: _maskPhones),
      minWidth: 2200,
      columns: const [
        DataColumn2(label: Text('Code')),
        DataColumn2(label: Text('Nom'), size: ColumnSize.L),
        DataColumn2(label: Text('Email'), size: ColumnSize.L),
        DataColumn2(label: Text('Siret')),
        DataColumn2(label: Text('Téléphone')),
        DataColumn2(label: Text('Accepte démat.'), size: ColumnSize.S),
        DataColumn2(label: Text('Adresse'), size: ColumnSize.L),
        DataColumn2(label: Text('Code postal'), size: ColumnSize.S),
        DataColumn2(label: Text('Ville')),
        DataColumn2(label: Text('Pays'), size: ColumnSize.S),
        DataColumn2(label: Text('IBAN'), size: ColumnSize.L),
        DataColumn2(label: Text('BIC')),
        DataColumn2(label: Text('N° TVA intracommunautaire')),
        DataColumn2(label: Text('Code NAF'), size: ColumnSize.S),
        DataColumn2(label: Text('N° comptable')),
        DataColumn2(label: Text('Montant'), numeric: true),
      ],
    );
  }

  Widget _buildAllInfosCustomers() {
    return _pagedTable(
      source:
          ListAllCustomersDataSource(_statsUseCase, maskPhones: _maskPhones),
      minWidth: 1700,
      columns: const [
        DataColumn2(label: Text('Code')),
        DataColumn2(label: Text('Nom'), size: ColumnSize.L),
        DataColumn2(label: Text('Email'), size: ColumnSize.L),
        DataColumn2(label: Text('Siret')),
        DataColumn2(label: Text('Téléphone')),
        DataColumn2(label: Text('Adresse'), size: ColumnSize.L),
        DataColumn2(label: Text('Code postal'), size: ColumnSize.S),
        DataColumn2(label: Text('Ville')),
        DataColumn2(label: Text('Pays'), size: ColumnSize.S),
        DataColumn2(label: Text('N° TVA intracommunautaire')),
        DataColumn2(label: Text('Code NAF'), size: ColumnSize.S),
        DataColumn2(label: Text('N° comptable')),
      ],
    );
  }

  Widget _buildTechnicalSupportOrders() {
    return _pagedTable(
      source: GetInfoTechnicalSupportDataSource(
        _statsUseCase,
        _selectedStartDate,
        _selectedEndDate,
      ),
      columns: const [
        DataColumn2(label: Text('N° de commande')),
        DataColumn2(label: Text('Nom'), size: ColumnSize.L),
        DataColumn2(label: Text('Montant total'), numeric: true),
        DataColumn2(label: Text('Nombre de QR codes'), numeric: true),
        DataColumn2(label: Text('Date de création')),
      ],
    );
  }

  Widget _buildQrCodeStatusByUserInfos() {
    return _pagedTable(
      source: QrCodeStatusByUserInfosDataSource(
        _statsUseCase,
        email: _qrEmail,
        firstname: _qrFirstname,
        lastname: _qrLastname,
        mobile: _qrMobile,
        maskPhones: _maskPhones,
      ),
      minWidth: 1800,
      columns: const [
        DataColumn2(label: Text('Identifiant')),
        DataColumn2(label: Text('N° de commande')),
        DataColumn2(label: Text('Montant'), numeric: true),
        DataColumn2(label: Text('Montant restant'), numeric: true),
        DataColumn2(label: Text('Donation'), size: ColumnSize.S),
        DataColumn2(label: Text("Date d'expiration")),
        DataColumn2(label: Text('Email'), size: ColumnSize.L),
        DataColumn2(label: Text('Prénom')),
        DataColumn2(label: Text('Nom')),
        DataColumn2(label: Text('Mobile')),
      ],
    );
  }
}

/// Entrée du catalogue des rapports.
class _CatalogItem extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _CatalogItem(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? kNavy900 : Colors.transparent,
        borderRadius: BorderRadius.circular(kRadiusSm),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(kRadiusSm),
          hoverColor: selected ? Colors.transparent : kNavy50,
          child: Container(
            constraints: const BoxConstraints(minHeight: 40),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                    color: selected ? kOrange : kNavy200,
                    shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label,
                    style:
                        ArcText.body(color: selected ? Colors.white : kNavy700)
                            .copyWith(
                                fontSize: 13,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.w500)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// --- Cellules ------------------------------------------------------------------

DataCell _textCell(String? value) => DataCell(Text(value ?? ''));

/// Identifiants, codes, IBAN, SIRET : chiffres à chasse fixe.
DataCell _monoCell(String? value) =>
    DataCell(Text(value ?? '', style: ArcText.data()));

DataCell _amountCell(String value) =>
    DataCell(Text(value, style: ArcText.data(fontWeight: FontWeight.w500)));

DataCell _phoneCell(String? value, bool masked) =>
    DataCell(Text(displayPhone(value, masked: masked), style: ArcText.data()));

/// Montant reçu en texte : formaté en euros s'il est lisible, tel quel sinon.
/// Absent : vide, ou `0,00 €` si [zeroIfMissing].
String _euroText(String? raw, {bool zeroIfMissing = false}) {
  final String text = raw?.trim() ?? '';
  if (text.isEmpty) return zeroIfMissing ? formatEuro(0) : '';
  final num? value = num.tryParse(text);
  return value == null ? text : formatEuro(value);
}

/// Date de l'API au format `13/10/2026` (texte brut s'il est illisible).
String _frenchDate(String? value) {
  if (value == null || value.isEmpty) return '';
  final String formatted = formatFrenchDate(value);
  return formatted.isEmpty ? value : formatted;
}

/// Date et heure de l'API : `13/10/2026 14:05` (texte brut s'il est illisible).
String _frenchDateTime(String? value) {
  final DateTime? parsed = DateTime.tryParse(value?.trim() ?? '');
  if (parsed == null) return value ?? '';
  final bool hasTime = parsed.hour != 0 || parsed.minute != 0;
  return DateFormat(hasTime ? 'dd/MM/yyyy HH:mm' : 'dd/MM/yyyy').format(parsed);
}

/// Numéro de téléphone regroupé par paires (`+33 6 49 12 87 95`) et, si
/// [masked], les quatre chiffres précédant les deux derniers remplacés par
/// des points (`+33 6 49 •• •• 95`).
String displayPhone(String? raw, {required bool masked}) {
  final String value = (raw ?? '').trim();
  if (value.isEmpty) return '';
  final String compact = value.replaceAll(RegExp(r'[\s.\-]'), '');
  String grouped = value;
  final RegExpMatch? international =
      RegExp(r'^\+33(\d)(\d{2})(\d{2})(\d{2})(\d{2})$').firstMatch(compact);
  final RegExpMatch? national =
      RegExp(r'^0(\d)(\d{2})(\d{2})(\d{2})(\d{2})$').firstMatch(compact);
  if (international != null) {
    grouped = '+33 ${international[1]} ${international[2]} '
        '${international[3]} ${international[4]} ${international[5]}';
  } else if (national != null) {
    grouped = '0${national[1]} ${national[2]} ${national[3]} '
        '${national[4]} ${national[5]}';
  }
  if (!masked) return grouped;

  final List<String> chars = grouped.split('');
  final List<int> digits = [
    for (int i = 0; i < chars.length; i++)
      if (RegExp(r'\d').hasMatch(chars[i])) i,
  ];
  if (digits.length <= 2) return grouped;
  for (final int i
      in digits.sublist(math.max(0, digits.length - 6), digits.length - 2)) {
    chars[i] = '•';
  }
  return chars.join();
}

// --- Sources de données ----------------------------------------------------------

class PartnerTotalDataSource extends AsyncDataTableSource {
  final StatsUseCase _statsUseCase;
  final DateTime? _dateFrom;
  final DateTime? _dateTo;
  int _lastKnownTotal = 0;

  PartnerTotalDataSource(this._statsUseCase, this._dateFrom, this._dateTo);

  @override
  Future<AsyncRowsResponse> getRows(int startIndex, int limit) async {
    final int apiOffset = startIndex;
    final paginated = await _statsUseCase.getPartnerTotalBalancesPaginated(
      _dateFrom,
      _dateTo,
      limit: limit,
      offset: apiOffset,
    );

    final data = paginated.items;
    final List<DataRow> rows = [
      for (final item in data)
        DataRow(cells: [
          _textCell(item.name),
          _amountCell(formatEuro(item.totalAmount)),
        ]),
    ];

    _lastKnownTotal = resolvePagedTotal(
        apiTotal: paginated.total,
        startIndex: startIndex,
        received: data.length,
        limit: limit);

    return AsyncRowsResponse(_lastKnownTotal, rows);
  }
}

class UsersDataSource extends AsyncDataTableSource {
  final StatsUseCase _statsUseCase;
  final bool maskPhones;
  int _lastKnownTotal = 0;

  UsersDataSource(this._statsUseCase, {this.maskPhones = false});

  @override
  Future<AsyncRowsResponse> getRows(int startIndex, int limit) async {
    final int apiOffset = startIndex;
    final paginated = await _statsUseCase.getUsersPaginated(
      limit: limit,
      offset: apiOffset,
    );

    final users = paginated.items;
    // Barre de valeur relative au plus gros montant de la page.
    final num pageMax =
        users.fold<num>(0, (max, user) => math.max(max, user.amount ?? 0));
    final List<DataRow> rows = [
      for (final user in users)
        DataRow(cells: [
          _phoneCell(user.mobile, maskPhones),
          DataCell(_Initials(user.initials ?? '')),
          DataCell(_ValueBar(
              ratio: pageMax > 0 ? (user.amount ?? 0) / pageMax : 0,
              highlight: pageMax > 0 && (user.amount ?? 0) == pageMax)),
          _amountCell(_formatAmountFixed(user.amount)),
        ]),
    ];

    _lastKnownTotal = resolvePagedTotal(
        apiTotal: paginated.total,
        startIndex: startIndex,
        received: users.length,
        limit: limit);

    return AsyncRowsResponse(_lastKnownTotal, rows);
  }
}

/// `2 300,00` : montant à deux décimales, sans symbole (colonne « € »).
String _formatAmountFixed(num? amount) =>
    NumberFormat('#,##0.00', 'fr_FR').format(amount ?? 0);

class VoucherTotalBalancePerCustomerDataSource extends AsyncDataTableSource {
  final StatsUseCase _statsUseCase;
  int _lastKnownTotal = 0;

  VoucherTotalBalancePerCustomerDataSource(this._statsUseCase);

  @override
  Future<AsyncRowsResponse> getRows(int startIndex, int limit) async {
    final int apiOffset = startIndex;
    final paginated =
        await _statsUseCase.getVoucherTotalBalancesPerCustomerPaginated(
      limit: limit,
      offset: apiOffset,
    );

    final vouchers = paginated.items;
    final List<DataRow> rows = [
      for (final item in vouchers)
        DataRow(cells: [
          _textCell(item.name),
          _amountCell(_euroText(item.amount, zeroIfMissing: true)),
          _monoCell(_frenchDate(item.expirationDate)),
        ]),
    ];

    _lastKnownTotal = resolvePagedTotal(
        apiTotal: paginated.total,
        startIndex: startIndex,
        received: vouchers.length,
        limit: limit);

    return AsyncRowsResponse(_lastKnownTotal, rows);
  }
}

class PartnerDigitalNeverOpenSessionDataSource extends AsyncDataTableSource {
  final StatsUseCase _statsUseCase;
  final bool maskPhones;
  int _lastKnownTotal = 0;

  PartnerDigitalNeverOpenSessionDataSource(this._statsUseCase,
      {this.maskPhones = false});

  @override
  Future<AsyncRowsResponse> getRows(int startIndex, int limit) async {
    final int apiOffset = startIndex;
    final paginated =
        await _statsUseCase.getPartnerDigitalNeverOpenSessionPaginated(
      limit: limit,
      offset: apiOffset,
    );

    final partners = paginated.items;
    final List<DataRow> rows = [
      for (final item in partners)
        DataRow(cells: [
          _textCell(item.name),
          _textCell(item.email),
          _phoneCell(item.phone, maskPhones),
          _textCell(item.withQrCode),
        ]),
    ];

    _lastKnownTotal = resolvePagedTotal(
        apiTotal: paginated.total,
        startIndex: startIndex,
        received: partners.length,
        limit: limit);

    return AsyncRowsResponse(_lastKnownTotal, rows);
  }
}

class SumExpiredVouchersConsumerDataSource extends AsyncDataTableSource {
  final StatsUseCase _statsUseCase;
  final DateTime? _dateFrom;
  final DateTime? _dateTo;
  int _lastKnownTotal = 0;

  SumExpiredVouchersConsumerDataSource(
      this._statsUseCase, this._dateFrom, this._dateTo);

  @override
  Future<AsyncRowsResponse> getRows(int startIndex, int limit) async {
    final int apiOffset = startIndex;
    final paginated =
        await _statsUseCase.getSumExpiredVouchersConsumerPaginated(
      dateFrom: _dateFrom,
      dateTo: _dateTo,
      limit: limit,
      offset: apiOffset,
    );

    final items = paginated.items;
    final List<DataRow> rows = [
      for (final item in items)
        DataRow(cells: [
          _textCell(item.name),
          _amountCell(item.expiredVouchers?.toString() ?? '0'),
          _amountCell(_euroText(item.unredeemendAmount, zeroIfMissing: true)),
        ]),
    ];

    _lastKnownTotal = resolvePagedTotal(
        apiTotal: paginated.total,
        startIndex: startIndex,
        received: items.length,
        limit: limit);

    return AsyncRowsResponse(_lastKnownTotal, rows);
  }
}

class DigitalPartnerNoActivityDataSource extends AsyncDataTableSource {
  final StatsUseCase _statsUseCase;
  final bool maskPhones;
  int _lastKnownTotal = 0;

  DigitalPartnerNoActivityDataSource(this._statsUseCase,
      {this.maskPhones = false});

  @override
  Future<AsyncRowsResponse> getRows(int startIndex, int limit) async {
    final int apiOffset = startIndex;
    final paginated = await _statsUseCase.getDigitalPartnerNoActivityPaginated(
      limit: limit,
      offset: apiOffset,
    );

    final partners = paginated.items;
    final List<DataRow> rows = [
      for (final item in partners)
        DataRow(cells: [
          _textCell(item.name),
          _monoCell(item.id?.toString()),
          _textCell(item.email),
          _phoneCell(item.phone, maskPhones),
        ]),
    ];

    _lastKnownTotal = resolvePagedTotal(
        apiTotal: paginated.total,
        startIndex: startIndex,
        received: partners.length,
        limit: limit);

    return AsyncRowsResponse(_lastKnownTotal, rows);
  }
}

class ListAllPartnersDataSource extends AsyncDataTableSource {
  final StatsUseCase _statsUseCase;
  final bool maskPhones;
  int _lastKnownTotal = 0;

  ListAllPartnersDataSource(this._statsUseCase, {this.maskPhones = false});

  @override
  Future<AsyncRowsResponse> getRows(int startIndex, int limit) async {
    final int apiOffset = startIndex;
    final paginated = await _statsUseCase.getAllInfosPartnersPaginated(
      limit: limit,
      offset: apiOffset,
    );

    final partners = paginated.items;
    final List<DataRow> rows = [
      for (final item in partners)
        DataRow(cells: [
          _monoCell(item.code),
          _textCell(item.name),
          _textCell(item.email),
          _monoCell(item.siret),
          _phoneCell(item.phone, maskPhones),
          _textCell(item.acceptDemat),
          _textCell(item.street),
          _monoCell(item.zip),
          _textCell(item.city),
          _textCell(item.country),
          _monoCell(item.iban),
          _monoCell(item.bic),
          _monoCell(item.intracommunityVatNumber),
          _monoCell(item.nafCode),
          _monoCell(item.accountingNumber),
          _amountCell(_euroText(item.amount)),
        ]),
    ];

    _lastKnownTotal = resolvePagedTotal(
        apiTotal: paginated.total,
        startIndex: startIndex,
        received: partners.length,
        limit: limit);

    return AsyncRowsResponse(_lastKnownTotal, rows);
  }
}

class ListAllCustomersDataSource extends AsyncDataTableSource {
  final StatsUseCase _statsUseCase;
  final bool maskPhones;
  int _lastKnownTotal = 0;

  ListAllCustomersDataSource(this._statsUseCase, {this.maskPhones = false});

  @override
  Future<AsyncRowsResponse> getRows(int startIndex, int limit) async {
    final int apiOffset = startIndex;
    final paginated = await _statsUseCase.getAllInfosCustomersPaginated(
      limit: limit,
      offset: apiOffset,
    );

    final customers = paginated.items;
    final List<DataRow> rows = [
      for (final item in customers)
        DataRow(cells: [
          _monoCell(item.code),
          _textCell(item.name),
          _textCell(item.email),
          _monoCell(item.siret),
          _phoneCell(item.phone, maskPhones),
          _textCell(item.street),
          _monoCell(item.zip),
          _textCell(item.city),
          _textCell(item.country),
          _monoCell(item.intracommunityVatNumber),
          _monoCell(item.nafCode),
          _monoCell(item.accountingNumber),
        ]),
    ];

    _lastKnownTotal = resolvePagedTotal(
        apiTotal: paginated.total,
        startIndex: startIndex,
        received: customers.length,
        limit: limit);

    return AsyncRowsResponse(_lastKnownTotal, rows);
  }
}

class GetInfoTechnicalSupportDataSource extends AsyncDataTableSource {
  final StatsUseCase _statsUseCase;
  final DateTime? _dateFrom;
  final DateTime? _dateTo;
  int _lastKnownTotal = 0;

  GetInfoTechnicalSupportDataSource(
      this._statsUseCase, this._dateFrom, this._dateTo);

  @override
  Future<AsyncRowsResponse> getRows(int startIndex, int limit) async {
    final int apiOffset = startIndex;
    final paginated = await _statsUseCase.getTechnicalSupportOrdersPaginated(
      _dateFrom,
      _dateTo,
      limit: limit,
      offset: apiOffset,
    );

    final orders = paginated.items;
    final List<DataRow> rows = [
      for (final item in orders)
        DataRow(cells: [
          _monoCell(item.orderNumber),
          _textCell(item.name),
          _amountCell(_euroText(item.totalByOrder, zeroIfMissing: true)),
          _amountCell(item.countQrcode?.toString() ?? '0'),
          _monoCell(_frenchDateTime(item.createdDate)),
        ]),
    ];

    _lastKnownTotal = resolvePagedTotal(
        apiTotal: paginated.total,
        startIndex: startIndex,
        received: orders.length,
        limit: limit);

    return AsyncRowsResponse(_lastKnownTotal, rows);
  }
}

class QrCodeStatusByUserInfosDataSource extends AsyncDataTableSource {
  final StatsUseCase _statsUseCase;
  final String _email;
  final String _firstname;
  final String _lastname;
  final String _mobile;
  final bool maskPhones;
  int _lastKnownTotal = 0;

  QrCodeStatusByUserInfosDataSource(
    this._statsUseCase, {
    String email = '',
    String firstname = '',
    String lastname = '',
    String mobile = '',
    this.maskPhones = false,
  })  : _email = email,
        _firstname = firstname,
        _lastname = lastname,
        _mobile = mobile;

  @override
  Future<AsyncRowsResponse> getRows(int startIndex, int limit) async {
    final int apiOffset = startIndex;
    final paginated =
        await _statsUseCase.getAllQrCodeStatusByUserInfosPaginated(
      email: _email,
      firstname: _firstname,
      lastname: _lastname,
      mobile: _mobile,
      limit: limit,
      offset: apiOffset,
    );

    final qrCodes = paginated.items;
    final List<DataRow> rows = [
      for (final item in qrCodes)
        DataRow(cells: [
          _monoCell(item.qrCodeIdentifier),
          _monoCell(item.orderNumber),
          _amountCell(formatEuro(item.amount)),
          _amountCell(formatEuro(item.remainingAmount)),
          DataCell(item.isDonation
              ? const ArcPill('Oui', tone: ArcTone.info)
              : Text('Non', style: ArcText.small(color: kText3))),
          _monoCell(_frenchDate(item.expiryDate)),
          _textCell(item.email),
          _textCell(item.firstname),
          _textCell(item.lastname),
          _phoneCell(item.mobile, maskPhones),
        ]),
    ];

    _lastKnownTotal = resolvePagedTotal(
        apiTotal: paginated.total,
        startIndex: startIndex,
        received: qrCodes.length,
        limit: limit);

    return AsyncRowsResponse(_lastKnownTotal, rows);
  }
}

/// Carré d'initiales du rapport « Comptes utilisateurs ».
class _Initials extends StatelessWidget {
  final String initials;
  const _Initials(this.initials);

  @override
  Widget build(BuildContext context) {
    if (initials.isEmpty) return const SizedBox.shrink();
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
          color: kNavy100, borderRadius: BorderRadius.circular(9)),
      child: Text(initials,
          style: ArcText.dialogTitle(color: kNavy600).copyWith(fontSize: 12)),
    );
  }
}

/// Barre de valeur (proportion du plus gros montant de la page).
class _ValueBar extends StatelessWidget {
  final double ratio;
  final bool highlight;
  const _ValueBar({required this.ratio, required this.highlight});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 8,
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
          color: kNavy50, borderRadius: BorderRadius.circular(999)),
      child: FractionallySizedBox(
        widthFactor: ratio.clamp(0.02, 1.0),
        child: Container(
          decoration: BoxDecoration(
              color: highlight ? kOrange : kNavy400,
              borderRadius: BorderRadius.circular(999)),
        ),
      ),
    );
  }
}
