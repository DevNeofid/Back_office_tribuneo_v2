import 'package:back_office_tribuneo_v2/presentation/widgets/tribuneo_loader.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:back_office_tribuneo_v2/domain/errors/api_exception.dart';
import 'package:back_office_tribuneo_v2/domain/models/bank_account_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/downloaded_file.dart';
import 'package:back_office_tribuneo_v2/domain/models/paginated_result.dart';
import 'package:back_office_tribuneo_v2/domain/models/transfer_order_model.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/bank_account_usecase.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/transfer_order_usecase.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/_global.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/file_downloader.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/formatters.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/arc/arc.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/hold_refund_dialog.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/loading.dart';

/// Historique des ordres de virement, page par page (10 par page).
class TranferOrderView extends StatefulWidget {
  const TranferOrderView({super.key});

  @override
  State<TranferOrderView> createState() => _TranferOrderViewState();
}

class _TranferOrderViewState extends State<TranferOrderView> {
  static const int _pageSize = 10;

  final TransferOrderUseCase _transferOrderUseCase = TransferOrderUseCase();
  final BankAccountUseCase _bankAccountUseCase = BankAccountUseCase();

  /// Le tableau n'est affiché qu'une fois les comptes connus : la colonne « Compte »
  /// en dépend, et colonnes et cellules doivent rester alignées.
  bool _isLoadingBankAccounts = true;

  /// Comptes du réseau, pour afficher le libellé du compte payeur. Colonne affichée
  /// seulement s'il y a plusieurs comptes.
  BankAccountsModel? _bankAccounts;

  /// Compte choisi dans le filtre (`null` : tous). Filtre la page affichée.
  String? _accountFilter;

  // Page courante.
  int _offset = 0;
  List<TransferOrderModel> _orders = const [];
  int _lastKnownTotal = 0;
  bool _isLoadingPage = true;
  bool _pageFailed = false;
  int _pageRequest = 0;

  @override
  void initState() {
    super.initState();
    _loadBankAccounts();
    _loadPage(0);
  }

  Future<void> _loadBankAccounts() async {
    BankAccountsModel? accounts;
    try {
      accounts = await _bankAccountUseCase.getBankAccounts();
    } catch (_) {
      // Colonne facultative : sans la liste, on affiche le tableau sans elle.
      accounts = null;
    }
    if (!mounted) return;
    setState(() {
      _bankAccounts = accounts;
      _isLoadingBankAccounts = false;
    });
  }

  Future<void> _loadPage(int startIndex) async {
    final int request = ++_pageRequest;
    setState(() {
      _isLoadingPage = true;
      _pageFailed = false;
    });
    PaginatedResult<TransferOrderModel>? result;
    try {
      result = await _transferOrderUseCase.getOrders(
        limit: _pageSize,
        offset: startIndex,
      );
    } catch (_) {
      result = null;
    }
    if (!mounted || request != _pageRequest) return;
    setState(() {
      _isLoadingPage = false;
      if (result == null) {
        _pageFailed = true;
        return;
      }
      _offset = startIndex;
      _orders = result.items;
      if (result.total > 0) {
        _lastKnownTotal = result.total;
      } else {
        _lastKnownTotal = startIndex + result.items.length;
        if (result.items.length == _pageSize) {
          _lastKnownTotal += 1;
        }
      }
    });
  }

  bool get _showBankAccount => _bankAccounts?.hasSeveralAccounts ?? false;

  /// Compte effectif d'un ordre : `null` (ordre antérieur aux comptes multiples)
  /// correspond au compte par défaut, comme dans [BankAccountsModel.labelForCode].
  String? _orderAccountCode(TransferOrderModel order) =>
      order.bankAccountCode ?? _bankAccounts?.defaultAccount?.code;

  List<TransferOrderModel> get _visibleOrders {
    if (!_showBankAccount || _accountFilter == null) return _orders;
    return _orders
        .where((order) => _orderAccountCode(order) == _accountFilter)
        .toList();
  }

