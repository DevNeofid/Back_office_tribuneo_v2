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
import '../../../config/responsive.dart';
import '../assistant/assistant_docked_panel.dart';
import '../../../domain/models/merchant_import_row_model.dart';
import '../../../domain/models/merchant_enrichment/enrichment_models.dart';
import '../../../domain/usecases/merchant_enrichment/enrichment_usecase.dart';
import '../../../domain/models/merchant_enrichment/vat_status.dart';
import 'vat_presentation.dart';

/// Shared by the real grid and the local, transport-free widget harness.
class EnrichmentButton extends StatefulWidget {
  final EnrichmentUseCase session;
  final List<MerchantImportRow> Function() rows;
  final Future<bool> Function() prepare;
  final AssistantRepository Function(ChatContextReference, String)? comparisonRepository;
  const EnrichmentButton(
      {super.key,
      required this.session,
      required this.rows,
      required this.prepare,
      this.comparisonRepository});
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
                  candidate: selection.candidate));
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
                        icon: const Icon(Icons.manage_search, size: 18),
                        label: const Text('Compléter les informations'))),
                if (!session.available)
                  IconButton(
                      tooltip: 'Vérifier la disponibilité de la recherche',
                      onPressed: session.busy ? null : session.initialize,
                      icon: const Icon(Icons.refresh, size: 18)),
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
  const EnrichmentPanel({super.key, required this.session, required this.rows,
    this.scopeActive, this.lifetime, this.comparisonRepository,
    this.dockComparison = false});
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
        session: s, proposal: selected.proposal, candidate: selected.candidate));
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

  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    return AnimatedBuilder(
        animation: s,
        builder: (context, _) {
          final eligible =
              widget.rows().where(EnrichmentUseCase.eligible).toList();
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
                      flex: 3,
                      child: SingleChildScrollView(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                            if (s.busy) const LinearProgressIndicator(),
                            if (s.message != null)
                              Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: EnrichmentNotice(
                                      error: true,
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
                              LinearProgressIndicator(
                                  value: job.total == 0
                                      ? 0
                                      : (job.done / job.total).clamp(0, 1)),
                              EnrichmentBadge(
                                  '${job.matched} correspondances · ${job.ambiguous} ambiguïtés · '
                                  '${job.unresolved} non résolues · ${job.stale} obsolètes'
                                  '${job.errorCode == null ? '' : ' · ${MerchantEnrichmentMessages.error(code: job.errorCode)}'}'),
                            ],
                            Wrap(
                                spacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  TextButton.icon(
                                      onPressed:
                                          s.busy ? null : () => s.resume(),
                                      icon: const Icon(Icons.refresh),
                                      label:
                                          const Text('Reprendre la lecture')),
                                  TextButton(
                                      onPressed: s.busy || job?.active != true
                                          ? null
                                          : s.cancel,
                                      child:
                                          const Text('Annuler la recherche')),
                                  if (job != null)
                                    Text(
                                        '${_jobLabel(job.status)} · ${job.done}/${job.total} lignes'),
                                ]),
                            ExpansionTile(
                                title:
                                    const Text('Informations sur la recherche'),
                                children: [
                                  Text(s.capability?.vat == true
                                      ? 'Propositions issues de sources publiques · Les valeurs déjà saisies sont conservées · TVA : source DGFiP datée, sans vérification VIES'
                                      : 'Propositions issues de sources publiques · Les valeurs déjà saisies sont conservées · TVA non vérifiée'),
                                  const Text(
                                      'Fermer met la lecture en pause ; la recherche serveur continue. Vous pouvez éditer le lot puis rouvrir ce dialogue.')
                                ]),
                            if (s.history != null &&
                                s.history!.items.isNotEmpty)
                              ExpansionTile(
                                  title:
                                      const Text('Historique des recherches'),
                                  children: [
                                    Wrap(
                                        spacing: 8,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        children: [
                                          SizedBox(
                                              width: 260,
                                              child: DropdownButton<String>(
                                                  isExpanded: true,
                                                  itemHeight: null,
                                                  value: s.history!.items.any((j) =>
                                                          j.id == job?.id)
                                                      ? job?.id
                                                      : null,
                                                  hint: const Text(
                                                      'Historique des recherches'),
                                                  items: s.history!.items
                                                      .map((j) => DropdownMenuItem(
                                                          value: j.id,
                                                          child: Padding(
                                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                                              child: Text(
                                                                  '${_jobLabel(j.status)} · ${MerchantEnrichmentMessages.sourceDate(j.updatedAt)}'))))
                                                      .toList(),
                                                  onChanged: s.busy
                                                      ? null
                                                      : (id) => s.resume(
                                                          historyOffset:
                                                              s.history!.offset,
                                                          jobId: id))),
                                          TextButton(
                                              onPressed: s.busy ||
                                                      s.history!.offset == 0
                                                  ? null
                                                  : () => s.resume(
                                                      historyOffset:
                                                          (s.history!.offset -
                                                                  20)
                                                              .clamp(0, 2000)),
                                              child: const Text(
                                                  'Recherches précédentes')),
                                          TextButton(
                                              onPressed: s.busy ||
                                                      !s.history!.hasNext
                                                  ? null
                                                  : () => s.resume(
                                                      historyOffset:
                                                          s.history!.offset +
                                                              s.history!.limit),
                                              child: const Text(
                                                  'Recherches suivantes')),
                                        ]),
                                  ]),
                          ]))),
                  const Divider(),
                  Expanded(
                      flex: 5,
                      child: DefaultTabController(
                          length: 2,
                          child: Column(children: [
                            const TabBar(
                                isScrollable: true,
                                tabAlignment: TabAlignment.start,
                                tabs: [
                                  Tab(text: 'Lignes à rechercher'),
                                  Tab(text: 'Propositions / historique')
                                ]),
                            Expanded(
                                child: TabBarView(children: [
                              Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                        child: ListView.builder(
                                            itemCount: eligible.length + 1,
                                            itemBuilder: (context, index) {
                                              if (index == 0) {
                                                return Padding(
                                                    padding: const EdgeInsets.only(bottom: 8),
                                                    child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                                        children: [
                                                          Text('${_selected.length} / ${eligible.length} lignes sélectionnées pour cette recherche (maximum ${s.capability?.maxRows ?? 2000}).'),
                                                          const Text('Sélection indépendante des cases de validation de la grille.'),
                                                        ]));
                                              }
                                              final row = eligible[index - 1];
                                              final details = [
                                                row.textOf('siret'),
                                                '${row.textOf('street')} ${row.textOf('zip')} ${row.textOf('city')}'.trim(),
                                              ].where((value) => value.isNotEmpty).join(' · ');
                                              return CheckboxListTile(
                                                  key: ValueKey(
                                                      'enrichment-scope-${row.id}'),
                                                  dense: true,
                                                  title: Tooltip(
                                                      message: row.textOf('name'),
                                                      child: Text(
                                                          'Ligne ${row.position} · ${row.textOf('name')}',
                                                          maxLines: 3,
                                                          overflow: TextOverflow.ellipsis)),
                                                  subtitle: details.isEmpty ? null : Text(details),
                                                  value: _selected
                                                      .contains(row.id),
                                                  onChanged: s.busy ||
                                                          job?.active == true ||
                                                          !s.batchEditable()
                                                      ? null
                                                      : (value) => setState(() {
                                                            if (value == true) {
                                                              _selected
                                                                  .add(row.id);
                                                            } else {
                                                              _selected.remove(
                                                                  row.id);
                                                            }
                                                          }));
                                            })),
                                    FilledButton(
                                        onPressed: s.busy ||
                                                job?.active == true ||
                                                _selected.isEmpty ||
                                                _selected.length >
                                                    (s.capability?.maxRows ??
                                                        0) ||
                                                !s.batchEditable()
                                            ? null
                                            : _start,
                                        child: Text(
                                            'Rechercher sur ces ${_selected.length} lignes')),
                                  ]),
                              Column(children: [
                                Expanded(
                                    child: page == null || page.items.isEmpty
                                        ? const Center(
                                            child: Text(
                                                'Aucune proposition publiée pour cette recherche.'))
                                        : ListView.builder(
                                            itemCount: page.items.length,
                                            itemBuilder: (context, index) {
                                              final p = page.items[index];
                                              return ExpansionTile(
                                                  key: ValueKey(
                                                      'proposal-${p.id}'),
                                                  title: Text(
                                                      'Ligne ${widget.rows().where((r) => r.id == p.rowId).firstOrNull?.position ?? p.rowId} · ${_stateLabel(p.state)}'),
                                                  subtitle: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(MerchantEnrichmentMessages.reasons(p.reasons)
                                                            .join(' · ')),
                                                        Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(12),
                                                            child: Wrap(
                                                                spacing: 8,
                                                                runSpacing: 8,
                                                                children: [
                                                                  if (s
                                                                      .canResearch(
                                                                          p))
                                                                    OutlinedButton(
                                                                        onPressed: () =>
                                                                            _research(
                                                                                p),
                                                                        child: const Text(
                                                                            'Préciser la recherche')),
                                                                  if (_canCompare(
                                                                      p))
                                                                    OutlinedButton(
                                                                        onPressed: _comparing
                                                                            ? null
                                                                            : () => _compare(
                                                                                p),
                                                                        child: const Text(
                                                                            'Comparer avec Néo')),
                                                                ])),
                                                      ]),
                                                  children: [
                                                    ...p.candidates
                                                        .map((c) => Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(12),
                                                            child: Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .stretch,
                                                                children: [
                                                                  Text(c.label,
                                                                      style: Theme.of(
                                                                              context)
                                                                          .textTheme
                                                                          .titleMedium),
                                                                  const SizedBox(
                                                                      height:
                                                                          8),
                                                                  ListTile(
                                                                    contentPadding:
                                                                        EdgeInsets
                                                                            .zero,
                                                                    subtitle: Text(
                                                                        '${c.kind == 'address' ? 'Adresse seule' : 'Établissement local'} · '
                                                                        'SIRET ${c.siret ?? 'non attribué'} · ${MerchantEnrichmentMessages.establishmentStatus(c.establishmentStatus)}\n'
                                                                        '${MerchantEnrichmentMessages.matchLevel(c.matchLevel)} · ${MerchantEnrichmentMessages.reasons(c.reasons).join(' · ')} · Précision : ${MerchantEnrichmentMessages.geoPrecision(c.geoPrecision)}'
                                                                        '${s.capability?.vat == true && c.kind == 'establishment' ? ' · TVA : ${vatStatusLabel(c.vatStatus, capability: true)}' : ''}'),
                                                                  ),
                                                                  Align(
                                                                      alignment:
                                                                          Alignment
                                                                              .centerRight,
                                                                      child: OutlinedButton(
                                                                          onPressed: s.busy
                                                                              ? null
                                                                              : () => showDialog<void>(context: context, builder: (_) => _CandidateReview(session: s, proposal: p, candidate: c)),
                                                                          child: const Text('Comparer / choisir'))),
                                                                ])))
                                                        .toList()
                                                  ]);
                                            })),
                                if (page != null)
                                  Wrap(
                                      spacing: 12,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        TextButton(
                                            onPressed: s.busy ||
                                                    page.offset == 0
                                                ? null
                                                : () => s.readPage(
                                                    (page.offset - page.limit)
                                                        .clamp(0, page.total)),
                                            child:
                                                const Text('Page précédente')),
                                        Text(
                                            '${page.offset + (page.items.isEmpty ? 0 : 1)}–${page.offset + page.items.length} / ${page.total}'),
                                        TextButton(
                                            onPressed: s.busy || !page.hasNext
                                                ? null
                                                : () => s.readPage(
                                                    page.offset + page.limit),
                                            child: const Text('Page suivante')),
                                      ]),
                              ]),
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
}

