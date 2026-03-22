CREATE ROLE data_user LOGIN PASSWORD '1234';
GRANT CONNECT ON DATABASE coolbluesong TO data_user;
GRANT CONNECT ON DATABASE template0 TO data_user;

\c coolbluesong

GRANT ALL ON SCHEMA public TO data_user;

GRANT CREATE ON TABLESPACE indexes_ts TO data_user;
