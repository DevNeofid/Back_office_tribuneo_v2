# Donner accès à l'application à un partenaire

## Objectif et prérequis

Transmettre au commerçant de quoi faire la première connexion à son compte
d'application : un QR code à imprimer ou un lien, à copier ou à envoyer par
e-mail. Ces actions se trouvent dans **Partenaires**, écran
**Liste des magasins partenaires**.

Le compte d'application est créé à l'ajout du partenaire. Son
**Nom d'utilisateur** est visible dans l'onglet **Informations générales**.
Tant que la première connexion n'est pas faite, ce compte n'a qu'un mot de passe
par défaut et n'est pas utilisable ; ce mot de passe n'est pas à communiquer.

Le QR de première connexion et le lien correspondent au même accès. Tant qu'il
n'a pas servi, le générer à nouveau redonne le même accès ; cela ne crée pas un
second compte et n'invalide pas un lien déjà envoyé. Une fois la première
connexion faite, le QR et le lien ne peuvent plus être générés.

Chaque choix du menu lance immédiatement la génération ; il peut enregistrer
l'accès s'il n'existait pas encore. Ne l'utilisez pas pour une simple vérification.

## QR code de première connexion

1. Sur la carte du partenaire, ouvrez l'icône QR (**Menu Qrcode**).
2. Choisissez **Générer le QR Code de première connexion**.
3. **Génération du QR Code...** s'affiche, puis un PDF est téléchargé sous le
   nom du partenaire, espaces remplacés par `_`, suivi de `_qr_code.pdf`.
4. Remettez ce document au commerçant uniquement.

Le QR de réception produit un fichier de même nom : rangez ou renommez les
fichiers pour ne pas les confondre.

## Lien de première connexion

1. Ouvrez **Menu Qrcode**, puis **Générer le lien de première connexion**.
2. La boîte **Votre lien pour** suivi du nom du partenaire affiche le lien.
3. Pour le copier, cliquez sur l'icône de copie : **Lien copié !** s'affiche.
4. Pour l'envoyer par e-mail, cochez **Envoyé par mail** : le bouton **Envoyer**
   devient actif. Cliquez dessus pour envoyer le lien à l'adresse e-mail de la
   fiche partenaire.
5. **Lien envoyé par mail avec succès !** signifie que le service d'envoi a
   accepté le message, pas qu'il a été reçu. **Fermer** ferme sans envoyer.

Vérifiez l'e-mail de la fiche avant l'envoi : il n'est pas modifiable dans cette
boîte. Avant un renvoi, demandez au commerçant de vérifier sa messagerie, y
compris les courriers indésirables.

## Refus et anomalies

| Situation | Effet constaté dans le code |
| --- | --- |
| Première connexion déjà faite | refus de l'API ; pour le lien, aucune boîte ni message |
| Aucun compte d'application lié à l'entité | refus `User not found` ; même affichage que ci-dessus |
| E-mail absent de la fiche lors de l'envoi | refus ; **Erreur lors de l'envoi : …** |
| Échec de l'envoi par le service d'e-mail | **Erreur lors de l'envoi : …** |
| Échec de génération du QR | aucun message ; **Génération du QR Code...** peut rester affiché |

Si l'indicateur de génération ne disparaît pas, le BO ne permet pas de le
fermer ; un rechargement de la page du navigateur est alors nécessaire (non
testé). Avant de relancer, demandez au commerçant s'il s'est déjà connecté.

Le BO ne propose pas, dans cet écran, de réinitialisation du mot de passe d'un
commerçant déjà connecté. Les étapes que le commerçant suit dans l'application
ne sont pas décrites ici.

## Confidentialité et portée de l'aide Néo

Le lien et le QR donnent accès à l'activation du compte : ne les transmettez
qu'au commerçant concerné et ne les collez pas dans une conversation. Néo
explique ces actions ; il ne génère ni QR, ni lien, ni e-mail.

Vérification au 30 octobre 2026 : menu, boîte du lien, repository, actions API
du lien et du QR et route du service de QR lus. Génération réelle, envoi réel,
contenu du PDF, parcours du commerçant et rechargement de page non testés.
