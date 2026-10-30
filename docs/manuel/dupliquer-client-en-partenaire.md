# Dupliquer un client en partenaire

## Objectif et prérequis

Ajouter le rôle partenaire à une entité déjà cliente depuis **Clients**, écran
**Liste des clients**. Disposez des droits de gestion des clients et vérifiez
l'identité de la fiche ainsi que son éventuelle présence dans **Partenaires**.

Le terme **Dupliquer** de l'écran correspond à l'ajout du type partenaire à la
même entité dans le réseau courant. Il ne crée pas une copie indépendante de
ses informations générales.

## Étapes

1. Dans **Clients**, retrouvez le client avec **Rechercher...** ou son initiale.
2. Dans l'en-tête de sa fiche, ouvrez le menu d'actions à trois points, distinct
   du menu d'édition des informations.
3. Choisissez **Dupliquer ce Client en Partenaire**.
4. La confirmation **Ajouter ce client comme Partenaire** indique :
   **Vous allez ajouter ce client comme partenaire. Êtes-vous sûr de vouloir continuer ?**
5. Cliquez sur **Annuler** pour fermer sans changement. **Valider** déclenche
   l'ajout du rôle partenaire.
6. Vérifiez ensuite la présence de l'entité dans **Partenaires** et son état
   dans **Clients** avant toute nouvelle tentative.

## Résultat et limites

- Le BO peut afficher **Client dupliqué en partenaire avec succès !** dès la
  validation : l'appel d'ajout n'est pas attendu avant ce message. Ce message
  ne garantit donc pas que l'API a terminé ni accepté l'opération.
- L'API refuse un rôle déjà présent dans le réseau avec
  `Entity type already exists`. Elle refuse une entité introuvable avec
  `Entity not found`. Ces détails ne sont pas nécessairement restitués dans
  cette confirmation.
- Selon l'état existant, l'API peut aussi créer un utilisateur administrateur
  de boutique, un fonds de boutique et un lien réseau. Une erreur peut survenir
  après l'ajout du rôle ; vérifiez les données avant de recommencer.
- Le dialogue ne demande pas de SIRET et l'action d'ajout de rôle ne le contrôle
  pas. Cela ne prouve pas qu'un particulier sans SIRET pourra ensuite suivre
  toutes les opérations d'un partenaire : l'API de modification générale exige
  un SIRET si l'entité est partenaire dans au moins un réseau.
- Les informations générales sont partagées par l'entité. Cette fiche ne
  décrit ni configuration, ni paiement, ni désactivation de partenaire.

## Portée de l'aide Néo

Néo explique cette action humaine ; il n'ajoute pas de rôle. Pour vérifier le
dialogue sans opération métier, ouvrez-le puis choisissez **Annuler**.

Vérification au 30 octobre 2026 : accès dans la fiche client, confirmation,
repository et action API lus. Dialogue en session, ajout réel, résultat et
absence de doublon après exécution non testés.
