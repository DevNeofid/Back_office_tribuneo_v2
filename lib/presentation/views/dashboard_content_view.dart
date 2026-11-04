import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:back_office_tribuneo_v2/core/notifiers/screen_open_requests.dart';
import 'package:back_office_tribuneo_v2/domain/models/accounting_entries_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/bank_account_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/bto_preview_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/merchant_import_batch_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/order_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/paginated_result.dart';
import 'package:back_office_tribuneo_v2/domain/models/transfer_order_model.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/accounting_entries_usecase.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/bank_account_usecase.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/merchant_import_usecase.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/orders_usecase.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/transfer_order_usecase.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/_global.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/formatters.dart';
import 'package:back_office_tribuneo_v2/presentation/views/my_single_page.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/arc/arc.dart';

/// Résultat d'un chargement : la valeur, ou l'erreur rencontrée. Une carte en
/// erreur s'affiche seule en erreur, sans bloquer le reste de la page.
class _Load<T> {
  final T? value;
  final Object? error;
  const _Load.ok(this.value) : error = null;
  const _Load.failed(Object this.error) : value = null;

  bool get failed => error != null;
}

Future<_Load<T>> _guard<T>(Future<T> Function() load) async {
  try {
    return _Load<T>.ok(await load());
  } catch (e) {
    return _Load<T>.failed(e);
  }
}

/// Derniers ordres de virement et comptes du réseau (libellé du compte payeur,
/// affiché seulement s'il y en a plusieurs).
class _Transfers {
  final List<TransferOrderModel> items;
  final BankAccountsModel? bankAccounts;
  const _Transfers(this.items, this.bankAccounts);
}

/// Tableau de bord : « Bonjour {réseau} », les éléments à traiter (prochain
/// virement, import en relecture, écritures), les dernières commandes, des
/// raccourcis et les derniers virements. Lecture seule : chaque bloc vient
/// d'un use case existant.
class DashboardContentView extends StatefulWidget {
  const DashboardContentView({super.key});

  @override
  State<DashboardContentView> createState() => _DashboardContentViewState();
}

class _DashboardContentViewState extends State<DashboardContentView> {
  late Future<List<_Load<Object?>>> _todo;
  late Future<_Load<PaginatedResult<OrderModel>>> _orders;
  late Future<_Load<_Transfers>> _transfers;

  @override
  void initState() {
    super.initState();
    _todo = _loadTodo();
    _orders = _loadOrders();
    _transfers = _loadTransfers();
  }

  Future<List<_Load<Object?>>> _loadTodo() => Future.wait<_Load<Object?>>([
        _guard<Object?>(() => TransferOrderUseCase().getPreview()),
        _guard<Object?>(_reviewBatch),
        _guard<Object?>(
            () => AccountingEntriesUseCase().getAccountingEntries(limit: 1)),
      ]);

  /// Import de commerçants en attente de relecture (le plus récent).
  Future<MerchantImportBatch?> _reviewBatch() async {
    final List<MerchantImportBatch> batches =
        await MerchantImportUseCase().getBatches(limit: 20);
    return batches.where((batch) => batch.isEditable).firstOrNull;
  }

  Future<_Load<PaginatedResult<OrderModel>>> _loadOrders() =>
      _guard(() => OrderUseCase().getOrders(limit: 5));

  Future<_Load<_Transfers>> _loadTransfers() => _guard(() async {
        final PaginatedResult<TransferOrderModel> result =
            await TransferOrderUseCase().getOrders(limit: 3);
        BankAccountsModel? accounts;
        try {
          accounts = await BankAccountUseCase().getBankAccounts();
        } catch (_) {
          // Sans les comptes, la liste s'affiche sans le libellé du compte.
        }
        return _Transfers(result.items, accounts);
      });

  void _open(String menu) => MySinglePage.maybeOf(context)?.openMenu(menu);

  void _openOrder(OrderModel order) {
    if (order.id != null) {
      ScreenOpenRequests.maybeOf(context)
          ?.request(ScreenOpenRequest('order', id: order.id));
    }
    _open('orders');
  }

  String get _today {
    final String date =
        DateFormat('EEEE d MMMM y', 'fr_FR').format(DateTime.now());
    return date.isEmpty ? date : date[0].toUpperCase() + date.substring(1);
  }

