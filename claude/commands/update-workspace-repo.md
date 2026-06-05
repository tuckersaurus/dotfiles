Patch an existing workspace repository to wire in a source repo and/or project. Applies repo-level patches (once per source repo — only on the first project from that repo) and project-level patches. Both patch types are idempotent: if the repo or project is already wired, that patch is skipped. Disk only — no git, no GitHub.

**This skill is non-interactive.** All required data must be supplied as arguments. No questions are asked.

**Arguments (all required):** `workspace=<owner>/<ws_repo>`, `repo=<owner>/<repo>`, `source_package=<pkg>`, `project=<name>`, `type=app|library`

- `source_package` — unscoped npm package name for the source repo (e.g. `zombie-miner`, not `@<owner>/zombie-miner`)

---

## Safety checks

Abort with a clear error message if any of the following are not met:

- All arguments are provided and non-empty
- `type` is exactly `app` or `library`
- Workspace exists on disk at `~/projects/source/github/<owner>/<ws_repo>`
- Source repo exists on disk at `~/projects/source/github/<owner>/<repo>`

---

## Step 1 — Repo-level patches (idempotent)

Scan workspace `package.json` for `"../source/<repo>"` in the workspaces array.

If **already present**: skip all repo-level patches and proceed to Step 2.

If **not present**, apply the following patches:

**`<ws_repo>.code-workspace`** — insert before `// <repo-roots>`, keep marker:
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
\i /schemas/<repo>/init.sql
-- <additional-source-repos>
```

**`.devcontainer/docker-compose.yml`** (postgres service) — insert before `# <additional-source-repo-schemas>`, keep marker:
```yaml
      - ${HOME}/projects/source/github/<owner>/<repo>/postgres:/schemas/<repo>:ro
      # <additional-source-repo-schemas>
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

---

## Step 2 — Project-level patches (idempotent)

Scan workspace `<ws_repo>.slnx` for `<Project Path=".../dotnet/src/<project>/..."`.

If **already present**: skip all project-level patches and proceed to Step 3.

If **not present**, apply the following patches:

**`<ws_repo>.code-workspace`** — insert before `// <app-projects>` (app) or `// <library-projects>` (library), keep marker:
```json
    ,
    {
      "name": "🚀 <project>",   (or 📚 for library)
      "path": "../source/<repo>/dotnet/src/<project>"
    }
    // <app-projects>
```

**`<ws_repo>.slnx`** — insert before `<!-- <additional-source-projects> -->`, keep marker:
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

---

## Step 3 — Print result

Print which patches were applied (repo-level, project-level, or both) and which were skipped as already present.
