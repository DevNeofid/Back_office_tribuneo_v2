# Générer le QR code de réception d'un partenaire

## Objectif et prérequis

Obtenir, sous forme de PDF à remettre au commerçant, le QR code de réception
propre à un partenaire du réseau courant, depuis **Partenaires**, écran
**Liste des magasins partenaires**.

Ce QR désigne le compte d'application du partenaire et son solde Tribuneo dans
le réseau courant, sans montant fixé. Il est distinct :

- du QR de première connexion, qui sert à activer le compte du commerçant :
  voir [Donner accès à l'application à un partenaire](donner-acces-application-partenaire.md) ;
- des QR codes des bons d'une commande et de leur archive, qui se génèrent
  depuis la commande : voir
  [Générer et télécharger les QR codes d'une commande](generer-qr-codes-commande.md).

Le partenaire doit avoir un compte d'application et un solde dans le réseau
courant ; c'est le cas après un ajout complet.

## Étapes

1. Retrouvez le partenaire avec
   [Rechercher et consulter un partenaire](rechercher-consulter-partenaire.md).
2. Sur sa carte, ouvrez l'icône QR (**Menu Qrcode**).
3. Choisissez **Générer le QR Code de réception**. La génération démarre
   immédiatement : aucune confirmation n'est demandée.
4. **Génération du QR Code...** s'affiche, puis un PDF est téléchargé sous le
   nom du partenaire, espaces remplacés par `_`, suivi de `_qr_code.pdf`.
5. Ouvrez le PDF et vérifiez le nom du commerçant qui y figure avant de le
   remettre.

Le QR de première connexion produit un fichier de même nom : renommez ou rangez
les fichiers pour ne pas les confondre.

## Limites et refus

- L'API refuse la génération si aucun compte d'application n'est lié à
  l'entité (`User not found`) ou si aucun solde n'existe pour ce compte dans le
  réseau courant (`Fund not found`).
- Le BO n'affiche aucun message d'erreur pour ce QR : en cas d'échec,
  **Génération du QR Code...** peut rester affiché sans pouvoir être fermé. Un
  rechargement de la page du navigateur est alors nécessaire (non testé).
- Le QR est propre au réseau courant. Pour un commerce partenaire de plusieurs
  réseaux, générez-le depuis chaque réseau concerné.
- Le contenu du QR est chiffré et recalculé à chaque génération. La validité
  d'un QR déjà imprimé après une nouvelle génération ou une désactivation n'est
  pas établie par les sources lues.
- La manière dont le QR est lu dans l'application n'est pas décrite ici.

## Portée de l'aide Néo

Néo explique la démarche ; il ne génère aucun QR code et ne peut pas en fournir.

Vérification au 30 octobre 2026 : menu, repository, action API et route du
service de génération lus. Génération réelle, contenu et lecture du PDF
non testés.
