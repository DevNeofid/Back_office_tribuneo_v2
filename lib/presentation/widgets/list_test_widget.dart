import 'package:flutter/material.dart';

class Header extends StatelessWidget {
  const Header({
    required Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Color> colors = [
      const Color(0xffB3B8DE),
      const Color(0xffE61B54),
      const Color(0xff3A4276),
    ];

    List<Map<String, dynamic>> transactions = [
      {
        'wording': 'Virement Tom Cruise',
        'amount': '+ 100 000 €',
        'date': '22/09/2022',
      },
      {
        'wording': 'Virement Tom Cruise',
        'amount': '- 100 000 €',
        'date': '13/09/2022',
      },
      {
        'wording': 'Virement Tom Cruise',
        'amount': '+ 100 000 €',
        'date': '04/09/2022',
      },
    ];
    return ListView.separated(
      itemCount: transactions.length,
      shrinkWrap: true,
      separatorBuilder: (BuildContext context, int index) {
        return const SizedBox(
          height: 5,
        );
      },
      itemBuilder: (context, index) {
        return ListTile(
          visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40),
          ),
          tileColor: colors[index % 3],
          leading: const Icon(Icons.account_box),
          title: SelectableText(transactions[index]['wording']),
          subtitle: SelectableText(transactions[index]['date']),
          trailing: SelectableText(transactions[index]['amount']),
        );
      },
    );
  }
}
