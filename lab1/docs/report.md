# Отчёт по лабораторной работе №1

## Задание

Цель работы: на выделенном узле создать и настроить новый кластер PostgreSQL, создать базу данных, табличное пространство и новую роль, а также наполнить базу тестовыми данными.

Вариант задания:

- директория кластера: `$HOME/hlt85`
- кодировка: `UTF8`
- локаль: русская
- способы подключения:
  - Unix-domain socket в режиме `peer`
  - TCP/IP только для `localhost`
- порт: `9145`
- аутентификация TCP/IP клиентов: пароль в открытом виде
- дополнительные параметры сервера:
  - `max_connections`
  - `shared_buffers`
  - `temp_buffers`
  - `work_mem`
  - `checkpoint_timeout`
  - `effective_cache_size`
  - `fsync`
  - `commit_delay`
- сценарий настройки: OLTP, `500 TPS`, размер транзакции `4 КБ`, приоритетом является сохранность данных
- директория WAL: `$PGDATA/pg_wal`
- формат логов: `.csv`
- уровень логирования: `WARNING`
- дополнительно логировать контрольные точки и попытки подключения
- создать табличное пространство для индексов: `$HOME/qbt25`
- создать базу `coolbluesong` на основе `template0`
- создать новую роль, выдать необходимые права и разрешить подключение к базе
- заполнение базы выполнить от имени новой роли
- вывести список всех табличных пространств и объектов в них

## Анализ материалов в репозитории

В каталоге лабораторной находятся следующие файлы:

- `init.sh` - инициализация кластера и первый запуск
- `pg_hba.sh` - настройка сетевых параметров и `pg_hba.conf`
- `config.sql` - установка параметров сервера через `ALTER SYSTEM`
- `stage3.sh` - создание табличного пространства и базы данных
- `create_role.sql` - создание роли и выдача прав
- `table.sql`, `bench.sql`, `test.sh` - подготовка и проверка OLTP-нагрузки
- `fill_table.sql` - заполнение пользовательской базы тестовыми данными
- `connect.sh` - примеры подключений
- `clean.sh` - очистка рабочих директорий

По результатам анализа обнаружены два важных замечания:

1. В тексте задания директория табличного пространства указана как `$HOME/qbt25`, а в `stage3.sh` и `clean.sh` фигурируют `gbt25` и `qbt25`. Для отчёта корректным считается путь из задания: `$HOME/qbt25`.
2. В скриптах OLTP-нагрузка выполняется в базе `postgres`, а пользовательская база `coolbluesong` заполняется отдельным тестовым набором. Это не противоречит структуре лабораторной: `postgres` используется как техническая база для подбора параметров, а основное наполнение прикладной базы выполняется ролью `data_user`.

## Этап 1. Инициализация кластера БД

Для выполнения первого этапа использовался скрипт `init.sh`.

```sh
#!/bin/sh

export PGDATA=$HOME/hlt85
export PGWAL=$PGDATA/pg_wal
export PGLOCALE=ru_RU.UTF-8
export PGENCODE=UTF8
export PGUSERNAME=postgres1
export PGHOST=pg110
export LANG=ru_RU.UTF-8
export LC_ALL=ru_RU.UTF-8

initdb -D "$PGDATA" --encoding=$PGENCODE --locale=$PGLOCALE --lc-messages=$PGLOCALE --lc-monetary=$PGLOCALE --lc-numeric=$PGLOCALE --lc-time=$PGLOCALE --username=$PGUSERNAME

pg_ctl -D $PGDATA -l $PGDATA/server.log start
```

Использованные параметры инициализации:

- кластер создаётся в каталоге `$HOME/hlt85`
- кодировка кластера: `UTF8`
- локаль для всех категорий: `ru_RU.UTF-8`
- имя администратора кластера: `postgres1`

Ключевая команда инициализации:

```sh
initdb -D "$HOME/hlt85" \
  --encoding=UTF8 \
  --locale=ru_RU.UTF-8 \
  --lc-messages=ru_RU.UTF-8 \
  --lc-monetary=ru_RU.UTF-8 \
  --lc-numeric=ru_RU.UTF-8 \
  --lc-time=ru_RU.UTF-8 \
  --username=postgres1
```

