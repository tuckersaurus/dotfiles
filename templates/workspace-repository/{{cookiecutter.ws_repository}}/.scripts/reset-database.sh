#!/bin/bash
set -e

on_error() {
  echo "     ...failed on line $1!"
}

trap 'on_error $LINENO' ERR

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
COMPOSE_FILE="$SCRIPT_DIR/../.devcontainer/docker-compose.yml"

echo "reset-database.sh ..."
echo "     Stopping postgres and removing data volume..."
echo "     WARNING: This will destroy all local database data."
echo ""

docker compose -f "$COMPOSE_FILE" rm -sf postgres
docker compose -f "$COMPOSE_FILE" down -v 2>/dev/null || true

echo "     ...complete!"
echo ""
echo "Rebuild the devcontainer to re-initialize the database from .postgres/01-int.sql."
echo ""
