#!/bin/bash
set -e

echo "Symlinking .gitconfig..."
ln -sf ~/dotfiles/.gitconfig ~/.gitconfig
echo "  done."

echo "Symlinking Claude CLAUDE.md..."
ln -sf ~/dotfiles/claude/CLAUDE.md ~/.claude/CLAUDE.md
echo "  done."

echo "Symlinking Claude settings.json..."
ln -sf ~/dotfiles/claude/settings.json ~/.claude/settings.json
echo "  done."

echo "Symlinking Claude commands..."
mkdir -p ~/.claude/commands
for cmd in ~/dotfiles/claude/commands/*.md; do
    ln -sf "$cmd" ~/.claude/commands/"$(basename "$cmd")"
done
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

if command -v cookiecutter &>/dev/null; then
    echo "cookiecutter already installed, skipping."
elif command -v python3 &>/dev/null; then
    echo "Installing cookiecutter..."
    curl -sS https://bootstrap.pypa.io/get-pip.py -o /tmp/get-pip.py
    python3 /tmp/get-pip.py --user --break-system-packages --quiet
    ~/.local/bin/pip install cookiecutter --break-system-packages --quiet
    echo "  done."
else
    echo "python3 not found, skipping cookiecutter installation."
fi

if command -v dotnet &>/dev/null; then
    echo "Installing dotnet templates..."
    shopt -s nullglob
    for tmpl in ~/dotfiles/templates/dotnet/*/; do
        dotnet new install "$tmpl"
        echo "  installed $(basename "${tmpl%/}")"
    done
    shopt -u nullglob
    echo "  done."
else
    echo "dotnet not found, skipping dotnet template installation."
fi

echo "Dotfiles installed. Run: source ~/.bashrc"
