import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:back_office_tribuneo_v2/domain/models/assistant_model.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/assistant/assistant_avatar.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/assistant/assistant_controller.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/assistant/assistant_message_view.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/assistant/tribuneo_mascot.dart';

/// Panneau de conversation de l'assistant (§ 3.3 et § 5 de la spec).
///
/// [input] appartient à l'overlay : le brouillon survit à « Réduire ».
class AssistantPanel extends StatefulWidget {
  static const int maxMessageLength = 1000;
  static const List<String> suggestions = [
    'Comment créer une commande ?',
    'Retrouver une commande',
    'Cette commande est-elle payée ?',
  ];

  final TextEditingController input;
  final bool fullScreen;

  const AssistantPanel(
      {super.key, required this.input, required this.fullScreen});

  @override
  State<AssistantPanel> createState() => _AssistantPanelState();
}

class _AssistantPanelState extends State<AssistantPanel> {
  final ScrollController _scroll = ScrollController();

  /// Garde le focus dans le panneau (et donc `Échap`) pendant que le champ de
  /// saisie est désactivé.
  final FocusNode _panelFocus = FocusNode(debugLabel: 'assistant-panel');
  late final FocusNode _inputFocus =
      FocusNode(debugLabel: 'assistant-input', onKeyEvent: _onInputKey);

  /// Faux dès que l'utilisateur remonte dans le fil : on ne le ramène plus en
  /// bas à chaque nouveau message.
  bool _stickToBottom = true;
  int _lastItemCount = -1;
  bool _wasPending = false;

  @override
  void dispose() {
    _scroll.dispose();
    _panelFocus.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  /// `Entrée` envoie, `Maj + Entrée` passe à la ligne.
  KeyEventResult _onInputKey(FocusNode node, KeyEvent event) {
    final bool isEnter = event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter;
    if (!isEnter || HardwareKeyboard.instance.isShiftPressed) {
      return KeyEventResult.ignored;
    }
    if (event is KeyDownEvent) _send();
    return KeyEventResult.handled;
  }

  void _send([String? text]) {
    final AssistantController controller = context.read<AssistantController>();
    final String message = text ?? widget.input.text;
    if (message.trim().isEmpty || controller.pending) return;
    if (text == null) widget.input.clear();
    _stickToBottom = true;
    controller.send(message);
  }

  Future<bool> _confirmClear() async {
    final AssistantController controller = context.read<AssistantController>();
    if (!controller.hasConversation) return true;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Fermer la conversation ?'),
          content: const Text('La conversation en cours sera effacée. '
              'Pour la garder, utilisez « Réduire ».'),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Fermer et effacer'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );
    return confirmed == true && mounted;
  }

  Future<void> _close() async {
    final AssistantController controller = context.read<AssistantController>();
    if (await _confirmClear()) controller.resetConversation(closePanel: true);
  }

  Future<void> _newConversation() async {
    final AssistantController controller = context.read<AssistantController>();
    if (await _confirmClear()) {
      controller.resetConversation(closePanel: false);
      _inputFocus.requestFocus();
    }
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification.depth == 0) {
      final ScrollMetrics metrics = notification.metrics;
      _stickToBottom = metrics.pixels >= metrics.maxScrollExtent - 48;
    }
    return false;
  }

