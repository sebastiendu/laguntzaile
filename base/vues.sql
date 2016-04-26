-- Gestion des événements

create or replace view liste_des_evenements as
select id, nom, debut, fin, lieu, archive
from evenement
order by debut desc;

create or replace view statistiques_evenement as
select id_evenement,
 count(distinct id_poste) as nombre_postes,
 count(distinct tour.id)  as nombre_tours,
 count(affectation.id) as nombre_affectations
from poste
 left join tour on id_poste = poste.id
 left join affectation on id_tour = tour.id
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
from evenement
 left join poste on id_evenement = evenement.id
  left join tour on id_poste = poste.id
   left join affectation on id_tour = tour.id
    join disponibilite on id_disponibilite = disponibilite.id
     join personne on id_personne = personne.id
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
 poste.id as id_poste,
 poste.nom as nom_poste,
 tour.id as id_tour,
 tour.debut as debut_tour,
 tour.fin as fin_tour,
 tour.min,
 tour.max,
 count(affectation.id) as nombre_affectations,
 string_agg(
  concat_ws(' ',
   upper(personne.nom),
   initcap(personne.prenom)
  ),
  ', '
 ) as liste_personnes,
 string_agg(
  concat_ws(' ',
   upper(personne_responsable.nom),
   initcap(personne_responsable.prenom)
  ),
  ', '
 ) as liste_responsables
from evenement
 left join poste on id_evenement = evenement.id
  left join responsable on id_poste = poste.id
   join personne as personne_responsable on id_personne = personne_responsable.id
  left join tour on tour.id_poste = poste.id
   left join affectation on id_tour = tour.id
    join disponibilite on id_disponibilite = disponibilite.id
     join personne on disponibilite.id_personne = personne.id
group by evenement.id, evenement.nom, evenement.debut, evenement.fin, evenement.lieu, poste.id, poste.nom, tour.id, tour.debut, tour.fin, tour.min, tour.max
order by evenement.id, tour.debut, tour.fin; -- FIXME : order by personne.nom, personne.prenom

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
 personne.commentaire,
 date_inscription,
 liste_amis,
 jours_et_heures_dispo,
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
 evenement.id as id_evenement,
 evenement.nom as nom_evenement,
 evenement.debut as debut_evenement,
 evenement.fin as fin_evenement,
 evenement.lieu as lieu_evenement,
 date_trunc('day', tour.debut) as jour,
 poste.id as id_poste,
 poste.nom as nom_poste,
 poste.description as description_poste,
 poste.posX as posX_poste,
 poste.posY as posY_poste,
 tour.id as id_tour,
 tour.debut as debut_tour,
 tour.fin as fin_tour,
 tour.min,
 tour.max,
 affectation.id as id_affectation,
 affectation.statut as statut_affectation,
 affectation.commentaire as commentaire_affectation,
 personne.id as id_personne,
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
from tour
 left join affectation on id_tour = tour.id
  left join disponibilite on id_disponibilite = disponibilite.id
   join personne on id_personne = personne.id
 join poste on id_poste = poste.id
  join evenement on poste.id_evenement = evenement.id
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
 count(affectation.id) as nombre_affectations
from tour
 left join affectation on id_tour = tour.id
group by id_poste;

create or replace view tours as -- utile ?
select id, id_poste, debut, fin, min, max
from tour
order by id_poste, debut, fin;

create or replace view horaires_nouveau_tour as
-- fin du plus recent tour ou debut evenement
select
 poste.id as id_poste,
 coalesce(max(tour.fin), evenement.debut) as debut,
 coalesce(max(tour.fin), evenement.debut) + interval '4 hours' as fin
from poste
 join evenement on id_evenement = evenement.id
 left join tour on id_poste = poste.id
group by poste.id, evenement.debut;

create or replace view statistiques_tour as
select tour.id as id_tour,
 count(affectation.id) as nombre_affectations
from tour
 left join affectation on id_tour = tour.id
group by tour.id;


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

