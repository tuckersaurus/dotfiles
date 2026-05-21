# Templates

Cookiecutter templates for bootstrapping new projects.

## Prerequisites

```bash
# Install cookiecutter (one-time)
python3 /tmp/get-pip.py --user --break-system-packages
~/.local/bin/pip install cookiecutter --break-system-packages
```

`~/.local/bin` must be on your `PATH` (already configured in `dotfiles/bash/path.sh`).

---

## Templates

### workspace-repository

A workspace repository containing project configuration — devcontainer, multi-root workspace, and a dotnet solution stub. References external source repositories; contains no source code.

```bash
cookiecutter ~/dotfiles/templates/workspace-repository
```

| Parameter | Description | Example |
|---|---|---|
| `ws_repository` | Workspace repository name | `zombie-miner-workspace` |
| `workspace_owner` | GitHub owner of the workspace repository | `tuckersaurus` |
| `source_owner` | GitHub owner of the source repository | `tuckersaurus` |
| `source_repo` | Source repository name (kebab-case) | `zombie-miner` |
| `source_project` | .csproj project name (PascalCase) | `ZombieMiner` |
| `source_package` | npm package name (defaults to `source_repo`) | `zombie-miner` |

---

## Adding a new template

1. Create a subdirectory: `templates/my-template/`
2. Add `cookiecutter.json` with parameter definitions
3. Add a `{{cookiecutter.output_dir}}/` subdirectory containing the template files
4. Use `{{cookiecutter.param_name}}` in file contents and filenames for substitution
5. Add a section to this README
