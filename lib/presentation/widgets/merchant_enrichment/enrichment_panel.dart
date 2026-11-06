import 'package:back_office_tribuneo_v2/presentation/widgets/tribuneo_loader.dart';
import '../../../domain/errors/merchant_enrichment_messages.dart';
import 'ui/enrichment_dialog.dart';
import 'research_form.dart';
import 'research_metadata_view.dart';
import '../../../domain/usecases/merchant_enrichment/research_usecase.dart';
import '../../../domain/models/merchant_enrichment/chat_context_reference.dart';
import '../../../domain/repositories/assistant_repository.dart';
import '../../../domain/usecases/merchant_enrichment/chat_comparison_usecase.dart';
import 'chat_comparison.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/responsive.dart';
import '../assistant/assistant_docked_panel.dart';
import '../assistant/neo_ai_button.dart';
import '../../../domain/models/merchant_import_row_model.dart';
import '../../../domain/models/merchant_enrichment/enrichment_models.dart';
import '../../../domain/usecases/merchant_enrichment/enrichment_usecase.dart';
import '../../../domain/models/merchant_enrichment/vat_status.dart';
import 'vat_presentation.dart';
import 'ui/enrichment_mini_map.dart';
import '../../utils/common.dart';
import '../arc/arc.dart';

/// Shared by the real grid and the local, transport-free widget harness.
class EnrichmentButton extends StatefulWidget {
  final EnrichmentUseCase session;
  final List<MerchantImportRow> Function() rows;
  final Future<bool> Function() prepare;
  final AssistantRepository Function(ChatContextReference, String)? comparisonRepository;

  /// Enregistre un point posé sur la carte comme saisie manuelle des
  /// coordonnées de la ligne ; `true` une fois enregistré. Absent : carte en
  /// consultation seule.
  final Future<bool> Function(int rowId, GeoPoint point)? onSetPosition;
  const EnrichmentButton(
      {super.key,
      required this.session,
      required this.rows,
      required this.prepare,
      this.comparisonRepository,
      this.onSetPosition});
  @override
  State<EnrichmentButton> createState() => _EnrichmentButtonState();
}

class _EnrichmentButtonState extends State<EnrichmentButton> {
  final _comparisonLifetime = ChatComparisonLifetime();
  bool _opening = false;

  /// Comparaison affichée dans le bouton flottant de Néo, à fermer si la
  /// grille disparaît (changement d'écran).
  AssistantDockedPanel? _docked;
  Object? _dockedToken;
  @override
  void dispose() {
    _comparisonLifetime.invalidate();
    _comparisonLifetime.dispose();
    final docked = _docked, token = _dockedToken;
    // Arbre verrouillé pendant le démontage : fermeture différée.
    if (docked != null && token != null) {
      scheduleMicrotask(() => docked.close(token));
    }
    super.dispose();
  }
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.session.initialize();
    });
  }

  Future<void> _open() async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      if (!await widget.prepare() || !mounted) return;
      // Avec le bouton flottant de Néo, « Comparer avec Néo » ferme ce
      // dialogue et ouvre la comparaison dans le panneau de Néo ; le dialogue
      // est rouvert ensuite si la comparaison y renvoie.
      final docked = AssistantDockedScope.maybeOf(context);
      while (mounted) {
        final comparison = await showDialog<ChatComparisonUseCase>(
            context: context,
            builder: (_) => EnrichmentPanel(
                session: widget.session,
                rows: widget.rows,
                scopeActive: () => mounted,
                lifetime: _comparisonLifetime,
                comparisonRepository: widget.comparisonRepository,
                onSetPosition: widget.onSetPosition,
                dockComparison: docked != null));
        widget.session.pause();
        if (comparison == null || docked == null || !mounted) return;
        final outcome = await _compareInAssistant(docked, comparison);
        if (!mounted) return;
        final selection = outcome.selection;
        if (selection != null &&
            _comparable(widget.session, selection.proposal,
                hasRepository: widget.comparisonRepository != null)) {
          await showDialog<void>(
              context: context,
              builder: (_) => _CandidateReview(
                  session: widget.session,
                  proposal: selection.proposal,
                  candidate: selection.candidate,
                  onSetPosition: widget.onSetPosition));
        }
        if (!outcome.reopenPanel) return;
      }
    } finally {
      widget.session.pause();
      if (mounted) setState(() => _opening = false);
    }
  }

  Future<ChatComparisonOutcome> _compareInAssistant(
      AssistantDockedPanel docked, ChatComparisonUseCase comparison) {
    final completer = Completer<ChatComparisonOutcome>();
    void done(ChatComparisonOutcome outcome) {
      if (completer.isCompleted) return;
      completer.complete(outcome);
      final token = _dockedToken;
      _dockedToken = null;
      if (token != null) docked.close(token);
    }

    _docked = docked;
    _dockedToken = docked.show(
        ChatComparison(
            session: comparison,
            fullScreen: !Responsive.isDesktop(context),
            onDone: done),
        // Remplacée par une autre conversation ancrée.
        onDismissed: () => done(ChatComparisonOutcome.closed));
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    if (!session.enabled) return const SizedBox.shrink();
    return AnimatedBuilder(
        animation: session,
        builder: (context, _) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Tooltip(
                    message: session.message ??
                        'Rechercher des propositions sourcées pour les champs vides.',
                    child: OutlinedButton.icon(
                        onPressed:
                            session.available && !_opening ? _open : null,
                        icon: const Icon(Icons.search_rounded, size: 18),
                        label: const Text('Compléter les informations'))),
                if (!session.available) ...[
                  const SizedBox(width: 6),
                  ArcIconAction(
                      icon: Icons.refresh_rounded,
                      tooltip: 'Vérifier la disponibilité de la recherche',
                      onPressed: session.busy ? null : session.initialize),
                ],
              ],
            ));
  }
}

