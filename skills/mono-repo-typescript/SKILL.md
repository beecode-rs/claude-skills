---
name: mono-repo-typescript
description: Expert in TypeScript monorepo architecture using pnpm workspaces. Helps with structuring packages (microservices, web apps, mobile apps, shared libs), configuring ES modules with path aliases, centralized config, Docker Compose orchestration, and inter-package dependencies. Use when user mentions monorepo, pnpm workspace, packages folder, shared libraries, common libs, multi-package project, microservices architecture, Docker Compose development environment, workspace setup, monorepo structure, package organization, shared config. Also use when starting a new TypeScript project that might grow to multiple services/apps, when splitting a service into smaller pieces, when asking about code sharing between frontend and backend, or when setting up any project with more than one deployable unit.
allowed-tools: Read, Write, Edit, Grep, Glob, Bash
model: sonnet
---

# TypeScript Monorepo Architecture

## Purpose

Guide the structure and orchestration of TypeScript monorepos with multiple packages including microservices, web apps, mobile apps, and shared libraries. Focus on high-level architecture, build orchestration, and development environment.

**Scope boundaries:**
- **This skill:** Monorepo structure, package organization, Docker Compose, build orchestration
- **writing-clean-ts skill:** Individual package code patterns (services, repositories, controllers)
- **contract-testing-ts skill:** Testing patterns and coverage

## When to Use

- Setting up a new monorepo with pnpm workspaces
- Structuring packages folder (microservices, web, mobile, libs)
- Configuring shared libraries (common, node-common, react-common)
- Setting up ES modules with path aliases
- Centralizing configuration (TypeScript, ESLint, Vitest)
- Orchestrating Docker Compose for development
- Managing inter-package dependencies
- **Starting ANY new TypeScript project that might grow to multiple packages**

## When NOT to Use

- **Single-package projects** → Use `writing-clean-ts` skill instead
- **Yarn or npm workspaces** → This skill is pnpm-specific
- **Non-TypeScript monorepos** → Patterns here assume TypeScript throughout
- **Existing monorepo with different conventions** → Adapt patterns as needed

## Quick Decision Guide

**Choosing the right package type:**

| You need... | Create... | Dependencies |
|-------------|-----------|--------------|
| Shared business models, utilities | `packages/common/` | None (pure) |
| Database, logging, messaging (Node.js) | `packages/node-common/` | `common` |
| Shared React components, hooks | `packages/react-common/` | `common` |
| Backend API/microservice | `packages/node-{domain}/` | `common`, `node-common` |
| Web application (Vite) | `packages/react-{name}/` | `common`, `react-common` |
| Mobile app (Expo) | `packages/mobile-app/` | `common`, `react-common` |
| Marketing/public site | `packages/website/` | `common`, `react-common` |

**Dependency flow:**
```
common → node-common → node-{service}
common → react-common → react-{app} / mobile-app
```

## Package Rules

These rules hold in every monorepo built with this skill. Code inside each package
follows `writing-clean-ts`.

### Where shared code goes

Put code in the lowest package that every consumer already depends on:

| The code is used by... | It goes in... |
|---|---|
| Frontend and backend (models, Zod schemas, enums, pure utils) | `common` |
| Several Node services and needs Node (DB, RMQ, Express middleware, logger setup) | `node-common` |
| Several React apps (components, hooks, API client) | `react-common` |
| One package only | That package |

- A model or Zod schema that both a `node-*` service and a `react-*` app use lives in
  `common`, never duplicated in each package.
- Code used by one package stays there. Move it down to a shared package when a second
  package needs it, not before.
- A shared package never contains code that only one app or service uses.

### Dependency direction

- `common` depends on no workspace package and on nothing platform-specific: no Node
  built-ins (`fs`, `path`), no Express or TypeORM, no React or DOM APIs.
- `node-common` depends only on `common`. `react-common` depends only on `common`.
- The tooling-only `@app/config` package (ESLint, Prettier and shared config files) is
  the one exception: any package may list it, and it holds no runtime code.
- `react-*`, `mobile-app` and `website` never depend on `node-*` or `node-common`, and
  `node-*` never depends on `react-*` or `react-common`.
- A service never imports another service (`node-core` never imports `node-auth`).
  Services talk over HTTP or RMQ; code they both need moves down to `common` or
  `node-common`.
