# Global Claude Code Instructions

## Response Style

- End responses with a succinct summary of what changed and what's next — keep it to 1-2 sentences.
- When you notice an opportunity to clean up or refactor surrounding code, mention it as a suggestion but never apply it automatically — always ask first.
- Present multiple options with a clear recommendation and reasoning when meaningful trade-offs exist. Skip this when the solution is straightforward and there's no real alternative.

## Code Comments

- Add a brief "what" comment on especially complex code blocks where the logic isn't immediately clear.
- Add a "why" comment whenever the reason behind a decision isn't obvious — hidden constraints, non-obvious invariants, workarounds.
- Don't comment on simple or self-evident code.

## Testing

After making code changes, run the project's test suite automatically. If tests fail, fix them before considering the task complete. If no test suite exists, note it rather than skipping silently.

## Package Management

Use `npm` exclusively — never suggest or use yarn, pnpm, or bun. Use `npm ci` for clean installs and `npm run` for scripts. Always confirm with the user before adding a new package dependency.

## Destructive Git Operations

Always confirm with the user before running any of the following, regardless of context:

- `git reset --hard`
- `git push --force` or `--force-with-lease`
- `git branch -D`
- `git clean -f` or `git clean -fd`
- `git checkout -- .` or `git restore .`
- Any rebase that rewrites commits already pushed to a remote

## Git Workflow

Always use the predefined skills for git operations — never run these ad-hoc, even mid-task:

- Branching → `/branch` skill
- Committing → `/commit` skill
- Pull requests → `/pr` skill

Before committing, assess whether the changes span distinct concerns. If so, suggest splitting into multiple commits and explain the proposed breakdown — let the user decide before proceeding.

All repos, including `~/dotfiles`, use branches and PRs. Never commit directly to main. If a commit is about to land on `main`, stop and confirm with the user before proceeding — default assumption is that a branch is needed.

## Custom Skills

Custom skills (`/commit`, `/branch`, `/pr`, and any others in `~/.claude/commands/`) were written collaboratively, so their commands are implicitly trusted:

- **User-invoked skill** (`/commit`, `/branch`, etc.): run it immediately — no "are you sure" check, no permission prompts. The only interactions should be the skill's own questions (e.g. options, split-commit suggestions).
- **Claude-invoked skill**: ask the user before invoking.
- **Exception**: pause if there is a clear privacy concern (e.g. a command would transmit sensitive data externally).

## Commits

Follow Conventional Commits for all commit messages, including ad-hoc commits (not just via `/commit`):

```
<type>: <short summary>
```

Types: `feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `ci`

- Lowercase type and summary
- Imperative mood, no trailing period
- Focus on the *why*, not just the *what*

## Shell Permissions

Read-only shell commands (`ls`, `find`, `cat`, `grep`, `stat`, `diff`, etc.) are in the global allow list and should never require a permission prompt. If one triggers a prompt, use the `update-config` skill to add it to the allowlist — don't ask the user each time.

## Plan Files

When writing or updating a plan file during Plan Mode, include a version header
at the top that increments each time the plan is revised based on user comments:

**Plan Version:** v1  
**Last Updated:** <date> <time>

Bump the version number (v1 → v2 → v3) and update the timestamp (date + time)
each time the plan is revised in response to user feedback.

Immediately after the version header, include a **Changes in v#** section that
lists what changed in the current version as a short bullet list. This makes it
easy for the user to review what was updated without reading the whole plan.
Previous versions' change notes should be kept beneath the current one.