  String get _greeting {
    final String name = globalNetworkName.trim();
    if (name.isEmpty || name == 'Chargement...') return 'Bonjour';
    return 'Bonjour $name';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ArcPageHeader(
          eyebrow: _today,
          title: _greeting,
          actions: [
            FilledButton.icon(
              onPressed: () => _open('orders'),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Nouvelle commande'),
            ),
          ],
        ),
        _buildTodo(),
        const SizedBox(height: 28),
        LayoutBuilder(builder: (context, constraints) {
          final Widget orders = _buildOrders();
          final Widget side = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildShortcuts(),
              const SizedBox(height: 20),
              _buildTransfers(),
            ],
          );
          if (constraints.maxWidth < 860) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [orders, const SizedBox(height: 20), side],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: orders),
              const SizedBox(width: 20),
              Expanded(child: side),
            ],
          );
        }),
      ],
    );
  }

  // --- À traiter -----------------------------------------------------------

  Widget _buildTodo() {
    return FutureBuilder<List<_Load<Object?>>>(
      future: _todo,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _section(
            title: 'À traiter',
            child: _cardGrid(List.generate(3, (_) => const _LoadingCard())),
          );
        }
        final List<_Load<Object?>> loads = snapshot.data!;
        final List<Widget> cards = [];
        int count = 0;

        // [build] : la carte et si elle demande une action (compteur), ou
        // `null` quand il n'y a rien à montrer.
        void add(_Load<Object?> load, String label,
            (Widget, bool)? Function(Object? value) build) {
          if (load.failed) {
            cards.add(_ErrorCard(
                label: label,
                onRetry: () => setState(() => _todo = _loadTodo())));
            return;
          }
          final (Widget, bool)? card = build(load.value);
          if (card == null) return;
          cards.add(card.$1);
          if (card.$2) count++;
        }

        add(loads[0], 'Prochain virement', (value) {
          final preview = value as BtoPreviewModel;
          return (_nextTransferCard(preview), preview.totals.requestsToPay > 0);
        });
        add(loads[1], 'Import de commerçants', (value) {
          final MerchantImportBatch? batch = value as MerchantImportBatch?;
          return batch == null ? null : (_importCard(batch), true);
        });
        add(loads[2], 'Écritures comptables', (value) {
          final result = value as PaginatedResult<AccountingEntriesModel>;
          return result.items.isEmpty ? null : (_entriesCard(result), false);
        });

        if (cards.isEmpty) return const SizedBox.shrink();
        return _section(
          title: 'À traiter',
          count: count > 0 ? '$count' : null,
          child: _cardGrid(cards),
        );
      },
    );
  }

  Widget _section(
      {required String title, String? count, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ArcSectionTitle(title, count: count, tone: ArcTone.warning),
        const SizedBox(height: 14),
        child,
      ],
    );
  }

  /// Grille « auto-fit » : colonnes d'au moins 300 px, cartes d'une même
  /// rangée à la même hauteur.
  Widget _cardGrid(List<Widget> cards) {
    const double gap = 20;
    return LayoutBuilder(builder: (context, constraints) {
      final int columns = ((constraints.maxWidth + gap) / (300 + gap))
          .floor()
          .clamp(1, cards.length);
      final List<Widget> rows = [];
      for (int start = 0; start < cards.length; start += columns) {
        final List<Widget> slice =
            cards.sublist(start, (start + columns).clamp(0, cards.length));
        rows.add(IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < columns; i++) ...[
                if (i > 0) const SizedBox(width: gap),
                Expanded(child: i < slice.length ? slice[i] : const SizedBox()),
              ],
            ],
          ),
        ));
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: gap),
            rows[i],
          ],
        ],
      );
    });
  }

  Widget _nextTransferCard(BtoPreviewModel preview) {
    final BtoPreviewTotals totals = preview.totals;
    final bool ready = totals.requestsToPay > 0;
    final String until = formatFrenchDate(preview.periodTo);
    final String detail = ready
        ? [
            plural(totals.requestsToPay, 'demande'),
            plural(totals.merchantsToPay, 'commerçant'),
            if (until.isNotEmpty) "jusqu'au $until",
          ].join(' · ')
        : 'Aucune demande prête à être payée';
    return _TodoCard(
      dark: true,
      label: 'PROCHAIN VIREMENT',
      badge: ready
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                  color: kNavy700, borderRadius: BorderRadius.circular(999)),
              child: Text('prêt',
                  style: ArcText.small(color: kOrange300)
                      .copyWith(fontSize: 11, fontWeight: FontWeight.w600)),
            )
          : null,
      body: [
        Text(formatEuro(totals.amountToTransfer),
            style:
                ArcText.kpi(color: kOrange).copyWith(fontSize: 44, height: 1)),
        const SizedBox(height: 6),
        Text(detail,
            style: ArcText.body(color: kNavy200).copyWith(fontSize: 13)),
        if (totals.requestsExcluded > 0) ...[
          const SizedBox(height: 4),
          Text('${plural(totals.requestsExcluded, 'demande')} hors virement',
              style: ArcText.small(color: kNavy300)),
        ],
      ],
      action: FilledButton.icon(
        onPressed: () => _open('refund'),
        style: FilledButton.styleFrom(
            minimumSize: const Size(0, 40),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            textStyle: ArcText.body()
                .copyWith(fontSize: 13, fontWeight: FontWeight.w600)),
        iconAlignment: IconAlignment.end,
        icon: const Icon(Icons.arrow_forward_rounded, size: 16),
        label: const Text('Préparer le virement'),
      ),
    );
  }

  Widget _importCard(MerchantImportBatch batch) {
    final String created = formatFrenchDate(batch.createdDate);
    return _TodoCard(
      label: 'IMPORT DE COMMERÇANTS',
      badge: ArcPill(batch.statusLabel, tone: ArcTone.warning),
      body: [
        if ((batch.source ?? '').isNotEmpty)
          Text(batch.source!,
              style:
                  ArcText.data(color: kNavy900, fontWeight: FontWeight.w500)),
        if (created.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text('Déposé le $created', style: ArcText.small(color: kText3)),
        ],
        const SizedBox(height: 14),
        Wrap(spacing: 6, runSpacing: 6, children: [
          _Tag(plural(batch.rowsWithErrors, 'anomalie'), ArcTone.danger),
          _Tag('${batch.rowsPending} à relire', ArcTone.info),
          _Tag(plural(batch.rowsValidated, 'validée'), ArcTone.success),
        ]),
      ],
      action:
          _cardButton('Reprendre la relecture', () => _open('merchantImport')),
    );
  }

  Widget _entriesCard(PaginatedResult<AccountingEntriesModel> result) {
    final AccountingEntriesModel last = result.items.first;
    final String created = formatFrenchDate(last.createdDate);
    final int files = result.total > 0 ? result.total : result.items.length;
    return _TodoCard(
      label: 'ÉCRITURES COMPTABLES',
      badge:
          Text(plural(files, 'fichier'), style: ArcText.small(color: kText3)),
      body: [
        Text(
            created.isEmpty
                ? 'Dernier fichier'
                : 'Dernier fichier, généré le $created',
            style: ArcText.body(color: kText2).copyWith(fontSize: 13)),
        if ((last.filename ?? '').isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(last.filename!,
              style:
                  ArcText.data(color: kNavy900, fontWeight: FontWeight.w500)),
        ],
      ],
      action:
          _cardButton('Ouvrir les écritures', () => _open('accountingentries')),
    );
  }

  Widget _cardButton(String label, VoidCallback onPressed) => OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 40),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            textStyle: ArcText.body()
                .copyWith(fontSize: 13, fontWeight: FontWeight.w600)),
        child: Text(label),
      );

  // --- Dernières commandes --------------------------------------------------

  Widget _buildOrders() {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(kRadiusMd),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _panelHeader(
              'Dernières commandes', 'Tout voir', () => _open('orders'),
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 12)),
          const Divider(height: 1, color: kNavy100),
          FutureBuilder<_Load<PaginatedResult<OrderModel>>>(
            future: _orders,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const _PanelLoading();
              final _Load<PaginatedResult<OrderModel>> load = snapshot.data!;
              if (load.failed) {
                return _PanelError(
                    message: 'Impossible de charger les dernières commandes.',
                    onRetry: () => setState(() => _orders = _loadOrders()));
              }
              final List<OrderModel> orders = load.value!.items;
              if (orders.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('Aucune commande pour le moment.',
                      style: ArcText.small(color: kText3)),
                );
              }
              return _ordersTable(orders);
            },
          ),
        ],
      ),
    );
  }

  Widget _ordersTable(List<OrderModel> orders) {
    TextStyle head =
        ArcText.small(color: kText2).copyWith(fontWeight: FontWeight.w600);
    Widget cell(Widget child,
            {EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 12),
            Alignment align = Alignment.centerLeft}) =>
        Padding(padding: padding, child: Align(alignment: align, child: child));

    Widget row(List<Widget> cells,
        {Color? color, VoidCallback? onTap, bool top = false}) {
      final Widget content = Container(
        constraints: BoxConstraints(minHeight: top ? 40 : 58),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color,
          border: top ? null : const Border(top: BorderSide(color: kNavy100)),
        ),
        child: Row(children: [
          Expanded(flex: 4, child: cells[0]),
          Expanded(flex: 3, child: cells[1]),
          Expanded(flex: 3, child: cells[2]),
          Expanded(flex: 3, child: cells[3]),
        ]),
      );
      if (onTap == null) return content;
      return Material(
        color: Colors.transparent,
        child: InkWell(onTap: onTap, hoverColor: kNavy50, child: content),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row(top: true, color: kSurface2, [
          cell(Text('Commande', style: head),
              padding: const EdgeInsets.only(left: 20, right: 12)),
          cell(Text('Offert par', style: head)),
          cell(Text('Montant', style: head), align: Alignment.centerRight),
          cell(Text('Paiement', style: head),
              padding: const EdgeInsets.only(left: 12, right: 20)),
        ]),
        for (final OrderModel order in orders)
          row(onTap: () => _openOrder(order), [
            cell(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(order.orderNumber ?? '',
                      style: ArcText.dataSmall(color: kNavy900)
                          .copyWith(fontSize: 12)),
                  if ((order.giftReason ?? '').isNotEmpty)
                    Text(order.giftReason!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ArcText.small(color: kText3)),
                ],
              ),
              padding: const EdgeInsets.only(left: 20, right: 12),
            ),
            cell(Text(order.giftFrom ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ArcText.body().copyWith(fontSize: 13))),
            cell(
                Text(formatEuro(order.totalAmount),
                    style: ArcText.data(fontWeight: FontWeight.w500)),
                align: Alignment.centerRight),
            cell(_paymentPill(order),
                padding: const EdgeInsets.only(left: 12, right: 20)),
          ]),
      ],
    );
  }

  /// Statut de paiement : payée (montant payé égal au total), non payée, ou
  /// l'écart entre le payé et le total.
  Widget _paymentPill(OrderModel order) {
    final num paid = order.paid ?? 0;
    final num total = order.totalAmount ?? 0;
    if (paid == total) {
      return const ArcPill('Payée',
          tone: ArcTone.success, icon: Icons.check_circle_outline_rounded);
    }
    if (paid == 0) {
      return const ArcPill('Non payée',
          tone: ArcTone.danger, icon: Icons.error_outline_rounded);
    }
    final num gap = paid - total;
    return ArcPill('Écart ${gap > 0 ? '+' : '−'}${formatEuro(gap.abs())}',
        tone: ArcTone.warning, icon: Icons.warning_amber_rounded);
  }

  // --- Raccourcis et derniers virements --------------------------------------

  Widget _buildShortcuts() {
    return ArcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Raccourcis', style: ArcText.cardTitle().copyWith(fontSize: 16)),
          const SizedBox(height: 12),
          _Shortcut(
              icon: Icons.person_add_alt_rounded,
              label: 'Ajouter un client',
              onTap: () => _open('customer')),
          const SizedBox(height: 10),
          _Shortcut(
              icon: Icons.add_business_outlined,
              label: 'Ajouter un partenaire',
              onTap: () => _open('partner')),
          const SizedBox(height: 10),
          _Shortcut(
              icon: Icons.upload_file_outlined,
              label: 'Importer des commerçants',
              onTap: () => _open('merchantImport')),
          const SizedBox(height: 10),
          _Shortcut(
              icon: Icons.bar_chart_rounded,
              label: 'Exporter une statistique',
              onTap: () => _open('stats')),
        ],
      ),
    );
  }

  Widget _buildTransfers() {
    return FutureBuilder<_Load<_Transfers>>(
      future: _transfers,
      builder: (context, snapshot) {
        final _Load<_Transfers>? load = snapshot.data;
        // Pas encore de virement : la carte est omise.
        if (load != null && !load.failed && load.value!.items.isEmpty) {
          return const SizedBox.shrink();
        }
        final Widget body;
        if (load == null) {
          body = const _PanelLoading(height: 100);
        } else if (load.failed) {
          body = _PanelError(
              padding: EdgeInsets.zero,
              message: 'Impossible de charger les derniers virements.',
              onRetry: () => setState(() => _transfers = _loadTransfers()));
        } else {
          final List<TransferOrderModel> items = load.value!.items;
          final BankAccountsModel? accounts = load.value!.bankAccounts;
          body = Column(children: [
            for (int i = 0; i < items.length; i++)
              _transferRow(items[i], accounts, last: i == items.length - 1),
          ]);
        }
        return ArcCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _panelHeader('Derniers virements', 'Historique',
                  () => _open('bankTransfertOrder')),
              const SizedBox(height: 6),
              body,
            ],
          ),
        );
      },
    );
  }

  Widget _transferRow(TransferOrderModel transfer, BankAccountsModel? accounts,
      {required bool last}) {
    final DateTime? date = DateTime.tryParse(transfer.createdDate ?? '');
    final String label = [
      if (date != null) DateFormat('d MMM', 'fr_FR').format(date),
      if (accounts?.hasSeveralAccounts ?? false)
        accounts!.labelForCode(transfer.bankAccountCode),
    ].where((part) => part.isNotEmpty).join(' · ');
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: last ? null : const Border(bottom: BorderSide(color: kNavy100)),
      ),
      child: Row(children: [
        Expanded(
          child: Text(label.isEmpty ? (transfer.filename ?? '') : label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ArcText.body(color: kText2).copyWith(fontSize: 13)),
        ),
        const SizedBox(width: 8),
        Text(formatEuro(transfer.refundedAmount),
            style: ArcText.data(fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _panelHeader(String title, String link, VoidCallback onLink,
      {EdgeInsets padding = EdgeInsets.zero}) {
    return Padding(
      padding: padding,
      child: Row(children: [
        Expanded(
            child:
                Text(title, style: ArcText.cardTitle().copyWith(fontSize: 16))),
        TextButton(
          onPressed: onLink,
          style: TextButton.styleFrom(
              minimumSize: const Size(0, 32),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              textStyle: ArcText.body()
                  .copyWith(fontSize: 13, fontWeight: FontWeight.w600)),
          child: Text(link),
        ),
      ]),
    );
  }
}

/// Carte « À traiter » : libellé en capitales, pastille, contenu et action
/// en bas. [dark] : la carte mise en avant (navy, motif des arcs).
class _TodoCard extends StatelessWidget {
  final String label;
  final Widget? badge;
  final List<Widget> body;
  final Widget action;
  final bool dark;
  const _TodoCard({
    required this.label,
    this.badge,
    required this.body,
    required this.action,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 236),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: dark ? kNavy900 : kSurface,
        borderRadius: BorderRadius.circular(kRadiusLg),
        border: dark ? null : Border.all(color: kBorder),
      ),
      child: Stack(children: [
        if (dark)
          const Positioned(
            right: -40,
            bottom: -50,
            child: Opacity(
              opacity: 0.16,
              child: ArcPicto(width: 220, ink: Colors.white, accent: kOrange),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Text(label,
                      style: ArcText.label(color: dark ? kNavy300 : kText2)
                          .copyWith(letterSpacing: 0.7)),
                ),
                if (badge != null) badge!,
              ]),
              const SizedBox(height: 18),
              ...body,
              const SizedBox(height: 18),
              const Spacer(),
              action,
            ],
          ),
        ),
      ]),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 236,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(kRadiusLg),
        border: Border.all(color: kBorder),
      ),
      child: const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2.5)),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String label;
  final VoidCallback onRetry;
  const _ErrorCard({required this.label, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 236),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(kRadiusLg),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: ArcText.label(color: kText2).copyWith(letterSpacing: 0.7)),
          const SizedBox(height: 18),
          const ArcPill('Chargement impossible',
              tone: ArcTone.danger, icon: Icons.error_outline_rounded),
          const SizedBox(height: 8),
          Text('Les données de ce bloc n\'ont pas pu être récupérées.',
              style: ArcText.small(color: kText3)),
          const SizedBox(height: 18),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}

