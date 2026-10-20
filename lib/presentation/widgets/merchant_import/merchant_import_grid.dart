import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:back_office_tribuneo_v2/core/utils/idempotency_key.dart';
import 'package:back_office_tribuneo_v2/domain/errors/api_exception.dart';
import 'package:back_office_tribuneo_v2/domain/errors/merchant_import_exceptions.dart';
import 'package:back_office_tribuneo_v2/domain/models/merchant_import_batch_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/merchant_import_row_model.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/merchant_import_usecase.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/formatters.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/loading.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/merchant_import/row_save_queue.dart';

/// Grille de relecture d'un lot d'import de commerçants.
///
/// Chaque modification est enregistrée aussitôt ([RowSaveQueue]) : on peut
/// fermer et reprendre plus tard, sur un autre poste. Les lignes se cochent une
/// par une (pas de « tout cocher », décision produit), puis s'importent.
class MerchantImportGrid extends StatefulWidget {
  final MerchantImportBatch batch;

  /// Retour à la liste des lots (les enregistrements sont déjà terminés).
  final VoidCallback onBack;

  /// Au moins un commerçant a été importé : la liste des partenaires est à
  /// recharger.
  final VoidCallback onImported;

  /// Remplaçable dans les tests.
  final MerchantImportUseCase? useCase;

  const MerchantImportGrid({
    super.key,
    required this.batch,
    required this.onBack,
    required this.onImported,
    this.useCase,
  });

  @override
  State<MerchantImportGrid> createState() => MerchantImportGridState();
}

enum _Editor { text, type, readOnly }

class _GridColumn {
  final String key;
  final String label;
  final double width;
  final _Editor editor;
  final bool numeric;

  /// Aide affichée au survol de l'en-tête.
  final String? hint;

  const _GridColumn(this.key, this.label, this.width,
      {this.editor = _Editor.text, this.numeric = false, this.hint});
}

enum _Filter {
  all('Toutes'),
  pending('À relire'),
  errors('En anomalie'),
  validated('Validées'),
  rejected('Écartées'),
  imported('Importées'),
  failed('En échec');

  final String label;
  const _Filter(this.label);
}

/// Cellule en cours d'édition : une seule à la fois, son contrôleur est créé à
/// l'entrée en édition et libéré à la sortie.
class _EditingCell {
  final int rowId;
  final String field;
  final String initialText;
  final TextEditingController controller;
  final FocusNode focusNode = FocusNode();

  /// Dernière valeur envoyée pendant l'édition (envoi après 800 ms sans frappe).
  String? lastSentText;

  _EditingCell(this.rowId, this.field, this.initialText)
      : controller = TextEditingController(text: initialText);

  void dispose() {
    controller.dispose();
    focusNode.dispose();
  }
}

class MerchantImportGridState extends State<MerchantImportGrid> {
  late final MerchantImportUseCase _useCase =
      widget.useCase ?? MerchantImportUseCase();
  late final RowSaveQueue _queue;
  final PendingIdempotencyKey _importKey = PendingIdempotencyKey();

  late MerchantImportBatch _batch;
  List<MerchantImportRow> _rows = [];
  final Map<int, int> _indexById = {};
  bool _isLoading = true;
  String? _loadError;
  bool _isImporting = false;

  _Filter _filter = _Filter.all;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _search = '';
  int _page = 0;

  /// Lignes de la page affichée, dans l'ordre (navigation au clavier).
  List<MerchantImportRow> _pageRows = [];

  _EditingCell? _editing;
  Timer? _editDebounce;
  Timer? _pollTimer;

  final ScrollController _vertical = ScrollController();
  final ScrollController _horizontal = ScrollController();

  static const int _pageSize = 50;
  static const double _rowHeight = 44;
  static const String _typePartner = 'partner';
  static const String _typeCustomer = 'customer';

  static const double _checkWidth = 48;
  static const double _warnWidth = 40;
  static const double _actionsWidth = 90;

  static const List<_GridColumn> _fieldColumns = [
    _GridColumn('name', 'Nom', 220),
    _GridColumn('type', 'Type', 120, editor: _Editor.type),
    _GridColumn('siret', 'SIRET', 150),
    _GridColumn('email', 'Email', 200),
    _GridColumn('phone', 'Téléphone', 130),
    _GridColumn('street', 'Adresse', 220),
    _GridColumn('zip', 'CP', 80),
    _GridColumn('city', 'Ville', 140),
    _GridColumn('country', 'Pays', 100),
    _GridColumn('lat', 'Latitude', 100, numeric: true),
    _GridColumn('lng', 'Longitude', 100, numeric: true),
    _GridColumn('activity_sectors', 'Secteurs', 180,
        hint: 'Plusieurs secteurs : séparez-les par « / ».'),
    _GridColumn('code', 'Code', 100, hint: "Vide : généré à l'import."),
    _GridColumn('intracommunity_vat_number', 'TVA intracom.', 150),
    _GridColumn('iban', 'IBAN', 230),
    _GridColumn('bic', 'BIC', 110),
    _GridColumn('bank_key', 'Clé RIB', 70),
    _GridColumn('account_number', 'N° comptable', 120),
    _GridColumn('naf', 'NAF', 90,
        editor: _Editor.readOnly, hint: 'Rempli par la recherche automatique.'),
    _GridColumn('website', 'Site web', 180,
        editor: _Editor.readOnly, hint: 'Rempli par la recherche automatique.'),
  ];

