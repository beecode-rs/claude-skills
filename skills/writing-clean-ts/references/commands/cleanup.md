# Cleanup Command

Full-scope code review: validates TypeScript against both line-level **style** (`style/`) and the **layered architecture** (`architecture/`). For a scoped pass, use `/clean-style` (style only) or `/clean-arch` (architecture only).

## Usage

When user says: "cleanup this code", "review this file", "check code quality", or "validate code structure"

## Process

Lint gate, before any checklist section: if the project has no `lint` / `lint-fix` scripts (or no ESLint config), set linting up first following `references/linting.md` ("Setting Up Linting"), then run. Run `lint-fix`, then `lint`, and use the real script output as input to this review. Sections marked `[lint]` below are verified ONLY by that output: do not scan the code by eye for them and do not ask an AI agent or AI reviewer to judge them - fix what the report flags (manually when not auto-fixable, following the fix guidance in each section) and re-run until `lint` passes. The unmarked sections are the manual review work the scripts cannot replace.

**Expo projects:** if the package is an Expo app (`expo` / `expo-router` dependency, `"main": "expo-router/entry"`, or an `expo` key in `app.json` / `app.config.ts`), do not report the framework-mandated Expo patterns: files in `src/app/` without layer suffixes, with `[param]`/`(group)`/`+name`/`_layout` names, or exporting a default component; `index.tsx` in `src/app/`; `src/app/` as a top-level folder (never suggest renaming it to `app-boot/`); `@/` imports, or a missing `"type": "module"` / `imports` field / `#src` paths; platform-variant files (`x.web.ts` next to `x.ts`). Still report relative imports, business logic or routing hooks inside screens, non-route code placed in `src/app/`, and route files that do more than read router params and pass props.

Run through each checklist section and report violations with file:line references. Style checks below cover the line-level style rules; structure checks cover the layered architecture rules.

When the scope is the whole source tree ("check all src files"), find candidates mechanically before reading: search for the pattern (`rg -n '\bparams\.' src`, `rg -n 'export const [A-Z_]+ =' src`, `rg -n 'process\.(env|platform)' src`, `rg -n 'export interface' src`, `rg -n '^export enum' src`), fix every hit, then re-run the search and account for each remaining match as a deliberate exception. After fixing, run typecheck, `lint-fix`, `lint`, and the tests, and report their real results.

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
| One-word group title inside a router's single `register()` | `// Usage` | ✅ PASS |

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
| Business logic called directly by name | `src/business/service/` |
| Encapsulated unit (public API + private internals in a folder) | `src/business/component/` |
| Named workflow boundary for a controller | `src/business/use-case/` |
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
| File name repeats its folder (`sessions/sessions-poll-service.ts`) | ❌ FAIL | `sessions/poll-service.ts` (export keeps the prefix: `SessionsPollService`) |
| Project/product name as prefix (`usage-pulse-app-flow.ts`) | ❌ FAIL | Name what it is: `desktop-app.ts` |
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

Only `is*` and `has*` are used. `can*`, `should*`, `will*`, `did*` ❌ FAIL (rename to `is*`/`has*`, e.g. `canEdit` → `isEditable`, `shouldSkipHistory` → `isHistorySkipped`).

**Avoid**: `visible`, `permission`, `active` (missing prefix)

**Also check**:
- `Promise<boolean>` return types need the prefix too: `engineInstalled(): Promise<boolean>` ❌ FAIL → `isEngineInstalled()` ✅ PASS
- The prefix comes FIRST in a boolean-returning function name: `resolveIsNewerVersion()` ❌ FAIL → `isNewerVersion()` ✅ PASS
- A two-member yes/no enum (`SUPPORTED` / `UNSUPPORTED`) ❌ FAIL → replace with an `is*` boolean flag and delete the enum
- Local boolean variables and destructured props, not just interface fields
- DOM-mirror props (`disabled`, `checked`) are ✅ PASS — they mirror native HTML attributes

#### Falsy Boolean Defaults