  void _scrollToBottom({required bool animate}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final double target = _scroll.position.maxScrollExtent;
      if (animate && !MediaQuery.of(context).disableAnimations) {
        _scroll.animateTo(target,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic);
      } else {
        _scroll.jumpTo(target);
      }
    });
  }

  /// Le champ désactivé perd le focus : on le confie au panneau pendant
  /// l'attente, puis on le rend au champ.
  void _handlePendingChange(bool pending) {
    if (pending == _wasPending) return;
    final bool hadInputFocus = _inputFocus.hasFocus;
    _wasPending = pending;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (pending && hadInputFocus) {
        _panelFocus.requestFocus();
      } else if (!pending && _panelFocus.hasPrimaryFocus) {
        _inputFocus.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final AssistantController controller = context.watch<AssistantController>();
    final List<AssistantMessage> messages = controller.messages;
    final bool pending = controller.pending;
    final int itemCount = messages.length + (pending ? 1 : 0);

    if (itemCount != _lastItemCount) {
      final bool firstBuild = _lastItemCount < 0;
      _lastItemCount = itemCount;
      if (firstBuild || _stickToBottom) _scrollToBottom(animate: !firstBuild);
    }
    _handlePendingChange(pending);

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): controller.minimize,
      },
      child: Focus(
        focusNode: _panelFocus,
        child: Semantics(
          container: true,
          label: 'Néo — assistant Tribuneo',
          child: Material(
            color: kPWhite,
            elevation: 8,
            shadowColor: kBlack.withValues(alpha: 0.4),
            clipBehavior: Clip.antiAlias,
            borderRadius: BorderRadius.circular(widget.fullScreen ? 0 : 16),
            child: Column(
              children: [
                _buildHeader(controller),
                Expanded(
                  child: messages.isEmpty && !pending
                      ? _buildWelcome()
                      : _buildThread(messages, pending),
                ),
                _buildInput(pending),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AssistantController controller) {
    return Container(
      color: kBlue,
      padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
      child: Row(
        children: [
          const AssistantAvatar(size: 32),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Néo',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            tooltip: 'Nouvelle conversation',
            color: Colors.white,
            onPressed: _newConversation,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Réduire',
            color: Colors.white,
            onPressed: controller.minimize,
            icon: const Icon(Icons.remove),
          ),
          IconButton(
            tooltip: 'Fermer',
            color: Colors.white,
            onPressed: _close,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 12),
          const TribuneoMascot(mood: TribuneoMascotMood.welcome),
          const SizedBox(height: 12),
          const Text(
            'Bonjour !',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w600, color: kBlue),
          ),
          const SizedBox(height: 8),
          const Text(
            "Je suis l'assistant Tribuneo. Posez-moi une question sur "
            "l'utilisation du back-office, ou sur vos commandes, clients et "
            'commerçants.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, height: 1.4, color: kGrey),
          ),
          const SizedBox(height: 20),
          for (final String suggestion in AssistantPanel.suggestions)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kBlue,
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: kLBlue),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    alignment: Alignment.centerLeft,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(kButtonRadius)),
                  ),
                  onPressed: () => _send(suggestion),
                  child: Text(suggestion),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildThread(List<AssistantMessage> messages, bool pending) {
    return LayoutBuilder(builder: (context, constraints) {
      final double maxBubbleWidth = (constraints.maxWidth - 32) * 0.85;
      return NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: ListView.separated(
          controller: _scroll,
          padding: const EdgeInsets.all(16),
          itemCount: messages.length + (pending ? 1 : 0),
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (index == messages.length) {
              return const AssistantTypingIndicator();
            }
            return AssistantMessageView(
              message: messages[index],
              maxBubbleWidth: maxBubbleWidth,
              isLast: index == messages.length - 1,
            );
          },
        ),
      );
    });
  }

  Widget _buildInput(bool pending) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: kPLGrey2)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: widget.input,
              focusNode: _inputFocus,
              autofocus: true,
              enabled: !pending,
              minLines: 1,
              maxLines: 4,
              maxLength: AssistantPanel.maxMessageLength,
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Écrire…',
                counterText: '',
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(kInputRadius)),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: kBlue),
                  borderRadius: BorderRadius.circular(kInputRadius),
                ),
              ),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: widget.input,
            builder: (context, value, _) => IconButton(
              tooltip: 'Envoyer',
              color: kBlue,
              onPressed:
                  pending || value.text.trim().isEmpty ? null : () => _send(),
              icon: const Icon(Icons.send),
            ),
          ),
        ],
      ),
    );
  }
}
