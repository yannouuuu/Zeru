# Accueil — idées pour le solde et le graphique

> Quatre directions natives pour afficher le solde et son graphe ensemble,
> avec l'interaction de drag conservée partout.

## Le problème

Le H1 « Accueil » est **redondant** (la barre d'onglets le dit déjà) et il pousse
la carte du solde vers le bas : la carte se colle au titre, et le graphe perd de
la largeur et de la hauteur utiles. Les quatre idées suppriment le grand titre
(titre inline) et donnent la priorité visuelle au solde.

## Idée 1 — « Le solde est le titre » ⭐ recommandée

Le solde prend le rôle du H1 : 62 pt, en haut du contenu, avec « 7 repas » en
pastille. Le graphe passe **pleine largeur**, bord à bord, juste en dessous.
Le sélecteur de période devient un segmented natif sous le graphe.

- **Pourquoi ça marche** : c'est le pattern de l'app Bourse d'Apple — le chiffre
  est la hiérarchie, le graphe est sa donnée. Le graphe gagne ~40 pt de largeur,
  donc plus lisible, et le drag a plus de surface.
- **Ce qu'on perd** : le titre « Accueil » (déjà dans la tab bar).

## Idée 2 — « Le graphe derrière le solde »

Le solde et le graphe deviennent **un seul objet** : le graphe occupe le haut de
l'écran, masqué par un dégradé, et le solde est posé dessus. On drague sur toute
la zone.

- **Pourquoi ça marche** : le plus immersif, le solde « baigne » dans ses données.
- **Le risque** : la lisibilité du chiffre dépend du graphe ; il faut un voile
  assez fort, et ça laisse moins de place au reste.

## Idée 3 — « La carte respire »

On garde la carte de verre, mais le H1 est remplacé par un salut
(« Bonjour Camille » + la date) et la carte gagne de l'air.

- **Pourquoi ça marche** : changement minimal, l'identité actuelle est conservée.
- **La limite** : la carte reste dense (solde + période + graphe + résumé dans un
  seul bloc), et le salut ajoute une ligne.

## Idée 4 — « Le bandeau compact »

Le solde tient sur une ligne (44 pt) avec « 7 repas » à droite, un **sparkline de
66 pt** pleine largeur sous lui, et la période passe dans un `Menu` de la barre
de navigation. L'historique remonte donc beaucoup plus haut.

- **Pourquoi ça marche** : c'est la vue la plus « opti » — on voit le solde, la
  tendance et le début de l'historique sans scroller.
- **La limite** : le graphe est plus petit, donc moins de place pour le drag
  précis ; le sélecteur de période est moins visible qu'un segmented.

## L'interaction conservée

Les quatre idées gardent l'animation de drag : le point suit le doigt, le solde
affiche la valeur au point touché, un retour haptique à chaque changement, et le
retour au solde courant au relâchement.

## Planche

`00-planche.png` : les quatre idées côte à côte.

## Recommandation

- **Idée 1** si tu veux la plus native et la plus solide : elle règle le problème
  à la racine et donne au graphe toute la largeur.
- **Idée 2** si tu veux le plus spectaculaire, en acceptant un peu de risque sur
  la lisibilité.
- **Idée 4** si tu veux la vue la plus dense en information.
- **Idée 3** si tu veux le changement minimal.

Un mix est possible : idée 1 avec le solde posé sur le graphe (idée 2), ou idée 4
avec un segmented compact au lieu du menu.
