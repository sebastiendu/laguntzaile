DATABASE_URL=laguntzaile

dump.sql.gz: base/structure.sql base/vues.sql base/roles_et_permissions.sql test/donnees/1_Lurrama2014/import.sql test/donnees/1_Lurrama2014/2014.csv test/donnees/2_AlternatibaSocoa2014/import.sql test/donnees/2_AlternatibaSocoa2014/personne.csv test/donnees/2_AlternatibaSocoa2014/poste.csv test/donnees/2_AlternatibaSocoa2014/tour.csv test/donnees/2_AlternatibaSocoa2014/affectation.csv
	psql -f base/structure.sql $(DATABASE_URL)
	psql -f base/vues.sql $(DATABASE_URL)
	psql -f base/roles_et_permissions.sql $(DATABASE_URL)
	(cd test/donnees/1_Lurrama2014 && psql -f import.sql $(DATABASE_URL))
	(cd test/donnees/2_AlternatibaSocoa2014 && psql -f import.sql $(DATABASE_URL))
	pg_dump -c $(DATABASE_URL)|gzip - >$@
