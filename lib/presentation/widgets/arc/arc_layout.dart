import 'package:flutter/material.dart';

import 'package:back_office_tribuneo_v2/presentation/utils/arc_theme.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';

/// En-tête d'écran : petit libellé de rubrique, titre en Bricolage Grotesque
/// et actions à droite (l'action principale, orange, en dernier).
class ArcPageHeader extends StatelessWidget {
  final String? eyebrow;
  final String title;
  final Widget? subtitle;

  /// Remplace [eyebrow] (ex. lien retour vers la liste).
  final Widget? leading;
  final List<Widget> actions;
  const ArcPageHeader({
    super.key,
    this.eyebrow,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.end,
        spacing: 16,
        runSpacing: 16,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (leading != null)
                leading!
              else if (eyebrow != null)
                Text(eyebrow!, style: ArcText.small(color: kText3)),
              const SizedBox(height: 4),
              Text(title, style: ArcText.display()),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                subtitle!,
              ],
            ],
          ),
          if (actions.isNotEmpty)
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: actions,
            ),
        ],
      ),
    );
  }
}

/// Carte blanche bordée (rayon 16).
class ArcCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color borderColor;
  final double radius;
  final List<BoxShadow>? shadow;
  const ArcCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color = kSurface,
    this.borderColor = kBorder,
    this.radius = kRadiusMd,
    this.shadow,
  });

  /// Ombre des panneaux qui flottent (fiche latérale, panneau dépliée).
  static const List<BoxShadow> raised = [
    BoxShadow(color: Color(0x1F1F2240), blurRadius: 24, offset: Offset(0, 8)),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor),
        boxShadow: shadow,
      ),
      child: child,
    );
  }
}

/// Tableau dans une carte : barre d'outils, contenu, pied (pagination).
class ArcTableCard extends StatelessWidget {
  final Widget? toolbar;
  final Widget child;
  final Widget? footer;
  const ArcTableCard({super.key, this.toolbar, required this.child, this.footer});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(kRadiusMd),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (toolbar != null) ...[
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: toolbar),
            const Divider(),
          ],
          child,
          if (footer != null) ...[
            const Divider(),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: footer),
          ],
        ],
      ),
    );
  }
}

/// Titre de section avec compteur facultatif.
class ArcSectionTitle extends StatelessWidget {
  final String title;
  final String? count;
  final ArcTone tone;
  final List<Widget> trailing;
  const ArcSectionTitle(this.title,
      {super.key, this.count, this.tone = ArcTone.info, this.trailing = const []});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(title, style: ArcText.sectionTitle()),
      if (count != null) ...[
        const SizedBox(width: 10),
        ArcCount(count!, tone: tone),
      ],
      const Spacer(),
      ...trailing,
    ]);
  }
}

/// Petit compteur en chiffres à chasse fixe.
class ArcCount extends StatelessWidget {
  final String value;
  final ArcTone tone;
  final bool square;
  const ArcCount(this.value,
      {super.key, this.tone = ArcTone.info, this.square = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(square ? kRadiusXs : 999),
      ),
      child: Text(value, style: ArcText.dataSmall(color: tone.text)),
    );
  }
}

/// Pagination compacte « 1–10 sur 937 ‹ › ».
class ArcPagination extends StatelessWidget {
  final String label;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final Widget? leading;
  const ArcPagination(
      {super.key,
      required this.label,
      this.onPrevious,
      this.onNext,
      this.leading});

  Widget _button(IconData icon, String tooltip, VoidCallback? onPressed) =>
      SizedBox(
        width: 32,
        height: 32,
        child: IconButton(
          tooltip: tooltip,
          padding: EdgeInsets.zero,
          iconSize: 18,
          style: IconButton.styleFrom(
            minimumSize: const Size(32, 32),
            side: BorderSide(color: onPressed == null ? kBorder : kBorderStrong),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
            disabledForegroundColor: kNavy300,
          ),
          onPressed: onPressed,
          icon: Icon(icon),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      if (leading != null) Expanded(child: leading!) else const Spacer(),
      Text(label, style: ArcText.dataSmall()),
      const SizedBox(width: 10),
      _button(Icons.chevron_left_rounded, 'Page précédente', onPrevious),
      const SizedBox(width: 6),
      _button(Icons.chevron_right_rounded, 'Page suivante', onNext),
    ]);
  }
}

/// Tuile d'indicateur. [dark] : la tuile mise en avant (navy, chiffre orange).
class ArcKpiTile extends StatelessWidget {
  final String label;
  final String value;
  final bool dark;
  final bool flat;
  const ArcKpiTile(
      {super.key,
      required this.label,
      required this.value,
      this.dark = false,
      this.flat = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: dark ? kNavy900 : (flat ? kNavy50 : kSurface),
        borderRadius: BorderRadius.circular(14),
        border: dark || flat ? null : Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label.toUpperCase(),
              style: ArcText.label(color: dark ? kNavy300 : kText2)),
          const SizedBox(height: 6),
          Text(value, style: ArcText.kpi(color: dark ? kOrange : kNavy900)),
        ],
      ),
    );
  }
}

/// Carré d'initiales (clients, partenaires).
class ArcAvatar extends StatelessWidget {
  final String name;
  final double size;
  final bool dark;
  const ArcAvatar(this.name, {super.key, this.size = 36, this.dark = false});

  static String initials(String name) {
    final words = name
        .replaceAll(RegExp(r"[^A-Za-zÀ-ÿ0-9 ]"), ' ')
        .split(' ')
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) {
      return words.first.substring(0, words.first.length < 2 ? 1 : 2).toUpperCase();
    }
    return (words[0][0] + words[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: dark ? kNavy900 : kNavy100,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Text(initials(name),
          style: ArcText.dialogTitle(color: dark ? kOrange : kNavy600)
              .copyWith(fontSize: size * 0.36, fontWeight: FontWeight.w800)),
    );
  }
}

/// État vide (pointillés, icône, titre, message).
class ArcEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final ArcTone tone;
  final Widget? action;
  const ArcEmptyState(
      {super.key,
      required this.icon,
      required this.title,
      this.message,
      this.tone = ArcTone.info,
      this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(kRadiusMd),
        border: Border.all(color: kBorderStrong),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
              color: tone.background, borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: tone.text),
        ),
        const SizedBox(height: 12),
        Text(title,
            textAlign: TextAlign.center,
            style: ArcText.cardTitle()),
        if (message != null) ...[
          const SizedBox(height: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Text(message!,
                textAlign: TextAlign.center, style: ArcText.small(color: kText3)),
          ),
        ],
        if (action != null) ...[const SizedBox(height: 16), action!],
      ]),
    );
  }
}

/// Liste de définitions « libellé : valeur » (fiches client / partenaire).
class ArcDefinitionList extends StatelessWidget {
  final List<(String, Widget)> entries;
  final double labelWidth;
  const ArcDefinitionList(this.entries, {super.key, this.labelWidth = 110});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (label, value) in entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(
                  width: labelWidth,
                  child: Text(label, style: ArcText.small(color: kText3))),
              Expanded(
                  child: DefaultTextStyle.merge(
                      style: ArcText.body().copyWith(fontSize: 13),
                      child: value)),
            ]),
          ),
      ],
    );
  }
}
