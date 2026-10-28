import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:back_office_tribuneo_v2/domain/errors/assistant_exception.dart';
import 'package:back_office_tribuneo_v2/domain/models/assistant_model.dart';
import 'package:back_office_tribuneo_v2/domain/repositories/assistant_repository.dart';

const String session = '0123456789abcdef0123456789abcdef';
Response<dynamic> response(int code, dynamic data) => Response<dynamic>(
    requestOptions: RequestOptions(path: '/chat'),
    statusCode: code,
    data: data);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Le pilote réel est désactivé par défaut, sans réponse factice',
      () async {
    expect(AssistantRepository.gatewayReady, isFalse);
    expect(AssistantRepository.demoEnabled, isFalse);
    expect(AssistantRepository(), isA<DisabledAssistantRepository>());
    await expectLater(AssistantRepository().createSession(),
        throwsA(isA<AssistantException>()));
  });

  test('La session est créée via Tribuneo avec le tenant CCI04', () async {
    final repository = ApiAssistantRepository(
      tenantResolver: () async => 'tribuneo_cci04',
      post: (path, body, tenant, timeout) async {
        expect(path, 'chat/sessions');
        expect(body, isNull);
        expect(tenant, 'tribuneo_cci04');
        return response(201, {
          'data': {'id': session}
        });
      },
    );
    expect(await repository.createSession(), session);
  });

  test('Un autre réseau est refusé avant toute requête', () async {
    int calls = 0;
    final repository = ApiAssistantRepository(
      tenantResolver: () async => 'tribuneo_autre_test',
      post: (path, body, tenant, timeout) async {
        calls++;
        return response(201, {
          'data': {'id': session}
        });
      },
    );
    await expectLater(
        repository.createSession(), throwsA(isA<AssistantException>()));
    expect(calls, 0);
  });

  test('Un identifiant de session serveur mal formé est refusé', () async {
    final repository = ApiAssistantRepository(
      tenantResolver: () async => 'tribuneo_cci04',
      post: (path, body, tenant, timeout) async => response(201, {
        'data': {'id': '../another-profile'}
      }),
    );
    await expectLater(
        repository.createSession(), throwsA(isA<AssistantException>()));
  });

  test(
      'Réessayer conserve request_id, une nouvelle question reçoit un autre id',
      () async {
    final List<String> ids = [];
    int calls = 0;
    final repository = ApiAssistantRepository(
      tenantResolver: () async => 'tribuneo_cci04',
      post: (path, body, tenant, timeout) async {
        expect(path, 'chat/sessions/$session/messages');
        expect(tenant, 'tribuneo_cci04');
        expect(timeout, const Duration(seconds: 90));
        expect(body.keys, unorderedEquals(['message', 'request_id']));
        final String id = body['request_id'] as String;
        expect(id, matches(RegExp(r'^[a-f0-9]{32}$')));
        ids.add(id);
        calls++;
        if (calls == 1) return response(503, {});
        return response(200, {
          'data': {
            'reply': {'text': 'Réponse CCI04', 'blocks': []}
          }
        });
      },
    );
    await expectLater(repository.sendMessage(session, 'Mes commandes'),
        throwsA(isA<AssistantException>()));
    expect((await repository.sendMessage(session, 'Mes commandes')).text,
        'Réponse CCI04');
    await repository.sendMessage(session, 'Mes commandes');
    expect(ids[0], ids[1]);
    expect(ids[1], isNot(ids[2]));
  });

  test('Message invalide et chemin injecté ne déclenchent aucun appel',
      () async {
    int calls = 0;
    final repository = ApiAssistantRepository(
      tenantResolver: () async => 'tribuneo_cci04',
      post: (path, body, tenant, timeout) async {
        calls++;
        return response(200, {});
      },
    );
    for (final input in ['', 'a' * 1001]) {
      await expectLater(repository.sendMessage(session, input),
          throwsA(isA<AssistantException>()));
    }
    await expectLater(repository.sendMessage('../profile', 'Bonjour'),
        throwsA(isA<AssistantException>()));
    expect(calls, 0);
  });

  test('Un refus Hermes relayé en 503 ne déconnecte pas la session utilisateur',
      () async {
    final repository = ApiAssistantRepository(
      tenantResolver: () async => 'tribuneo_cci04',
      post: (path, body, tenant, timeout) async => response(503, {
        'error': {
          'details': {'code': 'CHAT_UNAVAILABLE'}
        }
      }),
    );
    await expectLater(
        repository.sendMessage(session, 'Bonjour'),
        throwsA(isA<AssistantException>()
            .having((e) => e.kind, 'kind', AssistantErrorKind.unavailable)));
  });
}
