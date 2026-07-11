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

`install.sh` creates symlinks with `ln -sf` and automatically removes any
`~/.claude/commands/*.md` symlink that points into this repo's
`claude/commands/` but whose target no longer exists (e.g. after a skill is
renamed or deleted). Re-run `bash ~/dotfiles/install.sh` after any such
change to apply both the new links and the cleanup in one pass.