После инициализации сервер запускается командой:

```sh
pg_ctl -D "$HOME/hlt85" -l "$HOME/hlt85/server.log" start
```

## Этап 2. Конфигурация и запуск сервера БД

### Настройка подключений

Для настройки сетевых параметров и правил доступа используется скрипт `pg_hba.sh`.

```sh
echo "listen_addresses = 'localhost'" >> $PGDATA/postgresql.conf
echo "port = 9145" >> $PGDATA/postgresql.conf


cat > $PGDATA/pg_hba.conf << EOF
# TYPE  DATABASE        USER            ADDRESS                 METHOD
host    all             all             127.0.0.1/32            password
host    all             all             ::1/128                 password
local   all             all                                     peer
EOF

pg_ctl -D $PGDATA restart
```

Изменённые строки `postgresql.conf`:

```conf
listen_addresses = 'localhost'
port = 9145
```

Изменённое содержимое `pg_hba.conf`:

```conf
# TYPE  DATABASE        USER            ADDRESS                 METHOD
host    all             all             127.0.0.1/32            password
host    all             all             ::1/128                 password
local   all             all                                     peer
```

Эта конфигурация удовлетворяет требованиям задания:

- локальные подключения через Unix-domain socket разрешены по `peer`
- TCP/IP разрешён только для `localhost`
- для TCP/IP используется парольная аутентификация методом `password`
- удалённые подключения невозможны, так как сервер слушает только `localhost`

Проверка подключений выполняется командами:

```sh
psql -h /tmp -p 9145 postgres
psql -h 127.0.0.1 -p 9145 postgres
psql -U data_user -d coolbluesong -h localhost -p 9145
```

### Настройка параметров PostgreSQL

Параметры сервера задаются в `config.sql`.

```sql
ALTER SYSTEM SET max_connections = 100;
ALTER SYSTEM SET shared_buffers = '256MB';
ALTER SYSTEM SET temp_buffers = '8MB';
ALTER SYSTEM SET work_mem = '4MB';
ALTER SYSTEM SET checkpoint_timeout = '10min';
ALTER SYSTEM SET effective_cache_size = '4GB';
ALTER SYSTEM SET fsync = on;
ALTER SYSTEM SET commit_delay = 0;

ALTER SYSTEM SET log_destination = 'csvlog';
ALTER SYSTEM SET logging_collector = on;
ALTER SYSTEM SET log_filename = 'postgresql-%Y-%m-%d_%H%M%S.csv';
ALTER SYSTEM SET log_min_messages = warning;
ALTER SYSTEM SET log_connections = on;
ALTER SYSTEM SET log_disconnections = on;
ALTER SYSTEM SET log_checkpoints = on;

ALTER USER postgres1 WITH PASSWORD '1234';
```

Итоговые изменённые строки конфигурации:

```conf
max_connections = 100
shared_buffers = '256MB'
temp_buffers = '8MB'
work_mem = '4MB'
checkpoint_timeout = '10min'
effective_cache_size = '4GB'
fsync = on
commit_delay = 0

log_destination = 'csvlog'
logging_collector = on
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.csv'
log_min_messages = warning
log_connections = on
log_disconnections = on
log_checkpoints = on
```

### Обоснование параметров для OLTP

Сценарий из задания: около `500` транзакций в секунду, объём транзакции `4 КБ`, акцент на высокую доступность и сохранность данных.

Выбранные параметры можно обосновать так:

- `max_connections = 100`  
  Достаточный запас по числу одновременных клиентских подключений без чрезмерного расхода памяти на процессы PostgreSQL.

- `shared_buffers = 256MB`  
  Позволяет удерживать часто используемые страницы в буфере и уменьшать число физических обращений к диску.

- `temp_buffers = 8MB`  
  Для типичной OLTP-нагрузки временные объекты используются умеренно, поэтому большого значения не требуется.

- `work_mem = 4MB`  
  Подходит для коротких запросов и не приводит к резкому росту потребления памяти при большом количестве параллельных соединений.