class _CandidateReview extends StatefulWidget {
  final EnrichmentUseCase session;
  final EnrichmentProposal proposal;
  final EnrichmentCandidate candidate;
  const _CandidateReview(
      {required this.session, required this.proposal, required this.candidate});
  @override
  State<_CandidateReview> createState() => _CandidateReviewState();
}

class _CandidateReviewState extends State<_CandidateReview> {
  final Set<String> _fields = {};
  bool _acknowledge = false;
  @override
  Widget build(BuildContext context) {
    final s = widget.session, p = widget.proposal, c = widget.candidate;
    return AnimatedBuilder(
        animation: s,
        builder: (context, _) {
          final row = s.currentRow(p.rowId);
          final allowed = s.applicable(p, c);
          _fields.removeWhere((f) => !allowed.contains(f));
          final geo = _fields.contains('lat');
          final vat = s.capability?.vat == true;
          final rowSiretEmpty =
              MerchantImportRow.normalized('siret', row?.valueOf('siret'))
                  .isEmpty;
          return EnrichmentDialog(
              onClose: s.busy ? null : () => Navigator.pop(context),
              title: Text('Choisir : ${c.label}'),
              content: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SelectableText(c.label,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    SelectableText(
                        'SIRET : ${c.siret ?? 'non attribué'} · SIREN : ${c.siren ?? 'non attribué'}\n'
                        'Raison sociale : ${c.legalName ?? 'non renseignée'} · ${MerchantEnrichmentMessages.establishmentStatus(c.establishmentStatus)}\n'
                        '${MerchantEnrichmentMessages.matchLevel(c.matchLevel)} · ${MerchantEnrichmentMessages.reasons(c.reasons).join(' · ')}\n'
                        'Précision géographique : ${MerchantEnrichmentMessages.geoPrecision(c.geoPrecision)} · TVA : ${vatStatusLabel(c.vatStatus, capability: vat)}'),
                    const Text(
                        'Choisissez explicitement les champs vides à appliquer. Les valeurs actuelles sont conservées.'),
                    if (allowed.isEmpty)
                      const Text(
                          'Application indisponible : la proposition n’est plus à jour ou a déjà été appliquée, le SIRET diffère de celui de la ligne, la ligne n’est plus à relire, ou aucun champ vide n’a de valeur sourcée.'),
                    if (s.message != null)
                      EnrichmentNotice(
                          error: true, child: SelectableText(s.message!)),
                    EnrichmentComparison(
                        columns: const [
                          DataColumn(label: Text('Appliquer')),
                          DataColumn(label: Text('Champ')),
                          DataColumn(label: Text('Avant')),
                          DataColumn(label: Text('Proposition')),
                          DataColumn(label: Text('Après')),
                        ],
                        rows: c.fields.entries
                            .where(
                                (e) => EnrichmentUseCase.fields.contains(e.key))
                            .map((e) => DataRow(cells: [
                                  DataCell(Checkbox(
                                      value: _fields.contains(e.key),
                                      onChanged: !allowed.contains(e.key) ||
                                              s.busy
                                          ? null
                                          : (value) => setState(() {
                                                final pair = e.key == 'lat' ||
                                                        e.key == 'lng'
                                                    ? {'lat', 'lng'}
                                                    : {e.key};
                                                if (value == true) {
                                                  _fields.addAll(pair);
                                                } else {
                                                  _fields.removeAll(pair);
                                                  // Sans SIRET sur la ligne, retirer le SIRET retire la TVA liée.
                                                  VatRules.select(
                                                      _fields, e.key, false,
                                                      rowSiretEmpty:
                                                          rowSiretEmpty);
                                                }
                                              }))),
                                  DataCell(Text(_fieldLabel(e.key))),
                                  DataCell(Text(
                                      row?.textOf(e.key).isNotEmpty == true
                                          ? row!.textOf(e.key)
                                          : 'Vide')),
                                  DataCell(Text(
                                      MerchantImportRow.displayText(e.value))),
                                  DataCell(Text(_fields.contains(e.key)
                                      ? MerchantImportRow.displayText(e.value)
                                      : row?.textOf(e.key).isNotEmpty == true
                                          ? row!.textOf(e.key)
                                          : 'Vide')),
                                ]))
                            .toList()),
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
                    const SizedBox(height: 12),
                    ...c.sources.entries
                        .where((e) => EnrichmentUseCase.fields.contains(e.key))
                        .map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: SelectableText(
                                '${_fieldLabel(e.key)} · ${MerchantEnrichmentMessages.provider(e.value.provider)} · ${MerchantEnrichmentMessages.sourceDate(e.value.retrievedAt)}\n'
                                '${e.value.url} · Référence : ${e.value.recordId ?? '—'}'
                                '${e.value.precision == null && e.key != 'lat' && e.key != 'lng' ? '' : ' · Précision : ${MerchantEnrichmentMessages.geoPrecision(e.value.precision)}'}'))),
                    if (c.approximate)
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
                FilledButton(
                    onPressed: s.busy ||
                            _fields.isEmpty ||
                            (geo && c.approximate && !_acknowledge) ||
                            !VatRules.selectionValid(_fields,
                                rowSiretEmpty: rowSiretEmpty)
                        ? null
                        : () async {
                            final applied = await s.apply(p, c, {..._fields},
                                acknowledge: _acknowledge);
                            if (!mounted) return;
                            if (applied) Navigator.pop(context);
                          },
                    child: const Text('Appliquer au brouillon')),
              ]);
        });
  }
}

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
