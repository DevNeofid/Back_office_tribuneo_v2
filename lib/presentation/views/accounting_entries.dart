import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:back_office_tribuneo_v2/domain/errors/accounting_entries_config_exception.dart';
import 'package:back_office_tribuneo_v2/domain/errors/api_exception.dart';
import 'package:back_office_tribuneo_v2/domain/models/accounting_entries_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/paginated_result.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/accounting_entries_usecase.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/_global.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/file_downloader.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/formatters.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/accounting_entries_config_dialog.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/arc/arc.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/hold_refund_dialog.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/loading.dart';

/// Écritures comptables : déclenchement d'un nouveau fichier et historique des
/// fichiers générés, page par page (10 par page).
class AccountingEntriesView extends StatefulWidget {
  const AccountingEntriesView({super.key});

  @override
  State<AccountingEntriesView> createState() => _AccountingEntriesViewState();
}

class _AccountingEntriesViewState extends State<AccountingEntriesView> {
  static const int _pageSize = 10;

  final AccountingEntriesUseCase _accountingEntriesUseCase =
      AccountingEntriesUseCase();

  late DateTime today;
  late String formattedDate;

  // Page courante.
  int _offset = 0;
  List<AccountingEntriesModel> _entries = const [];
  int _lastKnownTotal = 0;
  bool _isLoadingPage = true;
  bool _pageFailed = false;
  int _pageRequest = 0;

  @override
  void initState() {
    super.initState();
    _timeNow();
    _loadPage(0);
  }

  _timeNow() {
    today = DateTime.now().subtract(const Duration(days: 1));
    formattedDate = DateFormat('yyyy-MM-dd').format(today);
    return formattedDate;
  }

  Future<void> _loadPage(int startIndex) async {
    final int request = ++_pageRequest;
    setState(() {
      _isLoadingPage = true;
      _pageFailed = false;
    });
    PaginatedResult<AccountingEntriesModel>? result;
    try {
      result = await _accountingEntriesUseCase.getAccountingEntries(
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
      _entries = result.items;
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

  Future _downloadFile(AccountingEntriesModel entry) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const LoadingDialog(
            loadingText: 'Génération des écritures comptables...');
      },
    );
    try {
      String? name = entry.filename;
      dynamic response =
          await _accountingEntriesUseCase.downloadFile(entry.id!);

      List<dynamic> listDynamic = response;

      FileDownloader.downloadLargeFile(listDynamic, name!, 'application/zip',
          fileExtension: 'zip');
      _loadPage(_offset);
    } catch (error) {
      snackbarKey.currentState?.showSnackBar(arcStatusSnackBar(
          'Aucune écritures comptables disponibles.',
          error: true));
    } finally {
      navigatorKey.currentState?.pop();
    }
  }

