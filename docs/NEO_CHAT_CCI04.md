# Activation Néo CCI04 en préproduction

Le dépôt utilise désormais ApiAssistantRepository, via l'ApiClient authentifié existant, quand NEO_CHAT_ENABLED=true est fourni à la compilation. Les requêtes concernent uniquement le tenant tribuneo_cci04 et les routes API POST /chat/sessions et POST /chat/sessions/{id}/messages. L'API Tribuneo reste l'unique interlocuteur du navigateur.

```sh
flutter build web --release --no-pub --dart-define=NEO_CHAT_ENABLED=true
```

Conserver la configuration Env.kUrl de préproduction habituelle. Aucune clé Hermes ni JWT agent dans les options de compilation. Sans activation explicite, Néo est masqué. Le dépôt factice ne peut être sélectionné qu'en debug avec NEO_CHAT_DEMO=true.

Prérequis avant recette : version API contenant la passerelle /chat, relais WireGuard privé autorisé et installé sur le VPS Hermes, clé API du seul profil CCI04 installée dans le fichier protégé de l'API, NEO_CHAT_ENABLED=true côté API et JWT MCP encore valide. Voir docs/deploiement/NEO_CHAT_CCI04.md dans le dépôt Tribuneo_API pour la préparation et le retour arrière.

L'interface conserve les contrôleurs, l'historique en mémoire et la mascotte existants. Les erreurs sont affichées sans réponse de substitution. Un nouvel identifiant aléatoire est utilisé pour chaque question ; un réessai immédiat après une panne conserve celui de la demande précédente pour éviter une double exécution ambiguë. Les conversations expirent côté serveur après une heure d'inactivité : en rouvrir une si nécessaire. Ne pas réessayer une ancienne demande au-delà du délai de cache d'une heure.

Recette réelle attendue : administrateur réseau CCI04, question de lecture connue, réponse réelle, contrôle des outils MCP et erreur d'indisponibilité sans déconnexion. Les autres réseaux ne sont pas activés. Les blocs document/action restent vides dans cette première version.

Tests ciblés : test/assistant_repository_test.dart et les tests assistant existants. Aucun déploiement ou appel facturé à Hermes n'est effectué par les tests.
