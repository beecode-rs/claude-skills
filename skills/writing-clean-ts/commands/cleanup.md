# Cleanup Command

Full-scope code review: validates TypeScript against both line-level **style** (`style/`) and the **layered architecture** (`architecture/`). For a scoped pass, use `/clean-style` (style only) or `/clean-arch` (architecture only).

## Usage

When user says: "cleanup this code", "review this file", "check code quality", or "validate code structure"

## Process

Run the project's lint script first (`lint-fix`, then `lint` to verify). Sections marked `[lint]` below are also enforced by the linter: auto-fixable issues are already resolved by `lint-fix`, and any remaining violations come with a lint report that guides the manual fix. The checks stay in this checklist to catch what the linter cannot fix on its own.

Run through each checklist section and report violations with file:line references. Style checks below reference the `style/` docs; structure checks reference the `architecture/` docs.

---

## Checklist

### 1. Comments Check

**Rule**: Zero tolerance for comments in code.

| Check | Pattern | Status |
|-------|---------|--------|
| No inline comments | `//` (not TODO) | ❌ FAIL |
| No block comments | `/* */` | ❌ FAIL |
| No JSDoc comments | `/** */` | ❌ FAIL |
| TODO with removal condition | `// TODO: Remove when [condition]` | ✅ PASS |
| TODO without removal condition | `// TODO fix this` | ❌ FAIL |

**Fix**: Refactor code to be self-documenting. Extract functions, rename variables, simplify logic.

---

### 2. For Loops Check `[lint]`

**Rule**: FOR LOOPS ARE PROHIBITED. Enforced by lint (`no-loops/no-loops`, not auto-fixable) - when lint reports a loop, rewrite it with the functional alternative.

| Pattern | Status | Alternative |
|---------|--------|-------------|
| `for (let i = 0; ...)` | ❌ FAIL | Use `.map()` or `.reduce()` |
| `for (const x of arr)` | ❌ FAIL | Use `.map()` or `.reduce()` |
| `for (const key in obj)` | ❌ FAIL | Use `Object.entries().map()` |

**Transformations**:
- Transformation → `.map()`
- Aggregation → `.reduce()`
- Filtering → `.filter()`
- Finding → `.find()`, `.some()`, `.every()`

---

### 3. Multi-Line Formatting Check

**Rule**: Multiple logical branches must span multiple lines for accurate code coverage.

#### Ternary Operators `[lint]`

```typescript
// ❌ WRONG - ternary operators are prohibited
const result = condition ? trueValue : falseValue
const result = condition
  ? trueValue
  : falseValue

// ✅ CORRECT - use if/else or extract to a function
if (condition) {
  return trueValue
}

return falseValue

// ✅ CORRECT - extract to a local function for const assignment
const getResult = () => {
  if (condition) {
    return trueValue
  }

  return falseValue
}

const result = getResult()
```

#### If Statements

```typescript
// ❌ WRONG - no braces (auto-fixed by lint: `curly`)
if (condition) doSomething()

// ❌ WRONG - single line braces
if (condition) { doSomething() }

// ✅ CORRECT - multi-line with braces
if (condition) {
  doSomething()
}
```

#### Arrow Functions

```typescript
// ❌ WRONG - logic on single line
const getValue = (x) => x ? x.toUpperCase() : ''

// ✅ CORRECT - block syntax
const getValue = (x) => {
  if (!x) {
    return ''
  }
  return x.toUpperCase()
}
```

---

### 4. File Organization Check

**Rule**: Files must be in correct directories.

| Code Type | Correct Location |
|-----------|------------------|
| REST API endpoint | `src/controller/express/` |
| React Router controller | `src/controller/react-router/` |
| Business logic (simple) | `src/business/service/` |
| Business logic (complex) | `src/business/component/` |
| Orchestration | `src/business/use-case/` |
| Repository | `src/business/repo/` |
| Data access | `src/dal/typeorm/` |
| Database entities | `src/dal/typeorm/entity/` |
| Type definitions | `src/business/model/` |
| React components | `src/ui-component/` |
| Pure utilities | `src/util/` |
| Reusable infrastructure (no business logic, destined for extraction) | `src/lib/` |

