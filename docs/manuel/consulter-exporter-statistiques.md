# Consulter et exporter les statistiques

## Objectif et prérequis

Choisir un rapport dans **Statistiques**, régler sa période ou ses filtres,
lire le tableau puis télécharger le CSV correspondant. Le serveur réserve
toutes les lectures et tous les exports de statistiques aux administrateurs du
réseau. Le menu reste affiché pour les autres comptes ; leurs tableaux restent
alors vides et l'export échoue.

Ces rapports sont des lectures : les ouvrir ou les exporter ne modifie aucune
commande, aucun bon ni aucun compte.

## Étapes

1. Ouvrez **Statistiques** dans le menu latéral.
2. Dans la liste déroulante en haut de l'écran, choisissez le rapport. À
   l'ouverture, **Comptes utilisateurs** est sélectionné. Après un changement,
   **Exporter en CSV** reste brièvement indisponible pendant le chargement.
3. Si le rapport a une période, réglez **Date de debut** et **Date de fin**
   avec l'icône calendrier (voir ci-dessous).
4. Pour **Statut des QR codes par client**, renseignez les filtres puis cliquez
   sur **Rechercher** : voir [la fiche de ce rapport](statistiques-statut-qr-codes-client.md).
5. Lisez le tableau. Il affiche dix lignes par page ; utilisez les flèches de
   pagination sous le tableau. **Montant total du réseau** affiche une seule
   ligne, sans pagination.
6. Cliquez sur **Exporter en CSV**, attendez la fin de l'indicateur de
   chargement dans le bouton, puis vérifiez les téléchargements du navigateur.

## Les onze rapports

| Choix dans la liste | Période | Fiche |
|---|---|---|
| **Comptes utilisateurs** | Non | [Comptes utilisateurs](statistiques-comptes-utilisateurs.md) |
| **Montant total des partenaires** | Oui | [Montant total des partenaires](statistiques-montant-total-partenaires.md) |
| **Montant total du réseau** | Oui | [Montant total du réseau](statistiques-montant-total-reseau.md) |
| **Montant total des bons par clients** | Non | [Montant total des bons par clients](statistiques-montant-total-bons-clients.md) |
| **Partenaires jamais connectés** | Non | [Partenaires jamais connectés](statistiques-partenaires-jamais-connectes.md) |
| **Somme des coupons expirés par client** | Oui | [Coupons expirés par client](statistiques-coupons-expires-clients.md) |
| **Partenaires sans transactions** | Non | [Partenaires sans transactions](statistiques-partenaires-sans-transactions.md) |
| **Toutes les infos partenaires** | Non | [Informations partenaires](statistiques-informations-partenaires.md) |
| **Toutes les infos clients** | Non | [Informations clients](statistiques-informations-clients.md) |
| **Support technique - commandes** | Oui | [Support technique - commandes](statistiques-support-technique-commandes.md) |
| **Statut des QR codes par client** | Filtres Nom, Prénom, Email, Mobile | [Statut des QR codes par client](statistiques-statut-qr-codes-client.md) |

Les rapports sans période donnent l'état des données au moment de la lecture.

## Période

- Valeurs par défaut à l'ouverture de l'écran : **Date de debut** au
  01/01/2023, **Date de fin** à la date du jour.
- Si vous choisissez un début postérieur à la fin, la fin est alignée sur le
  début ; si vous choisissez une fin antérieure au début, le début est aligné
  sur la fin.
- Le serveur refuse une période dont le début n'est pas strictement antérieur
  à la fin. Avec la même date en début et en fin, le tableau reste vide et
  l'export échoue : ce n'est pas la preuve d'une absence de données.
- Seules les dates sont transmises. Les bornes réellement appliquées
  dépendent du rapport :

| Rapport | Donnée filtrée | Bornes appliquées |
|---|---|---|
| Montant total des partenaires | Date de création de la transaction | À partir de 23:59:59 le jour de début, jusqu'à 23:59:59 exclu le jour de fin |
| Montant total du réseau, colonnes **Frais de gestion** et **Total injecté** | Date de création de l'ordre de virement ou de la commande | Mêmes bornes que ci-dessus |
| Montant total du réseau, colonne **Gain expiré total** | Date d'expiration du bon | De 23:59:59 le jour de début à 23:59:59 le jour de fin, inclus, et seulement si l'expiration est passée |
| Somme des coupons expirés par client | Date de création de la commande | Du jour de début à 00:00:00 jusqu'au jour de fin à 00:00:00 exclu |
| Support technique - commandes | Date de création de la commande | De 23:59:59 le jour de début à 23:59:59 le jour de fin, inclus |

