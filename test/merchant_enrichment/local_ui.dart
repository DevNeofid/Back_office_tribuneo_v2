// Explicit local entry point only: no ApiClient, Env, session or real network.
// flutter run --no-pub -d chrome -t test/merchant_enrichment/local_ui.dart
import 'package:flutter/material.dart';
import 'package:back_office_tribuneo_v2/domain/models/merchant_import_row_model.dart';
import 'package:back_office_tribuneo_v2/domain/repositories/merchant_enrichment/enrichment_repository.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/merchant_enrichment/enrichment_usecase.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/merchant_enrichment/enrichment_panel.dart';
import 'fixtures.dart';

void main() => runApp(const MaterialApp(home: LocalEnrichmentReview()));

class LocalEnrichmentReview extends StatefulWidget {
  const LocalEnrichmentReview({super.key});
  @override
  State<LocalEnrichmentReview> createState() => _LocalEnrichmentReviewState();
}

class _LocalEnrichmentReviewState extends State<LocalEnrichmentReview> {
  final transport = FakeEnrichmentTransport();
  final Map<int, MerchantImportRow> rows = {1: row(1), 2: row(2)};
  late final session = EnrichmentUseCase(
    repository: EnrichmentRepository(transport),
    batchId: 12,
    enabled: true,
    currentRow: (id) => rows[id],
    batchEditable: () => true,
    replaceRows: (next) => setState(() {
      for (final r in next) {
        rows[r.id] = r;
      }
    }),
    reloadRows: () async => rows.values.toList(),
  );
  @override
  void dispose() {
    session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title:
                const Text('E02 · Vérification locale · Données synthétiques')),
        body: Padding(
            padding: const EdgeInsets.all(24),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text(
                  'Transport en mémoire. Aucune requête réelle. Ce point d’entrée est réservé aux tests.'),
              EnrichmentButton(
                  session: session,
                  rows: () => rows.values.toList(),
                  prepare: () async => true),
              ...rows.values.map((r) => Text(
                  'Ligne ${r.id} · ${r.status} · v${r.version} · ${r.fields}')),
              Wrap(spacing: 8, children: [
                OutlinedButton(
                    onPressed: () {
                      transport.currentJob =
                          jobJson(status: 'completed', done: 2);
                    },
                    child: const Text('Terminer le job synthétique')),
                OutlinedButton(
                    onPressed: () {
                      transport.offline = !transport.offline;
                    },
                    child: const Text('Basculer réseau absent')),
                OutlinedButton(
                    onPressed: () {
                      transport.applyError = {
                        'code': 'ENRICHMENT_VERSION_CONFLICT'
                      };
                    },
                    child: const Text('Provoquer un conflit')),
              ]),
            ])),
      );
}
