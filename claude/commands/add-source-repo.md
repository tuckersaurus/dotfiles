Add a source repo (with its projects) to an existing workspace. Creates the source repo and/or projects on disk if needed. Patches all workspace config files.

**Arguments:** `workspace=<owner>/<ws_repo>` (optional), `repo=<owner>/<repo>` (optional), `projects=<name>:<type>[,<name>:<type>]` (optional), `push=false`, `visibility=private|public` (default `private`)

- `projects` — skips the interactive project loop; all projects assumed to already exist on disk; format: `ZombieMiner.Web:app,ZombieMiner.Core:library`

**General non-interactive rule:** If all required args are provided, skip the confirmation step and proceed directly.

---

## Question style rules

- **Free-text inputs** (repo names, project names, schemas): plain conversational text — never use `AskUserQuestion`.
- **Fixed-choice inputs** (workspace selection, create-or-cancel, what-next, final confirm): use `AskUserQuestion`.

---

## Lookup logic

All lookups are silent — no output to the user unless an action is required.

- **Repo on disk:** check if `$HOME/projects/source/github/<owner>/<repo>` exists.
- **Repo on GitHub:** only if not found on disk — run `gh repo view <owner>/<repo>`.
- **Project on disk:** check if `$HOME/projects/source/github/<owner>/<repo>/dotnet/src/<ProjectName>` exists.
- **source_package:** always auto-derived — never asked. If repo is `new`: use repo name as-is (e.g. `zombie-miner`). If repo is `existing`: read `name` from source repo's `package.json` and strip the `@<owner>/` prefix silently.

---

## Collection phase (Steps 1–5)

### Step 1 — Resolve workspace

If `workspace=` arg provided: resolve path silently. Proceed to Step 2.

If not provided, scan silently:
1. **Disk:** `find ~/projects/source/github -maxdepth 2 -name "*.code-workspace" 2>/dev/null`
2. **GitHub:** `gh repo list tuckersaurus --json name --jq '.[] | select(.name | startswith("ws-")) | .name'` — exclude any already found on disk

Combine both lists. For each GitHub-only result, append `(GitHub)` to the name so the user knows it isn't local yet.

- **One result total:** `AskUserQuestion` — "Found ws-my-app. Use this workspace?" → `Use it` / `Cancel`
- **Multiple results:** `AskUserQuestion` listing each workspace name as an option
- **None:** error — no workspace found on disk or GitHub

If user selects a GitHub-only workspace: flag it as `needs-clone` — do not clone yet. The clone happens in the scaffold phase after confirmation.

### Step 2 — Source repo

If `repo=` arg provided: use it silently. Proceed to Step 3.

Otherwise, plain text:
1. "What is the source repository name? (e.g. zombie-miner)"
2. "Who owns this repository? (e.g. tuckersaurus)"

→ **Lookup** repo on disk, then GitHub if not found locally.

If **not found anywhere:** `AskUserQuestion` — "tuckersaurus/repo wasn't found. What would you like to do?"
- `Create it (private)`
- `Create it (public)`
- `Cancel`

If creating: flag repo as `new (private)` or `new (public)` based on the chosen option — do not create yet.

If **found on disk:** flag as `existing`.

If **found on GitHub only:** flag as `existing, needs-clone` — do not clone yet.

### Step 3 — Idempotency check

Scan workspace `package.json` for `"../source/<repo>"` in the workspaces array. Silent check — only output if a duplicate is detected, then warn and exit.

### Step 4 — Project loop

Skip entirely if `projects=` arg was provided — use those name:type pairs directly (all assumed to exist on disk).

Otherwise, for each project:

1. Plain text — list any auto-detected `.csproj` names from `dotnet/src/` as suggestions in the question text:
   > "What is the project name? (PascalCase, e.g. ZombieMiner.Web)"

