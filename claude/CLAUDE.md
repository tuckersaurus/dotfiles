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

## Commits

Follow Conventional Commits for all commit messages, including ad-hoc commits (not just via `/commit`):

```
<type>: <short summary>
```

Types: `feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `ci`

- Lowercase type and summary
- Imperative mood, no trailing period
- Focus on the *why*, not just the *what*

## Plan Files

When writing or updating a plan file during Plan Mode, include a version header
at the top that increments each time the plan is revised based on user comments:

**Plan Version:** v1  
**Last Updated:** <date>

Bump the version number (v1 → v2 → v3) and update the date each time the plan
is revised in response to user feedback.
