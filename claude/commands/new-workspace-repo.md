Create a new bare **workspace repository** from the `workspace-repository` cookiecutter template. The workspace is the devcontainer + VS Code workspace config + solution stub that wires together one or more source repos. Source repos and projects are added later via `/add-source-repo` or `/new-environment`.

**Arguments:** `workspace_owner=<owner>` (default `tuckersaurus`), `ws_repository=<name>`, `push=true`, `visibility=private|public` (default `private`)

## Steps

1. Ask for or accept `workspace_owner` (default `tuckersaurus`) and `ws_repository` (ws- prefix convention, e.g. `ws-zombie-miner`). Skip if all required args are provided.

2. Confirm summary — skip if all required args are provided.

3. Run cookiecutter:
   ```bash
   cookiecutter ~/dotfiles/templates/workspace-repository \
     --no-input \
     --output-dir ~/projects/source/github/<workspace_owner> \
     ws_repository=<ws_repository> \
     workspace_owner=<workspace_owner>
   ```

4. Initialize git and commit:
   ```bash
   git -C ~/projects/source/github/<workspace_owner>/<ws_repository> init
   git -C ~/projects/source/github/<workspace_owner>/<ws_repository> add .
   git -C ~/projects/source/github/<workspace_owner>/<ws_repository> commit -m "chore: initial workspace scaffold"
   ```

5. If `push=true`: use `visibility` arg (or ask if not provided), then:
   ```bash
   gh repo create <workspace_owner>/<ws_repository> --<visibility> \
     --source="$HOME/projects/source/github/<workspace_owner>/<ws_repository>" \
     --remote=origin --push
   ```

6. Print local path (`~/projects/source/github/<workspace_owner>/<ws_repository>`) and GitHub URL if pushed.
