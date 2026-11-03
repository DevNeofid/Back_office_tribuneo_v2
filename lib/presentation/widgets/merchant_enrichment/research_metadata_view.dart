import 'package:flutter/material.dart';
import '../../../domain/models/merchant_enrichment/enrichment_models.dart';
import '../../../domain/models/merchant_enrichment/research_models.dart';
import '../../../domain/usecases/merchant_enrichment/enrichment_usecase.dart';

/// Historical criteria remain readable even when applying that job is stale.
class ResearchMetadataView extends StatefulWidget {
  final EnrichmentUseCase session;
  final String jobId;
  final bool Function() active;
  const ResearchMetadataView(
      {super.key,
      required this.session,
      required this.jobId,
      required this.active});
  @override
  State<ResearchMetadataView> createState() => _ResearchMetadataViewState();
}

class _ResearchMetadataViewState extends State<ResearchMetadataView> {
  late Future<ResearchMetadata?> result;
  @override
  void initState() {
    super.initState();
    result = load();
  }

  @override
  void didUpdateWidget(ResearchMetadataView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.jobId != widget.jobId || oldWidget.session != widget.session)
      result = load();
  }

  Future<ResearchMetadata?> load() async {
    final session = widget.session, id = widget.jobId;
    final tenant = await session.repository.transport.currentTenant();
    if (!mounted || !widget.active() || tenant.isEmpty)
      throw const EnrichmentException();
    ResearchMetadata metadata;
    try {
      metadata = await session.repository
          .researchMetadata(tenant, session.batchId, id);
    } on EnrichmentException catch (e) {
      if (e.status == 404) return null;
      rethrow;
    }
    if (!mounted ||
        !widget.active() ||
        await session.repository.transport.currentTenant() != tenant ||
        metadata.job.id != id ||
        metadata.job.batchId != session.batchId)
      throw const EnrichmentException();
    return metadata;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<ResearchMetadata?>(
      future: result,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done)
          return const SizedBox.shrink();
        if (snapshot.hasError)
          return const Text(
              'Critères historiques indisponibles. Reprenez la lecture pour réessayer.');
        final metadata = snapshot.data;
        if (metadata == null) return const SizedBox.shrink();
        return SelectableText(
            'Critères utilisés · Ligne ${metadata.rowId} · Version ${metadata.baseVersion} : '
            '${metadata.criteria.values.entries.map((e) => '${e.key} : ${e.value}').join(' · ')}',
            key: const ValueKey('research-metadata'));
      });
}