- An app never imports another app (`react-admin` never imports `react-core`, and neither
  imports `mobile-app` or `website`). Code two apps need moves down to `react-common` (or
  `common` when it has no React code).
- To break a cycle, move the code both sides need down into the lowest package both
  already depend on. Never break it by adding the reverse dependency.

### Imports across packages

- Inside a package, import its own files with `#src/...` and the `.js` extension:
  `import { userService } from '#src/business/service/user/user-service.js'`.
- Across packages, import through the target's `exports` map with the full path and no
  extension: `import { UserModel } from '@app/common/business/model/user/user-model'`. The
  `"./*"` export already maps it to `./dist/*.js`, so adding `.js` would resolve to
  `user-model.js.js`.
- Never import another package with a relative path (`../../common/src/...`), through its
  `src/` or `dist/` folder (`@app/common/src/...`), through its `__internal__/` folder, or
  as a bare package name (`@app/common`). Packages have no `"."` export and no barrel.
  The `writing-clean-ts` exception that lets an npm package's `main` entry be an
  `index.ts` applies only to packages published to npm, never to `@app/` workspace
  packages.
- The importing package lists the target in `dependencies` as `"workspace:*"`.

### Dependency versions

- Internal packages use `"workspace:*"`.
- External packages use `"catalog:"`. A package never pins its own version range.
- To add a new external dependency, add it to `catalog:` in `pnpm-workspace.yaml` first,
  then reference it as `"catalog:"` in the package, then run `pnpm install`.
- `ERR_PNPM_CATALOG_ENTRY_NOT_FOUND_FOR_SPEC` means a package references `catalog:` for a
  dependency the catalog doesn't have. Add it to the catalog.

### package.json shape

Every library and service package has:

- `name`: `@app/{folder-name}`
- `type`: `module`
- `exports`: `"./*"` mapping `import` to `./dist/*.js` and `types` to `./src/*.ts`.
  Shared libraries (`common`, `node-common`, `react-common`) add
  `"./__internal__/*": null`.
- `imports`: `"#src/*.js": "./dist/*.js"`
- scripts: `build` is `node ../../resource/script/npm/clean.js . && tsc -p ./tsconfig.build.json`,
  `clean` is `node ../../resource/script/npm/clean.js .`, and `test` runs Vitest with a
  base config from `config/vitest/`. Node resolves `#src` at runtime through `imports`, so
  the build needs no `tsc-alias` step. Every package also owns `"lint:eslint": "eslint ./ --quiet"`
  and `"lint-fix:eslint": "eslint ./ --fix"`, with an `eslint.config.js` that calls the
  root factory (`writing-clean-ts` `references/linting.md`).
- dependencies: `workspace:*` and `catalog:` only (see above).

A Vite app (`react-{name}`) has no `exports`, `imports` or `tsc` build: its `build` is
`tsc --noEmit && vite build`. `mobile-app` follows `writing-clean-ts`
`references/frameworks/expo.md`: no `type`, no `exports` or `imports`,
`"main": "expo-router/entry"`, and the `@/*` tsconfig alias instead of `#src`.

The root `package.json` holds `engines` (`node` and `pnpm` ranges), `private: true` and the
orchestration scripts.

### TypeScript config

- A Node or shared package's `tsconfig.json` extends
  `../../config/typescript/tsconfig.base.json`; a React package extends
  `../../config/typescript/tsconfig.react.base.json`. Every package sets the `#src` paths;
  packages that compile to `dist/` also set `outDir` and `rootDir`, while a Vite app sets
  `noEmit: true` (Vite builds it).
- `tsconfig.build.json` extends `./tsconfig.json` and turns on declarations.
- The root `tsconfig.json` has `composite: true`, `files: []` and one `references` entry per
  package folder. A new package is added to `references`.

### Root scripts

- The root `package.json` only orchestrates: `build`, `clean` and `test` fan out with
  `pnpm -r`, and `watch` runs `tsc -b -w`.
- Lint follows `writing-clean-ts` `references/linting.md`: the root runs Prettier, its own
  ESLint pass, `jsonsort`, and `lint:packages` (`pnpm -r run lint:eslint`), which fans out
  to each package's `lint:eslint`.
