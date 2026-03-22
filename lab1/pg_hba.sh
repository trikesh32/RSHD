echo "listen_addresses = 'localhost'" >> $PGDATA/postgresql.conf
echo "port = 9145" >> $PGDATA/postgresql.conf


cat > $PGDATA/pg_hba.conf << EOF
# TYPE  DATABASE        USER            ADDRESS                 METHOD
host    all             all             127.0.0.1/32            password
host    all             all             ::1/128                 password
local   all             all                                     peer
EOF

pg_ctl -D $PGDATA restart
