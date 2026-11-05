import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/_global.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/arc_theme.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/initial_route.dart';
import 'package:back_office_tribuneo_v2/presentation/views/login_view.dart';
import 'package:back_office_tribuneo_v2/presentation/views/my_single_page.dart';
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

  /// Pile de départ : une seule page, choisie selon la session (et non selon
  /// l'URL, qui peut encore indiquer `/#/login` après une reconnexion).
  static List<Route<dynamic>> initialRoutes(
          bool isAuthenticated) =>
      isAuthenticated
          ? singleInitialRoute('/', (context) => const MySinglePage())
          : singleInitialRoute(
              '/login', (context) => const LoginView(title: 'Login Page'));

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tribuneo Back-office',
      theme: ArcTheme.light(),
      scaffoldMessengerKey: snackbarKey,
      navigatorKey: navigatorKey,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('fr', 'FR'),
      ],
      initialRoute: isAuthenticated ? '/' : '/login',
      onGenerateInitialRoutes: (_) => initialRoutes(isAuthenticated),
      routes: {
        '/login': (context) => const LoginView(title: 'Login Page'),
        '/': (context) => const MySinglePage(),
      },
    );
  }
}
