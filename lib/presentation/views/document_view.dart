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
    super.dispose();
  }

  /// Deep-link de l'assistant : onglet « Factures ».
  void _handleOpenRequest() {
    if (_openRequests?.take(const {'invoices'}) == null || !mounted) return;
    _selectTab(0);
  }

  void _selectTab(int index) {
    setState(() => _selectedButtonIndex = index);
    final _InvoicePage page = _pages[index];
    if (!page.loaded && !page.isLoading) _loadPage(page, 0);
  }

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
          footer: ArcPagination(
            label: page.items.isEmpty
                ? '0 sur ${page.total}'
                : '${page.offset + 1}–${page.offset + page.items.length} sur ${page.total}',
            onPrevious: page.isLoading || page.offset == 0
                ? null
                : () => _loadPage(page, page.offset - _pageSize),
            onNext: page.isLoading || page.offset + _pageSize >= page.total
                ? null
                : () => _loadPage(page, page.offset + _pageSize),
          ),
          child: _buildContent(page),
        ),
      ],
    );
  }

  Widget _buildContent(_InvoicePage page) {
    final bool fees = page.type == 'fees';

    if (page.isLoading && page.items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (page.failed) {
      return _TableMessage(
        icon: Icons.error_outline_rounded,
        tone: ArcTone.danger,
        title: 'Impossible de charger les documents.',
        action: OutlinedButton.icon(
          onPressed: () => _loadPage(page, page.offset),
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Réessayer'),
        ),
      );
    }
    if (page.items.isEmpty) {
      return _TableMessage(
        icon: Icons.description_outlined,
        title: fees
            ? 'Aucune facture de frais de gestion'
            : 'Aucune facture',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (page.isLoading)
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
                  for (final InvoiceModel invoice in page.items)
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