class _PanelLoading extends StatelessWidget {
  final double height;
  const _PanelLoading({this.height = 160});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: const Center(
          child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5))),
    );
  }
}

class _PanelError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final EdgeInsets padding;
  const _PanelError(
      {required this.message,
      required this.onRetry,
      this.padding = const EdgeInsets.all(20)});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(message, style: ArcText.small(color: kDangerText)),
          TextButton.icon(
            onPressed: onRetry,
            style: TextButton.styleFrom(minimumSize: const Size(0, 32)),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}

/// Petite étiquette chiffrée (anomalies, à relire, validées).
class _Tag extends StatelessWidget {
  final String label;
  final ArcTone tone;
  const _Tag(this.label, this.tone);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
          color: tone.background,
          borderRadius: BorderRadius.circular(kRadiusXs)),
      child: Text(label,
          style: ArcText.dataSmall(color: tone.text).copyWith(fontSize: 12)),
    );
  }
}

class _Shortcut extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _Shortcut(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kNavy50,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        hoverColor: kNavy100,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                  color: kSurface, borderRadius: BorderRadius.circular(9)),
              child: Icon(icon, size: 18, color: kNavy600),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: ArcText.body(color: kNavy900)
                      .copyWith(fontWeight: FontWeight.w500)),
            ),
          ]),
        ),
      ),
    );
  }
}
