# {{cookiecutter.ws_repository}}

Workspace repository for developing **{{cookiecutter.source_repo}}**. This repository contains the development environment configuration — source code lives in the companion project repository.

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
- Source repo (`{{cookiecutter.source_repo}}`): `/project/source/{{cookiecutter.source_repo}}/`

## Database

Initialization runs from `.postgres/01-int.sql` on first container start. It:
1. Creates the dev service user (credentials from `.env`)
2. Sources `postgres/init.sql` from each mounted project repo to create schemas and grants

To restore a production dump, run `.scripts/refresh-database.sh` then restart the container.

## Environment

Copy `.devcontainer/.env.sample` to `.devcontainer/.env` and fill in the required values before starting the container.