class EnrichmentPanel extends StatefulWidget {
  final EnrichmentUseCase session;
  final List<MerchantImportRow> Function() rows;
  final bool Function()? scopeActive;
  final ChatComparisonLifetime? lifetime;
  final AssistantRepository Function(ChatContextReference, String)? comparisonRepository;

  /// « Comparer avec Néo » ferme ce dialogue en retournant la comparaison
  /// préparée, affichée ensuite dans le bouton flottant de Néo.
  final bool dockComparison;

  /// Enregistre un point posé sur la carte comme saisie manuelle des
  /// coordonnées de la ligne ; `true` une fois enregistré. Absent : carte en
  /// consultation seule.
  final Future<bool> Function(int rowId, GeoPoint point)? onSetPosition;
  const EnrichmentPanel({super.key, required this.session, required this.rows,
    this.scopeActive, this.lifetime, this.comparisonRepository,
    this.dockComparison = false, this.onSetPosition});
  @override
  State<EnrichmentPanel> createState() => _EnrichmentPanelState();
}

class _EnrichmentPanelState extends State<EnrichmentPanel> {
  final Set<int> _selected = {};
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.session.resume();
    });
  }

  @override
  void dispose() {
    widget.session.pause(notify: false);
    super.dispose();
  }

  bool _comparing = false;
  bool _canCompare(EnrichmentProposal p) => _comparable(widget.session, p,
      hasRepository: widget.comparisonRepository != null);
  Future<void> _compare(EnrichmentProposal p) async {
    if (_comparing || !_canCompare(p)) return;
    setState(() => _comparing = true);
    final s = widget.session;
    try {
      final tenant = await s.repository.transport.currentTenant();
      if (!mounted || !_canCompare(p)) return;
      final reference = ChatContextReference(batchId: p.batchId, rowId: p.rowId,
        proposalId: p.id, expectedVersion: p.baseVersion);
      final docked = widget.dockComparison;
      final comparison = ChatComparisonUseCase(enrichment: s, reference: reference, proposal: p,
        tenant: tenant, lifetime: widget.lifetime,
        // Ancrée dans Néo, la comparaison survit à ce dialogue : elle dépend
        // seulement de la grille.
        active: docked ? () => widget.scopeActive?.call() ?? true
          : () => mounted && (widget.scopeActive?.call() ?? true),
        assistant: widget.comparisonRepository?.call(reference, tenant) ??
          ApiAssistantRepository(enrichmentContext: reference, expectedTenant: tenant));
      if (docked) {
        Navigator.pop(context, comparison);
        return;
      }
      final selected = await showDialog<({EnrichmentProposal proposal, EnrichmentCandidate candidate})>(
        context: context, builder: (_) => ChatComparison(session: comparison));
      if (!mounted || selected == null || !_canCompare(selected.proposal)) return;
      await showDialog<void>(context: context, builder: (_) => _CandidateReview(
        session: s, proposal: selected.proposal, candidate: selected.candidate,
        onSetPosition: widget.onSetPosition));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Comparaison indisponible. Le choix manuel reste disponible.')));
    } finally {
      if (mounted) setState(() => _comparing = false);
    }
  }

  Future<void> _research(EnrichmentProposal p) async {
    if (!widget.session.canResearch(p)) return;
    final form = ResearchUseCase(widget.session, p,
      () => mounted && (widget.scopeActive?.call() ?? true));
    await showDialog<bool>(context: context, builder: (_) => ResearchForm(session: form));
  }

  Future<void> _start() async {
    final ids = _selected.toList()..sort();
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => EnrichmentDialog(
                maxWidth: 600,
                title: const Text('Lancer la recherche ?'),
                content: Text(
                    '${ids.length} ligne(s) explicitement sélectionnée(s).\n'
                    'Seuls les nom, SIRET et adresse publics sont utilisés. '
                    'La recherche prépare des propositions séparées. '
                    'Chaque application au brouillon sera à confirmer. '
                    'Le lot restera à relire, sans validation ni import.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Retour')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Lancer')),
                ]));
    if (confirmed == true && mounted) await widget.session.start(ids);
  }

  /// Lignes cochables au plus pour une recherche.
  int get _maxRows => widget.session.capability?.maxRows ?? 2000;

  bool _selectionLocked() {
    final s = widget.session;
    return s.busy || s.job?.active == true || !s.batchEditable();
  }

  /// « Tout sélectionner » : coche les lignes éligibles dans la limite de la
  /// recherche, ou décoche tout si elles le sont déjà.
  void _toggleAll(List<MerchantImportRow> eligible) {
    final target = eligible.take(_maxRows).map((r) => r.id).toSet();
    setState(() {
      if (_selected.containsAll(target)) {
        _selected.clear();
      } else {
        _selected
          ..clear()
          ..addAll(target);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    return AnimatedBuilder(
        animation: s,
        builder: (context, _) {
          final rows = widget.rows();
          final rowsById = {for (final r in rows) r.id: r};
          final eligible = rows.where(EnrichmentUseCase.eligible).toList();
          final allowed = eligible.map((r) => r.id).toSet();
          _selected.removeWhere((id) => !allowed.contains(id));
          final job = s.job;
          final page = s.page;
          return EnrichmentDialog(
            scrollable: false,
            onClose: () => Navigator.pop(context),
            title: const Text('Compléter les informations'),
            content: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Flexible(
                      flex: 2,
                      child: SingleChildScrollView(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                            if (s.busy) const TribuneoLoadingProgress(),
                            if (s.message != null)
                              Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: EnrichmentNotice(
                                      error: s.message !=
                                          EnrichmentUseCase.appliedMessage,
                                      child: SelectableText(s.message!,
                                          key: const ValueKey(
                                              'enrichment-message')))),
                            if (job != null) ...[
                              if (s.capability?.targetedResearch == true)
                                ResearchMetadataView(
                                    key:
                                        ValueKey('research-metadata-${job.id}'),
                                    session: s,
                                    jobId: job.id,
                                    active: () =>
                                        mounted &&
                                        (widget.scopeActive?.call() ?? true)),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: TribuneoLoadingProgress(
                                    animate: job.active,
                                    value: job.total == 0
                                        ? 0
                                        : (job.done / job.total).clamp(0, 1)),
                              ),
                              const SizedBox(height: 8),
                              _jobSummary(job),
                            ],
                            Wrap(
                                spacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  if (job != null)
                                    Text(
                                        '${_jobLabel(job.status)} · ${job.done}/${job.total} lignes',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: kNavy900)),
                                  TextButton.icon(
                                      onPressed:
                                          s.busy ? null : () => s.resume(),
                                      icon: const Icon(Icons.refresh),
                                      label:
                                          const Text('Reprendre la lecture')),
                                  if (job?.active == true)
                                    TextButton(
                                        onPressed: s.busy ? null : s.cancel,
                                        child:
                                            const Text('Annuler la recherche')),
                                  Tooltip(
                                    message: s.capability?.vat == true
                                        ? 'Propositions issues de sources publiques. Les valeurs déjà saisies sont conservées. TVA : source DGFiP datée, sans vérification VIES.\n'
                                            'Fermer met la lecture en pause ; la recherche serveur continue.'
                                        : 'Propositions issues de sources publiques. Les valeurs déjà saisies sont conservées. TVA non vérifiée.\n'
                                            'Fermer met la lecture en pause ; la recherche serveur continue.',
                                    child: const Icon(
                                        Icons.info_outline_rounded,
                                        size: 20,
                                        color: kNavy600),
                                  ),
                                ]),
                            if (s.history != null &&
                                s.history!.items.isNotEmpty)
                              _historyPicker(job),
                          ]))),
                  const SizedBox(height: 4),
                  Expanded(
                      flex: 5,
                      child: DefaultTabController(
                          length: 2,
                          child: Column(children: [
                            const SizedBox(height: 4),
                            const _SegmentedTabs(tabs: [
                              Tab(text: 'Lignes à rechercher', height: 34),
                              Tab(text: 'Propositions / historique', height: 34)
                            ]),
                            const SizedBox(height: 8),
                            Expanded(
                                child: TabBarView(children: [
                              _rowsTab(eligible),
                              _proposalsTab(page, rowsById),
                            ])),
                          ]))),
                ]),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Fermer'))
            ],
          );
        });
  }

  /// Compteurs de la recherche, en pastilles.
  Widget _jobSummary(EnrichmentJob job) => Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Wrap(spacing: 6, runSpacing: 6, children: [
        EnrichmentChip(_count(job.matched, 'correspondance'),
            icon: Icons.check_circle_outline, color: kSuccessText),
        EnrichmentChip(_count(job.ambiguous, 'ambiguïté'),
            icon: Icons.help_outline, color: kWarningText),
        EnrichmentChip(_count(job.unresolved, 'non résolue', 'non résolues'),
            icon: Icons.search_off, color: kNeutralText),
        if (job.stale > 0)
          EnrichmentChip(_count(job.stale, 'obsolète'),
              icon: Icons.update, color: kNeutralText),
        if (job.errorCode != null)
          EnrichmentChip(
              MerchantEnrichmentMessages.error(code: job.errorCode),
              icon: Icons.error_outline,
              color: kDangerText),
      ]));

  /// Recherche affichée, choisie dans les plus récentes.
  Widget _historyPicker(EnrichmentJob? job) {
    final s = widget.session;
    return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Wrap(
            spacing: 12,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Texte flexible : il passe à la ligne sur un écran étroit.
              const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.history_rounded, size: 18, color: kNavy600),
                SizedBox(width: 6),
                Flexible(
                    child: Text('Historique des recherches',
                        style: TextStyle(fontSize: 13, color: kText2))),
              ]),
              Container(
                  width: 300,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                      color: kSurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: kBorder, width: 1.5)),
                  child: DropdownButton<String>(
                      underline: const SizedBox.shrink(),
                      borderRadius: BorderRadius.circular(10),
                      isExpanded: true,
                      itemHeight: null,
                      value: s.history!.items.any((j) => j.id == job?.id)
                          ? job?.id
                          : null,
                      hint: const Text('Choisir une recherche'),
                      items: s.history!.items
                          .map((j) => DropdownMenuItem(
                              value: j.id,
                              child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                      '${_jobLabel(j.status)} · ${MerchantEnrichmentMessages.sourceDate(j.updatedAt)}'))))
                          .toList(),
                      onChanged: s.busy
                          ? null
                          : (id) => s.resume(
                              historyOffset: s.history!.offset, jobId: id))),
            ]));
  }

  Widget _rowsTab(List<MerchantImportRow> eligible) {
    final s = widget.session;
    final locked = _selectionLocked();
    final reachable = eligible.length < _maxRows ? eligible.length : _maxRows;
    final bool? all = _selected.isEmpty
        ? false
        : _selected.length >= reachable
            ? true
            : null;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      CheckboxListTile(
          key: const ValueKey('enrichment-select-all'),
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
          tristate: true,
          value: all,
          onChanged:
              locked || eligible.isEmpty ? null : (_) => _toggleAll(eligible),
          title: Text(
              eligible.length > _maxRows
                  ? 'Sélectionner les $_maxRows premières lignes'
                  : 'Tout sélectionner',
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: kNavy900)),
          subtitle: Text(
              '${_selected.length} / ${eligible.length} lignes sélectionnées pour cette recherche (maximum $_maxRows)')),
      const Divider(height: 1, color: kNavy100),
      Expanded(
          child: ListView.builder(
              itemCount: eligible.length,
              itemBuilder: (context, index) {
                final row = eligible[index];
                final details = [
                  row.textOf('siret'),
                  '${row.textOf('street')} ${row.textOf('zip')} ${row.textOf('city')}'
                      .trim(),
                ].where((value) => value.isNotEmpty).join(' · ');
                return CheckboxListTile(
                    key: ValueKey('enrichment-scope-${row.id}'),
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                    title: Tooltip(
                        message: row.textOf('name'),
                        child: Text(
                            'Ligne ${row.position} · ${row.textOf('name')}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis)),
                    subtitle: details.isEmpty
                        ? null
                        : Text(details,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                    value: _selected.contains(row.id),
                    onChanged: locked
                        ? null
                        : (value) => setState(() {
                              if (value == true) {
                                _selected.add(row.id);
                              } else {
                                _selected.remove(row.id);
                              }
                            }));
              })),
      const SizedBox(height: 8),
      FilledButton(
          onPressed: locked ||
                  _selected.isEmpty ||
                  _selected.length > (s.capability?.maxRows ?? 0)
              ? null
              : _start,
          child: Text('Rechercher sur ces ${_selected.length} lignes')),
    ]);
  }

  /// Il reste au moins un champ applicable pour un de ses candidats.
  bool _reviewable(EnrichmentProposal p) =>
      p.candidates.any((c) => widget.session.applicable(p, c).isNotEmpty);

  /// Charge la page suivante de propositions ; `false` s'il n'y en a pas.
  Future<bool> _loadNextPage() async {
    final page = widget.session.page;
    if (page == null || !page.hasNext) return false;
    await widget.session.readPage(page.offset + page.limit);
    return widget.session.page?.offset != page.offset;
  }

  /// Revue d'un candidat, enchaînable sur les propositions suivantes.
  /// [chained] : « Passer » et « Appliquer et suivante » enchaînent les
  /// propositions à traiter.
  Future<void> _review(EnrichmentProposal p, EnrichmentCandidate c,
          {bool chained = true}) =>
      showDialog<void>(
          context: context,
          builder: (_) => _CandidateReview(
              session: widget.session,
              proposal: p,
              candidate: c,
              pageItems: chained
                  ? () => widget.session.page?.items ?? const []
                  : null,
              loadNextPage: chained ? _loadNextPage : null,
              onSetPosition: widget.onSetPosition));

  Widget _proposalsTab(EnrichmentPage<EnrichmentProposal>? page,
      Map<int, MerchantImportRow> rowsById) {
    final s = widget.session;
    final todo = page?.items.where(_reviewable).toList() ?? const [];
    return Column(children: [
      if (todo.isNotEmpty)
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                    key: const ValueKey('review-chain'),
                    onPressed: s.busy
                        ? null
                        : () =>
                            _review(todo.first, todo.first.candidates.first),
                    icon: const Icon(Icons.playlist_play),
                    label: Text(
                        'Traiter une par une (${_count(todo.length, 'proposition')} sur cette page)')))),
      Expanded(
          child: page == null || page.items.isEmpty
              ? const Center(
                  child: Text('Aucune proposition publiée pour cette recherche.'))
              : ListView.builder(
                  itemCount: page.items.length,
                  itemBuilder: (context, index) => _proposalTile(
                      page.items[index], rowsById[page.items[index].rowId]))),
      if (page != null)
        Wrap(
            spacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TextButton(
                  onPressed: s.busy || page.offset == 0
                      ? null
                      : () => s.readPage(
                          (page.offset - page.limit).clamp(0, page.total)),
                  child: const Text('Page précédente')),
              Text(
                  '${page.offset + (page.items.isEmpty ? 0 : 1)}–${page.offset + page.items.length} / ${page.total}'),
              TextButton(
                  onPressed: s.busy || !page.hasNext
                      ? null
                      : () => s.readPage(page.offset + page.limit),
                  child: const Text('Page suivante')),
            ]),
    ]);
  }

  /// Une ligne par proposition : état et actions ; raisons et candidats une
  /// fois dépliée.
  Widget _proposalTile(EnrichmentProposal p, MerchantImportRow? row) {
    final s = widget.session;
    final style = _stateStyle(p.state);
    final name = row?.textOf('name') ?? '';
    final reasons = MerchantEnrichmentMessages.reasons(p.reasons);
    final count = p.candidates.length;
    final actions = [
      if (s.canResearch(p))
        OutlinedButton(
            style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, kControlHeightCompact),
                padding: const EdgeInsets.symmetric(horizontal: 12)),
            onPressed: () => _research(p),
            child: const Text('Préciser la recherche')),
      if (_canCompare(p))
        NeoAiButton(
            label: 'Comparer avec Néo',
            onPressed: _comparing ? null : () => _compare(p)),
    ];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kBorder)),
      child: ExpansionTile(
          key: ValueKey('proposal-${p.id}'),
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
          iconColor: kNavy600,
          collapsedIconColor: kNavy600,
          leading: Tooltip(
              message: _stateLabel(p.state),
              child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                      color: EnrichmentChip.backgroundFor(style.color),
                      borderRadius: BorderRadius.circular(8)),
                  child: Icon(style.icon, color: style.color, size: 17))),
          title: Text('Ligne ${row?.position ?? p.rowId}${name.isEmpty ? '' : ' · $name'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600, color: kNavy900)),
          subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    [
                      _stateLabel(p.state),
                      if (count > 0) '$count candidat${count > 1 ? 's' : ''}',
                    ].join(' · '),
                    style: TextStyle(color: style.color, fontSize: 12)),
                if (actions.isNotEmpty)
                  Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: actions)),
              ]),
          expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          children: [
            if (reasons.isNotEmpty)
              Text(reasons.join(' · '),
                  style: const TextStyle(fontSize: 12, color: kText3)),
            ...p.candidates.map((c) => _candidateCard(p, c)),
          ]),
    );
  }

  Widget _candidateCard(EnrichmentProposal p, EnrichmentCandidate c) {
    final s = widget.session;
    final reasons = MerchantEnrichmentMessages.reasons(c.reasons);
    final establishment = c.kind == 'establishment';
    return Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: kNavy50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kNavy200)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(c.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: kNavy800)),
          const SizedBox(height: 10),
          Wrap(spacing: 6, runSpacing: 6, children: [
            EnrichmentChip(establishment ? 'Établissement' : 'Adresse seule',
                icon: establishment ? Icons.storefront : Icons.place_outlined),
            if (c.siret != null) EnrichmentChip('SIRET ${c.siret}', mono: true),
            if (establishment) _establishmentChip(c.establishmentStatus),
            _matchChip(c.matchLevel,
                tooltip: reasons.isEmpty ? null : reasons.join('\n')),
            if (c.geoPrecision != null)
              EnrichmentChip(
                  'Précision : ${MerchantEnrichmentMessages.geoPrecision(c.geoPrecision)}',
                  icon: Icons.my_location),
            if (s.capability?.vat == true && establishment)
              EnrichmentChip(
                  'TVA : ${vatStatusLabel(c.vatStatus, capability: true)}'),
          ]),
          Align(
              alignment: Alignment.centerRight,
              child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, kControlHeightCompact),
                          padding: const EdgeInsets.symmetric(horizontal: 14)),
                      onPressed: s.busy ? null : () => _review(p, c, chained: false),
                      child: const Text('Comparer / choisir')))),
        ]));
  }
}

