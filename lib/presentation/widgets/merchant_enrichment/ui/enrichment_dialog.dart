import 'package:flutter/material.dart';
import '../../../utils/common.dart';
import '../../../utils/url_opener.dart';
import '../../arc/arc.dart';

/// Local presentation only. Callers retain ownership of every action and guard.
///
/// Dialogue « Arc » de l'import : fond blanc, titre en Bricolage Grotesque,
/// bouton de fermeture en haut à droite, pied gris clair pour les actions.
class EnrichmentDialog extends StatelessWidget {
  final Widget title, content;
  final List<Widget> actions;
  final double maxWidth;
  final bool scrollable;
  final VoidCallback? onClose;

  /// Petit libellé au-dessus du titre (ligne concernée…), en chasse fixe.
  final String? eyebrow;

  /// Élément affiché à droite du titre (légende de la carte…).
  final Widget? headerTrailing;
  const EnrichmentDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions = const [],
    this.maxWidth = 1080,
    this.scrollable = true,
    this.onClose,
    this.eyebrow,
    this.headerTrailing,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(12),
      backgroundColor: kSurface,
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: DefaultTextStyle.merge(
          style: const TextStyle(color: kInk, fontSize: 14, height: 1.45),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(
              padding:
                  EdgeInsets.fromLTRB(28, 22, onClose != null ? 18 : 28, 14),
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          if (eyebrow != null) ...[
                            Text(eyebrow!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: ArcText.dataSmall(color: kOrange700)
                                    .copyWith(fontSize: 12)),
                            const SizedBox(height: 4),
                          ],
                          Semantics(
                              header: true,
                              child: DefaultTextStyle(
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: ArcText.dialogTitle()
                                    .copyWith(fontSize: 24),
                                child: title,
                              )),
                        ])),
                    if (headerTrailing != null) ...[
                      const SizedBox(width: 12),
                      Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: headerTrailing!),
                    ],
                    if (onClose != null) ...[
                      const SizedBox(width: 10),
                      ArcIconAction(
                        icon: Icons.close_rounded,
                        tooltip: 'Fermer',
                        onPressed: onClose,
                        size: 34,
                      ),
                    ],
                  ]),
            ),
            Flexible(
                child: scrollable
                    ? SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(28, 4, 28, 20),
                        child: content)
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        child: content)),
            if (actions.isNotEmpty)
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                    color: kSurface2,
                    border: Border(top: BorderSide(color: kNavy100))),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                child: Wrap(
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    runSpacing: 8,
                    children: actions),
              ),
          ]),
        ),
      ),
    );
  }
}

/// Encadré d'information (navy), d'avertissement (orange) ou d'erreur
/// (framboise).
class EnrichmentNotice extends StatelessWidget {
  final Widget child;
  final bool error;

  /// Avertissement (orange) : ex. source indisponible lors de la recherche.
  final bool warning;
  const EnrichmentNotice(
      {super.key, required this.child, this.error = false, this.warning = false});
  @override
  Widget build(BuildContext context) {
    final Color background = error
        ? kDangerBg
        : warning
            ? kOrange50
            : kNavy50;
    final Color border = error
        ? kDanger.withValues(alpha: 0.45)
        : warning
            ? kOrange200
            : kNavy200;
    final Color ink = error
        ? kDangerText
        : warning
            ? kOrange700
            : kNavy600;
    return Semantics(
      liveRegion: error,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(
              error
                  ? Icons.error_outline_rounded
                  : warning
                      ? Icons.warning_amber_rounded
                      : Icons.info_outline_rounded,
              color: ink,
              size: 20),
          const SizedBox(width: 10),
          Expanded(
              child: DefaultTextStyle.merge(
                  style: const TextStyle(color: kInk, fontSize: 13),
                  child: child)),
        ]),
      ),
    );
  }
}

class EnrichmentBadge extends StatelessWidget {
  final String label;
  const EnrichmentBadge(this.label, {super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: kNavy100, borderRadius: BorderRadius.circular(8)),
        child: Text(label,
            style: const TextStyle(
                fontSize: 12, color: kNavy600, fontWeight: FontWeight.w600)),
      );
}

/// Retains the original DataCell widgets/callbacks; stacks values on narrow views.
///
/// Vue large : colonnes séparées par un trait vertical.
class EnrichmentComparison extends StatelessWidget {
  final List<DataColumn> columns;
  final List<DataRow> rows;

  /// Lignes estompées (rien à appliquer), par index.
  final Set<int> muted;
  const EnrichmentComparison(
      {super.key,
      required this.columns,
      required this.rows,
      this.muted = const {}});

  static const double _checkWidth = 96;
  static const _separator =
      VerticalDivider(width: 1, thickness: 1, color: kNavy100);