**Forbidden Locations** (must be moved):
- `src/parsers/` → `src/business/service/`
- `src/yaml/` → `src/business/service/` or `src/business/component/`
- `src/handlers/` → `src/controller/express/`
- `src/types/` → `src/business/model/`
- `src/helpers/` → `src/util/` or `src/business/service/`
- `src/domain/` → `src/business/`

**Note:** `src/lib/` is **allowed**, not forbidden. It holds reusable, non-business-logic infrastructure staged for extraction into a shared package (`@app/node-common/` etc.). Do **not** flag `src/lib/typeorm/`, `src/lib/rmq/`, etc.

---

### 5. Naming Convention Check

#### File Naming

| Pattern | Status | Example |
|---------|--------|---------|
| kebab-case | ✅ PASS | `project-service.ts` |
| `_kebab-case.ts` (leading underscore) | ✅ PASS | `_draft.ts` (private-file marker) |
| PascalCase | ❌ FAIL | `ProjectService.ts` |
| camelCase | ❌ FAIL | `projectService.ts` |

A leading underscore is an allowed private-file marker and MUST NOT be flagged as a kebab-case violation.

#### Export Naming

| Layer | Pattern | Example |
|-------|---------|---------|
| Service (singleton) | camelCase | `export const calculationService` |
| Service (class) | PascalCase | `export class SecretService` |
| Repository | PascalCase | `export class ProjectRepo` |
| Use Case | camelCase | `export const authUseCase` |
| DAL | PascalCase | `export class ProjectDal` |
| Entity | PascalCase | `export class ProjectEntity` |
| Handler | camelCase | `export const getProjectsAll` |

#### Method Naming

| Check | Pattern | Status |
|-------|---------|--------|
| Missing action verb | `users()`, `project()` | ❌ FAIL |
| Has action verb | `getUsers()`, `createProject()` | ✅ PASS |

#### Boolean Naming

| Prefix | Purpose | Example |
|--------|---------|---------|
| `is*` | State check | `isActive`, `isValid` |
| `has*` | Possession | `hasPermission`, `hasChildren` |
| `can*` | Ability | `canEdit`, `canDelete` |
| `should*` | Recommendation | `shouldRefresh` |
| `will*` | Future state | `willUpdate` |
| `did*` | Completed action | `didLoad` |

**Avoid**: `visible`, `permission`, `active` (missing prefix)

**Also check**:
- `Promise<boolean>` return types need the prefix too: `engineInstalled(): Promise<boolean>` ❌ FAIL → `isEngineInstalled()` ✅ PASS
- Local boolean variables and destructured props, not just interface fields
- DOM-mirror props (`disabled`, `checked`) are ✅ PASS — they mirror native HTML attributes

#### Falsy Boolean Defaults

**Rule**: Optional boolean flags default to falsy. Never encode a truthy default through an inverted check.

| Pattern | Status | Fix |
|---------|--------|-----|
| `if (x.flag !== false)` | ❌ FAIL | Invert the name: `shouldSkipFlag?: boolean` + `if (!x.shouldSkipFlag)` |
| `if (x.flag === true)` | ❌ FAIL | `if (x.flag)` |
| Destructured default `flag = true` | ❌ FAIL | Rename inverted so default is `false` |
| Persisted settings constant (`cleanText: true` in `defaultSettings`) | ✅ PASS | Sensible business default |

#### Timestamp Naming

| Field | Suffix | Example |
|-------|--------|---------|
| Creation time | `At` | `createdAt` |
| Update time | `At` | `updatedAt` |
| Deletion time | `At` | `deletedAt` |
| Event time | `At` | `publishedAt`, `verifiedAt` |

---

### 6. Class vs Object Pattern Check

**Mandatory Patterns**:

| Layer | Must Use | Pattern |
|-------|----------|---------|
| Repository | Class | `export class ProjectRepo` |
| DAL | Class | `export class ProjectDal` |
| Entity | Class | `export class ProjectEntity` |
| Use Case | Singleton | `export const authUseCase` |
| Handler | Singleton | `export const getProjectsAll` |
| Service | Either | Depends on `this` usage |

**Service Decision**:
- Service needs helper functions → Use class (helpers become `protected _` methods)
- Methods call each other via `this` → Use class
- Methods are independent → Use singleton (preferred)

---

### 7. Exported Instances Check

**Rule**: NEVER export instantiated class objects.

