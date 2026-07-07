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
- **test-typescript skill:** Testing patterns and coverage

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
    "lint": "prettier . && eslint . && pnpm -r lint",
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
    "#src/*": "./dist/*.js"
  }
}
```

**Usage in code:**
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

# 3. Resolve aliases (tsc-alias)
tsc-alias -p ./tsconfig.build.json
```

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
   - `exports` and `imports` for `#src/*`
   - Dependencies: `@app/common`, `@app/node-common` as `workspace:*`
   - Build scripts
3. [ ] Create `tsconfig.json` extending `../../config/typescript/tsconfig.base.json`
4. [ ] Create `tsconfig.build.json` for production builds
5. [ ] Create `src/` with `app/server-app.ts` entry point
6. [ ] Add to root `tsconfig.json` references
7. [ ] Add to `compose.yml` with Traefik labels
8. [ ] Run `pnpm install`

### Frontend Package

1. [ ] Create directory: `packages/react-{name}/`
2. [ ] Create `package.json` with:
   - `name`: `@app/react-{name}`
   - `type`: `module`
   - Dependencies: `@app/common`, `@app/react-common` as `workspace:*`
   - Vite config for dev server
3. [ ] Create `tsconfig.json` extending `../../config/typescript/tsconfig.react.base.json`
4. [ ] Create `vite.config.ts` with `vite-tsconfig-paths` plugin
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

### `ERR_PNPM_NO_MATCHING_VERSION`

**Cause:** Package references a `catalog:` dependency that doesn't exist in `pnpm-workspace.yaml`

**Fix:** Add the missing package to the catalog, or use explicit version:
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

**Cause:** TypeScript emits imports without `.js` extensions

**Fix:** Run `tsc-alias` after build, or use the bundled fix script:
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
    "build": "node ../../resource/script/npm/clean.js . && tsc -p ./tsconfig.build.json && tsc-alias -p ./tsconfig.build.json"
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
