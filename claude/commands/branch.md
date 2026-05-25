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

1. Run `git status` and `git diff HEAD` in parallel. Also note whether the user provided text after `/branch`.

2. **Determine the branch name source:**

   **With text provided** — treat it as a natural language description of the branch's purpose. Derive a candidate name (see naming rules in step 3) and go straight to the confirmation question (step 4) with that candidate as the recommendation alongside an option to give an explicit name instead.

   **Without text, with uncommitted changes** — analyze the diff to infer the branch's purpose. Derive a candidate name from the changes and go to the confirmation question (step 4) with that candidate as the recommendation alongside options to describe the purpose or give an explicit name instead.

   **Without text, no uncommitted changes** — no recommendation is possible. Use `AskUserQuestion` to ask:
   - "Describe the purpose" — I'll infer the type and derive a concise slug from your description
   - "Give me an exact name to format" — I'll apply the type prefix and kebab-case with minimal interpretation
   Then derive the name from the user's answer and go to step 4.

3. **Naming rules:**

   **Natural language path** (text provided or inferred from diff): analyze the description to infer the correct type and derive a slug that captures the essence — do not just reformat the user's words verbatim.
   - e.g. "I need to fix the redirect that happens after Google login" → `fix/google-login-redirect`
   - e.g. "add support for custom dotnet templates in the dev container" → `feat/dotnet-templates-dev-container`

   **Exact name path**: apply type prefix and kebab-case only.
   - e.g. "AddUserAuthFlow" → `feat/add-user-auth-flow`

4. Use `AskUserQuestion` to present the recommended branch name. Options depend on how the name was derived:

   - **Text provided or inferred from diff:** offer the recommended name + "Give me an exact name to format"
   - **No text, with diff:** offer the recommended name + "Describe the purpose instead" + "Give me an exact name to format"

   If the user picks an alternative option, collect their input and re-derive the name, then return to this step.

5. Once a name is confirmed, run:
   ```
   git checkout -b <branch-name>
   ```

6. Confirm success and print the branch name.
