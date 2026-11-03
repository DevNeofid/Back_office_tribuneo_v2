// Run by m12_verify.ps1: actual historical parsers are extracted only into its disposable copy.
import 'package:flutter_test/flutter_test.dart';
import 'package:back_office_tribuneo_v2/domain/models/merchant_enrichment/m12_legacy_enrichment_models.dart' as old;
import 'package:back_office_tribuneo_v2/domain/models/m12_legacy_assistant_model.dart' as old_chat;
import 'vat_fixtures.dart';

void main() {
  test('actual BO v1 parser accepts a sourced v1.1 proposal', () {
    final proposal = old.EnrichmentProposal.fromJson(vatProposalJson(vatCandidateJson()));
    expect(proposal.candidates.single.sources['intracommunity_vat_number']!.provider, 'dgfip_tva');
    expect(proposal.candidates.single.siret, vatSiret);
  });
  test('actual old assistant ignores the new server candidate block', () {
    final reply = old_chat.AssistantReply.fromJson({
      'text': 'Comparer', 'blocks': [{'type': 'enrichment_candidates', 'candidates': []}],
    });
    expect(reply.text, 'Comparer');
    expect(reply.blocks, isEmpty);
  });
}
