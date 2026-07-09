---
name: writing-clean-ts
description: Expert in TypeScript codebase patterns for backend and frontend. Helps with creating services, repositories, DALs, entities, controllers, handlers, use cases, React components, and UI screens. Make sure to use this skill whenever the user mentions TypeScript, Node.js, Express, TypeORM, React, React Router, React Native, Expo, creating an API endpoint, building a feature, implementing CRUD operations, or asks about codebase architecture - even if they don't explicitly say "clean architecture" or mention specific layers. For testing, use the test-typescript skill.
allowed-tools: Read, Write, Edit, Grep, Glob, Bash
---

# TypeScript Expert

## Purpose

Provide expert guidance on writing code that follows the Node.js codebase conventions, patterns, and architecture. Generate code that matches the existing style and integrates seamlessly.

## When to Use

- Creating new services, repositories, DALs, entities, controllers, handlers, or use cases
- Creating new frontend screens or UI components (React/React Native/Expo)
- Understanding the layered architecture pattern
- Following naming conventions and file organization
- Implementing TypeORM entities with proper relations
- Writing Express handlers with Zod validation
- Orchestrating business logic with use cases

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

### Layer Quick Reference

| Layer | Pattern | Location | Details |
|-------|---------|----------|---------|
| **App Boot** | Singleton | `src/app-boot/` | [app-boot-layer.md](layer/app-boot-layer.md) |
| **Controller** (Express) | Singleton | `src/controller/express/` | [controller-layer.md](layer/controller-layer.md) |
| **Controller** (React Router) | Function Component | `src/controller/react-router/` | [controller-react-router.md](layer/controller-react-router.md) |
| **Component** | Singleton | `src/business/component/` | [component-layer.md](layer/component-layer.md) |
| **Service** | Singleton/Class | `src/business/service/` | [service-layer.md](layer/service-layer.md) |
| **Repository** | Class | `src/business/repo/` | [repository-layer.md](layer/repository-layer.md) |
| **Use Case** | Singleton | `src/business/use-case/` | [use-case-layer.md](layer/use-case-layer.md) |
| **DAL** | Class | `src/dal/typeorm/` | [dal-layer.md](layer/dal-layer.md) |
| **Entity** | Class | `src/dal/typeorm/entity/` | [entity-layer.md](layer/entity-layer.md) |
| **UI Component** | Function Component | `src/ui-component/` | [ui-component-layer.md](layer/ui-component-layer.md) |

## Commands

- **Cleanup**: [commands/cleanup.md](commands/cleanup.md) - Systematic code review command to validate TypeScript code against clean architecture rules. Use when user says "cleanup this code", "review this file", "check code quality", or "validate code structure".

## Essential Patterns

**MANDATORY - READ THESE PATTERNS:**

- **Naming Conventions**: [patterns/naming-convention.md](patterns/naming-convention.md) - File naming, exports, and conventions for all layers
- **Class vs Object**: [patterns/class-vs-object.md](patterns/class-vs-object.md) - Decision guide for choosing classes vs singleton objects
- **Model vs Entity**: [patterns/model-vs-entity.md](patterns/model-vs-entity.md) - When to use Models vs Entities, transformation patterns
- **Object Params**: [patterns/object-params-pattern.md](patterns/object-params-pattern.md) - Function parameter patterns (business logic ALWAYS uses object params)
- **Null vs Undefined**: [patterns/null-undefined-pattern.md](patterns/null-undefined-pattern.md) - `undefined` in business logic, `null` only in DAL/Entity layer
- **Function Guidelines**: [patterns/function-guidelines.md](patterns/function-guidelines.md) - Error handling, naming, exhaustive checks
- **Timestamp Handling**: [patterns/timestamp-handling.md](patterns/timestamp-handling.md) - TypeORM setup and field naming
- **REST API URLs**: [patterns/rest-api-url-conventions.md](patterns/rest-api-url-conventions.md) - REST endpoint URL naming and structure (dashed-case, plural collections)
- **Express Handlers**: [patterns/express-handler-pattern.md](patterns/express-handler-pattern.md) - REST API endpoint handler implementation
- **Validation (Zod)**: [patterns/validation-pattern.md](patterns/validation-pattern.md) - Schema definitions, type inference, error handling
- **Code Style**: [patterns/code-style.md](patterns/code-style.md) - Multi-line formatting for accurate code coverage
- **File Organization**: [patterns/file-organization-pattern.md](patterns/file-organization-pattern.md) - Where to place files, module structure, preventing misplaced code

