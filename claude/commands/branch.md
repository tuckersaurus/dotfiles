Create a new git branch with a consistent name derived from the branch's purpose.

## Branch naming format

```
<type>/<short-description>
```

Types: `feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `ci`

Rules:
- Lowercase, kebab-case description
- Imperative and concise — 3 to 5 words max
- No ticket numbers, no trailing slashes

## Steps

1. Check whether the user provided text after `/branch`:

   **With text** — treat it as a natural language description of the branch's purpose and go straight to drafting (step 2).

   **Without text** — use `AskUserQuestion` to ask:
   - "Describe the purpose" — I'll infer the type and derive a concise slug from your description
   - "Give me an exact name to format" — I'll apply the type prefix and kebab-case with minimal interpretation

2. **Natural language path**: analyze the description to infer the correct type and derive a slug that captures the essence — do not just reformat the user's words verbatim.
   - e.g. "I need to fix the redirect that happens after Google login" → `fix/google-login-redirect`
   - e.g. "add support for custom dotnet templates in the dev container" → `feat/dotnet-templates-dev-container`

   **Exact name path**: apply type prefix and kebab-case only.
   - e.g. "AddUserAuthFlow" → `feat/add-user-auth-flow`

3. Use `AskUserQuestion` to present the drafted branch name and ask the user to confirm or provide changes.

4. Once confirmed, run:
   ```
   git checkout -b <branch-name>
   ```

5. Confirm success and print the branch name.
