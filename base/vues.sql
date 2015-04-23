-- Gestion des événements

create or replace view liste_des_evenements as
select id, nom, debut, fin, lieu, archive
from evenement
order by debut desc;

create or replace view statistiques_evenement as
select id_evenement,
 count(distinct id_poste) as nombre_postes,
 count(distinct tour.id)  as nombre_tours,
 count(*) as nombre_affectations
from poste
 join tour on id_poste = poste.id
 join affectation on id_tour = tour.id
group by id_evenement;


-- Sortie des états

create or replace view fiche_de_poste_benevoles_par_tour as
select
 poste.id_evenement,
 evenement.nom as nom_evenement,
 evenement.debut as debut_evenement,
 evenement.fin as fin_evenement,
 evenement.lieu as lieu_evenement,
 id_disponibilite,
 id_poste,
 poste.nom as nom_poste,
 poste.description as description_poste,
 poste.posX as posX_poste,
 poste.posY as posY_poste,
 id_tour,
 tour.debut as debut_tour,
 tour.fin as fin_tour,
 tour.min,
 tour.max,
 id_personne,
 upper(personne.nom) as nom_personne,
 initcap(personne.prenom) as prenom_personne,
 personne.ville,
 personne.portable
from affectation
 join tour on id_tour = tour.id
  join poste on id_poste = poste.id
   join evenement on poste.id_evenement = evenement.id
 join disponibilite on id_disponibilite = disponibilite.id
  join personne on personne.id = id_personne
order by id_evenement, poste.nom, tour.debut, tour.fin, personne.nom, personne.prenom;

create or replace view carte_de_benevole_inscriptions_postes as
select
 poste.id_evenement,
 evenement.nom as nom_evenement,
 evenement.debut as debut_evenement,
 evenement.fin as fin_evenement,
 evenement.lieu as lieu_evenement,
 id_disponibilite,
 id_personne,
 upper(personne.nom) as nom_personne,
 initcap(personne.prenom) as prenom_personne,
 -- TODO : Benevole ou Responsable
 personne.ville,
 personne.portable,
 personne.domicile,
 id_tour,
 tour.debut as debut_tour,
 tour.fin as fin_tour,
 id_poste,
 poste.nom as nom_poste
from affectation
 join tour on id_tour = tour.id
  join poste on id_poste = poste.id
   join evenement on poste.id_evenement = evenement.id
 join disponibilite on id_disponibilite = disponibilite.id
  join personne on id_personne = personne.id
order by poste.id_evenement, personne.nom, personne.prenom, tour.debut, tour.fin;

-- TODO : create or replace view liste_montage
-- TODO : create or replace view liste_demontage

create or replace view tableau_de_remplissage as
select
 poste.id_evenement,
 evenement.nom as nom_evenement,
 evenement.debut as debut_evenement,
 evenement.fin as fin_evenement,
 evenement.lieu as lieu_evenement,
 id_poste,
 poste.nom as nom_poste,
 id_tour,
 tour.debut as debut_tour,
 tour.fin as fin_tour,
 tour.min,
 tour.max,
 count(*) as nombre_affectations,
 string_agg(
  concat_ws(' ',
   upper(personne.nom),
   initcap(personne.prenom)
  ),
  ', '
 ) as liste_personnes