### Starter Templates

Copy-paste ready templates for quickly scaffolding new layers:

| Template | Location | Use When |
|----------|----------|----------|
| Service (singleton) | [templates/service-template.ts](templates/service-template.ts) | Creating a service with independent methods |
| Service (class) | [templates/service-class-template.ts](templates/service-class-template.ts) | Creating a service with interdependent methods |
| Parser Service | [templates/parser-service-template.ts](templates/parser-service-template.ts) | Creating a parser service (regex, date, etc.) |
| Repository | [templates/repository-template.ts](templates/repository-template.ts) | Creating a repository class |
| DAL | [templates/dal-template.ts](templates/dal-template.ts) | Creating a TypeORM DAL class |
| Entity | [templates/entity-template.ts](templates/entity-template.ts) | Creating a TypeORM entity |
| Use Case | [templates/use-case-template.ts](templates/use-case-template.ts) | Creating a use case for orchestrating services |
| Express Handler (GET) | [templates/express-handler-template.ts](templates/express-handler-template.ts) | Creating a GET list endpoint |
| Express Handler (POST) | [templates/express-handler-post-template.ts](templates/express-handler-post-template.ts) | Creating a POST create endpoint |
| React Controller | [templates/react-controller-template.tsx](templates/react-controller-template.tsx) | Creating a React Router controller |
| React Component | [templates/react-component-template.tsx](templates/react-component-template.tsx) | Creating a UI component |
| Model | [templates/model-template.ts](templates/model-template.ts) | Creating model type definitions |

### CRITICAL: No Comments

**Zero tolerance for comments in code.** This is not optional.

- ❌ No inline comments
- ❌ No block comments
- ❌ No JSDoc comments
- ❌ No explanatory comments
- ✅ Only `// TODO: Remove when [condition]` is temporarily acceptable

If code needs a comment to be understood, the code is wrong. Refactor instead:
- Extract to a well-named function
- Rename variables to be more descriptive
- Simplify the logic

### Quick Naming Reference

| Layer | File | Export | Example |
|-------|------|--------|---------|
| Controller (Express) | `kebab-case.ts` | `camelCase` singleton | `getProjectsAll.handler` |
| Controller (React Router) | `kebab-case.tsx` | `PascalCase` component | `<ProjectListController />` |
| Service | `kebab-case.ts` | `camelCase` singleton or `PascalCase` class | `calculationService` / `new SecretService()` |
| Repository | `kebab-case.ts` | `PascalCase` class | `new ProjectRepo()` |
| Use Case | `kebab-case.ts` | `camelCase` singleton | `gitUseCase.getCommits()` |
| DAL | `kebab-case.ts` | `PascalCase` class | `new ProjectDal()` |
| Entity | `kebab-case.ts` | `PascalCase` class | `ProjectEntity` |
| UI Component | `kebab-case.tsx` | `PascalCase` component | `<ProjectList />` |
| **Subfolder** (any layer) | `folder/date.ts` | `FolderPrefixDate` class | `YamlParserDate` / `FormattingStrategyJson` |

**Full details in [patterns/naming-convention.md](patterns/naming-convention.md)**

## Process

### 1. Identify What to Create

**Backend**: App Boot → Controller → Entity → DAL → Repository → Component/Service/Use Case
**Frontend**: Controller (React Router) → UI Component

### 2. Read Layer Documentation

**MANDATORY**: Read the complete layer documentation file from start to finish:
- Never set range limits when reading layer files
- Each layer file contains critical patterns and rules
- Follow the "MANDATORY - READ ENTIRE FILE" instructions

