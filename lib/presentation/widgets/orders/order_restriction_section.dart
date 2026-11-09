import 'package:flutter/material.dart';

import 'package:back_office_tribuneo_v2/data/local/storage_service.dart';
import 'package:back_office_tribuneo_v2/domain/errors/api_exception.dart';
import 'package:back_office_tribuneo_v2/domain/errors/order_error_messages.dart';
import 'package:back_office_tribuneo_v2/domain/models/order_beneficiaries_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/order_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/order_restriction_model.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/orders_usecase.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/_global.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/formatters.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/url_opener.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/arc/arc.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/orders/merchant_picker.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/orders/order_sheet.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/tribuneo_loader.dart';

// Commande restreinte à une liste de commerçants, côté fiche de la commande
// (spec du 28/10/2026, § 4) : badge, section « Commerçants acceptés »,
// modification et retrait de la liste.

/// « Restreinte : Noël 2026 · 12 commerçants » (badge de la fiche).
String restrictionBadgeLabel(OrderRestrictionSummary restriction) =>
    'Restreinte : ${restriction.label} · '
    '${plural(restriction.nbCommercants, 'commerçant')}';

/// « Restreinte : Noël 2026 (12 commerçants) » (infobulle de la liste).
String restrictionTooltip(OrderRestrictionSummary restriction) =>
    'Restreinte : ${restriction.label} '
    '(${plural(restriction.nbCommercants, 'commerçant')})';

/// Page des partenaires du site, présélectionnée sur la liste [restrictionId].
///
/// [network] : valeur du paramètre `reseau`. Le site (`partenaires.js`,
/// `findNetwork`) accepte le nom du réseau comme son identifiant ; le BO envoie
/// l'identifiant, qu'il connaît toujours et qui ne change pas.
String restrictionSiteUrl(String network, int restrictionId) =>
    Uri.https('tribuneo.com', '/partenaires.html',
        {'reseau': network, 'liste': '$restrictionId'}).toString();

/// Identifiant du réseau de la session, `null` s'il est inconnu (le lien vers le
/// site n'est alors pas affiché).
Future<String?> currentNetworkCode() async {
  try {
    final String? id = await StorageService().readSecureData('user_id_network');
    return id == null || int.tryParse(id.trim()) == null ? null : id.trim();
  } catch (_) {
    return null;
  }
}

/// Des chèques de la commande ont déjà servi à payer (montant restant inférieur
/// au montant d'origine). Statut inconnu : on considère que oui, l'avertissement
/// étant sans conséquence.
bool orderHasUsedVouchers(OrderBeneficiariesModel? status) {
  if (status == null) return true;
  return status.beneficiaries.any(
      (voucher) => voucher.assigned && voucher.remainingAmount < voucher.amount - 0.005);
}

/// Badge de tête de fiche.
class OrderRestrictionBadge extends StatelessWidget {
  final OrderRestrictionSummary restriction;
  const OrderRestrictionBadge(this.restriction, {super.key});

  @override
  Widget build(BuildContext context) {
    return ArcPill(restrictionBadgeLabel(restriction),
        tone: ArcTone.info, icon: Icons.lock_outline_rounded);
  }
}

/// Saisie de la liste d'une commande existante, puis
/// `PUT /order/{id}/restriction` (remplacement complet).
///
/// Retourne la liste enregistrée, `null` si l'utilisateur a annulé.
Future<OrderRestrictionModel?> showRestrictionEditDialog(
  BuildContext context, {
  required int idOrder,
  required RestrictionPartners partners,
  required bool vouchersUsed,
  OrderRestrictionModel? current,
  OrderUseCase? orderUseCase,
}) {
  return showDialog<OrderRestrictionModel>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _RestrictionEditDialog(
      idOrder: idOrder,
      partners: partners,
      vouchersUsed: vouchersUsed,
      current: current,
      orderUseCase: orderUseCase ?? OrderUseCase(),
    ),
  );
}

class _RestrictionEditDialog extends StatefulWidget {
  final int idOrder;
  final RestrictionPartners partners;
  final bool vouchersUsed;
  final OrderRestrictionModel? current;
  final OrderUseCase orderUseCase;

  const _RestrictionEditDialog({
    required this.idOrder,
    required this.partners,
    required this.vouchersUsed,
    required this.current,
    required this.orderUseCase,
  });

  @override
  State<_RestrictionEditDialog> createState() => _RestrictionEditDialogState();
}

