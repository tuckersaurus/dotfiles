if command -v keychain >/dev/null 2>&1 && [ -f "$HOME/.ssh/id_ed25519" ]; then
    eval $(keychain --eval --quiet id_ed25519)
fi
