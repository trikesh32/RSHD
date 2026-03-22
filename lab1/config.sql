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
