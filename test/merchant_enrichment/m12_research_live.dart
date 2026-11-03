part of 'live_local_api.dart';

ApiAssistantRepository _assistant(_LocalApi api, ChatContextReference reference) =>
    ApiAssistantRepository(enrichmentContext: reference, expectedTenant: _tenant,
      tenantResolver: api.currentTenant, post: (path, body, tenant, timeout) async {
        final r = await api.raw('POST', path, tenant: tenant, body: body ?? {});
        return Response(statusCode: r.status, data: r.body,
          requestOptions: RequestOptions(path: path));
      });
ChatContextReference _reference(EnrichmentProposal p) => ChatContextReference(
    batchId: p.batchId, rowId: p.rowId, proposalId: p.id, expectedVersion: p.baseVersion);

void _registerLot03Tests() {
  for (var n = 0; n < 8; n++) {
    final flags = n;
    test('lot03 HTTP matrix $flags: precision job result comparison review confirmed apply', () async {
      final vat = flags & 1 != 0, chat = flags & 2 != 0, research = flags & 4 != 0;
      final api = _LocalApi(18087 + flags);
      await api.login();
      final batch = await _createBatch(api, [{'name': 'ESSAI ABSENT', 'zip': '04000'}]);
      final grid = _Grid()..replace(await _rows(api, batch));
      final session = _session(api, batch, grid);
      addTearDown(session.dispose);
      await session.initialize();
      expect([session.capability!.vat, session.capability!.chatResolution,
        session.capability!.targetedResearch], [vat, chat, research]);
      final row = grid.rows.values.single, before = _state(grid.rows.values.single);
      await session.start([row.id]);
      await _until(() => session.job?.active == false && !session.busy);
      await session.readPage(0);
      final source = session.page!.items.single, originalJob = session.job!.id;
      expect(source.state, 'not_found');
      expect(source.candidates, isEmpty);
      final ref = _reference(source), assistant = _assistant(api, _reference(source));
      final oldChat = await assistant.createSession();
      final unresolved = await api.raw('POST', 'chat/sessions/$oldChat/messages', tenant: _tenant,
        body: {'message': 'Préciser', 'request_id': 'a' * 32, 'enrichment_context': ref.toJson()});
      expect(unresolved.status, !chat ? 503 : !research ? 409 : 200, reason: '${unresolved.body}');
      if (chat && research) {
        final reply = AssistantReply.fromJson(object(unresolved.body['data']['reply']));
        expect(reply.blocks.single, isA<AssistantEnrichmentResearchBlock>());
        final c = ChatComparisonUseCase(enrichment: session, reference: ref, proposal: source,
          tenant: _tenant, assistant: assistant, active: () => true);
        await c.prepareResearch(reply.blocks.single as AssistantEnrichmentResearchBlock);
      }
      final criteria = ResearchCriteria({'name': 'ESSAI MULTIPLE', 'siret': '', 'street': '',
        'zip': '04000', 'city': 'DIGNE-LES-BAINS', 'country': 'France'});
      final body = <String,dynamic>{'row_id': row.id, 'expected_version': row.version,
        'source_proposal_id': source.id, 'search': criteria.toJson()};
      if (!research) {
        final error = await _refusal(session.repository.startResearch(_tenant, batch, body, 'off-$batch'));
        expect(error.code, 'ENRICHMENT_RESEARCH_DISABLED');
        expect(_state((await _rows(api, batch)).single), before);
        return;
      }
      final form = ResearchUseCase(session, source, () => true);
      expect((await form.load()).values['name'], 'ESSAI ABSENT');
      expect(api.researchPosts, isEmpty, reason: 'Loading criteria cannot launch a job');
      expect(await form.confirm(criteria), isTrue, reason: session.message);
      expect(api.researchPosts, hasLength(1));
      final targeted = session.job!.id;
      expect(targeted, isNot(originalJob));
      await _until(() => session.job?.active == false && !session.busy);
      await session.readPage(0);
      final proposal = session.page!.items.single;
      expect(proposal.state, 'ambiguous');
      expect(proposal.candidates, hasLength(2));
      expect(proposal.candidates.first.vatStatus, vat ? 'found' : 'not_checked');
      final metadata = await session.repository.researchMetadata(_tenant, batch, targeted);
      expect([metadata.sourceProposalId, metadata.rowId, metadata.baseVersion], [source.id, row.id, row.version]);
      expect(metadata.criteria.values['country'], 'FR');
      final sent = api.researchPosts.single;
      final replay = await api.raw('POST', 'merchant-import/$batch/enrichment-research-jobs',
        tenant: _tenant, body: sent.body, headers: sent.headers);
      expect([replay.status, replay.replayed, replay.body['data']['id']], [202, true, targeted]);
      expect((await session.repository.proposals(_tenant, batch, originalJob)).items.single.id, source.id);
      expect(_state((await _rows(api, batch)).single), before);
      if (chat) {
        final newRef = _reference(proposal), nextAssistant = _assistant(api, _reference(proposal));
        final comparison = ChatComparisonUseCase(enrichment: session, reference: newRef, proposal: proposal,
          tenant: _tenant, assistant: nextAssistant, active: () => true);
        final newChat = await comparison.createSession();
        expect(newChat, isNot(oldChat));
        final rebind = await api.raw('POST', 'chat/sessions/$oldChat/messages', tenant: _tenant,
          body: {'message': 'Comparer', 'request_id': 'b' * 32, 'enrichment_context': newRef.toJson()});
        expect(rebind.status, 409);
        final reply = await comparison.sendMessage(newChat, 'Comparer');
        expect(reply.blocks, hasLength(2));
        final block = reply.blocks.whereType<AssistantEnrichmentCandidatesBlock>().single;
        final reviewed = await comparison.review(block, proposal.candidates.first.id);
        expect(reviewed.candidate.id, proposal.candidates.first.id);
        expect(api.calls.where((c) => c.endsWith('/apply')), isEmpty);
      }
      // Explicit, separate human confirmation after review. The research form never calls apply.
      expect(await session.apply(proposal, proposal.candidates.first,
        {'siret', if (vat) 'intracommunity_vat_number'}), isTrue, reason: session.message);
      final after = (await _rows(api, batch)).single;
      expect(after.version, row.version + 1);
      expect(after.status, 'pending');
      expect(after.valueOf('name'), row.valueOf('name'), reason: 'missing_only preserves human values');
      expect(after.valueOf('siret'), proposal.candidates.first.siret);
      expect((await session.repository.researchMetadata(_tenant, batch, targeted)).baseVersion, row.version);
      if (chat) {
        final stale = await api.raw('POST', 'chat/sessions/$oldChat/messages', tenant: _tenant,
          body: {'message': 'Préciser', 'request_id': 'a' * 32, 'enrichment_context': ref.toJson()});
        expect(stale.status, 409, reason: 'Cached reply must be revalidated after apply');
      }
    }, timeout: const Timeout(Duration(minutes: 3)));
  }
  test('lot03 HTTP provider error preserves failure reason and original cells', () async {
    final api = _LocalApi(18093); await api.login();
    final batch = await _createBatch(api, [{'name': 'ESSAI ABSENT', 'zip': '04000'}]);
    final grid = _Grid()..replace(await _rows(api,batch));
    final s = _session(api,batch,grid); addTearDown(s.dispose);
    await s.initialize(); await s.start([grid.rows.values.single.id]);
    await _until(() => s.job?.active == false && !s.busy); await s.readPage(0);
    final p=s.page!.items.single, before=_state(grid.rows.values.single);
    final f=ResearchUseCase(s,p,()=>true); await f.load();
    expect(await f.confirm(ResearchCriteria({'name':'ESSAI PANNE','siret':'','street':'',
      'zip':'04000','city':'','country':'FR'})),isTrue);
    await _until(() => s.job?.active == false && !s.busy); await s.readPage(0);
    final failed=s.page!.items.single;
    expect(failed.state,'provider_unavailable');
    expect(s.job!.status,'completed_with_errors');
    final a=_assistant(api,_reference(failed)), id=await _assistant(api,_reference(failed)).createSession();
    final reply=await a.sendMessage(id,'Expliquer la panne');
    expect(reply.blocks.single,isA<AssistantEnrichmentResearchBlock>());
    expect(_state((await _rows(api,batch)).single),before);
  }, timeout: const Timeout(Duration(minutes:3)));
  for (final revoke in [false, true]) {
    test('lot03 HTTP ${revoke ? "revocation" : "stale"} in flight discards Hermes reply', () async {
      final api=_LocalApi(18093); await api.login();
      final batch=await _createBatch(api,[{'name':'ESSAI ABSENT','zip':'04000'}]);
      final grid=_Grid()..replace(await _rows(api,batch));
      final s=_session(api,batch,grid); addTearDown(s.dispose);
      await s.initialize(); await s.start([grid.rows.values.single.id]);
      await _until(()=>s.job?.active == false && !s.busy); await s.readPage(0);
      final ref=_reference(s.page!.items.single), a=_assistant(api,_reference(s.page!.items.single));
      final id=await a.createSession();
      final pending=api.raw('POST','chat/sessions/$id/messages',tenant:_tenant,
        body:{'message':'M12_WAIT','request_id':'c'*32,'enrichment_context':ref.toJson()});
      await Future<void>.delayed(const Duration(milliseconds:700));
      if (revoke) {
        final logout=await api.raw('POST','auth/logout',body:{});
        expect(logout.status,200,reason:'${logout.body}');
      } else {
        final patch=await _patch(api,batch,grid.rows.values.single,
          {'field':'name','value':'Précision humaine concurrente'});
        expect(patch.status,200,reason:'${patch.body}');
      }
      final reply=await pending;
      expect(reply.status,revoke ? 401 : 409,reason:'${reply.body}');
      expect(reply.body['data'],isNull);
      // A repeat cannot retrieve the upstream reply from cache after revocation/stale.
      final retry=await api.raw('POST','chat/sessions/$id/messages',tenant:_tenant,
        body:{'message':'M12_WAIT','request_id':'c'*32,'enrichment_context':ref.toJson()});
      expect(retry.status,revoke ? 401 : 409,reason:'${retry.body}');
    },timeout:const Timeout(Duration(minutes:3)));
  }
}
