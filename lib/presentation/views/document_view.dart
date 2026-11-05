import 'dart:async';

import 'package:flutter/material.dart';
import 'package:back_office_tribuneo_v2/core/notifiers/screen_open_requests.dart';

import 'package:back_office_tribuneo_v2/domain/models/invoice_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/paginated_result.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/document_usecase.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/_global.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/file_downloader.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/formatters.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/invoice_download.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/local_search.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/arc/arc.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/hold_refund_dialog.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/loading.dart';

/// Documents : factures des commandes et factures de frais de gestion, page par
/// page (10 par page). Chaque onglet garde sa page.
class DocumentsContentView extends StatefulWidget {
  const DocumentsContentView({Key? key}) : super(key: key);

  @override
  State<DocumentsContentView> createState() => _DocumentsContentViewState();
}

class _DocumentsContentViewState extends State<DocumentsContentView> {
  static const int _pageSize = 10;

  final DocumentUseCase _documentUseCase = DocumentUseCase();
  int _selectedButtonIndex = 0;

  /// Onglet 0 : factures (`order`), onglet 1 : frais de gestion (`fees`).
  final List<_InvoicePage> _pages = [
    _InvoicePage('order'),
    _InvoicePage('fees'),
  ];

  ScreenOpenRequests? _openRequests;

  // Recherche : l'API ne filtre pas, tous les documents de l'onglet sont
  // chargés à la première recherche puis filtrés ici (10 par page).
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _query = '';
  int _searchOffset = 0;

