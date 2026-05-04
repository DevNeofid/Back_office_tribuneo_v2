import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:back_office_tribuneo_v2/config/size_config.dart';
import 'package:back_office_tribuneo_v2/domain/models/network_amount_model.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/stats_usecase.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';

class StatsContentView extends StatefulWidget {
  const StatsContentView({super.key});

  @override
  StatsContentViewState createState() => StatsContentViewState();
}

class StatsContentViewState extends State<StatsContentView> {
  final StatsUseCase _statsUseCase = StatsUseCase();
  final DateFormat dateFormat = DateFormat('dd/MM/yyyy');
  int _selectedButtonIndex = 0;
  final bool _isLoading = false;
  DateTime _selectedStartDate = DateTime(2023, 1, 1);
  DateTime _selectedEndDate = DateTime.now();

  @override
  void initState() {
    super.initState();
  }

  Widget _buildStyledTable(BuildContext context, Widget tableWidget,
      {int rowCount = 10}) {
    final double headerHeight = 54.0;
    final double rowHeight = 56.0;
    final double tableHeight = headerHeight + (rowCount * rowHeight);

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.70,
        ),
        child: SizedBox(
          height: tableHeight,
          child: Container(
            decoration: BoxDecoration(
              color: kWhite,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: kBlue.withValues(alpha: 0.07),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Theme(
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
                    dataRowMaxHeight: rowHeight,
                    headingRowHeight: headerHeight,
                  ),
                ),
                child: tableWidget,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return SizedBox(
      height: SizeConfig.screenHeight,
      child: Scaffold(
        body: Column(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 16.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: kWhite,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: kBlue),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _selectedButtonIndex,
                      icon: const Icon(Icons.arrow_drop_down, color: kBlue),
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: kBlueEnd,
                          fontWeight: FontWeight.w500),
                      onChanged: (int? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedButtonIndex = newValue;
                          });
                        }
                      },
                      items: const [
                        DropdownMenuItem(
                            value: 0, child: Text('Comptes utilisateurs')),
                        DropdownMenuItem(
                            value: 1,
                            child: Text('Montant total des partenaires')),
                        DropdownMenuItem(
                            value: 2, child: Text('Montant total du réseau')),
                        DropdownMenuItem(
                            value: 3,
                            child: Text('Montant total des bons par clients')),
                        DropdownMenuItem(
                            value: 4,
                            child: Text('Partenaires jamais connectés')),
                        DropdownMenuItem(
                            value: 5,
                            child:
                                Text('Somme des coupons expirés par client')),
                        DropdownMenuItem(
                            value: 6, child: Text('Partenaires sans activité')),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (_selectedButtonIndex == 1 ||
                _selectedButtonIndex == 2 ||
                _selectedButtonIndex == 5)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 300,
                      child: ListTile(
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                  'Date de debut: ${dateFormat.format(_selectedStartDate)}'),
                            ),
                            const Icon(Icons.calendar_today),
                          ],
                        ),
                        onTap: () async {
                          DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedStartDate,
                            firstDate: DateTime(2010),
                            lastDate: DateTime(3000),
                            locale: const Locale('fr', 'FR'),
                            fieldHintText: 'Jour/Mois/Annee',
                          );
                          if (picked != null) {
                            setState(() {
                              _selectedStartDate = picked;
                              if (_selectedStartDate
                                  .isAfter(_selectedEndDate)) {
                                _selectedEndDate = _selectedStartDate;
                              }
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 300,
                      child: ListTile(
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                  'Date de fin: ${dateFormat.format(_selectedEndDate)}'),
                            ),
                            const Icon(Icons.calendar_today),
                          ],
                        ),
                        onTap: () async {
                          DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedEndDate,
                            firstDate: DateTime(2010),
                            lastDate: DateTime(3000),
                            locale: const Locale('fr', 'FR'),
                            fieldHintText: 'Jour/Mois/Annee',
                          );
                          if (picked != null) {
                            setState(() {
                              _selectedEndDate = picked;
                              if (_selectedEndDate
                                  .isBefore(_selectedStartDate)) {
                                _selectedStartDate = _selectedEndDate;
                              }
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: kBlue))
                  : _buildSelectedContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedContent() {
    switch (_selectedButtonIndex) {
      case 0:
        return _buildUsersContent();
      case 1:
        return _buildPartnerTotalBalanceContent();
      case 2:
        return _buildNetworkTotalAmount();
      case 3:
        return _buildVoucherTotalBalancePerCustomer();
      case 4:
        return _buildPartnerDigitalNeverOpenSession();
      case 5:
        return _buildSumExpiredVouchersConsumer();
      case 6:
        return _buildDigitalPartnerNoActivity();
      default:
        return Container();
    }
  }

  Widget _buildPartnerTotalBalanceContent() {
    final bool isCompact = MediaQuery.of(context).size.width < 1500;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: _buildStyledTable(
        context,
        AsyncPaginatedDataTable2(
          wrapInCard: false,
          source: PartnerTotalDataSource(
            _statsUseCase,
            _selectedStartDate,
            _selectedEndDate,
          ),
          columnSpacing: isCompact ? 16 : 22,
          horizontalMargin: isCompact ? 10 : 14,
          minWidth: isCompact ? 600 : 800,
          rowsPerPage: 10,
          columns: const [
            DataColumn(label: Center(child: Text('Nom'))),
            DataColumn(label: Center(child: Text('Montant total'))),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: _buildStyledTable(
        context,
        AsyncPaginatedDataTable2(
          wrapInCard: false,
          source: UsersDataSource(_statsUseCase),
          rowsPerPage: 10,
          columns: const [
            DataColumn(label: Center(child: Text('Téléphone'))),
            DataColumn(label: Center(child: Text('Initiales'))),
            DataColumn(label: Center(child: Text('Montant coupon (€)'))),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkTotalAmount() {
    return FutureBuilder<List<NetworkTotalAmountModel>>(
      future: StatsUseCase()
          .getNetworkTotalAmounts(_selectedStartDate, _selectedEndDate),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          final data = snapshot.data ?? [];
          return Padding(
            padding: const EdgeInsets.all(16),
            child: _buildStyledTable(
              context,
              DataTable2(
                columns: const [
                  DataColumn(label: Center(child: Text('Frais de gestion'))),
                  DataColumn(label: Center(child: Text('Total injecté'))),
                  DataColumn(label: Center(child: Text('Gain expiré total'))),
                ],
                rows: data.map((item) {
                  final double expiredGain =
                      double.tryParse(item.expiredGainTotal) ?? 0.0;
                  return DataRow(
                    cells: [
                      DataCell(Center(
                          child: Text(
                              '${item.managementFees.toStringAsFixed(2)} €'))),
                      DataCell(
                          Center(child: Text('${item.injectedTotalAmount} €'))),
                      DataCell(Center(
                          child: Text('${expiredGain.toStringAsFixed(2)} €'))),
                    ],
                  );
                }).toList(),
              ),
              rowCount: data.isEmpty ? 1 : data.length,
            ),
          );
        }
      },
    );
  }

  Widget _buildVoucherTotalBalancePerCustomer() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: _buildStyledTable(
        context,
        AsyncPaginatedDataTable2(
          wrapInCard: false,
          source: VoucherTotalBalancePerCustomerDataSource(_statsUseCase),
          rowsPerPage: 10,
          columns: const [
            DataColumn(label: Center(child: Text('Nom'))),
            DataColumn(label: Center(child: Text('Montant'))),
            DataColumn(label: Center(child: Text('Date d\'expiration'))),
          ],
        ),
      ),
    );
  }

  Widget _buildPartnerDigitalNeverOpenSession() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: _buildStyledTable(
        context,
        AsyncPaginatedDataTable2(
          wrapInCard: false,
          source: PartnerDigitalNeverOpenSessionDataSource(_statsUseCase),
          rowsPerPage: 10,
          columns: const [
            DataColumn(label: Center(child: Text('Nom'))),
            DataColumn(label: Center(child: Text('Email'))),
            DataColumn2(
                size: ColumnSize.S, label: Center(child: Text('Téléphone'))),
            DataColumn2(
                size: ColumnSize.S, label: Center(child: Text('Avec QR Code'))),
          ],
        ),
      ),
    );
  }

  Widget _buildSumExpiredVouchersConsumer() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: _buildStyledTable(
        context,
        AsyncPaginatedDataTable2(
          wrapInCard: false,
          source: SumExpiredVouchersConsumerDataSource(
            _statsUseCase,
            _selectedStartDate,
            _selectedEndDate,
          ),
          rowsPerPage: 10,
          columns: const [
            DataColumn(label: Center(child: Text('Nom'))),
            DataColumn(label: Center(child: Text('Nombre de coupons'))),
            DataColumn(label: Center(child: Text('Somme non dépensée'))),
          ],
        ),
      ),
    );
  }

  Widget _buildDigitalPartnerNoActivity() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: _buildStyledTable(
        context,
        AsyncPaginatedDataTable2(
          wrapInCard: false,
          source: DigitalPartnerNoActivityDataSource(_statsUseCase),
          rowsPerPage: 10,
          columns: const [
            DataColumn(label: Center(child: Text('Nom'))),
            DataColumn(label: Center(child: Text('ID'))),
            DataColumn(label: Center(child: Text('Email'))),
            DataColumn(label: Center(child: Text('Téléphone'))),
          ],
        ),
      ),
    );
  }
}

