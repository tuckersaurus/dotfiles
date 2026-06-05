#!/bin/bash
set -e

on_error() {
  echo "     ...failed on line $1!"
}

trap 'on_error $LINENO' ERR

echo "post-create.sh ..."

# Docker creates parent directories as root when mounting a single file into a non-existent path.
# Fix ownership so Claude Code (and anything else) can write inside ~/.claude/.
sudo chown vscode:vscode /home/vscode/.claude

# Required by the Todo-Tree extension (vscode-ripgrep was renamed to @vscode/ripgrep, breaking bundled resolution)
sudo apt-get update -y
sudo apt-get install -y ripgrep

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

# Install Playwright Chromium for MCP browser automation
npx playwright install chromium
npx playwright install-deps chromium

# Restore the workspace solution stub for IDE tooling
dotnet restore \
  || echo "Warning: Solution restore failed — errors may be preventing a successful build."

echo "     ...complete!"
echo ""
echo "To refresh the database from production, run:"
echo "  bash .scripts/refresh-database.sh"
echo "Then rebuild the devcontainer to re-run the restore."
echo ""
