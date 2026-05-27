⚠️ Deprecated — use `/new-workspace-repo` + `/add-source-repo` instead.

Create a new **workspace repository** from the `workspace-repository-old` cookiecutter template and push it to GitHub. A workspace repo contains the devcontainer, VS Code workspace config, and .NET solution stub that wrap one or more source project repos.

Use this skill when you already know the source repos and projects. For a guided flow that also resolves or creates the source repos, use `/new-workspace-project` instead.

The template lives at `~/dotfiles/templates/workspace-repository-old`. Workspace repos are named with a `ws-` prefix (e.g., `ws-zombie-miner`, `ws-game-tools`) and live at `~/projects/source/github/<workspace_owner>/<ws_repository>/`.

## Collecting inputs (looping style)

### Step 1 — First source repo

Ask for the first source repo as `<owner>/<repo>` (e.g., `house-hippo-handlers/zombie-miner`).

Ask for the npm package name (`source_package`), defaulting to the full scoped name `@<source_owner>/<repo_name>` (e.g. `@tuckersaurus/zombie-miner`). Present one option `Accept "@<source_owner>/<repo_name>"` with description "Use Other to enter a different package name." Do NOT add a separate "Override it" option.

This repo becomes the **current repo**.

### Step 2 — First source project

Ask for the first .NET project from the current repo:
- Project name (PascalCase `.csproj` name, e.g. `ZombieMiner.Web`)
- Project type: **app** (🚀 — launchable, gets launch config and Run tasks) or **library** (📚 — no launch config)

### Step 3 — Loop: "What next?"

Use `AskUserQuestion` with these options:
- **"Add another project"** → Ask for project name and type. Automatically assigned to the current repo (no need to re-ask which repo). Return to step 3.
- **"Add another repo"** → Ask for the next repo as `<owner>/<repo>` and its `source_package` (default to the full scoped name `@<owner>/<repo>`, same UX as Step 1). That repo becomes the new current repo. Then ask for its first project (step 2). Return to step 3.
- **"Done"** → Exit the loop.

### Step 4 — Workspace parameters

Ask for:
- `workspace_owner` — GitHub owner for the workspace repo (default: owner of the first source repo)
- `ws_repository` — workspace repo name (suggest `ws-<source_repo>` for a single-repo workspace; for multi-repo, let the user choose freely but remind them of the `ws-` prefix convention)

### Step 5 — Confirm

Present a full summary of all collected values (source repos, source projects, workspace params) via `AskUserQuestion` before proceeding.

---

## Scaffolding

### Step 6 — Run cookiecutter with the first source repo and project

Cookiecutter scaffolds using the first source repo and first project as scalar parameters:

```bash
cookiecutter ~/dotfiles/templates/workspace-repository-old \
  --no-input \
  --output-dir ~/projects/source/github/<workspace_owner> \
  ws_repository=<ws_repository> \
  workspace_owner=<workspace_owner> \
  source_owner=<source_owner_1> \
  source_repo=<source_repo_1> \
  source_project=<source_project_1> \
  source_package=<source_package_1>
```

The `project.code-workspace` now uses three typed markers — all projects and repo roots are patched in by the skill (none are pre-populated by the scaffold). This guarantees the folder order: Workspace → Apps → Libraries → Repositories.

### Step 7 — Patch source repos

> **Scope rules:** `docker-compose.yml`, `01-int.sql`, `package.json`, and `tasks.json` are pre-populated with the first repo by the cookiecutter scaffold — patch these for **repos 2..N only**. `project.code-workspace` has no pre-populated repo entries — patch it for **all repos (1..N)**.

**`project.code-workspace`** (all repos 1..N) — replace `// <repo-roots>` with the repo's root folder AND keep the marker:
```json
    ,
    {
      "name": "🏁 Repository : <source_repo>",
      "path": "../source/<source_repo>"
    }
    // <repo-roots>
```

**`docker-compose.yml`** (repos 2..N only) — replace `# <additional-source-repos>` with the new volume mount AND keep the marker:
```yaml
      - ${HOME}/projects/source/github/<source_owner>/<source_repo>:/project/source/<source_repo>
      # <additional-source-repos>
```

