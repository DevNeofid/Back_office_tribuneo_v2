import 'package:back_office_tribuneo_v2/domain/models/assistant_model.dart';

/// Échec d'un appel à la passerelle `/chat`, classé pour l'affichage (§ 5.4).
class AssistantException implements Exception {
  final AssistantErrorKind kind;

  const AssistantException(this.kind);

  @override
  String toString() => 'AssistantException($kind)';
}
