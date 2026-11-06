import 'package:back_office_tribuneo_v2/presentation/widgets/tribuneo_loader.dart';
import '../../../domain/errors/merchant_enrichment_messages.dart';
import 'ui/enrichment_dialog.dart';
import 'package:flutter/material.dart';
import '../../utils/common.dart';
import '../arc/arc.dart';
import '../../../domain/models/merchant_enrichment/research_models.dart';
import '../../../domain/usecases/merchant_enrichment/research_usecase.dart';

class ResearchForm extends StatefulWidget {
  final ResearchUseCase session;
  const ResearchForm({super.key, required this.session});
  @override
  State<ResearchForm> createState() => _ResearchFormState();
}

class _ResearchFormState extends State<ResearchForm> {
  final inputs = <String, TextEditingController>{};
  bool loading = true, sending = false;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final criteria = await widget.session.load();
      if (!mounted) return;
      for (final entry in criteria.values.entries) {
        inputs[entry.key] = TextEditingController(text: entry.value);
      }
    } catch (_) {
      error = 'Critères indisponibles. Fermez puis actualisez la recherche.';
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> confirm() async {
    if (sending || loading || inputs.length != 6) return;
    final criteria =
        ResearchCriteria(inputs.map((k, v) => MapEntry(k, v.text)));
    if (criteria.error != null) {
      setState(() => error = criteria.error);
      return;
    }
    setState(() {
      sending = true;
      error = null;
    });
    final accepted = await widget.session.confirm(criteria);
    if (!mounted) return;
    if (accepted) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      sending = false;
      error = widget.session.enrichment.message ??
          'La ligne ou la session a changé. Fermez puis actualisez la recherche.';
    });
  }

  @override
  void dispose() {
    widget.session.closed = true;
    for (final c in inputs.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// Contexte humain : position et nom de la ligne, sans identifiant ni version technique.
  String _rowLabel() {
    final p = widget.session.proposal;
    final row = widget.session.enrichment.currentRow(p.rowId);
    final name = row?.textOf('name') ?? '';
    return 'Ligne ${row?.position ?? p.rowId}${name.isEmpty ? '' : ' · $name'}';
  }

  /// Champs affichés sur toute la largeur (nom, adresse).
  static const Set<String> _wide = {'name', 'street'};

  /// Champs en chiffres à chasse fixe.
  static const Set<String> _mono = {'siret', 'zip'};

  @override
  Widget build(BuildContext context) => PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) widget.session.closed = true;
      },
      child: EnrichmentDialog(
          maxWidth: 640,
          onClose: () => Navigator.pop(context),
          eyebrow: _rowLabel(),
          title: const Text('Préciser la recherche'),
          content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                    'Confirmez les six critères publics ci-dessous. Les cellules restent inchangées. '
                    'Toute application au brouillon demandera une confirmation indépendante.',
                    style: TextStyle(color: kText2)),
                if (widget.session.proposal.state == 'provider_unavailable')
                  const EnrichmentNotice(
                      warning: true,
                      child: Text(
                          'La source était indisponible lors de la recherche : cela ne signifie pas que le commerce est introuvable.')),
                const SizedBox(height: 16),
                if (loading || sending) ...[
                  ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: const TribuneoLoadingProgress()),
                  const SizedBox(height: 12),
                ],
                LayoutBuilder(builder: (context, constraints) {
                  final bool twoColumns = constraints.maxWidth >= 520;
                  final double half = twoColumns
                      ? (constraints.maxWidth - 16) / 2
                      : constraints.maxWidth;
                  return Wrap(spacing: 16, runSpacing: 16, children: [
                    for (final entry in inputs.entries)
                      SizedBox(
                        width: _wide.contains(entry.key)
                            ? constraints.maxWidth
                            : half,
                        child: TextField(
                          key: ValueKey('research-${entry.key}'),
                          controller: entry.value,
                          enabled: !sending,
                          textInputAction: TextInputAction.next,
                          style: _mono.contains(entry.key)
                              ? ArcText.data().copyWith(fontSize: 14)
                              : null,
                          decoration: InputDecoration(
                              labelText: MerchantEnrichmentMessages.field(entry.key)),
                        ),
                      ),
                  ]);
                }),
                if (error != null)
                  EnrichmentNotice(
                      error: true,
                      child:
                          Text(error!, key: const ValueKey('research-error'))),
              ]),
          actions: [
            OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer')),
            FilledButton(
                // Action de la maquette en navy : la recherche n'applique rien.
                style: FilledButton.styleFrom(
                    backgroundColor: kNavy600, foregroundColor: Colors.white),
                onPressed:
                    loading || sending || inputs.length != 6 ? null : confirm,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: TribuneoLoader())
                      : const Icon(Icons.refresh_rounded, size: 18),
                  const SizedBox(width: 8),
                  const Flexible(child: Text('Relancer la recherche')),
                ])),
          ]));
}