class _CandidateReview extends StatefulWidget {
  final EnrichmentUseCase session;
  final EnrichmentProposal proposal;
  final EnrichmentCandidate candidate;

  /// Propositions de la page, dans l'ordre : active la revue enchaînée
  /// (« Passer », « Appliquer et suivante »). Absent : un seul candidat.
  final List<EnrichmentProposal> Function()? pageItems;

  /// Charge la page suivante ; `false` s'il n'y en a plus.
  final Future<bool> Function()? loadNextPage;

  /// Enregistre un point posé sur la carte comme saisie manuelle des
  /// coordonnées de la ligne ; `true` une fois enregistré. Absent : carte en
  /// consultation seule.
  final Future<bool> Function(int rowId, GeoPoint point)? onSetPosition;
  const _CandidateReview(
      {required this.session,
      required this.proposal,
      required this.candidate,
      this.pageItems,
      this.loadNextPage,
      this.onSetPosition});
  @override
  State<_CandidateReview> createState() => _CandidateReviewState();
}

class _CandidateReviewState extends State<_CandidateReview> {
  final Set<String> _fields = {};
  bool _acknowledge = false;

  /// Proposition et candidat affichés : ils changent pendant une revue
  /// enchaînée. Aucun champ n'est jamais coché d'office.
  late EnrichmentProposal _p = widget.proposal;
  late EnrichmentCandidate _c = widget.candidate;
  int _applied = 0;
  bool _advancing = false, _finished = false;

