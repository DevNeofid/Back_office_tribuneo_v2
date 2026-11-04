import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:back_office_tribuneo_v2/domain/models/order_model.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/formatters.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/arc/arc.dart';

// Composants « Arc » propres à l'écran Commandes (panneau latéral, libellés de
// champ, encarts, statut de paiement). Candidats au socle s'ils servent ailleurs.

/// Séparateur des en-têtes et pieds de panneau (Navy 100).
const Color _kSheetDivider = kNavy100;

/// En-tête « rubrique » au-dessus d'un titre de panneau : en capitales
/// (« NOUVELLE COMMANDE ») ou en chiffres à chasse fixe (n° de commande).
class OrderSheetEyebrow extends StatelessWidget {
  final String text;
  final bool data;
  const OrderSheetEyebrow(this.text, {super.key, this.data = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      data ? text : text.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: data
          ? ArcText.data(color: kOrange700).copyWith(fontSize: 12)
          : ArcText.label(color: kOrange700).copyWith(letterSpacing: 0.7),
    );
  }
}

/// En-tête de panneau ou de grand dialogue : rubrique, titre, zone sous le
/// titre et actions à droite.
class OrderSheetHeader extends StatelessWidget {
  final Widget? eyebrow;
  final String title;
  final Widget? below;
  final List<Widget> trailing;
  const OrderSheetHeader({
    super.key,
    this.eyebrow,
    required this.title,
    this.below,
    this.trailing = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 16),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _kSheetDivider))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (eyebrow != null) ...[
                      eyebrow!,
                      const SizedBox(height: 2),
                    ],
                    Semantics(
                      header: true,
                      child: Text(title,
                          style:
                              ArcText.dialogTitle().copyWith(fontSize: 26)),
                    ),
                  ],
                ),
              ),
              if (trailing.isNotEmpty) ...[
                const SizedBox(width: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: trailing,
                ),
              ],
            ],
          ),
          if (below != null) ...[const SizedBox(height: 14), below!],
        ],
      ),
    );
  }
}

/// Pied de panneau (fond Surface 2, séparateur en haut).
class OrderSheetFooter extends StatelessWidget {
  final Widget? leading;
  final List<Widget> actions;
  const OrderSheetFooter({super.key, this.leading, this.actions = const []});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      decoration: const BoxDecoration(
        color: kSurface2,
        border: Border(top: BorderSide(color: _kSheetDivider)),
      ),
      child: Wrap(
        alignment: leading == null
            ? WrapAlignment.end
            : WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: [
          if (leading != null) leading!,
          Wrap(spacing: 10, runSpacing: 10, children: actions),
        ],
      ),
    );
  }
}

/// Bouton « Fermer » carré des en-têtes de panneau.
class OrderSheetCloseButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const OrderSheetCloseButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) => ArcIconAction(
      icon: Icons.close_rounded, tooltip: 'Fermer', onPressed: onPressed);
}

/// Panneau latéral droit (formulaires de commande, bons) affiché par
/// `showDialog` : pleine hauteur, largeur [width] au plus.
class OrderSheet extends StatelessWidget {
  final String semanticLabel;
  final Widget header;
  final Widget body;
  final Widget? footer;
  final double width;

  /// Le corps défile de lui-même (tableau) : pas de défilement ni de marges.
  final bool scrollBody;
  const OrderSheet({
    super.key,
    required this.semanticLabel,
    required this.header,
    required this.body,
    this.footer,
    this.width = 660,
    this.scrollBody = true,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width),
        child: SizedBox.expand(
          child: Semantics(
            container: true,
            scopesRoute: true,
            namesRoute: true,
            explicitChildNodes: true,
            label: semanticLabel,
            child: DecoratedBox(
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
                color: kSurface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    header,
                    Expanded(
                      child: scrollBody
                          ? SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 28, vertical: 22),
                              child: body,
                            )
                          : body,
                    ),
                    if (footer != null) footer!,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Libellé au-dessus d'un champ (13 px, Navy 700), « (optionnel) » en clair.
class OrderField extends StatelessWidget {
  final String label;
  final bool optional;
  final Widget child;
  final bool compact;
  const OrderField(
      {super.key,
      required this.label,
      required this.child,
      this.optional = false,
      this.compact = false});

  @override
  Widget build(BuildContext context) {
    final TextStyle style = GoogleFonts.poppins(
        fontSize: compact ? 12 : 13,
        fontWeight: FontWeight.w500,
        color: kNavy700);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(TextSpan(text: label, style: style, children: [
          if (optional)
            TextSpan(
                text: ' (optionnel)',
                style: style.copyWith(
                    fontWeight: FontWeight.w400, color: kText3)),
        ])),
        SizedBox(height: compact ? 4 : 6),
        child,
      ],
    );
  }
}

/// Décoration des champs en lecture seule (fond Navy 50, bord discret).
InputDecoration orderReadOnlyDecoration({String? hintText, Widget? prefixIcon}) {
  OutlineInputBorder border() => OutlineInputBorder(
      borderRadius: BorderRadius.circular(kRadiusSm),
      borderSide: const BorderSide(color: kBorder, width: 1.5));
  return InputDecoration(
    hintText: hintText,
    prefixIcon: prefixIcon,
    filled: true,
    fillColor: kNavy50,
    border: border(),
    enabledBorder: border(),
    focusedBorder: border(),
  );
}

/// Bloc teinté d'une ligne de bons (montant, quantité, message).
class OrderLineBox extends StatelessWidget {
  final Widget child;
  final Widget? trailing;
  const OrderLineBox({super.key, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kNavy50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: child),
          if (trailing != null) ...[const SizedBox(width: 10), trailing!],
        ],
      ),
    );
  }
}

