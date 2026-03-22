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