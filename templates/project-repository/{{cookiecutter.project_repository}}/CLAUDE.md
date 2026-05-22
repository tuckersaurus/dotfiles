# {{cookiecutter.project_repository}}

## Tech Stack

- .NET 10 / C#
- PostgreSQL
- npm (asset pipeline: esbuild, sass, TypeScript)

## Repository Layout

- `dotnet/src/` — .NET source projects
- `dotnet/tst/` — .NET test projects
- `postgres/init.sql` — Schema namespace definitions for this project
- `.github/workflows/` — CI/CD pipelines
- `.tools/` — Repository-scoped scripts and tooling

## Conventions

- C# style rules are in `dotnet/.editorconfig` (`root = true`)
- npm devDependencies are declared once at the repo root `package.json`
- src project packages are light — scripts only, no devDependencies (rely on npm hoisting)
- Root npm package: `@{{cookiecutter.project_owner}}/{{cookiecutter.package}}`
- Database schema: `{{cookiecutter.db_schema}}` (see `postgres/init.sql`)
- SCSS linting config: `stylelint.config.mjs`
