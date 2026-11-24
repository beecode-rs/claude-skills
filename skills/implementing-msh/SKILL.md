---
name: implementing-msh
description: How to implement solutions using the MSH (Micro-Service Helper) TypeScript packages from @beecode/msh-* (app-boot, env, error, logger, node-session, util, config). Use this skill whenever the user works with any @beecode/msh-* package, or asks to set up app initialization and graceful shutdown, environment variable validation, HTTP-aware errors and Express error handling, logging, request-scoped sessions/CLS/async-local-storage, or shared utilities (singletons, memoize, timeout, joi validation, time helpers). Also trigger when the user mentions MSH, beecode, AppFlow, LifeCycle, AppStarter, mshEnv, mshEnvResolver, errorFactory, errorHOF, ErrorBaseModel, HttpResponseCodeMapper, PresetConsoleSimpleString, PresetConsoleJson, PresetPino, LogLevel, LoggerStrategy, NodeSessionUtil, SessionStrategy, FastAlsStrategy, ClsHookedStrategy, AsyncLocalStorageStrategy, singletonPattern, SingletonAsync, ObjectUtil, TimeUtil, JoiUtil, memoizeFactory, or msh-config eslint/prettier config. Always consult this skill before writing code that imports from @beecode/msh-* so the correct current API and the right package version are used.
---

# implementing-msh

This skill helps implement features using the MSH (Micro-Service Helper) family of TypeScript packages published under the `@beecode/msh-*` scope. It works as a switch: the user describes a functionality, you route to the right package, verify the installed version is one you know how to help with, and only then write code.

The reason this skill exists as a switch rather than one flat guide is that the packages are decoupled and versioned independently. A user's project may pin `msh-logger@1.x` while you know `2.x`, and the two have different APIs (presets vs logger-strategy classes, different log levels, different import paths). Writing code against the wrong version wastes everyone's time. So the workflow has two steps that always run together: **identify the package**, then **check the version**.

## Contents

