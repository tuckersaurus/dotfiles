Full guided flow for creating a complete workspace environment from scratch: collect all details interactively with silent lookups, scaffold everything on disk, then optionally push to GitHub.

**Arguments:** none — all inputs are collected interactively.

---

## Question style rules

- **Free-text inputs** (names, owners, schemas): plain conversational text — never use `AskUserQuestion`.
- **Fixed-choice inputs** (create-or-cancel, project type, what-next, confirm): use `AskUserQuestion`.

---

## Lookup logic

Lookups are silent — no output to the user. Run them immediately after collecting the relevant name/owner.

- **Repo on disk:** check if `$HOME/projects/source/github/<owner>/<repo>` exists.
- **Repo on GitHub:** only if not found on disk — run `gh repo view <owner>/<repo>`.
- **Project on disk:** check if `$HOME/projects/source/github/<owner>/<repo>/dotnet/src/<ProjectName>` exists.
- **Project on GitHub** (only when parent repo is `needs-clone`): `gh api repos/<owner>/<repo>/contents/dotnet/src/<ProjectName>` — 200 means exists, 404 means not found.

Flag each repo and project as `new`, `existing`, or `existing, needs-clone`.

- **Found on disk:** `existing`
- **Not on disk, found on GitHub:** `existing, needs-clone` — do not clone during questions
- **Not found anywhere:** prompts the create-or-cancel question

---

## Collection phase (Steps 1–5)

### Step 1 — Workspace

Ask as plain text:
1. "What should the workspace be called? (e.g. ws-sample)"

Workspace owner is always `tuckersaurus`. Workspace is always `new` and always private — no lookup, no visibility question.

### Step 2 — Source repo

Ask as plain text:
1. "What is the source repository name? (e.g. source-sample)"
2. "Who owns this repository? (e.g. tuckersaurus)"

→ **Lookup** repo on disk, then GitHub if not found locally.

If **not found:** `AskUserQuestion` — "owner/repo wasn't found. What would you like to do?"
- `Create it (private)` → flag repo as `new (private)`
- `Create it (public)` → flag repo as `new (public)`
- `Cancel` → quit `/new-environment` entirely

If **found on disk:** flag as `existing` — no further questions for the repo itself; proceed to Step 3.

If **found on GitHub only:** flag as `existing, needs-clone` — no further questions; proceed to Step 3.

### Step 3 — Project

Ask as plain text:
1. "What is the project name? (PascalCase, e.g. SourceProject.Web)"

→ **Lookup** `$HOME/projects/source/github/<owner>/<repo>/dotnet/src/<ProjectName>`.

If the parent repo is `needs-clone`, skip the disk lookup and instead run the GitHub API check: `gh api repos/<owner>/<repo>/contents/dotnet/src/<ProjectName>`.

If **not found:** `AskUserQuestion` — "ProjectName wasn't found. What would you like to do?"
- `Create it (App)` → flag project as `new (App)`
- `Create it (Library)` → flag project as `new (Library)`
- `Cancel` → quit `/new-environment` entirely

If creating: plain text: "Any PostgreSQL schemas? (comma-separated, e.g. my_app, security — type 'none' for no schemas)"

Treat a response of `none` or `n` as no schemas — pass `schemas=` (empty string) to `/create-source-project`.

If **found:** flag as `existing` — no further questions for this project.

### Step 4 — What next?

`AskUserQuestion`:
- **"Add another project"** → return to Step 3 (within the current repo context)
- **"Add another repo"** → return to Step 2
- **"Done"** → proceed to Step 5

### Step 5 — Confirm

Build and display a scaffold plan in this format:

```
Workspace
  tuckersaurus/ws-sample                                     [CREATE]

Source repos & projects
  tuckersaurus/new-repo (private)                            [CREATE]
    └── NewRepo.Web        App    schemas: new_repo          [CREATE]

  tuckersaurus/existing-repo                                 [LINK]
    └── ExistingProject.Web  App                             [LINK]
    └── NewProject.API       App    schemas: new_project     [CREATE]
```

`AskUserQuestion`:
- **"Looks good, scaffold it"** → proceed to Step 6
- **"Go back and edit"** → return to Step 1

---

## Scaffold phase — disk only (Steps 6–10)

Nothing is committed or pushed in this phase.

### Step 6 — Clone any GitHub-only repos

For each source repo flagged `existing, needs-clone`:
```bash
git clone git@github.com:<owner>/<repo>.git \
  $HOME/projects/source/github/<owner>/<repo>
```

### Step 7 — Create workspace

```
/create-workspace-repo workspace_owner=tuckersaurus ws_repository=<ws_repository>
```

### Step 8 — Create new source repos

For each repo flagged `new (private)` or `new (public)`:
```
/create-source-repo owner=<owner> repo=<repo>
```
Skip repos flagged `existing` or `existing, needs-clone`.

### Step 9 — Create new projects

For each project flagged `new (App)` or `new (Library)`:
```
/create-source-project repo=<owner>/<repo> project=<name> type=<app|library> schemas=<s1,s2>
```
Pass `schemas=` (empty string) for projects with no schemas. Skip projects flagged `existing`.

### Step 10 — Patch workspace config

For every project across all source repos (both `new` and `existing`):
```
/update-workspace-repo workspace=<owner>/<ws_repository> repo=<owner>/<repo> source_package=<repo_name> project=<name> type=<app|library>
```
where `source_package` is the part after `/` in `<owner>/<repo>`. Call once per project — the skill handles repo-level patches automatically on the first project from each repo.

---

## GitHub phase (Step 11)

`AskUserQuestion`:
- **"Yes, push to GitHub"** → proceed below
- **"No, keep local only"** → skip to Step 12

For each **new** repo — workspace first, then source repos in collection order:

```bash
git -C $HOME/projects/source/github/<owner>/<repo> add .
git -C $HOME/projects/source/github/<owner>/<repo> commit -m "chore: initial scaffold"
gh repo create <owner>/<repo> --private \
  --source="$HOME/projects/source/github/<owner>/<repo>" \
  --remote=origin --push
git -C $HOME/projects/source/github/<owner>/<repo> branch --set-upstream-to=origin/main main
```

Use `--public` for repos flagged as `public`. The commit here captures the full initial state — cookiecutter output plus all workspace wiring — in a single first commit. No branch or PR needed; direct-to-main is correct for initial repo creation only.

For **existing** source repos: nothing to push — they were not modified.

---

## Step 12 — Completion summary

Print:
- All local paths created or linked
- GitHub URLs for any repos that were pushed (if Step 11 ran)