class _RestrictionEditDialogState extends State<_RestrictionEditDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final RestrictionDraft _draft = RestrictionDraft(
    label: widget.current?.label ?? '',
    entityIds: widget.current?.entityIds ?? const [],
  );
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    widget.partners.load();
  }

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final String? problem = _draft.validate();
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    if (widget.vouchersUsed) {
      final bool confirmed = await showArcConfirm(
        context,
        title: 'Modifier la liste',
        message: 'Les paiements déjà faits ne changent pas. La nouvelle liste '
            "s'applique aux prochains paiements.",
        confirmLabel: 'Enregistrer',
        icon: Icons.info_outline_rounded,
      );
      if (!confirmed || !mounted) return;
    }

    final OrderRestrictionInput input = _draft.toInput();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final OrderRestrictionModel? saved =
          await widget.orderUseCase.updateOrderRestriction(widget.idOrder, input);
      if (!mounted) return;
      Navigator.of(context).pop(saved ??
          OrderRestrictionModel(
            id: widget.current?.id,
            label: input.label,
            entityIds: input.entityIds,
            nbCommercants: input.entityIds.length,
          ));
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.code == OrderErrorMessages.restrictionUnknownEntities) {
        // Commerçants sortis du réseau : décochés, et liste rechargée.
        _draft.deselectAll(OrderErrorMessages.unknownEntityIds(e.details));
        widget.partners.load(force: true);
      }
      setState(() {
        _saving = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_saving,
      child: ArcDialog(
        icon: Icons.storefront_outlined,
        title: widget.current == null
            ? 'Restreindre à certains commerçants'
            : 'Modifier la liste',
        maxWidth: 720,
        content: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                RestrictionEditor(
                  draft: _draft,
                  partners: widget.partners,
                  listHeight: 300,
                  enabled: !_saving,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: ArcText.body(color: kDangerText)),
                ],
              ],
            ),
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving ? const OrderButtonSpinner() : const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}

/// Section « Commerçants acceptés » de la fiche d'une commande, disponible quel
/// que soit l'état de la commande (payée, facturée, distribuée).
class OrderRestrictionSection extends StatefulWidget {
  final OrderModel order;

  /// Statut lu à l'ouverture de la fiche : sert à savoir si des chèques ont
  /// déjà été utilisés.
  final OrderBeneficiariesModel? orderStatus;

  /// Appelé après chaque modification (`null` : liste retirée).
  final ValueChanged<OrderRestrictionSummary?> onChanged;

  const OrderRestrictionSection({
    super.key,
    required this.order,
    required this.orderStatus,
    required this.onChanged,
  });

  @override
  State<OrderRestrictionSection> createState() =>
      _OrderRestrictionSectionState();
}

class _OrderRestrictionSectionState extends State<OrderRestrictionSection> {
  final OrderUseCase _orderUseCase = OrderUseCase();
  final RestrictionPartners _partners = RestrictionPartners();

  /// La commande a une liste (d'après `GET /order`, puis les actions faites ici).
  late bool _restricted = widget.order.restriction != null;
  OrderRestrictionModel? _restriction;
  bool _loading = false;
  bool _removing = false;
  String? _error;
  String? _networkCode;

  @override
  void initState() {
    super.initState();
    if (_restricted) {
      _loading = true;
      _fetchRestriction();
      _partners.load();
    }
    currentNetworkCode().then((code) {
      if (mounted) setState(() => _networkCode = code);
    });
  }

  @override
  void dispose() {
    _partners.dispose();
    super.dispose();
  }

  void _retry() {
    setState(() {
      _loading = true;
      _error = null;
    });
    _fetchRestriction();
    _partners.load();
  }

  Future<void> _fetchRestriction() async {
    try {
      final OrderRestrictionModel? restriction =
          await _orderUseCase.getOrderRestriction(widget.order.id!);
      if (!mounted) return;
      setState(() {
        _restriction = restriction;
        _restricted = restriction != null;
        _loading = false;
      });
      // Retirée entre-temps (autre poste) : la liste des commandes se mettra à
      // jour à la fermeture.
      if (restriction == null) widget.onChanged(null);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    }
  }

  Future<void> _edit() async {
    final OrderRestrictionModel? saved = await showRestrictionEditDialog(
      context,
      idOrder: widget.order.id!,
      partners: _partners,
      vouchersUsed: orderHasUsedVouchers(widget.orderStatus),
      current: _restriction,
      orderUseCase: _orderUseCase,
    );
    if (saved == null || !mounted) return;
    setState(() {
      _restriction = saved;
      _restricted = true;
      _error = null;
    });
    widget.onChanged(saved.summary);
    snackbarKey.currentState?.showSnackBar(const SnackBar(
        content: Text('Liste des commerçants enregistrée.'),
        backgroundColor: kGreen));
  }

