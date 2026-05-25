Commit staged and unstaged changes in the current git repo.

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

1. Run these in parallel:
   - `git status` to see staged/unstaged/untracked files
   - `git diff HEAD` to see all current changes
   - `git branch --show-current` to check the active branch

2. **If the current branch is `main` (or `master`):**
   - Run `git branch --list` to find all local branches other than main
   - If other branches exist, use `AskUserQuestion` to let the user choose:
     - One option per existing branch (show the branch name)
     - A final option: "Create a new branch"
   - If no other branches exist, skip straight to the "Create a new branch" path
   - **If the user picks an existing branch:** run `git checkout <branch>` and continue to Step 3
   - **If the user picks "Create a new branch":** invoke the `/branch` skill now — do not create the branch any other way. After `/branch` completes, continue to Step 3.

3. Analyze the diff and draft a commit message following the format above.

4. Output the draft commit message as plain text in the conversation so the user can read it in full. Then use `AskUserQuestion` with a simple confirm/edit choice — do not put the message content inside the question options.

5. Once confirmed, stage the relevant files (prefer specific filenames over `git add -A`) and commit using a HEREDOC with the approved message.

6. Run `git status` to confirm the commit succeeded.

Do NOT push unless explicitly asked.
