# dotnet Custom Templates

Custom `dotnet new` templates for bootstrapping new projects. Each subdirectory here is a self-contained template that gets installed via `install.sh`.

---

## Directory Layout

Templates come in two structural flavors depending on whether output should land in a new subdirectory or directly in the current directory.

### Project template (creates a subdirectory)

Set `"preferNameDirectory": true` in `template.json`. Files are generated inside a new folder named after the project.

```
my-template/
├── .template.config/
│   └── template.json
├── MyApp.csproj            ← files sit at the template root
├── Program.cs
├── appsettings.json
└── Dockerfile
```

```
dotnet new mytemplate -n MyProject
# creates: MyProject/MyProject.csproj, MyProject/Program.cs, ...
```

### Item / file template (no subdirectory created)

Set `"preferNameDirectory": false` (or omit it — this is the default). Files are generated directly into the current directory. Useful for adding a single file to an existing project.

```
my-item-template/
├── .template.config/
│   └── template.json
└── MyService.cs            ← single file, generates in place
```

```
cd src/MyProject
dotnet new myitemtemplate -n OrderService
# creates: OrderService.cs in the current directory
```

The folder name (e.g. `my-template`) is just an organizational label — it does not affect the template's short name or identity.

---

## template.json Anatomy

```json
{
  "$schema": "http://json.schemastore.org/template",
  "author": "Shea Cox",
  "classifications": ["Common", "API"],
  "identity": "YourCompany.MyTemplate",
  "name": "My Project Template",
  "shortName": "mytemplate",
  "description": "A starter template with batteries included.",
  "tags": {
    "language": "C#",
    "type": "project"
  },
  "sourceName": "MyApp",
  "preferNameDirectory": true,
  "symbols": { },
  "sources": [ ]
}
```

| Field | Purpose |
|---|---|
| `identity` | Unique ID — used to uninstall/reinstall. Use reverse-DNS style. |
| `shortName` | What you type: `dotnet new mytemplate` |
| `sourceName` | Placeholder text in files/filenames replaced with the project name the user provides. |
| `preferNameDirectory` | `true` = generate into a new named folder. `false` (default) = generate into the current directory. |

---

## Symbol Examples

Symbols live inside `"symbols": { }` in `template.json`. They define the parameters and derived values that power substitution.

---

### 1. Basic String Replacement

Replaces a placeholder string in any file with a user-supplied value.

```json
"AuthorName": {
  "type": "parameter",
  "datatype": "string",
  "defaultValue": "Shea Cox",
  "description": "Name written into file headers and package metadata.",
  "replaces": "REPLACE_AUTHOR"
}
```

In your source files, any occurrence of `REPLACE_AUTHOR` is swapped out:

```xml
<!-- MyApp.csproj -->
<Authors>REPLACE_AUTHOR</Authors>
```

```
dotnet new mytemplate -n MyProject --AuthorName "Jane Smith"
```

---

### 2. Project Name — Automatic via `sourceName`

You do not need a symbol for the project name. `sourceName` handles it globally:
any occurrence of `MyApp` in **file contents** and **filenames** is replaced with whatever `-n` the user passes.

```
MyApp.csproj          → MyProject.csproj
namespace MyApp       → namespace MyProject
<AssemblyName>MyApp   → <AssemblyName>MyProject
```

---

### 3. Namespace-Safe Derived Value

If the user's project name might contain characters illegal in a C# namespace (spaces, hyphens, etc.), derive a safe version:

```json
"SafeNamespace": {
  "type": "derived",
  "valueSource": "name",
  "valueTransform": "safe_namespace",
  "replaces": "MyApp_Namespace",
  "description": "Namespace-safe version of the project name (hyphens → underscores, etc.)."
}
```

In source files use `MyApp_Namespace` as the placeholder:

```csharp
namespace MyApp_Namespace.Services;
```

`safe_namespace` is a built-in transform — no extra config needed.

---

### 4. Boolean Parameter (feature flag)

Lets the user opt in or out of an optional feature at generation time.

```json
"UseDocker": {
  "type": "parameter",
  "datatype": "bool",
  "defaultValue": "true",
  "description": "Include a Dockerfile and .dockerignore."
}
```

**Exclude files when the flag is off** (in `"sources"`):

```json
"sources": [
  {
    "modifiers": [
      {
        "condition": "(!UseDocker)",
        "exclude": ["Dockerfile", ".dockerignore"]
      }
    ]
  }
]
```

**Conditional blocks in C# files** use `#if` preprocessor syntax:

```csharp
#if (UseDocker)
    builder.Services.AddHealthChecks();
#endif
```

**Conditional blocks in JSON/YAML** use `##` comments:

