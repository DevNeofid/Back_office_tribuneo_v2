import 'package:back_office_tribuneo_v2/core/notifiers/screen_open_requests.dart';
import 'package:back_office_tribuneo_v2/domain/models/assistant_model.dart';

/// Cible d'un deep-link de l'assistant dans `MySinglePage`.
class AssistantDeepLink {
  /// `menuItems[*]['name']` du menu à afficher.
  final String menu;

  /// Demande d'ouverture à transmettre à l'écran (élément, onglet), `null`
  /// pour une simple liste.
  final ScreenOpenRequest? request;

  const AssistantDeepLink(this.menu, [this.request]);

  /// Correspondance validée le 21/10/2026 (§ 6 de la spec). `customer` ouvre
  /// seulement la liste : la fiche client n'accepte pas encore de demande.
  static AssistantDeepLink? fromLink(AssistantLinkBlock link) {
    switch (link.screen) {
      case 'orders':
        return const AssistantDeepLink('orders');
      case 'order':
      case 'payments':
        return AssistantDeepLink(
            'orders',
            link.id == null
                ? null
                : ScreenOpenRequest(link.screen, id: link.id));
      case 'customers':
      case 'customer':
        return const AssistantDeepLink('customer');
      case 'partners':
        return const AssistantDeepLink('partner');
      case 'bank_accounts':
        return link.id == null
            ? null
            : AssistantDeepLink(
                'partner', ScreenOpenRequest(link.screen, id: link.id));
      case 'invoices':
        return const AssistantDeepLink(
            'document', ScreenOpenRequest('invoices'));
      default:
        return null;
    }
  }
}