-- TODO : Trouver une interface ergonomique pour selectionner les anciens bénévoles,
-- et créer des enregistrements dans la table sollicitation.

-- Candidature d'un bénévole sollicité

-- TODO : mettre à jour le statut de la sollicitation : soit acceptée, soit rejetée.
-- l'acceptation est suivie d'une mise à jour de l'enregistrement dans la table personne


-- Contrôle et modération des candidatures

create or replace view candidatures_en_attente as
select
 disponibilite.id as id_disponibilite,
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
 where statut = 'proposee'
order by id_evenement, date_inscription, personne.nom;

create or replace view personnes_doublons as -- repérage des doublons probables
 with iddoublon as (
  with correspondance as (
   select nouveau.id as idnouveau, existant.id as id,
    nouveau.nom <> '' and lower(nouveau.nom) = lower(existant.nom) as memenom,
    nouveau.adresse <> '' and lower(nouveau.adresse) = lower(existant.adresse) as memeadresse,
    nouveau.ville <> '' and lower(nouveau.ville) = lower(existant.ville) as memeville,
    nouveau.email <> '' and lower(nouveau.email) = lower(existant.email) as memeemail,
    nouveau.domicile <> '' and lower(nouveau.domicile) = lower(existant.domicile) as memedomicile,
    nouveau.portable <> '' and lower(nouveau.portable) = lower(existant.portable) as memeportable,
    nouveau.prenom <> '' and lower(nouveau.prenom) = lower(existant.prenom) as memeprenom
   from personne nouveau, personne existant
   where nouveau.id <> existant.id
  )
  select *, (
   3 * memenom::integer +
   2 * memeadresse::integer +
   1 * memeville::integer +
   5 * memeemail::integer +
   4 * memedomicile::integer +
   5 * memeportable::integer +
   1 * memeprenom::integer
  ) / 21.0 as score
  from correspondance
 )
 select iddoublon.*, nom, prenom, ville
 from iddoublon join personne using(id)
 where score > 0
 order by score desc, nom, prenom, ville;


-- Inscription directe d'un bénévole

-- Afficher toutes les personnes avec l'indication pour chacun de sa présence dans la table disponibilité pour cet évenement

create or replace view personnes_inscrite_ou_pas_encore as
select
 id_evenement,
 personne.id as id_personne,
 disponibilite.id as id_disponibilite,
 personne.nom as nom_personne,
 prenom,
 ville -- et peut-être tous les autres champs de personne
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
 count(affectation.id) as nombre_affectations
from disponibilite
 join personne on id_personne = personne.id
 left join affectation on id_disponibilite = disponibilite.id
where disponibilite.statut = 'validee'
group by id_evenement, disponibilite.id, id_personne, personne.nom, personne.prenom, personne.ville
order by id_evenement, count(affectation.id) asc, personne.nom, personne.prenom, personne.ville;

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
 extract(year from age((select debut from evenement where id=id_evenement), date_naissance)) as age,
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
debut::date as date_debut,
fin,
to_char(debut, 'HHhMI') as heure_debut,
to_char(fin, 'HHhMI') as heure_fin,
to_char(fin - debut, 'HHhMI') as duree,
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
with besoin_par_tour as (
 with effectif_par_tour as (
  select tour.*, count(affectation.id) as effectif
  from tour left join affectation on id_tour = tour.id
  where statut is null or statut = 'validee' or statut = 'acceptee'
  group by tour.id
 )
  select *,
   case when effectif < min then min - effectif
        when effectif > max then max - effectif
        else 0 end as besoin
  from effectif_par_tour
)
select *,
 case when besoin > 0 then 100 * besoin / min
      when besoin < 0 then 100 * besoin / max
      else 0 end as faim,
 100 * effectif / ((min+max)/2) as taux
from besoin_par_tour;

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

-- Gestion des postes, tours, et affectations, pour l'affichage sur le plan

