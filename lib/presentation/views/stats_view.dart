import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:back_office_tribuneo_v2/config/size_config.dart';
import 'package:back_office_tribuneo_v2/domain/models/partner_unsettled_balance_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/partner_total_amount_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/user_balance_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/partner_activated_since_model.dart';
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
  DateTime? _selectedDate;
  DateTime _selectedStartDate = DateTime(2023, 1, 1);
  DateTime _selectedEndDate = DateTime.now();

  @override
  void initState() {
    super.initState();
  }

  Widget _buildStyledTable(BuildContext context, Widget tableWidget) {
    final bool isCompact = MediaQuery.of(context).size.width < 1500;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isCompact ? 600 : 800,
        ),
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
                  dataRowMaxHeight: 56,
                  headingRowHeight: 54,
                ),
              ),
              child: tableWidget,
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
                          value: 0,
                          child: Text('Comptes utilisateurs'),
                        ),
                        DropdownMenuItem(
                          value: 1,
                          child: Text('Comptes partenaires'),
                        ),
                        DropdownMenuItem(
                          value: 2,
                          child: Text('Partenaires Démat'),
                        ),
                        DropdownMenuItem(
                          value: 3,
                          child: Text('Montant total des partenaires'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (_selectedButtonIndex == 3)
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
        return _buildPartnersContent();
      case 2:
        return _buildDematPartnersContent();
      case 3:
        return _buildPartnerTotalBalanceContent();
      default:
        return Container();
    }
  }

  Widget _buildPartnerTotalBalanceContent() {
    return FutureBuilder<List<PartnerTotalAmountModel>>(
      future: StatsUseCase()
          .getPartnerTotalBalances(_selectedStartDate, _selectedEndDate),
      builder: (BuildContext context,
          AsyncSnapshot<List<PartnerTotalAmountModel>> snapshot) {
        final bool isCompact = MediaQuery.of(context).size.width < 1500;
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: _buildStyledTable(
              context,
              AsyncPaginatedDataTable2(
                wrapInCard: false,
                source: PartnerTotalDataSource(snapshot.data ?? []),
                columnSpacing: isCompact ? 16 : 22,
                horizontalMargin: isCompact ? 10 : 14,
                minWidth: isCompact ? 600 : 800,
                columns: const [
                  DataColumn(label: Text('Nom')),
                  DataColumn(label: Text('Montant total')),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildDematPartnersContent() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 300,
                      child: ListTile(
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(_selectedDate == null
                                  ? "Choisir une Date"
                                  : dateFormat.format(_selectedDate!)),
                            ),
                            const Icon(Icons.calendar_today),
                          ],
                        ),
                        onTap: () async {
                          DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate ?? DateTime.now(),
                            firstDate: DateTime(2010),
                            lastDate: DateTime(3000),
                            locale: const Locale("fr", "FR"),
                            fieldHintText: "Jour/Mois/Année",
                          );
                          if (picked != null && picked != _selectedDate) {
                            setState(() {
                              _selectedDate = picked;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<PartnerActivatedSinceModel>>(
            future: _selectedDate == null
                ? StatsUseCase().getPartnerActivated()
                : StatsUseCase().getPartnerActivated(_selectedDate!),
            builder: (context, snapshot) {
              final bool isCompact = MediaQuery.of(context).size.width < 1500;
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Text("Error: ${snapshot.error}");
              } else if (snapshot.hasData) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildStyledTable(
                    context,
                    DataTable2(
                      columnSpacing: isCompact ? 16 : 22,
                      horizontalMargin: isCompact ? 10 : 14,
                      minWidth: isCompact ? 600 : 800,
                      columns: const [
                        DataColumn(label: Text('CODE')),
                        DataColumn(label: Text('NOM')),
                        DataColumn(label: Text('VILLE')),
                        DataColumn(label: Text('DATE')),
                      ],
                      rows: List<DataRow>.generate(
                        snapshot.data!.length,
                        (index) {
                          var partner = snapshot.data![index];
                          final isEvenRow = index % 2 == 0;
                          return DataRow(
                            color: isEvenRow
                                ? WidgetStateProperty.all(kWhite)
                                : WidgetStateProperty.all(
                                    kLBlue.withValues(alpha: 0.10)),
                            cells: [
                              DataCell(Text(partner.code ?? 'N/A')),
                              DataCell(Text(partner.name ?? 'N/A')),
                              DataCell(Text(partner.city ?? 'N/A')),
                              DataCell(Text(partner.updatedDate ?? 'N/A')),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                );
              } else {
                return const Text("No data available");
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUsersContent() {
    return FutureBuilder<List<UserBalanceModel>>(
      future: StatsUseCase().getUsers(),
      builder: (BuildContext context,
          AsyncSnapshot<List<UserBalanceModel>> snapshot) {
        final bool isCompact = MediaQuery.of(context).size.width < 1500;
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: _buildStyledTable(
              context,
              AsyncPaginatedDataTable2(
                wrapInCard: false,
                source: UsersDataSource(snapshot.data ?? []),
                columnSpacing: isCompact ? 16 : 22,
                horizontalMargin: isCompact ? 10 : 14,
                minWidth: isCompact ? 600 : 800,
                columns: const [
                  DataColumn(label: Text('Téléphone')),
                  DataColumn(label: Text('Initiales')),
                  DataColumn(label: Text('Montant coupon (€)')),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildPartnersContent() {
    return FutureBuilder<List<PartnerUnsettledBalanceModel>>(
      future: StatsUseCase().getPartnerUnBalance(),
      builder: (BuildContext context,
          AsyncSnapshot<List<PartnerUnsettledBalanceModel>> snapshot) {
        final bool isCompact = MediaQuery.of(context).size.width < 1500;
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: _buildStyledTable(
              context,
              AsyncPaginatedDataTable2(
                wrapInCard: false,
                source: PartnersDataSource(snapshot.data ?? []),
                columnSpacing: isCompact ? 16 : 22,
                horizontalMargin: isCompact ? 10 : 14,
                minWidth: isCompact ? 600 : 800,
                columns: const [
                  DataColumn(label: Text('CODE')),
                  DataColumn(label: Text('NOM')),
                  DataColumn(label: Text('Ville')),
                  DataColumn(label: Text('Montant (€)')),
                ],
              ),
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
      final isEvenRow = i % 2 == 0;
      rows.add(
        DataRow(
          color: isEvenRow
              ? WidgetStateProperty.all(kWhite)
              : WidgetStateProperty.all(kLBlue.withValues(alpha: 0.10)),
          cells: [
            DataCell(Text(item.name ?? '')),
            DataCell(Text(item.totalAmount?.toStringAsFixed(2) ?? '0.00')),
          ],
        ),
      );
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
      final isEvenRow = i % 2 == 0;
      rows.add(
        DataRow(
          color: isEvenRow
              ? WidgetStateProperty.all(kWhite)
              : WidgetStateProperty.all(kLBlue.withValues(alpha: 0.10)),
          cells: [
            DataCell(Text(user.mobile ?? '')),
            DataCell(Text(user.initials ?? '')),
            DataCell(Text(user.amount?.toStringAsFixed(2) ?? '0.00')),
          ],
        ),
      );
    }

    return AsyncRowsResponse(_users.length, rows);
  }
}

class PartnersDataSource extends AsyncDataTableSource {
  final List<PartnerUnsettledBalanceModel> _balances;

  PartnersDataSource(this._balances);

  @override
  Future<AsyncRowsResponse> getRows(int startIndex, int limit) async {
    final endIndex = (startIndex + limit > _balances.length)
        ? _balances.length
        : startIndex + limit;

    final List<DataRow> rows = [];
    for (int i = startIndex; i < endIndex; i++) {
      final balance = _balances[i];
      final isEvenRow = i % 2 == 0;
      rows.add(
        DataRow(
          color: isEvenRow
              ? WidgetStateProperty.all(kWhite)
              : WidgetStateProperty.all(kLBlue.withValues(alpha: 0.10)),
          cells: [
            DataCell(Text(balance.code ?? '')),
            DataCell(Text(balance.name ?? '')),
            DataCell(Text(balance.city ?? '')),
            DataCell(Text(balance.amount?.toStringAsFixed(2) ?? '0.00')),
          ],
        ),
      );
    }

    return AsyncRowsResponse(_balances.length, rows);
  }
}
