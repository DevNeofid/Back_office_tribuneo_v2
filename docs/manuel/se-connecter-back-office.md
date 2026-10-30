# Se connecter au back-office

## Objectif et prérequis

Accéder au back-office avec un compte administrateur du réseau et ses
identifiants habituels. Un compte destiné à l'application partenaire ne suffit
pas. Cette procédure concerne une demande de connexion ; l'utilisation
ordinaire de Néo suppose que vous êtes déjà dans votre espace de gestion.

## Étapes

1. Ouvrez l'adresse du back-office qui vous a été communiquée. L'écran affiche
   **Backoffice**.
2. Renseignez **Nom d'utilisateur** avec l'identifiant de votre compte. Ce champ
   n'est pas intitulé « E-mail » : ne supposez pas que votre adresse e-mail
   constitue votre identifiant.
3. Renseignez **Mot de passe**. L'icône en forme d'œil permet de rendre la
   saisie visible ou de la masquer.
4. Cliquez sur **Connexion** et attendez la fin du chargement.
5. Vérifiez le nom du réseau en haut de page. Le dernier menu mémorisé peut
   s'ouvrir ; **Accueil** permet de retrouver le tableau de bord.

## Contrôles et limites

Le champ identifiant vide affiche **Entrez un identifiant valide**. Le champ
mot de passe n'a pas de validation locale équivalente dans cette vue ; un mot
de passe vide est refusé côté serveur. La connexion vérifie les identifiants
d'un utilisateur non supprimé. Le back-office contrôle ensuite le statut de
compte administrateur ; les actions protégées de l'API contrôlent aussi les
droits et la session.

Si **Accès refusé : votre compte n'est pas un compte administrateur.** apparaît,
demandez à votre interlocuteur habituel de vérifier le type de compte. Ne
cherchez pas à utiliser un compte partenaire pour administrer le réseau.

Une erreur de connexion, une session expirée ou un mot de passe oublié se
traitent avec [Résoudre un problème de connexion](resoudre-probleme-connexion.md).
Aucun lien **Mot de passe oublié** n'est proposé dans l'écran BO vérifié.

## Portée de l'aide Néo

Néo explique les étapes ; il ne se connecte pas à votre place, ne demande pas
votre mot de passe et ne réinitialise pas votre accès.

Vérification au 30 octobre 2026 : vue active, repositories et contrôles API lus.
Aucun identifiant essayé et aucune session ouverte pour cette vérification.
