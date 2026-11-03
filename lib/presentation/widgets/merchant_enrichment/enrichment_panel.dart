import 'research_form.dart';
import 'research_metadata_view.dart';
import '../../../domain/usecases/merchant_enrichment/research_usecase.dart';
import '../../../domain/models/merchant_enrichment/chat_context_reference.dart';
import '../../../domain/repositories/assistant_repository.dart';
import '../../../domain/usecases/merchant_enrichment/chat_comparison_usecase.dart';
import 'chat_comparison.dart';
import 'package:flutter/material.dart';
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
  @override
  void dispose() {
    _comparisonLifetime.invalidate();
    _comparisonLifetime.dispose();
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
      await showDialog<void>(
          context: context,
          builder: (_) =>
              EnrichmentPanel(session: widget.session, rows: widget.rows,
                scopeActive: () => mounted, lifetime: _comparisonLifetime, comparisonRepository: widget.comparisonRepository));
    } finally {
      widget.session.pause();
      if (mounted) setState(() => _opening = false);
    }
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
  const EnrichmentPanel({super.key, required this.session, required this.rows,
    this.scopeActive, this.lifetime, this.comparisonRepository});
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
  bool _canCompare(EnrichmentProposal p) {
    final s = widget.session, row = s.currentRow(p.rowId);
    return (AssistantRepository.gatewayReady || widget.comparisonRepository != null) &&
      s.available && s.capability?.chatResolution == true && !s.busy && s.batchEditable() &&
      (p.state == 'ambiguous' || (s.capability?.targetedResearch == true &&
        {'address_only', 'not_found', 'insufficient_input', 'provider_unavailable'}.contains(p.state))) &&
      p.batchId == s.batchId && (p.candidates.isNotEmpty || s.capability?.targetedResearch == true) &&
      p.candidates.length <= 5 && row != null && EnrichmentUseCase.eligible(row) && row.version == p.baseVersion;
  }
  Future<void> _compare(EnrichmentProposal p) async {
    if (_comparing || !_canCompare(p)) return;
    setState(() => _comparing = true);
    final s = widget.session;
    try {
      final tenant = await s.repository.transport.currentTenant();
      if (!mounted || !_canCompare(p)) return;
      final reference = ChatContextReference(batchId: p.batchId, rowId: p.rowId,
        proposalId: p.id, expectedVersion: p.baseVersion);
      final comparison = ChatComparisonUseCase(enrichment: s, reference: reference, proposal: p,
        tenant: tenant, lifetime: widget.lifetime, active: () => mounted && (widget.scopeActive?.call() ?? true),
        assistant: widget.comparisonRepository?.call(reference, tenant) ??
          ApiAssistantRepository(enrichmentContext: reference, expectedTenant: tenant));
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
        builder: (context) => AlertDialog(
                title: const Text('Lancer la recherche ?'),
                content: SizedBox(
                    width: 520,
                    child: Text(
                        '${ids.length} ligne(s) explicitement sélectionnée(s).\n'
                        'Seuls les nom, SIRET et adresse publics sont utilisés. '
                        'La recherche prépare des propositions séparées. '
                        'Chaque application au brouillon sera à confirmer. '
                        'Le lot restera à relire, sans validation ni import.')),
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
          return AlertDialog(
            title: const Text('Compléter les informations'),
            content: SizedBox(
                width: 1000,
                height: 620,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(s.capability?.vat == true
                          ? 'Propositions sourcées · Champs humains prioritaires · TVA : source DGFiP datée, sans vérification VIES'
                          : 'Propositions sourcées · Champs humains prioritaires · TVA non vérifiée'),
                      const Text(
                          'Fermer met la lecture en pause ; la recherche serveur continue. Vous pouvez éditer le lot puis rouvrir ce dialogue.'),
                      if (s.busy) const LinearProgressIndicator(),
                      if (s.message != null)
                        Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: SelectableText(s.message!,
                                key: const ValueKey('enrichment-message'))),
                      Wrap(
                          spacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            TextButton.icon(
                                onPressed: s.busy ? null : () => s.resume(),
                                icon: const Icon(Icons.refresh),
                                label: const Text('Reprendre la lecture')),
                            TextButton(
                                onPressed: s.busy || job?.active != true
                                    ? null
                                    : s.cancel,
                                child: const Text('Annuler la recherche')),
                            if (job != null)
                              Text(
                                  '${_jobLabel(job.status)} · ${job.done}/${job.total} lignes'),
                          ]),
                      if (job != null) ...[
                        if (s.capability?.targetedResearch == true) ResearchMetadataView(
                          key: ValueKey('research-metadata-${job.id}'), session: s, jobId: job.id,
                          active: () => mounted && (widget.scopeActive?.call() ?? true)),
                        LinearProgressIndicator(
                            value: job.total == 0
                                ? 0
                                : (job.done / job.total).clamp(0, 1)),
                        Text(
                            '${job.matched} correspondances · ${job.ambiguous} ambiguïtés · '
                            '${job.unresolved} non résolues · ${job.stale} obsolètes'
                            '${job.errorCode == null ? '' : ' · ${job.errorCode}'}'),
                      ],
                      if (s.history != null && s.history!.items.isNotEmpty)
                        Wrap(
                            spacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              DropdownButton<String>(
                                  value: s.history!.items
                                          .any((j) => j.id == job?.id)
                                      ? job?.id
                                      : null,
                                  hint: const Text('Historique des recherches'),
                                  items: s.history!.items
                                      .map((j) => DropdownMenuItem(
                                          value: j.id,
                                          child: Text(
                                              '${j.id.substring(0, 8)} · ${_jobLabel(j.status)}')))
                                      .toList(),
                                  onChanged: s.busy
                                      ? null
                                      : (id) => s.resume(
                                          historyOffset: s.history!.offset,
                                          jobId: id)),
                              TextButton(
                                  onPressed: s.busy || s.history!.offset == 0
                                      ? null
                                      : () => s.resume(
                                          historyOffset:
                                              (s.history!.offset - 20)
                                                  .clamp(0, 2000)),
                                  child: const Text('Recherches précédentes')),
                              TextButton(
                                  onPressed: s.busy || !s.history!.hasNext
                                      ? null
                                      : () => s.resume(
                                          historyOffset: s.history!.offset +
                                              s.history!.limit),
                                  child: const Text('Recherches suivantes')),
                            ]),
                      const Divider(),
                      Expanded(
                          child: DefaultTabController(
                              length: 2,
                              child: Column(children: [
                                const TabBar(tabs: [
                                  Tab(text: 'Lignes à rechercher'),
                                  Tab(text: 'Propositions / historique')
                                ]),
                                Expanded(
                                    child: TabBarView(children: [
                                  Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Text(
                                            '${_selected.length} / ${eligible.length} lignes sélectionnées pour cette recherche (maximum ${s.capability?.maxRows ?? 2000}).'),
                                        const Text(
                                            'Sélection indépendante des cases de validation de la grille.'),
                                        Expanded(
                                            child: ListView.builder(
                                                itemCount: eligible.length,
                                                itemBuilder: (context, index) {
                                                  final row = eligible[index];
                                                  return CheckboxListTile(
                                                      key: ValueKey(
                                                          'enrichment-scope-${row.id}'),
                                                      dense: true,
                                                      title: Text(
                                                          'Ligne ${row.position} · ${row.textOf('name')}'),
                                                      subtitle: Text(
                                                          '${row.textOf('siret')} · ${row.textOf('street')} ${row.textOf('zip')} ${row.textOf('city')}'),
                                                      value: _selected
                                                          .contains(row.id),
                                                      onChanged: s.busy ||
                                                              job?.active ==
                                                                  true ||
                                                              !s.batchEditable()
                                                          ? null
                                                          : (value) =>
                                                              setState(() {
                                                                if (value ==
                                                                    true) {
                                                                  _selected.add(
                                                                      row.id);
                                                                } else {
                                                                  _selected
                                                                      .remove(row
                                                                          .id);
                                                                }
                                                              }));
                                                })),
                                        FilledButton(
                                            onPressed: s.busy ||
                                                    job?.active == true ||
                                                    _selected.isEmpty ||
                                                    _selected.length >
                                                        (s.capability
                                                                ?.maxRows ??
                                                            0) ||
                                                    !s.batchEditable()
                                                ? null
                                                : _start,
                                            child: Text(
                                                'Rechercher sur ces ${_selected.length} lignes')),
                                      ]),
                                  Column(children: [
                                    Expanded(
                                        child: page == null ||
                                                page.items.isEmpty
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
                                                      subtitle: Text(p.reasons
                                                          .join(' · ')),
                                                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                                        if (s.canResearch(p)) OutlinedButton(
                                                          onPressed: () => _research(p),
                                                          child: const Text('Préciser la recherche')),
                                                        if (_canCompare(p)) OutlinedButton(
                                                          onPressed: _comparing ? null : () => _compare(p),
                                                          child: const Text('Comparer avec Néo')),
                                                      ]),
                                                      children: p.candidates
                                                          .map((c) => ListTile(
                                                                title: Text(
                                                                    c.label),
                                                                subtitle: Text(
                                                                    '${c.kind == 'address' ? 'Adresse seule' : 'Établissement local'} · '
                                                                    'SIRET ${c.siret ?? 'non attribué'} · ${c.establishmentStatus ?? ''}\n'
                                                                    '${c.matchLevel} · ${c.reasons.join(' · ')} · Précision : ${c.geoPrecision ?? 'unknown'}'
                                                                    '${s.capability?.vat == true && c.kind == 'establishment' ? ' · TVA : ${vatStatusLabel(c.vatStatus, capability: true)}' : ''}'),
                                                                trailing: OutlinedButton(
                                                                    onPressed: s
                                                                            .busy
                                                                        ? null
                                                                        : () => showDialog<void>(
                                                                            context:
                                                                                context,
                                                                            builder: (_) => _CandidateReview(
                                                                                session: s,
                                                                                proposal: p,
                                                                                candidate: c)),
                                                                    child: const Text('Comparer / choisir')),
                                                              ))
                                                          .toList());
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
                                                    : () => s.readPage((page
                                                                .offset -
                                                            page.limit)
                                                        .clamp(0, page.total)),
                                                child: const Text(
                                                    'Page précédente')),
                                            Text(
                                                '${page.offset + (page.items.isEmpty ? 0 : 1)}–${page.offset + page.items.length} / ${page.total}'),
                                            TextButton(
                                                onPressed:
                                                    s.busy || !page.hasNext
                                                        ? null
                                                        : () => s.readPage(
                                                            page.offset +
                                                                page.limit),
                                                child: const Text(
                                                    'Page suivante')),
                                          ]),
                                  ]),
                                ])),
                              ]))),
                    ])),
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
          return AlertDialog(
              title: Text('Choisir : ${c.label}'),
              content: SizedBox(
                  width: 900,
                  height: 500,
                  child: SingleChildScrollView(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                        SelectableText(
                            'Établissement : ${c.siret ?? 'non attribué'} · Unité légale : ${c.siren ?? 'non attribuée'}\n'
                            'Raison sociale : ${c.legalName ?? 'non renseignée'} · État : ${c.establishmentStatus ?? 'inconnu'}\n'
                            '${c.matchLevel} · ${c.reasons.join(' · ')}\n'
                            'Précision géographique : ${c.geoPrecision ?? 'unknown'} · TVA : ${vatStatusLabel(c.vatStatus, capability: vat)}'),
                        const Text(
                            'Choisissez explicitement les champs vides à appliquer. Les valeurs actuelles sont conservées.'),
                        if (allowed.isEmpty)
                          const Text(
                              'Application indisponible : proposition obsolète, déjà appliquée, conflit d’identité, ligne non pending ou aucun champ vide sourcé.'),
                        if (s.message != null) SelectableText(s.message!),
                        SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                                columnSpacing: 16,
                                columns: const [
                                  DataColumn(label: Text('Appliquer')),
                                  DataColumn(label: Text('Champ')),
                                  DataColumn(label: Text('Avant')),
                                  DataColumn(label: Text('Proposition')),
                                  DataColumn(label: Text('Après')),
                                ],
                                rows: c.fields.entries
                                    .where((e) => EnrichmentUseCase.fields
                                        .contains(e.key))
                                    .map((e) => DataRow(cells: [
                                          DataCell(Checkbox(
                                              value: _fields.contains(e.key),
                                              onChanged: !allowed
                                                          .contains(e.key) ||
                                                      s.busy
                                                  ? null
                                                  : (value) => setState(() {
                                                        final pair = e.key ==
                                                                    'lat' ||
                                                                e.key == 'lng'
                                                            ? {'lat', 'lng'}
                                                            : {e.key};
                                                        if (value == true) {
                                                          _fields.addAll(pair);
                                                        } else {
                                                          _fields
                                                              .removeAll(pair);
                                                          // Sans SIRET sur la ligne, retirer le SIRET retire la TVA liée.
                                                          VatRules.select(
                                                              _fields,
                                                              e.key,
                                                              false,
                                                              rowSiretEmpty:
                                                                  rowSiretEmpty);
                                                        }
                                                      }))),
                                          DataCell(Text(_fieldLabel(e.key))),
                                          DataCell(Text(
                                              row?.textOf(e.key).isNotEmpty ==
                                                      true
                                                  ? row!.textOf(e.key)
                                                  : 'Vide')),
                                          DataCell(Text(
                                              MerchantImportRow.displayText(
                                                  e.value))),
                                          DataCell(Text(_fields.contains(e.key)
                                              ? MerchantImportRow.displayText(
                                                  e.value)
                                              : row?.textOf(e.key).isNotEmpty ==
                                                      true
                                                  ? row!.textOf(e.key)
                                                  : 'Vide')),
                                        ]))
                                    .toList())),
                        if (c.kind == 'establishment')
                          VatCandidateSection(
                              candidate: c,
                              capability: vat,
                              selected: _fields.contains(VatRules.field),
                              applicable: allowed.contains(VatRules.field),
                              busy: s.busy,
                              rowSiretEmpty: rowSiretEmpty,
                              rowValue: row?.textOf(VatRules.field) ?? '',
                              onChanged: (value) => setState(() =>
                                  VatRules.select(
                                      _fields, VatRules.field, value,
                                      rowSiretEmpty: rowSiretEmpty))),
                        const SizedBox(height: 12),
                        ...c.sources.entries
                            .where(
                                (e) => EnrichmentUseCase.fields.contains(e.key))
                            .map((e) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: SelectableText(
                                    '${_fieldLabel(e.key)} · ${e.value.provider} · ${e.value.retrievedAt}\n'
                                    '${e.value.url} · Référence : ${e.value.recordId ?? '—'} · Précision : ${e.value.precision ?? 'unknown'}'))),
                        if (c.approximate)
                          CheckboxListTile(
                              value: _acknowledge,
                              onChanged: s.busy
                                  ? null
                                  : (v) =>
                                      setState(() => _acknowledge = v == true),
                              title: Text(
                                  'J’accepte des coordonnées de précision ${c.geoPrecision ?? 'unknown'}, sans certification d’un emplacement de devanture.')),
                      ]))),
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

String _jobLabel(String value) =>
    const {
      'queued': 'En attente',
      'running': 'En cours',
      'completed': 'Terminée',
      'completed_with_errors': 'Terminée avec erreurs',
      'failed': 'Échec',
      'cancelled': 'Annulée'
    }[value] ??
    value;
String _stateLabel(String value) =>
    const {
      'matched': 'Correspondance',
      'ambiguous': 'Choix manuel requis',
      'address_only': 'Adresse seule',
      'not_found': 'Aucun résultat',
      'insufficient_input': 'Informations insuffisantes',
      'provider_unavailable': 'Source indisponible',
      'stale': 'Obsolète',
      'skipped': 'Ignorée',
      'applied': 'Appliquée'
    }[value] ??
    value;
String _fieldLabel(String value) =>
    const {
      'name': 'Nom',
      'siret': 'SIRET',
      'street': 'Adresse',
      'zip': 'Code postal',
      'city': 'Ville',
      'country': 'Pays',
      'naf': 'NAF',
      'intracommunity_vat_number': 'TVA intracommunautaire',
      'lat': 'Latitude',
      'lng': 'Longitude'
    }[value] ??
    value;
