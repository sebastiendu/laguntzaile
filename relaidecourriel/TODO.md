Fournir un fichier de configuration par défaut dans le paquet debian

Permettre de préciser un fichier de configuration alternatif dans /etc/aliases :
/etc/aliases : lurrama: |/usr/local/sbin/robot /etc/relaidecourriel/lurrama2016.ini

Poster à SENDER la liste des adresses, nom, prenom, ville et identifiant des destinataires en erreur, le nombre d'envois faits (réussis et ratés), un rappel des sujet et date du message original

Substitution par la liste des affectations :
 - formater les dates et les heures de début et de fin du tour
 - sécuriser les caractères dans les noms des postes dans le HTML

Interpréter les bounces : https://pythonhosted.org/flufl.bounce/docs/using.html

Vérifier que le message contient bien _AFFECTATIONS_ pour un lot de disponibilités ; sinon retourner `EX_PROTOCOL` ou `EX_DATAERR`

Soigner les entêtes du message : mettre un list-id et de quoi se désabonner (regarder ce que mailman fait)
