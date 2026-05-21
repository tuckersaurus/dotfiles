#!/bin/bash
set -e

on_error() {
  echo "     ...failed on line $1!"
}

trap 'on_error $LINENO' ERR

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
DUMP_PATH="$SCRIPT_DIR/latest.dump"

if [ ! -s "$DUMP_PATH" ]; then
  echo "No dump found at $DUMP_PATH, skipping restore."
  exit 0
fi

echo "02-restore.sh ..."
echo "     Restoring database from dump..."

pg_restore --no-owner --no-acl \
  -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
  "$DUMP_PATH" || true

echo "     ...complete!"