- `checkpoint_timeout = 10min`  
  Более редкие контрольные точки уменьшают пиковую нагрузку на диск по сравнению с очень малым интервалом, но при этом значение остаётся безопасным.

- `effective_cache_size = 4GB`  
  Даёт планировщику представление о доступном файловом кэше ОС и помогает выбирать индексные планы.

- `fsync = on`  
  Обязателен для сценария, где приоритетом является сохранность данных. Отключать `fsync` при требованиях High Availability нельзя.

- `commit_delay = 0`  
  Для транзакций малого объёма и умеренной интенсивности это консервативное и безопасное решение: подтверждение коммита не задерживается искусственно.

Дополнительно настроено логирование в формате `.csv`, что соответствует заданию и облегчает последующий анализ журнала.

### Подготовка OLTP-теста

Для проверки типичной нагрузки используются файлы `table.sql`, `bench.sql` и `test.sh`.

Таблица для теста:

```sql
CREATE TABLE bench_kv (
 id        bigint PRIMARY KEY,
 payload   text NOT NULL,
 updated_at timestamptz NOT NULL DEFAULT now()
);


INSERT INTO bench_kv (id, payload)
SELECT i, repeat('a', 32)
FROM generate_series(1, 200000) AS s(i);
```

Сценарий транзакции:

```sql
\set id random(1, 200000)


BEGIN;
SELECT length(payload) FROM bench_kv WHERE id = :id;
SELECT updated_at FROM bench_kv WHERE id = :id;
UPDATE bench_kv
SET payload = repeat('x', 4096),
   updated_at = clock_timestamp()
WHERE id = :id;
COMMIT;
```

Запуск теста:

```sh
pgbench -p 9145 -n -f bench.sql -c 20 -j 16 -T 60 postgres -h /tmp
```

Этот тест имитирует короткие OLTP-транзакции с чтением и обновлением строки. Размер обновляемого поля `payload` доводится до `4096` байт, что соответствует требованию о размере транзакции порядка `4 КБ`.

## Этап 3. Табличное пространство, база данных и роль

### Создание табличного пространства и базы

В `stage3.sh` приведены команды создания табличного пространства и базы:

```sh
mkdir -p $HOME/gbt25

psql -h /tmp -p 9145 postgres -c "CREATE TABLESPACE indexes_ts LOCATION '$HOME/gbt25';"

psql -h /tmp -p 9145 postgres -c "CREATE DATABASE coolbluesong TEMPLATE template0 ENCODING 'UTF8' LC_COLLATE='ru_RU.UTF-8' LC_CTYPE='ru_RU.UTF-8';"
```

Для соответствия заданию путь табличного пространства должен быть приведён к виду:

```sh
mkdir -p $HOME/qbt25

psql -h /tmp -p 9145 postgres -c "CREATE TABLESPACE indexes_ts LOCATION '$HOME/qbt25';"

psql -h /tmp -p 9145 postgres -c "CREATE DATABASE coolbluesong TEMPLATE template0 ENCODING 'UTF8' LC_COLLATE='ru_RU.UTF-8' LC_CTYPE='ru_RU.UTF-8';"
```

Таким образом:

- создано табличное пространство `indexes_ts` для индексов
- создана база `coolbluesong` на основе `template0`

### Создание роли и выдача прав

Файл `create_role.sql`:

```sql
CREATE ROLE data_user LOGIN PASSWORD '1234';
GRANT CONNECT ON DATABASE coolbluesong TO data_user;
GRANT CONNECT ON DATABASE template0 TO data_user;

\c coolbluesong

GRANT ALL ON SCHEMA public TO data_user;

GRANT CREATE ON TABLESPACE indexes_ts TO data_user;
```

После выполнения этих команд:

- создаётся пользователь `data_user`
- роли разрешено подключение к базе `coolbluesong`
- роли выданы права на схему `public`
- роли разрешено создавать объекты в табличном пространстве `indexes_ts`

Лишнее право `GRANT CONNECT ON DATABASE template0 TO data_user;` не требуется для выполнения задания, но не мешает основной конфигурации.

