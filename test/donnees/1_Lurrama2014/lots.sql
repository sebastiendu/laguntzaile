insert into lot(id_evenement, titre, cle)
 values (1, 'lot de 5 personnes', 7357);

insert into lot_personne (id_lot, id_personne)
 select 1, id
 from personne
 where email ~ '^[^ @]+@[^ @]+$'
 order by nom
 limit 5;

