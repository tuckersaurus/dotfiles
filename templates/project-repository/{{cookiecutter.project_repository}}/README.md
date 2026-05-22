# {{cookiecutter.project_repository}}

## Structure

- `dotnet/src/` — .NET source projects (populated by `dotnet new`)
- `dotnet/tst/` — .NET test projects
- `postgres/` — Database schema definitions
- `.github/` — GitHub Actions workflows and PR/issue templates
- `.tools/` — Repository-scoped tooling and scripts

## Getting Started

### Install dependencies

```bash
npm run bootstrap
```

### Add a .NET project

After running `dotnet new` to create a project under `dotnet/src/`, add the project path to the `workspaces` array in `package.json` and update the `scripts` section accordingly.

### Database

Schema definitions live in `postgres/init.sql`. This file is sourced by the workspace devcontainer during database initialization. Add additional `CREATE SCHEMA` statements if this project spans multiple schemas.
