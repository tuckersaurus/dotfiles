Full guided flow for creating a complete workspace environment from scratch: collect all details interactively, then scaffold everything in the right order and wire it together.

**Arguments:** `push=true`, `visibility=private|public` (default `private`)

---

## Collection phase (Steps 1–5)

### Step 1 — Workspace params

Ask for:
- `workspace_owner` (default `tuckersaurus`)
- `ws_repository` (ws- prefix convention; suggest `ws-<first_repo>` once the first repo is known)

### Step 2 — First source repo

Ask for the first source repo as `<owner>/<repo>`.

### Step 3 — First project

Ask for:
- Project name (PascalCase, e.g. `ZombieMiner.Web`)
- Project type: **app** (🚀) or **library** (📚)
- PostgreSQL schemas for this project: suggest snake_case of project name; option for none; loop to add more

### Step 4 — Loop: "What next?"

Use `AskUserQuestion`:
- **"Add another project"** → ask project name + type + schemas, assign to current repo. Return to step 4.
- **"Add another repo"** → ask for `<owner>/<repo>`, it becomes the current repo. Ask its first project (name + type + schemas). Return to step 4.
- **"Done"** → exit loop.

### Step 5 — Confirm

Present full summary (workspace + all repos + all projects + schemas). Use `AskUserQuestion` to confirm.

---

## Scaffold phase (Steps 6–13)

All sub-skill calls pass args explicitly — no interactive prompts fire inside the sub-skills.

### Step 6 — Create workspace

```
/new-workspace-repo workspace_owner=<workspace_owner> ws_repository=<ws_repository> push=false
```

### Step 7 — Create each source repo

For each source repo:
```
/new-source-repo owner=<owner> repo=<repo> push=false
```

### Step 8 — Create each project

For each project in each source repo:
```
/new-source-project repo=<owner>/<repo> project=<name> type=<app|library> schemas=<s1,s2> push=false
```
(Pass `schemas=` (empty) for projects with no schemas.)

### Step 9 — Visibility

If `push=true` (default): ask private/public for all repos at once, or use `visibility=` arg if provided.

If `push=false`: skip Steps 9–12.

### Step 10 — Push workspace to GitHub

```bash
gh repo create <workspace_owner>/<ws_repository> --<visibility> \
  --source="$HOME/projects/source/github/<workspace_owner>/<ws_repository>" \
  --remote=origin --push
```

### Step 11 — Push each source repo to GitHub

For each source repo:
```bash
gh repo create <owner>/<repo> --<visibility> \
  --source="$HOME/projects/source/github/<owner>/<repo>" \
  --remote=origin --push
```

### Step 12 — Patch workspace for each source repo

For each source repo (workspace already has a remote from Step 10):
```
/add-source-repo workspace=<workspace_owner>/<ws_repository> repo=<owner>/<repo> source_package=<repo_name> projects=<name>:<type>[,<name>:<type>] push=true visibility=<visibility>
```
where `source_package` = the part after `/` in `<owner>/<repo>` (matches the package default set by `new-source-repo`).

If `push=false`:
```
/add-source-repo workspace=<workspace_owner>/<ws_repository> repo=<owner>/<repo> source_package=<repo_name> projects=<name>:<type>[,<name>:<type>] push=false
```

### Step 13 — Print completion summary

Print all local paths and GitHub URLs (if pushed).
