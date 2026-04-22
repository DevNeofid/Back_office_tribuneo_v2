import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:back_office_tribuneo_v2/config/size_config.dart';
import 'package:back_office_tribuneo_v2/domain/models/partner_total_amount_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/user_balance_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/network_amount_model.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/stats_usecase.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';

class StatsContentView extends StatefulWidget {
  const StatsContentView({super.key});

  @override
  StatsContentViewState createState() => StatsContentViewState();
}

class StatsContentViewState extends State<StatsContentView> {
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
    final bool isCompact = MediaQuery.of(context).size.width < 1500;

    final double headerHeight = 54.0;
    final double rowHeight = 56.0;
    final double tableHeight = headerHeight + (rowCount * rowHeight) + 16.0;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isCompact ? 600 : 800,
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
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (_selectedButtonIndex == 1 || _selectedButtonIndex == 2)
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
      default:
        return Container();
    }
  }

  Widget _buildPartnerTotalBalanceContent() {
    return FutureBuilder<List<PartnerTotalAmountModel>>(
      future: StatsUseCase()
          .getPartnerTotalBalances(_selectedStartDate, _selectedEndDate),
      builder: (context, snapshot) {
        final bool isCompact = MediaQuery.of(context).size.width < 1500;
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
              AsyncPaginatedDataTable2(
                wrapInCard: false,
                source: PartnerTotalDataSource(data),
                columnSpacing: isCompact ? 16 : 22,
                horizontalMargin: isCompact ? 10 : 14,
                minWidth: isCompact ? 600 : 800,
                rowsPerPage: 10,
                columns: const [
                  DataColumn(label: Center(child: Text('Nom'))),
                  DataColumn(label: Center(child: Text('Montant total'))),
                ],
              ),
              rowCount:
                  data.length > 10 ? 10 : (data.isEmpty ? 1 : data.length),
            ),
          );
        }
      },
    );
  }

  Widget _buildUsersContent() {
    return FutureBuilder<List<UserBalanceModel>>(
      future: StatsUseCase().getUsers(),
      builder: (context, snapshot) {
        final bool isCompact = MediaQuery.of(context).size.width < 1500;
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
              AsyncPaginatedDataTable2(
                wrapInCard: false,
                source: UsersDataSource(data),
                columnSpacing: isCompact ? 16 : 22,
                horizontalMargin: isCompact ? 10 : 14,
                minWidth: isCompact ? 600 : 800,
                rowsPerPage: 10,
                columns: const [
                  DataColumn(label: Center(child: Text('Téléphone'))),
                  DataColumn(label: Center(child: Text('Initiales'))),
                  DataColumn(label: Center(child: Text('Montant coupon (€)'))),
                ],
              ),
              rowCount:
                  data.length > 10 ? 10 : (data.isEmpty ? 1 : data.length),
            ),
          );
        }
      },
    );
  }

  Widget _buildNetworkTotalAmount() {
    return FutureBuilder<List<NetworkTotalAmountModel>>(
      future: StatsUseCase()
          .getNetworkTotalAmounts(_selectedStartDate, _selectedEndDate),
      builder: (context, snapshot) {
        final bool isCompact = MediaQuery.of(context).size.width < 1500;
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
                columnSpacing: isCompact ? 16 : 22,
                horizontalMargin: isCompact ? 10 : 14,
                minWidth: isCompact ? 600 : 800,
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
}

class PartnerTotalDataSource extends AsyncDataTableSource {
  final List<PartnerTotalAmountModel> _data;
  PartnerTotalDataSource(this._data);
  @override
  Future<AsyncRowsResponse> getRows(int startIndex, int limit) async {
    final endIndex =
        (startIndex + limit > _data.length) ? _data.length : startIndex + limit;
    final List<DataRow> rows = [];
    for (int i = startIndex; i < endIndex; i++) {
      final item = _data[i];
      rows.add(DataRow(
        color: i % 2 == 0
            ? WidgetStateProperty.all(kWhite)
            : WidgetStateProperty.all(kLBlue.withValues(alpha: 0.10)),
        cells: [
          DataCell(Center(child: Text(item.name ?? ''))),
          DataCell(Center(
              child: Text(item.totalAmount?.toStringAsFixed(2) ?? '0.00'))),
        ],
      ));
    }
    return AsyncRowsResponse(_data.length, rows);
  }
}

class UsersDataSource extends AsyncDataTableSource {
  final List<UserBalanceModel> _users;
  UsersDataSource(this._users);
  @override
  Future<AsyncRowsResponse> getRows(int startIndex, int limit) async {
    final endIndex = (startIndex + limit > _users.length)
        ? _users.length
        : startIndex + limit;
    final List<DataRow> rows = [];
    for (int i = startIndex; i < endIndex; i++) {
      final user = _users[i];
      rows.add(DataRow(
        color: i % 2 == 0
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
    return AsyncRowsResponse(_users.length, rows);
  }
}
