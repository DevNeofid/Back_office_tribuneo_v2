import 'package:back_office_tribuneo_v2/domain/errors/assistant_exception.dart';
import 'package:back_office_tribuneo_v2/domain/models/assistant_model.dart';
import 'package:back_office_tribuneo_v2/domain/repositories/assistant_repository.dart';

/// Réponses factices, en attendant la passerelle `/chat` (§ 7 de la spec).
///
/// Répond après [delay] avec un texte et, selon un mot-clé du message, un bloc
/// `link`, `choices` ou `document`. Les mots « quota » et « panne » simulent
/// les erreurs correspondantes.
class FakeAssistantRepository implements AssistantRepository {
  final Duration delay;
  int _sessionCount = 0;

  FakeAssistantRepository({this.delay = const Duration(milliseconds: 1500)});

  @override
  Future<String> createSession() async => 'fake-${++_sessionCount}';

  @override
  Future<AssistantReply> sendMessage(String sessionId, String message) async {
    await Future<void>.delayed(delay);
    final String text = message.toLowerCase();

    if (text.contains('quota')) {
      throw const AssistantException(AssistantErrorKind.quota);
    }
    if (text.contains('panne')) {
      throw const AssistantException(AssistantErrorKind.unavailable);
    }
    if (text.contains('factur')) {
      return const AssistantReply(
        text: 'Voici la facture de la commande **n° 1**.',
        blocks: [AssistantDocumentBlock(kind: 'invoice', idOrder: 1)],
      );
    }
    if (text.contains('pay')) {
      return const AssistantReply(
        text: 'La commande **n° 1** est payée à moitié : il reste un '
            'paiement à enregistrer.',
        blocks: [AssistantLinkBlock(screen: 'payments', id: 1)],
      );
    }
    if (text.contains('banc') ||
        text.contains('iban') ||
        text.contains('rib')) {
      return const AssistantReply(
        text: 'Les coordonnées bancaires du commerçant se trouvent sur sa '
            'fiche, onglet **Informations bancaires**.',
        blocks: [AssistantLinkBlock(screen: 'bank_accounts', id: 1)],
      );
    }
    if (text.contains('retrouver') || text.contains('cherche')) {
      return const AssistantReply(
        text: 'Je peux vous aider à retrouver une commande.',
        blocks: [
          AssistantChoicesBlock(
            question: 'Que connaissez-vous de la commande ?',
            options: [
              AssistantChoice(label: 'Son numéro', value: 'numero'),
              AssistantChoice(label: 'Le client', value: 'client'),
              AssistantChoice(label: 'La date', value: 'date'),
            ],
          ),
        ],
      );
    }
    if (text.contains('commande')) {
      return const AssistantReply(
        text: 'Pour créer une commande :\n\n'
            '1. ouvrez le menu **Commandes** ;\n'
            '2. cliquez sur le bouton **+** orange ;\n'
            '3. choisissez le client, puis saisissez les montants.\n\n'
            'La commande apparaît ensuite dans la liste.',
        blocks: [AssistantLinkBlock(screen: 'orders')],
      );
    }
    return AssistantReply(
      text: 'Réponse de démonstration à : *$message*\n\n'
          "Essayez par exemple « facture », « paiement », « bancaire », "
          "« retrouver une commande », « quota » ou « panne ».",
    );
  }
}
