create temporary table import(
	nom varchar not null,
	prenom varchar not null,
	adresse varchar not null,
	cp varchar not null,
	ville varchar not null,
	email varchar not null,
	domicile varchar not null,
	portable varchar not null,
	age varchar not null,
	profession varchar not null,
	competences varchar not null,
	bascophone varchar not null,
	RBPF varchar not null,
	divers varchar not null,
	montagejours varchar not null,
	demontagejours varchar not null,
	vbar1 varchar not null,vbar2goxoko varchar not null,vbrigadaberde varchar not null,vcontrolebillet varchar not null,ventrees varchar not null,vespacebenevoles varchar not null,vespaceenfants varchar not null,vfrites varchar not null,vinfo varchar not null,vplatsdecotes varchar not null,vprepazikiro varchar not null,vsecurite varchar not null,vtalo varchar not null,vtxartel1 varchar not null,vtxartel2 varchar not null,vvaisselle varchar not null,vvestiaire varchar not null,vvolante1egunez varchar not null,vvolante2gauez varchar not null,
	sbar1 varchar not null,sbar2goxoko varchar not null,sbasoberri varchar not null,sbrigadaberde varchar not null,scontrolebillet varchar not null,sentrees varchar not null,sespacebenevoles varchar not null,sespaceenfants varchar not null,sfrites varchar not null,sinfo varchar not null,splatsdecotes varchar not null,ssecurite varchar not null,sservicerestaurant varchar not null,stalo varchar not null,stxartel1 varchar not null,stxartel2 varchar not null,svaisselle varchar not null,svestiaire varchar not null,svolante1egunez varchar not null,svolante2gauez varchar not null,
	daidecuisine varchar not null,dbar1 varchar not null,dbar2goxoko varchar not null,dbasoberri varchar not null,dbrigadaberde varchar not null,dcontrolebillet varchar not null,ddebarrassagetri varchar not null,ddemontagemarchefermier varchar not null,dentrees varchar not null,despacebenevoles varchar not null,despaceenfants varchar not null,dfrites varchar not null,dinfo varchar not null,dinstallation varchar not null,dpeseejambon varchar not null,dplatsdecotes varchar not null,dsecurite varchar not null,dservice varchar not null,dsystemeticket varchar not null,dtalo varchar not null,dtxartel1 varchar not null,dtxartel2 varchar not null,dvaisselle varchar not null,dvestiaire varchar not null,dvolante1egunez varchar not null,dvolante2gauez varchar not null
);

\copy import from '2014.csv' (format csv, header, null 'null');

update import set domicile = '05 59 37 95 72' where portable='' and domicile='' and email='';
update import set nom = 'Quelqu''un' where nom='';

create function extraire_date_debut (date, varchar) returns timestamp as $$
 select
 $1
 + (
  cast(
   '0' || substring($2 from '%: #"%#"h% /%' for '#')
   as integer
  )
  * interval '1 hour'
 )
 + (
  cast(
   '0' || substring($2 from '%: %h#"%#" /%' for '#')
   as integer
  )
  * interval '1 minute'
 );
$$
language sql
immutable
returns null on null input;

create function extraire_date_fin (date, varchar) returns timestamp as $$
 select
 $1
 + (
  cast(
   '0' || substring($2 from '%/ #"%#"h%' for '#')
   as integer
  )
  * interval '1 hour'
 )
 + (
  cast(
   '0' || substring($2 from '%/ %h#"%#"' for '#')
   as integer
  )
  * interval '1 minute'
 );
$$
language sql
immutable
returns null on null input;

