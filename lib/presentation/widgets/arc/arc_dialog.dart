import 'package:flutter/material.dart';

import 'package:back_office_tribuneo_v2/presentation/utils/arc_theme.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';

/// Dialogue « Arc » : pastille d'icône teintée, titre en Bricolage Grotesque,
/// contenu, actions alignées à droite (l'action principale en dernier).
class ArcDialog extends StatelessWidget {
  final IconData? icon;
  final ArcTone tone;
  final String title;
  final Widget? content;
  final List<Widget> actions;
  final double maxWidth;
  const ArcDialog({
    super.key,
    this.icon,
    this.tone = ArcTone.info,
    required this.title,
    this.content,
    this.actions = const [],
    this.maxWidth = 460,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                      color: tone.background,
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: tone.text, size: 22),
                ),
                const SizedBox(height: 16),
              ],
              Text(title, style: ArcText.dialogTitle()),
              if (content != null) ...[
                const SizedBox(height: 8),
                Flexible(
                  child: SingleChildScrollView(
                    child: DefaultTextStyle.merge(
                        style: ArcText.body(color: kText2), child: content!),
                  ),
                ),
              ],
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 10,
                    runSpacing: 10,
                    children: actions,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Bouton « danger » (fond framboise) pour les suppressions et abandons.
ButtonStyle arcDangerButtonStyle() => FilledButton.styleFrom(
      backgroundColor: kDanger,
      foregroundColor: Colors.white,
    );

/// Confirmation : `true` si l'utilisateur valide.
Future<bool> showArcConfirm(
  BuildContext context, {
  required String title,
  String? message,
  String confirmLabel = 'Confirmer',
  String cancelLabel = 'Annuler',
  bool danger = false,
  IconData? icon,
}) async {
  final bool? result = await showDialog<bool>(
    context: context,
    builder: (context) => ArcDialog(
      icon: icon ?? (danger ? Icons.delete_outline_rounded : null),
      tone: danger ? ArcTone.danger : ArcTone.info,
      title: title,
      content: message == null ? null : Text(message),
      actions: [
        OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelLabel)),
        FilledButton(
            style: danger ? arcDangerButtonStyle() : null,
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel)),
      ],
    ),
  );
  return result ?? false;
}
