# {{cookiecutter.ws_repository}}

Workspace repository for **{{cookiecutter.ws_repository}}**. Contains the development environment configuration — source code lives in companion source repositories mounted as volumes in the devcontainer.

## What This Workspace Provides

- **Dev container** — Docker-based development environment with .NET, Node.js, and PostgreSQL
- **VS Code workspace** — Multi-root workspace linking workspace config and source repository
- **Database tooling** — Schema initialization and production dump restore scripts

## Structure

- `.devcontainer/` — Dev container configuration (devcontainer.json, docker-compose.yml, lifecycle scripts)
- `.postgres/` — Database initialization scripts (sourced by PostgreSQL on first start)
- `.scripts/` — Utility scripts (e.g., refresh-database.sh for fetching production dumps)
- `.vscode/` — VS Code launch and task configurations
- `project.code-workspace` — Multi-root VS Code workspace file
- `project.slnx` — .NET solution stub for tooling

## Container Paths

When running inside the dev container:

- Workspace: `/project/workspace/`
- Source repos: `/project/source/<repo>/` (one per wired source repo)

## Database

Initialization runs from `.postgres/01-int.sql` on first container start. It:
1. Creates the dev service user (credentials from `.env`)
2. Sources `postgres/init.sql` from each mounted project repo to create schemas and grants

To restore a production dump, run `.scripts/refresh-database.sh` then restart the container.

## Claude Memory

Project memory lives in `.claude/memory/` in this repo and is symlinked into Claude Code's memory system on every container attach (`post-attach.sh`). This means memory survives container rebuilds.

**All project-specific memory belongs in `.claude/memory/`** — TODOs, architectural decisions, discovered patterns, next steps. There is no meaningful local-only alternative for project memory in this setup.

**Do not store** in `.claude/memory/`:
- `settings.local.json` or any credentials (gitignored)
- User preferences or cross-project workflow patterns — those belong in `~/dotfiles/claude/`

## Environment

Copy `.devcontainer/.env.sample` to `.devcontainer/.env` and fill in the required values before starting the container.