create temporary table poste_colonne_jour(poste varchar, colonne varchar, jour date);
insert into poste_colonne_jour values
('Bar 1', 'vbar1', '2014-11-14'),
('Bar 1', 'sbar1', '2014-11-15'),
('Bar 1', 'dbar1', '2014-11-16'),
('Bar 2 Goxoko', 'vbar2goxoko', '2014-11-14'),
('Bar 2 Goxoko', 'sbar2goxoko', '2014-11-15'),
('Bar 2 Goxoko', 'dbar2goxoko', '2014-11-16'),
('Brigada berde','vbrigadaberde', '2014-11-14'),
('Brigada berde','sbrigadaberde', '2014-11-15'),
('Brigada berde','dbrigadaberde', '2014-11-16'),
('Contrôle billet','vcontrolebillet', '2014-11-14'),
('Contrôle billet','scontrolebillet', '2014-11-15'),
('Contrôle billet','dcontrolebillet', '2014-11-16'),
('Entrées','ventrees', '2014-11-14'),
('Entrées','sentrees', '2014-11-15'),
('Entrées','dentrees', '2014-11-16'),
('Espace bénévoles','vespacebenevoles', '2014-11-14'),
('Espace bénévoles','sespacebenevoles', '2014-11-15'),
('Espace bénévoles','despacebenevoles', '2014-11-16'),
('Espace enfants','vespaceenfants', '2014-11-14'),
('Espace enfants','sespaceenfants', '2014-11-15'),
('Espace enfants','despaceenfants', '2014-11-16'),
('Frites','vfrites', '2014-11-14'),
('Frites','sfrites', '2014-11-15'),
('Frites','dfrites', '2014-11-16'),
('Info','vinfo', '2014-11-14'),
('Info','sinfo', '2014-11-15'),
('Info','dinfo', '2014-11-16'),
('Plats de côtes','vplatsdecotes', '2014-11-14'),
('Plats de côtes','splatsdecotes', '2014-11-15'),
('Plats de côtes','dplatsdecotes', '2014-11-16'),
('Prepara zikiro','vprepazikiro', '2014-11-14'),
('Sécurité','vsecurite','2014-11-14'),
('Sécurité','ssecurite','2014-11-15'),
('Sécurité','dsecurite','2014-11-16'),
('Talo','vtalo', '2014-11-14'),
('Talo','stalo', '2014-11-15'),
('Talo','dtalo', '2014-11-16'),
('Txartel 1','vtxartel1','2014-11-14'),
('Txartel 1','stxartel1','2014-11-15'),
('Txartel 1','dtxartel1','2014-11-16'),
('Txartel 2','vtxartel2','2014-11-14'),
('Txartel 2','stxartel2','2014-11-15'),
('Txartel 2','dtxartel2','2014-11-16'),
('Vaisselle','vvaisselle', '2014-11-14'),
('Vaisselle','svaisselle', '2014-11-15'),
('Vaisselle','dvaisselle', '2014-11-16'),
('Vestiaire','vvestiaire', '2014-11-14'),
('Vestiaire','svestiaire', '2014-11-15'),
('Vestiaire','dvestiaire', '2014-11-16'),
('Volante 1 Egunez','vvolante1egunez', '2014-11-14'),
('Volante 1 Egunez','svolante1egunez', '2014-11-15'),
('Volante 1 Egunez','dvolante1egunez', '2014-11-16'),
('Volante 2 Gauez','vvolante2gauez', '2014-11-14'),
('Volante 2 Gauez','svolante2gauez', '2014-11-15'),
('Volante 2 Gauez','dvolante2gauez', '2014-11-16'),
('Baso berri','sbasoberri','2014-11-15'),
('Baso berri','dbasoberri','2014-11-16'),
('Service restaurant','sservicerestaurant','2014-11-15'),
('Aide cuisine','daidecuisine', '2014-11-16'),
('Débarrassage tri','ddebarrassagetri', '2014-11-16'),
('Démontage marché fermier','ddemontagemarchefermier','2014-11-16'),
('Installation','dinstallation','2014-11-16'),
('Pesée jambon','dpeseejambon','2014-11-16'),
('Système ticket','dsystemeticket', '2014-11-16');
create temporary table import_tour(poste varchar, debut timestamp, fin timestamp, nombre integer);

create function remplir_import_tour() returns integer as $$
declare
 pcj record;
begin
 for pcj in select * from poste_colonne_jour loop
  -- raise notice 'poste %, colonne %', pcj.poste, quote_ident(pcj.colonne);
  execute 'insert into import_tour
   select ' || quote_literal(pcj.poste) || ',
   extraire_date_debut('||quote_literal(pcj.jour)||','||quote_ident(pcj.colonne)||'),
   coalesce(
    extraire_date_fin('||quote_literal(pcj.jour)||','||quote_ident(pcj.colonne)||'),
    date ' || quote_literal(pcj.jour) || ' + interval ''1 day''
   ),
   count(*)
   from import
   where '||quote_ident(pcj.colonne)||'<>'||quote_literal('')||'
   group by ' || quote_ident(pcj.colonne);
 end loop;
 execute 'update import_tour set fin = fin + interval ''1 day'' where fin < debut';
 return 1;
end;
$$ language plpgsql;

