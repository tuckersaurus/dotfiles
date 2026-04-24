#!/bin/bash
set -e

DOTFILES="$HOME/dotfiles"

echo "Adding dotfiles source block to ~/.bashrc..."
BLOCK='
# --- dotfiles ---
for f in ~/dotfiles/bash/*.sh; do
    [ -f "$f" ] && source "$f"
done
[ -f ~/.secrets ] && source ~/.secrets'

if ! grep -q "dotfiles" ~/.bashrc; then
    echo "$BLOCK" >> ~/.bashrc
    echo "  done."
else
    echo "  already present, skipping."
fi

echo "Dotfiles installed. Run: source ~/.bashrc"
