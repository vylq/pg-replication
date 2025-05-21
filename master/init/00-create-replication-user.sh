#!/bin/bash
set -e

# Create replication user 'repl_user' with password 'repl_password'
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE USER repl_user WITH REPLICATION LOGIN PASSWORD 'repl_password';
EOSQL

# Create physical replication slot 'replica_slot' (must match replica's primary_slot_name)
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    SELECT pg_create_physical_replication_slot('replica_slot');
EOSQL

echo "Replication user 'repl_user' and replication slot 'replica_slot' created."
