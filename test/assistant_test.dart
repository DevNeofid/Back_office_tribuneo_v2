import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:back_office_tribuneo_v2/core/notifiers/screen_open_requests.dart';
import 'package:back_office_tribuneo_v2/domain/errors/assistant_exception.dart';
import 'package:back_office_tribuneo_v2/domain/models/assistant_model.dart';
import 'package:back_office_tribuneo_v2/domain/repositories/assistant_repository.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/assistant/assistant_controller.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/assistant/assistant_deep_link.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/assistant/assistant_overlay.dart';

class _MemoryPreferences implements AssistantPreferences {
  bool hidden;
  bool openedOnce = false;

  _MemoryPreferences({this.hidden = false});

  @override
  Future<bool> readHidden() async => hidden;

  @override
  Future<void> saveHidden(bool value) async => hidden = value;

  @override
  Future<bool> readOpenedOnce() async => openedOnce;

  @override
  Future<void> saveOpenedOnce() async => openedOnce = true;
}

/// Dépôt piloté par le test : chaque message attend qu'on le complète.
class _ScriptedRepository implements AssistantRepository {
  final List<String> sent = [];
  final List<Completer<AssistantReply>> _pending = [];
  int sessions = 0;

  @override
  Future<String> createSession() async => 'session-${++sessions}';

  @override
  Future<AssistantReply> sendMessage(String sessionId, String message) {
    sent.add(message);
    final Completer<AssistantReply> completer = Completer<AssistantReply>();
    _pending.add(completer);
    return completer.future;
  }

  void reply(AssistantReply reply) => _pending.removeAt(0).complete(reply);

  void fail(AssistantErrorKind kind) =>
      _pending.removeAt(0).completeError(AssistantException(kind));
}

const AssistantReply _textReply =
    AssistantReply(text: 'Bonjour, **voici** la réponse.');

AssistantController _controller(
        _ScriptedRepository repository, _MemoryPreferences preferences) =>
    AssistantController(repository: repository, preferences: preferences);

Future<void> _pumpOverlay(WidgetTester tester, AssistantController controller,
    {Size size = const Size(1400, 900)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await controller.load();
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: ChangeNotifierProvider<AssistantController>.value(
        value: controller,
        child: const Stack(
          children: [Positioned.fill(child: AssistantOverlay())],
        ),
      ),
    ),
  ));
  // Entrée + 3 pulsations d'attention.
  await tester.pumpAndSettle();
}

Future<void> _openPanel(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('assistant-launcher')));
  await tester.pumpAndSettle();
}

/// Envoie [text] depuis le champ de saisie (réponse laissée en attente).
Future<void> _sendFromInput(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  // Laisse passer le délai de double tap ouvert par le tap sur le champ.
  await tester.pump(kDoubleTapTimeout);
  await tester.tap(find.byTooltip('Envoyer'));
  await tester.pump();
}

