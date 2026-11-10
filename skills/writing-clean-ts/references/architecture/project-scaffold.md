# Project Scaffold

The one-time setup every new project gets before any feature code, and the same
setup an existing project gets when any piece is missing. This is step zero for
"create a project from scratch" and it exists for a concrete reason: projects
generated without it drift into relative imports, ad-hoc top-level folders
(`src/boot/`, `src/data/`, folder-per-file), hand-rolled boot code, and no lint
gate, so the cleanup command then reports dozens of issues. The scaffold makes
generation and cleanup agree: after setup plus layer-order construction, a
cleanup pass should find nothing structural to fix.

When a project already has all six pieces below, skip this file.

## Contents

- [The six setup pieces](#the-six-setup-pieces)
  - [1. package.json](#1-packagejson)
  - [2. tsconfig.json](#2-tsconfigjson)
  - [3. eslint.config.js](#3-eslintconfigjs)
  - [4. .prettierrc and .prettierignore](#4-prettierrc-and-prettierignore)
  - [5. Dev dependencies, pinned to the supported line](#5-dev-dependencies-pinned-to-the-supported-line)
  - [6. Verification loop](#6-verification-loop)
- [Then build in layer order](#then-build-in-layer-order)
- [Setup checklist](#setup-checklist)

## The six setup pieces

### 1. package.json

ES modules, the `#src` runtime alias, and the lint scripts:

```json
{
  "type": "module",
  "imports": {
    "#src/*": "./dist/*"
  },
  "scripts": {
    "build": "tsc",
    "dev": "tsx watch src/main.ts",
    "lint": "pnpm run lint:prettier && pnpm run lint:eslint && pnpm run lint:json",
    "lint-fix": "pnpm run lint-fix:prettier && pnpm run lint-fix:eslint && pnpm run lint-fix:json",
    "lint-fix:eslint": "eslint ./ --fix",
    "lint-fix:json": "jsonsort -t *.json '!./node_modules' '!./**/.env*'",
    "lint-fix:prettier": "prettier --write {**/*,*}.{js,ts,jsx,tsx,cjs,cts,mjs,mts,html}",
    "lint:eslint": "eslint ./ --quiet --no-error-on-unmatched-pattern",
    "lint:json": "pnpm run lint-fix:json -c",
    "lint:prettier": "prettier --check {**/*,*}.{js,ts,jsx,tsx,cjs,cts,mjs,mts,html}",
    "start": "node dist/main.js"
  }
}
```

**Why `"#src/*": "./dist/*"` and not `"./dist/*.js"`**: with `module: NodeNext`,
every internal import specifier already carries an explicit `.js` extension
(`#src/business/service/foo-service.js`). The `imports` mapping appends its own
suffix to whatever the `*` captured, so `./dist/*.js` produces
`./dist/business/service/foo-service.js.js` and plain `node dist/main.js` dies
with `ERR_MODULE_NOT_FOUND`. tsc never catches this (tsconfig `paths` resolves
the same specifier to the `.ts` source), only a real runtime boot does.

### 2. tsconfig.json

`NodeNext` resolution, strict mode, and the compile-time half of the alias.
For TypeORM projects also the decorator flags:

```json
{
  "compilerOptions": {
    "esModuleInterop": true,
    "experimentalDecorators": true,
    "emitDecoratorMetadata": true,
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "outDir": "dist",
    "paths": {
      "#src": ["./src"],
      "#src/*": ["./src/*"]
    },
    "rootDir": "src",
    "strict": true
  },
  "include": ["src"]
}
```

How the alias resolves: compile time through tsconfig `paths` (tsc and the
editor), dev time through `tsx` (honors the same paths), runtime in plain Node
through the package.json `imports` field. All three agree only when both halves
are configured exactly as above.

### 3. eslint.config.js

Generate from the complete Node.js backend template in `references/linting.md`
(flat config, type-checked presets, `no-loops`, `no-ternary`,
`no-relative-import-paths`, `sort-keys-fix`, `no-console`, the naming-convention
table). React frontends use the React deltas listed there.

### 4. .prettierrc and .prettierignore

```json
{
  "arrowParens": "always",
  "bracketSpacing": true,
  "endOfLine": "lf",
  "printWidth": 120,
  "semi": false,
  "singleQuote": true,
  "tabWidth": 2,
  "trailingComma": "all"
}
```

`.prettierignore` covers at least: `node_modules`, `dist`, `pnpm-lock.yaml`,
`.env*` (keep `!.env*.example`). Note that `jsonsort` rewrites JSON files with
tab indentation - that is its output style, not a formatting bug to fix by hand.

### 5. Dev dependencies, pinned to the supported line

```sh
pnpm add -D typescript@~6.0.0 @eslint/js@^9 eslint@^9 typescript-eslint@^8 \
  eslint-plugin-import eslint-plugin-no-loops eslint-plugin-no-only-tests \
  eslint-plugin-no-relative-import-paths eslint-plugin-sort-keys-fix \
  globals prettier json-sort-cli
```

The pins are load-bearing, learned from real failures, not stylistic:

| Package | Pin | Why |
|---|---|---|
| `typescript` | `~6.0.0` | typescript-eslint 8.x hard-errors on TS 7 (`typescript-eslint does not support TS 7.0`); TS 6 is the JS-compiler line the lint toolchain supports |
| `eslint` + `@eslint/js` | `^9` | `eslint-plugin-import` 2.x crashes on ESLint 10 (`sourceCode.getTokenOrCommentAfter is not a function`) |
| `typescript-eslint` | `^8` | the version whose rule set `references/linting.md` documents |
| `prettier` | `^3` | current major; no known conflicts |

Also: native modules (e.g. `better-sqlite3`) may need `pnpm rebuild
better-sqlite3` when the cached binding was built for a different Node version;
symptom is `Could not locate the bindings file` at boot.

### 6. Verification loop

After setup and after every task (create, edit, extend), the same loop is the
definition of done:

```sh
pnpm build && pnpm lint-fix && pnpm lint
```

All three exit 0, plus the app actually boots (`pnpm start` or `pnpm dev`) when
the task touched boot, DAL, or config code. The runtime boot matters: the two
bugs below passed `tsc` and only surfaced at boot.

## Then build in layer order

With the scaffold green, create code following `references/architecture/file-organization-pattern.md`
for placement, and read `references/architecture/example-app.md` for the
assembled shape of a complete verified project (all layers, config, boot). A
TypeORM + Express backend needs explicit column types on entities (see
`references/frameworks/typeorm.md`) because `tsx` does not emit decorator
metadata.

## Setup checklist

- [ ] `"type": "module"` and `"imports": { "#src/*": "./dist/*" }` in package.json
- [ ] tsconfig has both `paths` entries and `module`/`moduleResolution` `NodeNext`
- [ ] `lint` and `lint-fix` scripts exist and both exit 0 on the empty project
- [ ] eslint.config.js from the linting reference, Node or React flavor to match the runtime
- [ ] `.prettierrc` and `.prettierignore` in place
- [ ] typescript `~6.0.0`, eslint `^9`: not newest-major, the supported line
- [ ] `pnpm build` succeeds and `node dist/main.js` (or the dev command) boots
