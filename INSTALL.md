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
# vous devriez pouvoir créer d'autres rôles
createuser -P seb

# Créer une fois pour toutes la base de données laguntzaile dont le
# propriétaire sera l'utilisateur "seb" (remplacez seb par votre nom
# d'utilisateur)
createdb -O seb laguntzaile

# redevenir root
exit

# redevenir soi-même
exit
```

Après, deux options, au choix :

1. Population de la base avec des données de test

```bash
# Créer la base en local et en générer un dump
make dump.sql.gz
```

2. Création des tables et des vues sans les données

```
psql -f base/structure.sql laguntzaile
psql -f base/vues.sql laguntzaile
psql -f base/roles_et_permissions.sql laguntzaile
```

Enfin, pour tester (optionnel) :

```Bash
# Rentrer dans la base pour accéder aux données
psql laguntzaile
```

```SqlPostgresql
-- taper une requête
select * from evenement;

-- pour apprendre à se servir de psql
help
```


# Installation de l'environement de développement Qt

L'environnement de développement Qt5 est empaqueté dans Debian 8 (Jessie), mais il lui manque un meta-paquet qui dépendrait de tous les paquets requis.

```Bash
apt-get install g++ qtcreator $(aptitude -F %p search '?source-package(qt.*-opensource-src) !~ri386 !~i')
```
