import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:back_office_tribuneo_v2/presentation/utils/arc_theme.dart';

/// Pastille de statut du design system « Arc » : une icône (ou un point) et
/// un libellé, pour que le statut reste lisible sans la couleur.
class ArcPill extends StatelessWidget {
  final String label;
  final ArcTone tone;
  final IconData? icon;

  /// Fond plein (ex. « Importée ») au lieu du fond teinté.
  final bool solid;

  /// Coins de 8 px (pastilles d'information) au lieu d'une pilule.
  final bool square;

  const ArcPill(this.label,
      {super.key,
      this.tone = ArcTone.info,
      this.icon,
      this.solid = false,
      this.square = false});

  @override
  Widget build(BuildContext context) {
    final Color foreground = solid ? Colors.white : tone.text;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: solid ? tone.text : tone.background,
        borderRadius: BorderRadius.circular(square ? 8 : 999),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null)
          Icon(icon, size: 14, color: foreground)
        else
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
                color: solid ? Colors.white : tone.dot, shape: BoxShape.circle),
          ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                  fontSize: 12, fontWeight: FontWeight.w600, color: foreground)),
        ),
      ]),
    );
  }
}
