import 'dart:collection';

import 'package:flutter/material.dart';

import 'package:back_office_tribuneo_v2/domain/errors/order_error_messages.dart';
import 'package:back_office_tribuneo_v2/domain/models/entity_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/order_restriction_model.dart';
import 'package:back_office_tribuneo_v2/domain/repositories/partner_repository.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/partner_usecase.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/formatters.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/local_search.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/arc/arc.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/orders/order_sheet.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/tribuneo_loader.dart';

// Liste de commerçants d'une commande restreinte (spec du 28/10/2026, § 3) :
// nom de la liste et sélecteur, utilisés à la création et en modification.

/// Infobulle du badge des commerçants qui n'acceptent pas encore les chèques
/// dématérialisés (`accept_demat` faux).
const String kNotConnectedTooltip =
    "Ce commerçant ne s'est jamais connecté : il ne pourra encaisser ces "
    "chèques qu'après sa première connexion, et il n'apparaît pas sur "
    'tribuneo.com.';

/// Un commerçant proposé dans le sélecteur.
class RestrictionMerchant {
  final int id;
  final String name;
  final String city;
  final String sectors;

  /// Accepte les chèques dématérialisés (`accept_demat`).
  final bool connected;

  /// Nom et ville sans accents ni majuscules, pour la recherche.
  final String _searchKey;

  RestrictionMerchant({
    required this.id,
    required this.name,
    this.city = '',
    this.sectors = '',
    this.connected = true,
  }) : _searchKey = searchKey('$name $city');

  factory RestrictionMerchant.fromEntity(EntityModel entity) {
    return RestrictionMerchant(
      id: entity.id!,
      name: entity.name?.trim() ?? '',
      city: entity.address?.city?.trim() ?? '',
      sectors: (entity.activitySectors ?? [])
          .map((sector) => sector.name?.trim() ?? '')
          .where((name) => name.isNotEmpty)
          .join(', '),
      connected: entity.acceptDemat == true,
    );
  }

  /// « Châtillon-sur-Seine · Boulangerie », sans les parties absentes.
  String get subtitle =>
      [city, sectors].where((part) => part.isNotEmpty).join(' · ');

  /// `true` si chaque mot de [terms] (déjà passés par [searchKey]) figure dans
  /// le nom ou la ville.
  bool matches(List<String> terms) => terms.every(_searchKey.contains);

  /// Partenaires avec un id, sans doublon, triés par nom.
  static List<RestrictionMerchant> sortedFrom(Iterable<EntityModel> entities) {
    final Map<int, RestrictionMerchant> byId = {};
    for (final EntityModel entity in entities) {
      if (entity.id == null) continue;
      byId.putIfAbsent(entity.id!, () => RestrictionMerchant.fromEntity(entity));
    }
    final List<RestrictionMerchant> merchants = byId.values.toList()
      ..sort((a, b) {
        final int byName = searchKey(a.name).compareTo(searchKey(b.name));
        return byName != 0 ? byName : a.id.compareTo(b.id);
      });
    return merchants;
  }
}

/// Partenaires du réseau (`GET /entity?entity_type=partner`), chargés une fois
/// à la demande : sélecteur et noms des commerçants d'une liste.
class RestrictionPartners extends ChangeNotifier {
  final PartnerUseCase _partnerUseCase;
  RestrictionPartners({PartnerUseCase? partnerUseCase})
      : _partnerUseCase = partnerUseCase ?? PartnerUseCase();

  List<RestrictionMerchant>? _merchants;
  Map<int, RestrictionMerchant> _byId = const {};
  bool _loading = false;
  String? _error;
  Future<void>? _pending;
  bool _disposed = false;

  /// `null` tant que la liste n'est pas chargée.
  List<RestrictionMerchant>? get merchants => _merchants;
  bool get loading => _loading;
  String? get error => _error;

  /// Charge la liste si ce n'est pas déjà fait ([force] : la recharge).
  Future<void> load({bool force = false}) {
    if (!force && _merchants != null) return Future.value();
    // En microtâche : un appel depuis `initState` ne notifie pas les écouteurs
    // pendant la construction de l'écran.
    return _pending ??=
        Future.microtask(_load).whenComplete(() => _pending = null);
  }

  Future<void> _load() async {
    _loading = true;
    _error = null;
    _notify();
    try {
      final Map<int, dynamic> result = await _partnerUseCase.getPartners();
      final List<EntityModel> partners =
          (result[PartnerRepository.allPartnersKey] as List?)
                  ?.whereType<EntityModel>()
                  .toList() ??
              [];
      _merchants = RestrictionMerchant.sortedFrom(partners);
      _byId = {for (final merchant in _merchants!) merchant.id: merchant};
    } catch (_) {
      _error = 'Impossible de charger la liste des commerçants.';
    }
    _loading = false;
    _notify();
  }

