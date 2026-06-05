#!/bin/bash
set -e

on_error() {
  echo "     ...failed on line $1!"
}

trap 'on_error $LINENO' ERR

echo "post-attach.sh ..."

# Symlink workspace memory into the Claude Code projects directory so it
# survives container rebuilds (the source of truth lives in the repo).
MEMORY_SOURCE="/project/workspace/.claude/memory"
MEMORY_TARGET="/home/vscode/.claude/projects/-project-workspace/memory"
mkdir -p "$(dirname "$MEMORY_TARGET")"
if [ -L "$MEMORY_TARGET" ]; then
  rm "$MEMORY_TARGET"
fi
ln -s "$MEMORY_SOURCE" "$MEMORY_TARGET"

echo "     ...complete!"