  /// Point posé sur la carte : il remplace les coordonnées proposées et
  /// s'enregistre comme saisie manuelle.
  GeoPoint? _point;
  bool _savingPoint = false;
  String? _pointError;

  bool get _chained => widget.pageItems != null;

  bool _reviewable(EnrichmentProposal p) =>
      p.candidates.any((c) => widget.session.applicable(p, c).isNotEmpty);

  /// Propositions de la page qui restent à traiter.
  List<EnrichmentProposal> _todo() =>
      (widget.pageItems?.call() ?? const []).where(_reviewable).toList();

  EnrichmentProposal? _nextOnPage() {
    final items = widget.pageItems?.call() ?? const [];
    final from = items.indexWhere((x) => x.id == _p.id);
    for (var i = from + 1; i < items.length; i++) {
      if (_reviewable(items[i])) return items[i];
    }
    return null;
  }

  void _show(EnrichmentProposal p, [EnrichmentCandidate? c]) => setState(() {
        _p = p;
        _c = c ?? p.candidates.first;
        _fields.clear();
        _acknowledge = false;
        _point = null;
        _pointError = null;
      });

  /// Proposition suivante à traiter, sur cette page puis les suivantes ;
  /// écran de fin s'il n'y en a plus.
  Future<void> _advance() async {
    if (_advancing) return;
    var next = _nextOnPage();
    if (next == null && widget.loadNextPage != null) {
      setState(() => _advancing = true);
      try {
        while (next == null && await widget.loadNextPage!()) {
          if (!mounted) return;
          next = _todo().firstOrNull;
        }
      } finally {
        if (mounted) setState(() => _advancing = false);
      }
    }
    if (!mounted) return;
    if (next == null) {
      setState(() => _finished = true);
    } else {
      _show(next);
    }
  }

