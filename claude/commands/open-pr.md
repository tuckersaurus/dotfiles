Create a pull request for the current branch.

Accepts an optional repo path argument (e.g. `/open-pr ~/dotfiles`). If provided, all git commands run with `git -C <path>` and `gh` commands use the derived `--repo` flag. If omitted, operates on the current working directory.

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

1. Determine the git prefix: if a repo path argument was provided, use `git -C <path>` for all git commands. Otherwise use plain `git`.

2. Run in parallel:
   - `git [-C <path>] status` — warn if working tree is not clean
   - `git [-C <path>] log main..HEAD --oneline` — commits going into this PR
   - `git [-C <path>] diff main..HEAD` — full diff for context

3. If on `main`, stop and tell the user — PRs must come from a feature branch.

4. Draft a PR title (conventional commits) and description (Summary + Test plan) based on the diff and commit log.

5. Do not print the draft title/description as plain text first — the `AskUserQuestion` overlay can cover preceding chat content, hiding it from the user. Instead call `AskUserQuestion` directly with a short question (e.g. "Open this PR?") and put the full drafted title and description (Summary + Test plan) in the `preview` field of the "Confirm" option. Add an "Edit" option (no preview needed) for the user to supply a replacement title/description.

6. Once confirmed, push the branch if not already on remote:
   ```
   git [-C <path>] push -u origin HEAD
   ```

7. Derive the GitHub repo slug from the remote URL using:
   ```
   git [-C <path>] remote get-url origin
   ```
   Parse `owner/repo` from the result (handles both SSH and HTTPS remotes).
   Then create the PR:
   ```
   gh pr create --repo <owner>/<repo> --head <branch> --title "..." --body "..."
   ```

8. Output the PR URL.

Do NOT merge the PR unless explicitly asked.
