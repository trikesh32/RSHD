CREATE TABLE bench_kv (
 id        bigint PRIMARY KEY,
 payload   text NOT NULL,
 updated_at timestamptz NOT NULL DEFAULT now()
);


INSERT INTO bench_kv (id, payload)
SELECT i, repeat('a', 32)
FROM generate_series(1, 200000) AS s(i);