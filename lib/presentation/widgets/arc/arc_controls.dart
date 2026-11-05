import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:back_office_tribuneo_v2/presentation/utils/arc_theme.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';

/// Un segment de [ArcSegmented].
class ArcSegment<T> {
  final T value;
  final String label;
  final String? count;
  final IconData? icon;
  const ArcSegment(this.value, this.label, {this.count, this.icon});
}

/// Onglets segmentés (fond Navy 100, segment choisi en blanc).
class ArcSegmented<T> extends StatelessWidget {
  final List<ArcSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;
  final bool expand;
  final double height;
  const ArcSegmented({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.expand = false,
    this.height = 34,
  });

  @override
  Widget build(BuildContext context) {
    final children = [
      for (final s in segments)
        _segment(s, s.value == selected),
    ];
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
          color: kNavy100, borderRadius: BorderRadius.circular(kRadiusSm)),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 3),
            expand ? Expanded(child: children[i]) : children[i],
          ],
        ],
      ),
    );
  }

  Widget _segment(ArcSegment<T> s, bool on) {
    return Semantics(
      selected: on,
      button: true,
      child: Material(
        color: on ? kSurface : Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => onChanged(s.value),
          child: Container(
            height: height,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: on
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                        BoxShadow(
                            color: Color(0x261F2240),
                            blurRadius: 3,
                            offset: Offset(0, 1))
                      ])
                : null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (s.icon != null) ...[
                  Icon(s.icon, size: 16, color: on ? kNavy900 : kText2),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(s.label,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: on ? kNavy900 : kText2)),
                ),
                if (s.count != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                        color: on ? kNavy900 : kNavy200,
                        borderRadius: BorderRadius.circular(999)),
                    child: Text(s.count!,
                        style: ArcText.dataSmall(
                            color: on ? Colors.white : kNavy700)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Champ de recherche (icône loupe, hauteur 40).
class ArcSearchField extends StatelessWidget {
  final TextEditingController? controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final double? width;
  final String semanticLabel;
  const ArcSearchField({
    super.key,
    this.controller,
    this.hint = 'Rechercher…',
    this.onChanged,
    this.onSubmitted,
    this.width,
    this.semanticLabel = 'Rechercher',
  });

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: ArcText.body(),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        prefixIconConstraints: const BoxConstraints(minWidth: 40),
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(kRadiusSm),
            borderSide: const BorderSide(color: kBorder, width: 1.5)),
      ),
    );
    return Semantics(
        label: semanticLabel,
        child: SizedBox(width: width, height: 40, child: field));
  }
}

/// Bouton icône carré (36 px, fond Navy 50) avec infobulle.
class ArcIconAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color background;
  final Color foreground;
  final double size;
  const ArcIconAction({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.background = kNavy50,
    this.foreground = kNavy600,
    this.size = kControlHeightCompact,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        iconSize: 18,
        style: IconButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          disabledBackgroundColor: kNavy50,
          disabledForegroundColor: kNavy300,
          minimumSize: Size(size, size),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        icon: Icon(icon),
      ),
    );
  }
}

/// Puce de filtre en pilule (grille d'import, lettres, catégories).
class ArcFilterChip extends StatelessWidget {
  final String label;
  final String? count;
  final bool selected;
  final VoidCallback? onTap;
  const ArcFilterChip(
      {super.key,
      required this.label,
      this.count,
      this.selected = false,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color fg = selected ? Colors.white : kNavy700;
    return Material(
      color: selected ? kNavy900 : kSurface,
      shape: StadiumBorder(
          side: BorderSide(color: selected ? kNavy900 : kBorder)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
            if (count != null) ...[
              const SizedBox(width: 6),
              Text(count!,
                  style: ArcText.dataSmall(
                      color: selected ? kNavy200 : kText2)),
            ],
          ]),
        ),
      ),
    );
  }
}

/// Rangée de lettres (A, B, C…) pour filtrer une liste par initiale (clients,
/// partenaires). [selected] `null` : aucune lettre active (recherche en cours).
class ArcLetterBar extends StatelessWidget {
  final List<String> letters;
  final String? selected;
  final ValueChanged<String> onSelected;
  const ArcLetterBar({
    super.key,
    required this.letters,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [for (final letter in letters) _button(letter)],
    );
  }

  Widget _button(String letter) {
    final bool on = selected != null && selected == letter;
    return Tooltip(
      message: 'Lettre ${letter.toUpperCase()}',
      child: Semantics(
        selected: on,
        button: true,
        child: Material(
          color: on ? kNavy600 : kSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: on ? kNavy600 : kBorder),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => onSelected(letter),
            child: SizedBox(
              width: 28,
              height: 28,
              child: Center(
                child: Text(
                  letter.toUpperCase(),
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: on ? Colors.white : kText2),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
