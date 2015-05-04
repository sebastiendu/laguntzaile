create role administration;
grant all on all tables in schema public to administration; -- FIXME : restrict a bit more
grant all on all sequences in schema public to administration;
