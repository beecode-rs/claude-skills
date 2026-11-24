# Version check and breaking-change lookup

This is the procedure behind Step 2 and Step 3 of the SKILL.md workflow. Run it for every `@beecode/msh-*` package the task involves, before writing any code.

The point of this check: the bundled package references describe a specific known version (see the table in SKILL.md). The user's project may have a different major version, and across a major boundary the API can change enough that code from the reference will not compile or will behave wrong. Catching this up front is the single most valuable thing this skill does.

## Contents

- [Known versions (authoritative for this skill)](#known-versions-authoritative-for-this-skill)
- [Reference files are versioned](#reference-files-are-versioned)
- [Step A - Find the installed version](#step-a---find-the-installed-version)
- [Step B - Compare](#step-b---compare)
- [Step C - Fetch upstream on a breaking boundary](#step-c---fetch-upstream-on-a-breaking-boundary)
  - [What to do with what you find](#what-to-do-with-what-you-find)
  - [Known breaking boundaries](#known-breaking-boundaries-already-documented-in-the-bundled-references)
- [Honesty when fetch fails](#honesty-when-fetch-fails)

## Known versions (authoritative for this skill)

| Package | Known version | Major |
|---------|---------------|-------|
| `@beecode/msh-app-boot` | `2.0.2` | 2 |
| `@beecode/msh-env` | `2.0.3` | 2 |
| `@beecode/msh-error` | `2.0.6` | 2 |
| `@beecode/msh-logger` | `2.0.2` | 2 |
| `@beecode/msh-node-session` | `4.0.5` | 4 |
| `@beecode/msh-util` | `3.0.1` | 3 |
| `@beecode/msh-config` | `1.2.2` | 1 |

## Reference files are versioned

Each package has one reference file per version it was written against, named `references/<package>-<version>.md` (e.g. `references/logger-2.0.2.md`). After you determine the user's installed version (Step A) and confirm the major matches (Step B), read the file whose major matches the installed version. If several files share that major, read the one closest to the installed version (they describe the same API line; the closest is most accurate). If no file matches the user's major, do not read a mismatched file - that is a breaking boundary; go to Step C, fetch upstream, and write code for the user's version.

## Step A - Find the installed version

Look in the user's project root (and any workspace roots in a monorepo). Two sources, use both:

1. **Declared range** in `package.json` (`dependencies` / `devDependencies`), e.g. `"@beecode/msh-logger": "^2.0.2"`. The caret/tilde tells you the allowed range but not the exact installed copy.
2. **Resolved version** in `package-lock.json`. Grep for the package name and read the `"version"` field. This is the truth of what is actually installed.

A quick way to read both at once from the project root:

```bash
grep -n '@beecode/msh-' package.json
grep -n '"@beecode/msh-' package-lock.json
```

In a workspace/monorepo, each workspace has its own `package.json` and possibly its own lockfile or a shared root lockfile; check the workspace the user is editing in.

If the user has `node_modules` installed and the lockfile is missing, you can also read `node_modules/@beecode/msh-<pkg>/package.json` for the `version` field.

## Step B - Compare

Let `knownMajor` be the major from the table above and `installedMajor` be the major of the resolved version.

- `installedMajor === knownMajor`: proceed with the bundled reference. If the installed version is behind the known version (e.g. installed `2.0.0`, known `2.0.6`), mention the gap in case a feature you use was added later, but the API is compatible. Code from the reference is safe.
- `installedMajor !== knownMajor`: breaking boundary. Do not write code from the reference yet. Go to Step C.
- Not installed: give the install command from the package reference and confirm the user wants to add it before writing code that imports it.

## Step C - Fetch upstream on a breaking boundary

When the major differs, fetch the upstream docs for the user's version and adapt. The packages live in separate GitHub repos under `beecode-rs`, named `msh-<suffix>`:

| Package | GitHub repo |
|---------|-------------|
| `@beecode/msh-app-boot` | `beecode-rs/msh-app-boot` |
| `@beecode/msh-env` | `beecode-rs/msh-env` |
| `@beecode/msh-error` | `beecode-rs/msh-error` |
| `@beecode/msh-logger` | `beecode-rs/msh-logger` |
| `@beecode/msh-node-session` | `beecode-rs/msh-node-session` |
| `@beecode/msh-util` | `beecode-rs/msh-util` |
| `@beecode/msh-config` | `beecode-rs/msh-config` |

Fetch in this order, stop when you have enough to write correct code:

1. **MIGRATION.md** (the fastest source of "what broke between major versions"):
   `https://raw.githubusercontent.com/beecode-rs/msh-<pkg>/main/MIGRATION.md`
   Not every package has one; error and logger do. If absent, skip.
2. **README.md** (current public API and examples for the latest version):
   `https://raw.githubusercontent.com/beecode-rs/msh-<pkg>/main/README.md`
3. **Releases** (changelog per version, useful when the user's version is between known and latest):
   `https://github.com/beecode-rs/msh-<pkg>/releases`

Use `WebFetch` on the raw URLs (or the web-reader MCP). For a raw file, prompt WebFetch with "return the full content".

### What to do with what you find

- If the user's version is **older** than known (e.g. installed msh-logger `1.x`, known `2.x`): the MIGRATION.md "v1 to v2" section tells you exactly how their API differs (logger-strategy classes vs presets, `messagePrefix` vs `category`, old log levels, old import paths). Write code for their `1.x` API using the "v1" side of the migration table, and offer to help them upgrade.
- If the user's version is **newer** than known: the README and releases teach you the new API. Write code for the new API and note that the bundled reference is now behind (see "Keeping this skill current" in SKILL.md).

### Known breaking boundaries (already documented in the bundled references)

These are captured locally so you do not always need to fetch:

- **msh-error 1.x to 2.x**: internal restructure into `business/model/` and `business/service/` layers. Main entry `errorFactory`/`errorHOF` unchanged. Subpath imports moved (e.g. `dist/error/factory` to `dist/business/service/error-factory`). `stringUtil.codeNameFromEnum` removed, use `httpResponseCodeUtil.codeNameFromEnum`. See `references/error-2.0.6.md`.
- **msh-logger 1.x to 2.x**: logger-strategy classes became presets; `ConsoleLogStrategy*` split into `FormattingStrategy*` + `TransportingStrategy*`; `messagePrefix` became `category`; `LogLevel` mapping changed from 0 to 3 to 10 to 60 and added `FATAL`/`TRACE`; `consoleLogStrategy` param removed; JSON `logtype` key became `level`. See `references/logger-2.0.2.md`.

For any boundary not listed here, fetch upstream.

## Honesty when fetch fails

If `WebFetch` returns nothing useful (private repo, network blocked, 404), say so plainly: "I could not fetch the upstream docs for `<pkg>`; the code below is written for the known version `<x.y.z>` and may not match your installed `<a.b.c>`. Please verify against your version's README." Then write the best-effort code. Do not silently pretend the known version applies.