class PartnerTotalDataSource extends AsyncDataTableSource {
  final StatsUseCase _statsUseCase;
  final DateTime? _dateFrom;
  final DateTime? _dateTo;
  int _lastKnownTotal = 0;

  PartnerTotalDataSource(this._statsUseCase, this._dateFrom, this._dateTo);

  @override
  Future<AsyncRowsResponse> getRows(int startIndex, int limit) async {
    final int apiOffset = startIndex;
    final paginated = await _statsUseCase.getPartnerTotalBalancesPaginated(
      _dateFrom,
      _dateTo,
      limit: limit,
      offset: apiOffset,
    );

    final data = paginated.items;
    final List<DataRow> rows = [];
    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final int rowIndex = startIndex + i;
      rows.add(DataRow(
        color: rowIndex % 2 == 0
            ? WidgetStateProperty.all(kWhite)
            : WidgetStateProperty.all(kLBlue.withValues(alpha: 0.10)),
        cells: [
          DataCell(Center(child: Text(item.name ?? ''))),
          DataCell(Center(
              child: Text(item.totalAmount?.toStringAsFixed(2) ?? '0.00'))),
        ],
      ));
    }

    if (paginated.total > 0) {
      _lastKnownTotal = paginated.total;
    } else {
      _lastKnownTotal = startIndex + data.length;
      if (data.length == limit) {
        _lastKnownTotal += 1;
      }
    }

