# {{cookiecutter.ws_repository}}

Workspace repository for [{{cookiecutter.source_repo}}](https://github.com/{{cookiecutter.source_owner}}/{{cookiecutter.source_repo}}). Contains project configuration only — devcontainer, multi-root workspace, and dotnet solution stub. Source code lives in the source repository and is mounted as a volume in the devcontainer.

## Setup

### 1. Copy and fill in `.env`

```bash
cp .devcontainer/.env.sample .devcontainer/.env
```

Edit `.devcontainer/.env`:
- `POSTGRES_USER` / `POSTGRES_PASSWORD` — local superuser credentials (dev only; must also match VPS postgres container superuser for `refresh-database.sh`)
- `DB_NAME` — database name
- `DB_SCHEMA` — **must match production schema name** (cross-schema queries depend on this)
- `DB_USER` / `DB_PASSWORD` — local service account (dev only, does not need to match production)
- `VPS_USER` / `VPS_HOST` — SSH credentials for the production server

### 2. (Optional) Fetch a production database dump

Run from WSL **before** opening the devcontainer:

```bash
bash .scripts/refresh-database.sh
```

Saves a dump to `.postgres/latest.dump`. If skipped, the devcontainer starts with an empty database and only EF Core migrations are applied.

### 3. Open in devcontainer

Open the workspace in VS Code and reopen in container. On first start, the postgres container will:
1. Run `01-int.sql` — creates the schema and service user
2. Run `02-restore.sh` — restores the dump if one exists

Once postgres is healthy, `post-create.sh` installs dependencies and runs EF Core migrations.

## Refreshing the database

```bash
# From WSL
bash .scripts/refresh-database.sh

# Then: Dev Containers → Rebuild Container Without Cache
# (the postgres data volume must be deleted for init scripts to re-run)
```