  /// Le point peut-il être posé pour la ligne affichée ?
  bool _canPlace(MerchantImportRow? row) =>
      widget.onSetPosition != null &&
      widget.session.batchEditable() &&
      row != null &&
      EnrichmentUseCase.eligible(row);

  Future<void> _openMap(GeoPoint proposed, MerchantImportRow? row) async {
    final MapPick? pick = await showDialog<MapPick>(
        context: context,
        builder: (_) => EnrichmentMapDialog(
            proposed: proposed,
            precision: _c.geoPrecision,
            chosen: _point,
            editable: _canPlace(row)));
    if (pick == null || !mounted) return;
    setState(() {
      _point = pick.point;
      _pointError = null;
      // Le point posé remplace les coordonnées proposées.
      if (_point != null) _fields.removeAll({'lat', 'lng'});
    });
  }

  /// Champs cochés (application de la proposition), puis point posé sur la
  /// carte (saisie manuelle) : dans cet ordre, la proposition est encore à
  /// jour quand elle s'applique.
  Future<void> _apply({required bool thenNext}) async {
    final s = widget.session;
    final GeoPoint? point = _point;
    if (_fields.isNotEmpty) {
      final applied =
          await s.apply(_p, _c, {..._fields}, acknowledge: _acknowledge);
      if (!mounted || !applied) return;
    }
    if (point != null) {
      setState(() => _savingPoint = true);
      final bool saved = await widget.onSetPosition!(_p.rowId, point);
      if (!mounted) return;
      setState(() {
        _savingPoint = false;
        if (!saved) {
          _pointError =
              'Le point n’a pas pu être enregistré. Réessayez, ou saisissez les coordonnées dans la grille.';
        }
      });
      if (!saved) return;
    }
    _applied++;
    if (thenNext) {
      await _advance();
    } else {
      Navigator.pop(context);
    }
  }

