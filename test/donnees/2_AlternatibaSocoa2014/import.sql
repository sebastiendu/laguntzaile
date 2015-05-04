create temporary table import_personne(
	ref varchar not null primary key,
	nom varchar not null,
	prenom varchar not null,
	email varchar not null,
	portable varchar not null
);
\copy import_personne from 'personne.csv' (format csv, header, null 'null');
update import_personne set email='sdcns@sdcs.com' where portable = '' and email = '';
create temporary table import_poste(
	nom varchar not null,
	description varchar not null,
	ref varchar not null primary key,
	lieu varchar not null
);
\copy import_poste from 'poste.csv' (format csv, header, null 'null');
create temporary table import_tour(
	ref varchar not null primary key,
	debut time not null,
	fin time not null,
	notes varchar not null,
	max varchar not null default 100,
	refposte varchar not null,
	rdv varchar not null
);
\copy import_tour from 'tour.csv' (format csv, header, null 'null');
update import_tour set max='100' where max='';
update import_tour set fin='23:59:00' where fin < debut;
create temporary table import_affectation(
	refpersonne varchar not null,
	reftour varchar not null
);
\copy import_affectation from 'affectation.csv' (format csv, header, null 'null');

insert into evenement(id, nom, debut, fin, lieu) values
(2, 'Alternatiba Socoa 2014', '2014-10-05 06:00:00', '2014-10-06 00:00:00', 'Ciboure');

alter table personne add column ref varchar;
insert into personne
(nom, prenom, adresse, code_postal, ville, portable, domicile, email, date_naissance, profession, competences, langues, commentaire, avatar, ref)
select nom,prenom,'','','',portable,'',email,null,'','','','','',ref
from import_personne;

alter table poste add column ref varchar;
insert into poste(id_evenement, posX, posY, nom, description, ref)
select 2,random(),random(),nom,lieu,ref
from import_poste;

alter table tour add column ref varchar;
insert into tour (id_poste, debut, fin, min, max, ref)
select
 poste.id,
 date '2014-10-05' + debut,
 date '2014-10-05' + fin,
 1,
 cast(max as integer),
 import_tour.ref
from
 import_tour join poste on refposte = poste.ref;

insert into disponibilite
(id_personne, id_evenement, date_inscription, jours_et_heures_dispo, liste_amis, type_poste, commentaire, statut)
select id, 2, '2014-08-01', '', '', '', '', 'validee'
from personne;

insert into affectation (id_disponibilite, id_tour, date_et_heure_proposee, statut, commentaire)
 select disponibilite.id, tour.id, '2014-09-01', 'acceptee', ''
 from disponibilite
  join personne on id_personne = personne.id
  join import_affectation on refpersonne = personne.ref
  join tour on reftour = tour.ref;

alter table personne drop column ref;
alter table poste drop column ref;
alter table tour drop column ref;