  Future _downloadFile(TransferOrderModel order) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const LoadingDialog(
            loadingText: "Téléchargement de l'ordre de virement...");
      },
    );
    try {
      String? name = order.filename;
      dynamic res = await _transferOrderUseCase.downloadFile(order.id!);

      List<dynamic> listDynamic = res;

      FileDownloader.downloadLargeFile(
          listDynamic, name ?? 'virement', 'application/zip',
          fileExtension: 'zip');
    } catch (error) {
      snackbarKey.currentState?.showSnackBar(arcStatusSnackBar(
          'Erreur lors de la génération des ordres de virement.',
          error: true));
    } finally {
      navigatorKey.currentState?.pop();
    }
  }

  /// Un PDF (justificatif + facture) par demande payée par ce virement. Les
  /// virements antérieurs au 14/10/2026 n'en ont pas : 404, cas normal.
  Future _downloadDocuments(TransferOrderModel order) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const LoadingDialog(
            loadingText: 'Préparation des documents du virement...');
      },
    );
    DownloadedFile? file;
    String? failure;
    try {
      file = await _transferOrderUseCase.downloadDocuments(order.id!);
    } on ApiException catch (e) {
      failure = e.message;
    } catch (_) {
      failure = 'Erreur lors du téléchargement des documents du virement.';
    } finally {
      navigatorKey.currentState?.pop();
    }

    if (file != null) {
      FileDownloader.downloadLargeFile(file.bytes,
          file.filename ?? 'DOCUMENTS_BTO_${order.id}', 'application/zip',
          fileExtension: 'zip');
      return;
    }
    snackbarKey.currentState?.showSnackBar(arcStatusSnackBar(
        failure ?? 'Erreur lors du téléchargement des documents du virement.',
        error: true));
  }

  // ---------------------------------------------------------------------------
  // Affichage
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ArcPageHeader(eyebrow: 'Finance', title: 'Ordres de virement'),
        ArcTableCard(
          toolbar: _isLoadingBankAccounts ? null : _buildToolbar(),
          footer: ArcPagination(
            label: _paginationLabel(),
            onPrevious: _isLoadingPage || _offset == 0
                ? null
                : () => _loadPage(_offset - _pageSize),
            onNext: _isLoadingPage || _offset + _pageSize >= _lastKnownTotal
                ? null
                : () => _loadPage(_offset + _pageSize),
          ),
          child: _buildContent(),
        ),
      ],
    );
  }

  String _paginationLabel() {
    if (_orders.isEmpty) return '0 sur $_lastKnownTotal';
    return '${_offset + 1}–${_offset + _orders.length} sur $_lastKnownTotal';
  }

  Widget _buildToolbar() {
    final List<TransferOrderModel> visible = _visibleOrders;
    final num refunded =
        visible.fold<num>(0, (sum, order) => sum + (order.refundedAmount ?? 0));
    final num fees =
        visible.fold<num>(0, (sum, order) => sum + (order.retainedAmount ?? 0));
    final TextStyle text = ArcText.small().copyWith(fontSize: 13);
    final TextStyle figure =
        ArcText.data(color: kNavy900, fontWeight: FontWeight.w500);

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: [
        if (_showBankAccount)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ArcSegmented<String?>(
              segments: [
                const ArcSegment<String?>(null, 'Tous les comptes'),
                for (final BankAccountModel account in _bankAccounts!.accounts)
                  ArcSegment<String?>(account.code, account.label),
              ],
              selected: _accountFilter,
              onChanged: (code) => setState(() => _accountFilter = code),
            ),
          )
        else
          const SizedBox.shrink(),
        if (visible.isNotEmpty)
          Wrap(spacing: 16, runSpacing: 4, children: [
            Text.rich(TextSpan(style: text, children: [
              const TextSpan(text: 'Sur cette page : '),
              TextSpan(text: formatEuro(refunded), style: figure),
              const TextSpan(text: ' remboursés'),
            ])),
            Text.rich(TextSpan(style: text, children: [
              TextSpan(text: formatEuro(fees), style: figure),
              const TextSpan(text: ' de frais'),
            ])),
          ]),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoadingBankAccounts || (_isLoadingPage && _orders.isEmpty)) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: TribuneoLoader()),
      );
    }
    if (_pageFailed) {
      return _TableMessage(
        icon: Icons.error_outline_rounded,
        tone: ArcTone.danger,
        title: 'Impossible de charger les ordres de virement.',
        action: OutlinedButton.icon(
          onPressed: () => _loadPage(_offset),
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Réessayer'),
        ),
      );
    }
    if (_orders.isEmpty) {
      return const _TableMessage(
        icon: Icons.swap_horiz_rounded,
        title: 'Aucun ordre de virement',
      );
    }

    final List<TransferOrderModel> visible = _visibleOrders;
    if (visible.isEmpty) {
      return const _TableMessage(
        icon: Icons.filter_alt_off_outlined,
        title: 'Aucun ordre de ce compte sur cette page',
      );
    }

    final bool anyPeriod =
        visible.any((order) => _BtoPeriod.tryParse(order.filename) != null);
    final String? defaultCode = _bankAccounts?.defaultAccount?.code;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_isLoadingPage)
          const TribuneoLoadingProgress()
        else
          const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                columns: [
                  DataColumn(
                      label: Text(anyPeriod ? 'Période' : 'Nom du fichier'),
                      columnWidth: const IntrinsicColumnWidth(flex: 1)),
                  if (_showBankAccount) const DataColumn(label: Text('Compte')),
                  const DataColumn(
                      label: Text('Frais de gestion'), numeric: true),
                  const DataColumn(
                      label: Text('Montant remboursé'), numeric: true),
                  const DataColumn(label: Text('Créé le')),
                  const DataColumn(
                      label: Text('Fichiers'),
                      headingRowAlignment: MainAxisAlignment.end),
                ],
                rows: [
                  for (final TransferOrderModel order in visible)
                    _buildRow(order, defaultCode),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  DataRow _buildRow(TransferOrderModel order, String? defaultCode) {
    final String filename = order.filename ?? '';
    final _BtoPeriod? period = _BtoPeriod.tryParse(order.filename);
    final String? accountCode = _orderAccountCode(order);

    return DataRow(
      cells: [
        DataCell(period == null
            ? SelectableText(filename,
                style: ArcText.data(color: kNavy900, fontWeight: FontWeight.w500))
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(period.label,
                      style: ArcText.body(color: kNavy900).copyWith(
                          fontSize: 13, fontWeight: FontWeight.w500)),
                  SelectableText(filename,
                      style: ArcText.dataSmall(color: kText3)
                          .copyWith(fontSize: 10.5)),
                ],
              )),
        if (_showBankAccount)
          DataCell(_AccountPill(
            label: _bankAccounts!.labelForCode(order.bankAccountCode),
            primary: accountCode != null && accountCode == defaultCode,
          )),
        DataCell(Text(formatEuro(order.retainedAmount),
            style: ArcText.data(color: kText2))),
        DataCell(Text(formatEuro(order.refundedAmount),
            style: ArcText.data(fontWeight: FontWeight.w500))),
        DataCell(SelectableText(formatFrenchDate(order.createdDate),
            style: ArcText.body(color: kText2).copyWith(fontSize: 13))),
        DataCell(Align(
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ArcIconAction(
                icon: Icons.download_rounded,
                tooltip: "Télécharger l'ordre de virement",
                onPressed: () => _downloadFile(order),
              ),
              const SizedBox(width: 4),
              ArcIconAction(
                icon: Icons.folder_zip_outlined,
                tooltip: 'Documents (justificatifs et factures)',
                onPressed: () => _downloadDocuments(order),
              ),
            ],
          ),
        )),
      ],
    );
  }
}

