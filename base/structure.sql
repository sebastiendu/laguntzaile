begin;


drop table if exists evenement, poste, tour, personne, disponibilite, affectation, evenement_du_systeme cascade;
drop type if exists statut_disponibilite, statut_affectation;

create table evenement(
 id serial primary key,
 nom varchar not null,
 archive boolean not null default false,
 debut timestamp with time zone not null,
 fin timestamp with time zone not null,
 lieu varchar not null,
 plan text, -- document SVG
 id_evenement_precedent int references evenement,
 constraint "Le nom de l'évenement doit être renseigné" check (nom <> ''),
 constraint "Le début de l'évènement ne peut pas être après sa fin" check (debut <= fin)
);
create index on evenement(archive);
create index on evenement(debut);

create table poste(
 id serial primary key,
 id_evenement int references evenement,
 nom varchar not null,
 description text not null,
 position point not null, -- ou polygone, à voir
 constraint "Le nom du poste doit être renseigné" check (nom <> '')
);

create table tour(
 id serial primary key,
 id_poste int references poste,
 debut timestamp with time zone not null,
 fin timestamp with time zone not null,
 min int not null,
 max int not null,
 constraint "Le nombre minimum doit être positif" check (min > 0),
 constraint "Le nombre minimum ne doit pas dépasser le maximum" check (min <= max),
 constraint "Le début du tour ne peut pas être après sa fin" check (debut <= fin));
create index on tour(debut);
create index on tour(fin);
create index on tour(min);
create index on tour(max);

create table personne(
 id serial primary key,
 nom varchar not null,
 prenom varchar not null,
 adresse varchar not null,
 code_postal varchar not null,
 ville varchar not null,
 portable varchar not null,
 domicile varchar not null,
 email varchar not null,
 date_naissance date,
 profession varchar not null,
 competences varchar not null,
 avatar varchar not null, -- ?
 langues varchar not null,
 commentaire varchar not null,
 constraint "Le nom de la personne doit être renseigné" check (nom <> ''),
 constraint "Il faut un moyen de contact (email ou téléphone)" check (email <> '' or domicile <> '' or portable <> '')
);
create index on personne(nom);
create index on personne(prenom);
create index on personne(code_postal);
create index on personne(ville);
create index on personne(portable);
create index on personne(domicile);
create index on personne(email);
create index on personne(date_naissance);

create type statut_disponibilite AS enum (
 'proposee',
 'validee',
 'rejetee'
);
create table disponibilite(
 id serial primary key,
 id_personne int not null references personne,
 id_evenement int not null references evenement,
 date_inscription date,
 -- TODO: faut-il responsable boolean not null default false,
 jours_et_heures_dispo text not null,
 liste_amis text not null,
 type_poste text not null,
 commentaire text not null,
 statut statut_disponibilite not null default 'proposee'
);
create index on disponibilite(date_inscription);
create index on disponibilite(statut);

create type statut_affectation AS enum (
 'possible',
 'annulee',
 'validee',
 'proposee',
 'acceptee',
 'rejetee'
);
create table affectation(
 id serial primary key,
 id_disponibilite int not null references disponibilite,
 id_tour int not null references tour,
 date_et_heure_proposee timestamp,
 statut statut_affectation not null default 'possible',
 -- TODO: faut-il responsable boolean not null default false,
 commentaire text not null
);
create index on affectation(statut);

create table evenement_du_systeme(
 id serial primary key,
 date_et_heure timestamp not null,
 id_affectation int references affectation,
 id_evenement int references evenement,
 id_personne int references personne,
 id_poste int references poste,
 id_tour int references tour,
 id_disponibilite int references disponibilite,
 action varchar not null,
 constraint "Une action est requise sur chaque ligne du log" check (action <> '')
);
create index on evenement_du_systeme(action);
end;
