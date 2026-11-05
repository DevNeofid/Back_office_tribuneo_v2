import 'package:flutter/material.dart';

/// Pile de départ réduite à la seule page [name] (`onGenerateInitialRoutes`).
///
/// Par défaut, `initialRoute: '/login'` empile aussi '/' dessous : le retour
/// navigateur depuis la connexion affichait alors le back-office sans session.
List<Route<dynamic>> singleInitialRoute(String name, WidgetBuilder builder) => [
      MaterialPageRoute<void>(
          settings: RouteSettings(name: name), builder: builder),
    ];
