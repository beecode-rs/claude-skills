---
name: writing-clean-ts
description: >-
  Expert in TypeScript codebase patterns for backend and frontend: services,
  repositories, DALs, entities, models, enums, controllers, handlers, use
  cases, app boot, React components, and UI screens. Make sure to use this
  skill whenever the user mentions TypeScript, Node.js, Express, TypeORM,
  Electron, React, React Router, React Native, Expo, creating an API endpoint,
  building a feature, CRUD operations, or codebase architecture - even if they
  don't say "clean architecture". Also use it to refactor or clean up
  existing TypeScript (moving code between layers, renaming, splitting big
  files, constants/config/env, enums, singletons, reviewing against these
  conventions), for linting setup (ESLint, Prettier, json-sort-cli, lint
  scripts), and for ES module / import path setup (#src alias, absolute
  imports, tsconfig paths, "type": "module"). For tests, use the
  contract-testing-ts skill.
allowed-tools: Read, Write, Edit, Grep, Glob, Bash
---

# TypeScript Expert

Write, refactor, and review TypeScript so it follows one layered architecture (Controller → Use Case → Component → Service → Repository → DAL → Entity) and one set of naming, style, and linting conventions, and so new code matches the existing style and integrates seamlessly.

Use it when creating or moving services, repositories, DALs, entities, models, enums, controllers, handlers, use cases, app-boot code, or UI components; when refactoring or reviewing TypeScript against these conventions; and when setting up linting or ES modules with the `#src` alias.

## Core Workflow

1. **Detect the stack**: read the target package's `package.json` (in a monorepo, the package being worked on, not the root) and check for the files in the framework table below.
2. **Load references**: read `references/core-rules.md`, then only the rows below that match the stack and the task. Read each loaded file start to finish; never set range limits.
3. **Check the project setup** before writing feature code: ES modules with the `#src` alias and the `lint` / `lint-fix` scripts with their configs. If any of it is missing, set it up first (`references/linting.md`) - no exception for small, new, or existing projects.
4. **Build in layer order**: backend App Boot → Controller → Entity → DAL → Repository → Component/Service/Use Case; frontend Controller → UI Component. Start each new file from its starter template.
5. **Lint with the tools**: run `lint-fix`, then `lint`. What the scripts cover is judged only by their output - never by reviewing code by eye or by an AI agent/reviewer. Fix by hand only what the tools report but cannot fix. Never disable a rule to pass.
6. **Tests** belong to the `contract-testing-ts` skill.

## Load Only What You Need

Never load all reference files up front. Always read `references/core-rules.md` first; after that, read ONLY the files whose condition matches. Do not read the others.

### Frameworks

A project can match several rows (for example Express + TypeORM + Zod). Read every matching row and nothing else.

| Detected when... | Read |
|---|---|
| `expo` or `expo-router` in dependencies, `"main": "expo-router/entry"`, or `app.json` / `app.config.ts` with an `expo` key. Read it BEFORE writing, moving, or reviewing code | `references/frameworks/expo.md` |
| `react` in dependencies (includes React Native, Expo, and Electron renderers) | `references/frameworks/react.md` |
| `express` in dependencies | `references/frameworks/express.md` |
| `typeorm` in dependencies | `references/frameworks/typeorm.md` |
| `amqplib` in dependencies, or `src/controller/rmq/` exists | `references/frameworks/rmq.md` |
| `rxjs` in dependencies used for an event bus, or `src/controller/rxjs-bus/` exists | `references/frameworks/rxjs.md` |
| `electron` in dependencies, or `src/main/` + `src/renderer/` exist | `references/frameworks/electron.md` |
| `zod` in dependencies, or the task writes or reviews a controller handler, schema, or payload validation | `references/frameworks/zod.md` |

### Topics

