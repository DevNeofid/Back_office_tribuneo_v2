import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

/// Demande d'ouverture d'un écran sur un élément ou un onglet précis
/// (deep-link de l'assistant), par exemple `payments` + `id_order`.
class ScreenOpenRequest {
  final String screen;
  final int? id;

  const ScreenOpenRequest(this.screen, {this.id});

  @override
  String toString() => 'ScreenOpenRequest($screen, id: $id)';
}

/// Boîte aux lettres des demandes d'ouverture, fournie par `MySinglePage`.
///
/// Le shell dépose la demande puis affiche le menu cible. L'écran cible la
/// retire avec [take] : dans son `initState` s'il vient d'être créé, ou dans
/// un listener s'il était déjà affiché. Une seule demande à la fois : une
/// nouvelle remplace celle qui n'a pas été prise.
class ScreenOpenRequests extends ChangeNotifier {
  ScreenOpenRequest? _pending;

  void request(ScreenOpenRequest request) {
    _pending = request;
    notifyListeners();
  }

  /// Retire et retourne la demande en attente si son écran est dans [screens].
  ScreenOpenRequest? take(Set<String> screens) {
    final ScreenOpenRequest? pending = _pending;
    if (pending == null || !screens.contains(pending.screen)) return null;
    _pending = null;
    return pending;
  }

  /// `null` hors de `MySinglePage` (écran affiché seul, tests).
  static ScreenOpenRequests? maybeOf(BuildContext context) {
    try {
      return Provider.of<ScreenOpenRequests>(context, listen: false);
    } on ProviderNotFoundException {
      return null;
    }
  }
}