void main() {
  group('AssistantReply.fromJson', () {
    test('ignore les blocs inconnus ou incomplets', () {
      final AssistantReply reply = AssistantReply.fromJson({
        'text': 'Texte',
        'blocks': [
          {'type': 'link', 'screen': 'payments', 'id': 12},
          {'type': 'action', 'label': 'V2'},
          {'type': 'link', 'screen': 'payments'},
          {'type': 'link', 'screen': 'help'},
          {
            'type': 'choices',
            'question': 'Laquelle ?',
            'options': [
              {'label': 'A', 'value': 'a'},
            ],
          },
          {'type': 'document', 'kind': 'invoice', 'id_order': '7'},
          'pas un bloc',
        ],
      });

      expect(reply.text, 'Texte');
      expect(reply.blocks, hasLength(2));
      final AssistantLinkBlock link = reply.blocks[0] as AssistantLinkBlock;
      expect(link.screen, 'payments');
      expect(link.id, 12);
      expect((reply.blocks[1] as AssistantDocumentBlock).idOrder, 7);
    });

    test('limite les choix à 6 options', () {
      final AssistantReply reply = AssistantReply.fromJson({
        'text': '',
        'blocks': [
          {
            'type': 'choices',
            'question': 'Laquelle ?',
            'options': [
              for (int i = 0; i < 8; i++) {'label': 'L$i', 'value': 'v$i'},
            ],
          },
        ],
      });
      expect(
          (reply.blocks.single as AssistantChoicesBlock).options, hasLength(6));
    });
  });

  group('AssistantDeepLink', () {
    test('payments ouvre les commandes avec une demande sur la commande', () {
      final AssistantDeepLink target = AssistantDeepLink.fromLink(
          const AssistantLinkBlock(screen: 'payments', id: 42))!;
      expect(target.menu, 'orders');
      expect(target.request?.screen, 'payments');
      expect(target.request?.id, 42);
    });

    test('bank_accounts ouvre les partenaires sur le commerçant', () {
      final AssistantDeepLink target = AssistantDeepLink.fromLink(
          const AssistantLinkBlock(screen: 'bank_accounts', id: 5))!;
      expect(target.menu, 'partner');
      expect(target.request?.screen, 'bank_accounts');
      expect(target.request?.id, 5);
    });

    test('correspondance des listes', () {
      String? menu(String screen) =>
          AssistantDeepLink.fromLink(AssistantLinkBlock(screen: screen))?.menu;
      expect(menu('orders'), 'orders');
      expect(menu('customers'), 'customer');
      expect(menu('customer'), 'customer');
      expect(menu('partners'), 'partner');
      expect(menu('invoices'), 'document');
      expect(
          AssistantDeepLink.fromLink(
                  const AssistantLinkBlock(screen: 'invoices'))!
              .request
              ?.screen,
          'invoices');
    });
  });

  group('ScreenOpenRequests', () {
    test("seul l'écran concerné retire la demande", () {
      final ScreenOpenRequests requests = ScreenOpenRequests();
      requests.request(const ScreenOpenRequest('payments', id: 3));
      expect(requests.take(const {'bank_accounts'}), isNull);
      expect(requests.take(const {'order', 'payments'})?.id, 3);
      expect(requests.take(const {'order', 'payments'}), isNull);
    });
  });

  group('AssistantController', () {
    test('une réponse arrivée après Fermer est ignorée', () async {
      final _ScriptedRepository repository = _ScriptedRepository();
      final AssistantController controller =
          _controller(repository, _MemoryPreferences());
      await controller.load();
      controller.open();

      unawaited(controller.send('Bonjour'));
      await Future<void>.delayed(Duration.zero);
      expect(controller.pending, isTrue);

      controller.resetConversation(closePanel: true);
      repository.reply(_textReply);
      await Future<void>.delayed(Duration.zero);

      expect(controller.messages, isEmpty);
      expect(controller.pending, isFalse);
      expect(controller.isOpen, isFalse);
    });

    test('nouvelle session après effacement', () async {
      final _ScriptedRepository repository = _ScriptedRepository();
      final AssistantController controller =
          _controller(repository, _MemoryPreferences());
      await controller.load();

      unawaited(controller.send('Un'));
      await Future<void>.delayed(Duration.zero);
      repository.reply(_textReply);
      await Future<void>.delayed(Duration.zero);
      unawaited(controller.send('Deux'));
      await Future<void>.delayed(Duration.zero);
      repository.reply(_textReply);
      await Future<void>.delayed(Duration.zero);
      expect(repository.sessions, 1);

      controller.resetConversation(closePanel: false);
      unawaited(controller.send('Trois'));
      await Future<void>.delayed(Duration.zero);
      expect(repository.sessions, 2);
    });

    test('Réessayer renvoie le dernier message, sauf quota', () async {
      final _ScriptedRepository repository = _ScriptedRepository();
      final AssistantController controller =
          _controller(repository, _MemoryPreferences());
      await controller.load();

      unawaited(controller.send('Question'));
      await Future<void>.delayed(Duration.zero);
      repository.fail(AssistantErrorKind.unavailable);
      await Future<void>.delayed(Duration.zero);
      expect(controller.messages.last.role, AssistantMessageRole.error);
      expect(controller.messages.last.retryable, isTrue);

      unawaited(controller.retry());
      await Future<void>.delayed(Duration.zero);
      expect(repository.sent, ['Question', 'Question']);
      repository.reply(_textReply);
      await Future<void>.delayed(Duration.zero);
      expect(controller.messages.map((m) => m.role), [
        AssistantMessageRole.user,
        AssistantMessageRole.assistant,
      ]);

      expect(
          AssistantMessage.error(AssistantErrorKind.quota).retryable, isFalse);
    });
  });

  group('AssistantOverlay', () {
    testWidgets('masquer puis réafficher, état mémorisé', (tester) async {
      final _MemoryPreferences preferences = _MemoryPreferences();
      final AssistantController controller =
          _controller(_ScriptedRepository(), preferences);
      // Tablette : la pastille « masquer » est toujours visible.
      await _pumpOverlay(tester, controller, size: const Size(1000, 800));

      await tester.tap(find.byTooltip("Masquer l'assistant"));
      await tester.pumpAndSettle();
      expect(controller.state, AssistantLauncherState.hidden);
      expect(preferences.hidden, isTrue);

      await tester.tap(find.byKey(const ValueKey('assistant-tab')));
      await tester.pumpAndSettle();
      expect(controller.state, AssistantLauncherState.visible);
      expect(preferences.hidden, isFalse);
    });

    testWidgets("démarre caché si c'est mémorisé", (tester) async {
      final AssistantController controller =
          _controller(_ScriptedRepository(), _MemoryPreferences(hidden: true));
      await _pumpOverlay(tester, controller);

      expect(controller.state, AssistantLauncherState.hidden);
      await tester.tap(find.byKey(const ValueKey('assistant-tab')));
      await tester.pumpAndSettle();
      expect(controller.state, AssistantLauncherState.visible);
    });

    testWidgets('desktop : la pastille « masquer » apparaît au survol',
        (tester) async {
      final AssistantController controller =
          _controller(_ScriptedRepository(), _MemoryPreferences());
      await _pumpOverlay(tester, controller);

      // Sans survol, la pastille ne reçoit pas les clics.
      await tester.tap(find.byTooltip("Masquer l'assistant"),
          warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(controller.state, AssistantLauncherState.visible);

      final TestGesture mouse =
          await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(
          tester.getCenter(find.byKey(const ValueKey('assistant-launcher'))));
      await tester.pumpAndSettle();

      final Offset chip =
          tester.getCenter(find.byTooltip("Masquer l'assistant"));
      await mouse.moveTo(chip);
      await tester.pump(kDoubleTapTimeout);
      await mouse.down(chip);
      await mouse.up();
      await tester.pumpAndSettle();
      expect(controller.state, AssistantLauncherState.hidden);
    });

    testWidgets('les pulsations cessent après la première ouverture',
        (tester) async {
      final _MemoryPreferences preferences = _MemoryPreferences();
      final AssistantController controller =
          _controller(_ScriptedRepository(), preferences);
      await _pumpOverlay(tester, controller);
      expect(find.byKey(const ValueKey('assistant-halo')), findsNothing);

      // Pulsation toutes les 30 s tant que l'assistant n'a jamais été ouvert.
      await tester.pump(const Duration(seconds: 30));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const ValueKey('assistant-halo')), findsOneWidget);
      await tester.pumpAndSettle();

      await _openPanel(tester);
      expect(preferences.openedOnce, isTrue);
      await tester.tap(find.byTooltip('Réduire'));
      await tester.pumpAndSettle();

      await tester.pump(const Duration(seconds: 31));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const ValueKey('assistant-halo')), findsNothing);
    });

    testWidgets('Réduire garde le fil, pastille si la réponse arrive fermé',
        (tester) async {
      final _ScriptedRepository repository = _ScriptedRepository();
      final AssistantController controller =
          _controller(repository, _MemoryPreferences());
      await _pumpOverlay(tester, controller);
      await _openPanel(tester);

      await _sendFromInput(tester, 'Ma question');
      expect(find.text('Ma question'), findsOneWidget);

      await tester.tap(find.byTooltip('Réduire'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(controller.isOpen, isFalse);

      repository.reply(_textReply);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('assistant-unread')), findsOneWidget);

      await _openPanel(tester);
      expect(find.byKey(const ValueKey('assistant-unread')), findsNothing);
      expect(find.text('Ma question'), findsOneWidget);
      expect(controller.messages, hasLength(2));
    });

    testWidgets('Échap réduit sans effacer', (tester) async {
      final _ScriptedRepository repository = _ScriptedRepository();
      final AssistantController controller =
          _controller(repository, _MemoryPreferences());
      await _pumpOverlay(tester, controller);
      await _openPanel(tester);
      await _sendFromInput(tester, 'Question');
      repository.reply(_textReply);
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(controller.isOpen, isFalse);
      expect(controller.messages, hasLength(2));
    });

    testWidgets('Entrée envoie, Maj + Entrée non', (tester) async {
      final _ScriptedRepository repository = _ScriptedRepository();
      final AssistantController controller =
          _controller(repository, _MemoryPreferences());
      await _pumpOverlay(tester, controller);
      await _openPanel(tester);

      await tester.enterText(find.byType(TextField), 'Ligne');
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();
      expect(repository.sent, isEmpty);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(repository.sent, ['Ligne']);
    });

    testWidgets('Fermer : confirmation, Annuler ne change rien',
        (tester) async {
      final _ScriptedRepository repository = _ScriptedRepository();
      final AssistantController controller =
          _controller(repository, _MemoryPreferences());
      await _pumpOverlay(tester, controller);
      await _openPanel(tester);
      await _sendFromInput(tester, 'Question');
      repository.reply(_textReply);
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Fermer'));
      await tester.pumpAndSettle();
      expect(find.text('Fermer la conversation ?'), findsOneWidget);
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(controller.isOpen, isTrue);
      expect(controller.messages, hasLength(2));

      await tester.tap(find.byTooltip('Fermer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fermer et effacer'));
      await tester.pumpAndSettle();
      expect(controller.isOpen, isFalse);
      expect(controller.messages, isEmpty);
    });

    testWidgets('Fermer une conversation vide ne demande rien', (tester) async {
      final AssistantController controller =
          _controller(_ScriptedRepository(), _MemoryPreferences());
      await _pumpOverlay(tester, controller);
      await _openPanel(tester);
      expect(find.text('Comment créer une commande ?'), findsOneWidget);

      await tester.tap(find.byTooltip('Fermer'));
      await tester.pumpAndSettle();
      expect(find.text('Fermer la conversation ?'), findsNothing);
      expect(controller.isOpen, isFalse);
    });

    testWidgets('réponse arrivée après Fermer ignorée', (tester) async {
      final _ScriptedRepository repository = _ScriptedRepository();
      final AssistantController controller =
          _controller(repository, _MemoryPreferences());
      await _pumpOverlay(tester, controller);
      await _openPanel(tester);
      await _sendFromInput(tester, 'Question');

      await tester.tap(find.byTooltip('Fermer'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Fermer et effacer'));
      await tester.pump(const Duration(milliseconds: 300));

      repository.reply(_textReply);
      await tester.pumpAndSettle();
      expect(controller.messages, isEmpty);
      expect(find.byKey(const ValueKey('assistant-unread')), findsNothing);
    });

    testWidgets('rendu des blocs et actions', (tester) async {
      final _ScriptedRepository repository = _ScriptedRepository();
      final AssistantController controller =
          _controller(repository, _MemoryPreferences());
      AssistantLinkBlock? navigated;
      AssistantDocumentBlock? downloaded;
      controller
        ..onNavigate = ((link) => navigated = link)
        ..onDownloadDocument = ((document) => downloaded = document);
      await _pumpOverlay(tester, controller);
      await _openPanel(tester);

      await _sendFromInput(tester, 'Question');
      repository.reply(AssistantReply.fromJson({
        'text': 'Voici :',
        'blocks': [
          {'type': 'document', 'kind': 'invoice', 'id_order': 9},
          {'type': 'unknown'},
          {
            'type': 'choices',
            'question': 'Que voulez-vous ?',
            'options': [
              {'label': 'Option A', 'value': 'a'},
              {'label': 'Option B', 'value': 'b'},
            ],
          },
          {'type': 'link', 'screen': 'payments', 'id': 4},
        ],
      }));
      await tester.pumpAndSettle();

      expect(find.text('Facture'), findsOneWidget);
      expect(find.text('Que voulez-vous ?'), findsOneWidget);

      await tester.tap(find.text('Télécharger'));
      expect(downloaded?.idOrder, 9);

      // Un choix : envoie la valeur, affiche le libellé, désactive les boutons.
      await tester.tap(find.text('Option B'));
      await tester.pump();
      expect(repository.sent.last, 'b');
      expect(find.widgetWithText(OutlinedButton, 'Option B'), findsOneWidget);
      final OutlinedButton optionA =
          tester.widget(find.widgetWithText(OutlinedButton, 'Option A'));
      expect(optionA.onPressed, isNull);
      repository.reply(_textReply);
      await tester.pumpAndSettle();
      expect(find.text('Option B'), findsNWidgets(2));
      final OutlinedButton optionAAfter =
          tester.widget(find.widgetWithText(OutlinedButton, 'Option A'));
      expect(optionAAfter.onPressed, isNull);

      // Deep-link : navigation puis panneau réduit.
      await tester
          .ensureVisible(find.text('Ouvrir les paiements de la commande'));
      await tester.tap(find.text('Ouvrir les paiements de la commande'));
      await tester.pumpAndSettle();
      expect(navigated?.screen, 'payments');
      expect(navigated?.id, 4);
      expect(controller.isOpen, isFalse);
      expect(controller.messages, isNotEmpty);
    });

    testWidgets("erreur : bouton Réessayer, absent pour le quota",
        (tester) async {
      final _ScriptedRepository repository = _ScriptedRepository();
      final AssistantController controller =
          _controller(repository, _MemoryPreferences());
      await _pumpOverlay(tester, controller);
      await _openPanel(tester);

      await _sendFromInput(tester, 'Question');
      repository.fail(AssistantErrorKind.unavailable);
      await tester.pumpAndSettle();
      expect(find.textContaining('ne répond pas'), findsOneWidget);

      await tester.tap(find.text('Réessayer'));
      await tester.pump();
      repository.fail(AssistantErrorKind.quota);
      await tester.pumpAndSettle();
      expect(find.textContaining('quota mensuel'), findsOneWidget);
      expect(find.text('Réessayer'), findsNothing);
    });

    testWidgets('mobile : panneau plein écran', (tester) async {
      final AssistantController controller =
          _controller(_ScriptedRepository(), _MemoryPreferences());
      await _pumpOverlay(tester, controller, size: const Size(400, 800));
      await _openPanel(tester);

      expect(tester.getSize(find.byKey(const ValueKey('assistant-panel'))),
          const Size(400, 800));
    });
  });
}
