# Core Rules

The framework-independent rules for every TypeScript file this skill writes, moves, or reviews: architecture, naming, file organization, imports, code style, linting policy, refactoring, and the critical rules.

## Contents

- [Architecture Overview](#architecture-overview)
  - [Unified Architecture](#unified-architecture)
  - [Business Layer Placement](#business-layer-placement)
  - [Layer Quick Reference](#layer-quick-reference)
- [Essential Rules](#essential-rules)
  - [CRITICAL: No Comments](#critical-no-comments)
  - [Quick Naming Reference](#quick-naming-reference)
- [Process](#process)
  - [1. Identify What to Create](#1-identify-what-to-create)
  - [2. File Organization](#2-file-organization)
  - [3. Imports: ES Modules & Path Aliases (MANDATORY)](#3-imports-es-modules--path-aliases-mandatory)
  - [4. Code Style](#4-code-style)
  - [5. Linting](#5-linting)
- [Refactoring Existing Code](#refactoring-existing-code)
  - [Preserve Subfolder Groupings](#preserve-subfolder-groupings)
  - [What Goes Where](#what-goes-where)
  - [Refactoring Rules](#refactoring-rules)
- [Common Patterns](#common-patterns)
  - [Services](#services)
  - [Repositories](#repositories)
- [Common Pitfalls](#common-pitfalls)
- [Key Rules](#key-rules)

## Architecture Overview

### Unified Architecture

```
External Interface → Controller → Use Case → Component → Service → Repository → DAL → Entity (Database)
   (Entry Point)        (CL)         └─────────┴────────────┴────────────> (can also call Repository/Component directly)
```

**Controller Layer (CL)** - The unified entry point for ALL external interactions:
- **Backend**: REST API (Express), Event Bus (RxJS), Message Queue (RMQ)
- **Frontend**: Router integration (React Router)

Both translate external parameters into clean business layer calls:
- Backend: HTTP request params → Business logic
- Frontend: URL params/query strings → UI component props

### Business Layer Placement

The dividing line for where domain logic lives is **domain-awareness**: code that imports from `business/model/` (or operates on domain model shapes) is business layer; code that is generic over its inputs is `util/`; code that wraps a third-party library or infrastructure without domain knowledge is `lib/`.

- **Component**: an isolated folder encapsulating one unit of business logic: a public API plus private internals. Usually that means polymorphic dispatch (a selector choosing among strategies at runtime by type/kind/enum), but grouped pluggables, orchestrator + private helpers, and multi-backend contracts are components too
- **Service**: reusable single-responsibility logic called directly by name. May compose other services within the same package/subfolder/domain; cross-domain orchestration goes to a use-case
- **Use Case**: the controller-facing named boundary for a workflow. Usually orchestrates 2+ calls; a thin one-call use-case is acceptable when the boundary itself is the value (a stable domain-named entry point, or hiding which layer implements the operation)
- **Repository / DAL / Entity**: persistence

### Layer Quick Reference

| Layer | Pattern | Location | Notes |
|-------|---------|----------|-------|
| **App Boot** | `AppFlow` + `LifeCycle` classes | `src/app-boot/`, `src/app-boot/life-cycle/` | |
| **Controller** (interface: HTTP, frontend router, queue, event bus, IPC, cron) | Plain object per interface; frontend router controllers are function components | `src/controller/<interface>/` | Non-HTTP interfaces: `router.ts` + one handler file per domain |
| **Component** | Folder (selector singleton + strategy classes) | `src/business/component/` | |
| **Service** | Singleton/Class/Factory | `src/business/service/` | |
| **Repository** | Class | `src/business/repo/` | |
| **Use Case** | Plain object (stateless) | `src/business/use-case/` | |
| **Model** | `type` (class only to construct defaults) | `src/business/model/` | |
| **Enum** | One enum per file | `src/business/enum/` | |
| **DAL** | Class | `src/dal/`, `src/dal/<framework>/` | |
| **Entity** | Class | `src/dal/<framework>/entity/` | |
| **UI Component** | Function Component | `src/ui-component/` | |
| **Util** | Object or Class | `src/util/` | Files suffixed `-util` (exceptions: `constant`, `config`, `logger`, `error`) |
| **Lib** | Class or Singleton | `src/lib/` | Infrastructure wrappers, external-system readers, the app event bus. No suffix (exception: the lib's own `service.ts`) |

## Essential Rules

### CRITICAL: No Comments

**Zero tolerance for comments in code.** This is not optional.

- ❌ No inline comments
- ❌ No block comments
- ❌ No JSDoc comments
- ❌ No explanatory comments
- ✅ Only `// TODO: Remove when [condition]` is temporarily acceptable
- ✅ Tool pragmas (`// eslint-disable-next-line ...`, `// @ts-expect-error`) are tolerated: they are directives to tooling, not prose. Commented-out code is NOT tolerated: delete it (git remembers)
- ✅ One-word group titles inside a router's single `register()` (`// Usage`, `// Settings`) are tolerated: a flat list of registrations has no function to name

If code needs a comment to be understood, the code is wrong. Refactor instead:
- Extract to a well-named function
- Rename variables to be more descriptive
- Simplify the logic

### Quick Naming Reference

| Layer | File | Export | Example |
|-------|------|--------|---------|
| Controller interface (IPC/Bus/MQ/Cron) | `controller/<interface>/router.ts` + `<domain>.ts` | `camelCase` object | `ipcRouter.register()` / `ipcUpdate.check` |
| Service (business layer ONLY) | `<name>-service.ts` | `camelCase` singleton or `PascalCase` class | `calculationService` / `new SecretService()` |
| Repository | `<name>-repo.ts` | `PascalCase` class | `new ProjectRepo()` |
| Use Case | `<name>-use-case.ts` | `camelCase` plain object | `gitUseCase.getCommits()` |
| Model | `<name>-model.ts` | `PascalCase` type | `UsageModel` |
| Enum | `<name>-enum.ts` / `<name>-mapper-enum.ts` | `PascalCase` enum, no `Enum` suffix | `OS`, `SoundNameMapper` |
| Life cycle | `app-boot/life-cycle/<name>-life-cycle.ts` | `PascalCase` class | `SettingsLifeCycle` |
| One-instance class with memory | `<name>-singleton.ts` | `_PascalCase` class + `camelCaseSingleton` accessor | `settingsRepoSingleton()` |
| DAL | `<name>-dal.ts` | `PascalCase` class | `new ProjectDal()` |
| Entity | `<name>-entity.ts` | `PascalCase` class | `ProjectEntity` |
| Util | `<name>-util.ts` | `camelCase` object or `PascalCase` class | `langUtil.detectLang()` / `new FilePathUtil()` |
| Util (well-known) | `constant.ts`, `config.ts`, `logger.ts`, `error.ts` | `camelCase` object | `constant.regex.semverRegex`, `config.logLevel`, `logger().info()` |
| Lib | `<name>.ts` (no suffix) | `PascalCase` class or `camelCase` singleton | `Tray` / `tray` |
| UI Component | `kebab-case.tsx` | `PascalCase` component | `<ProjectList />` |
| **Subfolder** (any layer) | `folder/date.ts` | `FolderPrefixDate` class | `YamlParserDate` / `FormattingStrategyJson` |
| **Subfolder reserved** | `folder/index.ts`, `folder/service.ts` | folder name alone / folder + `Service` | `EntityParserStrategy` / `entityParserStrategyService` |

**`-service` is exclusive to `src/business/service/`.** Every other layer's suffix must match its layer: `-controller` for controller modules, `-dal` for DALs, `-util` for utils (well-known exceptions: `constant`, `config`, `logger`, `error`; plus the `-singleton` wiring suffix), and no suffix for lib files - with one exception: a `lib/<vendor>/service.ts` is that wrapper library's own operational API.

**Private files:** filenames are kebab-case, but a single leading underscore marks a file as private to its folder/component (never imported outside it), analogous to `_prop` on a class/object. This is allowed and is not a naming violation.

## Process

### 1. Identify What to Create

**Backend**: App Boot → Controller → Entity → DAL → Repository → Component/Service/Use Case
**Frontend**: Controller (frontend router) → UI Component

### 2. File Organization

**Strategy Pattern, open** (multiple independently selectable implementations of one interface):
```
src/
├── business/
│   ├── model/
│   │   └── some-strategy.ts                    # Interface + types
│   └── service/
│       └── some-strategy/                      # Subfolder groups all implementations
│           ├── impl-a.ts                       # SomeStrategyImplA class
│           ├── impl-b.ts                       # SomeStrategyImplB class
│           └── __mocks__/some-strategy-mock.ts # Mocks alongside implementations
├── controller/
│   └── preset/                                 # Presets in their own subfolder
│       ├── preset-a.ts
│       └── preset-b.ts
```

**Component** (an encapsulated unit: public API + private internals in ONE folder; usually runtime dispatch by type/kind/enum, but also grouped pluggables or an orchestrator + private helpers):
```
src/
└── business/
    └── component/
        └── some-strategy/                      # ONE folder for the whole unit, in the component layer
            ├── _strategy-a.ts                  # Private - never imported outside the folder
            ├── _strategy-b.ts                  # Private
            ├── service.ts                      # PUBLIC selector singleton - consumers import it directly
            └── index.ts                        # The strategy interface (only when one exists)
```

**Subfolder export naming: the export name is the folder name + file name concatenated.** Skip the `_` privacy prefix and every layer path segment (`src/`, `business/`, `component/`, `service/`...): layer folders group, they never name. The file name's segment lands at the end. Two reserved file names exist so the folder's primary files don't repeat the folder name in the filename:

| File in `entity-parser-strategy/` | Export name |
|---|---|
| `index.ts` | `EntityParserStrategy` - the strategy interface, named exactly after the folder (file contributes nothing) |
| `service.ts` | `entityParserStrategyService` (singleton) or `EntityParserStrategyService` (class) - folder + `Service` |
| `_class.ts` | `EntityParserStrategyClass` - folder + `Class`, underscore skipped |
| `_enum.ts` | `EntityParserStrategyEnum` |

### 3. Imports: ES Modules & Path Aliases (MANDATORY)

**Absolute imports only.** Every internal import uses the `#src/*` alias rooted at `src/`. Relative imports (`./sibling`, `../parent`) are PROHIBITED: they break silently when files move between layers and make deep chains unreadable (`../../../business/service/foo`). Always write `#src/business/service/foo-service` instead.

```typescript
import { ... } from '#src/...'              // Internal project imports (MANDATORY)
import { ... } from '@app/common/...'       // Shared (frontend + backend)
import { ... } from '@app/node-common/...'  // Backend-specific
import { ... } from '@app/react-common/...' // Frontend-specific
```

`#src/*` is for code inside the current project. The `@app/*` aliases are for monorepo shared packages only; replace `@app` with your project name. A single-package project uses `#src` alone.

Every project scaffolded or touched by this skill MUST run ES modules with the `#src` alias configured before any code is written:

**package.json** (ES modules only, never CommonJS; the `imports` field makes `#src/*` resolve at runtime in plain Node):
```json
{
  "type": "module",
  "imports": {
    "#src/*": "./dist/*.js"
  }
}
```

**tsconfig.json** (Node.js backend):
```json
{
  "compilerOptions": {
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "paths": {
      "#src": ["./src"],
      "#src/*": ["./src/*"]
    }
  }
}
```

React/Vite projects use `"module": "ESNext"` with `"moduleResolution": "Bundler"` and the same `paths` entry. With `NodeNext`, internal imports carry explicit `.js` extensions (`#src/business/service/foo-service.js`); bundler resolution omits them.

**Why `#src` and not an `@`-style alias:** the `#` prefix is a Node.js subpath import. It resolves at compile time through tsconfig `paths` and at runtime through the package.json `imports` field, so compiled output runs in plain Node without rewriting import paths. `@`-style aliases exist only in tsconfig and need a bundler plugin or a post-build rewriter to work at runtime.

Where the code runs:
- Node backend, dev: run with `tsx` (it honors tsconfig paths; `#src` needs no extra setup)
- Node backend, build: `tsc`, then `tsc-alias -p tsconfig.build.json` only if you want rewritten relative paths in `dist` (the package.json `imports` mapping to `./dist/*.js` already resolves `#src/*` on its own)
- Bundlers (Vite, webpack): `vite-tsconfig-paths` plugin or an equivalent `resolve.alias` entry mapping `#src` to `./src`

When starting an app from scratch, the initial scaffold MUST also add the lint scripts to `package.json` (`lint`, `lint-fix`) together with the ESLint config, `.prettierrc`, and the lint dev dependencies - see the Linting section below. Set all of this up before writing any feature code.

When joining an existing project without this setup, add it first. Rewrite relative imports to `#src` in every file you touch.

### 4. Code Style

- TypeScript with strict type checking
- **`[lint]` marker**: rules tagged `[lint]` are also enforced by the lint script. Write code that follows them, run `lint-fix` after writing, and manually fix only what the linter reports but cannot auto-fix. `[lint, auto-fix]` means `lint-fix` rewrites the code for you
- Use `type` keyword for imports when possible `[lint, auto-fix]`
- Imports sorted alphabetically with newlines between groups `[lint, auto-fix]`
- **Object params pattern**: Business logic ALWAYS uses object params
- **Destructure on the first line**: `const { a, b } = params` (or `props`) is the first body line; never read `params.x` after it
- **Defaults in the signature**: `resolve(params: { platform?: OS } = { platform: osUtil.resolvePlatform() })`, never `= value` in the destructure and never `{ ...defaults, ...params }` in the body. Same for React `props`
- **Never mutate inputs**: functions do not change their params or anything reachable from them; return new values
- **Exhaustive enum switches**: a switch covering every enum member ends in `default: { throw typeUtil.exhaustiveError('...', value) }` (from `@beecode/msh-util`)
- **One element per file**: One class/object/component per file (local types/interfaces allowed)
- **No ternary operators** `[lint]`: Ternary operators are prohibited. Use `if/else` or extract to a named function.
- **Multi-line code**: Always write multi-line code for accurate code coverage. If statements and arrow functions must span multiple lines with block syntax and explicit `return`. Single-line code hides branch coverage.
- **No for loops** `[lint]`: FOR LOOPS ARE PROHIBITED. Use `.map()` for transformations, `.reduce()` for aggregations.
- **No `let`**: `let` is prohibited - every binding is `const`. Branch-dependent values come from an extracted function that returns per branch.
- **Switch over if/else chains**: Branching on the same value across multiple cases uses a `switch`, never an if/else chain. The switch MUST be encapsulated in a well-named function where each case block returns (and `default` throws) - no `break`, no fallthrough.
- **No comments allowed**: Code must be self-documenting. Use descriptive function and variable names instead. Function names should explain what the function does, variable names should explain what they contain. If you feel the need to add a comment, first check if the code can be refactored to be more readable (extract function, rename variable, simplify logic).
- **TODO comments**: Only `// TODO` comments are allowed as temporary markers. Every TODO MUST include a clear removal condition. Example: `// TODO: Remove after implementing real authentication - currently using mock data`. All TODOs must be removed once the described condition is met.

### 5. Linting

**Linting is NEVER done by the AI agent by hand.** It is always done by the tools: ESLint for code rules, Prettier for formatting, json-sort-cli for JSON key sorting. The checks the scripts cover are DEFINED by the scripts (see the Linting reference, "What The Lint Scripts Check"): verify them only by running `lint` / `lint-fix`, never by reviewing code by eye and never by asking an AI agent or AI reviewer to judge them.

- After writing or changing code, ALWAYS run the project's `lint-fix` script, then `lint` to verify it passes clean
- NEVER hand-edit code to fix something `eslint --fix`, `prettier --write`, or `jsonsort` can fix
- If the project has no lint setup (no `lint` / `lint-fix` scripts or no ESLint config), set it up FIRST via the "Setting Up Linting" procedure in the Linting reference, then run it - existing projects without setup get the same treatment as new ones, and the missing scripts are never replaced by agent review
- When starting an app from scratch, ALWAYS add the lint scripts to its `package.json` (`lint`, `lint-fix`) and generate the ESLint config (Node.js backend or React frontend flavor) from the extracted rule inventory, using the newest tool versions - this is part of the initial scaffold, before any feature code (follow the "Setting Up Linting" procedure in the Linting reference)

## Refactoring Existing Code

When refactoring an existing codebase to follow this architecture, the goal is to move files to their correct layer while **preserving existing folder groupings** that already make sense. Refactoring is about relocating, not restructuring.

### Preserve Subfolder Groupings

When a group of files already lives in a meaningful subfolder (e.g., `formatting-strategy/`, `transporting-strategy/`, `preset/`), move the **entire subfolder** to the target layer - don't flatten it.

**Wrong (flattening loses grouping):**
```
Before: src/formatting-strategy/json.ts
After:  src/business/service/formatting-strategy-json.ts   ← Lost the grouping!
```

**Correct (preserve the folder):**
```
Before: src/formatting-strategy/json.ts
After:  src/business/service/formatting-strategy/json.ts   ← Folder kept as-is
```

### What Goes Where

| Code type | Target location | Notes |
|-----------|----------------|-------|
| Types (models) | `src/business/model/` | `type`, never `interface`; business logic and API clients found in model files move to services |
| Enums | `src/business/enum/` | One enum per `-enum.ts` file; string unions for closed sets become enums |
| Interfaces a class implements | next to the consumer (the `IXxxDal` in the repo file) or the implementations | The only place `interface` and the `I` prefix are used |
| Constants and env values | `src/util/constant.ts`, `src/util/config.ts` | Module-level constants and `process.env` reads anywhere else move here |
| Startup code (runs once on boot) | `src/app-boot/life-cycle/` | Even if it is currently called a use case or service |
| Reader/client for an external system's format | `src/lib/<name>/` | Its own folder: `service.ts` + files by responsibility |
| Strategy implementations (open - callers pick one) | `src/business/service/<strategy-name>/` | Keep subfolder grouping |
| Encapsulated unit (public API + private internals) | `src/business/component/<name>/` | ONE folder for the whole unit; `service.ts` is the public callable API, `index.ts` holds the strategy interface, `_`-prefixed files are private. Exports are named folder + file: `index.ts` exports the folder name (`EntityParserStrategy`), `service.ts` exports folder + `Service` (`entityParserStrategyService`) |
| Preconfigured entry points (presets) | `src/controller/preset/` | Keep subfolder grouping |
| Utility functions | `src/util/` | Project-local generic helpers (not domain-aware) |
| Reusable infrastructure (no business logic, multi-microservice, destined for a shared package) | `src/lib/` | TypeORM DataSource, table mappers, RMQ connections - staging area before extraction to `@app/node-common/` etc. |

### Refactoring Rules

1. **Move folders, don't flatten.** If files are already grouped in a subfolder, move the entire folder into the target layer.
2. **Keep file names as-is** unless they violate naming conventions (e.g., `index.ts` barrels should be removed).
3. **Update imports only** when the task is a move. Don't rename exports, classes, or functions as a side effect of moving files. When a rename *is* the task, propagate it everywhere: file, export, every import, every caller's identifiers, and tests.
4. **Interfaces can stay with implementations.** If an interface file (e.g., `formatting-strategy.ts`) defines the contract for a group of implementations (e.g., `formatting-strategy/json.ts`, `formatting-strategy/simple-string.ts`), it's fine to keep the interface inside the same subfolder rather than moving it to `model/`. The model folder is for standalone types.
5. **Tests and mocks move with their source.** If `json.test.ts` was next to `json.ts`, it stays next to `json.ts` in the new location. Test-only helpers (harnesses, fakes, fixtures) go in a `__tests__/` folder at the same level.
6. **Delete what no longer has a job.** Finished migrations, legacy readers for old formats, and unused placeholder implementations are removed with their tests, not kept "just in case".

## Common Patterns

### Services

```typescript
// Singleton object (stateless, independent methods, no helpers needed)
export const calculationService = {
  calculate(params: { amount: number }): number {
    // implementation
  }
}

// Class (constructor state, `this`-chaining, or `protected _` helpers:
// the class IS the splitting mechanism - class methods average ~10 lines
// because they decompose, singleton methods ~14 because they stay whole)
export class SecretService {
  decrypt(params: { secret: string }): string {
    const { secret } = params

    return this._internalDecrypt(secret)
  }

  protected _internalDecrypt(value: string): string {
    // implementation
  }
}
```

### Repositories

```typescript
// Always use classes
export class ProjectRepo extends CommonRepo<ProjectEntity, ProjectModel> {
  async findMany(params: {
    filter?: object
    pagination?: IPagination
  }): Promise<{ data: ProjectModel[]; pagination: IPaginationResult }> {
    // delegates to DAL
  }
}
```

## Common Pitfalls

- ❌ Using for loops (`for`, `for...of`, `for...in`) → ✅ Use `.map()` or `.reduce()` `[lint]`
- ❌ Using `let` for branch-dependent values (`let dir; if (...) { dir = ... }`) → ✅ `const` + extracted function that returns per branch
- ❌ If/else chains comparing the same value across branches → ✅ `switch` encapsulated in a function (braced cases that return, `default` throws)
- ❌ Using classes for controllers → ✅ Always use singleton objects
- ❌ Using classes (or `singletonPattern`) for use cases → ✅ Always stateless plain objects
- ❌ Keeping a single-call use-case that neither gives the controller a stable domain-named entry point nor hides the implementing layer → ✅ Thin use-cases are fine for those two jobs; anything else is a wrapper, so call the business function directly from the controller
- ❌ **Exporting instantiated class objects** like `export const x = new X()` → ✅ Export the class and use `new ClassName()` at the call site. For singletons, use `singletonPattern(() => new X())` from `@beecode/msh-util/singleton/pattern`
- ❌ Skipping object params in business logic → ✅ ALWAYS use object params
- ❌ Using factory functions for repos → ✅ Use `new ProjectRepo()`
- ❌ Creating arbitrary **top-level** folders outside the allowed set (`src/parsers/`, `src/yaml/`, `src/helpers/`) → ✅ Use `src/business/service/` or `src/business/component/` (subfolders within those layers are encouraged for grouping). Allowed top-level folders: `app-boot/`, `controller/`, `business/`, `dal/`, `ui-component/`, `util/`, `lib/`, `__internal__/`, `asset/`, `__tests__/` - see "File Location" below.
- ❌ Using the `-service` suffix outside `src/business/service/` (e.g., `src/util/lang-service.ts`, `src/lib/tray-service.ts`, `src/dal/history-service.ts`) → ✅ Match the layer's suffix: `-util` in `util/`, `-dal` in `dal/`, `-controller` for controller modules, and no suffix in `lib/`
- ❌ Exporting multiple standalone functions from one file → ✅ Group into singleton service object
- ❌ Module-level private helper functions next to a service export (`const parseUser = ...` at root of file) → ✅ Fold them into the class as `protected _` methods called via `this`
- ❌ Relative imports (`from '../business/service/foo'`, `from './bar'`) → ✅ Absolute `#src` alias imports only: `from '#src/business/service/foo-service'` `[lint]`
- ❌ Creating index.ts barrel files → ✅ Import directly from source files (index.ts is boilerplate)
- ❌ Creating parser modules with multiple exports → ✅ Use parser service template with singleton object
- ❌ `_`-prefixed functions on a plain object → ✅ Convert the object to a class; `_` members become `protected`
- ❌ Reading `params.x` in the body, or `const { x = 1 } = params` → ✅ Destructure on the first line; defaults in the signature
- ❌ Passing services/repos/DALs through constructor params → ✅ `import` them; owned instances are protected field initializers; constructors take config values only
- ❌ `singletonPattern` on a class that holds no memory → ✅ `new X()` at the call site; a singleton is justified only by state a new instance would not have
- ❌ Class in `x.ts` and its singleton in `x-singleton.ts` → ✅ One `x-singleton.ts`: `export class _X`, accessor at the end
- ❌ `export const MAX_ITEMS = 5` or constants at the top of a service → ✅ A key in the single `constant` object in `util/constant.ts`
- ❌ `process.env.X` outside `util/config.ts`, or writing to `config` at runtime → ✅ Read `config.x`; runtime changes live in a util memory module seeded from config
- ❌ `process.platform === 'darwin'` → ✅ `osUtil.resolvePlatform()` returning the `OS` enum
- ❌ Enum inside `model/`, `export enum StatusEnum`, a string union for a closed set → ✅ `business/enum/status-enum.ts` exporting `Status`; keys ≠ values → `...Mapper` in `-mapper-enum.ts`
- ❌ `export interface UsageModel`, `type IUsage` → ✅ `export type UsageModel`; `interface` + `I` only for contracts a class implements
- ❌ Repo that reads/writes files or knows a path → ✅ Repo speaks business words; the DAL owns `fs`, paths, and `read`/`write`
- ❌ Services taking settings as a param they could fetch → ✅ The service calls the repo itself
- ❌ Startup work in a use case, or a life cycle exposing public getters → ✅ Startup work is a life cycle; shared state lives in a lib/business `-singleton`
- ❌ Mutating a param (`items.push(x)`, `trigger.status = ...`) → ✅ Return a new value

## Key Rules

**LINT-FIX FIRST** (CRITICAL):
- Linting is NEVER done by the AI agent by hand - it is always done by the tools: ESLint, Prettier, and json-sort-cli
- NEVER manually fix lint issues if `lint-fix` command can fix them automatically
- NEVER manually format code (quotes, width, sort order) or sort JSON keys - that is Prettier's and jsonsort's job
- ALWAYS run `lint-fix` first before attempting manual fixes
- Only manually fix lint issues if `lint-fix` is unsuccessful in fixing the issue
- NEVER disable or downgrade a rule to make lint pass - fix the code instead
- The `[lint]`-marked rules in this skill are also enforced by the lint script: for loops (`no-loops`), ternaries (`no-ternary`), if-braces (`curly`), import order (`import/order`), relative imports (`no-relative-import-paths`), inline type imports (`consistent-type-imports`), sorted object keys (`sort-keys-fix`), member naming (`@typescript-eslint/naming-convention`), unused vars, no-console, and all Prettier formatting. They stay documented so code is written right the first time; the linter is the safety net. Verdicts on these rules come ONLY from running the scripts - never from the agent reading the code or an AI reviewer judging it
- When a project has no lint setup, scaffold it BEFORE any code task: `lint`/`lint-fix` scripts in `package.json`, ESLint config from the rule inventory, `.prettierrc`, dev dependencies installed. When starting an app from scratch this happens in the initial scaffold, never after the first feature. Never substitute agent review for the missing scripts
- This ensures consistency with project linting rules and saves time

**ABSOLUTE IMPORTS VIA `#src`** (CRITICAL) `[lint]`:
- Every internal import is absolute through the `#src/*` alias: `import { fooService } from '#src/business/service/foo-service'`
- Relative imports are PROHIBITED: no `./sibling`, no `../parent`, ever
- Projects MUST use ES modules (`"type": "module"` in package.json) with `#src` mapped in tsconfig `paths` AND in the package.json `imports` field before any code is written
- `#src` is a Node.js subpath import: compile time resolves through tsconfig `paths`, runtime through package.json `imports`, so built code runs in plain Node; dev uses `tsx`, bundlers use `vite-tsconfig-paths` or `resolve.alias`
- The lint script enforces this (`no-relative-import-paths`); when lint reports a relative import, rewrite it to the `#src` alias
- Full setup snippets: see "3. Imports: ES Modules & Path Aliases" above

**NO FOR LOOPS** (CRITICAL) `[lint]`:
- FOR LOOPS ARE PROHIBITED - use `.map()` or `.reduce()` instead
- No `for`, `for...of`, or `for...in` loops allowed
- Transformations → `.map()`, Aggregations → `.reduce()`, Filtering → `.filter()`
- The lint script enforces this (`no-loops`); when lint reports a loop, rewrite it manually

**NO INLINE ARROW FUNCTIONS** (CRITICAL):
- ALL arrow functions must use block syntax with explicit `return` - no exceptions
- `(x) => x + 1` is WRONG. Always write `(x) => { return x + 1 }`
- This applies everywhere: `.map()`, `.reduce()`, `.filter()`, `.find()`, `Array.from()`, callbacks, event handlers - no inline expressions
- Coverage tools cannot track branches on single-line arrow functions, producing false positives

**NO `let` - SWITCH OVER IF/ELSE CHAINS** (CRITICAL):
- `let` is PROHIBITED - every binding is `const`
- Branch-dependent values are returned from an extracted function, never accumulated into a mutable variable
- Branching on the same value across multiple cases uses a `switch`, never an if/else chain comparing one variable repeatedly
- Every switch MUST be encapsulated in a well-named function: each case uses a `{}` block and `return`s (or `throw`s in `default`) - no `break`, no fallthrough
- `default` MUST handle unsupported cases explicitly (throw or documented fallback) - never silent fallthrough

**NO COMMENTS** (CRITICAL):
- Zero comments allowed in any code - no exceptions
- Code must be self-documenting through clear naming
- If you need a comment, your code needs refactoring
- Only `// TODO: Remove when [condition]` is temporarily acceptable

**BOOLEAN PREFIXES & FALSY DEFAULTS** (CRITICAL):
- Every boolean - variable, property, parameter, return type, INCLUDING `Promise<boolean>` returns - must use the prefix `is*` or `has*` (`isActive`, `hasConflict`, `isEngineInstalled(): Promise<boolean>`). Only these two prefixes are used in practice; do not introduce `can*`, `should*`, `will*`, or `did*`
- A boolean-returning function's name STARTS with the prefix: `isNewerVersion()`, never `resolveIsNewerVersion()` or `checkHasAccess()`
- A two-member yes/no enum (`SUPPORTED`/`UNSUPPORTED`) is a boolean in disguise: replace it with an `is*` flag
- Optional boolean flags default to falsy. If the common case is "on", INVERT THE NAME instead of defaulting to true: `isHistorySkipped?: boolean` checked as `if (!isHistorySkipped)` - never `recordHistory !== false`
- Never write inverted boolean checks: `if (x.flag !== false)` and `if (x.flag === true)` both hide a truthy default - FAIL
- Exception: React props mirroring native HTML attributes (`disabled`, `checked`) keep the DOM name
- Truthy defaults are acceptable only for persisted settings/business constants (pagination `page = 1`, `defaultSettings`)

**NAME WHAT IT IS, NOT WHERE IT IS USED** (CRITICAL):
- Names describe the thing itself, so they survive a second caller: `SoundNameMapper`, not `SessionSoundMapper`; `digitSequenceRegex`, not `versionCompareRegex`; `desktop-app.ts`, not `<project-name>-app-flow.ts`
- Specific enough to be unambiguous: when the app has several kinds of trigger, there is no `TriggerModel`, only `ScheduleTriggerModel` and its siblings
- One meaning per word: when a word is overloaded ("token" = access token vs LLM token), qualify it everywhere (`accessTokenSource`)
- A rename propagates to every file, export, import, caller identifier, and test. Search for both camelCase and kebab-case forms before calling it done

**CONSTANTS, CONFIG, ENUMS** (CRITICAL):
- `util/constant.ts` exports one `constant` object; no `UPPER_CASE` exports, no module-level constants in other files. Keys nest by shared prefix (`constant.scheduleTrigger.run.log.limit`), `min`/`max`/`default` hang under the value they describe, regex keys end with `Regex`, time is milliseconds with `Ms` keys
- `util/config.ts` is the only reader of `process.env` (via `mshEnvResolver`) and is immutable after startup; runtime changes go to a util memory module seeded from config. Values an operator may tune → config; values nobody tunes → constant
- `process.platform` only in `osUtil.resolvePlatform()`, which returns the `OS` enum
- Enums: one per file in `business/enum/`, file `<name>-enum.ts`, export without `Enum` suffix, `UPPER_CASE` keys; keys ≠ values → `XxxMapper` in `<name>-mapper-enum.ts`; closed-set string unions become enums

**NO EXPORTED INSTANCES** (CRITICAL):
- **NEVER export instantiated class objects**: `export const x = new X()` is an anti-pattern
- **Export the CLASS only** and instantiate at the call site with `new ClassName()`
- This applies to ALL class-based layers: Service, Repository, DAL, Entity

**Why this matters:** Exporting instances hides dependencies, makes testing harder, and creates implicit singletons.

```typescript
// ❌ NEVER DO THIS
export const yamlParserContract = new YamlParserContract()
export const secretService = new SecretService()
const service = new SecretService()
export { service as secretService }

// ✅ CORRECT - Export class, instantiate at call site
export class YamlParserContract { ... }
export class SecretService { ... }

// Usage at call site:
const result = new YamlParserContract().parse(content)
const decrypted = new SecretService().decryptSecret(secret)
```

**If you need a singleton** (only when the instance holds memory a fresh instance would not have: cached data, subscriptions, a window handle, loaded settings), put the class and the `singletonPattern` accessor in ONE `<name>-singleton.ts` file, with the class prefixed `_` so nobody instantiates it directly:

```typescript
// src/business/repo/settings-repo-singleton.ts
import { singletonPattern } from '@beecode/msh-util/singleton/pattern'

export class _SettingsRepo { ... }

export const settingsRepoSingleton = singletonPattern(() => {
  return new _SettingsRepo()
})

// Usage - always call the accessor
settingsRepoSingleton().fetch()
```

A class with no such memory is not a singleton: remove the pattern and use `new X()`. When unsure whether it holds memory, ask.

**Controllers**:
- Backend: Express/RxJS/RMQ/IPC → Plain objects; an interface folder has one `router.ts` with a single `register()` (the `channel → handler` lines stay there, the callbacks live in `<domain>.ts` files)
- Every payload is validated with zod through the validation util, on every interface (HTTP, IPC, bus, queue)
- Frontend: router controllers → function components that translate URL → props
- **Single business call rule**: Controller handlers must call ONLY ONE function from the business layer (use-case, service, repo, or component). If multiple calls are needed, create a new service/use-case function that orchestrates them.
- **No dead-weight wrapper use-cases**: A use-case usually orchestrates two or more steps. A thin one-call use-case is acceptable only when it (a) gives the controller a stable, domain-named entry point, or (b) hides which layer implements the operation. Anything else is a wrapper the controller does not need, since controllers may call any business layer directly. The body's step names carry the detail.
- **Light handlers**: Controllers are for: (1) validate request data, (2) pass parameters to business layer, (3) format response. NO business logic in controllers.

**Business Logic**:
- Use Cases: Always stateless plain objects, never classes, never `singletonPattern` (prevents nesting; never call another use-case). Startup work is an app-boot life cycle, not a use case
- Components: encapsulated units (a folder with a public API and private internals: dispatch families, grouped pluggables, orchestrators, multi-backend contracts)
- Services: object for stateless simple logic, class for state/`this`-chaining/`protected _` helpers (the class IS the splitting mechanism), factory when it builds a value
- Repositories: Always classes. Business words only (`create`/`edit`/`remove`/`save`/`fetch`/`init`); they know nothing about files, paths, or storage frameworks. One DAL per repo; the `IXxxDal` interface is declared in the repo file
- DALs: own the storage framework (`fs`, paths, memory, ORM), speak `read`/`write`, hold no business logic; shared mechanics live in `common-file-dal.ts` / `common-memory-dal.ts`
- **No constructor dependency injection**: modules `import` their collaborators; owned instances are protected field initializers; constructors take config values only
- **The singleton pattern is in "NO EXPORTED INSTANCES" above**

**Object Params Pattern**:
- Business logic layers → ALWAYS use object params (even 1 parameter); a callback goes inside the params object under the key `callback`
- Every layer → destructure `params` / `props` on the first body line (never `params.x` afterwards); defaults go in the signature (`params: {...} = {...}`); never mutate what you received
- Protected `_` helper methods on a service class → Internal implementation detail: a single positional domain value is acceptable (e.g. `_decryptData = (data?: string) => { ... }`, as in the class service template); multiple inputs still use object params
- Utility and lib layers → Positional is fine for one or two params; use the object when names are not obvious from the call. A callback may sit as the second positional parameter next to a params object (e.g. rmq `route(filter, callback)`)

**One Element Per File**:
- One class/object/component per file
- Local types/interfaces allowed if not shared

**CRITICAL: Module Export Pattern**:
- **NEVER export multiple standalone functions** from a single file
- **NEVER export a bare standalone function - even when it is the file's only export**. A single function is still wrapped in a singleton service object (e.g. `export const dateParserService = { parse(params) {...} }`, not `export function parseDate(...)`). The only function-shaped exports allowed are React/UI components.
- **A file exports exactly ONE element** (a class or a plain object) and **never declares module-level (root-of-file) helper functions or constants alongside it**. Any helper becomes a `protected` method prefixed with a single underscore (`protected _parseUser(...)`) accessed via `this`, which means the module is a class. A plain object never has `_` members: an object literal cannot hide them, so an object with `_` functions is converted to a class. Constants go to `util/constant.ts`
- **The presence of helpers signals the class pattern** - methods calling each other via `this` (the class-vs-object rule)
- **ALWAYS group related functions** into a singleton service object
- **ALWAYS use object params** for all methods in service objects
- **NEVER use barrel exports** (re-exporting from index.ts) for business logic

**CRITICAL: No index.ts Barrel Files**:
- `index.ts` files that only re-export from other files are boilerplate and should NOT be created
- Import directly from source files instead (e.g., `from '#src/business/service/my-service.js'`)
- This applies to ALL layers - no index.ts files for services, components, repositories, etc.
- Only exception: index.ts may be used for npm package entry points (package.json "main" field)

**Example - WRONG (multiple exports):**
```typescript
// ❌ WRONG - Multiple standalone exports
export function parseRegex(value: unknown): RegExp | null { ... }
export function isRegexString(value: unknown): value is string { ... }
export function parseDate(value: unknown): Date | null { ... }
```

**Example - CORRECT (singleton service):**
```typescript
// ✅ CORRECT - Singleton service object
export const regexParserService = {
  parse(params: { value: unknown }): RegExp | null { ... },
  isString(params: { value: unknown }): params is string { ... },
}
```

**CRITICAL: File Location**:
- **The dividing line is domain-awareness**: logic that imports from `business/model/` or operates on domain shapes is business layer; generic helpers go to `util/`; non-domain third-party wrappers go to `lib/`
- **Business logic MUST be in `src/business/`** (service/, component/, use-case/, repo/, hook/ for shared React hooks); **models** in `business/model/` and **enums** in `business/enum/`
- **A `-util` file must be generic**: domain logic in a util moves to `business/service/`; knowledge of an external system's format (e.g. parsing another tool's transcripts) moves to `lib/<name>/`
- **Data access MUST be in `src/dal/`** (framework DALs in `src/dal/<framework>/`)
- **Controllers MUST be in `src/controller/<interface>/`**
- **Utility functions MAY be in `src/util/`** (project-local pure helpers; prefer services for complex logic)
- **Reusable infrastructure MAY be in `src/lib/`** - code with **no business logic** that is **reusable across multiple microservices**, kept as a staging area **until it is extracted** into a shared common package (`@app/node-common/`, `@app/common/`) or an external library. Examples: TypeORM `DataSource` singleton, table-name mapper, RMQ connection singletons. A `lib/<vendor>/service.ts` file is that wrapper library's own operational API - a legitimate exception to the no-`-service`-suffix rule
- **Package-private wiring in shared libs MAY be in `src/__internal__/`** (mirrors `business/`, `lib/`, `util/`, `dal/`); **frontend static assets** in `src/asset/`; **tests** in `__tests__/` subfolders colocated with their layer
- **NEVER create arbitrary top-level folders** outside the allowed set. Allowed top-level folders under `src/` are: `app-boot/`, `controller/`, `business/`, `dal/`, `ui-component/`, `util/`, `lib/`, `__internal__/`, `asset/`, `__tests__/` (so no `src/yaml/`, `src/parsers/`, `src/helpers/`).
- **Subfolders within layers are encouraged** for grouping related implementations (e.g., `src/business/service/formatting-strategy/json.ts`)