  Future _createAccountingEntries() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const LoadingDialog(
            loadingText: 'Génération des écritures comptables...');
      },
    );
    // L'erreur est mise de côté puis traitée après le `finally` : le pop() qui ferme
    // le dialogue de chargement fermerait sinon le dialogue d'erreur à sa place.
    Object? failure;
    try {
      dynamic response =
          await _accountingEntriesUseCase.createAccountingEntries();
      String fileName = 'ECRITURES_$formattedDate';
      List<dynamic> listDynamic = response;

      FileDownloader.downloadLargeFile(listDynamic, fileName, 'application/zip',
          fileExtension: 'zip');
    } catch (error) {
      failure = error;
    } finally {
      navigatorKey.currentState?.pop();
    }

    if (failure == null) return;

    if (failure is AccountingEntriesConfigException) {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (BuildContext context) => AccountingEntriesConfigDialog(
            errors: (failure as AccountingEntriesConfigException).errors),
      );
      return;
    }

    snackbarKey.currentState?.showSnackBar(arcStatusSnackBar(
        failure is ApiException
            ? failure.message
            : 'Erreur lors de la génération des écritures comptables.',
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
        ArcPageHeader(
          eyebrow: 'Finance',
          title: 'Écritures comptables',
          actions: [
            FilledButton.icon(
              onPressed: () {
                _createAccountingEntries();
              },
              icon: const Icon(Icons.play_arrow_rounded, size: 20),
              label: const Text('Déclencher les écritures comptables'),
            ),
          ],
        ),
        ArcTableCard(
          toolbar: Row(children: [
            Text('Fichiers générés',
                style: ArcText.cardTitle().copyWith(fontSize: 16)),
            if (_lastKnownTotal > 0) ...[
              const SizedBox(width: 10),
              ArcCount('$_lastKnownTotal'),
            ],
          ]),
          footer: ArcPagination(
            label: _entries.isEmpty
                ? '0 sur $_lastKnownTotal'
                : '${_offset + 1}–${_offset + _entries.length} sur $_lastKnownTotal',
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

  Widget _buildContent() {
    if (_isLoadingPage && _entries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_pageFailed) {
      return _TableMessage(
        icon: Icons.error_outline_rounded,
        tone: ArcTone.danger,
        title: 'Impossible de charger les écritures comptables.',
        action: OutlinedButton.icon(
          onPressed: () => _loadPage(_offset),
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Réessayer'),
        ),
      );
    }
    if (_entries.isEmpty) {
      return const _TableMessage(
        icon: Icons.table_chart_outlined,
        title: 'Aucune écriture comptable générée',
      );
    }

    final List<_EntriesPeriod?> periods = [
      for (final entry in _entries) _EntriesPeriod.tryParse(entry.filename),
    ];
    final bool anyPeriod = periods.any((period) => period != null);
    final int longest = periods.fold<int>(
        1, (max, p) => p != null && p.days > max ? p.days : max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_isLoadingPage)
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
                  if (anyPeriod) ...[
                    const DataColumn(label: Text('Période couverte')),
                    const DataColumn(
                        label: Text('Durée'),
                        columnWidth: IntrinsicColumnWidth(flex: 1)),
                  ],
                  DataColumn(
                      label: const Text('Fichier'),
                      columnWidth:
                          anyPeriod ? null : const IntrinsicColumnWidth(flex: 1)),
                  const DataColumn(label: Text('Généré le')),
                  const DataColumn(
                      label: Text('Télécharger'),
                      headingRowAlignment: MainAxisAlignment.end),
                ],
                rows: [
                  for (int i = 0; i < _entries.length; i++)
                    _buildRow(_entries[i], periods[i], anyPeriod, longest),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  DataRow _buildRow(AccountingEntriesModel entry, _EntriesPeriod? period,
      bool anyPeriod, int longest) {
    final String filename = entry.filename ?? '';
    return DataRow(
      cells: [
        if (anyPeriod) ...[
          DataCell(Text(period?.label ?? '',
              style: ArcText.body(color: kNavy900)
                  .copyWith(fontSize: 13, fontWeight: FontWeight.w500))),
          DataCell(period == null
              ? const SizedBox.shrink()
              : _DurationBar(days: period.days, longest: longest)),
        ],
        DataCell(SelectableText(filename,
            style: anyPeriod
                ? ArcText.dataSmall()
                : ArcText.data(color: kNavy900, fontWeight: FontWeight.w500))),
        DataCell(SelectableText(formatFrenchDate(entry.createdDate),
            style: ArcText.body(color: kText2).copyWith(fontSize: 13))),
        DataCell(Align(
          alignment: Alignment.centerRight,
          child: ArcIconAction(
            icon: Icons.download_rounded,
            tooltip: 'Télécharger',
            onPressed: () {
              _downloadFile(entry);
            },
          ),
        )),
      ],
    );
  }
}

/// Période couverte par un fichier d'écritures, lue dans son nom
/// (`ECRITURES_2026-10-08_2026-10-11.zip`). `null` si le nom ne suit pas
/// exactement ce format : on n'affiche alors que le nom du fichier.
class _EntriesPeriod {
  final DateTime from;
  final DateTime to;
  const _EntriesPeriod(this.from, this.to);

  static final RegExp _pattern = RegExp(
      r'^ECRITURES_(\d{4}-\d{2}-\d{2})_(\d{4}-\d{2}-\d{2})(?:\.zip)?$');

  static _EntriesPeriod? tryParse(String? filename) {
    final RegExpMatch? match = _pattern.firstMatch(filename?.trim() ?? '');
    if (match == null) return null;
    final DateTime? from = _strictDate(match.group(1)!);
    final DateTime? to = _strictDate(match.group(2)!);
    if (from == null || to == null || to.isBefore(from)) return null;
    return _EntriesPeriod(from, to);
  }

  /// Refuse les dates que `DateTime` corrigerait (2026-02-30).
  static DateTime? _strictDate(String value) {
    final DateTime? date = DateTime.tryParse(value);
    if (date == null) return null;
    return DateFormat('yyyy-MM-dd').format(date) == value ? date : null;
  }

  /// Nombre de jours couverts, bornes incluses.
  int get days => DateTime.utc(to.year, to.month, to.day)
          .difference(DateTime.utc(from.year, from.month, from.day))
          .inDays +
      1;

  String get label {
    final DateFormat dayMonth = DateFormat('d MMM', 'fr_FR');
    final DateFormat full = DateFormat('d MMM yyyy', 'fr_FR');
    if (from == to) return full.format(from);
    if (from.year != to.year) return '${full.format(from)} → ${full.format(to)}';
    return '${dayMonth.format(from)} → ${full.format(to)}';
  }
}

/// Barre de durée relative à la plus longue période de la page, et nombre de jours.
class _DurationBar extends StatelessWidget {
  final int days;
  final int longest;
  const _DurationBar({required this.days, required this.longest});

  @override
  Widget build(BuildContext context) {
    final double ratio = (days / longest).clamp(0.03, 1.0);
    return Row(children: [
      Expanded(
        child: Container(
          height: 6,
          constraints: const BoxConstraints(minWidth: 80),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
              color: kNavy50, borderRadius: BorderRadius.circular(999)),
          child: FractionallySizedBox(
            widthFactor: ratio,
            child: Container(
              decoration: BoxDecoration(
                  color: kNavy400, borderRadius: BorderRadius.circular(999)),
            ),
          ),
        ),
      ),
      const SizedBox(width: 10),
      SizedBox(
        width: 44,
        child: Text('$days j',
            textAlign: TextAlign.right, style: ArcText.dataSmall()),
      ),
    ]);
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
