// Run by m12_verify.ps1: actual historical parsers are extracted only into its disposable copy.
import 'package:flutter_test/flutter_test.dart';
import 'package:back_office_tribuneo_v2/domain/models/merchant_enrichment/m12_legacy_enrichment_models.dart' as old;
import 'package:back_office_tribuneo_v2/domain/models/m12_legacy_assistant_model.dart' as old_chat;
import 'package:back_office_tribuneo_v2/domain/models/merchant_enrichment/m12_lot02_enrichment_models.dart' as lot02;
import 'package:back_office_tribuneo_v2/domain/models/m12_lot02_assistant_model.dart' as lot02_chat;
import 'vat_fixtures.dart';

void main() {
  test('actual lot02 parsers tolerate targeted capability and ignore unknown research block', () {
    final capability=lot02.EnrichmentCapability.fromJson({'enabled':true,'registry':true,
      'geocoding':true,'vat':true,'chat_resolution':true,'max_rows':2000,'targeted_research':true});
    expect(capability.chatResolution,isTrue);
    final reply=lot02_chat.AssistantReply.fromJson({'text':'Préciser','blocks':[
      {'type':'enrichment_research','batch_id':1,'row_id':1,
        'proposal_id':'00000000-0000-4000-8000-000000000001','expected_version':1}]});
    expect(reply.blocks,isEmpty);
    expect(reply.text,'Préciser');
  });
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
