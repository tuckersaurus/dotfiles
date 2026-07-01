Commit staged and unstaged changes in a git repo.

Accepts an optional repo path argument (e.g. `/commit ~/dotfiles`). If provided, all git commands run with `git -C <path>`. If omitted, operates on the current working directory.

**Important:** This skill must be invoked once per repo that has changes — never bypass it with raw `git add` + `git commit` commands, even for secondary repos like `~/dotfiles`.

## Commit message format

Use **Conventional Commits**:

```
<type>: <short summary>
```

Types:
- `feat` — new feature or capability
- `fix` — bug fix
- `chore` — tooling, config, dependencies, scaffolding
- `docs` — documentation only
- `refactor` — restructuring without behaviour change
- `test` — adding or updating tests
- `ci` — CI/CD pipeline changes

Rules:
- Lowercase type and summary
- Summary is imperative mood, no period ("add X" not "adds X" or "added X")
- Focus on the *why*, not just the *what*
- One line; add a body only if the why genuinely needs more explanation

## Steps

1. Determine the git prefix: if a repo path argument was provided, use `git -C <path>` for all git commands. Otherwise use plain `git`.

2. Run these in parallel:
   - `git [-C <path>] status` to see staged/unstaged/untracked files
   - `git [-C <path>] diff HEAD` to see all current changes
   - `git [-C <path>] branch --show-current` to check the active branch

3. **If the current branch is `main` (or `master`):**
   - Run `git [-C <path>] branch --list` to find all local branches other than main
   - If other branches exist, use `AskUserQuestion` to let the user choose:
     - One option per existing branch (show the branch name)
     - A final option: "Create a new branch"
   - If no other branches exist, skip straight to the "Create a new branch" path
   - **If the user picks an existing branch:** run `git [-C <path>] checkout <branch>` and continue to Step 4
   - **If the user picks "Create a new branch":** invoke the `/branch` skill now — do not create the branch any other way. After `/branch` completes, continue to Step 4.

4. Analyze the diff and draft a commit message following the format above.

5. Do not print the draft message as plain text first — the `AskUserQuestion` overlay can cover preceding chat content, hiding it from the user. Instead call `AskUserQuestion` directly with a short question (e.g. "Commit with this message?") and put the full drafted commit message in the `preview` field of the "Confirm" option (the monospace preview box handles multi-line messages cleanly). Add an "Edit" option (no preview needed) for the user to supply a replacement.

6. Once confirmed, stage the relevant files with `git [-C <path>] add` (prefer specific filenames over `git add -A`) and commit using a HEREDOC with the approved message.

7. Run `git [-C <path>] status` to confirm the commit succeeded.

8. Push: `git [-C <path>] push`