```typescript
// ❌ WRONG - exported instance
export const secretService = new SecretService()

// ❌ WRONG - renamed instance
const service = new SecretService()
export { service as secretService }

// ✅ CORRECT - export class, instantiate at call site
export class SecretService { ... }
// Usage: new SecretService().decrypt()

// ✅ CORRECT - use singletonPattern if needed
import { singletonPattern } from '@beecode/msh-util/singleton/pattern'
export const secretServiceSingleton = singletonPattern(() => new SecretService())
```

---

### 8. Object Params Pattern Check

**Rule**: Business logic layers MUST use object params for ALL functions.

| Layer | Object Params Required |
|-------|------------------------|
| Service | ✅ Always (even 1 param) |
| Repository | ✅ Always (even 1 param) |
| Use Case | ✅ Always |
| Component | ✅ Always |
| DAL | ✅ Always |
| Controller | ❌ Framework signature exception |
| Utility | Conditional (skip if name implies params) |

```typescript
// ❌ WRONG - multiple params
findOneById(id: string): Promise<Model>

// ✅ CORRECT - object params
findOneById(params: { id: string }): Promise<Model>
```

---

### 9. Export Pattern Check

**Rule**: ONE export per file (grouped into service object). No bare function exports — even a single function is wrapped in a singleton service object.

```typescript
// ❌ WRONG - multiple standalone exports
export function parseRegex(value: unknown): RegExp | null { ... }
export function isRegexString(value: unknown): boolean { ... }

// ❌ WRONG - single bare function export (still not allowed)
export function parseDate(value: unknown): Date | null { ... }

// ✅ CORRECT - singleton service object
export const regexParserService = {
  parse(params: { value: unknown }): RegExp | null { ... },
  isString(params: { value: unknown }): boolean { ... },
}

// ✅ CORRECT - even a single function is wrapped in a service object
export const dateParserService = {
  parse(params: { value: unknown }): Date | null { ... },
}
```

**Exception**: React/UI components (function components) are the only function-shaped exports allowed.

---

### 10. Root-level Helper Functions Check

**Rule**: A service file must export exactly one element (a class or a singleton object) and must NOT declare module-level (root-of-file) helper functions alongside it. Any helper that serves the service becomes a member of the service itself.

Flag any non-exported function declared at module scope (including `const` arrow functions) in a file that exports a service/class/object:

| Pattern | Status | Fix |
|---------|--------|-----|
| `function helper(...)` or `const helper = (...) => {...}` at module scope, file exports a service/class/object | ❌ FAIL | Move into the class as a `protected _method` called via `this` |
| Helper as `protected _method` on the service class | ✅ PASS | - |
| `_`-prefixed property on a singleton object, never called by consumers | ✅ PASS | Consider class pattern instead |

```typescript
// ❌ WRONG - module-level helper next to the service export
const parseUser = (raw: RawUser): UserModel => {
  return { id: raw.id, name: raw.userName }
}

export class UserService {
  getUser(params: { id: string }): UserModel {
    return parseUser(fetchRaw(params.id))
  }
}

// ✅ CORRECT - helper folded into the class as a protected _ method
export class UserService {
  getUser(params: { id: string }): UserModel {
    return this._parseUser(fetchRaw(params.id))
  }

  protected _parseUser(raw: RawUser): UserModel {
    return { id: raw.id, name: raw.userName }
  }
}
```

**Signal**: If the service needs helpers at all, prefer the class pattern (methods calling each other via `this`) per the Class vs Object decision guide.

---

### 11. Barrel Export Check

**Rule**: NO index.ts files that only re-export.

```typescript
// ❌ WRONG - barrel export
// src/business/service/index.ts
export { regexService } from './regex-service.js'
export { dateService } from './date-service.js'

// ✅ CORRECT - direct import
import { regexService } from '#src/business/service/regex-service.js'
```

**Exceptions**:
- Type definitions in `src/business/model/`
- Component public API (`src/business/component/*/index.ts`)
- npm package entry points

---

### 12. Never Keyword in Enum Switch Check

**Rule**: Use exhaustive type checking with `never`.

```typescript
// ❌ WRONG - no exhaustive check
switch (status) {
  case 'active': return 1
  case 'inactive': return 2
  default: return 0
}

// ✅ CORRECT - compile-time safety
switch (status) {
  case 'active': {
    return 1
  }
  case 'inactive': {
    return 2
  }
  default: {
    throw typeUtil.exhaustiveError('Unknown status', status)
  }
}
```