  RestrictionMerchant? byId(int id) => _byId[id];

  /// Nom du commerçant, ou son numéro s'il n'est plus dans la liste.
  String nameOf(int id) {
    final String? name = _byId[id]?.name;
    return name == null || name.isEmpty ? 'Commerçant n° $id' : name;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// Saisie en cours : nom de la liste et commerçants cochés. La sélection est
/// conservée quand un commerçant est masqué par la recherche ou le filtre.
class RestrictionDraft extends ChangeNotifier {
  final TextEditingController labelController;
  final Set<int> _selected;

  RestrictionDraft({String label = '', Iterable<int> entityIds = const []})
      : labelController = TextEditingController(text: label),
        _selected = {...entityIds};

  Set<int> get selected => UnmodifiableSetView(_selected);
  int get selectedCount => _selected.length;
  bool isSelected(int id) => _selected.contains(id);

  void setSelected(int id, bool selected) {
    final bool changed = selected ? _selected.add(id) : _selected.remove(id);
    if (changed) notifyListeners();
  }

  void selectAll(Iterable<int> ids) {
    final int before = _selected.length;
    _selected.addAll(ids);
    if (_selected.length != before) notifyListeners();
  }

  void deselectAll(Iterable<int> ids) {
    final int before = _selected.length;
    _selected.removeAll(ids);
    if (_selected.length != before) notifyListeners();
  }

  /// Contrôle du nom avant envoi (l'API le refait).
  static String? validateLabel(String? value) {
    final String label = value?.trim() ?? '';
    if (label.isEmpty) {
      return OrderErrorMessages.restrictionMessageForCode(
          'RESTRICTION_LABEL_REQUIRED');
    }
    if (label.length > kRestrictionLabelMaxLength) {
      return OrderErrorMessages.restrictionMessageForCode(
          'RESTRICTION_LABEL_TOO_LONG');
    }
    return null;
  }

  /// Premier problème de la saisie, `null` si elle peut être envoyée.
  String? validate() =>
      validateLabel(labelController.text) ??
      (_selected.isEmpty
          ? OrderErrorMessages.restrictionMessageForCode('RESTRICTION_EMPTY')
          : null);

  OrderRestrictionInput toInput() => OrderRestrictionInput(
        label: labelController.text.trim(),
        entityIds: _selected.toList()..sort(),
      );

  @override
  void dispose() {
    labelController.dispose();
    super.dispose();
  }
}

/// Nom de la liste et sélecteur de commerçants.
class RestrictionEditor extends StatelessWidget {
  final RestrictionDraft draft;
  final RestrictionPartners partners;
  final double listHeight;
  final bool enabled;

  const RestrictionEditor({
    super.key,
    required this.draft,
    required this.partners,
    this.listHeight = 340,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        OrderField(
          label: 'Nom de la liste',
          child: TextFormField(
            controller: draft.labelController,
            enabled: enabled,
            maxLength: kRestrictionLabelMaxLength,
            style: ArcText.body(),
            validator: RestrictionDraft.validateLabel,
            decoration: const InputDecoration(
              hintText: 'Ex. Noël 2026',
              helperText: 'Ce nom sera visible publiquement sur tribuneo.com '
                  "et dans l'application (ex. « Noël 2026 »).",
              helperMaxLines: 3,
            ),
          ),
        ),
        const SizedBox(height: 10),
        OrderField(
          label: 'Commerçants acceptés',
          child: ListenableBuilder(
            listenable: partners,
            builder: (context, _) {
              final List<RestrictionMerchant>? merchants = partners.merchants;
              if (merchants == null) {
                return _PartnersPlaceholder(
                  height: listHeight,
                  error: partners.loading ? null : partners.error,
                  onRetry: () => partners.load(force: true),
                );
              }
              return MerchantPicker(
                merchants: merchants,
                draft: draft,
                listHeight: listHeight,
                enabled: enabled,
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Chargement (ou échec du chargement) des partenaires.
class _PartnersPlaceholder extends StatelessWidget {
  final double height;
  final String? error;
  final VoidCallback onRetry;
  const _PartnersPlaceholder(
      {required this.height, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: kBorder),
        borderRadius: BorderRadius.circular(kRadiusSm),
      ),
      child: error == null
          ? const SizedBox(width: 32, height: 32, child: TribuneoLoader())
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(error!, style: ArcText.body(color: kDangerText)),
                const SizedBox(height: 10),
                OutlinedButton(
                  style: orderCompactButtonStyle(),
                  onPressed: onRetry,
                  child: const Text('Réessayer'),
                ),
              ],
            ),
    );
  }
}

/// Sélecteur de commerçants : recherche par nom ou ville, filtre « pas encore
/// connectés », compteur, « Tout cocher / Tout décocher » sur les commerçants
/// affichés, liste virtualisée.
class MerchantPicker extends StatefulWidget {
  /// Triés par nom ([RestrictionMerchant.sortedFrom]).
  final List<RestrictionMerchant> merchants;
  final RestrictionDraft draft;
  final double listHeight;
  final bool enabled;

  const MerchantPicker({
    super.key,
    required this.merchants,
    required this.draft,
    this.listHeight = 340,
    this.enabled = true,
  });

  @override
  State<MerchantPicker> createState() => _MerchantPickerState();
}

class _MerchantPickerState extends State<MerchantPicker> {
  static const double _rowHeight = 56;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<String> _terms = const [];
  bool _showNotConnected = false;

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    setState(() {
      _terms = searchKey(value).split(' ').where((t) => t.isNotEmpty).toList();
    });
    _scrollToTop();
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  List<RestrictionMerchant> get _visible => widget.merchants
      .where((m) => (_showNotConnected || m.connected) && m.matches(_terms))
      .toList();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.draft,
      builder: (context, _) {
        final List<RestrictionMerchant> visible = _visible;
        final List<int> visibleIds = [for (final m in visible) m.id];
        final bool canSelect = widget.enabled &&
            visibleIds.any((id) => !widget.draft.isSelected(id));
        final bool canDeselect =
            widget.enabled && visibleIds.any(widget.draft.isSelected);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            ArcSearchField(
              controller: _searchController,
              hint: 'Rechercher par nom ou ville',
              onChanged: _onSearch,
            ),
            const SizedBox(height: 6),
            _notConnectedFilter(),
            const SizedBox(height: 4),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 4,
              children: [
                Text(
                  '${plural(widget.draft.selectedCount, 'sélectionné')} · '
                  '${plural(visible.length, 'affiché')}',
                  style: ArcText.small(color: kNavy700)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                Wrap(
                  spacing: 4,
                  children: [
                    TextButton(
                      onPressed: canSelect
                          ? () => widget.draft.selectAll(visibleIds)
                          : null,
                      child: const Text('Tout cocher'),
                    ),
                    TextButton(
                      onPressed: canDeselect
                          ? () => widget.draft.deselectAll(visibleIds)
                          : null,
                      child: const Text('Tout décocher'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              height: widget.listHeight,
              decoration: BoxDecoration(
                border: Border.all(color: kBorder),
                borderRadius: BorderRadius.circular(kRadiusSm),
              ),
              clipBehavior: Clip.antiAlias,
              child: visible.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          widget.merchants.isEmpty
                              ? 'Aucun commerçant dans ce réseau.'
                              : 'Aucun commerçant ne correspond.',
                          textAlign: TextAlign.center,
                          style: ArcText.body(color: kText3),
                        ),
                      ),
                    )
                  : Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      child: ListView.builder(
                        controller: _scrollController,
                        itemExtent: _rowHeight,
                        itemCount: visible.length,
                        itemBuilder: (context, index) =>
                            _row(visible[index], index),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _notConnectedFilter() {
    return InkWell(
      borderRadius: BorderRadius.circular(kRadiusSm),
      onTap: () => _setShowNotConnected(!_showNotConnected),
      child: Row(
        children: [
          Checkbox(
            value: _showNotConnected,
            onChanged: (value) => _setShowNotConnected(value ?? false),
          ),
          Flexible(
            child: Text(
              'Afficher aussi les commerçants pas encore connectés à Tribuneo',
              style: ArcText.small(color: kText2).copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  void _setShowNotConnected(bool value) {
    setState(() => _showNotConnected = value);
    _scrollToTop();
  }

  Widget _row(RestrictionMerchant merchant, int index) {
    final bool selected = widget.draft.isSelected(merchant.id);
    final String subtitle = merchant.subtitle;
    return Material(
      color: selected
          ? kNavy50
          : (index.isEven ? kSurface : kSurface2),
      child: InkWell(
        onTap: widget.enabled
            ? () => widget.draft.setSelected(merchant.id, !selected)
            : null,
        child: Padding(
          padding: const EdgeInsets.only(left: 4, right: 12),
          child: Row(
            children: [
              Checkbox(
                value: selected,
                onChanged: widget.enabled
                    ? (value) =>
                        widget.draft.setSelected(merchant.id, value ?? false)
                    : null,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      merchant.name.isEmpty
                          ? 'Commerçant n° ${merchant.id}'
                          : merchant.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ArcText.body().copyWith(
                          fontWeight: FontWeight.w500, height: 1.3),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ArcText.small(color: kText3),
                      ),
                  ],
                ),
              ),
              if (!merchant.connected) ...[
                const SizedBox(width: 8),
                const NotConnectedBadge(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Badge gris « Pas encore connecté » et son infobulle.
class NotConnectedBadge extends StatelessWidget {
  const NotConnectedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return const Tooltip(
      message: kNotConnectedTooltip,
      child: ArcPill('Pas encore connecté', tone: ArcTone.neutral),
    );
  }
}
