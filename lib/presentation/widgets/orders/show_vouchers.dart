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
import 'package:back_office_tribuneo_v2/presentation/widgets/date_formater.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/orders/order_expiry_date.dart';

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
    final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Désactiver un bon'),
            content: Text(
                'Êtes-vous sûr de vouloir désactiver le bon n°${voucher.id} de ${(voucher.amount ?? 0).toStringAsFixed(2)} € ?'),
            actions: <Widget>[
              TextButton(
                  child: const Text('Annuler'),
                  onPressed: () => Navigator.of(context).pop(false)),
              TextButton(
                  child: const Text(
                    'Désactiver',
                    style: TextStyle(color: kRed, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => Navigator.of(context).pop(true)),
            ],
          );
        });

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

  String _formatDate(String? date) {
    if (date == null || date.trim().isEmpty) return '-';
    return DateFormater().modifyDate(date);
  }

  DataCell _centeredCell(String text) {
    return DataCell(
        Center(child: SelectableText(text, textAlign: TextAlign.center)));
  }

  DataRow _buildRow(OrderVoucherModel voucher, int rowIndex) {
    final bool isEvenRow = rowIndex % 2 == 0;
    final bool canDisable = !voucher.hasUser && !voucher.isDeleted;
    final bool canUpdateExpiry = !voucher.isDeleted;
    final bool canResendMail = !voucher.isDeleted &&
        voucher.isDonation != 1 &&
        (voucher.email?.trim().isNotEmpty ?? false);

    return DataRow(
      color: isEvenRow
          ? WidgetStateProperty.all(kWhite)
          : WidgetStateProperty.all(kLBlue.withValues(alpha: 0.10)),
      cells: [
        _centeredCell('${networkId}' +
            '-' +
            '${voucher.id?.toString()}' +
            '-' +
            '${widget.order.id?.toString()}'),
        _centeredCell('${(voucher.amount ?? 0).toStringAsFixed(2)} €'),
        _centeredCell('${(voucher.remainingAmount ?? 0).toStringAsFixed(2)} €'),
        _centeredCell(voucher.isDonation == 1 ? 'Oui' : 'Non'),
        _centeredCell(voucher.name?.trim() ?? ''),
        _centeredCell(voucher.email?.trim() ?? ''),
        _centeredCell(voucher.mobile?.trim() ?? ''),
        _centeredCell(_formatDate(voucher.expiryDate)),
        _centeredCell(_formatDate(voucher.deletedDate)),
        DataCell(
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Tooltip(
                  message: canDisable
                      ? 'Désactiver le bon'
                      : voucher.isDeleted
                          ? 'Bon déjà désactivé'
                          : 'Bon associé à un utilisateur, désactivation impossible',
                  child: IconButton(
                    icon: Icon(Icons.block,
                        color: canDisable ? kRed : Colors.grey),
                    onPressed:
                        canDisable ? () => _disableVoucher(voucher) : null,
                  ),
                ),
                Tooltip(
                  message: canUpdateExpiry
                      ? 'Modifier la date d\'expiration'
                      : 'Bon déjà désactivé',
                  child: IconButton(
                    icon: Icon(Icons.edit_calendar,
                        color: canUpdateExpiry ? kBlue : Colors.grey),
                    onPressed: canUpdateExpiry
                        ? () => _updateExpiryDate(voucher)
                        : null,
                  ),
                ),
                if (_resendingVoucher == voucher.id)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: kBlue)),
                  )
                else
                  Tooltip(
                    message: canResendMail
                        ? "Renvoyer l'e-mail"
                        : 'Aucune adresse e-mail pour ce bon',
                    child: IconButton(
                      icon: Icon(Icons.forward_to_inbox,
                          color: canResendMail ? kBlue : Colors.grey),
                      onPressed: canResendMail && _resendingVoucher == null
                          ? () => _resendGiftMail(voucher)
                          : null,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  DataColumn2 _column(String label, ColumnSize size) {
    return DataColumn2(
      size: size,
      label: Expanded(
          child: Center(child: Text(label, textAlign: TextAlign.center))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: SelectableText(
          'Gestion des bons - Commande ${widget.order.orderNumber ?? ''}'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.85,
        height: MediaQuery.of(context).size.height * 0.7,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: kBlue))
            : _vouchers.isEmpty
                ? const Center(
                    child: Text('Aucun bon associé à cette commande.'))
                : Theme(
                    data: Theme.of(context).copyWith(
                      dataTableTheme: DataTableThemeData(
                        headingRowColor: WidgetStateProperty.all(kBlue),
                        headingTextStyle: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: kWhite,
                        ),
                        dataTextStyle: GoogleFonts.poppins(
                          fontSize: 13,
                          color: kBlueEnd,
                        ),
                        dividerThickness: 0.6,
                        dataRowMinHeight: 50,
                        dataRowMaxHeight: 56,
                        headingRowHeight: 54,
                      ),
                    ),
                    child: DataTable2(
                      columnSpacing: 16,
                      horizontalMargin: 10,
                      minWidth: 1200,
                      showCheckboxColumn: false,
                      columns: [
                        _column('ID', ColumnSize.S),
                        _column('Montant', ColumnSize.S),
                        _column('Montant restant', ColumnSize.S),
                        _column('Donation', ColumnSize.S),
                        _column('Nom', ColumnSize.M),
                        _column('Email', ColumnSize.L),
                        _column('Téléphone', ColumnSize.M),
                        _column('Expiration', ColumnSize.M),
                        _column('Suppression', ColumnSize.M),
                        _column('Action', ColumnSize.M),
                      ],
                      rows: [
                        for (int i = 0; i < _vouchers.length; i++)
                          _buildRow(_vouchers[i], i),
                      ],
                    ),
                  ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(_hasModifiedData),
            child: const Text('Fermer')),
      ],
    );
  }
}
