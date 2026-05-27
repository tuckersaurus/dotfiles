#!/bin/bash
set -e

on_error() {
  echo "     ...failed on line $1!"
}

trap 'on_error $LINENO' ERR

echo "post-create.sh ..."

# Install EF Core CLI tool
dotnet tool install --global dotnet-ef

# Install workspace-level npm dependencies (concurrently, watch scripts)
npm install

# Install npm dependencies for each mounted source repo
for source_dir in /project/source/*/; do
  if [ -f "$source_dir/package.json" ]; then
    npm install --prefix "$source_dir"
  fi
done

# Restore the workspace solution stub for IDE tooling
dotnet restore \
  || echo "Warning: Solution restore failed — errors may be preventing a successful build."

echo "     ...complete!"
echo ""
echo "To refresh the database from production, run:"
echo "  bash .scripts/refresh-database.sh"
echo "Then rebuild the devcontainer to re-run the restore."
echo ""
