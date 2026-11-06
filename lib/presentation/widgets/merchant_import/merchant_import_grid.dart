import 'package:back_office_tribuneo_v2/presentation/widgets/tribuneo_loader.dart';
import '../merchant_enrichment/ui/enrichment_dialog.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/arc/arc.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:back_office_tribuneo_v2/core/utils/idempotency_key.dart';
import 'package:back_office_tribuneo_v2/data/local/merchant_import_view_store.dart';
import 'package:back_office_tribuneo_v2/domain/errors/api_exception.dart';
import 'package:back_office_tribuneo_v2/domain/errors/merchant_import_exceptions.dart';
import 'package:back_office_tribuneo_v2/domain/errors/merchant_enrichment_messages.dart';
import 'package:back_office_tribuneo_v2/domain/models/merchant_import_batch_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/merchant_import_row_model.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/merchant_import_usecase.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/formatters.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/loading.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/merchant_import/row_save_queue.dart';
import 'package:back_office_tribuneo_v2/domain/repositories/merchant_enrichment/enrichment_repository.dart';
import 'package:back_office_tribuneo_v2/domain/repositories/merchant_enrichment/tribuneo_enrichment_transport.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/merchant_enrichment/enrichment_usecase.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/merchant_enrichment/enrichment_panel.dart';

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
  final EnrichmentTransport? enrichmentTransport;
  final bool enrichmentEnabled;

  /// Mémorisation de la vue (filtre, recherche, page) ; remplaçable dans les
  /// tests.
  final MerchantImportViewStore? viewStore;

  const MerchantImportGrid({
    super.key,
    required this.batch,
    required this.onBack,
    required this.onImported,
    this.useCase,
    this.enrichmentTransport,
    this.enrichmentEnabled = merchantEnrichmentEnabled,
    this.viewStore,
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
  enriched('Complétées par la recherche'),
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
  late final EnrichmentUseCase _enrichment;
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

  late final MerchantImportViewStore _viewStore =
      widget.viewStore ?? SecureMerchantImportViewStore();
  Timer? _viewSaveDebounce;

  /// L'utilisateur a déjà changé la vue : la vue mémorisée, lue ensuite, ne
  /// l'écrase pas.
  bool _viewTouched = false;

  _EditingCell? _editing;
  Timer? _editDebounce;
  Timer? _pollTimer;

  /// Volet figé à gauche (case, statut, nom) et volet défilant à droite :
  /// défilement vertical synchronisé, horizontal propre au volet droit.
  final ScrollController _leftVertical = ScrollController();
  final ScrollController _rightVertical = ScrollController();
  final ScrollController _horizontal = ScrollController();
  bool _syncingScroll = false;

  /// Ligne survolée, surlignée dans les deux volets pour la suivre d'un bout
  /// à l'autre.
  final ValueNotifier<int?> _hoveredRowId = ValueNotifier<int?>(null);

  /// Ligne courante pour le clavier (↑ ↓, Espace, E, Entrée), repérée dans
  /// les deux volets.
  final ValueNotifier<int?> _cursorRowId = ValueNotifier<int?>(null);
  final FocusNode _gridFocus = FocusNode(debugLabel: 'merchant-import-grid');

  static const int _pageSize = 50;
  static const double _rowHeight = 52;

  /// Trait vertical entre les colonnes, pour suivre une ligne.
  static final Border _cellSeparator =
      Border(right: BorderSide(color: kBorder));
  static final Border _headerSeparator =
      Border(right: BorderSide(color: kBorder));
  static const double _headerHeight = 44;
  static const String _typePartner = 'partner';
  static const String _typeCustomer = 'customer';

  static const double _accentWidth = 3;
  static const double _checkWidth = 44;
  static const double _statusWidth = 140;
  static const double _nameWidth = 240;
  static const double _actionsWidth = 96;
  static const double _leftWidth =
      _accentWidth + _checkWidth + _statusWidth + _nameWidth;

  /// Champs dont l'absence bloque la validation (le SIRET, pour un commerçant
  /// seulement). Source : `MerchantImportValidator` de l'API.
  static const Set<String> _requiredFields = {'name', 'type', 'email', 'siret'};

  static const _GridColumn _nameColumn = _GridColumn('name', 'Nom', _nameWidth);

  /// Colonnes du volet droit, dans l'ordre.
  static const List<_GridColumn> _scrollColumns = [
    _GridColumn('type', 'Type', 120,
        editor: _Editor.type, hint: 'Commerçant ou client.'),
    _GridColumn('siret', 'SIRET', 150),
    _GridColumn('email', 'Email', 210),
    _GridColumn('phone', 'Téléphone', 130),
    _GridColumn('street', 'Adresse', 220),
    _GridColumn('zip', 'CP', 80),
    _GridColumn('city', 'Ville', 150),
    _GridColumn('country', 'Pays', 100),
    _GridColumn('lat', 'Latitude', 125,
        numeric: true,
        hint: "Sans coordonnées, le commerçant n'apparaît pas sur la carte."),
    _GridColumn('lng', 'Longitude', 125, numeric: true),
    _GridColumn('activity_sectors', 'Secteurs', 180,
        hint: 'Plusieurs secteurs : séparez-les par « / ».'),
    _GridColumn('code', 'Code', 110, hint: "Vide : généré à l'import."),
    _GridColumn('intracommunity_vat_number', 'TVA intracom.', 150),
    _GridColumn('iban', 'IBAN', 240),
    _GridColumn('bic', 'BIC', 110),
    _GridColumn('bank_key', 'Clé RIB', 80),
    _GridColumn('account_number', 'N° comptable', 120),
    _GridColumn('naf', 'NAF', 90,
        editor: _Editor.readOnly, hint: 'Rempli par la recherche automatique.'),
  ];

  /// Champs affichés dans la grille.
  static final List<String> _fieldKeys =
      [_nameColumn, ..._scrollColumns].map((column) => column.key).toList();

  /// Colonnes texte, dans l'ordre de navigation au clavier (Tab).
  static final List<_GridColumn> _textColumns = [_nameColumn, ..._scrollColumns]
      .where((column) => column.editor == _Editor.text)
      .toList();

  static final double _rightWidth =
      _scrollColumns.fold<double>(0, (sum, column) => sum + column.width) +
          _actionsWidth;

  @override
  void initState() {
    super.initState();
    _batch = widget.batch;
    _enrichment = EnrichmentUseCase(
      repository: EnrichmentRepository(
          widget.enrichmentTransport ?? TribuneoEnrichmentTransport()),
      batchId: _batch.id,
      enabled: widget.enrichmentEnabled,
      currentRow: _rowById,
      batchEditable: () =>
          _editable && _queue.isIdle && _queue.failedCount == 0,
      replaceRows: (rows) {
        if (mounted) setState(() => _replaceRows(rows));
      },
      // The enrichment session checks its pinned tenant again before publishing.
      reloadRows: () => _useCase.getRows(_batch.id),
    );
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
    _leftVertical.addListener(() => _syncScroll(_leftVertical, _rightVertical));
    _rightVertical
        .addListener(() => _syncScroll(_rightVertical, _leftVertical));
    _reloadAll();
    _restoreView();
  }

  @override
  void dispose() {
    _enrichment.dispose();
    _queue.dispose();
    _searchDebounce?.cancel();
    _viewSaveDebounce?.cancel();
    _editDebounce?.cancel();
    _pollTimer?.cancel();
    _editing?.dispose();
    _searchController.dispose();
    _leftVertical.dispose();
    _rightVertical.dispose();
    _horizontal.dispose();
    _hoveredRowId.dispose();
    _cursorRowId.dispose();
    _gridFocus.dispose();
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
      case _Filter.enriched:
        return _fieldKeys.any(row.isAiValue);
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

  List<MerchantImportRow> _filteredRows() => _rows
      .where((row) => _matchesFilter(row, _filter) && _matchesSearch(row))
      .toList();

  // ---------------------------------------------------------------------------
  // Vue mémorisée (filtre, recherche, page)
  // ---------------------------------------------------------------------------

  Future<void> _restoreView() async {
    Map<String, dynamic>? saved;
    try {
      saved = await _viewStore.read(_batch.id);
    } catch (_) {
      return; // Stockage indisponible : vue par défaut.
    }
    if (saved == null || !mounted || _viewTouched) return;
    final _Filter filter = _Filter.values.firstWhere(
        (f) => f.name == saved!['filter'],
        orElse: () => _Filter.all);
    final String search =
        saved['search'] is String ? saved['search'] as String : '';
    final int page = saved['page'] is int ? saved['page'] as int : 0;
    setState(() {
      _filter = filter;
      _search = search.trim();
      _searchController.text = search;
      _page = page < 0 ? 0 : page;
    });
  }

  /// Mémorise la vue après un changement (filtre, recherche, page).
  void _viewChanged() {
    _viewTouched = true;
    _viewSaveDebounce?.cancel();
    _viewSaveDebounce = Timer(const Duration(milliseconds: 400), () {
      _viewStore.save(_batch.id, {
        'filter': _filter.name,
        'search': _search,
        'page': _page,
      }).catchError((Object _) {});
    });
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
      _viewChanged();
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
    // `autofocus` est ignoré quand la grille a déjà le focus clavier.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && identical(_editing, editing)) {
        editing.focusNode.requestFocus();
      }
    });
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
      _returnToGrid();
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
  // Clavier
  // ---------------------------------------------------------------------------

  /// La case de validation est-elle cochable pour [row] ? Mêmes règles que la
  /// case à cocher de la grille.
  bool _canToggleValidated(MerchantImportRow row) {
    final String status = _statusOf(row);
    final bool checked = status == MerchantImportRow.statusValidated;
    return _editable &&
        status != MerchantImportRow.statusImported &&
        status != MerchantImportRow.statusRejected &&
        (row.blockingIssues.isEmpty || checked);
  }

  /// Ligne sous le pointeur : elle devient la ligne courante du clavier.
  void _pointRow(int rowId) {
    _cursorRowId.value = rowId;
    if (_editing == null && !_gridFocus.hasFocus) _gridFocus.requestFocus();
  }

  void _moveCursor(int delta) {
    final List<MerchantImportRow> rows = _pageRows;
    if (rows.isEmpty) return;
    final int current = rows.indexWhere((r) => r.id == _cursorRowId.value);
    final int next = current < 0
        ? (delta > 0 ? 0 : rows.length - 1)
        : (current + delta).clamp(0, rows.length - 1);
    _cursorRowId.value = rows[next].id;
    _revealRow(next);
  }

  /// Fait défiler la grille pour montrer la ligne d'index [index].
  void _revealRow(int index) {
    if (!_rightVertical.hasClients) return;
    final ScrollPosition position = _rightVertical.position;
    final double top = index * _rowHeight;
    final double bottom = top + _rowHeight;
    if (top < position.pixels) {
      _rightVertical.jumpTo(top);
    } else if (bottom > position.pixels + position.viewportDimension) {
      _rightVertical.jumpTo((bottom - position.viewportDimension)
          .clamp(0, position.maxScrollExtent));
    }
  }

  KeyEventResult _onGridKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (_editing != null) return KeyEventResult.ignored;
    final LogicalKeyboardKey key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown) {
      _moveCursor(1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      _moveCursor(-1);
      return KeyEventResult.handled;
    }
    if (event is KeyRepeatEvent) return KeyEventResult.ignored;
    if (key == LogicalKeyboardKey.keyN) {
      _goToNextIssue();
      return KeyEventResult.handled;
    }
    final MerchantImportRow? row =
        _cursorRowId.value == null ? null : _rowById(_cursorRowId.value!);
    if (row == null) return KeyEventResult.ignored;
    final String status = _statusOf(row);
    if (key == LogicalKeyboardKey.space) {
      if (_canToggleValidated(row)) {
        _toggleValidated(row, status != MerchantImportRow.statusValidated);
      } else if (row.blockingIssues.isNotEmpty) {
        _snack('Ligne ${row.position} : à corriger avant validation.', kOrange);
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyE) {
      if (_editable && status != MerchantImportRow.statusImported) {
        _setRejected(row, status != MerchantImportRow.statusRejected);
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.f2) {
      _startEdit(row, _textColumns.first);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      _cursorRowId.value = null;
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// Après Entrée ou Échap dans une cellule, le clavier revient à la grille.
  void _returnToGrid() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _editing == null) _gridFocus.requestFocus();
    });
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
      builder: (context) => EnrichmentDialog(
        maxWidth: 600,
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
                  style: const TextStyle(color: kBlueEnd))),
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
      builder: (context) => EnrichmentDialog(
        maxWidth: 600,
        title: const Text('Importer les lignes validées'),
        content: SizedBox(
          width: double.infinity,
          child: Text(
              '$count commerçant(s) seront ajoutés au réseau. Les lignes '
              'non validées restent dans le lot, vous pourrez les importer plus '
              'tard.'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler')),
          FilledButton(
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
      builder: (context) => EnrichmentDialog(
        maxWidth: 600,
        title: const Text("Résultat de l'import"),
        content: SizedBox(
          width: double.infinity,
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
                        color: kBlueEnd)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 240,
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
                                          '${MerchantEnrichmentMessages.importFailure(failure.error)}',
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
                EnrichmentNotice(
                    child: Text(
                        '${result.skipped.length} ligne(s) n\'ont pas été importées '
                        'car elles ont de nouvelles anomalies : elles ont été '
                        'décochées.',
                        style: GoogleFonts.poppins(
                            fontSize: 14, color: kBlueEnd))),
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
      return const Center(child: TribuneoLoader());
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
    final List<MerchantImportRow> filtered = _filteredRows();
    final int pageCount =
        filtered.isEmpty ? 1 : (filtered.length / _pageSize).ceil();
    final int page = _page.clamp(0, pageCount - 1);
    final int start = page * _pageSize;
    _pageRows =
        filtered.sublist(start, (start + _pageSize).clamp(0, filtered.length));

    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 36, 40, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(counts),
          const SizedBox(height: 10),
          _buildProgress(counts),
          EnrichmentButton(
            session: _enrichment,
            rows: () => _rows,
            // Point posé sur la carte : saisie manuelle des deux cellules.
            onSetPosition: (rowId, point) async {
              _finishEdit(commit: true);
              _queue.editField(rowId, 'lat', point.lat.toStringAsFixed(6));
              _queue.editField(rowId, 'lng', point.lng.toStringAsFixed(6));
              await _queue.waitUntilIdle();
              return mounted && _queue.failedCount == 0;
            },
            prepare: () async {
              _finishEdit(commit: true);
              if (!_queue.isIdle) {
                await LoadingDialog.run(
                    context, 'Enregistrement en cours…', _queue.waitUntilIdle);
              }
              if (!mounted) return false;
              if (_queue.failedCount > 0) {
                _snack(
                    'Enregistrez les corrections avant de compléter les informations.',
                    kOrange);
                return false;
              }
              return true;
            },
          ),
          const SizedBox(height: 12),
          _buildFilters(counts),
          ..._buildBanners(),
          const SizedBox(height: 12),
          _buildLegend(),
          const SizedBox(height: 10),
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
    return ArcPageHeader(
      leading: TextButton.icon(
        onPressed: _back,
        icon: const Icon(Icons.arrow_back, size: 18),
        label: const Text('Lots'),
      ),
      title: 'Relecture du lot',
      subtitle: SelectableText(
        '${_batch.source ?? 'Lot ${_batch.id}'}'
        '${date.isEmpty ? '' : ' — $date'}',
        maxLines: 1,
        style: ArcText.dataSmall(),
      ),
      actions: [
        ArcPill(_batch.statusLabel,
            tone: _batch.isDone ? ArcTone.success : ArcTone.info,
            icon: _batch.isDone
                ? Icons.check_circle_outline
                : Icons.info_outline),
        _buildSaveIndicator(),
        IconButton(
          tooltip: 'Recharger',
          onPressed: _isImporting ? null : _reloadAll,
          icon: const Icon(Icons.refresh_rounded),
        ),
        FilledButton.icon(
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

  /// Avancement de la relecture du lot, et accès à la prochaine ligne à
  /// corriger.
  Widget _buildProgress(Map<_Filter, int> counts) {
    final int total = counts[_Filter.all]!;
    if (total == 0) return const SizedBox.shrink();
    final int imported = counts[_Filter.imported]!;
    final int validated = counts[_Filter.validated]!;
    final int rejected = counts[_Filter.rejected]!;
    final int errors = counts[_Filter.errors]!;
    final int done = imported + validated + rejected;
    final List<(int, Color, String)> segments = [
      (imported, kGreen, 'importée'),
      (validated, kGreen.withValues(alpha: 0.45), 'validée'),
      (rejected, kGrey.withValues(alpha: 0.35), 'écartée'),
      (total - done, kLBlue.withValues(alpha: 0.35), 'à relire'),
    ];
    final TextStyle small = GoogleFonts.poppins(fontSize: 12, color: kGrey);
    String plural(int n, String word) => '$n $word${n > 1 ? 's' : ''}';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Avancement : $done / $total lignes traitées',
                  key: const ValueKey('grid-progress'),
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: kBlueEnd)),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 8,
                  child: Row(children: [
                    for (final (int n, Color color, String _) in segments)
                      if (n > 0)
                        Expanded(flex: n, child: ColoredBox(color: color)),
                  ]),
                ),
              ),
              const SizedBox(height: 4),
              Wrap(spacing: 14, runSpacing: 2, children: [
                for (final (int n, Color color, String word) in segments)
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                            color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text(word == 'à relire' ? '$n à relire' : plural(n, word),
                        style: small),
                  ]),
              ]),
            ],
          ),
        ),
        if (errors > 0) ...[
          const SizedBox(width: 16),
          Tooltip(
            message: 'Raccourci clavier : N',
            child: OutlinedButton.icon(
              key: const ValueKey('next-issue'),
              style: OutlinedButton.styleFrom(
                  foregroundColor: kRed,
                  side: BorderSide(color: kRed.withValues(alpha: 0.5))),
              onPressed: _goToNextIssue,
              icon: const Icon(Icons.error_outline, size: 18),
              label: Text('Prochaine à corriger ($errors)'),
            ),
          ),
        ],
      ],
    );
  }

  /// Ligne en anomalie suivant la ligne courante (en boucle), sur toutes les
  /// pages : elle devient la ligne courante et sa première cellule fautive
  /// s'ouvre.
  void _goToNextIssue() {
    _finishEdit(commit: true);
    List<MerchantImportRow> rows = _filteredRows();
    if (!rows.any(_hasAnomaly) && _rows.any(_hasAnomaly)) {
      // Masquées par le filtre ou la recherche : on affiche les anomalies.
      _filter = _Filter.errors;
      _search = '';
      _searchController.clear();
      rows = _filteredRows();
    }
    final int start = rows.indexWhere((r) => r.id == _cursorRowId.value);
    int index = -1;
    for (var i = 1; i <= rows.length; i++) {
      final int candidate = (start + i) % rows.length;
      if (_hasAnomaly(rows[candidate])) {
        index = candidate;
        break;
      }
    }
    if (index < 0) {
      _snack('Aucune ligne à corriger.', kGreen);
      return;
    }
    final MerchantImportRow target = rows[index];
    setState(() => _page = index ~/ _pageSize);
    _viewChanged();
    _cursorRowId.value = target.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _revealRow(index % _pageSize);
      final MerchantImportIssue? issue = target.blockingIssues
          .where((issue) => issue.field != null)
          .firstOrNull;
      if (issue != null) {
        _jumpToIssue(target, issue);
      } else {
        _gridFocus.requestFocus();
      }
    });
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
              child: TribuneoLoader()),
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
                .where((filter) =>
                    filter != _Filter.enriched ||
                    counts[filter]! > 0 ||
                    _filter == filter)
                .map((filter) => ChoiceChip(
                      label: Text('${filter.label} (${counts[filter]})'),
                      selected: _filter == filter,
                      selectedColor: kNavy100,
                      backgroundColor: kSurface,
                      side: BorderSide(
                          color: _filter == filter ? kNavy300 : kBorder),
                      labelStyle: GoogleFonts.poppins(
                          fontSize: 13,
                          color: _filter == filter ? kNavy900 : kText2),
                      showCheckmark: false,
                      onSelected: (_) {
                        setState(() {
                          _filter = filter;
                          _page = 0;
                        });
                        _viewChanged();
                      },
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
    return ArcPagination(
      label: 'Lignes $from–$to sur $total',
      leading: Text('${page + 1} / $pageCount', style: ArcText.dataSmall()),
      onPrevious: page > 0 ? () => _goToPage(page - 1) : null,
      onNext: page < pageCount - 1 ? () => _goToPage(page + 1) : null,
    );
  }

  void _goToPage(int page) {
    _finishEdit(commit: true);
    setState(() => _page = page);
    _viewChanged();
    if (_leftVertical.hasClients) _leftVertical.jumpTo(0);
  }

  /// Garde les deux volets à la même hauteur de défilement.
  void _syncScroll(ScrollController from, ScrollController to) {
    if (_syncingScroll || !from.hasClients || !to.hasClients) return;
    final double offset = from.offset.clamp(0, to.position.maxScrollExtent);
    if (offset == to.offset) return;
    _syncingScroll = true;
    to.jumpTo(offset);
    _syncingScroll = false;
  }

  /// Amène la colonne de [issue] à l'écran et ouvre la cellule en édition.
  void _jumpToIssue(MerchantImportRow row, MerchantImportIssue issue) {
    final String? field = issue.field;
    if (field == null) return;
    _GridColumn? column;
    double offset = 0;
    if (field == _nameColumn.key) {
      column = _nameColumn;
    } else {
      for (final _GridColumn candidate in _scrollColumns) {
        if (candidate.key == field) {
          column = candidate;
          break;
        }
        offset += candidate.width;
      }
      if (column != null && _horizontal.hasClients) {
        _horizontal.animateTo(
            (offset - 40).clamp(0, _horizontal.position.maxScrollExtent),
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut);
      }
    }
    if (column != null) _startEdit(row, column);
  }

  /// Légende des repères de la grille.
  Widget _buildLegend() {
    final TextStyle style = GoogleFonts.poppins(fontSize: 12, color: kGrey);
    Widget item(Widget marker, String text) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            marker,
            const SizedBox(width: 6),
            Text(text, style: style)
          ],
        );
    return Wrap(
      spacing: 24,
      runSpacing: 6,
      children: [
        item(const Icon(Icons.error_outline, color: kRed, size: 16),
            'À corriger : la ligne ne peut pas être validée'),
        item(const Icon(Icons.warning_amber_rounded, color: kOrange, size: 16),
            'À vérifier : n\'empêche pas l\'import'),
        item(
            CustomPaint(
                size: const Size(10, 10), painter: _CornerMarkerPainter(kBlue)),
            'Modifié par rapport au fichier'),
        item(
            Text('*',
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w700, color: kOrange)),
            'Obligatoire'),
        item(const Icon(Icons.mouse_outlined, color: kGrey, size: 16),
            'Survolez une cellule ou un statut pour le détail'),
        Tooltip(
          message: 'Cliquez sur une ligne, puis :\n'
              '↑ ↓  ligne précédente / suivante\n'
              'Espace  valider / dévalider la ligne\n'
              'E  écarter / rétablir la ligne\n'
              'Entrée  modifier (Tab : cellule suivante)\n'
              'N  prochaine ligne à corriger\n'
              'Échap  quitter la cellule ou la ligne',
          child: item(
              const Icon(Icons.keyboard_outlined, color: kGrey, size: 16),
              'Raccourcis clavier'),
        ),
      ],
    );
  }

  /// Volet figé à gauche (case, statut, nom) et volet défilant à droite. Le
  /// défilement vertical est synchronisé ; la ligne survolée ou en cours
  /// d'édition est surlignée dans les deux volets.
  Widget _buildGrid() {
    final ScrollBehavior noScrollbars =
        ScrollConfiguration.of(context).copyWith(scrollbars: false);
    const EdgeInsets listPadding = EdgeInsets.only(bottom: 14);

    final Widget leftPane = Column(
      children: [
        _headerRow([
          const SizedBox(width: _accentWidth),
          _headerCell('', _checkWidth,
              hint: 'Cochez les lignes une par une, une fois relues.'),
          _headerCell('Statut', _statusWidth,
              hint: 'Survolez le statut pour la liste des anomalies ; '
                  'cliquez dessus pour aller à la première à corriger.'),
          _headerCell(_nameColumn.label, _nameColumn.width,
              required: _requiredHint(_nameColumn.key)),
        ]),
        Expanded(
          child: ScrollConfiguration(
            behavior: noScrollbars,
            child: ListView.builder(
              controller: _leftVertical,
              padding: listPadding,
              itemExtent: _rowHeight,
              itemCount: _pageRows.length,
              itemBuilder: (context, i) => _leftRow(_pageRows[i], i),
            ),
          ),
        ),
      ],
    );

    return Focus(
      focusNode: _gridFocus,
      onKeyEvent: _onGridKey,
      child: ArcTableCard(
          child: Expanded(
        child: LayoutBuilder(
          builder: (context, constraints) => Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: _leftWidth),
                child: Scrollbar(
                  controller: _rightVertical,
                  thumbVisibility: true,
                  notificationPredicate: (notification) =>
                      notification.depth == 1,
                  child: Scrollbar(
                    controller: _horizontal,
                    thumbVisibility: true,
                    child: ScrollConfiguration(
                      behavior: noScrollbars,
                      child: SingleChildScrollView(
                        controller: _horizontal,
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: _rightWidth,
                          height: constraints.maxHeight,
                          child: Column(
                            children: [
                              _headerRow([
                                ..._scrollColumns.map((column) => _headerCell(
                                    column.label, column.width,
                                    hint: column.hint,
                                    required: _requiredHint(column.key))),
                                _headerCell('', _actionsWidth),
                              ]),
                              Expanded(
                                child: ListView.builder(
                                  controller: _rightVertical,
                                  padding: listPadding,
                                  itemExtent: _rowHeight,
                                  itemCount: _pageRows.length,
                                  itemBuilder: (context, i) =>
                                      _rightRow(_pageRows[i], i),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Le volet figé passe au-dessus, avec une ombre dès que le volet
              // droit a défilé.
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: _leftWidth,
                child: AnimatedBuilder(
                  animation: _horizontal,
                  builder: (context, child) => DecoratedBox(
                    decoration: BoxDecoration(
                      color: kPWhite,
                      border: Border(
                          right:
                              BorderSide(color: kLBlue.withValues(alpha: 0.9))),
                      boxShadow:
                          _horizontal.hasClients && _horizontal.offset > 0
                              ? [
                                  BoxShadow(
                                      color: kBlueEnd.withValues(alpha: 0.18),
                                      blurRadius: 8,
                                      offset: const Offset(3, 0)),
                                ]
                              : null,
                    ),
                    child: child,
                  ),
                  child: leftPane,
                ),
              ),
            ],
          ),
        ),
      )),
    );
  }

  /// `Obligatoire…` pour l'info-bulle d'en-tête, `null` si le champ ne l'est
  /// pas.
  static String? _requiredHint(String field) {
    if (!_requiredFields.contains(field)) return null;
    return field == 'siret'
        ? 'Obligatoire pour un commerçant.'
        : 'Obligatoire.';
  }

  Widget _headerRow(List<Widget> cells) => Container(
        height: _headerHeight,
        color: kSurface2,
        child: Row(children: cells),
      );

  Widget _headerCell(String label, double width,
      {String? hint, String? required}) {
    final TextStyle style = GoogleFonts.poppins(
        fontSize: 12, fontWeight: FontWeight.w600, color: kText2);
    Widget cell = Container(
      width: width,
      decoration: BoxDecoration(border: _headerSeparator),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text.rich(
            TextSpan(text: label, children: [
              if (required != null)
                const TextSpan(text: ' *', style: TextStyle(color: kOrange700)),
            ]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
      ),
    );
    final String tooltip = [required, hint].whereType<String>().join('\n');
    if (tooltip.isNotEmpty) cell = Tooltip(message: tooltip, child: cell);
    return cell;
  }

  Color _rowColor(String status, int index) {
    final Color tint;
    switch (status) {
      case MerchantImportRow.statusImported:
        tint = kGreen.withValues(alpha: 0.10);
        break;
      case MerchantImportRow.statusRejected:
        tint = Colors.grey.withValues(alpha: 0.14);
        break;
      case MerchantImportRow.statusValidated:
        tint = kGreen.withValues(alpha: 0.06);
        break;
      default:
        tint =
            index.isOdd ? kLBlue.withValues(alpha: 0.10) : Colors.transparent;
    }
    return Color.alphaBlend(tint, kPWhite);
  }

  /// Fond, survol et repère gauche d'une ligne, communs aux deux volets.
  Widget _rowShell(MerchantImportRow row, int index,
      {required List<Widget> cells, bool leftPane = false}) {
    final String status = _statusOf(row);
    final Color base = _rowColor(status, index);
    return Listener(
      // Sans entrer dans l'arène des gestes : les clics des cellules restent
      // intacts.
      onPointerDown: (_) => _pointRow(row.id),
      child: MouseRegion(
        onEnter: (_) => _hoveredRowId.value = row.id,
        onExit: (_) {
          if (_hoveredRowId.value == row.id) _hoveredRowId.value = null;
        },
        child: ListenableBuilder(
          listenable: Listenable.merge([_hoveredRowId, _cursorRowId]),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: cells,
          ),
          builder: (context, child) {
            final bool cursor = _cursorRowId.value == row.id;
            final bool active = cursor ||
                _hoveredRowId.value == row.id ||
                _editing?.rowId == row.id;
            Color accent = Colors.transparent;
            if (status == MerchantImportRow.statusFailed) {
              accent = kRed;
            } else if (cursor) {
              accent = kOrange;
            } else if (active) {
              accent = kBlue;
            }
            return DecoratedBox(
              decoration: BoxDecoration(
                color: active
                    ? Color.alphaBlend(kBlue.withValues(alpha: 0.08), base)
                    : base,
                border: Border(
                  bottom: BorderSide(color: kLBlue.withValues(alpha: 0.45)),
                  left: leftPane
                      ? BorderSide(color: accent, width: _accentWidth)
                      : BorderSide.none,
                ),
              ),
              child: child,
            );
          },
        ),
      ),
    );
  }

  Widget _leftRow(MerchantImportRow row, int index) {
    final String status = _statusOf(row);
    return _rowShell(row, index, leftPane: true, cells: [
      _checkCell(row, status),
      _statusCell(row, status),
      _fieldCell(row, _nameColumn,
          rowEditable: _rowEditable(row),
          struck: status == MerchantImportRow.statusRejected),
    ]);
  }

  Widget _rightRow(MerchantImportRow row, int index) {
    final String status = _statusOf(row);
    final bool rowEditable = _rowEditable(row);
    final bool struck = status == MerchantImportRow.statusRejected;
    return _rowShell(row, index, cells: [
      ..._scrollColumns.map((column) =>
          _fieldCell(row, column, rowEditable: rowEditable, struck: struck)),
      _actionsCell(row, status),
    ]);
  }

  Widget _checkCell(MerchantImportRow row, String status) {
    final Widget content;
    if (status == MerchantImportRow.statusImported) {
      content = const Tooltip(
          message: 'Importé',
          child: Icon(Icons.check_circle, color: kGreen, size: 22));
    } else {
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
              '${blocking.map((issue) => '• ${_issueText(issue)}').join('\n')}',
          child: box,
        );
      }
      content = box;
    }
    return Container(
      width: _checkWidth,
      decoration: BoxDecoration(border: _cellSeparator),
      child: Stack(
        alignment: Alignment.center,
        children: [content, _saveBadge(row.id, RowSaveQueue.statusField)],
      ),
    );
  }

  /// Phrase locale d'une anomalie (code du validateur) ; le message, le code et la
  /// sévérité d'origine restent intacts dans le modèle.
  static String _issueText(MerchantImportIssue issue) =>
      MerchantEnrichmentMessages.importIssue(issue.code ?? '',
          field: issue.field);

  /// Résumé lisible de la ligne : ce qu'il reste à faire, en clair.
  Widget _statusCell(MerchantImportRow row, String status) {
    final List<MerchantImportIssue> errors = row.blockingIssues;
    final List<MerchantImportIssue> warnings =
        row.issues.where((issue) => issue.isWarning).toList();
    final List<MerchantImportIssue> infos =
        row.issues.where((issue) => issue.isInfo).toList();
    final String importError = row.error ?? '';

    String label;
    Color color;
    IconData icon;
    if (status == MerchantImportRow.statusImported) {
      (label, color, icon) = ('Importée', kGreen, Icons.check_circle);
    } else if (status == MerchantImportRow.statusRejected) {
      (label, color, icon) = ('Écartée', kGrey, Icons.remove_circle_outline);
    } else if (status == MerchantImportRow.statusFailed && errors.isEmpty) {
      (label, color, icon) = ('Échec import', kRed, Icons.error);
    } else if (errors.isNotEmpty) {
      (label, color, icon) =
          ('${errors.length} à corriger', kRed, Icons.error_outline);
    } else if (status == MerchantImportRow.statusValidated) {
      (label, color, icon) = ('Validée', kGreen, Icons.check_circle_outline);
    } else if (warnings.isNotEmpty) {
      (label, color, icon) = (
        '${warnings.length} à vérifier',
        kOrange,
        Icons.warning_amber_rounded
      );
    } else {
      (label, color, icon) = ('Prête à valider', kBlue, Icons.done);
    }

    String section(String title, List<MerchantImportIssue> issues) =>
        '$title\n${issues.map((issue) => '• ${_issueText(issue)}').join('\n')}';
    final List<String> tooltip = [
      if (status == MerchantImportRow.statusFailed && importError.isNotEmpty)
        'Échec de l\'import : ${MerchantEnrichmentMessages.importFailure(importError)}',
      if (errors.isNotEmpty)
        section('À corriger (bloque la validation) :', errors),
      if (warnings.isNotEmpty)
        section('À vérifier (n\'empêche pas l\'import) :', warnings),
      if (infos.isNotEmpty) section('Pour information :', infos),
      if (row.issues.isEmpty && status == MerchantImportRow.statusPending)
        'Aucune anomalie : cochez la ligne pour la valider.',
    ];

    Widget chip = ArcPill(
      label,
      icon: icon,
      tone: color == kRed
          ? ArcTone.danger
          : color == kGreen
              ? ArcTone.success
              : color == kOrange
                  ? ArcTone.warning
                  : color == kGrey
                      ? ArcTone.neutral
                      : ArcTone.info,
    );
    if (errors.isNotEmpty && _rowEditable(row)) {
      chip = MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => _jumpToIssue(row, errors.first),
          child: chip,
        ),
      );
    }
    if (tooltip.isNotEmpty) {
      chip = Tooltip(
        message: tooltip.join('\n\n'),
        waitDuration: const Duration(milliseconds: 300),
        child: chip,
      );
    }
    return Container(
      width: _statusWidth,
      decoration: BoxDecoration(border: _cellSeparator),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Align(alignment: Alignment.centerLeft, child: chip),
      ),
    );
  }

  Widget _fieldCell(MerchantImportRow row, _GridColumn column,
      {required bool rowEditable, required bool struck}) {
    final String field = column.key;
    final List<MerchantImportIssue> issues = row.issuesFor(field);
    final List<MerchantImportIssue> errors =
        issues.where((issue) => issue.isError).toList();
    final bool hasWarning = issues.any((issue) => issue.isWarning);
    final bool hasInfo = issues.any((issue) => issue.isInfo);
    final bool pending = _queue.hasPending(row.id, field);
    final bool modified = !pending && row.isModified(field);
    final bool aiValue = !pending && row.isAiValue(field);
    final String? source = row.sourceOf(field);
    final bool editable = rowEditable && column.editor != _Editor.readOnly;
    final bool editing = _isEditing(row, field);
    final RowEditState? saveState = _queue.stateOf(row.id, field);
    final String text = _typeLabel(field, _displayValue(row, field));
    // Cellule vide signalée : obligatoire (rouge) ou conseillée (gris).
    final String? placeholder = text.isNotEmpty || editing
        ? null
        : errors.isNotEmpty
            ? 'À renseigner'
            : hasWarning
                ? 'Non renseigné'
                : null;

    final List<String> tooltip = [
      ...issues.map(_issueText),
      if (modified)
        'Valeur du fichier : '
            '${_typeLabel(field, row.originalOf(field)).isEmpty ? '(vide)' : _typeLabel(field, row.originalOf(field))}',
      if (source != null && source != 'fichier') 'Source : $source',
      if (saveState == RowEditState.failed)
        'Enregistrement impossible : cliquez sur l\'icône pour réessayer.',
    ];

    final Widget content;
    if (editing) {
      final _EditingCell cell = _editing!;
      content = Padding(
        padding: const EdgeInsets.all(3),
        child: Focus(
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
              if (identical(_editing, cell)) {
                _finishEdit(commit: true);
                _returnToGrid();
              }
            },
            onTapOutside: (_) {
              if (identical(_editing, cell)) _finishEdit(commit: true);
            },
            style: GoogleFonts.poppins(fontSize: 13, color: kBlueEnd),
            decoration: const InputDecoration(
              isDense: true,
              filled: true,
              fillColor: kWhite,
              contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              border: OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: kBlue, width: 2)),
            ),
          ),
        ),
      );
    } else {
      final IconData? markerIcon = errors.isNotEmpty
          ? Icons.error_outline
          : hasWarning
              ? Icons.warning_amber_rounded
              : hasInfo
                  ? Icons.info_outline
                  : null;
      final Color markerColor = errors.isNotEmpty
          ? kRed
          : hasWarning
              ? kOrange
              : kBlue;
      content = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                placeholder ?? text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                // Italique de synthèse : pas de police italique à charger.
                style: placeholder != null
                    ? GoogleFonts.poppins(
                            fontSize: 12,
                            color: errors.isNotEmpty ? kRed : kGrey)
                        .copyWith(fontStyle: FontStyle.italic)
                    : GoogleFonts.poppins(
                        fontSize: 13,
                        color: struck ? kGrey : kBlueEnd,
                        decoration: struck ? TextDecoration.lineThrough : null),
              ),
            ),
            if (markerIcon != null) ...[
              const SizedBox(width: 4),
              Icon(markerIcon, color: markerColor, size: 15),
            ],
          ],
        ),
      );
    }

    Widget cell = Container(
      key: ValueKey('cell-${row.id}-$field'),
      width: column.width,
      decoration: BoxDecoration(
        color: editing
            ? null
            : errors.isNotEmpty
                ? kRed.withValues(alpha: 0.07)
                : aiValue
                    ? kOrange.withValues(alpha: 0.07)
                    : null,
        border: _cellSeparator,
      ),
      child: Stack(
        children: [
          Positioned.fill(child: content),
          if (modified && !editing)
            Positioned(
              left: 0,
              top: 0,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: editable
                    ? (details) =>
                        _offerRevert(row, field, details.globalPosition)
                    : null,
                child: CustomPaint(
                    size: const Size(10, 10),
                    painter: _CornerMarkerPainter(kBlue)),
              ),
            ),
          _saveBadge(row.id, field),
        ],
      ),
    );

    if (!editing && tooltip.isNotEmpty) {
      cell = Tooltip(
        message: tooltip.join('\n'),
        waitDuration: const Duration(milliseconds: 300),
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
          right: 2,
          top: 2,
          child: SizedBox(
              height: 12,
              width: 12,
              child: TribuneoLoader()),
        );
      case RowEditState.failed:
        return Positioned(
          right: 1,
          top: 1,
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
      return const SizedBox(width: _actionsWidth);
    }
    final bool rejected = status == MerchantImportRow.statusRejected;
    return SizedBox(
      width: _actionsWidth,
      child: Center(
        child: TextButton(
          style: TextButton.styleFrom(
            foregroundColor: rejected ? kBlue : kRed,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            textStyle: GoogleFonts.poppins(fontSize: 12),
          ),
          onPressed: _editable ? () => _setRejected(row, !rejected) : null,
          child: Text(
            rejected ? 'Rétablir' : 'Écarter',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ArcText.small(
                color:
                    !_editable ? kText3 : (rejected ? kNavy600 : kDangerText)),
          ),
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
    builder: (context) => EnrichmentDialog(
      maxWidth: 600,
      title: const Text('Abandonner ce lot'),
      content: const SizedBox(
        width: double.infinity,
        child: Text('Le lot ne pourra plus être modifié ni importé. Les '
            'commerçants déjà importés restent dans le réseau.'),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler')),
        FilledButton(
            style: arcDangerButtonStyle(),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Abandonner')),
      ],
    ),
  );
}

/// Petit triangle dans le coin d'une cellule modifiée (repère « à la tableur »).
class _CornerMarkerPainter extends CustomPainter {
  final Color color;

  const _CornerMarkerPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(0, size.height)
        ..close(),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_CornerMarkerPainter oldDelegate) =>
      oldDelegate.color != color;
}
