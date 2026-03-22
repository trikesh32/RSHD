\set id random(1, 200000)


BEGIN;
SELECT length(payload) FROM bench_kv WHERE id = :id;
SELECT updated_at FROM bench_kv WHERE id = :id;
UPDATE bench_kv
SET payload = repeat('x', 4096),
   updated_at = clock_timestamp()
WHERE id = :id;
COMMIT;