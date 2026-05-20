#!/bin/bash
set -e

echo "Symlinking .gitconfig..."
ln -sf ~/dotfiles/.gitconfig ~/.gitconfig
echo "  done."

echo "Symlinking Claude commands..."
mkdir -p ~/.claude/commands
ln -sf ~/dotfiles/claude/commands/commit.md ~/.claude/commands/commit.md
echo "  done."

echo "Symlinking .gitignore_global..."
ln -sf ~/dotfiles/.gitignore_global ~/.gitignore_global
echo "  done."

echo "Setting script permissions..."
chmod +x ~/dotfiles/scripts/*.sh
echo "  done."

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

if command -v dotnet &>/dev/null; then
    echo "Installing dotnet templates..."
    shopt -s nullglob
    for tmpl in ~/dotfiles/dotnet/templates/*/; do
        dotnet new install "$tmpl"
        echo "  installed $(basename "${tmpl%/}")"
    done
    shopt -u nullglob
    echo "  done."
else
    echo "  dotnet not found, skipping template installation."
fi

echo "Dotfiles installed. Run: source ~/.bashrc"
