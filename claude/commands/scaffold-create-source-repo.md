---
description: Create a new bare source repository from the cookiecutter template
argument-hint: "owner= repo="
---

Create a new bare **source repository** from the `project-repository` cookiecutter template. The source repo is the .NET project structure without any projects yet — use `/scaffold-create-source-project` to add projects, or `/scaffold` for the full guided flow.

**This skill is non-interactive.** All required data must be supplied as arguments. No questions are asked. No git or GitHub operations are performed — disk only.

**Arguments (all required):** `owner=<owner>`, `repo=<repo-name>`

The npm package name is derived automatically from `repo` (e.g. `zombie-miner` → `@<owner>/zombie-miner`). No override is supported.

---

## Safety checks

Abort with a clear error message if any of the following are not met:

- `owner` is provided and non-empty
- `repo` is provided and non-empty (kebab-case, e.g. `zombie-miner`)
- Target path `~/projects/source/github/<owner>/<repo>` does **not** already exist

---

## Steps

### 1 — Run cookiecutter

```bash
cookiecutter ~/dotfiles/templates/project-repository \
  --no-input \
  --output-dir ~/projects/source/github/<owner> \
  project_repository=<repo> \
  project_owner=<owner> \
  package=<repo>
```

### 2 — Initialise git

```bash
git -C ~/projects/source/github/<owner>/<repo> init
```

### 3 — Print result

Print the local path: `~/projects/source/github/<owner>/<repo>`
