import 'package:flutter/foundation.dart';

import 'package:back_office_tribuneo_v2/data/local/storage_function.dart';
import 'package:back_office_tribuneo_v2/domain/errors/assistant_exception.dart';
import 'package:back_office_tribuneo_v2/domain/models/assistant_model.dart';
import 'package:back_office_tribuneo_v2/domain/repositories/assistant_repository.dart';

/// États du lanceur (§ 3 de la spec).
enum AssistantLauncherState { visible, hidden, open }

/// Réglages de l'assistant mémorisés sur le poste.
abstract class AssistantPreferences {
  Future<bool> readHidden();
  Future<void> saveHidden(bool hidden);
  Future<bool> readOpenedOnce();
  Future<void> saveOpenedOnce();
}

class StorageAssistantPreferences implements AssistantPreferences {
  final StorageFunction _storageFunction = StorageFunction();

  @override
  Future<bool> readHidden() => _storageFunction.readAssistantHidden();

  @override
  Future<void> saveHidden(bool hidden) =>
      _storageFunction.saveAssistantHidden(hidden);

  @override
  Future<bool> readOpenedOnce() => _storageFunction.readAssistantOpenedOnce();

  @override
  Future<void> saveOpenedOnce() => _storageFunction.saveAssistantOpenedOnce();
}

/// État de l'assistant : lanceur, conversation en mémoire, réponse en attente.
///
/// Fourni par `MySinglePage` : il survit au changement d'écran et disparaît
/// avec la page (déconnexion), ce qui efface la conversation.
class AssistantController extends ChangeNotifier {
  AssistantController({
    AssistantRepository? repository,
    AssistantPreferences? preferences,
  })  : _repository = repository ?? AssistantRepository(),
        _preferences = preferences ?? StorageAssistantPreferences();

  final AssistantRepository _repository;
  final AssistantPreferences _preferences;

  /// Branchés par `MySinglePage`.
  void Function(AssistantLinkBlock link)? onNavigate;
  void Function(AssistantDocumentBlock document)? onDownloadDocument;
  void Function(String url)? onOpenUrl;

  bool _ready = false;
  AssistantLauncherState _state = AssistantLauncherState.visible;
  bool _openedOnce = false;
  final List<AssistantMessage> _messages = [];
  bool _pending = false;
  bool _hasUnread = false;
  int _replyPulses = 0;
  String? _sessionId;
  String? _lastSent;

  /// Incrémenté à chaque effacement : une réponse d'une conversation effacée
  /// est ignorée à son arrivée.
  int _conversation = 0;
  bool _disposed = false;

  /// Faux tant que les réglages du poste ne sont pas lus : rien n'est affiché,
  /// pour ne pas montrer le bouton puis le cacher aussitôt.
  bool get ready => _ready;
  AssistantLauncherState get state => _state;
  bool get isOpen => _state == AssistantLauncherState.open;
  bool get openedOnce => _openedOnce;
  List<AssistantMessage> get messages => List.unmodifiable(_messages);
  bool get hasConversation => _messages.isNotEmpty;
  bool get pending => _pending;

  /// Réponse arrivée pendant que le panneau était fermé.
  bool get hasUnread => _hasUnread;

  /// Nombre de réponses arrivées panneau fermé : le lanceur pulse une fois à
  /// chaque incrément.
  int get replyPulses => _replyPulses;

  Future<void> load() async {
    bool hidden = false;
    bool openedOnce = false;
    try {
      hidden = await _preferences.readHidden();
      openedOnce = await _preferences.readOpenedOnce();
    } catch (e) {
      if (kDebugMode) print('###DEBUG### Réglages assistant illisibles : $e');
    }
    if (_disposed) return;
    _state = hidden ? AssistantLauncherState.hidden : _state;
    _openedOnce = _openedOnce || openedOnce;
    _ready = true;
    notifyListeners();
  }

