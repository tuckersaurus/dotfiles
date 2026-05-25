Full guided flow for creating a new workspace: resolve or create source repos, ensure they're on disk, auto-detect properties, then delegate to `/new-github-workspace` to scaffold and publish the workspace repo.

Use `/new-github-workspace` directly if you already know all source repo and project names.

---

## Step 1 — First source repo

Ask for the first source repo as `<owner>/<repo>`.

Run `gh repo view <owner>/<repo> --json name,owner` to check if it exists:

**Found** — proceed to cloning check.

**Not found** — use `AskUserQuestion`:
- **"Create it"** — ask the user for permission to invoke `/new-github-project`, then invoke it with the given owner and repo name. Wait for it to complete before continuing. The newly created repo is now the first source repo.
- **"Choose a different repo"** — fetch available repos (personal + all orgs), filter out `ws-` prefix repos, present as options:
  ```bash
  # Personal repos
  gh repo list --limit 100 --json name,owner --no-archived
  # Org repos
  gh api /user/orgs --jq '.[].login' | while read org; do
    gh repo list "$org" --limit 100 --json name,owner --no-archived
  done
  ```
  Once the user selects a repo, that becomes the first source repo.

**Clone if not on disk:**
```bash
ls ~/projects/source/github/<owner>/<repo> 2>/dev/null || \
  git clone git@github.com:<owner>/<repo>.git ~/projects/source/github/<owner>/<repo>
```

**Auto-detect `source_package`**: read the `name` field from `~/projects/source/github/<owner>/<repo>/package.json` and strip the `@<owner>/` prefix. Confirm with the user (they can override).

This repo becomes the **current repo**.

---

## Step 2 — First source project

Auto-detect available `.csproj` files in the current repo:
```bash
find ~/projects/source/github/<owner>/<repo>/dotnet/src -name "*.csproj" 2>/dev/null | xargs -I{} basename {} .csproj
```

Present the found project names as suggestions via `AskUserQuestion`. The user confirms or types a different name.

Ask for project type: **app** (🚀) or **library** (📚).

---

## Step 3 — Loop: "What next?"

Use `AskUserQuestion` with these options:

- **"Add another project"** — ask for project name (suggest from remaining `.csproj` files in the current repo) and project type. Automatically assigned to the current repo. Return to step 3.
- **"Add another repo"** — repeat step 1 (resolve, clone, detect package name) for a new repo. That repo becomes the new current repo. Then perform step 2 for its first project. Return to step 3.
- **"Done"** — exit the loop.

---

## Step 4 — Workspace parameters

Ask for:
- `workspace_owner` — GitHub owner for the workspace repo (default: owner of the first source repo)
- `ws_repository` — workspace repo name (suggest `ws-<source_repo>` for a single-repo workspace; for multi-repo, let the user choose freely but remind them of the `ws-` prefix convention)

---

## Step 5 — Invoke `/new-github-workspace`

Ask the user for permission to invoke `/new-github-workspace` with all collected params. Once approved, invoke it — passing the workspace params and all source repo/project entries.
