---
description: Create a .NET project inside an existing source repo (no workspace wiring)
argument-hint: "repo= project= type= [schemas=]"
---

Create a .NET project inside an existing source repo. Updates the source repo's `package.json` workspaces. Does NOT patch workspace files — use `/add-source-project` to wire the project into a workspace.

**This skill is non-interactive.** All required data must be supplied as arguments. No questions are asked. No git or GitHub operations are performed — disk only.

**Arguments (all required):** `repo=<owner>/<repo>`, `project=<name>`, `type=app|library`

**Arguments (optional):** `schemas=<s1>,<s2>` — comma-delimited PostgreSQL schema names; omit or pass empty string for no schemas

---

## Safety checks

Abort with a clear error message if any of the following are not met:

- `repo` is provided in `<owner>/<repo>` format with both parts non-empty
- `project` is provided and non-empty (PascalCase, e.g. `ZombieMiner.Web`)
- `type` is exactly `app` or `library`
- Source repo exists on disk at `~/projects/source/github/<owner>/<repo>`
- Target path `~/projects/source/github/<owner>/<repo>/dotnet/src/<project>` does **not** already exist

---

## Steps

### 1 — Derive npm package name

Convert the project name to kebab-case:

```bash
python3 -c "
import re, sys
name = sys.argv[1]
parts = name.split('.')
kebab = '-'.join(re.sub(r'([A-Z])', r'-\1', p).strip('-').lower() for p in parts)
print(kebab)
" "<project>"
```

Full package name: `@<owner>/<kebab-project-name>` (e.g. `ZombieMiner.Web` → `@tuckersaurus/zombie-miner-web`)

### 2 — Create project files

Create all files under `~/projects/source/github/<owner>/<repo>/dotnet/src/<project>/`:

**`<project>.csproj`** (all types):
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

**`package.json`** (all types):
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

**`Program.cs`** (app only):
```csharp
var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();
app.Run();
```

**`appsettings.json`** (app only):
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

**`appsettings.Development.json`** (app only):
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

**`Properties/launchSettings.json`** (app only):
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

### 3 — Apply PostgreSQL schemas (if provided)

If `schemas` is non-empty, append to `~/projects/source/github/<owner>/<repo>/postgres/init.sql`:
```sql
CREATE SCHEMA IF NOT EXISTS <schema>;
```
One line per schema.

### 4 — Update source repo workspaces

Add `"dotnet/src/<project>"` to the `workspaces` array in `~/projects/source/github/<owner>/<repo>/package.json`.

### 5 — Print result

Print the local path: `~/projects/source/github/<owner>/<repo>/dotnet/src/<project>`
