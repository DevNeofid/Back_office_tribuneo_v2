import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/_global.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';
import 'package:back_office_tribuneo_v2/presentation/views/login_view.dart';
import 'package:back_office_tribuneo_v2/presentation/views/my_simple_page.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/main_usecase.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:back_office_tribuneo_v2/data/local/storage_function.dart';

void main() async {
  await initializeDateFormatting("fr_FR");
  WidgetsFlutterBinding.ensureInitialized();

  final MainUseCase mainUseCase = MainUseCase();
  bool isAuthenticated = await mainUseCase.checkToken();

  if (isAuthenticated) {
    final storageFunction = StorageFunction();
    final network = await storageFunction.readNetwork();

    if (network != null) {
      globalNetworkName = network.name;
    }
  }

  runApp(MyApp(isAuthenticated: isAuthenticated));
}

class MyApp extends StatelessWidget {
  final bool isAuthenticated;
  const MyApp({super.key, required this.isAuthenticated});

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
      initialRoute: isAuthenticated ? '/' : '/login',
      routes: {
        '/login': (context) => const LoginView(title: 'Login Page'),
        '/': (context) => const MySimplePage(),
      },
    );
  }
}
