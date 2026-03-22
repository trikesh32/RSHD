mkdir -p $HOME/gbt25

psql -h /tmp -p 9145 postgres -c "CREATE TABLESPACE indexes_ts LOCATION '$HOME/gbt25';"

psql -h /tmp -p 9145 postgres -c "CREATE DATABASE coolbluesong TEMPLATE template0 ENCODING 'UTF8' LC_COLLATE='ru_RU.UTF-8' LC_CTYPE='ru_RU.UTF-8';"

