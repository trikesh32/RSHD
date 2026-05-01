#!/bin/sh

export PGDATA=$HOME/hlt85
export PGWAL=$PGDATA/pg_wal
export PGLOCALE=ru_RU.UTF-8
export PGENCODE=UTF8
export PGUSERNAME=postgres1
export PGHOST=pg110
export LANG=ru_RU.UTF-8
export LC_ALL=ru_RU.UTF-8

initdb -D "$PGDATA" --encoding=$PGENCODE --locale=$PGLOCALE

pg_ctl -D $PGDATA -l $PGDATA/server.log start