**Rule**: Optional boolean flags default to falsy. Never encode a truthy default through an inverted check.

| Pattern | Status | Fix |
|---------|--------|-----|
| `if (x.flag !== false)` | ❌ FAIL | Invert the name: `isFlagSkipped?: boolean` + `if (!isFlagSkipped)` |
| `if (x.flag === true)` | ❌ FAIL | `if (x.flag)` |
| Default `flag: true` | ❌ FAIL | Rename inverted so default is `false` |
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
| Use Case | Plain object (stateless, never `singletonPattern`) | `export const authUseCase` |
| Handler | Plain object | `export const getProjectsAll` |
| Life cycle | Class extending `LifeCycle`, in `app-boot/life-cycle/` | `export class SettingsLifeCycle` |
| Service / Util / Lib | Either | Depends on helpers / `this` / state |

**Service Decision**:
- Service needs helper functions → Use class (helpers become `protected _` methods; the class IS the splitting mechanism)
- Methods call each other via `this`, or the service carries state → Use class
- Methods are independent and the logic is simple → Use singleton (a statement that no helpers are needed)
- Builds a value/config, no methods on `this` → Factory function

| Pattern | Status | Fix |
|---------|--------|-----|
| Plain object with `_`-prefixed functions | ❌ FAIL | Convert to a class; the `_` functions become `protected` |
| `singletonPattern` on a class holding no memory a new instance would lack | ❌ FAIL | Remove the singleton; `new X()` at the call site (ask when unsure) |
| Class in `x.ts`, accessor in `x-singleton.ts` | ❌ FAIL | Merge into `x-singleton.ts`: `export class _X` first, accessor last |
| Class behind a singleton not prefixed `_` | ❌ FAIL | Rename to `_X` |
| Services/repos/DALs passed through constructor params | ❌ FAIL | `import` them; owned instances as protected field initializers; constructors take config values only |
| Use case wrapped in `singletonPattern`, or a use case that runs once at startup | ❌ FAIL | Stateless plain object; startup work becomes an app-boot life cycle |
| Life cycle with public methods beyond create/destroy (`getWindow()`) | ❌ FAIL | Move the shared state to a lib/business `-singleton`; the life cycle only sets it up |

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
| Utility and Lib | Optional for 1-2 params (positional fine; object when names are not obvious) |

```typescript
// ❌ WRONG - multiple params
findOneById(id: string): Promise<Model>

// ✅ CORRECT - object params
findOneById(params: { id: string }): Promise<Model>
```

**Destructuring and defaults (every layer, `params` and `props` alike):**

| Pattern | Status | Fix |
|---------|--------|-----|
| `params.x` / `props.x` read anywhere in the body | ❌ FAIL | `const { x } = params` as the first body line; rename in the destructure if it would shadow |
| `const { x = 1 } = params` | ❌ FAIL | Move the default to the signature: `params: { x?: number } = { x: 1 }` |
| `const { x } = { x: 1, ...params }` / `params ?? {}` | ❌ FAIL | Same: default in the signature, plain destructure |
| `resolve(params: { platform?: OS } = { platform: osUtil.resolvePlatform() })` + `const { platform } = params` | ✅ PASS | |
| Mutating a param (`params.items.push(x)`, `trigger.status = ...`, `input.sort()`) | ❌ FAIL | Return a new value (`[...items, x]`, `{ ...trigger, status }`, `[...input].sort()`) |

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
| `_`-prefixed property on a plain object | ❌ FAIL | Convert the object to a class with `protected _` methods |
| Module-level constant (`const LIMIT = 50`, `const X_REGEX = /.../`) | ❌ FAIL | Move to the `constant` object in `util/constant.ts` |

