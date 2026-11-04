import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:back_office_tribuneo_v2/domain/models/assistant_model.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/arc/arc.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/assistant/assistant_controller.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/assistant/assistant_message_view.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/assistant/neo_ai_button.dart';
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

  /// Titre de l'en-tête.
  final String title;

  /// Contexte affiché sous l'en-tête (conversation contextuelle).
  final Widget? banner;

  const AssistantPanel(
      {super.key,
      required this.input,
      required this.fullScreen,
      this.title = 'Néo',
      this.banner});

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
        return ArcDialog(
          icon: Icons.delete_outline_rounded,
          tone: ArcTone.danger,
          title: 'Fermer la conversation ?',
          content: const Text('La conversation en cours sera effacée. '
              'Pour la garder, utilisez « Réduire ».'),
          actions: <Widget>[
            OutlinedButton(
              child: const Text('Annuler'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            FilledButton(
              style: arcDangerButtonStyle(),
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
      if (controller.onReviewCandidate != null) {
        controller.minimize();
        return;
      }
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

    final BorderRadius radius =
        BorderRadius.circular(widget.fullScreen ? 0 : kRadiusLg);
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
            color: kSurface,
            elevation: 10,
            shadowColor: const Color(0x661F2240),
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: radius,
              side: widget.fullScreen
                  ? BorderSide.none
                  : const BorderSide(color: kBorder),
            ),
            child: Column(
              children: [
                _buildHeader(controller),
                if (widget.banner != null) widget.banner!,
                Expanded(
                  child: ColoredBox(
                    color: kSurface2,
                    child: messages.isEmpty && !pending
                        ? _buildWelcome()
                        : _buildThread(messages, pending),
                  ),
                ),
                _buildInput(pending || controller.contextInvalid),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AssistantController controller) {
    return Container(
      decoration: const BoxDecoration(
        color: kSurface,
        border: Border(bottom: BorderSide(color: kNavy100)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: Row(
        children: [
          const _NeoBadge(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ArcText.dialogTitle().copyWith(fontSize: 20),
                ),
                Text('Assistant Tribuneo',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ArcText.small(color: kText3)),
              ],
            ),
          ),
          ArcIconAction(
            icon: Icons.refresh_rounded,
            tooltip: 'Nouvelle conversation',
            onPressed: _newConversation,
            size: 34,
          ),
          const SizedBox(width: 6),
          ArcIconAction(
            icon: Icons.remove_rounded,
            tooltip: 'Réduire',
            onPressed: controller.minimize,
            size: 34,
          ),
          const SizedBox(width: 6),
          ArcIconAction(
            icon: Icons.close_rounded,
            tooltip: 'Fermer',
            onPressed: _close,
            size: 34,
          ),
        ],
      ),
    );
  }

  Widget _buildWelcome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: TribuneoMascot(
                width: 180, mood: TribuneoMascotMood.welcome),
          ),
          const SizedBox(height: 12),
          Text('Bonjour !',
              style: ArcText.dialogTitle().copyWith(fontSize: 26)),
          const SizedBox(height: 6),
          Text(
            "Je suis l'assistant Tribuneo. Posez-moi une question sur "
            "l'utilisation du back-office, ou sur vos commandes, clients et "
            'commerçants.',
            style: ArcText.body(color: kText2).copyWith(fontSize: 13.5),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final String suggestion in AssistantPanel.suggestions)
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kNavy700,
                    backgroundColor: kSurface,
                    side: const BorderSide(color: kNavy200, width: 1.5),
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w400),
                  ),
                  onPressed: () => _send(suggestion),
                  child: Text(suggestion),
                ),
            ],
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          itemCount: messages.length + (pending ? 1 : 0),
          separatorBuilder: (_, __) => const SizedBox(height: 14),
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
    OutlineInputBorder border(Color color, [double width = 1.5]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: width),
        );
    return Container(
      decoration: const BoxDecoration(
        color: kSurface,
        border: Border(top: BorderSide(color: kNavy100)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
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
              style: const TextStyle(fontSize: 14, color: kInk),
              decoration: InputDecoration(
                hintText: 'Écrire…',
                counterText: '',
                isDense: true,
                filled: true,
                fillColor: kSurface,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: border(kBorderStrong),
                enabledBorder: border(kBorderStrong),
                disabledBorder: border(kBorder),
                focusedBorder: border(kNavy600, 2),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: widget.input,
            builder: (context, value, _) => SizedBox.square(
              dimension: 44,
              child: IconButton(
                tooltip: 'Envoyer',
                onPressed:
                    pending || value.text.trim().isEmpty ? null : () => _send(),
                style: IconButton.styleFrom(
                  backgroundColor: kOrange,
                  foregroundColor: kNavy900,
                  disabledBackgroundColor: kNavy100,
                  disabledForegroundColor: kNavy400,
                  minimumSize: const Size.square(44),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.send_rounded, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Visuel de Néo dans l'en-tête : picto Tribuneo dans un anneau arc-en-ciel.
class _NeoBadge extends StatelessWidget {
  const _NeoBadge();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: 44,
        height: 44,
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(
              colors: NeoAiButton.rainbow,
              transform: GradientRotation(3.67)),
        ),
        child: const DecoratedBox(
          decoration: BoxDecoration(color: kSurface, shape: BoxShape.circle),
          child: Center(child: ArcPicto(width: 26)),
        ),
      ),
    );
  }
}
