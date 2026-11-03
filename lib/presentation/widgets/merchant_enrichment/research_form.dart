import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) => PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) widget.session.closed = true;
      },
      child: AlertDialog(
          title: const Text('Préciser la recherche'),
          content: SizedBox(
              width: 560,
              child: SingleChildScrollView(
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                    Text(
                        'Ligne ${widget.session.proposal.rowId} · Version ${widget.session.proposal.baseVersion}'),
                    if (widget.session.proposal.state == 'provider_unavailable')
                      const Text(
                          'Le fournisseur était indisponible. Cela ne signifie pas que le commerce est introuvable.'),
                    const Text(
                        'Confirmez les six critères publics ci-dessous. Les cellules restent inchangées. '
                        'Toute application au brouillon demandera une confirmation indépendante.'),
                    if (loading || sending) const LinearProgressIndicator(),
                    for (final entry in inputs.entries)
                      TextField(
                          key: ValueKey('research-${entry.key}'),
                          controller: entry.value,
                          enabled: !sending,
                          decoration: InputDecoration(
                              labelText: const {
                            'name': 'Nom',
                            'siret': 'SIRET',
                            'street': 'Rue',
                            'zip': 'Code postal',
                            'city': 'Ville',
                            'country': 'Pays'
                          }[entry.key])),
                    if (error != null)
                      Text(error!, key: const ValueKey('research-error')),
                  ]))),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer')),
            FilledButton(
                onPressed:
                    loading || sending || inputs.length != 6 ? null : confirm,
                child: const Text('Relancer la recherche'))
          ]));
}
