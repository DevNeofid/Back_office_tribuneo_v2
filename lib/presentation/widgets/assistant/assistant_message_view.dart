import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:back_office_tribuneo_v2/domain/models/assistant_model.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/assistant/assistant_avatar.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/assistant/assistant_controller.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/assistant/assistant_markdown.dart';

const TextStyle _messageStyle =
    TextStyle(fontSize: 14, height: 1.4, color: kBlack);
const double _avatarSize = 24;
const double _avatarGap = 8;

/// Un message du fil : bulle de l'utilisateur, réponse de l'assistant (avec
/// ses blocs) ou erreur.
class AssistantMessageView extends StatelessWidget {
  final AssistantMessage message;
  final double maxBubbleWidth;

  /// Seule la dernière erreur du fil propose « Réessayer ».
  final bool isLast;

  const AssistantMessageView({
    super.key,
    required this.message,
    required this.maxBubbleWidth,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    switch (message.role) {
      case AssistantMessageRole.user:
        return Align(
          alignment: Alignment.centerRight,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxBubbleWidth),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                color: kBlue,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: SelectableText(
                message.text,
                style: _messageStyle.copyWith(color: Colors.white),
              ),
            ),
          ),
        );
      case AssistantMessageRole.assistant:
        return _AssistantRow(
          maxBubbleWidth: maxBubbleWidth,
          child: _AssistantReplyView(message: message),
        );
      case AssistantMessageRole.error:
        return _AssistantRow(
          maxBubbleWidth: maxBubbleWidth,
          child: _ErrorView(message: message, canRetry: isLast),
        );
    }
  }
}

/// Avatar de l'assistant suivi de son contenu, aligné à gauche.
class _AssistantRow extends StatelessWidget {
  final double maxBubbleWidth;
  final Widget child;

  const _AssistantRow({required this.maxBubbleWidth, required this.child});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AssistantAvatar(size: _avatarSize),
          const SizedBox(width: _avatarGap),
          ConstrainedBox(
            constraints: BoxConstraints(
                maxWidth: maxBubbleWidth - _avatarSize - _avatarGap),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _AssistantReplyView extends StatelessWidget {
  final AssistantMessage message;

  const _AssistantReplyView({required this.message});

  @override
  Widget build(BuildContext context) {
    final AssistantController controller = context.read<AssistantController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (message.text.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: kPLGrey2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(12),
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: AssistantMarkdown(
              data: message.text,
              style: _messageStyle,
              onTapLink: controller.openUrl,
            ),
          ),
        for (final AssistantBlock block in message.blocks)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: AssistantBlockView(message: message, block: block),
          ),
      ],
    );
  }
}

/// Rendu d'un bloc d'interface (§ 5.2 de la spec).
class AssistantBlockView extends StatelessWidget {
  final AssistantMessage message;
  final AssistantBlock block;

  const AssistantBlockView(
      {super.key, required this.message, required this.block});

  @override
  Widget build(BuildContext context) {
    final AssistantController controller = context.watch<AssistantController>();
    final AssistantBlock block = this.block;
    switch (block) {
      case AssistantLinkBlock():
        return OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: kBlue,
            side: const BorderSide(color: kLBlue),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(kButtonRadius)),
          ),
          onPressed: () => controller.navigate(block),
          icon: const Icon(Icons.open_in_new, size: 16),
          label: Text(block.buttonLabel),
        );
      case AssistantChoicesBlock():
        final bool enabled = !message.choicesAnswered && !controller.pending;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (block.question.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(block.question,
                    style: _messageStyle.copyWith(fontWeight: FontWeight.w600)),
              ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final AssistantChoice choice in block.options)
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kBlue,
                      side: const BorderSide(color: kLBlue),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(kButtonRadius)),
                    ),
                    onPressed: enabled
                        ? () => controller.answerChoice(message, choice)
                        : null,
                    child: Text(choice.label),
                  ),
              ],
            ),
          ],
        );
      case AssistantDocumentBlock():
        return Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: kPLGrey2),
            borderRadius: BorderRadius.circular(kButtonRadius),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.picture_as_pdf_outlined, color: kBlue),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Facture',
                        style: _messageStyle.copyWith(
                            fontWeight: FontWeight.w600)),
                    if (block.label != null)
                      Text(block.label!,
                          style: _messageStyle.copyWith(
                              fontSize: 12, color: kGrey)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: kBlue),
                onPressed: () => controller.downloadDocument(block),
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Télécharger'),
              ),
            ],
          ),
        );
    }
  }
}

class _ErrorView extends StatelessWidget {
  final AssistantMessage message;
  final bool canRetry;

  const _ErrorView({required this.message, required this.canRetry});

  @override
  Widget build(BuildContext context) {
    final AssistantController controller = context.watch<AssistantController>();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: kRed.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message.text, style: _messageStyle),
          if (canRetry && message.retryable)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: kBlue),
                onPressed: controller.pending ? null : controller.retry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Réessayer'),
              ),
            ),
        ],
      ),
    );
  }
}

/// Bulle « trois points » pendant l'attente de la réponse.
class AssistantTypingIndicator extends StatefulWidget {
  const AssistantTypingIndicator({super.key});

  @override
  State<AssistantTypingIndicator> createState() =>
      _AssistantTypingIndicatorState();
}

class _AssistantTypingIndicatorState extends State<AssistantTypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // L'animation ne tourne que tant que la bulle est affichée.
    if (MediaQuery.of(context).disableAnimations) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: "L'assistant écrit",
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AssistantAvatar(size: _avatarSize),
            const SizedBox(width: _avatarGap),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: kPLGrey2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 0; i < 3; i++)
                      Padding(
                        padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
                        child: Opacity(
                          opacity: _dotOpacity(i),
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                                color: kBlue, shape: BoxShape.circle),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Chaque point s'allume à son tour.
  double _dotOpacity(int index) {
    if (!_controller.isAnimating) return 0.6;
    final double phase = (_controller.value - index / 3) * 2 * math.pi;
    return 0.3 + 0.7 * (0.5 + 0.5 * math.cos(phase));
  }
}
