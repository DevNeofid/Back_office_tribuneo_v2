part of 'live_local_api.dart';

void _registerLot02Tests() {
  test('ancien serveur HTTP refuse le contexte sans reprise ordinaire', () async {
    final api = _LocalApi(18082);
    await api.login();
    var calls = 0;
    final client = ApiAssistantRepository(
        enrichmentContext: const ChatContextReference(batchId: 1, rowId: 1,
            proposalId: '00000000-0000-4000-8000-000000000001', expectedVersion: 1),
        expectedTenant: _tenant, tenantResolver: api.currentTenant,
        post: (path, body, tenant, timeout) async {
          calls++;
          final r = await api.raw('POST', path, tenant: tenant, body: body);
          expect(r.status, 400);
          expect(r.body['error']['details']['code'], 'CHAT_BAD_INPUT');
          return Response(statusCode: r.status, data: r.body, requestOptions: RequestOptions(path: path));
        });
    await expectLater(client.sendMessage('a' * 32, 'Comparer'), throwsA(anything));
    expect(calls, 1);
  });
  for (final flags in [(false, false), (true, false), (false, true), (true, true)]) {
    test('lot02 HTTP flags ${flags.$1 ? 1 : 0}${flags.$2 ? 1 : 0}: worker, chat, review and human apply', () async {
      final port = 18083 + (flags.$1 ? 1 : 0) + (flags.$2 ? 2 : 0);
      final api = _LocalApi(port);
      await api.login();
      final batch = await _createBatch(api, [
        {'name': 'ESSAI MULTIPLE', 'zip': '04000', 'city': 'DIGNE-LES-BAINS'},
      ]);
      final grid = _Grid()..replace(await _rows(api, batch));
      final session = _session(api, batch, grid);
      addTearDown(session.dispose);
      await session.initialize();
      expect([session.capability!.vat, session.capability!.chatResolution], [flags.$1, flags.$2]);
      final row = grid.rows.values.single;
      final before = _state(row);
      await session.start([row.id]);
      await _until(() => session.job?.active == false && !session.busy);
      await session.readPage(0);
      final proposal = session.page!.items.single;
      final candidate = proposal.candidates.first;
      expect(proposal.state, 'ambiguous');
      expect(proposal.candidates, hasLength(2));
      expect(candidate.vatStatus, flags.$1 ? 'found' : 'not_checked');
      expect(_state((await _rows(api, batch)).single), before);
      final reference = ChatContextReference(batchId: batch, rowId: row.id,
          proposalId: proposal.id, expectedVersion: row.version);
      ApiAssistantRepository assistant({ChatContextReference? context}) => ApiAssistantRepository(
          enrichmentContext: context, expectedTenant: _tenant,
          tenantResolver: api.currentTenant,
          post: (path, body, tenant, timeout) async {
            final r = await api.raw('POST', path, tenant: tenant, body: body ?? {});
            return Response(statusCode: r.status, data: r.body, requestOptions: RequestOptions(path: path));
          });
      final ordinary = assistant();
      final ordinaryId = await ordinary.createSession();
      expect((await ordinary.sendMessage(ordinaryId, 'Bonjour')).blocks, isEmpty);
      final contextual = assistant(context: reference);
      final id = await contextual.createSession();
      if (!flags.$2) {
        await expectLater(contextual.sendMessage(id, 'Comparer'), throwsA(anything));
      } else {
        final comparison = ChatComparisonUseCase(enrichment: session, reference: reference,
            proposal: proposal, tenant: _tenant, assistant: contextual, active: () => true);
        final dedicated = await comparison.createSession();
        final reply = await comparison.sendMessage(dedicated, 'Comparer');
        final block = reply.blocks.single as AssistantEnrichmentCandidatesBlock;
        expect(block.candidates.map((c) => c.id), proposal.candidates.map((c) => c.id));
        expect(block.candidates.any((c) => c.id == 'forged'), isFalse);
        final writesBefore = api.calls.where((s) => s.endsWith('/apply')).length;
        final selected = await comparison.review(block, candidate.id);
        expect(selected.candidate.id, candidate.id);
        expect(api.calls.where((s) => s.endsWith('/apply')).length, writesBefore);
      }
      expect(_state((await _rows(api, batch)).single), before, reason: 'Chat/review never writes');
      final fields = {'siret', if (flags.$1) 'intracommunity_vat_number'};
      expect(await session.apply(proposal, candidate, fields), isTrue, reason: session.message);
      final after = (await _rows(api, batch)).single;
      expect(after.version, row.version + 1);
      expect(after.status, 'pending');
      expect(after.valueOf('siret'), candidate.fields['siret']);
      if (flags.$1) expect(after.valueOf('intracommunity_vat_number'), candidate.fields['intracommunity_vat_number']);
      final stale = await api.raw('POST', 'chat/sessions/$id/messages', tenant: _tenant, body: {
        'message': 'Comparer', 'request_id': 'b' * 32, 'enrichment_context': reference.toJson(),
      });
      expect(stale.status, flags.$2 ? 409 : 503);
      expect(await _batchStatus(api, batch), 'review');
    }, timeout: const Timeout(Duration(minutes: 3)));
  }
}
