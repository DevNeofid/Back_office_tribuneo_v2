import 'package:back_office_tribuneo_v2/data/local/storage_service.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:back_office_tribuneo_v2/domain/errors/api_exception.dart';
import 'package:back_office_tribuneo_v2/domain/models/order_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/order_update_results_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/order_voucher_model.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/orders_usecase.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/_global.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/formatters.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/arc/arc.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/orders/order_expiry_date.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/orders/order_sheet.dart';

enum _VoucherAction { resendMail, updateExpiry, disable }

class ShowVouchers extends StatefulWidget {
  final OrderModel order;

  const ShowVouchers({Key? key, required this.order}) : super(key: key);

  @override
  ShowVouchersState createState() => ShowVouchersState();
}

class ShowVouchersState extends State<ShowVouchers> {
  final OrderUseCase _orderUseCase = OrderUseCase();
  final StorageService _storageService = StorageService();
  List<OrderVoucherModel> _vouchers = [];
  bool _isLoading = true;
  bool _hasModifiedData = false;
  int? _resendingVoucher;
  String? networkId;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    networkId = await _storageService.readSecureData('id_network');
    if (!mounted) return;
    await _refreshVouchers();
  }

  Future<void> _refreshVouchers() async {
    setState(() => _isLoading = true);
    final List<OrderVoucherModel> response =
        await _orderUseCase.getOrderVouchers(widget.order.id!);
    if (!mounted) return;
    setState(() {
      _vouchers = response;
      _isLoading = false;
    });
  }

  Future<void> _disableVoucher(OrderVoucherModel voucher) async {
    final bool confirmed = await showArcConfirm(
      context,
      title: 'Désactiver un bon',
      message: 'Êtes-vous sûr de vouloir désactiver le bon n°${voucher.id} de '
          '${(voucher.amount ?? 0).toStringAsFixed(2)} € ? Il ne pourra plus '
          'être utilisé.',
      confirmLabel: 'Désactiver',
      danger: true,
      icon: Icons.block_rounded,
    );

    if (confirmed != true) return;

    try {
      await _orderUseCase.disableVoucher(voucher.id!);
      _hasModifiedData = true;
      await _refreshVouchers();
      snackbarKey.currentState?.showSnackBar(const SnackBar(
          content: Text('Bon désactivé avec succès.'),
          backgroundColor: kGreen));
    } on ApiException catch (e) {
      snackbarKey.currentState?.showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: kRed));
    } catch (_) {
      snackbarKey.currentState?.showSnackBar(const SnackBar(
          content: Text('Erreur lors de la désactivation du bon.'),
          backgroundColor: kRed));
    }
  }

  Future<void> _updateExpiryDate(OrderVoucherModel voucher) async {
    // Minimum demain ; prolonger un bon déjà expiré est possible.
    final DateTime? selected = await pickExpiryDate(context,
        current: DateTime.tryParse(voucher.expiryDate ?? ''));

    if (selected == null) return;

    try {
      // L'API attend 'yyyy-MM-dd' et ajoute elle-même l'heure ' 23:59:59'.
      final VoucherExpiryUpdateResult result =
          await _orderUseCase.updateVoucherExpiryDate(
              voucher.id!, DateFormat('yyyy-MM-dd').format(selected));
      _hasModifiedData = true;
      await _refreshVouchers();
      final VoucherWalletUpdate? wallet = result.wallet;
      snackbarKey.currentState?.showSnackBar(SnackBar(
          content: Text(
              'Date d\'expiration mise à jour au ${_getDisplayableDate(selected)}.'
              '${wallet == null ? '' : ' Le solde du consommateur a été mis à jour '
                  '(${formatEuro(wallet.oldAmount)} → ${formatEuro(wallet.newAmount)}).'}'),
          backgroundColor: kGreen,
          duration: Duration(seconds: wallet == null ? 4 : 8)));
    } on ApiException catch (e) {
      snackbarKey.currentState?.showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: kRed));
    } catch (_) {
      snackbarKey.currentState?.showSnackBar(const SnackBar(
          content:
              Text('Erreur lors de la mise à jour de la date d\'expiration.'),
          backgroundColor: kRed));
    }
  }

  /// Renvoie le mail « chèque cadeau ». L'API refuse (`VOUCHER_ASSIGNED`) si le
  /// bon est déjà attribué.
  Future<void> _resendGiftMail(OrderVoucherModel voucher) async {
    if (_resendingVoucher != null) return;
    setState(() => _resendingVoucher = voucher.id);
    try {
      final String? email = await _orderUseCase.resendGiftMail(voucher.id!);
      snackbarKey.currentState?.showSnackBar(SnackBar(
          content: Text('E-mail renvoyé à ${email ?? voucher.email ?? ''}.'),
          backgroundColor: kGreen));
    } on ApiException catch (e) {
      snackbarKey.currentState?.showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: kRed));
    } finally {
      if (mounted) setState(() => _resendingVoucher = null);
    }
  }

  String _getDisplayableDate(DateTime date) {
    String day = date.day > 9 ? date.day.toString() : "0${date.day.toString()}";
    String month =
        date.month > 9 ? date.month.toString() : "0${date.month.toString()}";
    return "$day/$month/${date.year}";
  }

  // ---------------------------------------------------------------------------
  // Affichage
  // ---------------------------------------------------------------------------

  /// Identifiant du bon tel qu'imprimé : réseau-bon-commande.
  String _voucherCode(OrderVoucherModel voucher) =>
      '$networkId-${voucher.id}-${widget.order.id}';

  /// « C202610121 · test multi-compte · Fête des mères », sans les parties
  /// absentes.
  String get _eyebrow => [
        widget.order.orderNumber,
        widget.order.giftFrom,
        widget.order.giftReason,
      ]
          .map((part) => part?.trim() ?? '')
          .where((part) => part.isNotEmpty)
          .join(' · ');

  void _close() => Navigator.of(context).pop(_hasModifiedData);

  Widget _status(OrderVoucherModel voucher) {
    if (voucher.isDeleted) {
      final String deleted = formatFrenchDate(voucher.deletedDate);
      final Widget pill = const ArcPill('Désactivé', tone: ArcTone.neutral);
      return deleted.isEmpty
          ? pill
          : Tooltip(message: 'Désactivé le $deleted', child: pill);
    }
    if (voucher.hasUser) {
      return const ArcPill('Associé à un utilisateur', tone: ArcTone.info);
    }
    return const ArcPill('Actif', tone: ArcTone.success);
  }

  DataRow _buildRow(OrderVoucherModel voucher) {
    final bool canDisable = !voucher.hasUser && !voucher.isDeleted;
    final bool canUpdateExpiry = !voucher.isDeleted;
    final bool canResendMail = !voucher.isDeleted &&
        voucher.isDonation != 1 &&
        (voucher.email?.trim().isNotEmpty ?? false);

    final String name = voucher.name?.trim() ?? '';
    final String email = voucher.email?.trim() ?? '';
    final String mobile = voucher.mobile?.trim() ?? '';

    return DataRow(
      cells: [
        DataCell(SelectableText(_voucherCode(voucher),
            style: ArcText.dataSmall(color: kNavy900))),
        DataCell(Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (name.isNotEmpty)
              SelectableText(name,
                  maxLines: 1,
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w500, color: kInk)),
            SelectableText(
                email.isNotEmpty ? email : 'Aucune adresse e-mail pour ce bon',
                maxLines: 1,
                style: ArcText.small(color: kText3)),
          ],
        )),
        DataCell(SelectableText(mobile,
            style: ArcText.data(color: kText2).copyWith(fontSize: 12))),
        DataCell(Text(formatEuro(voucher.amount),
            style: ArcText.data(fontWeight: FontWeight.w500))),
        DataCell(Text(formatEuro(voucher.remainingAmount),
            style: ArcText.data(color: kText2))),
        DataCell(Text(formatFrenchDate(voucher.expiryDate),
            style: ArcText.body(color: kText2).copyWith(fontSize: 13))),
        DataCell(Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            _status(voucher),
            if (voucher.isDonation == 1)
              const ArcPill('Don', tone: ArcTone.warning, square: true),
          ],
        )),
        DataCell(Align(
          alignment: Alignment.centerRight,
          child: _resendingVoucher == voucher.id
              ? const Padding(
                  padding: EdgeInsets.all(8),
                  child: SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : _actionsMenu(voucher,
                  canDisable: canDisable,
                  canUpdateExpiry: canUpdateExpiry,
                  canResendMail: canResendMail),
        )),
      ],
    );
  }

  PopupMenuItem<_VoucherAction> _menuItem(
    _VoucherAction value, {
    required IconData icon,
    required String label,
    required bool enabled,
    String? disabledReason,
    bool danger = false,
  }) {
    final Color color = !enabled
        ? kNavy300
        : danger
            ? kDangerText
            : kInk;
    return PopupMenuItem<_VoucherAction>(
      value: value,
      enabled: enabled,
      child: Row(
        children: [
          Icon(icon,
              size: 16,
              color: !enabled
                  ? kNavy300
                  : danger
                      ? kDangerText
                      : kNavy600),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: danger ? FontWeight.w600 : FontWeight.w400,
                        color: color)),
                if (!enabled && disabledReason != null)
                  Text(disabledReason, style: ArcText.small(color: kText3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionsMenu(OrderVoucherModel voucher,
      {required bool canDisable,
      required bool canUpdateExpiry,
      required bool canResendMail}) {
    return PopupMenuButton<_VoucherAction>(
      tooltip: 'Actions du bon',
      icon: const Icon(Icons.more_horiz_rounded, size: 18),
      constraints: const BoxConstraints(minWidth: 250, maxWidth: 300),
      onSelected: (action) {
        switch (action) {
          case _VoucherAction.resendMail:
            _resendGiftMail(voucher);
          case _VoucherAction.updateExpiry:
            _updateExpiryDate(voucher);
          case _VoucherAction.disable:
            _disableVoucher(voucher);
        }
      },
      itemBuilder: (context) => [
        _menuItem(
          _VoucherAction.resendMail,
          icon: Icons.mail_outline_rounded,
          label: "Renvoyer l'e-mail",
          enabled: canResendMail && _resendingVoucher == null,
          disabledReason: canResendMail ? null : 'Aucune adresse e-mail pour ce bon',
        ),
        _menuItem(
          _VoucherAction.updateExpiry,
          icon: Icons.calendar_month_outlined,
          label: 'Modifier la date d\'expiration',
          enabled: canUpdateExpiry,
          disabledReason: 'Bon déjà désactivé',
        ),
        const PopupMenuDivider(),
        _menuItem(
          _VoucherAction.disable,
          icon: Icons.block_rounded,
          label: 'Désactiver le bon',
          enabled: canDisable,
          danger: true,
          disabledReason: voucher.isDeleted
              ? 'Bon déjà désactivé'
              : 'Bon associé à un utilisateur, désactivation impossible',
        ),
      ],
    );
  }

  DataColumn2 _column(String label,
      {ColumnSize size = ColumnSize.M,
      double? fixedWidth,
      bool numeric = false}) {
    return DataColumn2(
      size: size,
      fixedWidth: fixedWidth,
      numeric: numeric,
      label: Text(label),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_vouchers.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(28),
        child: Align(
          alignment: Alignment.topCenter,
          child: ArcEmptyState(
            icon: Icons.confirmation_number_outlined,
            title: 'Aucun bon associé à cette commande.',
          ),
        ),
      );
    }
    return DataTable2(
      columnSpacing: 16,
      horizontalMargin: 28,
      minWidth: 980,
      headingRowHeight: 44,
      dataRowHeight: 60,
      showCheckboxColumn: false,
      columns: [
        _column('Bon', fixedWidth: 120),
        _column('Bénéficiaire', size: ColumnSize.L),
        _column('Téléphone', fixedWidth: 120),
        _column('Montant', fixedWidth: 96, numeric: true),
        _column('Restant', fixedWidth: 96, numeric: true),
        _column('Expiration', fixedWidth: 100),
        _column('État', fixedWidth: 190),
        _column('Action', fixedWidth: 64, numeric: true),
      ],
      rows: [for (final voucher in _vouchers) _buildRow(voucher)],
    );
  }

  @override
  Widget build(BuildContext context) {
    final String eyebrow = _eyebrow;
    final num total =
        _vouchers.fold<num>(0, (sum, voucher) => sum + (voucher.amount ?? 0));
    // Sans bouton « Fermer » en pied : un clic hors du panneau rend aussi
    // l'information « bons modifiés » pour recharger la liste.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: OrderSheet(
        semanticLabel: 'Bons de la commande',
        width: 900,
        scrollBody: false,
        header: OrderSheetHeader(
          eyebrow:
              eyebrow.isEmpty ? null : OrderSheetEyebrow(eyebrow, data: true),
          title: 'Bons de la commande',
          trailing: [
            if (!_isLoading && _vouchers.isNotEmpty)
              ArcPill(
                  '${plural(_vouchers.length, 'bon')} · ${formatEuro(total)}',
                  tone: ArcTone.info),
            OrderSheetCloseButton(onPressed: _close),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }
}