```typescript
// ❌ WRONG - module-level helper next to the service export
const parseUser = (raw: RawUser): UserModel => {
  return { id: raw.id, name: raw.userName }
}

export class UserService {
  getUser(params: { id: string }): UserModel {
    const { id } = params

    return parseUser(fetchRaw(id))
  }
}

// ✅ CORRECT - helper folded into the class as a protected _ method
export class UserService {
  getUser(params: { id: string }): UserModel {
    const { id } = params

    return this._parseUser(fetchRaw(id))
  }

  protected _parseUser(raw: RawUser): UserModel {
    return { id: raw.id, name: raw.userName }
  }
}
```

**Signal**: If the service needs helpers at all, prefer the class pattern (methods calling each other via `this`) per the class-vs-object rule.

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
- A strategy interface in `business/component/<name>/index.ts` or `business/service/<name>/index.ts`
- Component entry files for multi-backend components (e.g. `data-store/common.ts` re-exporting from `_common/`)
- npm package entry points

---

### 12. Exhaustive Enum Switch Check

**Rule**: A switch whose cases cover every member of an enum (or closed union) MUST throw `typeUtil.exhaustiveError(message, value)` from `@beecode/msh-util` in `default`. Check every switch in the scope, including factories (enum → strategy) and components (enum → JSX).

```typescript
// ❌ WRONG - no exhaustive check, raw strings
switch (status) {
  case 'active': return 1
  case 'inactive': return 2
  default: return 0
}

// ✅ CORRECT - enum members, braced cases, exhaustive default
switch (status) {
  case ProjectStatus.ACTIVE: {
    return 1
  }
  case ProjectStatus.INACTIVE: {
    return 2
  }
  default: {
    throw typeUtil.exhaustiveError('unknown status', status)
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
if (platform === OS.MACOS) {
  appDataDir = darwinPath
} else if (platform === OS.WINDOWS) {
  appDataDir = config.windows.appDataDir
} else if (platform === OS.LINUX) {
  appDataDir = linuxPath
} else {
  throw new Error(`unsupported platform: ${platform}`)
}

// ✅ CORRECT - switch encapsulated in a function, called into a const
const resolveAppDataDir = (params: { platform: OS }): string => {
  const { platform } = params

  switch (platform) {
    case OS.MACOS: {
      return darwinPath
    }
    case OS.WINDOWS: {
      return config.windows.appDataDir
    }
    case OS.LINUX: {
      return linuxPath
    }
    default: {
      throw typeUtil.exhaustiveError('unsupported platform', platform)
    }
  }
}

const appDataDir = resolveAppDataDir({ platform: osUtil.resolvePlatform() })
```

**Note**: Plain `if/else` on distinct boolean conditions is ✅ PASS — the rule targets chains comparing one value repeatedly.

---

### 14. Import Paths Check `[lint]`

**Rule**: Internal imports are absolute through the `#src/*` alias only. Relative imports (`./`, `../`) are prohibited; the project runs ES modules with the alias configured (`"type": "module"` + `"imports"` in package.json, `paths` in tsconfig).

| Pattern | Status | Fix |
|---------|--------|-----|
| `import { x } from '#src/business/service/foo-service'` | ✅ PASS | |
| `import { x } from '../business/service/foo-service'` | ❌ FAIL | Rewrite as `#src/business/service/foo-service` |
| `import { x } from './foo-service'` (sibling) | ❌ FAIL | Rewrite as the full `#src/<layer>/.../foo-service` path |
| package.json missing `"type": "module"` | ❌ FAIL | Add it before writing any code |
| package.json missing `"imports": { "#src/*": "./dist/*.js" }` | ❌ FAIL | Add it so `#src/*` resolves at runtime in plain Node (subpath import) |
| tsconfig missing `"paths": { "#src": ["./src"], "#src/*": ["./src/*"] }` | ❌ FAIL | Configure both entries; bundlers additionally need `vite-tsconfig-paths` or `resolve.alias` |

**Note**: Private files (leading `_`) are still imported by absolute `#src` path from within their folder; `@app/*` monorepo shared-package imports are also ✅ PASS.

---

### 15. Constant, Config & Platform Check

**Rule**: one `constant` object in `util/constant.ts`, env read only in `util/config.ts` (immutable after startup), runtime changes in a util memory module seeded from config, `process.platform` only in `osUtil.resolvePlatform()`.