  Widget _finishedDialog() => EnrichmentDialog(
      maxWidth: 600,
      onClose: () => Navigator.pop(context),
      title: const Text('Revue terminée'),
      content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
                child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                        color: kSuccessBg,
                        borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.task_alt_rounded,
                        color: kSuccessText, size: 30))),
            const SizedBox(height: 14),
            Text(
                'Plus aucune proposition à traiter. '
                '${_count(_applied, 'proposition appliquée', 'propositions appliquées')} au brouillon pendant cette revue.',
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text(
                'Validez ensuite les lignes dans la grille avant l’import.',
                textAlign: TextAlign.center,
                style: TextStyle(color: kText3)),
          ]),
      actions: [
        FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer')),
      ]);

  /// Ligne en cours et propositions restantes, pendant une revue enchaînée.
  Widget _chainHeader(MerchantImportRow? row) {
    final remaining = _todo().length;
    final name = row?.textOf('name') ?? '';
    return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Ligne ${row?.position ?? _p.rowId}${name.isEmpty ? '' : ' · $name'}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, color: kNavy900)),
              EnrichmentChip(
                  '${_count(remaining, 'proposition')} à traiter sur cette page',
                  icon: Icons.playlist_play,
                  color: kNavy600),
              if (_applied > 0)
                EnrichmentChip(
                    _count(_applied, 'appliquée', 'appliquées'),
                    icon: Icons.check,
                    color: kSuccessText),
            ]));
  }

  /// Plusieurs candidats : choix explicite de celui à relire.
  Widget _candidatePicker() => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Wrap(spacing: 6, runSpacing: 6, children: [
        for (var i = 0; i < _p.candidates.length; i++)
          ChoiceChip(
              key: ValueKey('candidate-pick-${_p.candidates[i].id}'),
              label: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 260),
                  child: Text('${i + 1}. ${_p.candidates[i].label}',
                      overflow: TextOverflow.ellipsis)),
              selected: _p.candidates[i].id == _c.id,
              onSelected: widget.session.busy
                  ? null
                  : (_) => _show(_p, _p.candidates[i])),
      ]));

  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    if (_finished) return _finishedDialog();
    return AnimatedBuilder(
        animation: s,
        builder: (context, _) {
          final p = _p, c = _c;
          final row = s.currentRow(p.rowId);
          final allowed = s.applicable(p, c);
          _fields.removeWhere((f) => !allowed.contains(f));
          final geo = _fields.contains('lat');
          final vat = s.capability?.vat == true;
          final rowSiretEmpty =
              MerchantImportRow.normalized('siret', row?.valueOf('siret'))
                  .isEmpty;
          final reasons = MerchantEnrichmentMessages.reasons(c.reasons);
          final entries = c.fields.entries
              .where((e) => EnrichmentUseCase.fields.contains(e.key))
              .toList();
          String before(String key) =>
              row?.textOf(key).isNotEmpty == true ? row!.textOf(key) : 'Vide';
          final GeoPoint? point = _point;
          bool placed(String key) =>
              point != null && (key == 'lat' || key == 'lng');
          String pointValue(String key) => key == 'lat'
              ? point!.lat.toStringAsFixed(6)
              : point!.lng.toStringAsFixed(6);
          final canApply = !s.busy &&
              !_advancing &&
              !_savingPoint &&
              (_fields.isNotEmpty || point != null) &&
              !(geo && c.approximate && !_acknowledge) &&
              VatRules.selectionValid(_fields, rowSiretEmpty: rowSiretEmpty);
          return EnrichmentDialog(
              onClose: s.busy ? null : () => Navigator.pop(context),
              title: Text('Choisir : ${c.label}'),
              content: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_chained) _chainHeader(row),
                    if (_advancing) const TribuneoLoadingProgress(),
                    if (p.candidates.length > 1) _candidatePicker(),
                    Wrap(spacing: 6, runSpacing: 6, children: [
                      EnrichmentChip('SIRET ${c.siret ?? 'non attribué'}',
                          mono: c.siret != null),
                      EnrichmentChip('SIREN ${c.siren ?? 'non attribué'}',
                          mono: c.siren != null),
                      if (c.legalName != null)
                        EnrichmentChip(c.legalName!, icon: Icons.business),
                      if (c.kind == 'establishment')
                        _establishmentChip(c.establishmentStatus),
                      _matchChip(c.matchLevel),
                      EnrichmentChip(
                          c.geoPrecision == null
                              ? 'Précision géographique non renseignée'
                              : 'Précision géographique : ${MerchantEnrichmentMessages.geoPrecision(c.geoPrecision)}',
                          icon: Icons.my_location),
                      EnrichmentChip(
                          'TVA : ${vatStatusLabel(c.vatStatus, capability: vat)}'),
                    ]),
                    if (reasons.isNotEmpty)
                      _Collapsible(
                          key: const ValueKey('candidate-reasons'),
                          title: 'Détails de la correspondance',
                          children: [
                            for (final reason in reasons)
                              Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text('• $reason',
                                      style: const TextStyle(fontSize: 13))),
                          ]),
                    if (allowed.isEmpty)
                      const EnrichmentNotice(
                          child: Text(
                              'Rien à appliquer : aucun champ vide de la ligne n’a de valeur proposée, ou la proposition n’est plus applicable (ligne modifiée, SIRET différent, déjà appliquée).')),
                    // En revue enchaînée, la réussite précédente est déjà
                    // comptée dans l'en-tête : pas de message sur la suivante.
                    if (s.message != null &&
                        !(_chained &&
                            s.message == EnrichmentUseCase.appliedMessage))
                      EnrichmentNotice(
                          error: s.message != EnrichmentUseCase.appliedMessage,
                          child: SelectableText(s.message!)),
                    const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                            'Cochez les champs vides à remplir. Les valeurs déjà saisies sont conservées.',
                            style: TextStyle(fontSize: 13, color: kText3))),
                    EnrichmentComparison(
                        columns: const [
                          DataColumn(label: Text('Appliquer')),
                          DataColumn(label: Text('Champ')),
                          DataColumn(label: Text('Avant')),
                          DataColumn(label: Text('Proposition')),
                          DataColumn(label: Text('Après')),
                        ],
                        muted: {
                          for (var i = 0; i < entries.length; i++)
                            if (!allowed.contains(entries[i].key) &&
                                !placed(entries[i].key))
                              i
                        },
                        rows: entries.map((e) {
                          final proposed =
                              MerchantImportRow.displayText(e.value);
                          final chosen = _fields.contains(e.key);
                          return DataRow(cells: [
                            DataCell(placed(e.key)
                                ? const Tooltip(
                                    message: 'Point posé sur la carte',
                                    child: Icon(Icons.push_pin,
                                        size: 20, color: kDanger))
                                : Checkbox(
                                value: chosen,
                                onChanged: !allowed.contains(e.key) || s.busy
                                    ? null
                                    : (value) => setState(() {
                                          final pair =
                                              e.key == 'lat' || e.key == 'lng'
                                                  ? {'lat', 'lng'}
                                                  : {e.key};
                                          if (value == true) {
                                            _fields.addAll(pair);
                                          } else {
                                            _fields.removeAll(pair);
                                            // Sans SIRET sur la ligne, retirer le SIRET retire la TVA liée.
                                            VatRules.select(
                                                _fields, e.key, false,
                                                rowSiretEmpty: rowSiretEmpty);
                                          }
                                        }))),
                            DataCell(Text(_fieldLabel(e.key),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600))),
                            DataCell(Text(before(e.key))),
                            DataCell(Text(proposed.isEmpty ? '—' : proposed)),
                            DataCell(placed(e.key)
                                ? Text('${pointValue(e.key)} (carte)',
                                    style: const TextStyle(
                                        color: kDangerText,
                                        fontWeight: FontWeight.w600))
                                : Text(chosen ? proposed : before(e.key),
                                    style: chosen
                                        ? const TextStyle(
                                            color: kSuccessText,
                                            fontWeight: FontWeight.w600)
                                        : null)),
                          ]);
                        }).toList()),
                    if (EnrichmentMiniMap.displayable(
                        c.fields['lat'], c.fields['lng']))
                      _Collapsible(
                          key: const ValueKey('candidate-map'),
                          title: 'Position sur la carte',
                          initiallyExpanded: true,
                          children: [
                            EnrichmentMiniMap(
                                lat: (c.fields['lat'] as num).toDouble(),
                                lng: (c.fields['lng'] as num).toDouble(),
                                precision: c.geoPrecision,
                                chosen: point,
                                canPlace: _canPlace(row),
                                onOpen: () => _openMap((
                                  lat: (c.fields['lat'] as num).toDouble(),
                                  lng: (c.fields['lng'] as num).toDouble()
                                ), row)),
                            if (point != null)
                              EnrichmentNotice(
                                  key: const ValueKey('map-point-notice'),
                                  child: Wrap(
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      spacing: 8,
                                      children: [
                                        Text(
                                            'Point posé sur la carte : ${IgnTiles.format(point)}. '
                                            'Il sera enregistré comme une saisie manuelle des coordonnées.'),
                                        TextButton(
                                            onPressed: _savingPoint
                                                ? null
                                                : () => setState(
                                                    () => _point = null),
                                            child: const Text(
                                                'Garder la position proposée')),
                                      ])),
                            if (_pointError != null)
                              EnrichmentNotice(
                                  error: true,
                                  child: Text(_pointError!)),
                          ]),
                    if (c.kind == 'establishment')
                      VatCandidateSection(
                          candidate: c,
                          capability: vat,
                          selected: _fields.contains(VatRules.field),
                          applicable: allowed.contains(VatRules.field),
                          busy: s.busy,
                          rowSiretEmpty: rowSiretEmpty,
                          rowValue: row?.textOf(VatRules.field) ?? '',
                          onChanged: (value) => setState(() => VatRules.select(
                              _fields, VatRules.field, value,
                              rowSiretEmpty: rowSiretEmpty))),
                    _sources(c),
                    if (c.approximate && point == null)
                      CheckboxListTile(
                          value: _acknowledge,
                          onChanged: s.busy
                              ? null
                              : (v) => setState(() => _acknowledge = v == true),
                          title: Text(
                              'J’accepte des coordonnées approximatives (${MerchantEnrichmentMessages.geoPrecision(c.geoPrecision)}), sans garantie de l’emplacement exact de la devanture.')),
                  ]),
              actions: [
                TextButton(
                    onPressed: s.busy ? null : () => Navigator.pop(context),
                    child: const Text('Retour')),
                if (_chained)
                  TextButton.icon(
                      onPressed: s.busy || _advancing ? null : _advance,
                      icon: const Icon(Icons.skip_next),
                      label: const Text('Passer')),
                FilledButton(
                    onPressed: canApply
                        ? () => _apply(thenNext: _chained)
                        : null,
                    child: Text(_chained
                        ? 'Appliquer et suivante'
                        : 'Appliquer au brouillon')),
              ]);
        });
  }

  /// Sources repliées, regroupées quand plusieurs champs viennent du même
  /// enregistrement : champs, source, date, référence et lien court.
  Widget _sources(EnrichmentCandidate c) {
    final groups =
        <String, ({EnrichmentSource source, List<String> fields, bool geo})>{};
    for (final e in c.sources.entries
        .where((e) => EnrichmentUseCase.fields.contains(e.key))) {
      final v = e.value;
      final key =
          '${v.provider}|${v.url}|${v.recordId}|${v.retrievedAt}|${v.precision}';
      final geo = e.key == 'lat' || e.key == 'lng';
      final group = groups[key];
      groups[key] = (
        source: v,
        fields: [...?group?.fields, _fieldLabel(e.key)],
        geo: (group?.geo ?? false) || geo
      );
    }
    if (groups.isEmpty) return const SizedBox.shrink();
    return _Collapsible(
        key: const ValueKey('candidate-sources'),
        title: 'Sources (${groups.length})',
        children: [
          for (final g in groups.values)
            Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(g.fields.join(', '),
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, color: kNavy800)),
                      Text(
                          [
                            MerchantEnrichmentMessages.provider(
                                g.source.provider),
                            MerchantEnrichmentMessages.sourceDate(
                                g.source.retrievedAt),
                            if (g.source.recordId != null)
                              'Réf. ${g.source.recordId}',
                            if (g.source.precision != null || g.geo)
                              'Précision : ${MerchantEnrichmentMessages.geoPrecision(g.source.precision)}',
                          ].join(' · '),
                          style: const TextStyle(fontSize: 12, color: kText3)),
                      EnrichmentSourceLink(g.source.url),
                    ])),
        ]);
  }
}