  bool get _searching => _query.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _openRequests = ScreenOpenRequests.maybeOf(context)
      ?..addListener(_handleOpenRequest);
    _handleOpenRequest();
    _selectTab(_selectedButtonIndex);
  }

  @override
  void dispose() {
    _openRequests?.removeListener(_handleOpenRequest);
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Deep-link de l'assistant : onglet « Factures ».
  void _handleOpenRequest() {
    if (_openRequests?.take(const {'invoices'}) == null || !mounted) return;
    _selectTab(0);
  }

  void _selectTab(int index) {
    setState(() {
      _selectedButtonIndex = index;
      _searchOffset = 0;
    });
    final _InvoicePage page = _pages[index];
    if (!page.loaded && !page.isLoading) _loadPage(page, 0);
    if (_searching) _ensureAllLoaded(page);
  }

  void _onSearchChanged(String text) {
    _searchDebounce?.cancel();
    _searchDebounce =
        Timer(const Duration(milliseconds: 300), () => _search(text.trim()));
  }

  void _search(String query) {
    if (!mounted) return;
    setState(() {
      _query = query;
      _searchOffset = 0;
    });
    if (_searching) _ensureAllLoaded(_pages[_selectedButtonIndex]);
  }

  void _ensureAllLoaded(_InvoicePage page) {
    if (page.all == null && !page.isLoadingAll) _loadAll(page);
  }

  Future<void> _loadAll(_InvoicePage page) async {
    final int request = ++page.allRequest;
    setState(() {
      page.isLoadingAll = true;
      page.allFailed = false;
    });
    List<InvoiceModel>? all;
    try {
      all = await fetchAllPages<InvoiceModel>((limit, offset) =>
          _documentUseCase.getInvoices(page.type,
              limit: limit, offset: offset));
    } catch (_) {
      all = null;
    }
    if (!mounted || request != page.allRequest) return;
    setState(() {
      page.isLoadingAll = false;
      page.all = all;
      page.allFailed = all == null;
    });
  }

  /// N° de facture / transaction / commande, client ou commerçant, montant,
  /// date d'émission.
  bool _matches(InvoiceModel invoice) => matchesSearch(_query, [
        invoice.invoiceNumber,
        invoice.transactionNumber,
        invoice.orderNumber,
        invoice.entityName,
        invoice.entityCode,
        invoice.giftFrom,
        invoice.giftReason,
        if (invoice.totalAmountInvoice != null) ...[
          formatEuro(invoice.totalAmountInvoice),
          invoice.totalAmountInvoice!.toStringAsFixed(2),
        ],
        formatFrenchDate(invoice.createdDate),
        invoice.createdDate,
      ]);

  List<InvoiceModel> _searchResults(_InvoicePage page) =>
      (page.all ?? const <InvoiceModel>[]).where(_matches).toList();

  Future<void> _loadPage(_InvoicePage page, int startIndex) async {
    final int request = ++page.request;
    setState(() {
      page.isLoading = true;
      page.failed = false;
    });
    PaginatedResult<InvoiceModel>? result;
    try {
      result = await _documentUseCase.getInvoices(
        page.type,
        limit: _pageSize,
        offset: startIndex,
      );
    } catch (_) {
      result = null;
    }
    if (!mounted || request != page.request) return;
    setState(() {
      page.isLoading = false;
      if (result == null) {
        page.failed = true;
        return;
      }
      page.loaded = true;
      page.offset = startIndex;
      page.items = result.items;
      page.total = result.total > 0
          ? result.total
          : startIndex + result.items.length;
    });
  }

  Future _downloadFileInvoice(InvoiceModel order) async {
    final String name = order.entityName?.replaceAll(' ', '_') ?? 'Facture';
    await downloadOrderInvoice(context, order.idOrder!,
        fallbackName: '${name}_${order.orderNumber}');
  }

  Future _downloadFileFees(InvoiceModel fee) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const LoadingDialog(loadingText: 'Génération du document...');
      },
    );
    try {
      String? name = fee.entityName;
      name = name?.replaceAll(' ', '_') ?? 'Frais';
      dynamic response = await _documentUseCase.downloadFileFees(
          fee.transactionNumber ?? '');
      List<dynamic> listDynamic = response;

      FileDownloader.downloadLargeFile(listDynamic, name, 'application/zip',
          fileExtension: 'zip');
    } catch (error) {
      snackbarKey.currentState?.showSnackBar(arcStatusSnackBar(
          'Erreur lors de la génération du fichier.',
          error: true));
    } finally {
      navigatorKey.currentState?.pop();
    }
  }

  // ---------------------------------------------------------------------------
  // Affichage
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final _InvoicePage page = _pages[_selectedButtonIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ArcPageHeader(
          eyebrow: 'Finance',
          title: 'Documents',
          actions: [
            ArcSegmented<int>(
              height: 40,
              segments: const [
                ArcSegment(0, 'Factures'),
                ArcSegment(1, 'Frais de gestion'),
              ],
              selected: _selectedButtonIndex,
              onChanged: _selectTab,
            ),
          ],
        ),
        ArcTableCard(
          toolbar: Align(
            alignment: Alignment.centerLeft,
            child: ArcSearchField(
              controller: _searchController,
              hint: page.type == 'fees'
                  ? 'N° de facture ou de transaction, commerçant, montant…'
                  : 'N° de facture ou de commande, client, montant…',
              semanticLabel: 'Rechercher un document',
              width: 420,
              onChanged: _onSearchChanged,
            ),
          ),
          footer: _searching ? _searchFooter(page) : _pageFooter(page),
          child: _searching
              ? _buildSearchContent(page)
              : _buildContent(page,
                  items: page.items,
                  isLoading: page.isLoading,
                  failed: page.failed,
                  onRetry: () => _loadPage(page, page.offset)),
        ),
      ],
    );
  }

  Widget _pageFooter(_InvoicePage page) => ArcPagination(
        label: page.items.isEmpty
            ? '0 sur ${page.total}'
            : '${page.offset + 1}–${page.offset + page.items.length} sur ${page.total}',
        onPrevious: page.isLoading || page.offset == 0
            ? null
            : () => _loadPage(page, page.offset - _pageSize),
        onNext: page.isLoading || page.offset + _pageSize >= page.total
            ? null
            : () => _loadPage(page, page.offset + _pageSize),
      );

  Widget _searchFooter(_InvoicePage page) {
    final int count = page.isLoadingAll ? 0 : _searchResults(page).length;
    final int end = (_searchOffset + _pageSize).clamp(0, count);
    return ArcPagination(
      leading: Text('Recherche « $_query »',
          overflow: TextOverflow.ellipsis, style: ArcText.small()),
      label: count == 0 ? '0 résultat' : '${_searchOffset + 1}–$end sur $count',
      onPrevious: _searchOffset == 0
          ? null
          : () => setState(() => _searchOffset -= _pageSize),
      onNext: end >= count
          ? null
          : () => setState(() => _searchOffset += _pageSize),
    );
  }

  Widget _buildSearchContent(_InvoicePage page) {
    return _buildContent(page,
        items: _searchResults(page).skip(_searchOffset).take(_pageSize).toList(),
        isLoading: page.isLoadingAll,
        failed: page.allFailed,
        onRetry: () => _loadAll(page),
        emptyTitle: 'Aucun document ne correspond à « $_query »');
  }

  Widget _buildContent(
    _InvoicePage page, {
    required List<InvoiceModel> items,
    required bool isLoading,
    required bool failed,
    required VoidCallback onRetry,
    String? emptyTitle,
  }) {
    final bool fees = page.type == 'fees';

    if (isLoading && items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (failed) {
      return _TableMessage(
        icon: Icons.error_outline_rounded,
        tone: ArcTone.danger,
        title: 'Impossible de charger les documents.',
        action: OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Réessayer'),
        ),
      );
    }
    if (items.isEmpty) {
      return _TableMessage(
        icon: Icons.description_outlined,
        title: emptyTitle ??
            (fees ? 'Aucune facture de frais de gestion' : 'Aucune facture'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isLoading)
          const LinearProgressIndicator(minHeight: 2)
        else
          const SizedBox(height: 2),
        LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                columns: [
                  if (fees)
                    const DataColumn(label: Text('N° de transaction')),
                  const DataColumn(label: Text('N° de facture')),
                  DataColumn(
                      label: Text(fees ? 'Commerçant' : 'Client'),
                      columnWidth: const IntrinsicColumnWidth(flex: 1)),
                  DataColumn(
                      label: Text(fees ? 'Montant des frais' : 'Montant TTC'),
                      numeric: true),
                  const DataColumn(label: Text('Émise le')),
                  const DataColumn(
                      label: Text('PDF'),
                      headingRowAlignment: MainAxisAlignment.end),
                ],
                rows: [
                  for (final InvoiceModel invoice in items)
                    _buildRow(invoice, fees),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  DataRow _buildRow(InvoiceModel invoice, bool fees) {
    final String name = invoice.entityName ?? '';
    return DataRow(
      cells: [
        if (fees)
          DataCell(SelectableText(invoice.transactionNumber ?? '',
              style: ArcText.data())),
        DataCell(SelectableText(invoice.invoiceNumber ?? '',
            style: ArcText.data(color: kNavy900, fontWeight: FontWeight.w500))),
        DataCell(name.isEmpty
            ? const SizedBox.shrink()
            : Row(mainAxisSize: MainAxisSize.min, children: [
                ArcAvatar(name, size: 30),
                const SizedBox(width: 10),
                Flexible(
                  child: SelectableText(name,
                      style: ArcText.body()
                          .copyWith(fontSize: 13, fontWeight: FontWeight.w500)),
                ),
              ])),
        DataCell(Text(
            invoice.totalAmountInvoice == null
                ? ''
                : formatEuro(invoice.totalAmountInvoice),
            style: ArcText.data(fontWeight: FontWeight.w500))),
        DataCell(SelectableText(formatFrenchDate(invoice.createdDate),
            style: ArcText.body(color: kText2).copyWith(fontSize: 13))),
        DataCell(Align(
          alignment: Alignment.centerRight,
          child: ArcIconAction(
            icon: Icons.download_rounded,
            tooltip: 'Télécharger',
            onPressed: () {
              fees ? _downloadFileFees(invoice) : _downloadFileInvoice(invoice);
            },
          ),
        )),
      ],
    );
  }
}

/// État de pagination d'un onglet.
class _InvoicePage {
  final String type;
  _InvoicePage(this.type);

  int offset = 0;
  List<InvoiceModel> items = const [];
  int total = 0;
  bool isLoading = false;
  bool loaded = false;
  bool failed = false;
  int request = 0;

  /// Tous les documents de l'onglet (recherche), `null` tant qu'ils ne sont
  /// pas chargés.
  List<InvoiceModel>? all;
  bool isLoadingAll = false;
  bool allFailed = false;
  int allRequest = 0;
}

/// Message à la place du tableau (chargement en échec, liste vide).
class _TableMessage extends StatelessWidget {
  final IconData icon;
  final ArcTone tone;
  final String title;
  final Widget? action;
  const _TableMessage(
      {required this.icon,
      required this.title,
      this.tone = ArcTone.info,
      this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
              color: tone.background, borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: tone.text),
        ),
        const SizedBox(height: 12),
        Text(title, textAlign: TextAlign.center, style: ArcText.cardTitle()),
        if (action != null) ...[const SizedBox(height: 16), action!],
      ]),
    );
  }
}
