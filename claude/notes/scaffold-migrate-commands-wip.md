# WIP: /scaffold and /migrate Commands

> **Update:** Mode A below (new project scaffold) was implemented as `/new-environment`, then later renamed to `/scaffold` — naming has converged with the original plan. Its 6 supporting skills (create/add source repo, create/add source project, create/update workspace repo) were also renamed to a `scaffold-` prefix so they group together in autocomplete. Mode B (create a workspace for an *existing* GitHub repo, via a dedicated repo-picker) is **not** built — `/scaffold` only does GitHub lookup as a fallback within its existing linear flow, not Mode B's separate `gh repo list` picker. `/migrate` is also still unbuilt. Both remain open below.

## What was done this session

### New: `templates/project-repository/` cookiecutter template
Companion to the existing `workspace-repository` template. Generates a source code
repository skeleton with:
- `cookiecutter.json` — 4 variables: `project_repository`, `project_owner`, `package`, `db_schema`
- `package.json` — scoped (`@owner/package`), private, pre-loaded devDependencies, `workspaces: ["dotnet/src/<ProjectName>"]` placeholder, `--workspace=` script examples
- `stylelint.config.mjs` — standard SCSS config
- `postgres/init.sql` — `CREATE SCHEMA IF NOT EXISTS {{db_schema}}` + grants to `DB_USER` env var
- `dotnet/.editorconfig` — full C# ruleset (copied from ws-template)
- `dotnet/nuget.config` — nuget.org + GitHub Packages, env var auth
- `.vscode/launch.json` + `tasks.json` — generic JSONC stubs with comments
- `.github/` — PR template, bug report issue template, workflows placeholder
- `CLAUDE.md` — project context (no workspace refs)
- `LICENSE`, `README.md`, `.gitattributes`, `.gitignore`, `.editorconfig`

### Updated: `templates/workspace-repository/`
- `.postgres/01-int.sql` — now creates service user first, then `\i`s each project's `postgres/init.sql`
- `package.json` — workspace member changed from deep src path to project root; scripts use `--workspace=@owner/package` syntax
- `CLAUDE.md` — new file describing workspace purpose, container paths, database setup
- `.github/` — PR template, bug report issue template, workflows placeholder

### Updated: dotfiles infrastructure
- `claude/CLAUDE.md` — global Claude Code instructions (response style, comments, testing,
  npm exclusivity, destructive git confirmation, conventional commits, plan versioning)
- `claude/settings.json` — tracked in dotfiles (effortLevel: high, git/gh permissions)
- `install.sh` — symlinks `CLAUDE.md` and `settings.json` using `ln -sfr` (relative, safe for devcontainer mounts)
- `templates/NOTES.md` — note about keeping .github templates consistent across templates

---

## Next: /scaffold command

### Purpose
Orchestrate creating a new project + workspace repository pair, or creating a workspace
for an existing GitHub repository. Ensures the two cookiecutter templates are always
run as a matched pair with consistent variable values.

### Two modes (ask user at start)

**Mode A: New project**
1. Prompt for: `project_repository`, `project_owner`, `package` (default: project_repository), `db_schema` (default: project_repository with `-`→`_`)
2. Run `cookiecutter ~/dotfiles/templates/project-repository` with those values
3. Run `cookiecutter ~/dotfiles/templates/workspace-repository` pre-filling:
   - `source_repo` = `project_repository`
   - `source_owner` = `project_owner`
   - `source_package` = `package`
   - `workspace_owner` = `project_owner` (or ask separately)
4. Ask: create GitHub repos now? If yes, `gh repo create` for both (ask public/private)
5. Output next steps: clone repos, run `dotnet new`, populate `workspaces` in `package.json`

**Mode B: Existing GitHub repo (create workspace for it)**
1. `gh repo list --json name,owner,description --limit 50` → present list, user picks one
2. Try to read values from the selected repo via GitHub API:
   - `source_package`: `gh api repos/owner/repo/contents/package.json` → parse `name` field (strip `@owner/`)
   - `db_schema`: `gh api repos/owner/repo/contents/postgres/init.sql` → parse `CREATE SCHEMA IF NOT EXISTS <name>`
   - If either file doesn't exist (repo not using project-repository template), ask manually
3. Clone repo to correct local path: `gh repo clone owner/repo ~/projects/source/github/owner/repo`
4. Run `cookiecutter ~/dotfiles/templates/workspace-repository` with pre-filled values
5. Ask: create workspace GitHub repo? If yes, `gh repo create`
6. Output next steps

### Fallback handling
If the selected repo's `package.json` or `postgres/init.sql` don't match the expected
structure (not a project-repository template repo), note what couldn't be detected and
ask for those values manually before continuing.

### File location
`~/dotfiles/claude/commands/scaffold.md`

---

## Next: /migrate command

### Purpose
Wrap common EF Core migration commands with awareness of the `dotnet/src/` project layout.
Eliminates manually typing `--project` paths each time.

### Behavior
1. Scan `dotnet/src/` for projects (directories containing a `.csproj` file)
2. If multiple found, ask user to pick one. If only one, use it automatically.
3. Ask which operation:
   - `add <name>` — `dotnet ef migrations add <name> --project dotnet/src/<Project>`
   - `update` — `dotnet ef database update --project dotnet/src/<Project>`
   - `remove` — `dotnet ef migrations remove --project dotnet/src/<Project>`
   - `list` — `dotnet ef migrations list --project dotnet/src/<Project>`
4. Run the command, surface output. If `update` fails, show the error clearly.

### File location
`~/dotfiles/claude/commands/migrate.md`

---

## Branch to create when resuming
`feat/scaffold-migrate-commands`
