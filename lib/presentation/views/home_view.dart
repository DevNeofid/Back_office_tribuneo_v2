import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tribuneo_backoffice/domain/models/user_model_backup.dart';

// late Box<UserModel> connectedUserBox;

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  UserModel? connectedUser;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  void initState() {
    init();
    super.initState();
  }

  init() async {
    Box connectedUserBox = Hive.box<UserModel>('connectedUser');
    connectedUser = connectedUserBox.get('user');
  }

  @override
  Widget build(BuildContext context) {
    if (connectedUser?.id == null) {
      return Scaffold(
        appBar: AppBar(
          title: SelectableText(widget.title),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const SelectableText(
                "TOTO",
              ),
              SelectableText(
                '$_counter',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _incrementCounter,
          tooltip: 'Increment',
          child: const Icon(Icons.add),
        ),
      );
    } else {
      //
      return Scaffold(
        appBar: AppBar(
          title: SelectableText(widget.title),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SelectableText(
                "Bonjour ${connectedUser?.firstname}  ${connectedUser?.lastname} !",
              ),
              SelectableText(
                '$_counter',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
        ),
      );
    }
  }
}