  static final List<_GridColumn> _textColumns =
      _fieldColumns.where((column) => column.editor == _Editor.text).toList();

  static final Set<String> _visibleFields =
      _fieldColumns.map((column) => column.key).toSet();

  static final List<double> _columnWidths = [
    _checkWidth,
    _warnWidth,
    ..._fieldColumns.map((column) => column.width),
    _actionsWidth,
  ];

  static final double _tableWidth =
      _columnWidths.fold<double>(0, (sum, width) => sum + width);

  static final Map<int, TableColumnWidth> _tableColumnWidths = {
    for (int i = 0; i < _columnWidths.length; i++)
      i: FixedColumnWidth(_columnWidths[i]),
  };

  @override
  void initState() {
    super.initState();
    _batch = widget.batch;
    _queue = RowSaveQueue(
      send: (rowId, body) => _useCase.patchRow(_batch.id, rowId, body),
      currentRow: _rowById,
      onRowsUpdated: (rows) {
        if (mounted) setState(() => _replaceRows(rows));
      },
      onConflict: (edit) => _snack(
          edit.isStatus
              ? "Cette ligne vient d'être modifiée par quelqu'un d'autre : "
                  'elle a été rechargée.'
              : "Cette cellule vient d'être modifiée par quelqu'un d'autre : "
                  'sa valeur a été rechargée.',
          kOrange),
      onRejected: _onRejected,
      onUnvalidated: (_) =>
          _snack('Ligne modifiée : à valider de nouveau.', kBlue),
      onChanged: () {
        if (mounted) setState(() {});
      },
    );
    _reloadAll();
  }

