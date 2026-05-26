Create a new **project repository** from the `project-repository` cookiecutter template and push it to GitHub. This is specifically for project repos — use a different command or template for workspace repositories or other repo types.

The template lives at `~/dotfiles/templates/project-repository` and scaffolds a full project structure including .github workflows, .devcontainer, dotnet layout, postgres, and VSCode config.

## Steps

1. Check whether the user provided arguments after `/new-github-project`:

   **With arguments** — parse them:
   - First arg is the repo name (kebab-case)
   - Second arg (optional) is the GitHub owner — defaults to `tuckersaurus` if omitted
   - `source_project=<name>` (optional keyword arg) — the primary .NET project name; if omitted, the template default applies (`<PascalCase(repo)>.Web`)

   **Without arguments** — use `AskUserQuestion` to ask:
   - "Repository name (kebab-case)" — e.g. `zombie-miner`
   - "GitHub owner" — personal (`tuckersaurus`) or an org (e.g. `debugden-net`); default `tuckersaurus`

2. Ask about PostgreSQL schemas:

   - Ask: "Does this project use a PostgreSQL schema?" (default: yes)
   - If **yes**:
     1. Ask for the first schema name (default: repo name with hyphens replaced by underscores, e.g. `zombie-miner` → `zombie_miner`)
     2. Loop: ask "Add another schema?" (default: no). If yes, ask for the next schema name. Repeat until no.
   - If **no**: `db_schemas` is an empty string

3. Confirm the cookiecutter variables with the user before running:
   - `project_repository` → the repo name provided
   - `project_owner` → the GitHub owner provided
   - `package` → defaults to the repo name (ask only if they want to override)
   - `source_project` → the .NET project name (e.g. `ZombieMiner.Web`); if not provided as an argument, derive the default as `<PascalCase(repo)>.Web` and show it in the summary. The user can cancel and re-run with `source_project=<name>` to change it.
   - `db_schemas` → comma-delimited schema names (or empty string for no database)

   Use `AskUserQuestion` to present a summary and get confirmation before proceeding.

4. The target directory is always:
   ```
   ~/projects/source/github/<owner>/<repo-name>
   ```
   This is hardcoded — the command always creates the project here regardless of the current working directory.

5. Run cookiecutter non-interactively using `--no-input` with explicit variable overrides, so there are no interactive prompts:
   ```bash
   cookiecutter ~/dotfiles/templates/project-repository \
     --no-input \
     --output-dir ~/projects/source/github/<owner> \
     project_repository=<repo-name> \
     project_owner=<owner> \
     package=<package> \
     source_project=<source_project> \
     db_schemas=<schema1>,<schema2>
   ```
   Pass `db_schemas=` (empty) when the project has no database. The Jinja2 loop in `postgres/init.sql` splits on commas and generates one `CREATE SCHEMA` per non-empty entry — no post-scaffold editing required.

6. Initialize git and make the first commit:
   ```bash
   git -C ~/projects/source/github/<owner>/<repo-name> init
   git -C ~/projects/source/github/<owner>/<repo-name> add .
   git -C ~/projects/source/github/<owner>/<repo-name> commit -m "chore: initial project scaffold from template"
   ```

7. Create the GitHub repo and push:
   ```bash
   gh repo create <owner>/<repo-name> --private --source="$HOME/projects/source/github/<owner>/<repo-name>" --remote=origin --push
   ```
   Ask the user whether the repo should be `--private` or `--public` before running if not obvious from context.

8. Confirm success and print:
   - The local path (`~/projects/source/github/<owner>/<repo-name>`)
   - The GitHub URL (`https://github.com/<owner>/<repo-name>`)
