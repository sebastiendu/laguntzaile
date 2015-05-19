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

create or replace function bytea_import(p_path text, p_result out bytea)
 language plpgsql as $$
 declare
  l_oid oid;
  r record;
 begin
  p_result := '';
  select lo_import(p_path) into l_oid;
  for r in (
   select data from pg_largeobject
    where loid = l_oid
    order by pageno
  ) loop
   p_result = p_result || r.data;
  end loop;
  perform lo_unlink(l_oid);
end;$$;
\set pwd `pwd`
insert into evenement(id, nom, debut, fin, lieu, plan) values
(2, 'Alternatiba Socoa 2014', '2014-10-05 06:00:00', '2014-10-06 00:00:00', 'Ciboure',
 convert_from(bytea_import(:'pwd'||'/'||'plan.svg'), 'utf8')::xml
);
drop function bytea_import(text);

alter table personne add column ref varchar;
insert into personne
(nom, prenom, adresse, code_postal, ville, portable, domicile, email, date_naissance, profession, competences, langues, commentaire, avatar, ref)
select nom,prenom,'','','',portable,'',email,null,'','','','','',ref
from import_personne;

alter table poste add column ref varchar;
insert into poste(id_evenement, posX, posY, nom, description, ref)
select 2,0,0,nom,lieu,ref
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

create temporary table import_position (nom varchar not null primary key, x decimal not null, y decimal not null);
\copy import_position from 'positions' (format text);
update poste set
 posX = (select x from import_position where nom = poste.nom),
 posY = (select y from import_position where nom = poste.nom)
where id_evenement=2;

update disponibilite
set statut=case (random() * 3)::integer
 when 0 then 'proposee'
 when 1 then 'rejetee'
 else 'validee' end
where id not in (select id_disponibilite from affectation);

update affectation
set statut=case (random() * 10)::integer
 when 0 then 'possible'
 when 1 then 'annulee'
 when 2 then 'validee'
 when 3 then 'proposee'
 when 4 then 'rejetee'
 else 'acceptee' end;
