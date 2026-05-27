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

# Install repo-level npm dependencies (sass, esbuild, cpx2, etc.)
npm install --prefix "/project/source/{{cookiecutter.source_repo}}"

# Apply EF Core migrations on top of restored dump (or from scratch if no dump)
dotnet ef database update --project "/project/source/{{cookiecutter.source_repo}}/dotnet/src/{{cookiecutter.source_project}}" \
  || echo "Warning: Migrations failed — ensure the database is reachable and the schema is initialized."

# Restore the workspace solution stub for IDE tooling
dotnet restore \
  || echo "Warning: Solution restore failed — errors may be preventing a successful build."

echo "     ...complete!"
echo ""
echo "To refresh the database from production, run:"
echo "  bash .scripts/refresh-database.sh"
echo "Then rebuild the devcontainer to re-run the restore."
echo ""
