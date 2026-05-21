#!/bin/bash
set -e

on_error() {
  echo "     ...failed on line $1!"
}

trap 'on_error $LINENO' ERR

# Load .env if variables aren't already injected (running in WSL, not container)
if [ -z "$VPS_HOST" ]; then
  SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
  set -a
  source "$SCRIPT_DIR/../.devcontainer/.env"
  set +a
fi

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
DUMP_PATH="$SCRIPT_DIR/../.postgres/latest.dump"

echo "refresh-database.sh ..."
echo "     Creating dump via SSH..."

ssh "$VPS_USER@$VPS_HOST" \
  "docker exec postgres pg_dump -Fc --no-owner --no-acl -U $POSTGRES_USER $DB_NAME" \
  > "$DUMP_PATH"

echo "     Dump saved to .postgres/latest.dump"
echo "     ...complete!"
echo ""
echo "Rebuild the devcontainer to restore the new dump."
echo ""