| Pattern | Status | Fix |
|---------|--------|-----|
| `export const UPPER_CASE_NAME = ...` anywhere | ❌ FAIL | A camelCase key in the single `constant` object (or `config` if env-settable) |
| `constant.ts` exporting several constants instead of one object | ❌ FAIL | `export const constant = { ... }` |
| Keys sharing a prefix left flat (`scheduleTriggerRunLogLimit`, `scheduleTriggerRunTimeoutMs`) | ❌ FAIL | Nest: `scheduleTrigger.run.log.limit`, `scheduleTrigger.run.timeoutMs` |
| `minDurationMs` / `maxDurationMs` / `defaultDurationMs` as siblings | ❌ FAIL | `durationMs: { min, max, default }` under the value they describe |
| Regex outside `constant.ts`, or a regex key ending in `Pattern`/`Re` | ❌ FAIL | Move to `constant`, key ends with `Regex` |
| Constant or regex named after its caller (`versionCompareRegex`) | ❌ FAIL | Name what it matches/is (`digitSequenceRegex`) |
| Time value in seconds/minutes/hours | ❌ FAIL | Milliseconds, key ends with `Ms` |
| `process.env` outside `util/config.ts` | ❌ FAIL | Declare the key in `config` (`mshEnvResolver`) and read `config.x` |
| Config value assigned after startup | ❌ FAIL | Keep config immutable; runtime changes go to a util memory module seeded from config |
| Raw `process.env` mixed into `config` | ❌ FAIL | Separate `processEnv()` export in `config.ts` |
| `process.platform` outside `os-util.ts`, or raw `'darwin'`/`'win32'` strings | ❌ FAIL | `osUtil.resolvePlatform()` returning the `OS` enum |
| Hardcoded tunable values in a model or service | ❌ FAIL | `config` if env-settable, otherwise `constant` |

---

### 16. Enum & Type Check

| Pattern | Status | Fix |
|---------|--------|-----|
| Enum declared in a model file or in `model/` | ❌ FAIL | Own file in the sibling `business/enum/` folder |
| Enum file not ending in `-enum.ts` | ❌ FAIL | `<name>-enum.ts` (or `<name>-mapper-enum.ts`) |
| Exported enum name ending in `Enum` | ❌ FAIL | Drop the suffix: `OSEnum` → `OS` |
| Keys ≠ values without `Mapper` in the name | ❌ FAIL | Rename `XxxMapper`, file `<name>-mapper-enum.ts` |
| String union for a closed domain set (`'claude' \| 'zai'`) | ❌ FAIL | Enum in its own file; replace every literal with the member |
| `export interface` for a model, props, or params | ❌ FAIL | `export type` (interface only when a class implements it) |
| `type` whose name starts with `I` | ❌ FAIL | Drop the `I`; pick a descriptive name if that collides |
| `XxxEntity` in `business/model/` | ❌ FAIL | Rename to `XxxModel` (entities exist only in the DAL) |
| Business logic or an API client inside a model file | ❌ FAIL | Move to the service/repo layer; the model file keeps only types |

---

### 17. Naming Meaning Check

| Pattern | Status | Fix |
|---------|--------|-----|
| Name describes the current caller, not the thing (`SessionSoundMapper` for a sound-name mapper) | ❌ FAIL | `SoundNameMapper` |
| Generic name where the domain has several kinds (`TriggerModel` among schedule/usage/session triggers) | ❌ FAIL | Qualify: `ScheduleTriggerModel` |
| Overloaded word used unqualified ("token" for both access token and LLM token) | ❌ FAIL | Qualify everywhere: `accessTokenSource` |
| Rename applied to the file but not to callers, identifiers, or tests | ❌ FAIL | Propagate the rename across the whole source tree |

---

### 18. Layer Placement Check