create or replace view poste_et_tour as -- pour affichage du plan
select
poste.id as id_poste,
poste.id_evenement,
poste.nom,
poste.description,
poste.posx,
poste.posy,
tour.debut,
tour.id as id_tour,
tour.fin,
tour.min,
tour.max,
count(affectation.id)  as nombre_affectations,
sum(case when affectation.statut = 'possible' then 1 else 0 end) as nombre_affectations_possibles,
sum(case when affectation.statut = 'proposee' then 1 else 0 end) as nombre_affectations_proposees,
sum(case when affectation.statut in ('validee', 'acceptee') then 1 else 0 end) as nombre_affectations_validees_ou_acceptees,
sum(case when affectation.statut in ('rejetee', 'annulee') then 1 else 0 end) as nombre_affectations_rejetees_ou_annulees
FROM poste
left join tour on poste.id = id_poste
left join affectation on tour.id = id_tour
GROUP BY poste.id, poste.id_evenement, poste.nom, poste.description, poste.posx, poste.posy, tour.debut, tour.id, tour.fin,tour.min, tour.max;


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
  join poste on id_poste = poste.id;


-- Sollicitation par téléphone
-- cf tours_benevole


-- Sollicitation par email
-- cf tours_benevole


-- Affectation ou refus de ses affectation par un bénévole
-- cf tours_benevole

-- Consultation des tours à pourvoir ou de l'état de remplissage des tours
-- ("emploi du temps")
create or replace view postes_par_ordre_chronologique as
 select poste.*
 from poste left join tour on id_poste = poste.id
 group by poste.id
 order by min(debut), max(fin);

create or replace view duree_evenement as
 select id_evenement,
  min(tour.debut) as debut,
  max(tour.fin) as fin,
  max(tour.fin) - min(tour.debut) as duree
 from poste
  left join tour on id_poste = poste.id
 group by id_evenement;

create or replace view intervalle_sequence_evenement as
 select *,
  case
   when duree < '20 hours'
    then interval '1 hour'
   when duree < '3 day'
    then interval '6 hours'
   when duree < '1 week'
    then interval '1 day'
   else interval '1 week'
  end as intervalle
 from duree_evenement;

create or replace view intervalle_sequence_et_debut_arrondi_evenement as
 select *,
  to_timestamp(
   extract(epoch from intervalle)
   *
   (extract(epoch from debut)/extract(epoch from intervalle))::integer
  ) at time zone 'UTC' as debut_arrondi
 from intervalle_sequence_evenement;

create or replace view intervalle_sequence_et_debut_et_duree_arrondis_evenement as
 select *,
  intervalle * (select count(*) from generate_series(debut_arrondi, fin, intervalle)) as duree_arrondie
 from intervalle_sequence_et_debut_arrondi_evenement;

create or replace view sequence_evenement as
 select *,
  generate_series(debut_arrondi, fin, intervalle) as debut_sequence,
  extract(epoch from intervalle) / extract(epoch from duree_arrondie) as proportion
 from intervalle_sequence_et_debut_et_duree_arrondis_evenement;

create or replace view libelle_sequence_evenement as
 select *,
  debut_sequence + intervalle as fin_sequence,
  to_char(debut_sequence,
   case intervalle
    when '1 hour' then 'FMHH24 h'
    when '6 hours' then 'FMHH24 h' -- TODO : nuit matin après-midi soir
    when '1 day' then 'TMDay DD'
    else 'Semaine WW'
  end) as libelle_sequence
 from sequence_evenement;

create or replace view tours_emploi_du_temps as
 select
  id_poste,
  t.id,
  extract(epoch from t.debut - e.debut_arrondi) / extract(epoch from e.duree_arrondie) as position_relative,
  extract(epoch from t.fin - t.debut) / extract(epoch from e.duree_arrondie) duree_relative,
  min, max, t.debut, t.fin, effectif, besoin, faim, taux
 from taux_de_remplissage_tour as t
  join poste on poste.id = t.id_poste
  join intervalle_sequence_et_debut_et_duree_arrondis_evenement as e using(id_evenement)
 order by t.debut, t.fin;