/// Section repliée par défaut (détails, sources).
class _Collapsible extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final bool initiallyExpanded;
  const _Collapsible(
      {super.key,
      required this.title,
      required this.children,
      this.initiallyExpanded = false});

  @override
  Widget build(BuildContext context) => ExpansionTile(
      initiallyExpanded: initiallyExpanded,
      title: Text(title,
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600, color: kNavy600)),
      iconColor: kNavy600,
      collapsedIconColor: kNavy600,
      tilePadding: EdgeInsets.zero,
      dense: true,
      shape: const Border(),
      collapsedShape: const Border(),
      expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
      childrenPadding: const EdgeInsets.only(left: 4, bottom: 8),
      children: children);
}

/// « 1 correspondance », « 3 correspondances ».
String _count(int n, String singular, [String? plural]) =>
    '$n ${n > 1 ? plural ?? '${singular}s' : singular}';

/// Icône et couleur de l'état d'une proposition.
({IconData icon, Color color}) _stateStyle(String state) {
  switch (state) {
    case 'matched':
      return (icon: Icons.check_circle_outline, color: kSuccessText);
    case 'applied':
      return (icon: Icons.done_all, color: kSuccessText);
    case 'ambiguous':
      return (icon: Icons.help_outline, color: kWarningText);
    case 'address_only':
      return (icon: Icons.place_outlined, color: kNavy600);
    case 'insufficient_input':
      return (icon: Icons.edit_note, color: kWarningText);
    case 'provider_unavailable':
      return (icon: Icons.cloud_off, color: kDangerText);
    case 'stale':
      return (icon: Icons.update, color: kDangerText);
    default:
      return (icon: Icons.search_off, color: kNeutralText);
  }
}

