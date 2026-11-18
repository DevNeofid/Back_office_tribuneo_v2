# Restreindre une commande à certains commerçants

## Objectif et prérequis

Par défaut, les chèques d'une commande sont acceptés chez tous les commerçants
du réseau. Vous pouvez les réserver à une liste nommée de commerçants, à la
création de la commande ou plus tard. Les commerçants de la liste sont les
partenaires du réseau.

Le nom de la liste est public : il apparaît sur tribuneo.com et dans
l'application (par exemple « Noël 2026 »).

## À la création d'une commande

1. Dans **Commandes**, cliquez sur **Ajouter une commande**.
2. Dans la section **Où les chèques sont acceptés**, choisissez
   **Seulement chez certains commerçants** au lieu de
   **Chez tous les commerçants du réseau**.
3. Renseignez la liste (voir « Composer la liste » ci-dessous), puis terminez
   la commande comme d'habitude : voir
   [Créer une commande en saisie manuelle](creer-commande-manuelle.md) ou
   [Créer une commande par import de fichier](creer-commande-import-fichier.md).

## Sur une commande existante

1. Dans **Commandes**, retrouvez la commande, puis ouvrez le menu **Edition**
   et choisissez **Commerçants acceptés**. Ce choix est disponible quel que
   soit l'état de la commande, même facturée.
2. La section **Commerçants acceptés** affiche « Valable chez tous les
   commerçants du réseau. » ou le nom de la liste et son nombre de commerçants.
3. Cliquez sur **Restreindre à certains commerçants** (ou **Modifier la liste**
   si une liste existe), composez la liste, puis cliquez sur **Enregistrer**.
   Message : **Liste des commerçants enregistrée.**
4. Si des chèques de la commande ont déjà servi, une confirmation
   **Modifier la liste** rappelle que les paiements déjà faits ne changent pas :
   la nouvelle liste s'applique aux prochains paiements.

Pour revenir à tous les commerçants, cliquez sur **Rendre valable partout**,
puis **Continuer**. Message : **La commande est désormais valable chez tous les
commerçants.** **Voir sur le site** ouvre la liste publiée sur tribuneo.com.

## Composer la liste

- **Nom de la liste** : obligatoire, 60 caractères au plus.
- **Commerçants acceptés** : cochez les commerçants. La recherche
  **Rechercher par nom ou ville** accepte plusieurs mots, sans tenir compte des
  accents. **Tout cocher** et **Tout décocher** agissent sur les commerçants
  affichés ; le compteur indique « n sélectionné(s) · m affiché(s) ».
- Par défaut, seuls les commerçants qui acceptent la dématérialisation sont
  listés. Cochez **Afficher aussi les commerçants pas encore connectés à
  Tribuneo** pour voir les autres. La pastille **Pas encore connecté** signale
  un commerçant qui ne pourra encaisser ces chèques qu'après sa première
  connexion, et qui n'apparaît pas sur tribuneo.com.

## Repérer une commande restreinte

Dans **Commandes**, un cadenas à côté du **N°** signale une commande restreinte ;
son infobulle donne le nom de la liste et le nombre de commerçants. Un clic sur
le cadenas ouvre **Modifier la commande** sur la section
**Commerçants acceptés**. La recherche de l'écran porte aussi sur le nom de la
liste.

## Contrôles et limites

- « Donnez un nom à la liste. » ; « Le nom de la liste ne doit pas dépasser 60
  caractères. » ; « Sélectionnez au moins un commerçant. »
- « Certains commerçants ne font plus partie du réseau. Rechargez la liste et
  vérifiez votre sélection. » : les commerçants concernés sont décochés et la
  liste rechargée ; vérifiez la sélection avant d'enregistrer à nouveau.
- Quand tous les chèques de la commande ont expiré, la liste n'est plus
  affichée sur le site ni dans l'application.
- Si la liste des commerçants ne se charge pas, « Impossible de charger la
  liste des commerçants. » s'affiche avec **Réessayer**.

## Portée de l'aide Néo

Néo explique la restriction ; il ne crée, ne modifie ni ne retire aucune liste.

Vérification au 18 novembre 2026 : formulaire de commande, section
**Commerçants acceptés** et sélecteur de commerçants lus dans le code de
l'interface « Arc ». Enregistrement réel et affichage sur tribuneo.com non
testés.
