
-- Gestion des postes, tours, et affectations, pour l'affichage sur le plan

create or replace view poste_et_tour as -- pour affichage du plan
select 
poste.id,
poste.id_evenement, 
poste.nom, 
poste.description, 
poste.posx,
poste.posy, 
tour.debut,
tour.id,
tour.fin,
tour.min, 
tour.max,
count(*)  as nombre_affectations,
sum(case when affectation.statut = 'possible' then 1 else 0 end) as nombre_affectations_possibles,
sum(case when affectation.statut = 'proposee' then 1 else 0 end) as nombre_affectations_proposees,
sum(case when affectation.statut in ('validee', 'acceptee') then 1 else 0 end) as nombre_affectations_validees_ou_acceptees

FROM poste
join tour on poste.id = tour.id_poste
join affectation on tour.id = affectation.id_tour
GROUP BY poste.id, poste.id_evenement, poste.nom, poste.description, poste.posx,poste.posy, tour.debut,tour.fin,tour.min, tour.max
-- TODO : Attendre modification Gaizka

