#!/bin/bash
set -e

echo "Symlinking .gitconfig..."
ln -sf ~/dotfiles/.gitconfig ~/.gitconfig
# VS Code injects a runtime-specific credential helper into ~/.gitconfig on every attach.
# skip-worktree tells git to ignore local modifications so it never shows as a diff.
git -C ~/dotfiles update-index --skip-worktree .gitconfig
echo "  done."

echo "Switching dotfiles remote to SSH..."
git -C ~/dotfiles remote set-url origin git@github.com:tuckersaurus/dotfiles.git
echo "  done."

echo "Fixing ~/.claude ownership (may have been created by root)..."
sudo mkdir -p ~/.claude
sudo chown -R "$(whoami):$(whoami)" ~/.claude
echo "  done."

echo "Symlinking Claude CLAUDE.md..."
mkdir -p ~/.claude
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
for f in ~/dotfiles/scripts/*; do
    [ -f "$f" ] && chmod +x "$f"
done
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
else
    echo "Installing cookiecutter via pipx..."
    sudo apt-get update -qq
    sudo apt-get install -y pipx python3 python3-venv --quiet
    pipx install cookiecutter
    echo "  done."
fi

echo "Dotfiles installed. Run: source ~/.bashrc"
