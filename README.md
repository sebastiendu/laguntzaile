# Système de gestion des affectations aux tours de travail


## Description fonctionnelle à destination des utilisateurs

Un administrateur crée les comptes utilisateurs des responsables sur une base de données.

Les responsables disposent d'une application de bureau pour plannifier un évenement à venir.

Cette application permet de définir la liste des postes et des tours et de charger un plan des lieux pour y placer les postes.

Elle permet aussi d'inscrire les premiers participants et de leur assigner des tours.

Par l'application, un responsable crée des lots de personnes à solliciter.

Dans son outil habituel de gestion de courriel (Thunderbird, le Mail Orange ou Gmail), il rédige le message de sollicitation et le poste à une adresse de courriel donnée par l'application.

Un robot reçoit ce message et le relaie vers les boites de courriel des personnes du lot.

Les personnes destinataires recoivent avec le message un lien cliquable qui les amène au formulaire d'inscription des participants, où les champs sont pré-remplis avec les informations déjà connues.

Les inscriptions de nouvelles personnes sont aussi possibles par ce même formulaire en ligne.

Les responsables assignent des tours de travail aux personnes inscrites.

Ils ont une vue en temps réel du taux de remplissage des postes.

Par un nouveau message de courriel dispatché par le robot, le responsable informe chaque participant de ses affectations et lui demande de suivre un nouveau lien cliquable pour les valider ou les refuser.

On peut répéter cet échange avec les personnes concernées au fur et à mesure des nouvelles affectations.

Les responsables suivent l'état des affectations.

L'application de gestion des responsables propose la génération des documents suivants :

 - Fiche de postes / Bénévoles par tours
 - Carte de bénévole / Inscription postes
 - Tableau de remplissage
 - Bénévoles sans tour de travail
 - Export général


## Description technique

Le système logiciel est centralisé sur une base PostgreSQL.

Les comptes utilisateurs sont gérés en utilisant un outil comme [Adminer](https://www.adminer.org/) ou en SQL directement.

Par exemple :

``` sql
create user seb in group administration;
```

Le gestionnaire des affectations est réalisée en Qt5 (QML/C++).

Le relai de courriel est implémenté en C++.

Les formulaires web sont générés en PHP et javascript.


## Installation

Voir [INSTALL.md](INSTALL.md).


## Licence d'utilisation

[GPLv3](LICENSE)