| Pattern | Status | Fix |
|---------|--------|-----|
| `-util` file with domain logic | ❌ FAIL | Rename to `-service`, move to `business/service/` |
| `-util` file that knows an external system's format (another tool's transcripts) | ❌ FAIL | `lib/<name>/` folder: `service.ts` + files by responsibility |
| Startup code in a use case or service | ❌ FAIL | `app-boot/life-cycle/<name>-life-cycle.ts` |
| Life cycle files directly in `app-boot/` | ❌ FAIL | `app-boot/life-cycle/` |
| Controller registration code (channel → handler) in a life cycle | ❌ FAIL | `controller/<interface>/router.ts`; the life cycle only calls `register()` |
| Several `registerX()` functions in one router | ❌ FAIL | One `register()`, domains separated by a one-word title comment, callbacks in `<domain>.ts` |
| Handcrafted payload checks on a raw record in a controller | ❌ FAIL | zod schema through the validation util |
| Listener arrays / `onUpdate(listener)` registries in services | ❌ FAIL | Emit a typed message on the app event bus (lib); subscribe in `controller/rxjs-bus/` |
| Event bus in `business/service/` or `util/` | ❌ FAIL | `lib/` |
| Test-only helper (contract harness, fake, fixture) next to production code | ❌ FAIL | `__tests__/` at the same level; `*.contract.yaml` / `*.test.ts` stay next to the source |
| Finished migration code, legacy format readers, unused dummy implementations | ❌ FAIL | Delete them with their tests and wiring |
| Near-identical functions repeated (three `_ensureUniqueXId` copies) | ❌ FAIL | One generic util (or one `protected _` method) called for each case |

---

### 19. Repo & DAL Check

| Pattern | Status | Fix |
|---------|--------|-----|
| Repo imports `fs`, builds a path, or parses JSON | ❌ FAIL | Move to the repo's DAL |
| Repo method named `read*`/`write*`, or DAL method named `save*`/`fetch*` | ❌ FAIL | Repo: business words; DAL: `read`/`write` |
| DAL applying defaults, sanitizing, or emitting events | ❌ FAIL | Move to the repo |
| Two repos holding the same data (a file repo and an in-memory copy) | ❌ FAIL | One repo: async `init()` from app boot, sync `fetch()`, write-through `save()` |
| Repeated file/memory mechanics in several DALs | ❌ FAIL | `common-file-dal.ts` / `common-memory-dal.ts` base |
| Service taking data as a param it could fetch itself (settings) | ❌ FAIL | The service calls the repo |

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
IMPORTS       → Absolute #src/* only, no ./ or ../ (ESM + aliases) `[lint]`
NAMING        → kebab-case files, action verbs, boolean prefixes (incl. Promise<boolean>)
BOOL DEFAULTS → falsy; no `!== false` / `= true` flags; invert the name (isXSkipped)
CLASS/OBJECT  → Repo/DAL/Entity/LifeCycle=class, UseCase/Handler=plain object; `_` helpers ⇒ class
EXPORTS       → No instantiated objects, one element per file
ROOT HELPERS  → No module-scope functions in service files (protected _ methods)
OBJECT PARAMS → Business logic always uses { params }; destructure first line; defaults in signature
NO MUTATION   → Never change params or what they reference; return new values
SINGLETON     → Only with memory; `_Class` + accessor in one -singleton.ts; no constructor DI
BARREL FILES  → No index.ts re-exports
ENUM SWITCH   → default throws typeUtil.exhaustiveError
ENUMS         → business/enum/, one per -enum.ts, no Enum suffix, keys≠values ⇒ Mapper, unions ⇒ enums
CONSTANTS     → one `constant` object, nested keys, Regex/Ms suffixes; process.env only in config.ts
TYPES         → `type` for models/props/params; interface + I only for class contracts
NAMES         → what it is, not where it's used; renames propagate everywhere
REPO/DAL      → repo = business words, no files; DAL = read/write, fs, paths
LET           → PROHIBITED; const only, branch values from returning functions
IF/ELSE CHAIN → Same value across cases = switch in a function (braced cases, default throws)
```
