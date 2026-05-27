Add a source repo (with its projects) to an existing workspace. Creates the source repo and/or projects on disk if needed. Patches all workspace config files and commits.

**Arguments:** `workspace=<owner>/<ws_repo>` (optional), `repo=<owner>/<repo>` (optional), `source_package=<pkg>` (optional), `projects=<name>:<type>[,<name>:<type>]` (optional), `push=true`, `visibility=private|public` (default `private`)

- `source_package` — unscoped npm package name (e.g. `zombie-miner`, not `@tuckersaurus/zombie-miner`); skips Step 5 prompt when provided
- `projects` — skips the interactive project loop; all projects assumed to already exist on disk; format: `ZombieMiner.Web:app,ZombieMiner.Core:library`

**General non-interactive rule:** If all required args are provided, skip the confirmation step and proceed directly.

---

## Steps

### 1 — Resolve workspace

- If `workspace=<owner>/<ws_repo>` provided → use `~/projects/source/github/<owner>/<ws_repo>`
- Else scan: `find ~/projects/source/github -maxdepth 2 -name "project.code-workspace" 2>/dev/null`
  - One result: confirm with user
  - Multiple: present as options
  - None: error
- If workspace path not on disk: `gh repo view <owner>/<ws_repo>` — clone if found on GitHub, else error

### 2 — Accept or ask for source repo

Accept from `repo=` arg, or ask for `<owner>/<repo>`.

### 3 — Idempotency check

Scan workspace `package.json` for `"../source/<repo>"` in workspaces array. If found: warn ("this repo is already in the workspace") and exit.

### 4 — Resolve source repo

- On disk: proceed.
- Not on disk: `gh repo view <owner>/<repo> --json name`
  - Found on GitHub → clone it
  - Not found → offer **"Create it"** (`/new-source-repo owner=<owner> repo=<repo> push=false visibility=<visibility>`) or **"Cancel"**

### 5 — Detect source_package

Skip if `source_package=` arg provided.

Otherwise: read `name` from `~/projects/source/github/<owner>/<repo>/package.json`, strip `@<owner>/` prefix to get the unscoped name (e.g. `@tuckersaurus/zombie-miner` → `zombie-miner`). Present `Accept "zombie-miner" (@tuckersaurus/zombie-miner)` + Other.

Note: `source_package` must be the unscoped name — the patch template uses `@<source_owner>/<source_package>`.

### 6 — Project loop

Skip entirely if `projects=` arg was provided — use those name:type pairs directly (projects assumed to exist on disk already).

Otherwise (interactive):
- Auto-detect `.csproj` names in `dotnet/src/` for suggestions
- Ask project name
- If project exists at `dotnet/src/<project>/`: detect type from `.csproj` (`Sdk="Microsoft.NET.Sdk.Web"` → app; else → library) — confirm with user
- If project doesn't exist: ask type + schemas → call `/new-source-project repo=<owner>/<repo> project=<project> type=<type> schemas=<schemas> push=false visibility=<visibility>` (all args — no prompts inside)
- Ask "Add another project?" — loop

### 7 — Confirm

Skip if all required args were provided.

### 8 — Patch workspace — repo-level

**`project.code-workspace`** — insert before `// <repo-roots>`, keep marker:
```json
    ,
    {
      "name": "🏁 Repository : <repo>",
      "path": "../source/<repo>"
    }
    // <repo-roots>
```

**`.devcontainer/docker-compose.yml`** — insert before `# <additional-source-repos>`, keep marker:
```yaml
      - ${HOME}/projects/source/github/<owner>/<repo>:/project/source/<repo>
      # <additional-source-repos>
```

**`.postgres/01-int.sql`** — insert before `-- <additional-source-repos>`, keep marker:
```sql
\i /project/source/<repo>/postgres/init.sql
-- <additional-source-repos>
```

**`package.json`**:
- Add `"../source/<repo>"` to the `workspaces` array
- Add `"watch:<repo>": "npm --workspace=@<source_owner>/<source_package> run watch:web"` to `scripts`
- Update `watch` script: if value is `"concurrently"` (bare) → replace with `"concurrently \"npm run watch:<repo>\""`, else append ` \"npm run watch:<repo>\"`

**`.vscode/tasks.json`** — insert before `// <additional-tasks>`, keep marker:
```json
    ,
    {
      "label": "Watch : <repo>",
      "type": "shell",
      "command": "npm",
      "args": ["run", "watch:<repo>"],
      "problemMatcher": [],
      "group": "build",
      "isBackground": true,
      "runOptions": { "reevaluateOnRerun": true }
    }
    // <additional-tasks>
```

### 9 — Patch workspace — project-level

For each project (same patches as `/add-source-project` Step 6):

**`project.code-workspace`** — insert before `// <app-projects>` (app) or `// <library-projects>` (library), keep marker:
```json
    ,
    {
      "name": "🚀 <project>",   (or 📚 for library)
      "path": "../source/<repo>/dotnet/src/<project>"
    }
    // <app-projects>
```

**`project.slnx`** — insert before `<!-- <additional-source-projects> -->`, keep marker:
```xml
  <Project Path="../source/<repo>/dotnet/src/<project>/<project>.csproj" />
  <!-- <additional-source-projects> -->
```

**`.vscode/tasks.json`** (app only) — insert before `// <additional-tasks>`, keep marker:
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

**`.vscode/launch.json`** (app only) — insert before `// <additional-launch-configs>`, keep marker:
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

### 10 — Commit workspace

```bash
git -C <ws_path> add .
git -C <ws_path> commit -m "chore: add <repo> to workspace"
```

If `push=true`: `git -C <ws_path> push`

### 11 — Push source repo (if new project was created)

Only if `/new-source-project` was called in Step 6 AND `push=true`:
- If source repo has a remote (`git -C <path> remote get-url origin` succeeds): `git -C <path> push`
- If no remote: use `visibility` arg (or ask if not provided), then:
  ```bash
  gh repo create <owner>/<repo> --<visibility> \
    --source="$HOME/projects/source/github/<owner>/<repo>" \
    --remote=origin --push
  ```

### 12 — Print summary

Print all paths and GitHub URLs (if pushed).
