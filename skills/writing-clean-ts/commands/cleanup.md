# Cleanup Command

Full-scope code review: validates TypeScript against both line-level **style** (`style/`) and the **layered architecture** (`architecture/`). For a scoped pass, use `/clean-style` (style only) or `/clean-arch` (architecture only).

## Usage

When user says: "cleanup this code", "review this file", "check code quality", or "validate code structure"

## Process

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

### 2. For Loops Check

**Rule**: FOR LOOPS ARE PROHIBITED.

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

#### Ternary Operators

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
// ❌ WRONG - no braces
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

**Forbidden Locations** (must be moved):
- `src/parsers/` → `src/business/service/`
- `src/yaml/` → `src/business/service/` or `src/business/component/`
- `src/handlers/` → `src/controller/express/`
- `src/types/` → `src/business/model/`
- `src/helpers/` → `src/util/` or `src/business/service/`
- `src/domain/` → `src/business/`

---

### 5. Naming Convention Check

#### File Naming

| Pattern | Status | Example |
|---------|--------|---------|
| kebab-case | ✅ PASS | `project-service.ts` |
| PascalCase | ❌ FAIL | `ProjectService.ts` |
| camelCase | ❌ FAIL | `projectService.ts` |

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

**Rule**: ONE export per file (grouped into service object).

```typescript
// ❌ WRONG - multiple standalone exports
export function parseRegex(value: unknown): RegExp | null { ... }
export function isRegexString(value: unknown): boolean { ... }

// ✅ CORRECT - singleton service object
export const regexParserService = {
  parse(params: { value: unknown }): RegExp | null { ... },
  isString(params: { value: unknown }): boolean { ... },
}
```

---

### 10. Barrel Export Check

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

### 11. Never Keyword in Enum Switch Check

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
  case 'active': return 1
  case 'inactive': return 2
  default:
    throw typeUtil.exhaustiveError('Unknown status', status)
}
```

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

The following issues can be auto-fixed:
- [ ] Replace ternary operators with if/else or local functions
- [ ] Object params pattern
```

---

## Quick Reference Card

```
COMMENTS      → None (except TODO with condition)
FOR LOOPS     → Use .map() / .reduce() / .filter()
TERNARY       → PROHIBITED — use if/else or extract to function
MULTI-LINE    → If, arrow functions
FILE ORG      → Correct directories only
NAMING        → kebab-case files, action verbs, boolean prefixes
CLASS/OBJECT  → Repo/DAL/Entity=class, UseCase/Handler=singleton
EXPORTS       → No instantiated objects, one element per file
OBJECT PARAMS → Business logic always uses { params }
BARREL FILES  → No index.ts re-exports
ENUM SWITCH   → Use never for exhaustive check
```
