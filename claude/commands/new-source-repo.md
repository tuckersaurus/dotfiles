Create a new bare **source repository** from the `project-repository` cookiecutter template. The source repo is the .NET project structure without any projects yet — use `/new-source-project` to add projects, or `/new-environment` for the full guided flow.

**Arguments:** `owner=<owner>` (default `tuckersaurus`), `repo=<repo-name>`, `push=true`, `visibility=private|public` (default `private`)

## Steps

1. Ask for or accept `owner` (default `tuckersaurus`) and `repo` (kebab-case, e.g. `zombie-miner`). Skip if all required args are provided.

2. Confirm summary (`project_repository`, `project_owner`, `package`) — `package` defaults to repo name. Skip if all required args are provided.

3. Run cookiecutter:
   ```bash
   cookiecutter ~/dotfiles/templates/project-repository \
     --no-input \
     --output-dir ~/projects/source/github/<owner> \
     project_repository=<repo> \
     project_owner=<owner> \
     package=<package>
   ```

4. Initialize git and commit:
   ```bash
   git -C ~/projects/source/github/<owner>/<repo> init
   git -C ~/projects/source/github/<owner>/<repo> add .
   git -C ~/projects/source/github/<owner>/<repo> commit -m "chore: initial project scaffold"
   ```

5. If `push=true`: use `visibility` arg (or ask if not provided), then:
   ```bash
   gh repo create <owner>/<repo> --<visibility> \
     --source="$HOME/projects/source/github/<owner>/<repo>" \
     --remote=origin --push
   ```

6. Print local path (`~/projects/source/github/<owner>/<repo>`) and GitHub URL if pushed.
