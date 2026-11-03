import '../../models/merchant_enrichment/enrichment_models.dart';
import '../../models/merchant_enrichment/research_models.dart';
import 'enrichment_usecase.dart';

/// Owns one form lifetime. Criteria come exclusively from the row or server metadata.
class ResearchUseCase {
  final EnrichmentUseCase enrichment;
  final EnrichmentProposal proposal;
  final bool Function() active;
  String? tenant;
  bool closed = false;
  ResearchUseCase(this.enrichment, this.proposal, this.active);
  bool get valid => !closed && active() && enrichment.canResearch(proposal);
  Future<ResearchCriteria> load() async {
    if (!valid) throw const EnrichmentException();
    tenant = await enrichment.repository.transport.currentTenant();
    if (tenant!.isEmpty || !valid) throw const EnrichmentException();
    ResearchMetadata? metadata;
    try {
      metadata = await enrichment.repository
          .researchMetadata(tenant!, enrichment.batchId, proposal.jobId);
    } on EnrichmentException catch (e) {
      if (e.status != 404) rethrow;
    }
    if (!valid ||
        tenant != await enrichment.repository.transport.currentTenant() ||
        !valid) {
      throw const EnrichmentException();
    }
    if (metadata != null) {
      if (metadata.job.id != proposal.jobId ||
          metadata.job.batchId != enrichment.batchId ||
          metadata.rowId != proposal.rowId ||
          metadata.baseVersion != proposal.baseVersion) {
        throw const EnrichmentException();
      }
      return metadata.criteria;
    }
    final row = enrichment.currentRow(proposal.rowId)!;
    return ResearchCriteria(
        {for (final key in ResearchCriteria.limits.keys) key: row.textOf(key)});
  }

  Future<bool> confirm(ResearchCriteria criteria) async {
    if (!valid || tenant == null) return false;
    return enrichment.research(
        proposal, criteria, tenant!, () => !closed && active());
  }
}