| Task involves... | Read |
|---|---|
| Any code task (always, first) | `references/core-rules.md` |
| Creating, naming, or renaming a file, export, enum, function, variable, or boolean | `references/style/naming-convention.md` |
| Writing or editing function bodies (ternaries, loops, `let`, switches, arrows, mutation, defaults) | `references/style/code-style.md` |
| Error handling, exhaustive switches, or a function whose name must cover its behavior | `references/style/function-guidelines.md` |
| A function over ~30 lines, or splitting a function or file | `references/style/function-size.md` |
| Writing or changing a function signature (params, defaults, callbacks) | `references/style/object-params-pattern.md` |
| Date/time fields (`*At` fields, `Date` values, timestamp columns) | `references/style/timestamp-handling.md` |
| Creating a file or folder, moving code, or deciding which layer code belongs in | `references/architecture/file-organization-pattern.md` |
| Choosing class vs plain object vs singleton for a module | `references/architecture/class-vs-object.md` |
| Constants, env/config values, runtime state, or platform checks | `references/architecture/constant-config-pattern.md` |
| Model types, or converting between entities and models | `references/architecture/model-vs-entity.md` |
| Missing values across layers (`null`, `undefined`, optional fields) | `references/architecture/null-undefined-pattern.md` |
| Startup or shutdown code (`src/app-boot/`, life cycles) | `references/architecture/app-boot-layer.md` |
| Any controller (`src/controller/`) | `references/architecture/controller-layer.md` |
| A unit in `src/business/component/` (selector + strategies, public API + private helpers) | `references/architecture/component-layer.md` |
| A service in `src/business/service/` | `references/architecture/service-layer.md` |
| A use case in `src/business/use-case/` | `references/architecture/use-case-layer.md` |
| A repository in `src/business/repo/` | `references/architecture/repository-layer.md` |
| A DAL in `src/dal/` (database, file, memory, or API storage) | `references/architecture/dal-layer.md` |
| An entity in `src/dal/*/entity/` | `references/architecture/entity-layer.md` |
| A UI component in `src/ui-component/` | `references/architecture/ui-component-layer.md` |
| Designing or reviewing REST endpoint URLs | `references/architecture/rest-api-url-conventions.md` |
| Setting up linting (new project, or a project with no `lint` / `lint-fix` scripts), editing ESLint/Prettier/jsonsort config, checking what the lint scripts verify, or understanding a lint rule | `references/linting.md` |

### Commands

| User says... | Read |
|---|---|
| "cleanup this code", "review this file", "check code quality", "validate code structure" | `references/commands/cleanup.md`, plus the framework and topic rows that match the code under review |
| "review the architecture", "clean-arch", "check structure", "is this in the right layer" | `references/commands/clean-arch.md`, plus `references/architecture/` files `file-organization-pattern.md`, `class-vs-object.md`, `model-vs-entity.md`, `constant-config-pattern.md`, `null-undefined-pattern.md`, `rest-api-url-conventions.md`, the layer files for the layers under review, `references/frameworks/express.md` and `references/frameworks/zod.md` when controllers are in scope, and `references/frameworks/expo.md` in an Expo project. Do not load `references/style/` |
| "review the style", "clean-style", "check readability", or style-only feedback | `references/commands/clean-style.md`, plus every file in `references/style/`, and `references/frameworks/expo.md` in an Expo project. Do not load `references/architecture/` |

### Starter Templates

Copy-paste scaffolds. Open only the one for the file being created.

| Creating... | Template |
|---|---|
| A service with independent methods (singleton) | `templates/service-template.ts` |
| A service with interdependent methods (class) | `templates/service-class-template.ts` |
| A parser service (regex, date, etc.) | `templates/parser-service-template.ts` |
| A repository class | `templates/repository-template.ts` |
| A TypeORM DAL class | `templates/dal-template.ts` |
| A TypeORM entity | `templates/entity-template.ts` |
| A use case orchestrating services | `templates/use-case-template.ts` |
| An Express GET list endpoint | `templates/express-handler-template.ts` |
| An Express POST create endpoint | `templates/express-handler-post-template.ts` |
| A React Router controller (not in Expo) | `templates/react-controller-template.tsx` |
| A React UI component | `templates/react-component-template.tsx` |
| Model type definitions | `templates/model-template.ts` |
| An enum (or `-mapper-enum` when keys differ from values) | `templates/enum-template.ts` |
| A strategy/pluggable class inside a component or service subfolder | `templates/subfolder-component-template.ts` |

## License

This skill is licensed under the terms in [LICENSE.txt](LICENSE.txt).
