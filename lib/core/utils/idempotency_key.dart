import 'dart:math';

/// Clé d'idempotence (en-tête `Idempotency-Key`) : 16 octets aléatoires en
/// hexadécimal, soit 32 caractères (l'API en accepte 255 au plus).
String generateIdempotencyKey() {
  final Random random = Random.secure();
  return List<String>.generate(
          16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'))
      .join();
}

/// Une clé par opération métier, pas par clic : la clé de la dernière tentative
/// non réussie est réutilisée tant que le corps envoyé reste identique, pour que
/// l'API ne crée pas un second enregistrement si le premier était passé (coupure
/// réseau, timeout, double clic).
class PendingIdempotencyKey {
  String? _key;
  String? _payload;

  /// Clé à envoyer pour [payload] (corps JSON de la requête) : celle de la
  /// tentative précédente si le corps n'a pas changé, sinon une nouvelle.
  String keyFor(String payload) {
    if (_key == null || _payload != payload) {
      _key = generateIdempotencyKey();
      _payload = payload;
    }
    return _key!;
  }

  /// À appeler après un succès (y compris rejoué) : la prochaine opération
  /// partira avec une clé neuve.
  void clear() {
    _key = null;
    _payload = null;
  }

  /// À appeler après un échec, avec le code d'erreur de l'API (`null` pour une
  /// erreur réseau ou un timeout). La clé est gardée tant que le premier envoi
  /// a pu, ou peut encore, aboutir côté API ; elle est effacée quand l'API a
  /// refusé la requête pour de bon, la prochaine tentative partant alors neuve.
  void onError(String? code) {
    switch (code) {
      case null:
      case 'IDEMPOTENCY_REQUEST_IN_PROGRESS':
      case 'IDEMPOTENCY_KEY_RETRY':
      case 'SERVER_ERROR':
        return;
      default:
        clear();
    }
  }
}
