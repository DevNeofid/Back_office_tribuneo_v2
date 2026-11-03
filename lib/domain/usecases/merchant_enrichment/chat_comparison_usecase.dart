import 'package:flutter/foundation.dart';
import '../../models/merchant_enrichment/chat_context_reference.dart';
import '../../models/merchant_enrichment/enrichment_models.dart';
import '../../models/assistant_model.dart';
import '../../repositories/assistant_repository.dart';
import '../../errors/assistant_exception.dart';
import 'enrichment_usecase.dart';

/// Invalidated synchronously when the owning grid/button is disposed.
class ChatComparisonLifetime extends ChangeNotifier {
  bool active = true;
  void invalidate() {
    if (!active) return;
    active = false;
    notifyListeners();
  }
}

/// Read-only guard around the existing assistant transport. No apply/import method.
class ChatComparisonUseCase implements AssistantRepository {
  final EnrichmentUseCase enrichment;
  final ChatContextReference reference;
  final EnrichmentProposal proposal;
  final String tenant;
  final AssistantRepository assistant;
  final bool Function() active;
  final ChatComparisonLifetime? lifetime;
  ChatComparisonUseCase(
      {required this.enrichment,
      required this.reference,
      required this.proposal,
      required this.tenant,
      required this.assistant,
      required this.active,
      this.lifetime});

  bool get locallyValid {
    final row = enrichment.currentRow(reference.rowId);
    return active() &&
        lifetime?.active != false &&
        enrichment.available &&
        enrichment.capability?.chatResolution == true &&
        enrichment.batchEditable() &&
        row != null &&
        EnrichmentUseCase.eligible(row) &&
        row.version == reference.expectedVersion;
  }

  Future<void> check() async {
    if (!locallyValid ||
        await enrichment.repository.transport.currentTenant() != tenant ||
        !locallyValid) {
      throw const AssistantException(AssistantErrorKind.contextStale);
    }
  }

  @override
  Future<String> createSession() async {
    await check();
    final id = await assistant.createSession();
    await check();
    return id;
  }

  @override
  Future<AssistantReply> sendMessage(String sessionId, String message) async {
    await check();
    final reply = await assistant.sendMessage(sessionId, message);
    await check();
    // Only the dedicated comparison callback can render server candidate references.
    return AssistantReply(
        text: reply.text,
        blocks: reply.blocks
            .whereType<AssistantEnrichmentCandidatesBlock>()
            .where((b) => b.reference.same(reference))
            .toList());
  }

  Future<({EnrichmentProposal proposal, EnrichmentCandidate candidate})> review(
      AssistantEnrichmentCandidatesBlock block, String candidateId) async {
    await check();
    if (!block.reference.same(reference) ||
        !block.candidates.any((c) => c.id == candidateId)) {
      throw const AssistantException(AssistantErrorKind.contextStale);
    }
    final rows = await enrichment.reloadRows();
    await check();
    final row = rows.where((r) => r.id == reference.rowId).firstOrNull;
    if (row == null ||
        !EnrichmentUseCase.eligible(row) ||
        row.version != reference.expectedVersion) {
      throw const AssistantException(AssistantErrorKind.contextStale);
    }
    // Search the persisted job, including pagination, rather than trust the chat label.
    final job = await enrichment.repository
        .read(tenant, reference.batchId, proposal.jobId);
    if (job.id != proposal.jobId || job.batchId != reference.batchId) {
      throw const AssistantException(AssistantErrorKind.contextStale);
    }
    EnrichmentProposal? fresh;
    for (int offset = 0; offset < 2000; offset += 50) {
      final page = await enrichment.repository
          .proposals(tenant, reference.batchId, proposal.jobId, offset: offset);
      await check();
      fresh = page.items.where((p) => p.id == reference.proposalId).firstOrNull;
      if (fresh != null || !page.hasNext) break;
    }
    final candidate =
        fresh?.candidates.where((c) => c.id == candidateId).firstOrNull;
    if (fresh == null ||
        fresh.state != 'ambiguous' ||
        fresh.batchId != reference.batchId ||
        fresh.rowId != reference.rowId ||
        fresh.baseVersion != reference.expectedVersion ||
        fresh.jobId != proposal.jobId ||
        candidate == null) {
      throw const AssistantException(AssistantErrorKind.contextStale);
    }
    await check();
    enrichment.replaceRows(rows);
    return (proposal: fresh, candidate: candidate);
  }
}
