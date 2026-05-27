Add a .NET project to an existing workspace. Cascades: creates source repo / project on disk if needed; applies repo-level workspace patches if this source repo isn't already wired into the workspace.

**Arguments:** `workspace=<owner>/<ws_repo>` (optional), `repo=<owner>/<repo>` (optional), `project=<name>` (optional), `type=app|library` (optional), `schemas=<s1>,<s2>` (optional), `source_package=<pkg>` (optional), `push=true`, `visibility=private|public` (default `private`)

- `source_package` — unscoped npm package name (e.g. `zombie-miner`); needed when repo-level patches fire for the first time
- `schemas` — PostgreSQL schemas for the project; passed through to `/new-source-project` if project doesn't exist yet

**General non-interactive rule:** If all required args are provided, skip the confirmation step and proceed directly.

---

## Steps

### 1 — Resolve workspace

Same as `/add-source-repo` Step 1 (check disk, then GitHub, then clone; scan if no `workspace=` arg).

### 2 — Resolve source repo

Accept from `repo=` arg, or ask for `<owner>/<repo>`. Resolve same as `/add-source-repo` Step 4 (disk → GitHub clone → "Create it" via `/new-source-repo push=false visibility=<visibility>`).

### 3 — Project name and type

Accept from `project=` arg (or ask). Then:

**Project exists** at `dotnet/src/<project>/`:
- Detect type from `.csproj`: `Sdk="Microsoft.NET.Sdk.Web"` → app; else → library
- Use `type=` arg if provided, else confirm with user

**Project doesn't exist**:
- Use `type=` arg if provided, else ask
- Use `schemas=` arg if provided, else ask (same UX as `/new-source-project` Step 5)
- Call `/new-source-project repo=<owner>/<repo> project=<project> type=<type> schemas=<schemas> push=false visibility=<visibility>` (all args — no prompts inside)

### 4 — Idempotency check

Scan workspace `project.slnx` for `<Project Path=".../dotnet/src/<project>/...`. If found: warn ("this project is already in the workspace") and exit.

### 5 — Repo-level patches (if needed)

Scan workspace `package.json` for `"../source/<repo>"` in workspaces array.

If **not found** (first project from this repo):
- Auto-detect `source_package`: read `name` from source repo's `package.json`, strip `@<owner>/` prefix (e.g. `zombie-miner`). Use `source_package=` arg if provided instead.
- Apply all repo-level patches (same as `/add-source-repo` Step 8).

### 6 — Project-level patches

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

**`.vscode/launch.json`** (app only) — insert before `// <additional-launch-configs>`, keep marker. Check whether the `configurations` array already has entries (search for a `}` between `"configurations": [` and the marker); if this is the first entry omit the leading `,`, otherwise include it:
```json
    ,   ← omit if first entry
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

### 7 — Commit workspace

```bash
git -C <ws_path> add .
git -C <ws_path> commit -m "chore: add <project> to workspace"
```

If `push=true`: `git -C <ws_path> push`

### 8 — Push source repo (if new project was created)

Only if `/new-source-project` was called in Step 3 AND `push=true`:
- If source repo has a remote (`git -C <path> remote get-url origin` succeeds): `git -C <path> push`
- If no remote: use `visibility` arg (or ask if not provided), then:
  ```bash
  gh repo create <owner>/<repo> --<visibility> \
    --source="$HOME/projects/source/github/<owner>/<repo>" \
    --remote=origin --push
  ```

### 9 — Print summary

Print all paths and GitHub URLs (if pushed).
