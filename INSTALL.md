# Installation de la base de données sous Debian

Voici les commandes à taper pour installer votre instance de la base de données.

```bash
# devenir root
su -

# installer le SGBDR et wget (au cas où on ne l'aurait pas encore)
apt-get install postgresql wget

# toujours en tant que root, devenir l'administrateur du SGBD
su - postgres


# créer un compte utilisateur (pour l'accès à la base)
# remplacez seb par votre nom d'utilisateur, ci-dessous.
# createuser vous demandera de saisir un mot de passe
createuser -P seb

# Créer une fois pour toutes la base de données laguntzaile dont le
# propriétaire sera l'utilisateur "seb" (remplacez seb par votre nom
# d'utilisateur)
createdb -O seb laguntzaile

# redevenir root
exit

# redevenir soi-même
exit

# créer les tables et les vues dans la base laguntzaile
psql -f data/structure.sql laguntzaile
psql -f data/vues.sql laguntzaile
```

Ensuite pour tester (optionnel) :

```bash
# Rentrer dans la base pour accéder aux données
psql laguntzaile
```

```postgresql
# taper une requête
select * from evenement;

# pour apprendre à se servir de psql
help
```