  /// Cellules d'une ligne large, séparées par un trait vertical.
  static Widget _wideRow(List<Widget> cells) => IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SizedBox(
              width: _checkWidth,
              child: Align(alignment: Alignment.center, child: cells[0])),
          for (final cell in cells.skip(1)) ...[
            _separator,
            Expanded(
                child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Align(alignment: Alignment.centerLeft, child: cell))),
          ],
        ]),
      );

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, size) {
        final wide = size.maxWidth >= 700;
        return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (wide)
                Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                        color: kSurface2,
                        border: Border.all(color: kNavy100),
                        borderRadius: BorderRadius.circular(12)),
                    child: DefaultTextStyle.merge(
                        style: const TextStyle(
                            fontSize: 12,
                            color: kText2,
                            fontWeight: FontWeight.w600),
                        child: _wideRow(
                            [for (final column in columns) column.label]))),
              for (var r = 0; r < rows.length; r++)
                Opacity(
                  opacity: muted.contains(r) ? 0.55 : 1,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: EdgeInsets.all(wide ? 8 : 12),
                    decoration: BoxDecoration(
                        color: kSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kBorder)),
                    child: DefaultTextStyle.merge(
                      style: const TextStyle(fontSize: 13, color: kInk),
                      child: wide
                          ? _wideRow(
                              [for (final cell in rows[r].cells) cell.child])
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                  Row(children: [
                                    rows[r].cells[0].child,
                                    Expanded(child: rows[r].cells[1].child)
                                  ]),
                                  for (var i = 2; i < rows[r].cells.length; i++)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            DefaultTextStyle.merge(
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color: kText2,
                                                    fontWeight:
                                                        FontWeight.w600),
                                                child: columns[i].label),
                                            rows[r].cells[i].child,
                                          ]),
                                    ),
                                ]),
                    ),
                  ),
                ),
            ]);
      });
}

/// Petite pastille d'information (SIRET, état, niveau de correspondance…).
///
/// [color] est la couleur du texte ; le fond teinté en découle (couleurs de
/// statut « Arc » : succès, avertissement, danger, neutre, navy).
class EnrichmentChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;

  /// Détail affiché au survol.
  final String? tooltip;

  /// Chiffres à chasse fixe (SIRET, SIREN).
  final bool mono;
  const EnrichmentChip(this.label,
      {super.key,
      this.icon,
      this.color = kNavy600,
      this.tooltip,
      this.mono = false});

  /// Fond teinté associé à une couleur de texte de statut.
  static Color backgroundFor(Color color) {
    if (color == kSuccessText || color == kGreen) return kSuccessBg;
    if (color == kWarningText || color == kOrange) return kWarningBg;
    if (color == kDangerText || color == kRed) return kDangerBg;
    if (color == kNeutralText || color == kGrey) return kNeutralBg;
    if (color == kNavy600 || color == kBlue || color == kBlueEnd) {
      return kNavy100;
    }
    return color.withValues(alpha: 0.1);
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle style = mono
        ? ArcText.dataSmall(color: color).copyWith(fontSize: 12, height: 1.35)
        : TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color,
            height: 1.35);
    Widget chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: backgroundFor(color),
          borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
        ],
        Flexible(child: Text(label, style: style)),
        if (tooltip != null) ...[
          const SizedBox(width: 4),
          Icon(Icons.info_outline_rounded, size: 13, color: color),
        ],
      ]),
    );
    if (tooltip != null) {
      chip = Tooltip(
          message: tooltip,
          waitDuration: const Duration(milliseconds: 200),
          child: chip);
    }
    return chip;
  }
}

/// Lien court vers une source publique : le domaine est affiché, l'adresse
/// complète est au survol. Seules les adresses http(s) sont ouvertes.
class EnrichmentSourceLink extends StatelessWidget {
  final String url;
  const EnrichmentSourceLink(this.url, {super.key});

  static String? _host(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null ||
        !(uri.scheme == 'https' || uri.scheme == 'http') ||
        uri.host.isEmpty) {
      return null;
    }
    return uri.host;
  }

  @override
  Widget build(BuildContext context) {
    final host = _host(url);
    if (host == null) return const SizedBox.shrink();
    return Tooltip(
      message: url,
      waitDuration: const Duration(milliseconds: 300),
      child: TextButton.icon(
        style: TextButton.styleFrom(
            foregroundColor: kNavy600,
            minimumSize: const Size(0, 32),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            visualDensity: VisualDensity.compact),
        onPressed: () => openExternalUrl(url),
        icon: const Icon(Icons.open_in_new_rounded, size: 15),
        label: Text(host,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline)),
      ),
    );
  }
}
