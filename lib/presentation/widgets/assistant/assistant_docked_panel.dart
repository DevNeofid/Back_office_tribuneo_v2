import 'package:flutter/widgets.dart';

/// Conversation Néo contextuelle (ex. « Comparer avec Néo ») affichée dans le
/// panneau du bouton flottant, à la place de la conversation ordinaire.
///
/// La conversation ordinaire n'est ni effacée ni remplacée : elle réapparaît
/// à la fermeture du panneau ancré. Un seul panneau ancré à la fois : en
/// afficher un nouveau ferme le précédent (son `onDismissed` est appelé).
class AssistantDockedPanel extends ChangeNotifier {
  _DockedEntry? _entry;
  bool _disposed = false;

  /// Panneau affiché, `null` s'il n'y en a pas.
  Widget? get panel => _entry?.panel;

  /// Clé du panneau affiché : change à chaque [show].
  Key? get panelKey => _entry == null ? null : ObjectKey(_entry);

  /// Affiche [panel] et retourne le jeton à passer à [close].
  /// [onDismissed] : appelé si le panneau est fermé par un autre que son
  /// propriétaire (remplacé par un autre panneau ancré).
  Object show(Widget panel, {VoidCallback? onDismissed}) {
    final _DockedEntry? previous = _entry;
    final _DockedEntry entry = _DockedEntry(panel, onDismissed);
    _entry = entry;
    previous?.onDismissed?.call();
    _notify();
    return entry;
  }

  /// Ferme le panneau de jeton [token] ; sans effet s'il a déjà été remplacé.
  void close(Object token) {
    if (!identical(_entry, token)) return;
    _entry = null;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _entry = null;
    super.dispose();
  }
}

class _DockedEntry {
  final Widget panel;
  final VoidCallback? onDismissed;
  _DockedEntry(this.panel, this.onDismissed);
}

/// Rend [AssistantDockedPanel] accessible aux écrans de `MySinglePage`.
///
/// Absent (tests, assistant désactivé) : les écrans gardent leur affichage en
/// dialogue.
class AssistantDockedScope extends InheritedWidget {
  final AssistantDockedPanel docked;

  const AssistantDockedScope(
      {super.key, required this.docked, required super.child});

  static AssistantDockedPanel? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AssistantDockedScope>()?.docked;

  @override
  bool updateShouldNotify(AssistantDockedScope oldWidget) =>
      docked != oldWidget.docked;
}