---

### 13. `let` & If/Else Chain Check

**Rule**: `let` is prohibited (`const` only). Branching on the same value across multiple cases is a `switch`, encapsulated in a function.

| Pattern | Status | Fix |
|---------|--------|-----|
| `let x` followed by branch assignments | ❌ FAIL | Extract a function that returns per branch, call it into a `const` |
| `if (v === 'a') ... else if (v === 'b') ... else if (v === 'c')` (same value) | ❌ FAIL | `switch` encapsulated in a function |
| Switch inline in main flow (not inside a function) | ❌ FAIL | Wrap in a well-named function (`resolveX`, `mapXToY`) |
| `case 'x':` without `{}` block / uses `break` | ❌ FAIL | Braced case blocks that `return` (or `throw` in `default`) |
| `default` silently falls through or returns uninitialized value | ❌ FAIL | `default: { throw ... }` or documented fallback return |

```typescript
// ❌ WRONG - if/else chain on one value, mutating a let
let appDataDir
if (platform === 'darwin') {
  appDataDir = darwinPath
} else if (platform === 'win32') {
  appDataDir = process.env.APPDATA
} else if (platform === 'linux') {
  appDataDir = linuxPath
} else {
  throw new Error(`unsupported platform: ${platform}`)
}

// ✅ CORRECT - switch encapsulated in a function, called into a const
const resolveAppDataDir = () => {
  switch (process.platform) {
    case 'darwin': {
      return darwinPath
    }
    case 'win32': {
      return process.env.APPDATA
    }
    case 'linux': {
      return linuxPath
    }
    default: {
      throw new Error(`unsupported platform: ${process.platform}`)
    }
  }
}

const appDataDir = resolveAppDataDir()
```

**Note**: Plain `if/else` on distinct boolean conditions is ✅ PASS — the rule targets chains comparing one value repeatedly.

---

## Output Format

After running the cleanup command, provide a structured report:

```markdown
# Cleanup Report: [filename]

## Summary
- **Total Issues**: X
- **Critical**: X (blocks merge)
- **Warnings**: X (should fix)

## Issues Found

### Critical Issues

| Line | Category | Issue | Fix |
|------|----------|-------|-----|
| 15 | Comments | Inline comment found | Remove or refactor |
| 23 | For Loops | `for...of` loop used | Use `.map()` |

### Warnings

| Line | Category | Issue | Suggestion |
|------|----------|-------|------------|
| 45 | Naming | Boolean missing prefix | Rename `active` to `isActive` |

## Recommendations

1. [Specific recommendation based on findings]
2. [Another recommendation]

## Auto-fixable

- [ ] Run `lint-fix` (ESLint, Prettier, jsonsort) first - it auto-fixes the mechanical `[lint]` issues (import order, sorted keys, braces, formatting)

The following issues can be auto-fixed:
- [ ] Replace ternary operators with if/else or local functions (flagged by lint `no-ternary`, rewritten manually)
- [ ] Object params pattern
```

---

## Quick Reference Card

```
LINT FIRST    → Run `lint-fix` before reviewing; `[lint]` rules are also enforced by the lint script
COMMENTS      → None (except TODO with condition)
FOR LOOPS     → Use .map() / .reduce() / .filter() `[lint]`
TERNARY       → PROHIBITED - use if/else or extract to function `[lint]`
MULTI-LINE    → If, arrow functions
FILE ORG      → Correct directories only
NAMING        → kebab-case files, action verbs, boolean prefixes (incl. Promise<boolean>)
BOOL DEFAULTS → falsy; no `!== false` / `= true` flags; invert the name (shouldSkip*)
CLASS/OBJECT  → Repo/DAL/Entity=class, UseCase/Handler=singleton
EXPORTS       → No instantiated objects, one element per file
ROOT HELPERS  → No module-scope functions in service files (protected _ methods)
OBJECT PARAMS → Business logic always uses { params }
BARREL FILES  → No index.ts re-exports
ENUM SWITCH   → Use never for exhaustive check
LET           → PROHIBITED; const only, branch values from returning functions
IF/ELSE CHAIN → Same value across cases = switch in a function (braced cases, default throws)
```
