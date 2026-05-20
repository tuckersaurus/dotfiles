Commit staged and unstaged changes in the current git repo.

## Steps

1. Run these in parallel:
   - `git status` to see staged/unstaged/untracked files
   - `git diff HEAD` to see all current changes
   - `git log --oneline -5` to understand this repo's commit message style

2. Analyze the diff and draft a commit message that:
   - Follows the style and prefix conventions seen in the log (e.g. `chore:`, `feat:`, `fix:`)
   - Focuses on the *why*, not just the *what*
   - Is concise (one line summary; body only if genuinely needed)

3. Use `AskUserQuestion` to present your draft commit message and ask the user to confirm or provide changes. Show the message clearly so they can review it.

4. Once confirmed, stage the relevant files (prefer specific filenames over `git add -A`) and commit using a HEREDOC with the approved message, appending the co-author line:
   ```
   Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
   ```

5. Run `git status` to confirm the commit succeeded.

Do NOT push unless explicitly asked.
