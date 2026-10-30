# Mettre en attente ou libérer une demande de remboursement

## Objectif

Suspendre une demande de remboursement dont vous doutez, pour qu'elle ne soit
pas payée par le prochain ordre de virement, puis la libérer quand elle peut
l'être. Ce parcours est actif dans le menu **Prochain virement**.

La mise en attente ne prévient pas le partenaire et n'annule pas la demande :
elle l'écarte des virements tant qu'elle n'est pas libérée.

## Mettre en attente

1. Dans **Prochain virement**, section **À payer**, dépliez la ligne du
   commerçant.
2. Sur la ligne de la demande, cliquez sur **Mettre en attente**.
3. La fenêtre **Mettre en attente** rappelle la demande et le commerçant et
   indique **Cette demande ne sera pas payée tant qu'elle n'aura pas été
   libérée.**
4. Saisissez si besoin un **Motif (facultatif)**, 255 caractères au plus.
   Ce motif est visible par les administrateurs du réseau ; n'y mettez pas de
   donnée bancaire.
5. Cliquez sur **Mettre en attente**. Pour renoncer, cliquez sur **Annuler** :
   rien n'est envoyé.
6. Le message **Demande … mise en attente.** s'affiche et l'aperçu est
   rechargé : la demande passe dans **Écartées** avec le motif
   **Mise en attente** et votre motif entre guillemets.

Le bouton n'existe que dans **À payer**. Une demande déjà écartée pour un
autre motif ne peut pas être mise en attente depuis l'écran.

## Libérer

1. Dans **Écartées**, sur une demande **Mise en attente**, cliquez sur
   **Libérer**.
2. La fenêtre **Libérer la demande …** indique
   **Cette demande sera incluse dans le prochain virement.**
3. Cliquez sur **Libérer**, ou sur **Annuler** pour renoncer.
4. Le message **Demande … libérée.** s'affiche et l'aperçu est rechargé.

La libération retire seulement la mise en attente. Si la demande a un autre
motif, par exemple une adresse incomplète, elle reste dans **Écartées**
malgré le texte de la fenêtre. Elle ne sera payée qu'à la génération d'un
ordre de virement.

## Messages et refus

| Message | Signification |
| --- | --- |
| **Le motif ne doit pas dépasser 255 caractères.** | Motif refusé ; la fenêtre reste ouverte |
| **Cette demande a déjà été payée.** | La demande est déjà rattachée à un ordre de virement |
| **Demande introuvable.** | Numéro inconnu ou qui n'est pas une demande de remboursement |
| **Erreur lors de la mise en attente de la demande.** | Échec sans cause précise |
| **Erreur lors de la libération de la demande.** | Échec sans cause précise |

Après un échec, l'aperçu est rechargé : regardez dans quelle section se
trouve la demande avant de recommencer.

## Règles utiles

- Une nouvelle mise en attente d'une demande déjà libérée remplace l'ancien
  motif et l'ancienne date. Le back-office n'affiche pas d'historique des
  mises en attente.
- Libérer une demande qui n'est plus en attente est sans effet.
- Une demande payée ne peut plus être mise en attente ni libérée.

## Portée de l'aide Néo

Néo explique la mise en attente et la libération ; il ne suspend ni ne libère
aucune demande.

Vérification au 30 octobre 2026 : boutons, fenêtres, messages, repository et
actions API de mise en attente et de libération lus. Aucune mise en attente
ni libération réelle ; ouverture puis **Annuler** non exécutées en session.
