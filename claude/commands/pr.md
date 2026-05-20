Create a pull request for the current branch.

## PR title format

Same as commit messages — Conventional Commits:

```
<type>: <short summary>
```

Types: `feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `ci`

Rules:
- Lowercase type and summary
- Summary is imperative mood, no period
- Focus on the *why*, not just the *what*

## PR description format

```markdown
## Summary
- <bullet points covering what changed and why>

## Test plan
- [ ] <steps to verify each change manually>
```

## Steps

1. Run in parallel:
   - `git status` — warn if working tree is not clean
   - `git log main..HEAD --oneline` — commits going into this PR
   - `git diff main..HEAD` — full diff for context

2. If on `main`, stop and tell the user — PRs must come from a feature branch.

3. Draft a PR title (conventional commits) and description (Summary + Test plan) based on the diff and commit log.

4. Use `AskUserQuestion` to show the draft title and description and ask the user to confirm or provide changes.

5. Once confirmed, push the branch if not already on remote:
   ```
   git push -u origin HEAD
   ```

6. Create the PR using a HEREDOC for the body:
   ```
   gh pr create --title "..." --body "..."
   ```

7. Output the PR URL.

Do NOT merge the PR unless explicitly asked.