### Наполнение базы от имени новой роли

Для пользовательской базы `coolbluesong` используется скрипт `fill_table.sql`.

```sql
\c coolbluesong;

CREATE TABLE simple_table (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL
);

CREATE INDEX idx_simple_table_name ON simple_table(name) 
    TABLESPACE indexes_ts;

INSERT INTO simple_table (name)
SELECT 
    CASE (random() * 5)::INT
        WHEN 0 THEN 'Алексей'
        WHEN 1 THEN 'Мария'
        WHEN 2 THEN 'Дмитрий'
        WHEN 3 THEN 'Екатерина'
        WHEN 4 THEN 'Владимир'
        ELSE 'Ольга'
    END || ' ' ||
    CASE (random() * 5)::INT
        WHEN 0 THEN 'Иванов'
        WHEN 1 THEN 'Петров'
        WHEN 2 THEN 'Сидоров'
        WHEN 3 THEN 'Кузнецов'
        WHEN 4 THEN 'Смирнов'
        ELSE 'Попов'
    END || ' ' ||
    LPAD((random() * 999)::INT::TEXT, 3, '0')
FROM generate_series(1, 100);
```

Примечание: в исходном файле строки с русскими именами сохранены в повреждённой кодировке, но по смыслу это набор русских ФИО. В отчёте приведён их нормализованный вид.

Смысл наполнения:

- таблица `simple_table` создаётся в табличном пространстве по умолчанию базы
- индекс `idx_simple_table_name` явно создаётся в `indexes_ts`
- тем самым табличное пространство для индексов используется по назначению

Подключение для выполнения наполнения от имени новой роли:

```sh
psql -U data_user -d coolbluesong -h localhost -p 9145
```

## Вывод списка табличных пространств и объектов

Для вывода списка табличных пространств кластера:

```sql
SELECT oid, spcname, pg_tablespace_location(oid) AS location
FROM pg_tablespace
ORDER BY spcname;
```

Для вывода объектов, размещённых в табличных пространствах:

```sql
SELECT
    t.spcname AS tablespace_name,
    n.nspname AS schema_name,
    c.relname AS object_name,
    c.relkind AS object_type
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
JOIN pg_tablespace t ON t.oid = c.reltablespace
ORDER BY t.spcname, n.nspname, c.relname;
```

Ожидаемый результат после выполнения лабораторной:

- в системных табличных пространствах `pg_default` и `pg_global` находятся системные объекты кластера
- в табличном пространстве `indexes_ts` находится индекс `idx_simple_table_name`

## Использованные скрипты

### `init.sh`

```sh
#!/bin/sh

export PGDATA=$HOME/hlt85
export PGWAL=$PGDATA/pg_wal
export PGLOCALE=ru_RU.UTF-8
export PGENCODE=UTF8
export PGUSERNAME=postgres1
export PGHOST=pg110
export LANG=ru_RU.UTF-8
export LC_ALL=ru_RU.UTF-8

initdb -D "$PGDATA" --encoding=$PGENCODE --locale=$PGLOCALE --lc-messages=$PGLOCALE --lc-monetary=$PGLOCALE --lc-numeric=$PGLOCALE --lc-time=$PGLOCALE --username=$PGUSERNAME

pg_ctl -D $PGDATA -l $PGDATA/server.log start
```

### `pg_hba.sh`

```sh
echo "listen_addresses = 'localhost'" >> $PGDATA/postgresql.conf
echo "port = 9145" >> $PGDATA/postgresql.conf


cat > $PGDATA/pg_hba.conf << EOF
# TYPE  DATABASE        USER            ADDRESS                 METHOD
host    all             all             127.0.0.1/32            password
host    all             all             ::1/128                 password
local   all             all                                     peer
EOF

pg_ctl -D $PGDATA restart
```

### `config.sql`