```json
{
  "Logging": { }
##if (UseDocker)
  ,"HealthChecks": { "enabled": true }
##endif
}
```

---

### 5. Choice / Enum Parameter

Restricts input to a fixed set of options. Great for target framework, database provider, auth strategy, etc.

```json
"Framework": {
  "type": "parameter",
  "datatype": "choice",
  "description": "Target framework.",
  "defaultValue": "net9.0",
  "choices": [
    { "choice": "net8.0", "description": ".NET 8 (LTS)" },
    { "choice": "net9.0", "description": ".NET 9 (current)" }
  ],
  "replaces": "REPLACE_TFM"
}
```

In the `.csproj`:

```xml
<TargetFramework>REPLACE_TFM</TargetFramework>
```

Combine with a `computed` symbol to drive conditionals:

```json
"IsNet8": {
  "type": "computed",
  "value": "(Framework == \"net8.0\")"
}
```

```xml
#if (IsNet8)
<PackageReference Include="Microsoft.AspNetCore.Authentication.JwtBearer" Version="8.*" />
#else
<PackageReference Include="Microsoft.AspNetCore.Authentication.JwtBearer" Version="9.*" />
#endif
```

---

### 6. Auto-Generated GUID

Generates a fresh GUID at template instantiation time — useful for project/solution IDs.

```json
"ProjectGuid": {
  "type": "generated",
  "generator": "guid",
  "replaces": "00000000-0000-0000-0000-000000000000",
  "parameters": {
    "format": "D"
  }
}
```

Format options: `"D"` → `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`, `"B"` → `{...}`, `"N"` → no dashes.

In a `.sln` or `.csproj`:

```
Project("{00000000-0000-0000-0000-000000000000}") = "MyApp", "MyApp.csproj"
```

---

### 7. Auto-Generated Current Year

Useful for license headers and copyright notices.

```json
"CurrentYear": {
  "type": "generated",
  "generator": "now",
  "replaces": "REPLACE_YEAR",
  "parameters": {
    "format": "yyyy"
  }
}
```

In a `LICENSE` file:

```
Copyright (c) REPLACE_YEAR REPLACE_AUTHOR
```

---

### 8. File Rename Based on a Parameter

Rename a file to match a user-supplied value (separate from `sourceName` substitution):

```json
"Environment": {
  "type": "parameter",
  "datatype": "string",
  "defaultValue": "Development",
  "description": "Environment name for the appsettings override file.",
  "replaces": "REPLACE_ENV"
}
```

```json
"sources": [
  {
    "rename": {
      "appsettings.REPLACE_ENV.json": "appsettings.Development.json"
    }
  }
]
```

The rename key is resolved after symbol substitution, so `REPLACE_ENV` in the key is replaced first.

---

## Forms and Replacement Chaining

`forms` let a single parameter drive multiple replacements simultaneously — each in a different case style. The engine matches the *transformed* placeholder and replaces it with the *same transform* applied to the user's value, so you write each casing variant of the placeholder once in your source files and they all update together.

---

### Built-in form identifiers

| Identifier | Example output |
|---|---|
| `identity` | `MyService` (no change) |
| `lower_case` | `myservice` |
| `upper_case` | `MYSERVICE` |
| `pascal_case` | `MyService` |
| `camel_case` | `myService` |
| `kebab_case` | `my-service` |
| `snake_case` | `my_service` |
| `safe_name` | C#-identifier-safe (replaces illegal chars) |
| `safe_namespace` | Namespace-safe (dots/underscores, no leading digit) |

---

### 9. Multi-Form Replacement (one parameter, many case variants)

Add a `forms` block to a symbol to have it generate a replacement for each listed form. In your source files, write the *transformed* version of the placeholder — the engine matches it automatically.

```json
"symbols": {
  "EntityName": {
    "type": "parameter",
    "datatype": "string",
    "defaultValue": "MyEntity",
    "description": "Entity class name. All casing variants are replaced automatically.",
    "replaces": "MyEntity",
    "forms": {
      "global": ["identity", "camel_case", "snake_case", "kebab_case", "lower_case", "upper_case"]
    }
  }
}
```

With `--EntityName OrderItem`, the engine replaces all of these in one pass:

| Placeholder in source | Replaced with |
|---|---|
| `MyEntity` | `OrderItem` |
| `myEntity` | `orderItem` |
| `my_entity` | `order_item` |
| `my-entity` | `order-item` |
| `myentity` | `orderitem` |
| `MYENTITY` | `ORDERITEM` |

Example usage across file types:

```csharp
// MyEntity.cs
public class MyEntity { }               → OrderItem.cs / public class OrderItem { }
```

