# E06 — relance ciblée depuis le panneau et Néo

La capability serveur `targeted_research` est additive : absente/false => aucun parcours ciblé. Aucun nouveau flag de build. Le formulaire manuel reste indépendant du chat et d’Hermes. Les flags du lot 02 et leur comportement par défaut ne changent pas.

`ResearchForm` est utilisé par `EnrichmentPanel` et le contrôleur de comparaison dédié. Le bloc `enrichment_research` ne transporte que batch/row/proposal/version. Le rendu ordinaire ignore cette action faute de `ResearchActions`. Aucun texte ou bloc du modèle ne devient un critère.

Les six champs sont préremplis depuis la ligne autorisée ou le GET des métadonnées du job. Une ancienne route renvoie 404 => préremplissage depuis la ligne ; toute autre erreur de métadonnées bloque la saisie préremplie. La confirmation « Relancer la recherche » seule appelle le POST. La validation porte sur tailles en caractères, contrôles, URL, UTF-8 <=4096 octets, SIRET/Luhn, code postal, France et critères suffisants. Pas de troncature.

Le usecase conserve la clé par proposition et corps normalisé pendant les échecs ; un corps différent crée une nouvelle clé. Busy, tenant, version, état, job courant, batch et durée de vie sont contrôlés avant/après attente. Le nouveau job suit le mécanisme existant : progression, lecture, pause, annulation et historique. Les anciens résultats restent côté serveur. Les critères historiques sont affichés séparément, même si la ligne est devenue obsolète. Aucune cellule n’est modifiée par ce parcours ; l’apply existant garde sa confirmation indépendante et ses protections d’identité/CAS.

Les résultats suivants se comparent sur une nouvelle action humaine qui crée un contrôleur et une session dédiés. Aucune ancienne conversation n’est réaffectée.

## Contrats

- `CONTRAT_V1_2.openapi.json` : copie inchangée de la préparation pour les routes E05.
- `SCHEMA_BLOC_RELANCE.json` : schéma gelé du bloc serveur.
- `CONTRAT_CHAT_RESEARCH.openapi.json` : extension chat E06, identique à la copie API. Elle porte `blocks.maxItems=2` et l’union candidats/research. Les contrats actifs restent inchangés ; M12 consolide cette extension. Le contrat de préparation limite encore ChatReply au seul bloc candidats : cette différence est explicitement documentée.

## Vérification locale

Depuis BO, avec Flutter/Dart et cache déjà présents (aucune résolution de dépendances) :

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File test/merchant_enrichment/research_run.ps1 -Mode Test
powershell -NoProfile -ExecutionPolicy Bypass -File test/merchant_enrichment/research_run.ps1 -Mode Analyze
```

Le lanceur crée uniquement `test/merchant_enrichment/research_runtime/`, vérifie les SHA-256 des copies des sources du worktree, utilise un Env synthétique, puis supprime ce répertoire exact. Il n’importe jamais `.env`, `env.g.dart` privé, clés ou fichier commerçants réel. Les fichiers de configuration de packages et leur graphe sont réutilisés depuis le cache existant. `SOURCES_TESTS.json` prouve les sources testées. Journaux : `TESTS_FLUTTER.txt`, `ANALYSE_FLUTTER.txt`.

Les transports de test couvrent exclusivement les chemins du contrat ; le code de production utilise `EnrichmentRepository`. Les routes ciblées et la capability réelles appartiennent à E05 et ne sont pas ajoutées par E06. Le vrai assemblage E05/E06 reste à vérifier par M12. La recette globale préproduction est différée.