2. → **Lookup** project on disk. If the source repo is `existing, needs-clone`, skip the disk lookup and run `gh api repos/<owner>/<repo>/contents/dotnet/src/<ProjectName>` instead (200 = exists, 404 = not found).

   If **existing:** detect type from `.csproj` (`Sdk="Microsoft.NET.Sdk.Web"` → App; else → Library) for on-disk repos. For GitHub-only repos, infer from the `.csproj` via `gh api repos/<owner>/<repo>/contents/dotnet/src/<ProjectName>/<ProjectName>.csproj`. Use silently — no confirmation question.

   If **new:**
   - `AskUserQuestion` — "ProjectName wasn't found. What would you like to do?" → `Create it (App)` / `Create it (Library)` / `Cancel`
   - Plain text: "Any PostgreSQL schemas? (comma-separated, e.g. zombie_miner — type 'none' for no schemas)"
   - Treat a response of `none` or `n` as no schemas — pass `schemas=` (empty string) to `/create-source-project`.
   - Flag project as `new (App)` or `new (Library)` with schemas stored — do not create yet.

3. `AskUserQuestion` — "What next?" → `Add another project` / `Done`

### Step 5 — Confirm

Skip if all required args were provided.

Display a scaffold plan using this format:

```
Adding to workspace: tuckersaurus/ws-my-app

  tuckersaurus/zombie-miner (private)                        [CREATE]
    └── ZombieMiner.Web    App    schemas: zombie_miner      [CREATE]
    └── ZombieMiner.Core   Library                           [EXISTING]
```

`AskUserQuestion`:
- `Looks good, proceed`
- `Go back and edit`

---

## Scaffold phase (Steps 6–9)

### Step 6 — Clone any GitHub-only items

For each item flagged `needs-clone` (workspace or source repo):
```bash
git clone git@github.com:<owner>/<repo>.git \
  $HOME/projects/source/github/<owner>/<repo>
```

### Step 7 — Create source repo (if new)

If repo is flagged `new`:
```
/create-source-repo owner=<owner> repo=<repo>
```
Skip if flagged `existing` or `existing, needs-clone`.

### Step 8 — Create new projects

For each project flagged `new (App)` or `new (Library)`:
```
/create-source-project repo=<owner>/<repo> project=<name> type=<app|library> schemas=<s1,s2>
```
Pass `schemas=` (empty string) for no schemas. Skip projects flagged `existing`.

### Step 9 — Patch workspace

For each project (both `new` and `existing`):
```
/update-workspace-repo workspace=<ws_owner>/<ws_repo> repo=<owner>/<repo> source_package=<source_package> project=<name> type=<app|library>
```

---

## Commit & push phase (Steps 10–11)

If `push=false`: skip this phase entirely.

### Step 10 — Commit workspace changes

The workspace is an existing repo — changes go via branch → PR, not directly to main.

```bash
git -C <ws_path> checkout -b chore/add-<repo>-to-workspace
git -C <ws_path> add .
git -C <ws_path> commit -m "chore: add <repo> to workspace"
git -C <ws_path> push -u origin chore/add-<repo>-to-workspace
gh pr create --repo <ws_owner>/<ws_repo> \
  --title "chore: add <repo> to workspace" \
  --body "Wires tuckersaurus/<repo> into the workspace config." \
  --base main
```

### Step 11 — Push source repo (if new)

Only if the source repo was flagged `new (private)` or `new (public)` in Step 2:
- If source repo already has a remote (`git -C <path> remote get-url origin` succeeds): `git -C <path> push`
- If no remote (repo was just created locally):
  ```bash
  git -C $HOME/projects/source/github/<owner>/<repo> add .
  git -C $HOME/projects/source/github/<owner>/<repo> commit -m "chore: initial scaffold"
  gh repo create <owner>/<repo> --<visibility> \
    --source="$HOME/projects/source/github/<owner>/<repo>" \
    --remote=origin --push
  ```
  This is initial creation — a single direct push to main is correct here.

---

### Step 10 — Print summary

Print all local paths and GitHub URLs (if pushed).
