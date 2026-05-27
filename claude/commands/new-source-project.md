Create a .NET project inside an existing source repo. Updates the source repo's `package.json` workspaces. Does NOT patch workspace files — use `/add-source-project` to wire the project into a workspace.

**Arguments:** `repo=<owner>/<repo>`, `project=<name>`, `type=app|library`, `schemas=<s1>,<s2>` (optional), `push=true`, `visibility=private|public` (default `private`)

## Steps

### 1 — Accept or ask for source repo

Accept from `repo=` arg, or ask for `<owner>/<repo>`.

### 2 — Resolve source repo

- **On disk** at `~/projects/source/github/<owner>/<repo>`: proceed.
- **Not on disk**: run `gh repo view <owner>/<repo> --json name`
  - Found on GitHub → clone it:
    ```bash
    git clone git@github.com:<owner>/<repo>.git ~/projects/source/github/<owner>/<repo>
    ```
  - Not found on GitHub → offer:
    - **"Create it"** → call `/new-source-repo owner=<owner> repo=<repo> push=false visibility=<visibility>`, then continue
    - **"Cancel"** → exit

### 3 — Accept or ask for project name

Accept from `project=` arg, or ask for project name (PascalCase, e.g. `ZombieMiner.Api`). Suggest based on existing `.csproj` naming patterns in `dotnet/src/`.

### 4 — Accept or ask for project type

Accept from `type=` arg, or ask: **app** (🚀 — ASP.NET Core, gets `Program.cs` + appsettings + launchSettings) or **library** (📚 — class library, csproj + package.json only).

### 5 — Accept or ask for PostgreSQL schemas

Skip entirely if `schemas=` arg was provided — use the arg value (empty string = no schemas).

Otherwise ask interactively: suggest snake_case of project name (e.g. `ZombieMiner.Web` → `zombie_miner`), option for none, loop to add more.

If schemas were specified (non-empty), append to `~/projects/source/github/<owner>/<repo>/postgres/init.sql`:
```sql
CREATE SCHEMA IF NOT EXISTS <schema>;
```

### 6 — Confirm

Skip if all required args are provided.

### 7 — Derive npm package name

```bash
python3 -c "
import re, sys
name = sys.argv[1]
parts = name.split('.')
kebab = '-'.join(re.sub(r'([A-Z])', r'-\1', p).strip('-').lower() for p in parts)
print(kebab)
" "<project>"
```
Full package name: `@<owner>/<kebab-project-name>` (e.g. `@tuckersaurus/zombie-miner-web`)

### 8 — Create project files

**All types** — create in `~/projects/source/github/<owner>/<repo>/dotnet/src/<project>/`:

`<project>.csproj`:
```xml
<Project Sdk="Microsoft.NET.Sdk.Web">  <!-- or Microsoft.NET.Sdk for library -->
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
    <RootNamespace><project></RootNamespace>
  </PropertyGroup>
</Project>
```

`package.json`:
```json
{
  "name": "@<owner>/<kebab-project-name>",
  "version": "0.0.0",
  "private": true,
  "scripts": {
    "watch:web": "echo \"Add web watch script here.\""
  }
}
```

**App only** — also create:

`Program.cs`:
```csharp
var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();
app.Run();
```

`appsettings.json`:
```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*"
}
```

`appsettings.Development.json`:
```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  }
}
```

`Properties/launchSettings.json`:
```json
{
  "profiles": {
    "dev-container": {
      "commandName": "Project",
      "applicationUrl": "http://localhost:5000",
      "environmentVariables": {
        "ASPNETCORE_ENVIRONMENT": "Development"
      }
    }
  }
}
```

### 9 — Update source repo workspaces

Add `"dotnet/src/<project>"` to the `workspaces` array in `~/projects/source/github/<owner>/<repo>/package.json`.

### 10 — Commit (always)

```bash
git -C ~/projects/source/github/<owner>/<repo> add .
git -C ~/projects/source/github/<owner>/<repo> commit -m "feat: add <project> project"
```

### 11 — Push (conditional)

If `push=false`: skip.

If `push=true`:
- If repo has a remote (`git -C <path> remote get-url origin` succeeds): `git push`
- If no remote (fresh local repo): use `visibility` arg (or ask if not provided), then:
  ```bash
  gh repo create <owner>/<repo> --<visibility> \
    --source="$HOME/projects/source/github/<owner>/<repo>" \
    --remote=origin --push
  ```

### 12 — Print results

Print what was created. Note to use `/add-source-project` to wire this project into a workspace.