select remplir_import_tour();

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
(1, 'Lurrama 2014', '2014-11-12 09:00:00', '2014-11-17 17:00:00', 'Biarritz',
 convert_from(bytea_import(:'pwd'||'/'||'plan.svg'), 'utf8')::xml
);
drop function bytea_import(text);

insert into poste(id_evenement, posX, posY, nom, description)
values
(1, 0, 0, 'Montage', ''), -- id = 1
(1, 0, 0, 'Démontage', ''); -- id = 2

insert into poste(id_evenement, posX, posY, nom, description)
select 1,0,0,poste,''
from import_tour
group by poste;

insert into tour (id_poste, debut, fin, min, max)
values
(1, '2014-11-12 09:00', '2014-11-12 17:00', 60, 70),
(1, '2014-11-13 09:00', '2014-11-13 17:00', 15, 25),
(2, '2014-11-17 09:00', '2014-11-17 17:00', 60, 70);

insert into tour (id_poste, debut, fin, min, max)
select
 poste.id, debut, fin, nombre, nombre
from
 import_tour join poste on poste = nom;

insert into personne
(nom, prenom, adresse, code_postal, ville, portable, domicile, email, date_naissance, profession, competences, langues, commentaire, avatar)
select nom, prenom, adresse, cp, ville, domicile, portable, email,
case when age = '' then null else
 date '2014-10-01' - (cast('0'||age as integer) * interval '1 year')
end
, profession, competences, case bascophone when 'Oui' then 'eu fr' else 'fr' end, divers, ''
from import;

insert into disponibilite
(id_personne, id_evenement, date_inscription, jours_et_heures_dispo, liste_amis, type_poste, commentaire, statut)
select id, 1, '2014-09-01', '', '', '', '', 'validee'
from personne;

insert into affectation (id_disponibilite, id_tour, date_et_heure_proposee, statut, commentaire)
 select disponibilite.id, tour.id, '2014-10-01', 'acceptee', ''
 from disponibilite
  join personne on id_personne = personne.id
  join import using (nom, prenom, ville),
 tour join poste on poste.id = tour.id_poste
 where poste.nom='Montage'
  and tour.debut = '2014-11-12 09:00'
  and import.montagejours like 'Mercredi 12%';

insert into affectation (id_disponibilite, id_tour, date_et_heure_proposee, statut, commentaire)
 select disponibilite.id, tour.id, '2014-10-01', 'acceptee', ''
 from disponibilite
  join personne on id_personne = personne.id
  join import using (nom, prenom, ville),
 tour join poste on poste.id = tour.id_poste
 where poste.nom='Montage'
  and tour.debut = '2014-11-13 09:00'
  and import.montagejours like '%Jeudi 13%';

insert into affectation (id_disponibilite, id_tour, date_et_heure_proposee, statut, commentaire)
 select disponibilite.id, tour.id, '2014-10-01', 'acceptee', ''
 from disponibilite
  join personne on id_personne = personne.id
  join import using (nom, prenom, ville),
 tour join poste on poste.id = tour.id_poste
 where poste.nom='Démontage'
  and tour.debut = '2014-11-17 09:00'
  and import.demontagejours like '%Lundi 17%';

create function remplir_affectation() returns integer as $$
declare
 pcj record;
begin
 for pcj in select * from poste_colonne_jour loop
  execute 'insert into affectation (id_disponibilite, id_tour, date_et_heure_proposee, statut, commentaire)
 select
  disponibilite.id,
  tour.id,
  '||quote_literal('2014-10-01')||',
  '||quote_literal('acceptee')||',
  '||quote_literal('')||'
 from disponibilite
  join personne on id_personne = personne.id
  join import using (nom, prenom, ville),
 tour join poste on poste.id = tour.id_poste
 where poste.nom='||quote_literal(pcj.poste)||'
  and extraire_date_debut('||quote_literal(pcj.jour)||','||quote_ident(pcj.colonne)||') = tour.debut
  and date_trunc(' || quote_literal('day') || ', tour.debut) = '||quote_literal(pcj.jour);
 end loop;
 return 1;
end;
$$ language plpgsql;

select remplir_affectation();

drop function remplir_affectation();
drop function remplir_import_tour();
drop function extraire_date_debut(date, varchar);
drop function extraire_date_fin(date, varchar);

create temporary table import_position (nom varchar not null primary key, x decimal not null, y decimal not null);
\copy import_position from 'positions' (format text);
update poste set
 posX = (select x from import_position where nom = poste.nom),
 posY = (select y from import_position where nom = poste.nom)
where id_evenement=1;

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