Widget _establishmentChip(String? status) => EnrichmentChip(
    MerchantEnrichmentMessages.establishmentStatus(status),
    color: status == 'closed'
        ? kDangerText
        : status == 'active'
            ? kSuccessText
            : kNeutralText);

Widget _matchChip(String level, {String? tooltip}) => EnrichmentChip(
    MerchantEnrichmentMessages.matchLevel(level),
    icon: Icons.join_inner,
    tooltip: tooltip,
    color: level == 'exact_identifier' || level == 'name_address'
        ? kSuccessText
        : kWarningText);

bool _comparable(EnrichmentUseCase s, EnrichmentProposal p,
    {required bool hasRepository}) {
  final row = s.currentRow(p.rowId);
  return (AssistantRepository.gatewayReady || hasRepository) &&
    s.available && s.capability?.chatResolution == true && !s.busy && s.batchEditable() &&
    (p.state == 'ambiguous' || (s.capability?.targetedResearch == true &&
      {'address_only', 'not_found', 'insufficient_input', 'provider_unavailable'}.contains(p.state))) &&
    p.batchId == s.batchId && (p.candidates.isNotEmpty || s.capability?.targetedResearch == true) &&
    p.candidates.length <= 5 && row != null && EnrichmentUseCase.eligible(row) && row.version == p.baseVersion;
}

// Libellés du catalogue partagé (domain/errors/merchant_enrichment_messages.dart) :
// délégués conservés pour les appels existants, aucune seconde copie des textes.
String _jobLabel(String value) => MerchantEnrichmentMessages.jobStatus(value);
String _stateLabel(String value) =>
    MerchantEnrichmentMessages.proposalState(value);
String _fieldLabel(String value) => MerchantEnrichmentMessages.field(value);

/// Onglets segmentés « Arc » (fond Navy 100, onglet choisi en blanc) sur un
/// [TabBar] : clavier, sémantique et [DefaultTabController] inchangés.
class _SegmentedTabs extends StatelessWidget {
  final List<Tab> tabs;
  const _SegmentedTabs({required this.tabs});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
            color: kNavy100, borderRadius: BorderRadius.circular(kRadiusSm)),
        child: TabBar(
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: kNavy900,
          unselectedLabelColor: kText2,
          labelStyle:
              GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
          unselectedLabelStyle:
              GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
          labelPadding: const EdgeInsets.symmetric(horizontal: 14),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          splashBorderRadius: BorderRadius.circular(8),
          indicator: BoxDecoration(
            color: kSurface,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x261F2240), blurRadius: 3, offset: Offset(0, 1))
            ],
          ),
          tabs: tabs,
        ),
      );
}
