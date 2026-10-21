import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';

/// Rendu markdown **simple** des réponses de l'assistant : paragraphes, titres
/// (rendus en gras), listes à puces ou numérotées, gras, italique, code en
/// ligne et liens `[texte](url)`. Pas de HTML : tout le reste est du texte.
class AssistantMarkdown extends StatefulWidget {
  final String data;
  final TextStyle style;
  final void Function(String url) onTapLink;

  const AssistantMarkdown({
    super.key,
    required this.data,
    required this.style,
    required this.onTapLink,
  });

  @override
  State<AssistantMarkdown> createState() => _AssistantMarkdownState();
}

class _MarkdownBlock {
  /// Puce (`•`) ou numéro (`1.`) ; `null` pour un paragraphe.
  final String? marker;
  final String text;
  final bool heading;

  const _MarkdownBlock(this.text, {this.marker, this.heading = false});
}

class _AssistantMarkdownState extends State<AssistantMarkdown> {
  static final RegExp _bullet = RegExp(r'^\s*[-*•]\s+(.*)$');
  static final RegExp _ordered = RegExp(r'^\s*(\d+)[.)]\s+(.*)$');
  static final RegExp _heading = RegExp(r'^\s*#{1,6}\s+(.*)$');
  static final RegExp _inline = RegExp(
    r'\*\*(.+?)\*\*'
    r'|__(.+?)__'
    r'|\[([^\]]+)\]\(([^)\s]+)\)'
    r'|`([^`]+)`'
    r'|\*(?!\s)(.+?)(?<!\s)\*'
    r'|(?<![A-Za-z0-9])_(?!\s)(.+?)(?<!\s)_(?![A-Za-z0-9])',
  );

  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final TapGestureRecognizer recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  static List<_MarkdownBlock> _parseBlocks(String data) {
    final List<_MarkdownBlock> blocks = [];
    final List<String> paragraph = [];

    void flush() {
      if (paragraph.isEmpty) return;
      blocks.add(_MarkdownBlock(paragraph.join('\n')));
      paragraph.clear();
    }

    for (final String line in data.split('\n')) {
      final RegExpMatch? bullet = _bullet.firstMatch(line);
      final RegExpMatch? ordered = _ordered.firstMatch(line);
      final RegExpMatch? heading = _heading.firstMatch(line);
      if (line.trim().isEmpty) {
        flush();
      } else if (bullet != null) {
        flush();
        blocks.add(_MarkdownBlock(bullet.group(1)!, marker: '•'));
      } else if (ordered != null) {
        flush();
        blocks.add(
            _MarkdownBlock(ordered.group(2)!, marker: '${ordered.group(1)}.'));
      } else if (heading != null) {
        flush();
        blocks.add(_MarkdownBlock(heading.group(1)!, heading: true));
      } else {
        paragraph.add(line.trimRight());
      }
    }
    flush();
    return blocks;
  }

  static bool _isSafeUrl(String url) {
    final Uri? uri = Uri.tryParse(url);
    return uri != null &&
        (uri.scheme == 'https' ||
            uri.scheme == 'http' ||
            uri.scheme == 'mailto');
  }

  List<InlineSpan> _inlineSpans(String text) {
    final List<InlineSpan> spans = [];
    int start = 0;
    for (final RegExpMatch match in _inline.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }
      final String? bold = match.group(1) ?? match.group(2);
      final String? linkText = match.group(3);
      final String? linkUrl = match.group(4);
      final String? code = match.group(5);
      final String? italic = match.group(6) ?? match.group(7);
      if (bold != null) {
        spans.add(TextSpan(
            text: bold, style: const TextStyle(fontWeight: FontWeight.bold)));
      } else if (linkText != null && linkUrl != null) {
        if (_isSafeUrl(linkUrl)) {
          final TapGestureRecognizer recognizer = TapGestureRecognizer()
            ..onTap = () => widget.onTapLink(linkUrl);
          _recognizers.add(recognizer);
          spans.add(TextSpan(
            text: linkText,
            style: const TextStyle(
                color: kBlue, decoration: TextDecoration.underline),
            recognizer: recognizer,
            mouseCursor: SystemMouseCursors.click,
          ));
        } else {
          spans.add(TextSpan(text: linkText));
        }
      } else if (code != null) {
        spans.add(TextSpan(
          text: code,
          style: const TextStyle(
              fontFamily: 'monospace', backgroundColor: kPLGrey2),
        ));
      } else if (italic != null) {
        spans.add(TextSpan(
            text: italic, style: const TextStyle(fontStyle: FontStyle.italic)));
      }
      start = match.end;
    }
    if (start < text.length) spans.add(TextSpan(text: text.substring(start)));
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();
    final List<_MarkdownBlock> blocks = _parseBlocks(widget.data);
    final List<Widget> children = [];
    for (int i = 0; i < blocks.length; i++) {
      final _MarkdownBlock block = blocks[i];
      final bool previousIsItem = i > 0 && blocks[i - 1].marker != null;
      if (i > 0) {
        children.add(
            SizedBox(height: block.marker != null && previousIsItem ? 2 : 8));
      }
      final Widget text = Text.rich(
        TextSpan(
          style: block.heading
              ? widget.style.copyWith(fontWeight: FontWeight.bold)
              : widget.style,
          children: _inlineSpans(block.text),
        ),
      );
      children.add(block.marker == null
          ? text
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 20,
                  child: Text(block.marker!, style: widget.style),
                ),
                Expanded(child: text),
              ],
            ));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}
