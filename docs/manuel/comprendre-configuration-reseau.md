# Comprendre la configuration du réseau

## Objectif

Distinguer les choix accessibles dans les écrans métier et les réglages du
réseau qui nécessitent votre interlocuteur habituel chez Neofid.

## Repères dans le back-office

1. Vérifiez le nom du réseau affiché en haut de page. Il est chargé à la
   connexion ou repris de la session locale ; ce n'est pas un sélecteur de
   réseau ni une preuve que tous les paramètres sont correctement configurés.
2. Utilisez les menus métier décrits dans
   [Naviguer dans le back-office](naviguer-back-office.md).
3. Pour un réglage absent de ces menus, faites préciser le besoin à votre
   interlocuteur habituel, en indiquant le réseau et le message éventuel.

La version lue ne comporte pas de menu général **Configuration** ou
**Comptes bancaires du réseau**. Le clic sur le nom du réseau ouvre seulement
le choix **Déconnexion**. Il ne permet pas de modifier l'identité, les droits
d'accès ou les réglages du réseau.

## Comptes bancaires du réseau

Aucun écran actif d'ajout, de modification ou de suppression de ces comptes
n'est identifié dans le BO. Le logiciel lit les comptes déjà configurés par
Neofid pour les proposer ou les afficher dans les écrans concernés. Il ne faut
pas chercher un formulaire de création à partir de cette liste.

- Le **compte encaisseur** peut être proposé lors de l'enregistrement d'un
  paiement de commande : voir
  [Enregistrer un paiement](enregistrer-paiement-commande.md).
- Le **Compte payeur :** se consulte et, lorsque le réseau le permet, se choisit
  dans **Prochain virement** : voir
  [Choisir le compte payeur](choisir-compte-payeur-virement.md).
- Les journaux et comptes comptables relèvent de
  [Faire configurer les écritures comptables](configurer-ecritures-comptables.md).

Ces choix utilisent des comptes existants. Un compte unique ou un compte
imposé par les réglages du réseau peut empêcher l'apparition d'une liste de
choix ; cela ne prouve pas qu'un écran de gestion bancaire manque à votre compte.
Les coordonnées bancaires d'un client ou d'un partenaire appartiennent à leur
fiche et ne configurent pas les comptes du réseau.

Pour faire ajouter ou corriger un compte du réseau, sollicitez votre
interlocuteur Neofid habituel. Aucun formulaire BO, adresse de support ou
commande technique à exécuter n'est fourni ici. N'envoyez pas de coordonnées
bancaires réelles ni de secret dans le chat pour cette démarche.

## Secteurs et rapports

Le menu **Secteurs** gère un catalogue partagé ; il ne constitue pas le
paramétrage général du réseau. Voir
[Créer un secteur](creer-secteur-activite.md) et
[Supprimer un secteur](supprimer-secteur-activite.md).
Les rapports détaillés sont accessibles depuis **Statistiques** et font l'objet
d'une documentation séparée.

## Portée de l'aide Néo

Néo indique les limites et les fiches utiles. Il reste en lecture seule : il
ne change ni réseau, ni droits, ni paramètres, ni compte bancaire.

Vérification au 30 octobre 2026 : menus actifs, en-tête, chargement réseau,
repository bancaire et service API lus. Aucun paramètre en service interrogé
et aucune écriture effectuée.
