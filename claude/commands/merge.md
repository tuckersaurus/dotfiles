Merge a pull request into its base branch.

## Default behaviour

- **Strategy**: Squash and Merge
- **Branch deletion**: prompted after merge (deletes both local and remote)
- Override strategy by appending `--rebase` or `--merge` to the invocation

## Arguments

- **No args** — find the open PR for the current branch and merge it
- **PR number** (e.g. `/merge 42`) — merge that specific PR regardless of current branch
- **Strategy override** — e.g. `/merge --rebase` or `/merge 42 --merge`

## Steps

1. **Derive the repo slug** from the remote URL:
   ```
   git remote get-url origin
   ```
   Parse `owner/repo` from the result (handles both SSH `git@github.com:owner/repo.git` and HTTPS `https://github.com/owner/repo.git`).

2. **Determine the target PR:**
   - If a PR number was passed as an argument: use it directly — fetch its details with `gh pr view <number> --repo <owner>/<repo> --json number,title,headRefName,baseRefName`
   - Otherwise: get the current branch with `git branch --show-current`, then run `gh pr list --head <branch> --repo <owner>/<repo> --json number,title,headRefName,baseRefName,state` and take the first open result
   - If no open PR is found: stop and tell the user to run `/pr` first

3. **Print a PR summary** as plain text before doing anything:
   ```
   PR #<number>: <title>
   <headRefName> → <baseRefName>
   Strategy: Squash and Merge (or the override if one was passed)
   ```

4. **Check CI status** via `gh pr checks <number> --repo <owner>/<repo>`:
   - **No checks configured** — proceed
   - **All passing** — proceed
   - **Any failing** — stop. Print which checks failed. Do not offer to proceed.
   - **Any pending** — warn the user, then use `AskUserQuestion` to ask:
     - "Proceed anyway" — continue to step 5
     - "Cancel — wait for checks to finish" — stop

5. **Confirm the merge** using `AskUserQuestion`:
   - "Squash and merge" (or the override strategy label)
   - "Cancel"

6. **Merge:**
   ```
   gh pr merge <number> --repo <owner>/<repo> --squash
   ```
   Swap `--squash` for `--rebase` or `--merge` if an override was passed.

7. **Ask about branch deletion** using `AskUserQuestion`:
   - "Yes — delete `<headRefName>` (local + remote)"
   - "No — keep the branch"

   If yes, run both:
   ```
   git push origin --delete <headRefName>
   git branch -D <headRefName>
   ```
   If the local branch doesn't exist (e.g. PR was opened from a fork or a different machine), skip the `git branch -D` step silently.

8. **Switch to the base branch and pull:**
   ```
   git checkout <baseRefName>
   git pull
   ```

9. **Confirm success** — print the merged PR title and confirm the base branch is up to date.
