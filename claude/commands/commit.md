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

2. Analyze the diff and draft a commit message following the format above.

3. Use `AskUserQuestion` to present your draft commit message and ask the user to confirm or provide changes. Show the message clearly so they can review it.

4. Once confirmed, stage the relevant files (prefer specific filenames over `git add -A`) and commit using a HEREDOC with the approved message.

5. Run `git status` to confirm the commit succeeded.

Do NOT push unless explicitly asked.