/// Encart d'information (Navy 100) ou d'attention (Orange 50 bordé).
class OrderNotice extends StatelessWidget {
  final String text;
  final bool warning;
  final Widget? action;
  const OrderNotice(this.text,
      {super.key, this.warning = false, this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: warning ? kOrange50 : kNavy100,
        borderRadius: BorderRadius.circular(14),
        border: warning ? Border.all(color: kOrange200) : null,
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 10,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 260),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Icon(
                      warning
                          ? Icons.lock_outline_rounded
                          : Icons.info_outline_rounded,
                      size: 18,
                      color: warning ? kOrange700 : kNavy600),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(text,
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          height: 1.45,
                          color: warning ? kInk : kNavy700)),
                ),
              ],
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

/// Bouton compact (36 px) des encarts et barres d'outils.
ButtonStyle orderCompactButtonStyle() => ButtonStyle(
      minimumSize:
          const WidgetStatePropertyAll(Size(0, kControlHeightCompact)),
      padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 14)),
      textStyle: WidgetStatePropertyAll(
          GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
    );

/// Indicateur de chargement des boutons d'enregistrement.
class OrderButtonSpinner extends StatelessWidget {
  const OrderButtonSpinner({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(strokeWidth: 2.2, color: kNavy600));
}

// ---------------------------------------------------------------------------
// Statut de paiement et expiration (lecture des données déjà chargées)
// ---------------------------------------------------------------------------

enum OrderPaymentKind { paid, unpaid, gap }

/// Paiement d'une commande : payée (payé = total), non payée (rien payé) ou
/// écart (payé ≠ total, signé : `+` trop payé, `−` reste à payer).
class OrderPaymentStatus {
  final OrderPaymentKind kind;
  final num paid;
  final num total;
  const OrderPaymentStatus._(this.kind, this.paid, this.total);

  factory OrderPaymentStatus.of(OrderModel order) {
    final num paid = order.paid ?? 0;
    final num total = order.totalAmount ?? 0;
    final OrderPaymentKind kind = (paid - total).abs() < 0.005
        ? OrderPaymentKind.paid
        : paid == 0
            ? OrderPaymentKind.unpaid
            : OrderPaymentKind.gap;
    return OrderPaymentStatus._(kind, paid, total);
  }

  num get gap => paid - total;

  ArcTone get tone => switch (kind) {
        OrderPaymentKind.paid => ArcTone.success,
        OrderPaymentKind.unpaid => ArcTone.danger,
        OrderPaymentKind.gap => ArcTone.warning,
      };

  String get _signedGap => '${gap > 0 ? '+' : '−'}${formatEuro(gap.abs())}';

  /// « Payée », « Non payée », « Écart +25,00 € ».
  String get label => switch (kind) {
        OrderPaymentKind.paid => 'Payée',
        OrderPaymentKind.unpaid => 'Non payée',
        OrderPaymentKind.gap => 'Écart $_signedGap',
      };

  /// « Écart · payé 150,00 € pour 125,00 € » (formulaire de modification).
  String get detailedLabel => kind == OrderPaymentKind.gap
      ? 'Écart · payé ${formatEuro(paid)} pour ${formatEuro(total)}'
      : label;

  Widget pill({bool detailed = false}) =>
      ArcPill(detailed ? detailedLabel : label, tone: tone);
}

/// Date d'expiration des bons de la commande, si lisible.
DateTime? orderExpiryDate(OrderModel order) =>
    DateTime.tryParse(order.fundExpiryDate?.date?.trim() ?? '');

/// La date d'expiration de la commande est passée.
bool isOrderExpired(OrderModel order, [DateTime? now]) {
  final DateTime? expiry = orderExpiryDate(order);
  return expiry != null && expiry.isBefore(now ?? DateTime.now());
}
