import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tribuneo_backoffice/config/size_config.dart';
import 'package:tribuneo_backoffice/domain/models/partner_unsettled_balance_model.dart';
import 'package:tribuneo_backoffice/domain/models/user_balance_model.dart';
import 'package:tribuneo_backoffice/domain/models/partner_activated_since_model.dart';
import 'package:tribuneo_backoffice/domain/usecases/stats_usecase.dart';
import 'package:tribuneo_backoffice/presentation/utils/common.dart';
import 'package:tribuneo_backoffice/presentation/widgets/neo_button.dart';

class StatsContentView extends StatefulWidget {
  const StatsContentView({super.key});

  @override
  StatsContentViewState createState() => StatsContentViewState();
}

class StatsContentViewState extends State<StatsContentView> {
  final DateFormat dateFormat = DateFormat('dd/MM/yyyy');
  int _selectedButtonIndex = 0;
  bool _isLoading = false;
  DateTime? _selectedDate; // Ensure this is within the class scope

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return SizedBox(
      height: SizeConfig.screenHeight * 0.8,
      child: Scaffold(
        body: Column(
          children: [
            Row(
              children: [
                NeoButton(
                  onPressed: () {
                    setState(() {
                      _selectedButtonIndex = 0;
                    });
                  },
                  text: 'Comptes utilisateurs',
                  backgroundColor:
                      _selectedButtonIndex == 0 ? kBlue : Colors.grey,
                ),
                SizedBox(width: SizeConfig.screenWidth * 0.01),
                NeoButton(
                  onPressed: () {
                    setState(() {
                      _selectedButtonIndex = 1;
                    });
                  },
                  text: 'Comptes partenaires',
                  backgroundColor:
                      _selectedButtonIndex == 1 ? kBlue : Colors.grey,
                ),
                SizedBox(width: SizeConfig.screenWidth * 0.01),
                NeoButton(
                  onPressed: () {
                    setState(() {
                      _selectedButtonIndex = 2;
                    });
                  },
                  text: 'Partenaires Démat',
                  backgroundColor:
                      _selectedButtonIndex == 2 ? kBlue : Colors.grey,
                ),
              ],
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
      default:
        return Container();
    }
  }

  Widget _buildDematPartnersContent() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      // Adjust the width as needed
                      width: 300,
                      child: ListTile(
                        title: Row(
                          children: [
                            Expanded(
                              // Check if _selectedDate is null, if so, display 'Select Date'
                              // otherwise, display the formatted selected date
                              child: Text(_selectedDate == null
                                  ? "Choisir une Date"
                                  : "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}"),
                            ),
                            Icon(Icons.calendar_today),
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
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Text("Error: ${snapshot.error}");
              } else if (snapshot.hasData) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: DataTable2(
                    columnSpacing: 12,
                    horizontalMargin: 12,
                    minWidth: 600,
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
                        return DataRow(cells: [
                          DataCell(Text(partner.code ?? 'N/A')),
                          DataCell(Text(partner.name ?? 'N/A')),
                          DataCell(Text(partner.city ?? 'N/A')),
                          DataCell(Text(partner.updatedDate ?? 'N/A')),
                        ]);
                      },
                    ),
                  ),
                );
              } else {
                return Text("No data available");
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: AsyncPaginatedDataTable2(
              source: UsersDataSource(snapshot.data ?? []),
              columnSpacing: 12,
              horizontalMargin: 12,
              minWidth: 600,
              columns: const [
                DataColumn(label: Text('Téléphone')),
                DataColumn(label: Text('Initials')),
                DataColumn(label: Text('Montant coupon (€)')),
              ],
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: AsyncPaginatedDataTable2(
              source: PartnersDataSource(snapshot.data ?? []),
              columnSpacing: 12,
              horizontalMargin: 12,
              minWidth: 600,
              columns: const [
                DataColumn(label: Text('CODE')),
                DataColumn(label: Text('NOM')),
                DataColumn(label: Text('Ville')),
                DataColumn(label: Text('Montant (€)')),
              ],
            ),
          );
        }
      },
    );
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
    final List<DataRow> rows = _users.sublist(startIndex, endIndex).map((user) {
      return DataRow(cells: [
        DataCell(Text(user.mobile ?? '')),
        DataCell(Text(user.initials ?? '')),
        DataCell(Text(user.amount?.toStringAsFixed(2) ?? '0.00')),
      ]);
    }).toList();

    return AsyncRowsResponse(
        _users.length, rows); // Corrected order or constructor call
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
    final List<DataRow> rows =
        _balances.sublist(startIndex, endIndex).map((balance) {
      return DataRow(cells: [
        DataCell(Text(balance.code ?? '')),
        DataCell(Text(balance.name ?? '')),
        DataCell(Text(balance.city ?? '')),
        DataCell(Text(balance.amount?.toStringAsFixed(2) ?? '0.00')),
      ]);
    }).toList();

    return AsyncRowsResponse(
        _balances.length, rows); // Corrected order or constructor call
  }
}
