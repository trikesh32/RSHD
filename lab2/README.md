Подключение к основному узлу

```
ssh -J s409711@helios.cs.ifmo.ru:2222 postgres1@pg110
```

Подключение к резервному узлу

```
ssh -J s409711@helios.cs.ifmo.ru:2222 postgres0@pg121
```

для подключения с основного узла на резервный без пароля прокинем ssh ключи

на основном узле
```
ssh-keygen -t rsa
ssh-copy-id -i ~/.ssh/id_rsa.pub postgres0@pg121
```

теперь создадим пользователя с правами репликации

```
CREATE ROLE trikesh_amuzkarapuz WITH LOGIN REPLICATION PASSWORD 'admin';
```

Добавим в файл pg_hba.conf на основном узле правило, разрешающее локальное replication-подключение для созданного пользователя:

```
host   replication     trikesh_amuzkarapuz   ::1/128        trust
```

на резервном узле создадим папочку (ну хоть не мамочку) для хранения архивов WAL

```
ssh postgres0@pg121 "mkdir -p ~/backup_dir/wal"
```

Далее на основном узле было настроено архивирование WAL. Для этого в файл postgresql.auto.conf были добавлены следующие параметры (почему не postgresql.conf? патамушта не хочу):

```
wal_level = replica
archive_mode = on
archive_command = 'scp %p postgres0@pg121:~/backup_dir/wal/%f'
archive_timeout = 60
```

Параметр wal_level = replica задаёт уровень журналирования, необходимый для резервного копирования.
Параметр archive_mode = on включает архивирование WAL.
Параметр archive_command задаёт команду передачи WAL-сегментов на резервный узел.
Параметр archive_timeout = 60 задаёт максимальный интервал принудительного архивирования сегмента WAL.

Теперь займемся резервным копированием через pg_basebackup

```
pg_basebackup -D /tmp/backup -Ft -Xs -P -h localhost -p 9145 -U trikesh_amuzkarapuz
```