### 3. File Organization

**Backend Feature** (`featureName`):
```
src/
├── controller/express/feature-name.ts          # All endpoints in one file
├── controller/preset/feature-name-preset.ts    # Preconfigured entry points (if applicable)
├── dal/typeorm/
│   ├── entity/feature-name-entity.ts
│   └── feature-name-dal.ts
└── business/
    ├── repo/feature-name-repo.ts
    ├── service/feature-name-service.ts          # or component/ for complex logic
    ├── service/feature-name/                    # Subfolder when multiple related implementations
    │   ├── impl-a.ts
    │   └── impl-b.ts
    ├── use-case/feature-name-use-case.ts
    └── model/feature-name-model.ts
```

**Strategy Pattern** (multiple implementations of one interface):
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

**Frontend Feature** (React Router):
```
src/
├── controller/react-router/feature-name/
│   ├── list.tsx                                 # /feature-name
│   ├── detail.tsx                               # /feature-name/:id
│   ├── create.tsx                               # /feature-name/create
│   └── edit.tsx                                 # /feature-name/:id/edit
└── ui-component/feature-name/
    ├── list.tsx
    ├── detail.tsx
    ├── create-form.tsx
    └── edit-form.tsx
```

### 4. Path Aliases

```typescript
import { ... } from '#src/...'              // Internal project imports
import { ... } from '@app/common/...'       // Shared (frontend + backend)
import { ... } from '@app/node-common/...'  // Backend-specific
import { ... } from '@app/react-common/...' // Frontend-specific
```

Replace `@app` with your project name.

### 5. Code Style

- TypeScript with strict type checking
- Use `type` keyword for imports when possible
- Imports sorted alphabetically with newlines between groups
- **Object params pattern**: Business logic ALWAYS uses object params (see [patterns/object-params-pattern.md](patterns/object-params-pattern.md))
- **One element per file**: One class/object/component per file (local types/interfaces allowed)
- **No ternary operators**: Ternary operators are prohibited. Use `if/else` or extract to a named function. See [patterns/code-style.md](patterns/code-style.md) for alternatives and scoping rules
- **Multi-line code**: Always write multi-line code for accurate code coverage. If statements and arrow functions must span multiple lines with block syntax and explicit `return`. Single-line code hides branch coverage. See [patterns/code-style.md](patterns/code-style.md)
- **No for loops**: FOR LOOPS ARE PROHIBITED. Use `.map()` for transformations, `.reduce()` for aggregations. See [patterns/code-style.md](patterns/code-style.md) for detailed examples.
- **No comments allowed**: Code must be self-documenting. Use descriptive function and variable names instead. Function names should explain what the function does, variable names should explain what they contain. If you feel the need to add a comment, first check if the code can be refactored to be more readable (extract function, rename variable, simplify logic).
- **TODO comments**: Only `// TODO` comments are allowed as temporary markers. Every TODO MUST include a clear removal condition. Example: `// TODO: Remove after implementing real authentication - currently using mock data`. All TODOs must be removed once the described condition is met.

## Refactoring Existing Code

When refactoring an existing codebase to follow this architecture, the goal is to move files to their correct layer while **preserving existing folder groupings** that already make sense. Refactoring is about relocating, not restructuring.

### Preserve Subfolder Groupings

When a group of files already lives in a meaningful subfolder (e.g., `formatting-strategy/`, `transporting-strategy/`, `preset/`), move the **entire subfolder** to the target layer — don't flatten it.

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
| Interfaces, types, enums | `src/business/model/` | If standalone, or keep in subfolder if tightly coupled to implementations |
| Strategy implementations | `src/business/service/<strategy-name>/` | Keep subfolder grouping |
| Preconfigured entry points (presets) | `src/controller/preset/` | Keep subfolder grouping |
| Utility functions | `src/util/` | Project-local stateless helpers |
| Reusable infrastructure (no business logic, multi-microservice, destined for a shared package) | `src/lib/` | TypeORM DataSource, table mappers, RMQ connections — staging area before extraction to `@app/node-common/` etc. |