  @override
  void dispose() {
    _queue.dispose();
    _searchDebounce?.cancel();
    _editDebounce?.cancel();
    _pollTimer?.cancel();
    _editing?.dispose();
    _searchController.dispose();
    _vertical.dispose();
    _horizontal.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Données
  // ---------------------------------------------------------------------------

  MerchantImportRow? _rowById(int rowId) {
    final int? index = _indexById[rowId];
    return index == null ? null : _rows[index];
  }

  void _setRows(List<MerchantImportRow> rows) {
    _rows = rows;
    _indexById
      ..clear()
      ..addAll({for (int i = 0; i < rows.length; i++) rows[i].id: i});
  }

  /// Remplace les lignes reçues, sauf si la grille en a déjà une version plus
  /// récente (réponses croisées).
  void _replaceRows(List<MerchantImportRow> rows) {
    for (final MerchantImportRow row in rows) {
      final int? index = _indexById[row.id];
      if (index == null) continue;
      if (row.version >= _rows[index].version) _rows[index] = row;
    }
  }

  Future<void> _reloadAll() async {
    setState(() {
      _isLoading = _rows.isEmpty;
      _loadError = null;
    });
    try {
      final List<dynamic> results = await Future.wait<dynamic>([
        _useCase.getBatch(_batch.id),
        _useCase.getRows(_batch.id),
      ]);
      if (!mounted) return;
      setState(() {
        _batch = results[0] as MerchantImportBatch;
        _setRows(results[1] as List<MerchantImportRow>);
        _isLoading = false;
      });
      _updatePolling();
    } on ApiException catch (e) {
      if (!mounted) return;
      if (_isBatchGone(e)) {
        _snack(e.message, kRed);
        widget.onBack();
        return;
      }
      setState(() {
        _isLoading = false;
        if (_rows.isEmpty) _loadError = e.message;
      });
      if (_rows.isNotEmpty) _snack(e.message, kRed);
    }
  }

  Future<void> _reloadBatch() async {
    try {
      final MerchantImportBatch batch = await _useCase.getBatch(_batch.id);
      if (!mounted) return;
      setState(() => _batch = batch);
      _updatePolling();
    } on ApiException catch (e) {
      if (!mounted) return;
      if (_isBatchGone(e)) {
        _snack(e.message, kRed);
        widget.onBack();
      }
    }
  }

  /// Recherche en cours (étapes 2-3) : on recharge le lot toutes les 3 s, et
  /// les lignes à chaque progression, jusqu'au passage en relecture.
  void _updatePolling() {
    if (!_batch.isProcessing) {
      _pollTimer?.cancel();
      _pollTimer = null;
      return;
    }
    _pollTimer ??= Timer.periodic(const Duration(seconds: 3), (_) => _poll());
  }

  Future<void> _poll() async {
    final MerchantImportBatch before = _batch;
    try {
      final MerchantImportBatch batch = await _useCase.getBatch(_batch.id);
      if (!mounted) return;
      setState(() => _batch = batch);
      if (batch.progressDone != before.progressDone ||
          batch.status != before.status) {
        final List<MerchantImportRow> rows = await _useCase.getRows(batch.id);
        if (!mounted) return;
        setState(() => _setRows(rows));
      }
      _updatePolling();
    } on ApiException {
      // Nouvel essai au prochain passage.
    }
  }

  bool _isBatchGone(ApiException e) =>
      e.code == 'BATCH_NOT_FOUND' || e.code == 'ROW_NOT_FOUND';

  void _onRejected(RowEdit edit, ApiException error) {
    if (!mounted) return;
    _snack(error.message, kRed);
    switch (error.code) {
      case 'ROW_HAS_ERRORS':
        final MerchantImportRow? current = _rowById(edit.rowId);
        final MerchantImportRow? serverRow =
            error is MerchantImportConflict ? error.row : null;
        if (serverRow != null) {
          setState(() => _replaceRows([serverRow]));
        } else if (current != null && error is MerchantImportConflict) {
          setState(() => _replaceRows([
                current.copyWith(
                    issues: error.issues,
                    status: MerchantImportRow.statusPending)
              ]));
        }
        break;
      case 'BATCH_NOT_EDITABLE':
        _reloadBatch();
        break;
      case 'ROW_IMPORTED':
        _reloadAll();
        break;
      case 'BATCH_NOT_FOUND':
      case 'ROW_NOT_FOUND':
        widget.onBack();
        break;
    }
  }

  // ---------------------------------------------------------------------------
  // Filtres, compteurs, pagination
  // ---------------------------------------------------------------------------

  /// Statut affiché : celui demandé tant que le serveur ne l'a pas confirmé.
  String _statusOf(MerchantImportRow row) =>
      _queue.pendingStatus(row.id) ?? row.status;

  bool _hasAnomaly(MerchantImportRow row) {
    final String status = _statusOf(row);
    return row.hasBlockingIssue &&
        status != MerchantImportRow.statusImported &&
        status != MerchantImportRow.statusRejected;
  }

  bool _matchesFilter(MerchantImportRow row, _Filter filter) {
    final String status = _statusOf(row);
    switch (filter) {
      case _Filter.all:
        return true;
      case _Filter.pending:
        return status == MerchantImportRow.statusPending;
      case _Filter.errors:
        return _hasAnomaly(row);
      case _Filter.validated:
        return status == MerchantImportRow.statusValidated;
      case _Filter.rejected:
        return status == MerchantImportRow.statusRejected;
      case _Filter.imported:
        return status == MerchantImportRow.statusImported;
      case _Filter.failed:
        return status == MerchantImportRow.statusFailed;
    }
  }

  bool _matchesSearch(MerchantImportRow row) {
    if (_search.isEmpty) return true;
    final String needle = _search.toLowerCase();
    final String compactNeedle = needle.replaceAll(' ', '');
    return row.textOf('name').toLowerCase().contains(needle) ||
        row.textOf('city').toLowerCase().contains(needle) ||
        (compactNeedle.isNotEmpty &&
            row.textOf('siret').replaceAll(' ', '').contains(compactNeedle));
  }

  Map<_Filter, int> _counts() {
    final Map<_Filter, int> counts = {for (final f in _Filter.values) f: 0};
    for (final MerchantImportRow row in _rows) {
      for (final _Filter filter in _Filter.values) {
        if (_matchesFilter(row, filter)) counts[filter] = counts[filter]! + 1;
      }
    }
    return counts;
  }

  void _onSearchChanged(String text) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {
        _search = text.trim();
        _page = 0;
      });
    });
  }

  // ---------------------------------------------------------------------------
  // Édition
  // ---------------------------------------------------------------------------

  bool get _editable => _batch.isEditable && !_isImporting;

  bool _rowEditable(MerchantImportRow row) {
    final String status = _statusOf(row);
    return _editable &&
        status != MerchantImportRow.statusImported &&
        status != MerchantImportRow.statusRejected;
  }

  dynamic _displayValue(MerchantImportRow row, String field) =>
      _queue.hasPending(row.id, field)
          ? _queue.pendingValue(row.id, field)
          : row.fields[field];

  bool _isEditing(MerchantImportRow row, String field) =>
      _editing?.rowId == row.id && _editing?.field == field;

  void _startEdit(MerchantImportRow row, _GridColumn column) {
    if (!_rowEditable(row) || column.editor != _Editor.text) return;
    if (_isEditing(row, column.key)) return;
    _finishEdit(commit: true);

    final _EditingCell editing = _EditingCell(row.id, column.key,
        MerchantImportRow.displayText(_displayValue(row, column.key)));
    editing.controller.selection = TextSelection(
        baseOffset: 0, extentOffset: editing.controller.text.length);
    editing.focusNode.addListener(() {
      if (!editing.focusNode.hasFocus && identical(_editing, editing)) {
        _finishEdit(commit: true);
      }
    });
    editing.controller.addListener(() {
      _editDebounce?.cancel();
      _editDebounce = Timer(const Duration(milliseconds: 800), () {
        if (identical(_editing, editing)) _submitEdit(editing);
      });
    });
    setState(() => _editing = editing);
  }

  /// Envoie la saisie si elle diffère de la dernière valeur envoyée (ou, à
  /// défaut, de la valeur de départ).
  void _submitEdit(_EditingCell editing) {
    final String text = editing.controller.text.trim();
    if (text == (editing.lastSentText ?? editing.initialText.trim())) return;
    editing.lastSentText = text;
    _queue.editField(editing.rowId, editing.field, text);
  }

  /// Sort de l'édition. [commit] : envoie la saisie ; sinon (Échap), rétablit
  /// la valeur de départ si une saisie était déjà partie.
  void _finishEdit({required bool commit}) {
    final _EditingCell? editing = _editing;
    if (editing == null) return;
    _editDebounce?.cancel();
    _editing = null;
    if (commit) {
      _submitEdit(editing);
    } else if (editing.lastSentText != null) {
      _queue.editField(editing.rowId, editing.field, editing.initialText);
    }
    if (mounted) setState(() {});
    // Le champ est encore dans l'arbre jusqu'à la prochaine image.
    WidgetsBinding.instance.addPostFrameCallback((_) => editing.dispose());
  }

  /// Tab / Maj+Tab : cellule texte voisine, puis ligne suivante ou précédente.
  void _moveEdit(_EditingCell editing, {required bool forward}) {
    final List<MerchantImportRow> rows = _pageRows;
    int r = rows.indexWhere((row) => row.id == editing.rowId);
    int c = _textColumns.indexWhere((column) => column.key == editing.field);
    _finishEdit(commit: true);
    if (r < 0 || c < 0) return;
    c += forward ? 1 : -1;
    if (c >= _textColumns.length) {
      c = 0;
      r++;
    } else if (c < 0) {
      c = _textColumns.length - 1;
      r--;
    }
    while (r >= 0 && r < rows.length && !_rowEditable(rows[r])) {
      r += forward ? 1 : -1;
    }
    if (r < 0 || r >= rows.length) return;
    _startEdit(rows[r], _textColumns[c]);
  }

  KeyEventResult _onEditKey(_EditingCell editing, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.tab) {
      _moveEdit(editing, forward: !HardwareKeyboard.instance.isShiftPressed);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _finishEdit(commit: false);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<String?> _showMenuAt(
      Offset globalPosition, List<PopupMenuEntry<String>> items) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    return showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
          globalPosition & const Size(1, 1), Offset.zero & overlay.size),
      items: items,
    );
  }

  Future<void> _pickType(MerchantImportRow row, Offset position) async {
    _finishEdit(commit: true);
    final String? type = await _showMenuAt(position, const [
      PopupMenuItem(value: _typePartner, child: Text('Commerçant')),
      PopupMenuItem(value: _typeCustomer, child: Text('Client')),
    ]);
    if (type != null && mounted) _queue.editField(row.id, 'type', type);
  }

  Future<void> _offerRevert(
      MerchantImportRow row, String field, Offset position) async {
    _finishEdit(commit: true);
    final String original = _typeLabel(field, row.originalOf(field));
    final String? choice = await _showMenuAt(position, [
      PopupMenuItem(
          value: 'revert',
          child: Text('Revenir à l\'origine : '
              '${original.isEmpty ? '(vide)' : '« $original »'}')),
    ]);
    if (choice == 'revert' && mounted) {
      _queue.editField(row.id, field, row.originalOf(field));
    }
  }

  void _toggleValidated(MerchantImportRow row, bool checked) {
    _finishEdit(commit: true);
    _queue.setStatus(
        row.id,
        checked
            ? MerchantImportRow.statusValidated
            : MerchantImportRow.statusPending);
  }

  void _setRejected(MerchantImportRow row, bool rejected) {
    _finishEdit(commit: true);
    _queue.setStatus(
        row.id,
        rejected
            ? MerchantImportRow.statusRejected
            : MerchantImportRow.statusPending);
  }

  // ---------------------------------------------------------------------------
  // Sortie, import, abandon
  // ---------------------------------------------------------------------------

  /// Avant d'importer, d'abandonner ou de fermer : attend la fin des
  /// enregistrements et avertit s'il reste des échecs. `true` si on peut
  /// continuer.
  Future<bool> prepareToLeave({String actionLabel = 'Fermer'}) async {
    _finishEdit(commit: true);
    if (!_queue.isIdle) {
      await LoadingDialog.run(
          context, 'Enregistrement en cours…', _queue.waitUntilIdle);
    }
    if (!mounted) return false;
    final int failed = _queue.failedCount;
    if (failed == 0) return true;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifications non enregistrées'),
        content: Text('$failed modification(s) n\'ont pas pu être '
            'enregistrées. $actionLabel quand même ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler')),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('$actionLabel quand même',
                  style: const TextStyle(color: kRed))),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _back() async {
    if (await prepareToLeave(actionLabel: 'Quitter')) widget.onBack();
  }

  Future<void> _import() async {
    if (_isImporting || !_batch.isEditable) return;
    if (!await prepareToLeave(actionLabel: 'Importer')) return;
    if (!mounted) return;
    final int count = _counts()[_Filter.validated]!;
    if (count == 0) {
      _snack('Aucune ligne validée à importer.', kOrange);
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Importer les lignes validées'),
        content: SizedBox(
          width: 480,
          child: Text(
              '$count commerçant(s) seront ajoutés au réseau. Les lignes '
              'non validées restent dans le lot, vous pourrez les importer plus '
              'tard.'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: kOrange, foregroundColor: kPWhite),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Importer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isImporting = true);
    try {
      final MerchantImportResult result = await LoadingDialog.run(
          context,
          'Import en cours…',
          () => _useCase.importValidated(_batch.id,
              idempotencyKey: _importKey.keyFor('import:${_batch.id}')));
      _importKey.clear();
      if (result.imported > 0) widget.onImported();
      if (!mounted) return;
      if (result.batch != null) setState(() => _batch = result.batch!);
      await _showImportResult(result);
      if (mounted) await _reloadAll();
    } on ApiException catch (e) {
      _importKey.onError(e.code);
      _snack(e.message, kRed);
      if (_isBatchGone(e)) {
        widget.onBack();
      } else if (e.code == 'BATCH_NOT_IMPORTABLE' ||
          e.code == 'IDEMPOTENCY_REQUEST_IN_PROGRESS') {
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) await _reloadAll();
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  Future<void> _showImportResult(MerchantImportResult result) {
    String nameOf(int id) {
      final String name = _rowById(id)?.textOf('name') ?? '';
      return name.isEmpty ? 'Ligne $id' : name;
    }

    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Résultat de l'import"),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  '${result.imported} importé(s), dont ${result.created} '
                  'nouveau(x) commerçant(s).',
                  style: GoogleFonts.poppins(fontSize: 14, color: kBlack)),
              if (result.failed.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('${result.failed.length} ligne(s) en échec :',
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: kRed)),
                const SizedBox(height: 8),
                Flexible(
                  child: SingleChildScrollView(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: kPWhite,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: kRed.withValues(alpha: 0.35)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: result.failed
                            .map((failure) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Padding(
                                        padding:
                                            EdgeInsets.only(top: 2, right: 8),
                                        child: Icon(Icons.error_outline,
                                            size: 16, color: kRed),
                                      ),
                                      Expanded(
                                        child: SelectableText(
                                          '${nameOf(failure.id)} : '
                                          '${failure.error}',
                                          style: GoogleFonts.poppins(
                                              fontSize: 13, color: kBlack),
                                        ),
                                      ),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                ),
              ],
              if (result.skipped.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                    '${result.skipped.length} ligne(s) n\'ont pas été importées '
                    'car elles ont de nouvelles anomalies : elles ont été '
                    'décochées.',
                    style: GoogleFonts.poppins(fontSize: 14, color: kOrange)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer')),
        ],
      ),
    );
  }

  Future<void> _cancelBatch() async {
    if (!_batch.isEditable) return;
    if (!await prepareToLeave(actionLabel: 'Abandonner')) return;
    if (!mounted) return;
    final bool? confirmed = await confirmCancelBatch(context);
    if (confirmed != true || !mounted) return;
    try {
      await _useCase.cancel(_batch.id);
      _snack('Lot abandonné.', kBlue);
      await _reloadBatch();
    } on ApiException catch (e) {
      _snack(e.message, kRed);
      if (_isBatchGone(e)) {
        widget.onBack();
      } else {
        await _reloadBatch();
      }
    }
  }

  void _snack(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 6)));
  }

  // ---------------------------------------------------------------------------
  // Affichage
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: kBlue));
    }
    if (_loadError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SelectableText(_loadError!,
                style: GoogleFonts.poppins(color: kRed)),
            const SizedBox(height: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton.icon(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('Retour aux lots'),
                ),
                TextButton.icon(
                  onPressed: _reloadAll,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Réessayer'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final Map<_Filter, int> counts = _counts();
    final List<MerchantImportRow> filtered = _rows
        .where((row) => _matchesFilter(row, _filter) && _matchesSearch(row))
        .toList();
    final int pageCount =
        filtered.isEmpty ? 1 : (filtered.length / _pageSize).ceil();
    final int page = _page.clamp(0, pageCount - 1);
    final int start = page * _pageSize;
    _pageRows =
        filtered.sublist(start, (start + _pageSize).clamp(0, filtered.length));

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(counts),
          const SizedBox(height: 12),
          _buildFilters(counts),
          ..._buildBanners(),
          const SizedBox(height: 12),
          Expanded(
            child: _pageRows.isEmpty
                ? Center(
                    child: Text(
                        _rows.isEmpty
                            ? 'Ce lot ne contient aucune ligne.'
                            : 'Aucune ligne ne correspond aux filtres.',
                        style: GoogleFonts.poppins(color: kGrey)))
                : _buildGrid(),
          ),
          const SizedBox(height: 8),
          _buildPagination(filtered.length, page, pageCount),
        ],
      ),
    );
  }

  Widget _buildHeader(Map<_Filter, int> counts) {
    final int validated = counts[_Filter.validated]!;
    final String date = formatFrenchDate(_batch.createdDate);
    return Row(
      children: [
        TextButton.icon(
          onPressed: _back,
          icon: const Icon(Icons.arrow_back, size: 18),
          label: const Text('Lots'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SelectableText(
            '${_batch.source ?? 'Lot ${_batch.id}'}'
            '${date.isEmpty ? '' : ' — $date'}',
            maxLines: 1,
            style: GoogleFonts.poppins(
                fontSize: 20, fontWeight: FontWeight.w600, color: kBlue),
          ),
        ),
        _buildSaveIndicator(),
        const SizedBox(width: 12),
        IconButton(
          tooltip: 'Recharger',
          onPressed: _isImporting ? null : _reloadAll,
          icon: const Icon(Icons.refresh, color: kBlue),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
              backgroundColor: kOrange, foregroundColor: kPWhite),
          onPressed: validated > 0 && _editable ? _import : null,
          icon: const Icon(Icons.download_done, size: 18),
          label: Text('Importer les lignes validées ($validated)'),
        ),
        PopupMenuButton<String>(
          tooltip: 'Plus d\'actions',
          enabled: _editable,
          onSelected: (value) {
            if (value == 'cancel') _cancelBatch();
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'cancel',
              child: Text('Abandonner ce lot', style: TextStyle(color: kRed)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSaveIndicator() {
    final int failed = _queue.failedCount;
    final int active = _queue.activeCount;
    final TextStyle style = GoogleFonts.poppins(fontSize: 13);
    if (failed > 0) {
      return Tooltip(
        message: 'Cliquer pour réessayer maintenant',
        child: TextButton.icon(
          onPressed: _queue.retryAll,
          icon: const Icon(Icons.sync_problem, color: kRed, size: 18),
          label: Text('$failed erreur(s) d\'enregistrement',
              style: style.copyWith(color: kRed)),
        ),
      );
    }
    if (active > 0) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
              height: 14,
              width: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: kBlue)),
          const SizedBox(width: 8),
          Text('Enregistrement… ($active)',
              style: style.copyWith(color: kBlue)),
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.cloud_done_outlined, color: kGreen, size: 18),
        const SizedBox(width: 6),
        Text('Enregistré', style: style.copyWith(color: kGreen)),
      ],
    );
  }

  Widget _buildFilters(Map<_Filter, int> counts) {
    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _Filter.values
                .map((filter) => ChoiceChip(
                      label: Text('${filter.label} (${counts[filter]})'),
                      selected: _filter == filter,
                      selectedColor: kBlue,
                      labelStyle: GoogleFonts.poppins(
                          fontSize: 13,
                          color: _filter == filter ? kWhite : kBlueEnd),
                      showCheckmark: false,
                      onSelected: (_) => setState(() {
                        _filter = filter;
                        _page = 0;
                      }),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 280,
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            style: GoogleFonts.poppins(fontSize: 13),
            decoration: const InputDecoration(
              isDense: true,
              hintText: 'Rechercher (nom, ville, SIRET)',
              prefixIcon: Icon(Icons.search, size: 20),
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildBanners() {
    String? text;
    Color color = kOrange;
    if (_batch.isProcessing) {
      text = 'Recherche en cours : ${_batch.progressDone} / '
          '${_batch.progressTotal}. La grille est en lecture seule jusqu\'à la '
          'fin de la recherche.';
      color = kBlue;
    } else if (_batch.isDone) {
      text = 'Import terminé : le lot est en lecture seule.';
      color = kGreen;
    } else if (_batch.isCancelled) {
      text = 'Lot abandonné : il est en lecture seule.';
      color = kGrey;
    } else if (!_batch.isEditable) {
      text = '${_batch.statusLabel} : le lot est en lecture seule.';
    }
    if (text == null) return const [];
    return [
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
                _batch.isDone ? Icons.check_circle_outline : Icons.info_outline,
                color: color,
                size: 20),
            const SizedBox(width: 10),
            Expanded(
                child: Text(text,
                    style: GoogleFonts.poppins(fontSize: 13, color: kBlueEnd))),
          ],
        ),
      ),
    ];
  }

  Widget _buildPagination(int total, int page, int pageCount) {
    final int from = total == 0 ? 0 : page * _pageSize + 1;
    final int to = (page * _pageSize + _pageSize).clamp(0, total);
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('Lignes $from–$to sur $total',
            style: GoogleFonts.poppins(fontSize: 13, color: kGrey)),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Page précédente',
          onPressed: page > 0 ? () => _goToPage(page - 1) : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Text('${page + 1} / $pageCount',
            style: GoogleFonts.poppins(fontSize: 13, color: kBlueEnd)),
        IconButton(
          tooltip: 'Page suivante',
          onPressed: page < pageCount - 1 ? () => _goToPage(page + 1) : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  void _goToPage(int page) {
    _finishEdit(commit: true);
    setState(() => _page = page);
    if (_vertical.hasClients) _vertical.jumpTo(0);
  }

  /// En-tête figé en haut ; défilement horizontal commun à l'en-tête et au
  /// corps, défilement vertical du corps seul. La barre verticale reste
  /// visible au bord droit quel que soit le défilement horizontal.
  Widget _buildGrid() {
    return LayoutBuilder(
      builder: (context, constraints) => Scrollbar(
        controller: _vertical,
        thumbVisibility: true,
        notificationPredicate: (notification) => notification.depth == 1,
        child: Scrollbar(
          controller: _horizontal,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _horizontal,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: _tableWidth,
              height: constraints.maxHeight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderTable(),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _vertical,
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Table(
                        columnWidths: _tableColumnWidths,
                        defaultVerticalAlignment:
                            TableCellVerticalAlignment.middle,
                        border: TableBorder(
                            horizontalInside: BorderSide(
                                color: kLBlue.withValues(alpha: 0.5))),
                        children: [
                          for (int i = 0; i < _pageRows.length; i++)
                            _buildRow(_pageRows[i], i),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderTable() {
    Widget label(String text, {String? hint}) {
      final Widget child = Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Text(text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
                fontSize: 13, fontWeight: FontWeight.w600, color: kWhite)),
      );
      return hint == null ? child : Tooltip(message: hint, child: child);
    }

    return Table(
      columnWidths: _tableColumnWidths,
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          decoration: const BoxDecoration(color: kBlue),
          children: [
            label('', hint: 'Cochez les lignes une par une une fois relues.'),
            label('⚠', hint: 'Anomalies de la ligne'),
            ..._fieldColumns
                .map((column) => label(column.label, hint: column.hint)),
            label(''),
          ],
        ),
      ],
    );
  }

  TableRow _buildRow(MerchantImportRow row, int index) {
    final String status = _statusOf(row);
    final bool rowEditable = _rowEditable(row);
    final bool struck = status == MerchantImportRow.statusRejected;

    Color? background;
    if (status == MerchantImportRow.statusImported) {
      background = kGreen.withValues(alpha: 0.12);
    } else if (status == MerchantImportRow.statusRejected) {
      background = Colors.grey.withValues(alpha: 0.12);
    } else if (status == MerchantImportRow.statusValidated) {
      background = kGreen.withValues(alpha: 0.06);
    } else if (index.isOdd) {
      background = kLBlue.withValues(alpha: 0.10);
    }

    return TableRow(
      decoration: BoxDecoration(
        color: background,
        border: status == MerchantImportRow.statusFailed
            ? const Border(left: BorderSide(color: kRed, width: 3))
            : null,
      ),
      children: [
        _checkCell(row, status),
        _warningCell(row),
        ..._fieldColumns
            .map((column) => _fieldCell(row, column, rowEditable, struck)),
        _actionsCell(row, status),
      ],
    );
  }

  Widget _checkCell(MerchantImportRow row, String status) {
    if (status == MerchantImportRow.statusImported) {
      return const SizedBox(
        height: _rowHeight,
        child: Tooltip(
            message: 'Importé',
            child: Icon(Icons.check_circle, color: kGreen, size: 22)),
      );
    }
    final bool checked = status == MerchantImportRow.statusValidated;
    final List<MerchantImportIssue> blocking = row.blockingIssues;
    // Une ligne cochée qui serait devenue bloquante reste décochable.
    final bool enabled = _editable &&
        status != MerchantImportRow.statusRejected &&
        (blocking.isEmpty || checked);

    Widget box = Checkbox(
      value: checked,
      activeColor: kGreen,
      onChanged:
          enabled ? (value) => _toggleValidated(row, value == true) : null,
    );
    if (blocking.isNotEmpty && !checked) {
      box = Tooltip(
        message: 'À corriger avant validation :\n'
            '${blocking.map((issue) => '• ${issue.message}').join('\n')}',
        child: box,
      );
    }
    return SizedBox(
      height: _rowHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          box,
          _saveBadge(row.id, RowSaveQueue.statusField),
        ],
      ),
    );
  }

  /// Anomalies sans colonne visible (ou de la ligne entière) et erreur d'import.
  Widget _warningCell(MerchantImportRow row) {
    final List<MerchantImportIssue> issues = row.issues
        .where((issue) =>
            issue.field == null || !_visibleFields.contains(issue.field))
        .toList();
    final List<String> lines = [
      if (row.isFailed && (row.error ?? '').isNotEmpty)
        'Échec de l\'import : ${row.error}',
      ...issues.map((issue) => issue.message),
    ];
    if (lines.isEmpty) return const SizedBox(height: _rowHeight);

    final bool error = (row.isFailed && (row.error ?? '').isNotEmpty) ||
        issues.any((issue) => issue.isError);
    final bool warning = issues.any((issue) => issue.isWarning);
    return SizedBox(
      height: _rowHeight,
      child: Tooltip(
        message: lines.join('\n'),
        child: Icon(
          error
              ? Icons.error
              : warning
                  ? Icons.warning_amber_rounded
                  : Icons.info_outline,
          color: error
              ? kRed
              : warning
                  ? kOrange
                  : kBlue,
          size: 20,
        ),
      ),
    );
  }

  Widget _fieldCell(MerchantImportRow row, _GridColumn column, bool rowEditable,
      bool struck) {
    final String field = column.key;
    final List<MerchantImportIssue> issues = row.issuesFor(field);
    final bool hasError = issues.any((issue) => issue.isError);
    final bool hasWarning = issues.any((issue) => issue.isWarning);
    final bool hasInfo = issues.any((issue) => issue.isInfo);
    final bool pending = _queue.hasPending(row.id, field);
    final bool modified = !pending && row.isModified(field);
    final bool aiValue = !pending && row.isAiValue(field);
    final String? source = row.sourceOf(field);
    final bool editable = rowEditable && column.editor != _Editor.readOnly;
    final bool editing = _isEditing(row, field);
    final RowEditState? saveState = _queue.stateOf(row.id, field);

    final List<String> tooltip = [
      ...issues.map((issue) => issue.message),
      if (modified)
        () {
          final String original = _typeLabel(field, row.originalOf(field));
          return 'Valeur d\'origine : ${original.isEmpty ? '(vide)' : original}';
        }(),
      if (source != null) 'Source : $source',
      if (saveState == RowEditState.failed)
        'Enregistrement impossible : cliquez sur l\'icône pour réessayer.',
    ];

    final Widget content;
    if (editing) {
      final _EditingCell cell = _editing!;
      content = Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: (_, event) => _onEditKey(cell, event),
        child: TextField(
          controller: cell.controller,
          focusNode: cell.focusNode,
          autofocus: true,
          keyboardType: column.numeric
              ? const TextInputType.numberWithOptions(
                  decimal: true, signed: true)
              : TextInputType.text,
          onSubmitted: (_) {
            if (identical(_editing, cell)) _finishEdit(commit: true);
          },
          onTapOutside: (_) {
            if (identical(_editing, cell)) _finishEdit(commit: true);
          },
          style: GoogleFonts.poppins(fontSize: 13, color: kBlueEnd),
          decoration: const InputDecoration(
            isDense: true,
            filled: true,
            fillColor: kPWhite,
            contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 10),
            border: OutlineInputBorder(),
            focusedBorder:
                OutlineInputBorder(borderSide: BorderSide(color: kBlue)),
          ),
        ),
      );
    } else {
      content = Align(
        alignment: Alignment.centerLeft,
        child: Text(
          _typeLabel(field, _displayValue(row, field)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
              fontSize: 13,
              color: struck ? kGrey : kBlueEnd,
              decoration: struck ? TextDecoration.lineThrough : null),
        ),
      );
    }

    Widget cell = Container(
      height: _rowHeight - 4,
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
      padding: EdgeInsets.symmetric(horizontal: editing ? 0 : 6),
      decoration: BoxDecoration(
        color: hasError
            ? kRed.withValues(alpha: 0.08)
            : aiValue
                ? kOrange.withValues(alpha: 0.06)
                : null,
        border: hasError
            ? Border.all(color: kRed)
            : hasWarning
                ? Border.all(color: kOrange)
                : null,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: content),
          if (modified && !editing)
            Positioned(
              left: -4,
              top: 0,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: editable
                    ? (details) =>
                        _offerRevert(row, field, details.globalPosition)
                    : null,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration:
                      const BoxDecoration(color: kBlue, shape: BoxShape.circle),
                ),
              ),
            ),
          if (hasInfo && !editing)
            const Positioned(
              right: 0,
              bottom: 2,
              child: Icon(Icons.info_outline, color: kBlue, size: 12),
            ),
          _saveBadge(row.id, field),
        ],
      ),
    );

    if (!editing && tooltip.isNotEmpty) {
      cell = Tooltip(
        message: tooltip.join('\n'),
        waitDuration: const Duration(milliseconds: 400),
        child: cell,
      );
    }
    if (!editing && editable) {
      cell = MouseRegion(
        cursor: column.editor == _Editor.type
            ? SystemMouseCursors.click
            : SystemMouseCursors.text,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: column.editor == _Editor.type
              ? (details) => _pickType(row, details.globalPosition)
              : (_) => _startEdit(row, column),
          child: cell,
        ),
      );
    }
    return cell;
  }

  /// Petit indicateur d'enregistrement dans le coin d'une cellule.
  Widget _saveBadge(int rowId, String field) {
    switch (_queue.stateOf(rowId, field)) {
      case RowEditState.queued:
      case RowEditState.saving:
        return const Positioned(
          right: 1,
          top: 1,
          child: SizedBox(
              height: 12,
              width: 12,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: kBlue)),
        );
      case RowEditState.failed:
        return Positioned(
          right: 0,
          top: 0,
          child: Tooltip(
            message: 'Enregistrement impossible : cliquer pour réessayer.',
            child: InkWell(
              onTap: () => _queue.retry(rowId, field),
              child: const Icon(Icons.sync_problem, color: kRed, size: 14),
            ),
          ),
        );
      case null:
        return const SizedBox.shrink();
    }
  }

  Widget _actionsCell(MerchantImportRow row, String status) {
    if (status == MerchantImportRow.statusImported) {
      return const SizedBox(height: _rowHeight);
    }
    final bool rejected = status == MerchantImportRow.statusRejected;
    return SizedBox(
      height: _rowHeight,
      child: Center(
        child: TextButton(
          style: TextButton.styleFrom(
            foregroundColor: rejected ? kBlue : kRed,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            textStyle: GoogleFonts.poppins(fontSize: 12),
          ),
          onPressed: _editable ? () => _setRejected(row, !rejected) : null,
          child: Text(rejected ? 'Rétablir' : 'Écarter'),
        ),
      ),
    );
  }

  /// Libellé de la colonne Type ; texte brut pour les autres colonnes.
  static String _typeLabel(String field, dynamic value) {
    final String text = MerchantImportRow.displayText(value);
    if (field != 'type') return text;
    switch (text) {
      case _typePartner:
        return 'Commerçant';
      case _typeCustomer:
        return 'Client';
      default:
        return text;
    }
  }
}

/// Confirmation avant d'abandonner un lot (liste des lots et grille).
Future<bool?> confirmCancelBatch(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Abandonner ce lot'),
      content: const SizedBox(
        width: 460,
        child: Text('Le lot ne pourra plus être modifié ni importé. Les '
            'commerçants déjà importés restent dans le réseau.'),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler')),
        TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Abandonner', style: TextStyle(color: kRed))),
      ],
    ),
  );
}