```json
// appsettings.json
"myEntity": { "tableName": "my_entity" } → "orderItem": { "tableName": "order_item" }
```

```yaml
# docker-compose.yml
service: my-entity                       → service: order-item
```

---

### 10. Custom Forms (regex-based transforms)

When the built-in identifiers aren't enough, define your own in a top-level `forms` section using `replace` (regex find/replace):

```json
{
  "forms": {
    "global": {
      "stripCompanySuffix": {
        "identifier": "replace",
        "parameters": {
          "find": "(?i)service$",
          "replaceWith": ""
        }
      },
      "dockerImageName": {
        "identifier": "replace",
        "parameters": {
          "find": "[^a-z0-9-]",
          "replaceWith": "-"
        }
      }
    }
  },
  "symbols": {
    "ServiceName": {
      "type": "parameter",
      "datatype": "string",
      "replaces": "MyService",
      "forms": {
        "global": ["identity", "lower_case", "stripCompanySuffix", "dockerImageName"]
      }
    }
  }
}
```

With `--ServiceName "OrderService"`:

| Placeholder | Form applied | Result |
|---|---|---|
| `MyService` | `identity` | `OrderService` |
| `myservice` | `lower_case` | `orderservice` |
| `MyServicestripped` | `stripCompanySuffix` | `Order` |
| `my-service` | `dockerImageName` | `orderservice` (after lowercasing first — see chaining below) |

---

### 11. Chaining via Derived Symbols

For multi-step transforms (apply transform A, then transform B to the result), chain `derived` symbols — each takes the output of the previous as its input:

```json
"symbols": {
  "ServiceName": {
    "type": "parameter",
    "datatype": "string",
    "replaces": "MyService"
  },
  "ServiceNameNoSuffix": {
    "type": "derived",
    "valueSource": "ServiceName",
    "valueTransform": "stripCompanySuffix",  ← step 1: "OrderService" → "Order"
    "replaces": "MyServiceBase"
  },
  "ServiceNameDockerTag": {
    "type": "derived",
    "valueSource": "ServiceNameNoSuffix",    ← step 2: derived from step 1
    "valueTransform": "lower_case",          ← "Order" → "order"
    "replaces": "my-service-tag"
  }
}
```

With `--ServiceName "OrderService"`:

```
MyService       → OrderService     (original parameter)
MyServiceBase   → Order            (suffix stripped)
my-service-tag  → order            (lowercased result of step 1)
```

Use this when a built-in form alone isn't enough — clean the value first, then transform the cleaned result.

---

### 12. Applying Forms to `sourceName`

`forms` work on `sourceName` too, giving you all case variants of the project name without any extra symbols:

```json
{
  "sourceName": "MyApp",
  "preferNameDirectory": true,
  "forms": {
    "global": {
      "global": ["identity", "camel_case", "kebab_case", "snake_case", "lower_case"]
    }
  }
}
```

With `-n "ShoppingCart"`:

| Placeholder in source | Replaced with |
|---|---|
| `MyApp` | `ShoppingCart` |
| `myApp` | `shoppingCart` |
| `my-app` | `shopping-cart` |
| `my_app` | `shopping_cart` |
| `myapp` | `shoppingcart` |

This covers C# class names, route paths, Docker image names, and environment variable prefixes all from a single `-n` flag — no extra parameters needed.

---

## Installing & Testing a Template Locally

```bash
# Install from source directory
dotnet new install ./my-template

# List installed templates
dotnet new list

# Generate a project template (creates subdirectory)
dotnet new mytemplate -n MyProject --AuthorName "Jane Smith" --UseDocker false

# Generate an item template (no subdirectory, files land in current dir)
cd src/MyExistingProject
dotnet new myitemtemplate -n OrderService

# Uninstall
dotnet new uninstall YourCompany.MyTemplate
```

After running `install.sh` on a new machine, all templates in this directory are installed automatically.

---

## Quick Reference: Symbol Types

| Type | Use case |
|---|---|
| `parameter` + `string` | Any free-form text substitution |
| `parameter` + `bool` | Feature flags, file inclusion/exclusion |
| `parameter` + `choice` | Enum-style selection (framework, db, auth) |
| `derived` | Transform another symbol (e.g. namespace-safe name) |
| `computed` | Boolean expression from other symbols (drives `#if`) |
| `generated` + `guid` | Fresh GUID per instantiation |
| `generated` + `now` | Current date/year |
| `forms` (built-in) | One parameter → multiple case variants simultaneously |
| `forms` (custom `replace`) | Regex-based transforms on any symbol value |
| chained `derived` | Multi-step transforms — output of one feeds the next |
