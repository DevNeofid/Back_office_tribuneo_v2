# Utiliser « Générer le CSV » pour les bons d'une commande

## Objectif et prérequis

Télécharger les identifiants UUID des liens QR des bons d'une commande, avec
les droits d'administration du réseau. La commande, ses bons non annulés et
des liens QR associés doivent exister.

**Générer le CSV** et **Générer le récapitulatif** sont deux entrées distinctes :
le [récapitulatif](generer-recapitulatif-commande.md) comporte les montants et
les coordonnées enregistrées ; le CSV décrit ici contient uniquement des UUID.
Pour savoir quel export choisir, précisez le contenu attendu.

## Étapes

1. Ouvrez **Commandes**, écran **Liste des commandes**, puis retrouvez la
   commande et vérifiez son numéro.
2. Sur sa ligne, ouvrez l'icône de la colonne **Gestion** et choisissez
   **Générer le CSV**. La sélection lance directement le téléchargement,
   sans formulaire ni confirmation.
3. Attendez pendant **Téléchargement du fichier CSV...**.
4. Vérifiez les téléchargements du navigateur. Le nom utilisé par le BO est
   `<nom du client>_<numéro de commande>.csv`, avec les espaces du nom remplacés
   par des tirets bas.
5. Ouvrez le fichier dans un éditeur de texte ou un tableur en conservant les
   identifiants comme du texte. Il contient un UUID par ligne, sans en-tête,
   sans montant, sans restant et sans coordonnées de bénéficiaire.

## Règles et limites

- Le fichier reprend des liens existants pour les bons non annulés. Les bons
  sans lien retrouvé n'ajoutent pas de ligne : un export obtenu ne prouve pas
  la couverture de tous les bons de la commande.
- La sélection des liens n'exclut pas les liens déjà utilisés et ne filtre pas
  les dates d'expiration. La présence d'un UUID ne prouve pas qu'il soit encore
  utilisable.
- Le fichier n'est ni une archive d'images QR, ni le fichier attendu pour
  [créer une commande par import](creer-commande-import-fichier.md).
- Il n'est pas nécessaire de lancer la génération du ZIP pour essayer cet
  export : cette action lit les liens existants, sans les créer. En cas de
  lien absent, faites vérifier les données plutôt que supposer qu'une
  génération de ZIP corrigera le problème.

## En cas d'erreur

Le message du BO est **Erreur lors de la génération du CSV.** Il ne précise
pas la cause. Le serveur peut notamment refuser si la commande est introuvable,
si aucun bon n'est trouvé ou si aucun lien QR n'est retrouvé.

Vérifiez la bonne commande et les téléchargements du navigateur, puis faites
vérifier les données si le problème persiste. Ce message ou un fichier absent
ne permettent pas à eux seuls de conclure que la commande n'a aucun bon.

## Avec Néo

Demandez : « Comment utiliser Générer le CSV pour les UUID d'une commande ? ».
Néo explique le choix et le téléchargement ; il ne génère pas et ne joint pas
ce fichier. Une demande comme « export CSV » peut nécessiter de préciser
UUID, récapitulatif ou import.