-- TODO : nom du responsable (leur demander d'abord si "responsable" fait référence au poste, au tour ou à la personne (disponibilite)
from affectation
 join tour on id_tour = tour.id
  join poste on id_poste = poste.id
   join evenement on poste.id_evenement = evenement.id
 join disponibilite on id_disponibilite = disponibilite.id
  join personne on id_personne = personne.id
group by poste.id_evenement, evenement.nom, evenement.debut, evenement.fin, evenement.lieu, id_poste, poste.nom, id_tour, tour.debut, tour.fin, tour.min, tour.max
order by poste.id_evenement, tour.debut, tour.fin; -- FIXME : order by personne.nom, personne.prenom

create or replace view fiches_a_probleme as
select
 id_evenement,
 evenement.nom as nom_evenement,
 evenement.debut as debut_evenement,
 evenement.fin as fin_evenement,
 evenement.lieu as lieu_evenement,
 id_personne,
 upper(personne.nom) as nom_personne,
 initcap(personne.prenom) as prenom_personne,
 adresse,
 code_postal,
 ville,
 portable,
 domicile,
 email,
 date_naissance,
 profession,
 competences,
 langues,
 personne.commentaire
 date_inscription,
 liste_amis,
 type_poste,
 disponibilite.commentaire as commentaire_disponibilite,
 statut
from disponibilite
 join evenement on id_evenement = evenement.id
 join personne on id_personne = personne.id
where disponibilite.id not in (
 select id_disponibilite
 from affectation
);

create or replace view export_general_tours as
select
 poste.id_evenement,
 evenement.nom as nom_evenement,
 evenement.debut as debut_evenement,
 evenement.fin as fin_evenement,
 evenement.lieu as lieu_evenement,
 date_trunc('day', tour.debut) as jour,
 id_poste,
 poste.nom as nom_poste,
 poste.description as description_poste,
 poste.posX as posX_poste,
 poste.posY as posY_poste,
 id_tour,
 tour.debut as debut_tour,
 tour.fin as fin_tour,
 tour.min,
 tour.max,
 affectation.id as id_affectation,
 affectation.statut as statut_affectation,
 affectation.commentaire
 id_personne,
 upper(personne.nom) as nom_personne,
 initcap(personne.prenom) as prenom_personne,
 adresse,
 code_postal,
 ville,
 portable,
 domicile,
 email,
 date_naissance,
 profession,
 competences,
 langues,
 personne.commentaire as commentaire_personne,
 disponibilite.id as id_disponibilite,
 date_inscription,
 liste_amis,
 type_poste,
 disponibilite.commentaire as commentaire_disponibilite,
 disponibilite.statut
from affectation
 join tour on id_tour = tour.id
  join poste on id_poste = poste.id
   join evenement on poste.id_evenement = evenement.id
 join disponibilite on id_disponibilite = disponibilite.id
  join personne on id_personne = personne.id
order by poste.id_evenement, tour.debut, tour.fin, poste.nom, personne.nom, personne.prenom, personne.ville;

create or replace view export_general_personnes as
select
 disponibilite.id_evenement,
 evenement.nom as nom_evenement,
 evenement.debut as debut_evenement,
 evenement.fin as fin_evenement,
 evenement.lieu as lieu_evenement,
 id_personne,
 upper(personne.nom) as nom_personne,
 initcap(personne.prenom) as prenom_personne,
 adresse,
 code_postal,
 ville,
 portable,
 domicile,
 email,
 date_naissance,
 profession,
 competences,
 langues,
 personne.commentaire as commentaire_personne,
 disponibilite.id as id_disponibilite,
 date_inscription,
 liste_amis,
 type_poste,
 disponibilite.commentaire as commentaire_disponibilite,
 disponibilite.statut as statut_disponibilite,
 affectation.id as id_affectation,
 affectation.statut as statut_affectation,
 affectation.commentaire,
 date_trunc('day', tour.debut) as jour,
 id_poste,
 poste.nom as nom_poste,
 poste.description as description_poste,
 poste.posX as posX_poste,
 poste.posY as posY_poste,
 id_tour,
 tour.debut as debut_tour,
 tour.fin as fin_tour,
 tour.min,
 tour.max
from disponibilite
 join evenement on disponibilite.id_evenement = evenement.id
 join personne on id_personne = personne.id
 left join affectation on id_disponibilite = disponibilite.id
  left join tour on id_tour = tour.id
   left join poste on id_poste = poste.id
order by disponibilite.id_evenement, personne.nom, personne.prenom, personne.ville, tour.debut, tour.fin, poste.nom;


-- Gestion des postes et tours

create or replace view postes as -- utile ?
select id, id_evenement, nom, description, posX, posY
from poste
order by id_evenement, nom;

create or replace view statistiques_postes as
select id_poste,
 count(distinct tour.id)  as nombre_tours,
 count(*) as nombre_affectations
from tour
 join affectation on id_tour = tour.id
group by id_poste;

create or replace view tours as -- utile ?
select id, id_poste, debut, fin, min, max
from tour
order by id_poste, debut, fin;

create or replace view horaires_nouveau_tour as
-- fin du plus recent tour ou debut evenement
select
 id_poste,
 coalesce(max(tour.fin), evenement.fin) as debut,
 coalesce(max(tour.fin), evenement.fin) + interval '4 hours' as fin
from poste
 join evenement on id_evenement = evenement.id
 left join tour on id_poste = poste.id
group by id_poste, evenement.fin;

create or replace view statistiques_tour as
select id_tour,
 count(*) as nombre_affectations
from tour
 join affectation on id_tour = tour.id
group by id_tour;


-- Candidature d'un bénévole

create or replace view evenements_auxquels_peut_candidater as
select * from evenement
where not archive
 and now() < fin;


-- Messages de sollicitation

create or replace view nombre_de_benevoles as
select
 id_evenement,
 evenement.nom as nom_evenement,
 archive,
 evenement.debut,
 evenement.fin,
 lieu,
 id_evenement_precedent,
 count(distinct id_disponibilite) as nombre_de_benevoles
 from affectation
  join tour on id_tour = tour.id
   join poste on id_poste = poste.id
    join evenement on id_evenement = evenement.id
 group by id_evenement, evenement.nom, archive, evenement.debut, evenement.fin, lieu, id_evenement_precedent
 order by evenement.debut, evenement.fin;

-- TODO : Trouver une interface argonomique pour selectionner les anciens bénévoles,
-- et créer des enregistrements dans la table sollicitation.
-- TODO : réfléchir à la contruction de l'adresse email du reply-to et/ou Return-path.
-- TODO : réfléchir au filtre d'insertion de l'URL identifiant

-- TODO : réfléchir à la sécurité : une fois la fiche mise à jour, il ne faut plus que l'URL puisse être utilisée à nouveau (vérifier disponibilité.statut)


-- Candidature d'un bénévole sollicité

-- TODO : mettre à jour le statut de la sollicitation : soit acceptée, soit rejetée.
-- l'acceptation est suivie d'une mise à jour de l'enregistrement dans la table personne


-- Contrôle et modération des candidatures

create or replace view candidatures_en_attente as
select
 id_evenement,
 id_personne,
 upper(personne.nom) as nom_personne,
 initcap(personne.prenom) as prenom_personne,
 adresse,
 code_postal,
 ville,
 portable,
 domicile,
 email,
 date_naissance,
 profession,
 competences,
 avatar,
 langues,
 personne.commentaire as commentaire_personne,
 date_inscription,
 liste_amis,
 type_poste,
 disponibilite.commentaire as commentaire_disponibilite
from disponibilite
 join personne on id_personne = personne.id
-- where statut = 'validé_par_candidat' -- FIXME TODO : diagramme état-transition d'une disponibilité
order by id_evenement, date_inscription, personne.nom;

create or replace view personnes_doublons as -- repérage des doublons probables
 with iddoublon as (
  with correspondance as (
   select nouveau.id as idnouveau, existant.id as id,
    nouveau.nom <> '' and lower(nouveau.nom) = lower(existant.nom) as memenom,
    nouveau.adresse <> '' and lower(nouveau.adresse) = lower(existant.adresse) as memeadresse,
    coalesce(nouveau.ville = existant.ville, false) as memeville,
    nouveau.email <> '' and lower(nouveau.email) = lower(existant.email) as memeemail,
    nouveau.domicile <> '' and nouveau.domicile = existant.domicile as memedomicile,
    nouveau.portable <> '' and nouveau.portable = existant.portable as memeportable,
    coalesce(nouveau.prenom <> '' and lower(nouveau.prenom) = lower(existant.prenom), false) as memeprenom
   from personne nouveau, personne existant
  )
  select *, (
   3 * memenom::integer +
   2 * memeadresse::integer +
   1 * memeville::integer +
   3 * memeemail::integer +
   3 * memedomicile::integer +
   3 * memeportable::integer +
   1 * memeprenom::integer
  ) / 16.0 as score
  from correspondance
 )
 select *
 from iddoublon join personne using(id)
 where score > 0
 order by score desc, nom, prenom, ville;


-- Inscription directe d'un bénévole

-- Afficher toutes les personnes avec l'indication pour chacun de sa présence dans la table disponibilité pour cet évenement

create or replace view personnes_inscrite_ou_pas_encore as
select id_evenement, personne.id as id_personne, disponibilite.id as id_disponibilite, personne.nom as nom_personne, prenom, ville -- et peut-être tous les autres champs de personne
from personne left join disponibilite on id_personne = personne.id
order by id_evenement, personne.nom, prenom, ville;


-- Gestion des affectations

create or replace view benevoles_disponibles as
select
 id_evenement,
 disponibilite.id as id_disponibilite,
 id_personne,
 upper(personne.nom) as nom_personne,
 initcap(personne.prenom) as prenom_personne,
 personne.ville,
 count(*) as nombre_affectations
from disponibilite
 join personne on id_personne = personne.id
 left join affectation on id_disponibilite = disponibilite.id
-- where disponibilite.statut = 'valide' -- TODO : revoir les statuts d'une disponibilité
group by id_evenement, disponibilite.id, id_personne, personne.nom, personne.prenom, personne.ville
order by id_evenement, count(*) asc, personne.nom, personne.prenom, personne.ville;

create or replace view fiche_benevole as
select
 id_evenement,
 id_personne,
 disponibilite.id as id_disponibilite,
 date_inscription,
 liste_amis,
 type_poste,
 disponibilite.commentaire as commentaire_disponibilite,
 disponibilite.statut as statut_disponibilite,
 personne.nom,
 personne.prenom,
 adresse,
 code_postal,
 ville,
 portable,
 domicile,
 email,
 date_naissance,
 extract(year from age(date_naissance)) as age,
 profession,
 competences,
 avatar,
 langues,
 personne.commentaire as commentaire_personne
from disponibilite join personne on id_personne = personne.id;

-- Les autres informations utiles de la fiche de la personne disponibles sont
--  - les tours déjà affectés
--  - l'historique des échanges avec cette personne sur cet evenement
--  - la liste des autres évenements auxquels cette personne a participé
create or replace view tours_benevole as
select
id_disponibilite,
affectation.id as id_affectation,
id_tour,
date_et_heure_proposee,
affectation.statut as statut_affectation,
affectation.commentaire as commentaire_affectation,
id_poste,
debut,
fin,
min,
max,
poste.nom as nom_poste,
poste.description as description_poste,
poste.posX as posX_poste,
poste.posY as posY_poste
from disponibilite
 left join affectation on id_disponibilite = disponibilite.id
  left join tour on id_tour = tour.id
   left join poste on id_poste = poste.id
order by debut, fin, date_et_heure_proposee;

create or replace view historique_disponibilite as
select
 eds.id as id_evenement_du_systeme,
 eds.id_disponibilite,
 date_et_heure,
 id_affectation,
 eds.id_poste,
 eds.id_tour,
 action,
 debut, fin, min, max,
 nom, description, posX, posY
from evenement_du_systeme eds
 join disponibilite on id_disponibilite = disponibilite.id
 left join affectation on id_affectation = affectation.id
 left join tour on eds.id_tour = tour.id
 left join poste on eds.id_poste = poste.id
order by id_disponibilite, date_et_heure;

create or replace view evenements_benevole as
select
id_personne,
id_evenement,
nom,
debut,
fin,
lieu,
disponibilite.id as id_disponibilite
from disponibilite
 join evenement on id_evenement = evenement.id
order by id_personne, fin desc, debut desc;

-- Couleurs des tours(postes) en fonction de la disponibilité
-- Couleurs des disponibilités en fonction du tour

create or replace view taux_de_remplissage_tour as
with etat_tour as (
 select
  id_tour,
  min,
  max,
  debut,
  fin,
  coalesce(nombre_affectations, 0) as effectif,
  greatest(min - nombre_affectations, min) - greatest(nombre_affectations - max, 0) as besoin
 from tour
  left join statistiques_tour on id_tour = tour.id
)
select
 id_tour,
 min,
 max,
 debut,
 fin,
 effectif,
 besoin,
 case when besoin > 0 then besoin / min
      when besoin < 0 then besoin / max
      else 0 end as faim,
 effectif / ((min+max)/2) as taux
from etat_tour;

create or replace view compatibilite_tour_disponibilite as
with taux_de_compatibilite_entre_tours as (
 with ecart_entre_tours as (
  select
   t1.id as id_t1,
   t2.id as id_t2,
   greatest(t2.debut - t1.fin, t1.debut - t2.fin) as ecart
  from tour t1, tour t2
 )
 select
  id_t1,
  id_t2,
  case when ecart >= interval '4 hours' then 1
       when ecart <= interval '0' then -1
       else 0 end as taux -- FIXME : formule
 from ecart_entre_tours
)
select
 disponibilite.id as id_disponibilite,
 id_t1 as id_tour,
 coalesce(min(taux), 1) as compatibilite
from
 disponibilite
  left join affectation on id_disponibilite = disponibilite.id
   left join taux_de_compatibilite_entre_tours on id_t1 = id_tour
group by
 disponibilite.id,
 id_t1;

create or replace view personnes_tour as
select
 id_tour,
 id_disponibilite,
 id_personne,
 upper(personne.nom) as nom_personne,
 initcap(personne.prenom) as prenom_personne,
 personne.ville
from affectation
 join tour on id_tour = tour.id
 join disponibilite on id_disponibilite = disponibilite.id
  join personne on id_personne = personne.id
order by id_tour, personne.nom, personne.prenom, personne.ville;

create or replace view taux_de_remplissage_par_heure as
select
 date_trunc('hour', debut + (fin - debut)/2) as heure,
 avg(taux)
from
 taux_de_remplissage_tour
group by heure;


-- Demandes de validation des affectations

create or replace view affectations as -- TODO : trouver un meilleur nom
select
 poste.id_evenement,
 affectation.statut as statut_affectation,
 date_et_heure_proposee,
 affectation.id as id_affectation,
 id_disponibilite,
 id_personne,
 id_tour,
 id_poste,
 affectation.commentaire as commentaire_affectation,
 upper(personne.nom) as nom_personne,
 initcap(personne.prenom) as prenom_personne,
 personne.ville,
 debut,
 fin,
 poste.nom as nom_poste,
 description
from affectation
 join disponibilite on id_disponibilite = disponibilite.id
  join personne on id_personne = personne.id
 join tour on id_tour = tour.id
  join poste on id_poste = poste.id
order by poste.id_evenement, affectation.statut, date_et_heure_proposee;


-- Sollicitation par téléphone
-- cf tours_benevole


-- Sollicitation par email
-- cf tours_benevole
-- TODO : generation de l'URL unique identifiant l'affectation ou la disponibilite


-- Affectation ou refus de ses affectation par un bénévole
-- cf tours_benevole

-- Consultation des tours à pourvoir ou de l'état de remplissage des tours
-- cf tableau_de_remplissage