    return AsyncRowsResponse(_lastKnownTotal, rows);
  }
}

class UsersDataSource extends AsyncDataTableSource {
  final StatsUseCase _statsUseCase;
  int _lastKnownTotal = 0;

  UsersDataSource(this._statsUseCase);

  @override
  Future<AsyncRowsResponse> getRows(int startIndex, int limit) async {
    final int apiOffset = startIndex;
    final paginated = await _statsUseCase.getUsersPaginated(
      limit: limit,
      offset: apiOffset,
    );

    final users = paginated.items;
    final List<DataRow> rows = [];
    for (int i = 0; i < users.length; i++) {
      final user = users[i];
      final int rowIndex = startIndex + i;
      rows.add(DataRow(
        color: rowIndex % 2 == 0
            ? WidgetStateProperty.all(kWhite)
            : WidgetStateProperty.all(kLBlue.withValues(alpha: 0.10)),
        cells: [
          DataCell(Center(child: Text(user.mobile ?? ''))),
          DataCell(Center(child: Text(user.initials ?? ''))),
          DataCell(
              Center(child: Text(user.amount?.toStringAsFixed(2) ?? '0.00'))),
        ],
      ));
    }

    if (paginated.total > 0) {
      _lastKnownTotal = paginated.total;
    } else {
      _lastKnownTotal = startIndex + users.length;
      if (users.length == limit) {
        _lastKnownTotal += 1;
      }
    }

    return AsyncRowsResponse(_lastKnownTotal, rows);
  }
}

class VoucherTotalBalancePerCustomerDataSource extends AsyncDataTableSource {
  final StatsUseCase _statsUseCase;
  int _lastKnownTotal = 0;

  VoucherTotalBalancePerCustomerDataSource(this._statsUseCase);

  String _formatExpirationDate(String? value) {
    if (value == null || value.isEmpty) return '';

    final DateTime? parsed = DateTime.tryParse(value);
    if (parsed == null) return value;

    return DateFormat('dd/MM/yyyy').format(parsed);
  }

  @override
  Future<AsyncRowsResponse> getRows(int startIndex, int limit) async {
    final int apiOffset = startIndex;
    final paginated =
        await _statsUseCase.getVoucherTotalBalancesPerCustomerPaginated(
      limit: limit,
      offset: apiOffset,
    );

    final vouchers = paginated.items;
    final List<DataRow> rows = [];
    for (int i = 0; i < vouchers.length; i++) {
      final item = vouchers[i];
      final int rowIndex = startIndex + i;
      rows.add(DataRow(
        color: rowIndex % 2 == 0
            ? WidgetStateProperty.all(kWhite)
            : WidgetStateProperty.all(kLBlue.withValues(alpha: 0.10)),
        cells: [
          DataCell(Center(child: Text(item.name ?? ''))),
          DataCell(Center(child: Text(item.amount ?? '0.00'))),
          DataCell(
              Center(child: Text(_formatExpirationDate(item.expirationDate)))),
        ],
      ));
    }

    if (paginated.total > 0) {
      _lastKnownTotal = paginated.total;
    } else {
      _lastKnownTotal = startIndex + vouchers.length;
      if (vouchers.length == limit) {
        _lastKnownTotal += 1;
      }
    }

    return AsyncRowsResponse(_lastKnownTotal, rows);
  }
}

