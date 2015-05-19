begin;


drop table if exists evenement, poste, tour, personne, disponibilite, affectation, lot, lot_personne, lot_affectation, evenement_du_systeme cascade;

create table evenement(
 id serial primary key,
 nom varchar not null,
 archive boolean not null default false,
 debut timestamp with time zone not null,
 fin timestamp with time zone not null,
 lieu varchar not null,
 plan xml, -- document SVG
 id_evenement_precedent int references evenement on delete set null,
 constraint "Le nom de l'évenement doit être renseigné" check (nom <> ''),
 constraint "Le début de l'évènement ne peut pas être après sa fin" check (debut <= fin)
);
create index on evenement(archive);
create index on evenement(debut);

create table poste(
 id serial primary key,
 id_evenement int references evenement on delete cascade,
 nom varchar not null,
 description text not null,
 posX decimal not null, -- ou polygone, à voir
 posY decimal not null,
 constraint "Le nom du poste doit être renseigné" check (nom <> '')
);

create table tour(
 id serial primary key,
 id_poste int references poste on delete cascade,
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
create index on personne(lower(nom));
create index on personne(lower(adresse));
create index on personne(lower(ville));
create index on personne(lower(email));
create index on personne(lower(domicile));
create index on personne(lower(portable));
create index on personne(lower(prenom));

create table disponibilite(
 id serial primary key,
 id_personne int not null references personne on delete cascade,
 id_evenement int not null references evenement on delete cascade,
 date_inscription timestamp,
 -- TODO: faut-il responsable boolean not null default false,
 jours_et_heures_dispo text not null,
 liste_amis text not null,
 type_poste text not null,
 commentaire text not null,
 statut varchar not null default 'proposee' check (statut in (
  'proposee', -- par le bénévole au responsable (candidature)
  'validee', -- par le responsable (le bénévole devient disponible)
  'rejetee' -- par le responsable
 ))
);
create index on disponibilite(date_inscription);
create index on disponibilite(statut);

create table affectation(
 id serial primary key,
 id_disponibilite int not null references disponibilite on delete cascade,
 id_tour int not null references tour on delete cascade,
 date_et_heure_proposee timestamp,
 statut varchar not null default 'possible' check (statut in (
  'possible', -- Tant qu'on a pas soumis
  'annulee', -- Par le responsable
  'validee', -- Forcée
  'proposee', -- Envoyé par mail
  'acceptee', -- Par le bénévole
  'rejetee' -- par le bénév
 )),
 -- TODO: faut-il responsable boolean not null default false,
 commentaire text not null
);
create index on affectation(statut);

create table lot(
 id serial primary key,
 titre varchar not null,
 date_de_creation timestamp not null default CURRENT_TIMESTAMP,
 cle int not null default ((2^31 - 1) * random())::integer,
 traite boolean not null default false,
 modele varchar,
 expediteur varchar
);
create index on lot(date_de_creation);
create index on lot(traite);

create table lot_personne(
 id_lot int not null references lot on delete cascade,
 id_personne int not null references personne on delete cascade,
 traite boolean not null default false,
 reussi boolean not null default false,
 primary key(id_lot, id_personne)
);
create index on lot_personne(traite);
create index on lot_personne(reussi);

create table lot_affectation(
 id_lot int not null references lot on delete cascade,
 id_affectation int not null references affectation on delete cascade,
 traite boolean not null default false,
 reussi boolean not null default false,
 primary key(id_lot, id_affectation)
);
create index on lot_affectation(traite);
create index on lot_affectation(reussi);

create table evenement_du_systeme(
 id serial primary key,
 date_et_heure timestamp not null default CURRENT_TIMESTAMP,
 id_affectation int references affectation on delete set null,
 id_evenement int references evenement on delete set null,
 id_personne int references personne on delete set null,
 id_poste int references poste on delete set null,
 id_tour int references tour on delete set null,
 id_disponibilite int references disponibilite on delete set null,
 action varchar not null,
 constraint "Une action est requise sur chaque ligne du log" check (action <> '')
);
create index on evenement_du_systeme(action);
end;
