# Résoudre un problème de connexion au back-office

## Objectif

Comprendre les messages de connexion et transmettre les éléments utiles à
votre interlocuteur habituel chargé du réseau ou du support, sans communiquer
de secret. Cette aide concerne uniquement un problème d'accès au back-office.

## Selon le message affiché

| Message | Démarche |
| --- | --- |
| **Entrez un identifiant valide** | Renseignez **Nom d'utilisateur** : la validation locale vérifie seulement qu'il n'est pas vide. |
| **Erreur de connexion. Veuillez vérifier vos identifiants.** | Vérifiez l'identifiant du compte et votre saisie. Ce message est générique : il ne prouve pas à lui seul que le mot de passe est faux ; un problème technique peut aussi le provoquer. |
| **Accès refusé : votre compte n'est pas un compte administrateur.** | Faites vérifier que vous disposez du compte administrateur du réseau, et non d'un accès à l'application partenaire. |
| **Trop de tentatives de connexion. Veuillez réessayer dans …** | Attendez le délai affiché, en minutes ou en secondes, avant de réessayer. Ne multipliez pas les tentatives pendant ce délai. |
| **Votre session a expiré, veuillez vous reconnecter** | Le logiciel revient à l'écran de connexion. Reprenez la [procédure de connexion](se-connecter-back-office.md) avec vos propres identifiants. |

Le logiciel tente de renouveler la session automatiquement. Une panne réseau
temporaire pendant ce renouvellement n'est pas systématiquement traitée comme
une expiration. Au démarrage, toutefois, un échec de vérification de session
peut ramener à l'écran de connexion. Un retour à cet écran ne prouve donc pas
que votre compte a été supprimé.

## Mot de passe oublié ou difficulté persistante

1. Ne cherchez pas un bouton de récupération dans cette page : aucun parcours
   **Mot de passe oublié** n'est accessible dans le BO vérifié.
2. Sollicitez votre interlocuteur habituel chargé du réseau ou du support pour
   faire vérifier votre accès et connaître la démarche adaptée. Aucun contact
   support ni adresse de réinitialisation n'est indiqué dans cette page.
3. Transmettez le libellé exact du message, l'heure approximative, le navigateur
   utilisé et le nom du réseau attendu. Masquez les informations personnelles
   de toute capture ; ne transmettez ni mot de passe, ni cookie, ni jeton de
   session à Néo.

Des fonctions de réinitialisation existent côté API, mais cela ne constitue
pas un parcours utilisateur accessible dans cet écran. Aucun envoi d'e-mail
ni réinitialisation ne découle de cette fiche.

Si une opération métier précédait l'interruption, vérifiez son résultat dans
l'écran concerné avant de la recommencer : une erreur d'affichage ou de
connexion ne garantit pas l'absence d'effet.

## Portée de l'aide Néo

Néo explique les messages et aide à formuler le problème. Il ne vérifie pas
votre mot de passe, ne débloque pas un compte et ne déclenche pas de récupération.

Vérification au 30 octobre 2026 : code BO/API lu. Aucun essai de connexion,
expiration provoquée, oubli de mot de passe ou contact support exécuté.
