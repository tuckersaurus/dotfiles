Clean up the local git repo: switch to main, pull latest, and delete any local branches whose remote tracking branch has been deleted.

## Steps

1. Check the current branch with `git branch --show-current`.

2. If not already on `main`, run `git checkout main`. If the checkout fails due to uncommitted changes, stop and tell the user to stash or commit first.

3. Run `git pull` to bring main up to date with origin.

4. Find orphaned local branches — branches whose upstream is gone:
   ```
   git branch -vv | grep ': gone]'
   ```
   Parse the branch names from the output (first field after trimming leading whitespace and `*`).

5. If no orphaned branches are found, report that the repo is already clean and stop.

6. If orphaned branches are found, list them clearly and use `AskUserQuestion` to confirm before deleting:
   - "Delete all N listed branches" — proceed with deletion
   - "Cancel" — stop without deleting anything

7. For each confirmed branch, run:
   ```
   git branch -D <branch-name>
   ```

8. Report how many branches were deleted and confirm main is up to date.
