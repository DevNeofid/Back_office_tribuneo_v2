import 'package:back_office_tribuneo_v2/presentation/widgets/tribuneo_loader.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:back_office_tribuneo_v2/presentation/widgets/arc/arc.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';

/// Panneau latéral de formulaire « Arc » (maquette FormClient) : en-tête avec
/// rubrique en capitales, titre et bouton de fermeture, corps défilant en
/// sections, pied gris clair avec les actions (l'action principale en
/// dernier). S'ouvre avec `showDialog`, comme les anciens formulaires.
///
/// Partagé par les formulaires clients, partenaires, adresses, informations
/// bancaires et secteurs (à déplacer dans le socle `widgets/arc`).
class ArcFormPanel extends StatelessWidget {
  final String eyebrow;
  final String title;
  final Widget? subtitle;
  final List<Widget> children;
  final List<Widget> actions;

  /// `null` : bouton de fermeture désactivé (enregistrement en cours).
  final VoidCallback? onClose;
  final double width;

  const ArcFormPanel({
    super.key,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    required this.children,
    required this.actions,
    required this.onClose,
    this.width = 600,
  });

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.sizeOf(context).width;
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: math.min(width, screenWidth),
        height: double.infinity,
        decoration: const BoxDecoration(
          color: kSurface,
          boxShadow: [
            BoxShadow(
                color: Color(0x4D1F2240),
                blurRadius: 64,
                spreadRadius: -12,
                offset: Offset(0, 24)),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(eyebrow.toUpperCase(),
                              style: ArcText.label(color: kOrange700)
                                  .copyWith(letterSpacing: 0.7)),
                          const SizedBox(height: 2),
                          Text(title,
                              style: ArcText.dialogTitle()
                                  .copyWith(fontSize: 26, height: 1.15)),
                          if (subtitle != null) ...[
                            const SizedBox(height: 6),
                            DefaultTextStyle.merge(
                                style: ArcText.small(color: kText2),
                                child: subtitle!),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ArcIconAction(
                      icon: Icons.close_rounded,
                      tooltip: 'Fermer',
                      onPressed: onClose,
                    ),
                  ],
                ),
              ),
              const Divider(color: kNavy100),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 22, 28, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (int i = 0; i < children.length; i++) ...[
                        if (i > 0) const SizedBox(height: 26),
                        children[i],
                      ],
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                decoration: const BoxDecoration(
                  color: kSurface2,
                  border: Border(top: BorderSide(color: kNavy100)),
                ),
                child: Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: actions,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Section numérotée (ou marquée d'une icône) d'un [ArcFormPanel].
class ArcFormSection extends StatelessWidget {
  final String? number;
  final IconData? icon;
  final String title;
  final List<Widget> children;
  const ArcFormSection({
    super.key,
    this.number,
    this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: kNavy100, borderRadius: BorderRadius.circular(8)),
            child: number != null
                ? Text(number!,
                    style: ArcText.dataSmall(color: kNavy600)
                        .copyWith(fontSize: 12, fontWeight: FontWeight.w600))
                : Icon(icon ?? Icons.edit_note_rounded,
                    size: 16, color: kNavy600),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: ArcText.cardTitle())),
        ]),
        for (final child in children) ...[
          const SizedBox(height: 14),
          child,
        ],
      ],
    );
  }
}

/// Élément de [ArcFormGrid] ; [span] : toute la largeur.
class ArcGridItem {
  final Widget child;
  final bool span;
  const ArcGridItem(this.child, {this.span = false});
}

/// Grille de champs sur deux colonnes (une seule sous 420 px).
class ArcFormGrid extends StatelessWidget {
  final List<ArcGridItem> items;
  const ArcFormGrid(this.items, {super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final double full = constraints.maxWidth;
      final bool twoColumns = full >= 420;
      final double half = twoColumns ? (full - 16) / 2 : full;
      return Wrap(
        spacing: 16,
        runSpacing: 14,
        children: [
          for (final item in items)
            SizedBox(width: item.span ? full : half, child: item.child),
        ],
      );
    });
  }
}

/// Saisie en chiffres à chasse fixe (SIRET, IBAN, téléphone, codes) : le
/// texte saisi passe en Martian Mono, le libellé reste en Poppins.
class ArcMonoField extends StatelessWidget {
  final Widget child;
  const ArcMonoField({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle mono = ArcText.data().copyWith(fontSize: 14);
    return Theme(
      data: theme.copyWith(
        textTheme: theme.textTheme.copyWith(
          bodyLarge: mono,
          titleMedium: mono,
        ),
      ),
      child: child,
    );
  }
}

/// Note d'aide (icône info et texte gris).
class ArcFormNote extends StatelessWidget {
  final String text;
  const ArcFormNote(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 1),
          child: Icon(Icons.info_outline_rounded, size: 16, color: kText3),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: ArcText.small(color: kText3))),
      ],
    );
  }
}

/// Carte à interrupteur (ex. « Accepte la dématérialisation »).
class ArcToggleCard extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String title;
  final String? subtitle;
  const ArcToggleCard({
    super.key,
    required this.value,
    required this.onChanged,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kSurface2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: kBorder, width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            Switch(value: value, onChanged: onChanged),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: kNavy900)),
                  if (subtitle != null)
                    Text(subtitle!, style: ArcText.small(color: kText3)),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Action principale (orange) ; le loader Tribuneo remplace le libellé pendant
/// l'enregistrement.
class ArcSubmitButton extends StatelessWidget {
  final String label;
  final bool busy;
  final VoidCallback onPressed;
  const ArcSubmitButton({
    super.key,
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: busy ? null : onPressed,
      child: busy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: TribuneoLoader(),
            )
          : Text(label),
    );
  }
}