class PartnerDigitalNeverOpenSessionDataSource extends AsyncDataTableSource {
  final StatsUseCase _statsUseCase;
  int _lastKnownTotal = 0;

  PartnerDigitalNeverOpenSessionDataSource(this._statsUseCase);

  @override
  Future<AsyncRowsResponse> getRows(int startIndex, int limit) async {
    final int apiOffset = startIndex;
    final paginated =
        await _statsUseCase.getPartnerDigitalNeverOpenSessionPaginated(
      limit: limit,
      offset: apiOffset,
    );

    final partners = paginated.items;
    final List<DataRow> rows = [];
    for (int i = 0; i < partners.length; i++) {
      final item = partners[i];
      final int rowIndex = startIndex + i;
      rows.add(DataRow(
        color: rowIndex % 2 == 0
            ? WidgetStateProperty.all(kWhite)
            : WidgetStateProperty.all(kLBlue.withValues(alpha: 0.10)),
        cells: [
          DataCell(Center(child: Text(item.name ?? ''))),
          DataCell(Center(child: Text(item.email ?? ''))),
          DataCell(Center(child: Text(item.phone ?? ''))),
          DataCell(Center(child: Text(item.withQrCode ?? ''))),
        ],
      ));
    }

    if (paginated.total > 0) {
      _lastKnownTotal = paginated.total;
    } else {
      _lastKnownTotal = startIndex + partners.length;
      if (partners.length == limit) {
        _lastKnownTotal += 1;
      }
    }

    return AsyncRowsResponse(_lastKnownTotal, rows);
  }
}

class SumExpiredVouchersConsumerDataSource extends AsyncDataTableSource {
  final StatsUseCase _statsUseCase;
  final DateTime? _dateFrom;
  final DateTime? _dateTo;
  int _lastKnownTotal = 0;

  SumExpiredVouchersConsumerDataSource(
      this._statsUseCase, this._dateFrom, this._dateTo);

  @override
  Future<AsyncRowsResponse> getRows(int startIndex, int limit) async {
    final int apiOffset = startIndex;
    final paginated =
        await _statsUseCase.getSumExpiredVouchersConsumerPaginated(
      dateFrom: _dateFrom,
      dateTo: _dateTo,
      limit: limit,
      offset: apiOffset,
    );

    final items = paginated.items;
    final List<DataRow> rows = [];
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final int rowIndex = startIndex + i;
      rows.add(DataRow(
        color: rowIndex % 2 == 0
            ? WidgetStateProperty.all(kWhite)
            : WidgetStateProperty.all(kLBlue.withValues(alpha: 0.10)),
        cells: [
          DataCell(Center(child: Text(item.name ?? ''))),
          DataCell(
              Center(child: Text(item.expiredVouchers?.toString() ?? '0'))),
          DataCell(Center(child: Text(item.unredeemendAmount ?? '0.00'))),
        ],
      ));
    }

    if (paginated.total > 0) {
      _lastKnownTotal = paginated.total;
    } else {
      _lastKnownTotal = startIndex + items.length;
      if (items.length == limit) {
        _lastKnownTotal += 1;
      }
    }

    return AsyncRowsResponse(_lastKnownTotal, rows);
  }
}

class DigitalPartnerNoActivityDataSource extends AsyncDataTableSource {
  final StatsUseCase _statsUseCase;
  int _lastKnownTotal = 0;

  DigitalPartnerNoActivityDataSource(this._statsUseCase);

  @override
  Future<AsyncRowsResponse> getRows(int startIndex, int limit) async {
    final int apiOffset = startIndex;
    final paginated = await _statsUseCase.getDigitalPartnerNoActivityPaginated(
      limit: limit,
      offset: apiOffset,
    );

    final partners = paginated.items;
    final List<DataRow> rows = [];
    for (int i = 0; i < partners.length; i++) {
      final item = partners[i];
      final int rowIndex = startIndex + i;
      rows.add(DataRow(
        color: rowIndex % 2 == 0
            ? WidgetStateProperty.all(kWhite)
            : WidgetStateProperty.all(kLBlue.withValues(alpha: 0.10)),
        cells: [
          DataCell(Center(child: Text(item.name ?? ''))),
          DataCell(Center(child: Text(item.id?.toString() ?? ''))),
          DataCell(Center(child: Text(item.email ?? ''))),
          DataCell(Center(child: Text(item.phone ?? ''))),
        ],
      ));
    }

    if (paginated.total > 0) {
      _lastKnownTotal = paginated.total;
    } else {
      _lastKnownTotal = startIndex + partners.length;
      if (partners.length == limit) {
        _lastKnownTotal += 1;
      }
    }

    return AsyncRowsResponse(_lastKnownTotal, rows);
  }
}
