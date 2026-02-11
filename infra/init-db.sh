#!/bin/bash
set -e

# Create additional databases for Solid Cache / Queue / Cable
for db in dxceco_poc_production_cache dxceco_poc_production_queue dxceco_poc_production_cable; do
  echo "Creating database: $db"
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
    CREATE DATABASE $db OWNER $POSTGRES_USER;
EOSQL
done
