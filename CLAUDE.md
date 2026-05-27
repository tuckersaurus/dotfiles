# dotfiles

Personal dotfiles and development environment configuration.

## Repository Layout

- `claude/CLAUDE.md` — global Claude Code instructions (symlinked to `~/.claude/CLAUDE.md`)
- `claude/settings.json` — Claude Code settings: allowlist, MCP servers, effort level (symlinked to `~/.claude/settings.json`)
- `claude/commands/` — custom slash skills (symlinked into `~/.claude/commands/`)
- `templates/` — cookiecutter templates for workspace and source repositories
- `bash/` — shell configuration sourced by `.bashrc`
- `scripts/` — helper scripts added to `PATH` by `install.sh`
- `install.sh` — run on new machines and devcontainers; creates all symlinks

## README Maintenance

**Whenever making changes to this repo, update `README.md` to reflect them.** Specifically:

- **New or modified skills** (`claude/commands/`) — if the skill requires bash commands not already in the allowlist (step 11 of README), add those entries to `claude/settings.json` and update the allowlist reference block in the README.
- **Template changes** (`templates/`) — update the relevant step description in the README if the scaffold workflow changes.
- **`install.sh` changes** — re-run `bash ~/dotfiles/install.sh` after editing to verify symlinks are correct; update step 5 of the README if the install process changes.

## install.sh Notes

`install.sh` creates symlinks with `ln -sf` — it does **not** remove stale symlinks when source files are renamed. After renaming or deleting a file that was previously symlinked, manually remove the stale link:

```bash
find ~/.claude/commands -maxdepth 1 -name "*.md" -type l | while read link; do
  target=$(readlink "$link")
  if [ ! -f "$target" ]; then rm "$link"; fi
done
```

Then re-run `bash ~/dotfiles/install.sh`.