### Refactoring Rules

1. **Move folders, don't flatten.** If files are already grouped in a subfolder, move the entire folder into the target layer.
2. **Keep file names as-is** unless they violate naming conventions (e.g., `index.ts` barrels should be removed).
3. **Update imports only.** Don't rename exports, classes, or functions during a refactor.
4. **Interfaces can stay with implementations.** If an interface file (e.g., `formatting-strategy.ts`) defines the contract for a group of implementations (e.g., `formatting-strategy/json.ts`, `formatting-strategy/simple-string.ts`), it's fine to keep the interface inside the same subfolder rather than moving it to `model/`. The model folder is for standalone types.
5. **Tests and mocks move with their source.** If `json.test.ts` was next to `json.ts`, it stays next to `json.ts` in the new location.

## Common Patterns

### Controllers (Backend)

```typescript
// Express Controller - Always singleton
export const getProjectsAll = {
  handler: new HttpUtil().expressEndPoint(async (req) => {
    const { filter, pagination } = validationUtil.parse(
      new HttpUtil().expressQueryToJsonParser(req.query),
      reqQueryParamsSchema
    )
    return await new ProjectRepo().findMany({ filter, pagination })
  }),
  schema: { /* Swagger schema */ }
}
```

### Controllers (Frontend - React Router)

```typescript
// React Router Controller - Extracts routing params
export const ProjectDetailController = (): React.ReactElement => {
  const { projectId } = useParams<{ projectId: string }>()
  const { ownerId } = useContext(AuthContext)

  if (!projectId || !ownerId) return <ErrorView />

  return (
    <Box sx={{ p: 1 }}>
      <ProjectDetail projectId={projectId} ownerId={ownerId} />
    </Box>
  )
}
```

### Services

```typescript
// Singleton object (preferred - independent methods)
export const calculationService = {
  calculate(params: { amount: number }): number {
    // implementation
  }
}

// Class (when methods call each other via `this`)
export class SecretService {
  decrypt(params: { secret: string }): string {
    return this._internalDecrypt(params.secret)
  }

  private _internalDecrypt(value: string): string {
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

### Backend
- ❌ Using for loops (`for`, `for...of`, `for...in`) → ✅ Use `.map()` or `.reduce()`
- ❌ Using classes for controllers → ✅ Always use singleton objects
- ❌ Using classes for use cases → ✅ Always use singleton objects
- ❌ **Exporting instantiated class objects** like `export const x = new X()` → ✅ Export the class and use `new ClassName()` at the call site. For singletons, use `singletonPattern(() => new X())` from `@beecode/msh-util/singleton/pattern`
- ❌ Skipping object params in business logic → ✅ ALWAYS use object params
- ❌ Using factory functions for repos → ✅ Use `new ProjectRepo()`
- ❌ Creating arbitrary **top-level** folders outside the allowed set (`src/parsers/`, `src/yaml/`, `src/helpers/`) → ✅ Use `src/business/service/` or `src/business/component/` (subfolders within those layers are encouraged for grouping). Note: `src/lib/` **is** an allowed top-level folder — see "File Location" below.
- ❌ Exporting multiple standalone functions from one file → ✅ Group into singleton service object
- ❌ Creating index.ts barrel files → ✅ Import directly from source files (index.ts is boilerplate)
- ❌ Creating parser modules with multiple exports → ✅ Use parser service template with singleton object

### Frontend
- ❌ Using routing hooks in UI components → ✅ Only controllers use routing hooks
- ❌ Making controllers reusable → ✅ One controller per route
- ❌ Not extracting URL params in controller → ✅ Controllers translate router → props
- ❌ Business logic in UI components → ✅ Use services/repositories

## Key Rules

**LINT-FIX FIRST** (CRITICAL):
- NEVER manually fix lint issues if `lint-fix` command can fix them automatically
- ALWAYS run `lint-fix` first before attempting manual fixes
- Only manually fix lint issues if `lint-fix` is unsuccessful in fixing the issue
- This ensures consistency with project linting rules and saves time

**NO FOR LOOPS** (CRITICAL):
- FOR LOOPS ARE PROHIBITED - use `.map()` or `.reduce()` instead
- No `for`, `for...of`, or `for...in` loops allowed
- Transformations → `.map()`, Aggregations → `.reduce()`, Filtering → `.filter()`
- See [patterns/code-style.md](patterns/code-style.md) for detailed examples

**NO INLINE ARROW FUNCTIONS** (CRITICAL):
- ALL arrow functions must use block syntax with explicit `return` — no exceptions
- `(x) => x + 1` is WRONG. Always write `(x) => { return x + 1 }`
- This applies everywhere: `.map()`, `.reduce()`, `.filter()`, `.find()`, `Array.from()`, callbacks, event handlers — no inline expressions
- Coverage tools cannot track branches on single-line arrow functions, producing false positives
- See [patterns/code-style.md](patterns/code-style.md) for examples

**NO COMMENTS** (CRITICAL):
- Zero comments allowed in any code - no exceptions
- Code must be self-documenting through clear naming
- If you need a comment, your code needs refactoring
- Only `// TODO: Remove when [condition]` is temporarily acceptable

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