- Each package owns its `build`, `clean`, `test` and `serve` scripts. Root scripts never
  repeat package logic.
- Run one package's script with `pnpm --filter @app/{name} {script}` (or the `ws-build` /
  `ws-test` shortcuts, which expand to it), never `cd packages/{name} && pnpm run ...`.

### compose.yml services

Each runnable package is one service named after its folder:

- `build` uses context `.` and `resource/docker/Dockerfile.node-base`.
- `command: pnpm run serve` and `working_dir: /app/packages/{name}`.
- The source is mounted read-only: `./:/app:ro` (plus the `node_modules` named volume).
- `depends_on` lists the infrastructure it needs with `condition: service_healthy`, and
  every infrastructure service (`pg`, `rmq`, `proxy`) defines a `healthcheck`.
- Traefik labels route by path: `PathPrefix(`/api/{domain}`)` with a `stripprefix`
  middleware for a backend service, `PathPrefix(`/{app}`)` for a frontend app.

### READMEs

Every package has a `README.md`, no exceptions, plus one at the monorepo root.
A README is written for the reader who just arrived: what this thing is, how to run
it, what it expects from the environment.

**Library package** (published or installed by other projects): title, one-line
purpose, badges (CI, coverage, license, npm) when the package is published, a
generated table of contents, `Install` (`pnpm i @scope/name`), `Quick Start` or
`Usage` with one minimal runnable example, `API Reference` when the package has a
real surface, `Architecture` with a diagram when it helps, `License`.

**App or service package** (runnable, not installed): title, one-line purpose,
generated table of contents, how to run it in dev (the compose service and its URL),
env vars as one table per config group with `env` / `Required` / `Default` columns
generated from the package's `src/util/config.ts`, the scripts worth knowing, and a
short note on how it fits with the other packages.

**Monorepo root**: what the project is, a package map, prerequisites, getting
started (the init steps in order), and the common commands.

**Diagrams** inside a README: PlantUML by default. Use Mermaid when the project is
open source and hosted on GitHub, because GitHub renders Mermaid natively.

The table of contents uses `<!-- toc -->` / `<!-- tocstop -->` markers and is
generated (`markdown-toc` or equivalent), never maintained by hand.

## Monorepo Structure Overview

```
project-root/
├── packages/                    # All packages live here
│   ├── common/                  # Shared business models, utilities
│   ├── node-common/             # Node.js-specific utilities
│   ├── react-common/            # React shared components
│   ├── config/                  # Shared ESLint, Prettier, TypeScript configs
│   ├── node-core/               # Backend microservice
│   ├── node-auth/               # Auth microservice
│   ├── react-admin/             # Admin web app
│   ├── react-core/              # Main web app
│   ├── mobile-app/              # Mobile app (React Native/Expo)
│   └── website/                 # Marketing site (Next.js)
├── config/                      # Root-level shared configs
│   ├── typescript/              # TypeScript base configs
│   ├── vitest/                  # Vitest base configs
│   └── eslint/                  # ESLint base configs
├── resource/
│   ├── script/                  # Build and utility scripts
│   ├── docker/                  # Dockerfiles
│   └── secret/                  # Encrypted secrets
├── package.json                 # Root orchestration
├── pnpm-workspace.yaml          # Workspace and catalog config
├── tsconfig.json                # TypeScript project references
├── compose.yml                  # Docker Compose for development
└── .env.example                 # Environment template
```

## Root Orchestration

### package.json

