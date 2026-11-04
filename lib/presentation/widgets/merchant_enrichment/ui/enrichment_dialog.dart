import 'package:flutter/material.dart';
import '../../../utils/common.dart';
import '../../../utils/url_opener.dart';

/// Local presentation only. Callers retain ownership of every action and guard.
class EnrichmentDialog extends StatelessWidget {
  final Widget title, content;
  final List<Widget> actions;
  final double maxWidth;
  final bool scrollable;
  final VoidCallback? onClose;
  const EnrichmentDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions = const [],
    this.maxWidth = 1080,
    this.scrollable = true,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final border = OutlineInputBorder(borderRadius: BorderRadius.circular(12));
    return Theme(
      data: base.copyWith(
        textTheme: base.textTheme
            .apply(fontFamily: 'Poppins_regular', bodyColor: kBlack),
        colorScheme: base.colorScheme.copyWith(
          primary: kBlue,
          secondary: kOrange,
          surface: kPWhite,
          error: kRed,
        ),
        filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
          backgroundColor: kBlue,
          foregroundColor: kPWhite,
          minimumSize: const Size(48, 48),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        )),
        outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
          foregroundColor: kBlue,
          minimumSize: const Size(48, 48),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        )),
        textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
          foregroundColor: kBlue,
          minimumSize: const Size(48, 48),
        )),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: kPWhite,
          border: border,
          enabledBorder:
              border.copyWith(borderSide: const BorderSide(color: kLBlue)),
          contentPadding: const EdgeInsets.all(16),
        ),
        tabBarTheme: const TabBarThemeData(
          labelColor: kBlueEnd,
          unselectedLabelColor: kGrey,
          indicatorColor: kOrange,
        ),
      ),
      child: Dialog(
        insetPadding: const EdgeInsets.all(12),
        backgroundColor: kPWhite,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              color: kBlueEnd,
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
              child: Row(children: [
                Expanded(
                    child: Semantics(
                        header: true,
                        child: DefaultTextStyle(
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontFamily: 'Poppins_regular',
                              fontSize: 19,
                              fontWeight: FontWeight.w600,
                              color: kPWhite),
                          child: title,
                        ))),
                if (onClose != null)
                  IconButton(
                    tooltip: 'Fermer',
                    onPressed: onClose,
                    color: kPWhite,
                    icon: const Icon(Icons.close),
                  ),
              ]),
            ),
            Flexible(
                child: scrollable
                    ? SingleChildScrollView(
                        padding: const EdgeInsets.all(20), child: content)
                    : Padding(
                        padding: const EdgeInsets.all(12), child: content)),
            if (actions.isNotEmpty)
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                    color: kLGrey,
                    border: Border(top: BorderSide(color: kLBlue))),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 4,
                    children: actions),
              ),
          ]),
        ),
      ),
    );
  }
}

class EnrichmentNotice extends StatelessWidget {
  final Widget child;
  final bool error;
  const EnrichmentNotice({super.key, required this.child, this.error = false});
  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: error,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: kLGrey,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: error ? kRed : kLBlue)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(error ? Icons.error_outline : Icons.info_outline,
                color: error ? kRed : kBlue, size: 22),
            const SizedBox(width: 12),
            Expanded(child: child),
          ]),
        ),
      );
}

class EnrichmentBadge extends StatelessWidget {
  final String label;
  const EnrichmentBadge(this.label, {super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
            color: kLGrey, borderRadius: BorderRadius.circular(12)),
        child: Text(label,
            style:
                const TextStyle(color: kBlueEnd, fontWeight: FontWeight.w600)),
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
      VerticalDivider(width: 1, thickness: 1, color: kLBlue);

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
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                        color: kBlue.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12)),
                    child: DefaultTextStyle.merge(
                        style: const TextStyle(
                            color: kBlueEnd, fontWeight: FontWeight.w600),
                        child: _wideRow(
                            [for (final column in columns) column.label]))),
              for (var r = 0; r < rows.length; r++)
                Opacity(
                  opacity: muted.contains(r) ? 0.6 : 1,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: EdgeInsets.all(wide ? 8 : 12),
                    decoration: BoxDecoration(
                        color: kLGrey,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kLBlue.withValues(alpha: 0.6))),
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
                                                  color: kBlue,
                                                  fontWeight: FontWeight.w600),
                                              child: columns[i].label),
                                          rows[r].cells[i].child,
                                        ]),
                                  ),
                              ]),
                  ),
                ),
            ]);
      });
}

/// Petite pastille d'information (SIRET, état, niveau de correspondance…).
class EnrichmentChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;

  /// Détail affiché au survol.
  final String? tooltip;
  const EnrichmentChip(this.label,
      {super.key, this.icon, this.color = kBlueEnd, this.tooltip});

  @override
  Widget build(BuildContext context) {
    Widget chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.35))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
        ],
        Flexible(
            child: Text(label,
                style: TextStyle(fontSize: 12, color: color, height: 1.3))),
        if (tooltip != null) ...[
          const SizedBox(width: 4),
          Icon(Icons.info_outline, size: 13, color: color),
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
            minimumSize: const Size(0, 32),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            visualDensity: VisualDensity.compact),
        onPressed: () => openExternalUrl(url),
        icon: const Icon(Icons.open_in_new, size: 15),
        label: Text(host,
            style: const TextStyle(
                fontSize: 12, decoration: TextDecoration.underline)),
      ),
    );
  }
}
