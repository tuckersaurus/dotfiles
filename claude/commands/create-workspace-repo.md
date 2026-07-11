---
description: Create a new bare workspace repository from the cookiecutter template
argument-hint: "workspace_owner= ws_repository="
---

Create a new bare **workspace repository** from the `workspace-repository` cookiecutter template. The workspace is the devcontainer + VS Code workspace config + solution stub that wires together one or more source repos. Source repos and projects are added later via `/add-source-repo` or `/new-environment`.

**This skill is non-interactive.** All required data must be supplied as arguments. No questions are asked. No git or GitHub operations are performed — disk only.

**Arguments (all required):** `workspace_owner=<owner>`, `ws_repository=<name>`

---

## Safety checks

Abort with a clear error message if any of the following are not met:

- `workspace_owner` is provided and non-empty
- `ws_repository` is provided, non-empty, and starts with `ws-`
- Target path `~/projects/source/github/<workspace_owner>/<ws_repository>` does **not** already exist

---

## Steps

### 1 — Run cookiecutter

```bash
cookiecutter ~/dotfiles/templates/workspace-repository \
  --no-input \
  --output-dir ~/projects/source/github/<workspace_owner> \
  ws_repository=<ws_repository> \
  workspace_owner=<workspace_owner>
```

### 2 — Initialise git

```bash
git -C ~/projects/source/github/<workspace_owner>/<ws_repository> init
```

### 3 — Print result

Print the local path: `~/projects/source/github/<workspace_owner>/<ws_repository>`