```json
{
  "name": "project-name",
  "type": "module",
  "private": true,
  "engines": {
    "node": ">=22 <23",
    "pnpm": ">=10 <11"
  },
  "scripts": {
    "build": "tsc -b && pnpm -r build",
    "clean": "pnpm -r clean",
    "lint": "pnpm run lint:prettier && pnpm run lint:eslint && pnpm run lint:packages && pnpm run lint:json",
    "lint-fix": "pnpm run lint-fix:prettier && pnpm run lint-fix:eslint && pnpm run lint-fix:packages && pnpm run lint-fix:json",
    "lint:eslint": "eslint ./ --quiet --no-error-on-unmatched-pattern",
    "lint-fix:eslint": "pnpm run lint:eslint --fix",
    "lint:packages": "pnpm -r run lint:eslint",
    "lint-fix:packages": "pnpm -r run lint-fix:eslint",
    "lint:prettier": "prettier --check {**/*,*}.{js,ts,jsx,tsx,cjs,cts,mjs,mts,html}",
    "lint-fix:prettier": "prettier --write {**/*,*}.{js,ts,jsx,tsx,cjs,cts,mjs,mts,html}",
    "lint:json": "pnpm run lint-fix:json -c",
    "lint-fix:json": "jsonsort -t *.json '!./packages' '!./node_modules' '!./**/.env*'",
    "test": "pnpm -r test",
    "watch": "tsc -b -w",
    "ws-build": "pnpm --filter",
    "ws-test": "pnpm --filter"
  },
  "devDependencies": {
    "@types/node": "catalog:",
    "typescript": "catalog:",
    "vitest": "catalog:",
    "eslint": "catalog:",
    "prettier": "catalog:"
  },
  "pnpm": {
    "overrides": {
      "@internal/msh-*": "link:../external-msh-monorepo/packages/$1"
    }
  }
}
```

> **Note:** The `pnpm.overrides` section shows how to link packages from an external monorepo. This is an example for a specific project setup - remove if not needed.

### pnpm-workspace.yaml

```yaml
packages:
  - packages/*

catalog:
  typescript: ^5.7
  vitest: ^3.0
  eslint: ^9.22
  prettier: ^3.5
  "@types/node": ^22
  zod: ^3.24
  express: ^5.0
  react: ^19
  "@mui/material": ^7

catalogProtocols:
  # Example for external monorepo linking:
  # msh-internal: link:
```

> **Note:** Use `catalog:` in package.json to reference these versions. This ensures consistency across all packages.

### tsconfig.json (Project References)

```json
{
  "compilerOptions": {
    "composite": true
  },
  "references": [
    { "path": "packages/common" },
    { "path": "packages/node-common" },
    { "path": "packages/react-common" },
    { "path": "packages/node-core" },
    { "path": "packages/react-admin" }
  ],
  "files": []
}
```

## Package Types Overview

| Package | Purpose | Dependencies |
|---------|---------|--------------|
| `common` | Shared business models, utilities | None (pure) |
| `node-common` | Node.js infrastructure (DB, logging, MQ) | `common` |
| `react-common` | Shared React components, hooks | `common` |
| `node-*` | Backend microservices | `common`, `node-common` |
| `react-*` | Frontend web apps | `common`, `react-common` |
| `mobile-app` | React Native/Expo app | `common`, `react-common` |

**For detailed package configurations, see:**
- [Backend Packages](references/backend-packages.md) - common, node-common, microservices
- [Frontend Packages](references/frontend-packages.md) - react-common, web apps, mobile

## ES Modules & Path Aliases

### The #src/* Pattern

Each package uses path aliases for clean imports:

**tsconfig.json:**
```json
{
  "compilerOptions": {
    "paths": {
      "#src": ["./src"],
      "#src/*": ["./src/*"]
    }
  }
}
```

**package.json:**
```json
{
  "imports": {
    "#src/*.js": "./dist/*.js"
  }
}
```

**Usage in code** (always with the `.js` extension):
```typescript
import { someUtil } from '#src/util/some-util.js'
import { UserModel } from '#src/business/model/user/user-model.js'
```

**Why this matters:** The `#src/*` alias works both at compile-time (TypeScript paths) and runtime (Node.js subpath imports), so built code works without path rewriting issues.

### Build Process

```bash
# 1. Clean dist
node ../../resource/script/npm/clean.js .

# 2. Compile TypeScript
tsc -p ./tsconfig.build.json
```

No alias-rewriting step: the compiled code keeps `#src/...js` imports and Node resolves
them at runtime through the package's `imports` field.

## Inter-Package Dependencies

### Dependency Hierarchy

```
                    @app/common (core models, utilities)
                          │
          ┌───────────────┼───────────────┐
          │               │               │
          ▼               ▼               ▼
      node-common    node-core      react-common
          │               │               │
          │               │               │
          └───────────────┴───────────────┘
                          │
                          ▼
                    Frontend Apps
              (react-admin, react-core, mobile-app)
```

### Workspace Dependencies

