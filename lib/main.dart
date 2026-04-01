import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:tribuneo_backoffice/data/local/local_data_helper.dart';
import 'package:tribuneo_backoffice/domain/models/user_model.dart';
import 'package:tribuneo_backoffice/presentation/utils/_global.dart';
import 'package:tribuneo_backoffice/presentation/utils/common.dart';
import 'package:tribuneo_backoffice/presentation/views/login_view.dart';
import 'package:tribuneo_backoffice/presentation/views/my_simgle_page.dart';
import 'package:tribuneo_backoffice/domain/usecases/main_usecase.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  Hive.registerAdapter(UserModelAdapter());
  await Hive.openBox<UserModel>('users');
  await Hive.openBox('token');

  LocalDataHelper localDataHelper = LocalDataHelper();

  // Vérifiez si le token est correct
  String? token = await localDataHelper.getByKey('token', 0);
  bool isTokenValid = false;
  if (token != null) {
    isTokenValid = await MainUseCase().authCheck(token);
  }
  runApp(MyApp(isTokenValid: isTokenValid));
}

class MyApp extends StatelessWidget {
  final bool isTokenValid;
  const MyApp({super.key, required this.isTokenValid});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tribuneo Back-office',
      theme: ThemeData(
        scaffoldBackgroundColor: kPLGrey,
      ),
      scaffoldMessengerKey: snackbarKey,
      navigatorKey: navigatorKey,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('fr', 'FR'),
      ],
      initialRoute: isTokenValid ? '/' : '/login',
      routes: {
        '/login': (context) => const LoginView(title: 'Login Page'),
        '/': (context) => const MySimplePage(),
      },
    );
  }
}
