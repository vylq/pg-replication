#!/bin/bash
set -e

REPL_USER="repl_user"
REPL_PASSWORD="repl_password"

PGDATA_DIR="$PGDATA"


echo "Waiting for master to start..."
while ! pg_isready -h "$PGMASTER_HOST" -p 5432 -U "$REPL_USER" -d "dbname=$POSTGRES_DB" ; do
    sleep 2
done
echo "Master is ready."

if [ -n "$(ls -A "$PGDATA_DIR")" ] && [ ! -f "$PGDATA_DIR/standby.signal" ]; then
    echo "PGDATA directory is not empty and not a standby. Cleaning up for base backup..."
    rm -rf "$PGDATA_DIR"/*
elif [ -f "$PGDATA_DIR/standby.signal" ]; then
    echo "Existing standby.signal found. Assuming replica is already configured. Starting PostgreSQL."
    exec docker-entrypoint.sh postgres -c config_file=/etc/postgresql/postgresql.conf -c hba_file=/etc/postgresql/pg_hba.conf
    exit 0
fi


echo "Performing pg_basebackup..."
PGPASSWORD="$REPL_PASSWORD" pg_basebackup \
    -h "$PGMASTER_HOST" \
    -p 5432 \
    -U "$REPL_USER" \
    -D "$PGDATA_DIR" \
    -Fp \
    -Xs \
    -P \
    -R \
    --slot="$PRIMARY_SLOT_NAME"

if [ $? -ne 0 ]; then
    echo "pg_basebackup failed!"
    exit 1
fi
echo "Base backup successful."

if [ ! -f "$PGDATA_DIR/standby.signal" ] && [ "$(psql -V | awk '{print $3}' | cut -d. -f1)" -ge 12 ]; then
   echo "standby.signal not found after pg_basebackup -R. Creating it."
   touch "$PGDATA_DIR/standby.signal"
fi


echo "Replica setup complete. Starting PostgreSQL standby server..."

exec docker-entrypoint.sh postgres -c config_file=/etc/postgresql/postgresql.conf -c hba_file=/etc/postgresql/pg_hba.conf