Conséquence : pour trois de ces rapports, le jour choisi en début n'est
couvert que pour sa dernière seconde. Pour couvrir tout un mois avec
**Montant total des partenaires**, choisissez en début le dernier jour du mois
précédent. Pour **Somme des coupons expirés par client**, choisissez au
contraire en fin le lendemain du dernier jour voulu.

Les dates sont interprétées dans le fuseau Europe/Paris par le serveur. Le
fuseau de la base pour les dates enregistrées et pour « maintenant » n'est pas
établi : autour de minuit, une ligne peut basculer d'un jour à l'autre.

## Export CSV

- Le fichier contient **toutes** les lignes du rapport pour la période ou les
  filtres appliqués, pas seulement la page affichée. Aucune limite de nombre
  de lignes n'est appliquée à l'export.
- Le nom du fichier est imposé par le back-office :

| Rapport | Nom du fichier téléchargé |
|---|---|
| Comptes utilisateurs | `comptes_utilisateurs.csv` |
| Montant total des partenaires | `montant_total_partenaires.csv` |
| Montant total du réseau | `montant_total_reseau.csv` |
| Montant total des bons par clients | `montant_total_bons_clients.csv` |
| Partenaires jamais connectés | `partenaires_jamais_connectes.csv` |
| Somme des coupons expirés par client | `somme_coupons_expires.csv` |
| Partenaires sans transactions | `partenaires_sans_activite.csv` |
| Toutes les infos partenaires | `toutes_les_infos_partenaires.csv` |
| Toutes les infos clients | `toutes_les_infos_clients.csv` |
| Support technique - commandes | `support_technique_commandes.csv` |
| Statut des QR codes par client | `liste_qr_code_status.csv` |

- Format : texte UTF-8 avec marque d'ordre d'octets, séparateur point-virgule,
  une première ligne d'en-têtes, décimales avec un point. Un champ contenant
  un point-virgule ou un guillemet est mis entre guillemets ; les retours à la
  ligne d'un champ sont remplacés par des espaces.
- Les en-têtes du fichier sont techniques et diffèrent des titres de colonnes
  de l'écran. Les montants peuvent y être écrits différemment (sans symbole €,
  ou au format brut de la base). Deux rapports n'exportent pas toutes les
  colonnes affichées : **ID** de **Partenaires sans transactions** et
  **Date de création** de **Support technique - commandes**. Chaque fiche de
  rapport donne la correspondance.
- Ouvrez le fichier dans un tableur en choisissant le point-virgule comme
  séparateur et en gardant les codes, téléphones, SIRET et IBAN au format texte.

## En cas d'erreur ou de tableau vide

L'export affiche alors **Erreur: Exception: Aucune donnée CSV reçue**. Ce
message apparaît dans plusieurs cas que l'écran ne distingue pas : aucune
ligne pour ce rapport, période refusée, droits insuffisants ou échec de
lecture. De même, un tableau vide ou réduit à ses en-têtes ne prouve pas
l'absence de données.

Vérifiez le rapport choisi, la période et les filtres, puis rechargez l'écran.
Après un changement de rapport, de période ou de filtre, le tableau peut
rester positionné sur la page consultée auparavant : revenez aux premières
pages avant de conclure. Si le doute persiste, faites vérifier les droits et
les données.

## Données personnelles et usage des chiffres

Plusieurs exports contiennent des coordonnées personnelles (téléphone, e-mail,
nom) et, pour les partenaires, l'IBAN et le BIC complets. Aucun masquage n'est
appliqué par le back-office ni par l'export. Conservez et transmettez ces
fichiers selon les règles de confidentialité du réseau.

Chaque montant suit une définition technique précisée dans la fiche du
rapport. Un total, un solde ou une ligne absente ne prouve pas à lui seul une
situation comptable, un paiement ou une anomalie : rapprochez-le des écrans
concernés avant toute décision.

## Avec Néo

Demandez par exemple : « Comment exporter les statistiques en CSV ? » ou
« Quelles dates choisir pour un mois complet ? ». Néo explique le parcours et
les définitions ; il ne lit pas ces rapports, ne lance aucun export et ne
joint aucun fichier. La navigation générale et le tableau de bord ont leurs
propres fiches : [Naviguer dans le back-office](naviguer-back-office.md) et
[Comprendre le tableau de bord](comprendre-tableau-bord.md).
