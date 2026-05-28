Clean up the local git repo: switch to main, pull latest, and delete any local branches whose remote tracking branch has been deleted.

## Arguments

- **No args** — interactive mode: prompts before deleting orphaned branches
- **`--yes`** — non-interactive mode: auto-deletes all orphaned branches without prompting (used by `/merge`)

## Steps

1. Note whether `--yes` was passed as an argument. Check the current branch with `git branch --show-current`.

2. If not already on `main`, run `git checkout main`. If the checkout fails due to uncommitted changes, stop and tell the user to stash or commit first.

3. Run `git pull --prune` to bring main up to date with origin and remove stale remote-tracking refs in one step.

4. Find orphaned local branches — branches whose upstream is gone or was never set:
   ```
   git for-each-ref --format='%(refname:short) %(upstream:track)' refs/heads \
     | grep -vE '^(main|master) ' \
     | grep -E '\[gone\]|^[^ ]+ $'
   ```
   Parse the branch name from the first field of each matching line. This catches both branches marked `[gone]` (upstream configured but remote deleted) and branches that lost their tracking ref entirely after a prune.

5. If no orphaned branches are found, report that the repo is already clean and stop.

6. If orphaned branches are found:
   - **`--yes` passed** — delete all orphaned branches immediately without prompting
   - **No flag** — list them clearly and use `AskUserQuestion` to confirm before deleting:
     - "Delete all N listed branches" — proceed with deletion
     - "Cancel" — stop without deleting anything

7. For each confirmed branch, run:
   ```
   git branch -D <branch-name>
   ```

8. Report how many branches were deleted and confirm main is up to date.