  void open() {
    if (_state == AssistantLauncherState.open) return;
    _state = AssistantLauncherState.open;
    _hasUnread = false;
    if (!_openedOnce) {
      _openedOnce = true;
      _persist(_preferences.saveOpenedOnce);
    }
    notifyListeners();
  }

  /// Referme le panneau en gardant la conversation.
  void minimize() {
    if (_state != AssistantLauncherState.open) return;
    _state = AssistantLauncherState.visible;
    notifyListeners();
  }

  void hide() {
    if (_state != AssistantLauncherState.visible) return;
    _state = AssistantLauncherState.hidden;
    _persist(() => _preferences.saveHidden(true));
    notifyListeners();
  }

  void show() {
    if (_state != AssistantLauncherState.hidden) return;
    _state = AssistantLauncherState.visible;
    _persist(() => _preferences.saveHidden(false));
    notifyListeners();
  }

  /// Efface la conversation et oublie la session de chat : le prochain message
  /// en créera une nouvelle. [closePanel] : « Fermer » plutôt que « Nouvelle
  /// conversation ».
  void resetConversation({required bool closePanel}) {
    _conversation++;
    _messages.clear();
    _sessionId = null;
    _lastSent = null;
    _pending = false;
    _hasUnread = false;
    if (closePanel && _state == AssistantLauncherState.open) {
      _state = AssistantLauncherState.visible;
    }
    notifyListeners();
  }

  /// Envoie [text] à l'assistant. [display] : texte affiché dans le fil à la
  /// place de [text] (libellé d'un choix).
  Future<void> send(String text, {String? display}) async {
    final String message = text.trim();
    if (message.isEmpty || _pending) return;
    _messages.add(AssistantMessage.user(display ?? message));
    _lastSent = message;
    await _request(message);
  }

  /// Renvoie le dernier message après une erreur.
  Future<void> retry() async {
    final String? message = _lastSent;
    if (message == null || _pending) return;
    if (_messages.isNotEmpty &&
        _messages.last.role == AssistantMessageRole.error) {
      _messages.removeLast();
    }
    await _request(message);
  }

  /// Clic sur une option d'un bloc `choices` : les boutons se désactivent.
  Future<void> answerChoice(
      AssistantMessage message, AssistantChoice choice) async {
    if (_pending || message.choicesAnswered) return;
    message.choicesAnswered = true;
    await send(choice.value, display: choice.label);
  }

  /// Ouvre l'écran ciblé puis réduit le panneau pour le laisser voir.
  void navigate(AssistantLinkBlock link) {
    onNavigate?.call(link);
    minimize();
  }

  void downloadDocument(AssistantDocumentBlock document) =>
      onDownloadDocument?.call(document);

  void openUrl(String url) => onOpenUrl?.call(url);

  Future<void> _request(String message) async {
    final int conversation = _conversation;
    _pending = true;
    notifyListeners();

    AssistantMessage reply;
    try {
      final String session = _sessionId ?? await _repository.createSession();
      if (_isStale(conversation)) return;
      _sessionId = session;
      reply = AssistantMessage.assistant(
          await _repository.sendMessage(session, message));
    } on AssistantException catch (e) {
      reply = AssistantMessage.error(e.kind);
    } catch (e) {
      if (kDebugMode) print('###DEBUG### Assistant : $e');
      reply = AssistantMessage.error(AssistantErrorKind.other);
    }
    if (_isStale(conversation)) return;

    _pending = false;
    _messages.add(reply);
    if (_state != AssistantLauncherState.open) {
      _hasUnread = true;
      _replyPulses++;
    }
    notifyListeners();
  }

  bool _isStale(int conversation) => _disposed || conversation != _conversation;

  /// Un réglage non enregistré n'est pas bloquant : il sera seulement perdu
  /// au prochain chargement.
  void _persist(Future<void> Function() write) {
    write().catchError((Object e) {
      if (kDebugMode)
        print('###DEBUG### Réglage assistant non enregistré : $e');
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