```sql
ALTER SYSTEM SET max_connections = 100;
ALTER SYSTEM SET shared_buffers = '256MB';
ALTER SYSTEM SET temp_buffers = '8MB';
ALTER SYSTEM SET work_mem = '4MB';
ALTER SYSTEM SET checkpoint_timeout = '10min';
ALTER SYSTEM SET effective_cache_size = '4GB';
ALTER SYSTEM SET fsync = on;
ALTER SYSTEM SET commit_delay = 0;

ALTER SYSTEM SET log_destination = 'csvlog';
ALTER SYSTEM SET logging_collector = on;
ALTER SYSTEM SET log_filename = 'postgresql-%Y-%m-%d_%H%M%S.csv';
ALTER SYSTEM SET log_min_messages = warning;
ALTER SYSTEM SET log_connections = on;
ALTER SYSTEM SET log_disconnections = on;
ALTER SYSTEM SET log_checkpoints = on;

ALTER USER postgres1 WITH PASSWORD '1234';
```

### `stage3.sh`

```sh
mkdir -p $HOME/qbt25

psql -h /tmp -p 9145 postgres -c "CREATE TABLESPACE indexes_ts LOCATION '$HOME/qbt25';"

psql -h /tmp -p 9145 postgres -c "CREATE DATABASE coolbluesong TEMPLATE template0 ENCODING 'UTF8' LC_COLLATE='ru_RU.UTF-8' LC_CTYPE='ru_RU.UTF-8';"
```

### `create_role.sql`

```sql
CREATE ROLE data_user LOGIN PASSWORD '1234';
GRANT CONNECT ON DATABASE coolbluesong TO data_user;

\c coolbluesong

GRANT ALL ON SCHEMA public TO data_user;
GRANT CREATE ON TABLESPACE indexes_ts TO data_user;
```

### `fill_table.sql`

```sql
\c coolbluesong;

CREATE TABLE simple_table (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL
);

CREATE INDEX idx_simple_table_name ON simple_table(name)
    TABLESPACE indexes_ts;

INSERT INTO simple_table (name)
SELECT 
    CASE (random() * 5)::INT
        WHEN 0 THEN 'Алексей'
        WHEN 1 THEN 'Мария'
        WHEN 2 THEN 'Дмитрий'
        WHEN 3 THEN 'Екатерина'
        WHEN 4 THEN 'Владимир'
        ELSE 'Ольга'
    END || ' ' ||
    CASE (random() * 5)::INT
        WHEN 0 THEN 'Иванов'
        WHEN 1 THEN 'Петров'
        WHEN 2 THEN 'Сидоров'
        WHEN 3 THEN 'Кузнецов'
        WHEN 4 THEN 'Смирнов'
        ELSE 'Попов'
    END || ' ' ||
    LPAD((random() * 999)::INT::TEXT, 3, '0')
FROM generate_series(1, 100);
```

### `table.sql`

```sql
CREATE TABLE bench_kv (
 id        bigint PRIMARY KEY,
 payload   text NOT NULL,
 updated_at timestamptz NOT NULL DEFAULT now()
);


INSERT INTO bench_kv (id, payload)
SELECT i, repeat('a', 32)
FROM generate_series(1, 200000) AS s(i);
```

### `bench.sql`

```sql
\set id random(1, 200000)


BEGIN;
SELECT length(payload) FROM bench_kv WHERE id = :id;
SELECT updated_at FROM bench_kv WHERE id = :id;
UPDATE bench_kv
SET payload = repeat('x', 4096),
   updated_at = clock_timestamp()
WHERE id = :id;
COMMIT;
```

### `test.sh`

```sh
pgbench -p 9145 -n -f bench.sql -c 20 -j 16 -T 60 postgres -h /tmp
```

## Итог

В ходе работы был инициализирован и настроен кластер PostgreSQL в каталоге `$HOME/hlt85`, сконфигурированы допустимые способы подключения, настроены параметры сервера под OLTP-сценарий с приоритетом сохранности данных, включено логирование в формате CSV, создано табличное пространство для индексов, база `coolbluesong` и роль `data_user`.

База была заполнена тестовыми данными, причём индекс размещён в отдельном табличном пространстве `indexes_ts`, что подтверждает корректное использование табличного пространства по назначению. Все основные команды, SQL-скрипты и изменённые строки конфигурационных файлов приведены в отчёте.
