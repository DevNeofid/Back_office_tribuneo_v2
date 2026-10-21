/// Modèles de l'assistant (chatbot) du back-office.
///
/// Contrat provisoire de la passerelle `/chat` : voir
/// `SPEC_front_chatbot_affichage_2026-10-21.md` § 5.2 et § 7.

/// Bloc d'interface joint à une réponse de l'assistant.
///
/// Un bloc de type inconnu, ou mal formé, est ignoré par [AssistantBlock.fromJson]
/// (retourne `null`) : l'API peut ajouter des types sans casser le BO.
sealed class AssistantBlock {
  const AssistantBlock();

  static AssistantBlock? fromJson(dynamic json) {
    if (json is! Map) return null;
    final Map<String, dynamic> map = Map<String, dynamic>.from(json);
    switch (map['type']) {
      case 'link':
        return AssistantLinkBlock.fromJson(map);
      case 'choices':
        return AssistantChoicesBlock.fromJson(map);
      case 'document':
        return AssistantDocumentBlock.fromJson(map);
      default:
        return null;
    }
  }
}

/// Deep-link vers un écran du BO (§ 6 de la spec).
class AssistantLinkBlock extends AssistantBlock {
  /// Écrans connus. `payments` et `bank_accounts` n'ont de sens qu'avec un id.
  static const Set<String> screens = {
    'orders',
    'order',
    'customers',
    'customer',
    'partners',
    'invoices',
    'payments',
    'bank_accounts',
  };

  /// Écrans qui ciblent un élément ; pour les listes, un `id` reçu est ignoré.
  static const Set<String> _screensWithId = {
    'order',
    'customer',
    'payments',
    'bank_accounts',
  };

  final String screen;
  final int? id;

  /// Libellé fourni par l'API, prioritaire sur le libellé par défaut.
  final String? label;

  const AssistantLinkBlock({required this.screen, this.id, this.label});

  static AssistantLinkBlock? fromJson(Map<String, dynamic> json) {
    final String? screen = json['screen']?.toString();
    if (screen == null || !screens.contains(screen)) return null;
    final int? id = _parseInt(json['id']);
    // `order` et `customer` sans id restent utilisables : ils ouvrent la liste.
    if (id == null && (screen == 'payments' || screen == 'bank_accounts')) {
      return null;
    }
    final String? label = json['label']?.toString();
    return AssistantLinkBlock(
      screen: screen,
      id: _screensWithId.contains(screen) ? id : null,
      label: label == null || label.trim().isEmpty ? null : label,
    );
  }

  String get buttonLabel {
    if (label != null) return label!;
    switch (screen) {
      case 'orders':
        return 'Ouvrir la liste des commandes';
      case 'order':
        return 'Ouvrir la commande';
      case 'customers':
        return 'Ouvrir la liste des clients';
      case 'customer':
        return 'Ouvrir la fiche du client';
      case 'partners':
        return 'Ouvrir la liste des commerçants';
      case 'invoices':
        return 'Ouvrir les factures';
      case 'payments':
        return 'Ouvrir les paiements de la commande';
      case 'bank_accounts':
        return 'Ouvrir les informations bancaires';
      default:
        return 'Ouvrir';
    }
  }
}

class AssistantChoice {
  final String label;
  final String value;

  const AssistantChoice({required this.label, required this.value});
}

/// Question à choix : le clic envoie [AssistantChoice.value] comme message de
/// l'utilisateur, en affichant [AssistantChoice.label].
class AssistantChoicesBlock extends AssistantBlock {
  final String question;
  final List<AssistantChoice> options;

  const AssistantChoicesBlock({required this.question, required this.options});

  static AssistantChoicesBlock? fromJson(Map<String, dynamic> json) {
    final dynamic rawOptions = json['options'];
    if (rawOptions is! List) return null;
    final List<AssistantChoice> options = [];
    for (final dynamic option in rawOptions) {
      if (option is! Map) continue;
      final String? label = option['label']?.toString();
      final String? value = option['value']?.toString();
      if (label == null || label.isEmpty || value == null || value.isEmpty) {
        continue;
      }
      options.add(AssistantChoice(label: label, value: value));
    }
    if (options.length < 2) return null;
    return AssistantChoicesBlock(
      question: json['question']?.toString() ?? '',
      options: options.take(6).toList(),
    );
  }
}

/// Document téléchargeable. Seul `kind = invoice` existe au MVP.
class AssistantDocumentBlock extends AssistantBlock {
  final String kind;
  final int idOrder;

  /// Libellé facultatif (ex. numéro de facture), fourni par l'API.
  final String? label;

  const AssistantDocumentBlock(
      {required this.kind, required this.idOrder, this.label});

  static AssistantDocumentBlock? fromJson(Map<String, dynamic> json) {
    final String? kind = json['kind']?.toString();
    final int? idOrder = _parseInt(json['id_order']);
    if (kind != 'invoice' || idOrder == null) return null;
    final String? label = json['label']?.toString();
    return AssistantDocumentBlock(
      kind: kind!,
      idOrder: idOrder,
      label: label == null || label.trim().isEmpty ? null : label,
    );
  }
}

/// Réponse de l'assistant à un message.
class AssistantReply {
  final String text;
  final List<AssistantBlock> blocks;

  const AssistantReply({required this.text, this.blocks = const []});

  factory AssistantReply.fromJson(Map<String, dynamic> json) {
    final dynamic rawBlocks = json['blocks'];
    return AssistantReply(
      text: json['text']?.toString() ?? '',
      blocks: rawBlocks is List
          ? rawBlocks
              .map(AssistantBlock.fromJson)
              .whereType<AssistantBlock>()
              .toList()
          : const [],
    );
  }
}

enum AssistantMessageRole { user, assistant, error }

/// Erreurs affichées dans le fil (§ 5.4).
enum AssistantErrorKind { quota, unavailable, sessionExpired, other }

/// Message du fil de conversation.
class AssistantMessage {
  final AssistantMessageRole role;
  final String text;
  final List<AssistantBlock> blocks;
  final AssistantErrorKind? errorKind;

  /// Vrai dès qu'un choix d'un bloc `choices` de ce message a été cliqué.
  bool choicesAnswered = false;

  AssistantMessage.user(this.text)
      : role = AssistantMessageRole.user,
        blocks = const [],
        errorKind = null;

  AssistantMessage.assistant(AssistantReply reply)
      : role = AssistantMessageRole.assistant,
        text = reply.text,
        blocks = reply.blocks,
        errorKind = null;

  AssistantMessage.error(AssistantErrorKind kind)
      : role = AssistantMessageRole.error,
        text = errorText(kind),
        blocks = const [],
        errorKind = kind;

  /// Le quota atteint ne se règle pas en réessayant.
  bool get retryable => errorKind != AssistantErrorKind.quota;

  static String errorText(AssistantErrorKind kind) {
    switch (kind) {
      case AssistantErrorKind.quota:
        return "Le quota mensuel de l'assistant est atteint.";
      case AssistantErrorKind.unavailable:
        return "L'assistant ne répond pas pour le moment. "
            'Réessayez dans quelques instants.';
      case AssistantErrorKind.sessionExpired:
      case AssistantErrorKind.other:
        return 'Une erreur est survenue.';
    }
  }
}

int? _parseInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