  Future<void> _removeRestriction() async {
    final bool confirmed = await showArcConfirm(
      context,
      title: 'Rendre valable partout',
      message: 'Les chèques de cette commande seront acceptés chez tous les '
          'commerçants du réseau. Continuer ?',
      confirmLabel: 'Continuer',
      icon: Icons.lock_open_rounded,
    );
    if (!confirmed || !mounted) return;
    setState(() => _removing = true);
    try {
      await _orderUseCase.deleteOrderRestriction(widget.order.id!);
      if (!mounted) return;
      setState(() {
        _restriction = null;
        _restricted = false;
        _removing = false;
        _error = null;
      });
      widget.onChanged(null);
      snackbarKey.currentState?.showSnackBar(const SnackBar(
          content: Text(
              'La commande est désormais valable chez tous les commerçants.'),
          backgroundColor: kGreen));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _removing = false);
      snackbarKey.currentState?.showSnackBar(SnackBar(
          content: Text(e.message),
          backgroundColor: kRed,
          duration: const Duration(seconds: 8)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Commerçants acceptés', style: ArcText.cardTitle()),
        const SizedBox(height: 10),
        _content(),
      ],
    );
  }

  Widget _content() {
    if (!_restricted) {
      return OrderNotice(
        'Valable chez tous les commerçants du réseau.',
        action: ElevatedButton(
          style: orderCompactButtonStyle(),
          onPressed: _edit,
          child: const Text('Restreindre à certains commerçants'),
        ),
      );
    }
    if (_loading) {
      return const SizedBox(
          height: 64,
          child: Center(
              child: SizedBox(width: 28, height: 28, child: TribuneoLoader())));
    }
    if (_error != null || _restriction == null) {
      return OrderNotice(
        _error ?? 'Impossible de charger la liste des commerçants.',
        warning: true,
        action: OutlinedButton(
          style: orderCompactButtonStyle(),
          onPressed: _retry,
          child: const Text('Réessayer'),
        ),
      );
    }

    final OrderRestrictionModel restriction = _restriction!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${restriction.label} · '
          '${plural(restriction.nbCommercants, 'commerçant')}',
          style: ArcText.body().copyWith(fontWeight: FontWeight.w600),
        ),
        if (!restriction.active) ...[
          const SizedBox(height: 10),
          const OrderNotice(
            'Tous les chèques de cette commande ont expiré : la liste '
            "n'est plus affichée sur le site ni dans l'application.",
            warning: true,
          ),
        ],
        const SizedBox(height: 10),
        _merchantNames(restriction),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FilledButton(
              style: orderCompactButtonStyle(),
              onPressed: _removing ? null : _edit,
              child: const Text('Modifier la liste'),
            ),
            OutlinedButton(
              style: orderCompactButtonStyle(),
              onPressed: _removing ? null : _removeRestriction,
              child: _removing
                  ? const OrderButtonSpinner()
                  : const Text('Rendre valable partout'),
            ),
            if (_networkCode != null && restriction.id != null)
              TextButton.icon(
                onPressed: () => openExternalUrl(
                    restrictionSiteUrl(_networkCode!, restriction.id!)),
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: const Text('Voir sur le site'),
              ),
          ],
        ),
      ],
    );
  }

  /// Noms des commerçants de la liste, triés, d'après les partenaires chargés.
  Widget _merchantNames(OrderRestrictionModel restriction) {
    return ListenableBuilder(
      listenable: _partners,
      builder: (context, _) {
        if (_partners.merchants == null && _partners.loading) {
          return const SizedBox(
              height: 48,
              child: Center(
                  child:
                      SizedBox(width: 24, height: 24, child: TribuneoLoader())));
        }
        final List<int> ids = [...restriction.entityIds]..sort((a, b) =>
            _partners.nameOf(a).toLowerCase().compareTo(
                _partners.nameOf(b).toLowerCase()));
        if (ids.isEmpty) {
          return Text('Aucun commerçant.', style: ArcText.small(color: kText3));
        }
        return Container(
          constraints: const BoxConstraints(maxHeight: 220),
          decoration: BoxDecoration(
            border: Border.all(color: kBorder),
            borderRadius: BorderRadius.circular(kRadiusSm),
          ),
          clipBehavior: Clip.antiAlias,
          child: ListView.builder(
            shrinkWrap: true,
            itemExtent: 40,
            itemCount: ids.length,
            itemBuilder: (context, index) {
              final int id = ids[index];
              final RestrictionMerchant? merchant = _partners.byId(id);
              return Container(
                color: index.isEven ? kSurface : kSurface2,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const Icon(Icons.storefront_outlined,
                        size: 16, color: kNavy600),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        merchant != null && merchant.city.isNotEmpty
                            ? '${_partners.nameOf(id)} · ${merchant.city}'
                            : _partners.nameOf(id),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ArcText.body().copyWith(fontSize: 13),
                      ),
                    ),
                    if (merchant != null && !merchant.connected) ...[
                      const SizedBox(width: 8),
                      const NotConnectedBadge(),
                    ],
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
