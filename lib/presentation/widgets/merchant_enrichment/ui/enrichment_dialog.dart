import 'package:flutter/material.dart';
import '../../../utils/common.dart';

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
class EnrichmentComparison extends StatelessWidget {
  final List<DataColumn> columns;
  final List<DataRow> rows;
  const EnrichmentComparison(
      {super.key, required this.columns, required this.rows});
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, size) {
        final wide = size.maxWidth >= 700;
        return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (wide)
                Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(children: [
                SizedBox(width: 112, child: columns[0].label),
                      for (final column in columns.skip(1))
                        Expanded(child: column.label),
                    ])),
              for (final row in rows)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: kLGrey, borderRadius: BorderRadius.circular(12)),
                  child: wide
                      ? Row(children: [
                  SizedBox(width: 112, child: row.cells[0].child),
                          for (final cell in row.cells.skip(1))
                            Expanded(
                                child: Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: cell.child)),
                        ])
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                              Row(children: [
                                row.cells[0].child,
                                Expanded(child: row.cells[1].child)
                              ]),
                              for (var i = 2; i < row.cells.length; i++)
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
                                        row.cells[i].child,
                                      ]),
                                ),
                            ]),
                ),
            ]);
      });
}