**If you need a singleton**, use the memoization pattern from `@beecode/msh-util`:

```typescript
import { singletonPattern } from '@beecode/msh-util/singleton/pattern'

// Export the singleton accessor (not the instance)
export const secretServiceSingleton = singletonPattern(() => new SecretService())

// Usage - always call the singleton function
secretServiceSingleton().decryptSecret(secret)
```

**Controllers**:
- Backend: Express/RxJS/RMQ → Always singleton objects
- Frontend: React Router → Function components that translate URL → props
- **Single business call rule**: Controller handlers must call ONLY ONE function from the business layer (use-case, service, repo, or component). If multiple calls are needed, create a new service/use-case function that orchestrates them.
- **Light handlers**: Controllers are for: (1) validate request data, (2) pass parameters to business layer, (3) format response. NO business logic in controllers.

**Business Logic**:
- Use Cases: Always singleton objects (prevents nesting)
- Components: Complex domain logic (3+ states, self-contained)
- Services: Simple logic (singleton preferred, class if methods call each other)
- Repositories: Always classes
- **See "NO EXPORTED INSTANCES" section above for singleton pattern**

**Object Params Pattern**:
- Business logic layers → ALWAYS use object params (even 1 parameter)
- Utility layer → Conditional (skip if name implies parameter)

**One Element Per File**:
- One class/object/component per file
- Local types/interfaces allowed if not shared

**CRITICAL: Module Export Pattern**:
- **NEVER export multiple standalone functions** from a single file
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
  isString(params: { value: unknown }): value is string { ... },
}
```

**CRITICAL: File Location**:
- **Business logic MUST be in `src/business/`** (service/, component/, use-case/, repo/)
- **Data access MUST be in `src/dal/`** (typeorm/)
- **HTTP handlers MUST be in `src/controller/express/`**
- **Utility functions MAY be in `src/util/`** (project-local pure helpers; prefer services for complex logic)
- **Reusable infrastructure MAY be in `src/lib/`** — code with **no business logic** that is **reusable across multiple microservices**, kept as a staging area **until it is extracted** into a shared common package (`@app/node-common/`, `@app/common/`) or an external library. Examples: TypeORM `DataSource` singleton, table-name mapper, RMQ connection singletons
- **NEVER create arbitrary top-level folders** outside the allowed set. Allowed top-level folders under `src/` are: `app-boot/`, `controller/`, `business/`, `dal/`, `ui-component/`, `util/`, `lib/` (so no `src/yaml/`, `src/parsers/`, `src/helpers/`)
- **Subfolders within layers are encouraged** for grouping related implementations (e.g., `src/business/service/formatting-strategy/json.ts`)