**`01-int.sql`** (repos 2..N only) — replace `-- <additional-source-repos>` with the new `\i` line AND keep the marker:
```sql
\i /project/source/<source_repo>/postgres/init.sql
-- <additional-source-repos>
```

**`package.json`** (repos 2..N only) — append to `workspaces` array, add watch script, and extend the `concurrently` call:
- Add `"../source/<source_repo>"` to `workspaces`
- Add `"watch:<source_repo>": "npm --workspace=@<source_owner>/<source_package> run watch:web"` to `scripts`
- Append `\"npm run watch:<source_repo>\"` to the `watch` concurrently call

**`tasks.json`** (repos 2..N only) — replace `// <additional-tasks>` with the new `Watch : <repo>` task AND keep the marker:
```json
    ,
    {
      "label": "Watch : <source_repo>",
      "type": "shell",
      "command": "npm",
      "args": ["run", "watch:<source_repo>"],
      "problemMatcher": [],
      "group": "build",
      "isBackground": true,
      "runOptions": { "reevaluateOnRerun": true }
    }
    // <additional-tasks>
```

### Step 8 — Patch ALL source projects (projects 1..M)

For **every** source project, apply the following patches. App-type projects go at `// <app-projects>`; library-type go at `// <library-projects>`. This guarantees the folder order regardless of the order projects were entered.

**`project.code-workspace`** — for apps, replace `// <app-projects>`; for libraries, replace `// <library-projects>`. Keep the marker in both cases:
```json
    ,
    {
      "name": "🚀 <project>" (or 📚 for library),
      "path": "../source/<project_source_repo>/dotnet/src/<project>"
    }
    // <app-projects>   ← (or // <library-projects> for 📚)
```

**`project.slnx`** — replace `<!-- <additional-source-projects> -->` with the `<Project>` element AND keep the marker:
```xml
  <Project Path="../source/<project_source_repo>/dotnet/src/<project>/<project>.csproj" />
  <!-- <additional-source-projects> -->
```

**`tasks.json`** (app type only) — replace `// <additional-tasks>` with Run tasks AND keep the marker:
```json
    ,
    {
      "label": "Run <project>",
      "type": "shell",
      "command": "dotnet",
      "args": ["watch", "run", "--launch-profile", "dev-container", "--project",
               "${workspaceFolder:🚀 <project>}/<project>.csproj"],
      "problemMatcher": "$msCompile",
      "group": "build",
      "runOptions": { "reevaluateOnRerun": true },
      "isBackground": true,
      "options": { "env": { "ASPNETCORE_URLS": "http://0.0.0.0:5000" } }
    },
    {
      "label": "Run + Watch <project>",
      "dependsOn": ["Run <project>", "Watch Assets"],
      "dependsOrder": "parallel",
      "group": "build"
    }
    // <additional-tasks>
```

**`launch.json`** (app type only) — replace `// <additional-launch-configs>` with the config AND keep the marker:
```json
    ,
    {
      "name": "Launch <project>",
      "type": "coreclr",
      "request": "launch",
      "program": "${workspaceFolder:🚀 <project>}/bin/Debug/net10.0/<project>.dll",
      "cwd": "${workspaceFolder:🚀 <project>}",
      "preLaunchTask": "Run + Watch <project>"
    }
    // <additional-launch-configs>
```

---

## Finalize

### Step 9 — Initialize git and commit

```bash
git -C ~/projects/source/github/<workspace_owner>/<ws_repository> init
git -C ~/projects/source/github/<workspace_owner>/<ws_repository> add .
git -C ~/projects/source/github/<workspace_owner>/<ws_repository> commit -m "chore: initial workspace scaffold from template"
```

### Step 10 — Create GitHub repo and push

Ask the user whether the repo should be `--private` or `--public` (default: private).

```bash
gh repo create <workspace_owner>/<ws_repository> --private \
  --source="$HOME/projects/source/github/<workspace_owner>/<ws_repository>" \
  --remote=origin --push
```

### Step 11 — Confirm success

Print:
- Local path: `~/projects/source/github/<workspace_owner>/<ws_repository>`
- GitHub URL: `https://github.com/<workspace_owner>/<ws_repository>`