In package.json:
```json
{
  "dependencies": {
    "@app/common": "workspace:*",
    "@app/node-common": "workspace:*",
    "@app/react-common": "workspace:*",
    "@app/config": "workspace:*"
  }
}
```

### Catalog Dependencies

In package.json:
```json
{
  "dependencies": {
    "zod": "catalog:",
    "express": "catalog:",
    "typeorm": "catalog:"
  },
  "devDependencies": {
    "typescript": "catalog:",
    "vitest": "catalog:"
  }
}
```

## Docker Compose Development

**For full Docker setup, see [Infrastructure Reference](references/infrastructure.md)**

### Quick Start

```yaml
# compose.yml - minimal example
services:
  node-core:
    build:
      context: .
      dockerfile: resource/docker/Dockerfile.node-base
    command: pnpm run serve
    working_dir: /app/packages/node-core
    volumes:
      - ./:/app:ro
    depends_on:
      pg: { condition: service_healthy }
    labels:
      - "traefik.http.routers.node-core.rule=PathPrefix(`/api/core`)"
```

### Common Commands

```bash
docker compose up -d          # Start all services
docker compose logs -f node-core  # View logs
docker compose up -d --build node-core  # Rebuild
docker compose down           # Stop all
```

## Process

### 1. Analyze Requirements

- Identify package types needed (services, apps, libs)
- Determine shared code boundaries
- Plan dependency hierarchy

### 2. Structure Packages

- Create packages in `./packages/` folder
- Set up common libs first (common, node-common, react-common)
- Configure package.json with proper exports and workspace deps
- Create tsconfig.json extending base configs

### 3. Configure Root

- Set up pnpm-workspace.yaml with catalog
- Configure root package.json scripts
- Create tsconfig.json with project references
- Set up centralized config in config/

### 4. Set Up Docker

- Create compose.yml with all services
- Configure Traefik routing
- Set up health checks
- Configure volume mounts for development

### 5. Verify Setup

```bash
pnpm install      # Install dependencies
pnpm build        # Build all packages
pnpm test         # Run tests
docker compose up -d  # Start development environment
```

## Adding a New Package

Use this checklist when creating a new package:

### Backend Package

1. [ ] Create directory: `packages/node-{name}/`
2. [ ] Create `package.json` with:
   - `name`: `@app/node-{name}`
   - `type`: `module`
   - `exports` (`"./*"`) and `imports` (`"#src/*.js": "./dist/*.js"`)
   - Dependencies: `@app/common`, `@app/node-common` as `workspace:*`, external ones as `catalog:`
   - `build`, `clean`, `lint:eslint`, `lint-fix:eslint`, `serve`, `start` and `test` scripts
3. [ ] Create `tsconfig.json` extending `../../config/typescript/tsconfig.base.json`
4. [ ] Create `tsconfig.build.json` for production builds, and `eslint.config.js` calling `createNodeEslintConfig`
5. [ ] Create `src/main.ts` (starts the flow) and `src/app-boot/{name}-app.ts` (the AppFlow, named for the app), per the `writing-clean-ts` app-boot layer
6. [ ] Add to root `tsconfig.json` references
7. [ ] Add to `compose.yml` with Traefik labels
8. [ ] Run `pnpm install`

### Frontend Package

1. [ ] Create directory: `packages/react-{name}/`
2. [ ] Create `package.json` with:
   - `name`: `@app/react-{name}`
   - `type`: `module`
   - Dependencies: `@app/common`, `@app/react-common` as `workspace:*`
   - Scripts: `build` (`tsc --noEmit && vite build`), `lint:eslint`, `lint-fix:eslint`, `serve` (`vite`), `start`, `test`
3. [ ] Create `tsconfig.json` extending `../../config/typescript/tsconfig.react.base.json`
4. [ ] Create `vite.config.ts` with `vite-tsconfig-paths` plugin, and `eslint.config.js` calling `createReactEslintConfig`
5. [ ] Create `src/` with `main.tsx` entry point
6. [ ] Add to root `tsconfig.json` references
7. [ ] Add to `compose.yml` if needed
8. [ ] Run `pnpm install`

## Best Practices

### Package Naming