/// Période couverte par un ordre de virement, lue dans son nom de fichier
/// (`BTO_2026-10-13_2026-10-15_151929.zip`). `null` si le nom ne suit pas
/// exactement ce format : on n'affiche alors que le nom du fichier.
class _BtoPeriod {
  final DateTime from;
  final DateTime to;
  const _BtoPeriod(this.from, this.to);

  static final RegExp _pattern = RegExp(
      r'^BTO_(\d{4}-\d{2}-\d{2})_(\d{4}-\d{2}-\d{2})(?:_\d+)?(?:\.zip)?$');

  static _BtoPeriod? tryParse(String? filename) {
    final RegExpMatch? match = _pattern.firstMatch(filename?.trim() ?? '');
    if (match == null) return null;
    final DateTime? from = _strictDate(match.group(1)!);
    final DateTime? to = _strictDate(match.group(2)!);
    if (from == null || to == null || to.isBefore(from)) return null;
    return _BtoPeriod(from, to);
  }

  /// Refuse les dates que `DateTime` corrigerait (2026-02-30).
  static DateTime? _strictDate(String value) {
    final DateTime? date = DateTime.tryParse(value);
    if (date == null) return null;
    return DateFormat('yyyy-MM-dd').format(date) == value ? date : null;
  }

  /// « 13 oct. 2026 », « 13 oct. → 15 oct. 2026 » ou, à cheval sur deux
  /// années, « 28 déc. 2025 → 3 janv. 2026 ».
  String get label {
    final DateFormat dayMonth = DateFormat('d MMM', 'fr_FR');
    final DateFormat full = DateFormat('d MMM yyyy', 'fr_FR');
    if (from == to) return full.format(from);
    if (from.year != to.year) return '${full.format(from)} → ${full.format(to)}';
    return '${dayMonth.format(from)} → ${full.format(to)}';
  }
}

/// Pastille du compte payeur : pleine pour le compte par défaut, bordée sinon.
class _AccountPill extends StatelessWidget {
  final String label;
  final bool primary;
  const _AccountPill({required this.label, required this.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: primary ? kNavy600 : kSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: primary ? kNavy600 : kNavy400, width: 1.5),
      ),
      child: Text(label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ArcText.small(color: primary ? Colors.white : kNavy600)
              .copyWith(fontWeight: FontWeight.w600)),
    );
  }
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