- [Supported packages and known versions](#supported-packages-and-known-versions)
- [Workflow](#workflow) - route to the package, check the version, fetch upstream on mismatch, implement
  - [Step 1 - Route to the package(s)](#step-1---route-to-the-packages)
  - [Step 2 - Check the installed version before writing code](#step-2---check-the-installed-version-before-writing-code)
  - [Step 3 - On a major-version mismatch, fetch upstream changes](#step-3---on-a-major-version-mismatch-fetch-upstream-changes)
  - [Step 4 - Read the package reference and implement](#step-4---read-the-package-reference-and-implement)
- [Conventions to match](#conventions-to-match)
- [When the user's request does not map to a package](#when-the-users-request-does-not-map-to-a-package)
- [Keeping this skill current](#keeping-this-skill-current)

## Supported packages and known versions

These are the versions this skill was authored against (captured from the MSH monorepo source). They are the versions you can help with directly from the bundled references, without going to the internet.

| Package | npm name | Known version | Reference |
|---------|----------|---------------|-----------|
| app-boot | `@beecode/msh-app-boot` | `2.0.2` | `references/app-boot-2.0.2.md` |
| env | `@beecode/msh-env` | `2.0.3` | `references/env-2.0.3.md` |
| error | `@beecode/msh-error` | `2.0.6` | `references/error-2.0.6.md` |
| logger | `@beecode/msh-logger` | `2.0.2` | `references/logger-2.0.2.md` |
| node-session | `@beecode/msh-node-session` | `4.0.5` | `references/node-session-4.0.5.md` |
| util | `@beecode/msh-util` | `3.0.1` | `references/util-3.0.1.md` |
| config | `@beecode/msh-config` | `1.2.2` | `references/config-1.2.2.md` |

Each package reference file is named `<package>-<version>.md` for the exact version it was written against, so multiple versions can coexist. When a package ships a new major (or a minor with notable API changes), add a new `references/<package>-<new-version>.md` file instead of overwriting the old one, and add a row for it above. To pick which file to read at runtime, match the user's installed major; if several files share that major, read the one closest to the installed version. If none matches the user's major, that is a breaking boundary (Step 3).

## Workflow

### Step 1 - Route to the package(s)

Read `references/packages.md`. It maps common user intents ("set up logging", "throw a 403", "validate env vars", "graceful shutdown", "request-scoped session") to one or more packages, with keywords to disambiguate. A single request often touches several packages (for example, app-boot wants a logger from msh-logger; env wants a logger from msh-logger; node-session often pairs with msh-util's `singletonPattern`). Identify every package the task involves, not just the obvious one.

If the intent is ambiguous or spans packages you are unsure about, ask the user a short clarifying question before reading references. Do not guess and write code against the wrong package.

### Step 2 - Check the installed version before writing code

This step is mandatory and is what prevents the most expensive mistake: writing code for a version the user does not have.

Read `references/version-check.md` and follow it. In short:

1. Find the installed version of each involved `@beecode/msh-*` package in the user's project (read `package.json` for the declared range, and `package-lock.json` for the exact resolved version).
2. Compare the installed **major** version against the known version above.
   - **Same major** (e.g. known `2.0.2`, installed `2.1.0`): you can help directly from the bundled reference. Note the delta to the user and proceed. Patch/minor differences rarely break the public API.
   - **Different major** (e.g. known `2.x`, installed `1.x` or `3.x`): this is a breaking boundary. Do not write code yet. Go to Step 3.
3. If the package is not installed at all, tell the user the install command from the reference and confirm they want to add it.

### Step 3 - On a major-version mismatch, fetch upstream changes

When the installed major version differs from the known one, your bundled reference may be wrong for the user's version. Fetch the upstream README and (if present) MIGRATION.md from the package's GitHub repo and adapt:

- README: `https://raw.githubusercontent.com/beecode-rs/msh-<pkg>/main/README.md`
- Migration guide: `https://raw.githubusercontent.com/beecode-rs/msh-<pkg>/main/MIGRATION.md`
- Releases: `https://github.com/beecode-rs/msh-<pkg>/releases`

Use `WebFetch` (or the web-reader MCP) to pull these. The repo name is `msh-<pkg>` where `<pkg>` is the package suffix (e.g. `msh-app-boot`, `msh-node-session`, `msh-env`). Summarize to the user what changed across the breaking boundary (renamed imports, removed APIs, new required params) and write code for **their** version, not the known one. If their version is newer than the known one, the upstream README teaches you the new API; if older, the MIGRATION.md teaches you how their version differs from what you know.

If the fetch fails or returns nothing useful, say so honestly and offer to help against the known version with a clear caveat that the user should verify against their installed version's docs.

### Step 4 - Read the package reference and implement

Read the matching versioned reference for each involved package. Files are named `references/<pkg>-<version>.md` (e.g. `references/logger-2.0.2.md`). Pick the file whose major matches the user's installed version; if several share that major, pick the closest. If no file matches the user's major, go back to Step 3. Each reference contains: the install command, the exact public exports and import paths, copy-paste usage examples, and any breaking-change notes. Write code that matches the user's installed version and follows the conventions below.

## Conventions to match

These packages and their consumers follow specific conventions. Match them so generated code fits the surrounding project:

- **Imports**: consumers import from the npm package, e.g. `import { errorFactory } from '@beecode/msh-error'`. Subpath imports are used for presets and strategies that are not exported from the main entry (e.g. `@beecode/msh-logger/controller/preset/console-simple-string`). Always use the exact subpath shown in the reference; do not invent paths.
- **Strategy pattern**: logging, sessions, and env location/naming all use pluggable strategies. Prefer the bundled presets/defaults over hand-rolling a strategy unless the user needs custom behavior.
- **Errors**: throw `errorFactory()` errors (they carry `httpCode` and `payload`); catch with `instanceof ErrorBaseModel` when you need the structured fields.

## When the user's request does not map to a package

If the user is working in an MSH-based project but the task is not about an `@beecode/msh-*` package (for example, general TypeScript, a database, or another library), do not force this skill onto it. Help directly and only pull a package reference if a specific `@beecode/msh-*` import comes up.

## Keeping this skill current

The known versions above drift as packages release. Reference files are versioned in their names so old versions stay supported alongside new ones: when a package ships a new major (or a minor with notable API changes), add a new `references/<package>-<new-version>.md` file rather than overwriting the existing one, then add a row to the known-versions table above. When you discover a user running a newer major than any bundled file, and you fetch and learn the new API, mention to the user that the skill has no file for that version yet, so they can add one if they want the skill to stay current. When you add, rename, or remove a section in this file or in a reference file, update the Contents list at its top so the map stays accurate.