- Use `@app/` prefix for internal packages
- Backend: `node-{domain}` (e.g., `node-core`, `node-auth`)
- Frontend: `react-{purpose}` (e.g., `react-admin`, `react-core`)
- Shared: `common`, `node-common`, `react-common`

### Version Management

- Use `catalog:` for shared dependency versions
- Use `workspace:*` for internal packages
- Keep versions consistent across packages

### Build Order

1. Build common libs first
2. Build platform-specific libs second
3. Build apps/services last
4. Use TypeScript project references for correct order

### Development Workflow

- Use Docker Compose for full stack development
- Use volume mounts for hot reload
- Use Traefik for routing between services
- Use health checks for service dependencies

## Common Pitfalls

- **Circular dependencies:** Never let common depend on platform-specific libs
- **Mixed module systems:** All packages should use ES modules (`"type": "module"`)
- **Missing exports:** Always define `exports` field in package.json
- **Incorrect paths:** Ensure tsconfig paths match package.json imports
- **Catalog drift:** Keep pnpm-workspace.yaml catalog versions consistent
- **Missing .js extensions:** ES modules require `.js` in import paths

## Troubleshooting

### `ERR_PNPM_CATALOG_ENTRY_NOT_FOUND_FOR_SPEC`

**Cause:** Package references a `catalog:` dependency that doesn't exist in `pnpm-workspace.yaml`
(pnpm prints `No catalog entry 'x' was found for catalog 'default'`). Not to be confused with
`ERR_PNPM_NO_MATCHING_VERSION`, which means no published version matches a range.

**Fix:** Add the missing package to the catalog (never pin a version in the package instead):
```yaml
# pnpm-workspace.yaml
catalog:
  your-missing-package: ^1.0.0
```

### TypeScript project reference errors

**Cause:** A package is referenced in root `tsconfig.json` but doesn't exist or has errors

**Fix:**
1. Ensure package exists in `packages/` folder
2. Run `pnpm install` to link workspace packages
3. Build dependencies first: `pnpm --filter @app/common build`

### `Cannot find module '#src/...'`

**Cause:** Path alias not configured correctly or package not built

**Fix:**
1. Check `tsconfig.json` has `paths` configured
2. Check `package.json` has `imports` configured
3. Run `pnpm build` in the package
4. Ensure you're using `.js` extension in imports

### ES module errors in built code

**Cause:** Source imports are missing the `.js` extension (TypeScript emits them as written)

**Fix:** Add `.js` to the imports in `src/`. For a React package built without a bundler,
use the bundled fix script:
```bash
node scripts/build-esm-fix.js packages/your-package
```

### Docker volume permission errors

**Cause:** Container runs as different user than host

**Fix:**
1. Add `USER node` to Dockerfile after install
2. Or run: `docker compose exec node-core chown -R node:node /app`

### Tests fail with "Cannot find module"

**Cause:** Vitest config doesn't resolve path aliases

**Fix:** Use `vite-tsconfig-paths` in vitest config:
```javascript
import tsconfigPaths from 'vite-tsconfig-paths'
export default {
  test: { ... },
  plugins: [tsconfigPaths()]
}
```

### Workspace package not found

**Cause:** `workspace:*` dependency not installed

**Fix:**
1. Run `pnpm install` at root
2. Check package name matches exactly in `package.json`
3. Verify package is in `packages/` folder

## Bundled Scripts

This skill includes helper scripts in `scripts/`:

- **`clean.js`** - Removes `dist/` folder
- **`build-esm-fix.js`** - Adds `.js` extensions to ES module imports

Copy these to `resource/script/npm/` in your project and reference in package.json:
```json
{
  "scripts": {
    "build": "node ../../resource/script/npm/clean.js . && tsc -p ./tsconfig.build.json"
  }
}
```

## References

- [Backend Packages](references/backend-packages.md) - Detailed config for common, node-common, microservices
- [Frontend Packages](references/frontend-packages.md) - Detailed config for react-common, web apps, mobile
- [Infrastructure](references/infrastructure.md) - Docker Compose, build scripts, centralized configs

## External Resources

- [pnpm Workspaces](https://pnpm.io/workspaces)
- [TypeScript Project References](https://www.typescriptlang.org/docs/handbook/project-references.html)
- [Docker Compose](https://docs.docker.com/compose/)
- [Traefik](https://doc.traefik.io/traefik/)
