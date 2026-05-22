Create a new **project repository** from the `project-repository` cookiecutter template and push it to GitHub. This is specifically for project repos — use a different command or template for workspace repositories or other repo types.

The template lives at `~/dotfiles/templates/project-repository` and scaffolds a full project structure including .github workflows, .devcontainer, dotnet layout, postgres, and VSCode config.

## Steps

1. Check whether the user provided arguments after `/new-github-project`:

   **With arguments** — parse them:
   - First arg is the repo name (kebab-case)
   - Second arg (optional) is the GitHub owner — defaults to `tuckersaurus` if omitted

   **Without arguments** — use `AskUserQuestion` to ask:
   - "Repository name (kebab-case)" — e.g. `zombie-miner`
   - "GitHub owner" — personal (`tuckersaurus`) or an org (e.g. `debugden-net`); default `tuckersaurus`

2. Confirm the four cookiecutter variables with the user before running:
   - `project_repository` → the repo name provided
   - `project_owner` → the GitHub owner provided
   - `package` → defaults to the repo name (ask only if they want to override)
   - `db_schema` → defaults to repo name with hyphens replaced by underscores (ask only if they want to override)

   Use `AskUserQuestion` to present a summary and get confirmation before proceeding.

3. The target directory is always:
   ```
   ~/projects/source/github/<owner>/<repo-name>
   ```
   This is hardcoded — the command always creates the project here regardless of the current working directory.

4. Run cookiecutter non-interactively using `--no-input` with explicit variable overrides, so there are no interactive prompts:
   ```bash
   cookiecutter ~/dotfiles/templates/project-repository \
     --no-input \
     --output-dir ~/projects/source/github/<owner> \
     project_repository=<repo-name> \
     project_owner=<owner> \
     package=<package> \
     db_schema=<db_schema>
   ```

5. Initialize git and make the first commit:
   ```bash
   cd ~/projects/source/github/<owner>/<repo-name>
   git init
   git add .
   git commit -m "chore: initial project scaffold from template"
   ```

6. Create the GitHub repo and push:
   ```bash
   gh repo create <owner>/<repo-name> --private --source="$HOME/projects/source/github/<owner>/<repo-name>" --remote=origin --push
   ```
   Ask the user whether the repo should be `--private` or `--public` before running if not obvious from context.

7. Confirm success and print:
   - The local path (`~/projects/source/github/<owner>/<repo-name>`)
   - The GitHub URL (`https://github.com/<owner>/<repo-name>`)
