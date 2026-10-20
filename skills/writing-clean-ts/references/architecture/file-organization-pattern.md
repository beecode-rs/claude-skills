# File Organization Pattern

This document defines where files must be placed and how modules should be structured. Following these rules prevents misplaced code and maintains architectural integrity.

## The Master Criterion: Domain-Awareness

The single clearest dividing line for "where does this logic live":

> **Does the code know about the business domain?** (imports from `business/model/`, or operates on domain model shapes like entities, projects, tokens)
> - **Yes** → business layer: `business/service/`, `business/component/`, `business/use-case/`, `business/repo/`
> - **No** → infrastructure: `util/` (generic pure helper) or `lib/` (third-party/infrastructure wrapper, or a reader/client for an external system)

Structural shape alone does not decide this. An enum-to-readable-string mapper is structurally identical to a util (pure switch-map functions), but because it imports five domain enums and maps them, it is a service. A URL builder that imports a `MicroServiceNameMapper` model is a service. A migration checker that wraps TypeORM with zero domain knowledge is lib code, no matter how much logic it contains.

**External-system knowledge is lib, not util.** Code that knows another tool's file format, protocol, or vendor-specific data (parsing Claude Code session transcripts, reading a vendor's credential store) is not a generic helper: it is an integration that could be extracted into its own package one day. It lives in `lib/<name>/` in its own folder, with the public API in `service.ts` and the rest split into files by responsibility (`lib/claude-transcript-reader/service.ts`, `.../_line-parser.ts`, `.../_usage-extractor.ts`). Name the folder for what it does with the external system (`claude-transcript-reader`), not for the feature that first needed it.

Secondary signals, consistent but not sufficient alone:
- Utils never call repos or services. Services may call repos, components, dals, utils, and other same-package services.
- Utils are stateless (or config/logger singletons). Services may hold constructor state.

## Directory Structure

### Backend Structure

```
src/
├── app-boot/                    # Application initialization and shutdown
│   ├── <app-name>.ts            # The AppFlow (desktop-app.ts, api-server.ts)
│   └── life-cycle/              # One *-life-cycle.ts class per startup concern
├── controller/
│   ├── express/                 # REST API handlers
│   ├── ipc/                     # Electron IPC: router.ts + one handler file per domain
│   ├── rxjs-bus/                # Event bus subscriptions: router-singleton.ts + handlers
│   └── react-router/            # Frontend route controllers
├── business/
│   ├── component/               # Encapsulated units: folder with a public API and private internals
│   ├── service/                 # Directly-called business logic (flat files or subfolders)
│   ├── use-case/                # Controller-facing named workflow boundaries
│   ├── repo/                    # Repository classes
│   ├── hook/                    # Shared React hooks (shared packages only)
│   ├── model/                   # Models only (types, model classes)
│   ├── enum/                    # One enum per *-enum.ts / *-mapper-enum.ts file
│   └── schema/                  # Zod schemas the business layer uses (*-schema.ts)
├── dal/
│   ├── common-file-dal.ts       # Shared file storage mechanics
│   ├── common-memory-dal.ts     # Shared in-memory storage mechanics
│   ├── *-dal.ts                 # One DAL per repo (file/memory)
│   └── typeorm/
│       ├── entity/              # TypeORM entities
│       └── *-dal.ts             # TypeORM DAL classes
├── ui-component/                # React UI components
├── util/                        # Pure utility functions (project-local, NO business logic)
├── lib/                         # Third-party/infrastructure wrappers (NOT domain-aware) - staging area until extracted to a shared package
├── __internal__/                # Package-private wiring in shared libs (mirrors business/, lib/, util/, dal/)
├── asset/                       # Frontend static assets (logo, scss, images)
└── __tests__/                   # Tests for the package's public surface
```

**Multi-process apps** (Electron) repeat this tree per process: `src/main/` (Node main process), `src/renderer/src/` (React renderer), and `src/shared/` (models, enums, constants, and pure utils both sides import). Something used by both processes lives in `src/shared/` under the same layer name (`src/shared/business/enum/`, `src/shared/util/constant.ts`); something used by one process lives in that process's tree.

The old folder names you may encounter in existing code, and their targets: `src/app/` → `src/app-boot/`, `src/screen/` → `src/controller/react-router/`, `src/component/` → `src/ui-component/`. Generate the new names for new code; treat the old names in existing packages as rename candidates. **Exception: in an Expo project `src/app/` is the Expo Router routes folder, not an old app-boot name. Never rename it**.

### Where to Place Code

| Code Type | Location | Example Path |
|-----------|----------|--------------|
| REST API endpoint | `src/controller/express/` | `src/controller/express/get-projects-all.ts` |
| Business logic called directly by name | `src/business/service/` | `src/business/service/calculation-service.ts` |
| Encapsulated unit (public API + private internals in a folder) | `src/business/component/<name>/` | `src/business/component/entity-format-strategy/` |
| Named workflow boundary for a controller | `src/business/use-case/` | `src/business/use-case/auth-use-case.ts` |
| Data access | `src/business/repo/` | `src/business/repo/project-repo.ts` |
| Database operations | `src/dal/typeorm/` | `src/dal/typeorm/project-dal.ts` |
| Database entities | `src/dal/typeorm/entity/` | `src/dal/typeorm/entity/project-entity.ts` |
| Type definitions (models) | `src/business/model/` | `src/business/model/core/project-model.ts` |
| Enums | `src/business/enum/` | `src/business/enum/usage-activity-status-enum.ts` |
| Constants (fixed by code) | `src/util/constant.ts` | `constant.scheduleTrigger.durationMs.max` |
| Env-driven config | `src/util/config.ts` | `config.update.feedUrl` |
| Startup / shutdown work | `src/app-boot/life-cycle/` | `src/app-boot/life-cycle/settings-life-cycle.ts` |
| Reader/client for an external system's format | `src/lib/<name>/` | `src/lib/claude-transcript-reader/service.ts` |
| Test-only helpers (harnesses, fakes, fixtures) | `__tests__/` next to the code they serve | `src/util/__tests__/constant-contract-harness.ts` |
| React components | `src/ui-component/` | `src/ui-component/project-list.tsx` |
| Shared React hooks (shared packages) | `src/business/hook/` | `src/business/hook/use-debounce.ts` |
| Pure utilities (generic over inputs) | `src/util/` | `src/util/date-util.ts` |
| Third-party wrapper, not domain-aware | `src/lib/<vendor>/` | `src/lib/typeorm/service.ts` |
| Package-private wiring in a shared lib | `src/__internal__/` | `src/__internal__/business/repo/repo-singleton.ts` |
| Static frontend assets | `src/asset/` | `src/asset/logo/logo.svg` |

## Placement Decision Tree

The decision sequence as actually practised:

```
New logic. Where does it live?
│
├─ Runs once at startup/shutdown (load state, register, start pollers)?
│    └─ YES → src/app-boot/life-cycle/<name>-life-cycle.ts
│
├─ Wraps a third-party library / infrastructure, or knows an external
│  system's format/protocol, and is not domain-aware?
│    └─ YES → src/lib/<name>/              (service.ts = the lib's own public API)
│
├─ Generic pure helper (no business/model import, no state)?
│    └─ YES → src/util/<name>-util.ts      (class PascalCase or object camelCase)
│
├─ A fixed value or an env-driven setting?
│    ├─ fixed by the code      → a key in src/util/constant.ts
│    └─ chosen at startup      → a key in src/util/config.ts
│
├─ Type, interface, or enum only?
│    ├─ domain data shape      → src/business/model/<domain>/<name>-model.ts (a `type`)
│    ├─ closed set of values   → src/business/enum/<name>-enum.ts
│    └─ contract a class implements → next to its consumer (repo file for IXxxDal) or implementation
│
└─ Business logic (domain-aware):
     ├─ One isolated unit: public API + private helpers hidden in a folder
     │  (usually multiple implementations selected at runtime by type/kind/enum,
     │  but also grouped pluggables or an orchestrator + private helpers)?
     │    └─ YES → src/business/component/<name>/
     ├─ A service-to-service dependency that is exclusive (the depended-on
     │  service has no other callers, its consumer is controller-facing)?
     │    └─ YES → src/business/component/<name>/   (service.ts + _x-service.ts)
     ├─ One workflow = a sequence of business calls owned by a controller?
     │    └─ YES → src/business/use-case/<name>-use-case.ts
     ├─ Needs TypeORM/HTTP persistence?
     │    └─ YES → src/business/repo/<name>-repo.ts
     └─ Otherwise → src/business/service/<name>-service.ts
```

## Subfolder Grouping Within Layers

When you have multiple implementations of the same concept (strategies, parsers, presets, adapters), group them in a **subfolder** within the target layer. This preserves the natural organizational structure and makes it easy to find all variants of a concept.

### Why subfolders over flat prefixed files

Flat prefixed files work for one or two implementations, but break down when you have many related files. Subfolders keep related code visually grouped and allow simple file names.

```
❌ Flat (hard to see what's related):
src/business/service/
├── formatting-strategy-json.ts
├── formatting-strategy-simple-string.ts
├── transporting-strategy-console.ts
├── transporting-strategy-pino.ts
├── transporting-strategy-stream.ts
├── transporting-strategy-void.ts
└── secret-service.ts

✅ Subfolder (grouping is clear):
src/business/service/
├── formatting-strategy/
│   ├── json.ts
│   └── simple-string.ts
├── transporting-strategy/
│   ├── console.ts
│   ├── pino.ts
│   ├── stream.ts
│   └── void.ts
└── secret-service.ts
```

### When to use subfolders vs. flat files

| Scenario | Approach | Example |
|----------|----------|---------|
| Single implementation | Flat file | `src/business/service/secret-service.ts` |
| 2+ services sharing an interface, shape, or composition chain | Subfolder | `src/business/service/ast-parse/` |
| Strategies selected at runtime by an in-folder selector, or an orchestrator with private helpers | Component folder | `src/business/component/entity-format-strategy/` |
| Pluggables imported individually by consumers | Component folder | `src/business/component/token/` |
| Preconfigured entry points (presets) | Subfolder in controller | `src/controller/preset/console-simple-string.ts` |
| Domain with multiple endpoints | Subfolder in controller | `src/controller/express/project/get-projects-all.ts` |

### Strategy Pattern Example (open)

When a concept has an interface and multiple implementations that outside callers pick from individually, the interface can either live in `model/` or stay inside the subfolder alongside its implementations.

**Option A - Interface in model/ (when interface is used broadly):**
```
src/business/
├── model/
│   └── formatting-strategy.ts          # FormattingStrategy interface
└── service/
    └── formatting-strategy/
        ├── json.ts                     # FormattingStrategyJson class
        └── simple-string.ts            # FormattingStrategySimpleString class
```

**Option B - Interface in subfolder (when interface is tightly coupled to implementations):**
```
src/business/service/
└── ast-parse/
    ├── index.ts                        # AstParseStrategy interface
    ├── service.ts                      # astParseService
    └── tag-service.ts                  # astParseTagService
```

Both options are valid. Choose Option A when other layers import the interface independently. Choose Option B when the interface is only meaningful within the context of its implementations.

The examples above are the **open** case: each strategy is a standalone, independently selectable unit that outside callers pick from, so they live as public files in `service/`. For the case where a selector or orchestrator owns the strategies, see the next section.

### Closed Pattern Implementations → Component Layer

When one unit of business logic needs a public API plus private internals (a selector that dispatches to strategies, an orchestrator with private helpers, several pluggables behind one folder), the whole unit lives in **one folder** under **`src/business/component/`**, never split across layers:

```
src/business/component/
└── entity-format-strategy/
    ├── index.ts              # the strategy interface (exists iff there is one)
    ├── service.ts            # the PUBLIC selector singleton - consumers import it directly
    ├── _class.ts             # private strategy (leading `_` = never imported outside this folder)
    ├── _enum.ts              # private strategy
    └── _type.ts              # private strategy
```

**Rules:**
- `service.ts` is the public callable API. Consumers import `#src/business/component/<name>/service` directly, even from controllers.
- `index.ts` holds the strategy interface only (3-6 lines). It is not a barrel and not a wrapper object.
- Strategy files are `_`-prefixed when an in-folder selector chooses among them. When consumers import the pieces individually, the files are NOT `_`-prefixed (that is Shape B, grouped pluggables).
- Do NOT split the pattern across locations (selector in one folder, strategies in another). Splitting it breaks the public/private boundary that is the whole point of the pattern.

### Preset Pattern Example

Preconfigured entry points that wire together strategies belong in the controller layer, grouped in a subfolder:

```
src/controller/
└── preset/
    ├── console-simple-string.ts        # PresetConsoleSimpleString
    ├── console-json.ts                 # PresetConsoleJson
    ├── pino.ts                         # PresetPino
    └── void.ts                         # PresetVoid
```

### Shared React Hooks (`src/business/hook/`)

Shared packages expose React hooks as a business sub-layer: `src/business/hook/use-debounce.ts`. A hook is business logic with React as its runtime; it lives under `business/`, not under `util/` or `ui-component/`.

### Mock and Test Placement in Subfolders

Test **specs** live next to the file they test: `json.contract.yaml` and `json.test.ts` sit beside `json.ts`. Everything else that exists only for tests (contract harness adapters, mocks, fakes, fixtures, fake factories) goes into a `__tests__/` folder at the same level as the code it serves, never loose among production files:

```
src/business/service/
└── formatting-strategy/
    ├── json.ts
    ├── json.contract.yaml
    ├── simple-string.ts
    ├── simple-string.test.ts
    └── __tests__/
        ├── formatting-strategy-mock.ts
        └── json-contract-harness.ts
```

A test-only file sitting next to production code (`src/util/_constant-contract-harness.ts`) moves into `__tests__/` (`src/util/__tests__/constant-contract-harness.ts`); the `_` private-file prefix is not a substitute. Model folders carry fake factories in `__tests__/` (e.g. `user-model-fake-factory.ts`).

## CRITICAL: Forbidden Locations

**NEVER create arbitrary top-level folders outside the defined structure.** The allowed top-level folders under `src/` are: `app-boot/`, `controller/`, `business/`, `dal/`, `ui-component/`, `util/`, `lib/`, `__internal__/`, `asset/`, `__tests__/` (Expo projects also allow `app/` for route files only). Subfolders *within* layers are encouraged for grouping related files.

### Examples of WRONG Locations:

```
❌ src/yaml/                    # Should be src/business/service/ or src/business/component/
❌ src/parsers/                 # Should be src/business/service/
❌ src/handlers/                # Should be src/controller/express/
❌ src/types/                   # Should be src/business/model/
❌ src/helpers/                 # Should be src/util/ or src/business/service/
❌ src/utils/                   # Should be src/util/
❌ src/domain/                  # Should be src/business/
```

### Examples of CORRECT Locations:

```
✅ src/business/service/yaml-parser-service.ts            # Flat file for a single service
✅ src/business/service/formatting-strategy/json.ts       # Subfolder grouping related implementations
✅ src/business/service/transporting-strategy/console.ts  # Subfolder grouping related implementations
✅ src/business/component/entity-format-strategy/         # Encapsulated unit
✅ src/controller/preset/console-simple-string.ts         # Subfolder grouping related presets
✅ src/util/date-util.ts
✅ src/business/model/yaml-contract-model.ts
✅ src/lib/typeorm/service.ts                             # The wrapper lib's own service
```

### Reusable Infrastructure (`src/lib/`)

`src/lib/` holds wrappers around third-party libraries and infrastructure integrations that are **not domain-aware**: TypeORM DataSource, RMQ connections, Axios interceptors, Apollo plugins, storage strategies, event buses.

- Contains **no business logic** (no `business/model/` imports)
- Can potentially be **reused across multiple microservices**
- Is **destined to be extracted** into a shared common package (`@app/node-common/`, `@app/common/`) or an external library

It is a staging area: code lives here while it is only being used by the hosted service, and moves out once there is a need to use it in other services.

**The lib layer is meant to be exported as an external lib, and an external lib can have its own service layer.** A `service.ts` file inside `lib/<vendor>/` is that wrapper library's own service: its operational API (`dockerodeService`, `rmqService`, `typeormService` exported as singleton objects). This convention is legitimate; the general ban on the `-service` suffix applies to other lib file names, not to this file.

The contrast that shows the boundary: `lib/typeorm/` is the DataSource and migration checker (pure infrastructure, zero domain knowledge), while `business/component/data-store/` holds `CommonRepo`/`ICommonDal`/`TypeormCommonDal`/`MemoryCommonDal` (domain-aware: pagination models, entity events). Both wrap TypeORM; only one knows the domain.

**`src/lib/` vs `src/util/`:**
- `src/lib/` - wraps a third-party library or infrastructure, or reads/talks to an external system, not domain-aware, destined for a shared package
- `src/util/` - project-local pure utility functions, generic over their inputs (stateless helpers that belong to this service)
- When unsure, prefer `src/util/`

```
✅ src/lib/typeorm/service.ts            # The TypeORM wrapper lib's own service
✅ src/lib/typeorm/table-name-mapper.ts  # Table-name mapping
✅ src/lib/rmq/connection.ts             # RabbitMQ connection singleton
```

### Package-Private Wiring (`src/__internal__/`)

Shared packages (common, node-common, react-common) keep package-private wiring in `src/__internal__/`, mirroring the shapes it supports (`__internal__/business/`, `__internal__/lib/`, `__internal__/util/`, `__internal__/dal/`): config setters, logger factories, internal repo singletons. The folder tells consumers "exported by the package, not for direct import inside it". Only shared libraries need it; a service or app package does not.

## Module Export Pattern

### Rule: ONE Export Per File (Service/Component Pattern)

**NEVER export multiple standalone functions from a single file.**

When you have related functions, they MUST be grouped into a singleton service object.

### Wrong: Multiple Standalone Exports

```typescript
// ❌ WRONG: src/yaml/types/regex-parser.ts
export function parseRegex(value: unknown): RegExp | null {
  // ...
}

export function isRegexString(value: unknown): value is string {
  // ...
}
```

**Problems with this approach:**
- Violates one-element-per-file principle
- Functions are not grouped logically
- Harder to mock in tests
- Inconsistent with architecture patterns

### Correct: Singleton Service Object

```typescript
// ✅ CORRECT: src/business/service/regex-parser-service.ts
export const regexParserService = {
  parse(params: { value: unknown }): RegExp | undefined {
    const { value } = params

    if (typeof value !== 'string') {
      return undefined
    }

    const match = constant.regex.regexLiteralRegex.exec(value)
    if (!match) {
      return undefined
    }

    const pattern = match[2]
    if (pattern === undefined) {
      return undefined
    }

    const flags = match[4] ?? ''

    try {
      return new RegExp(pattern, flags)
    } catch {
      return undefined
    }
  },

  isString(params: { value: unknown }): boolean {
    const { value } = params

    if (typeof value !== 'string') {
      return false
    }

    return constant.regex.regexLiteralRegex.test(value)
  },
}
```

The regex lives in `constant.ts` (`constant.regex.regexLiteralRegex`), not at the top of the service file.

**Benefits:**
- Single export per file
- Functions are logically grouped
- Easy to mock entire service
- Consistent with architecture
- Uses object params pattern

## Barrel Exports (index.ts)

### Rule: AVOID Barrel Exports for Business Logic

**Barrel exports** (re-exporting from index.ts) create implicit dependencies and make code harder to trace.

### Wrong: Barrel Export Pattern

```typescript
// ❌ WRONG: src/yaml/types/index.ts
export { parseRegex, isRegexString } from './regex-parser.js'
export { parseDate, isDateString } from './date-parser.js'
export { parseError, isErrorString } from './error-parser.js'

// This encourages importing from the barrel:
import { parseRegex, parseDate, parseError } from '#src/yaml/types/index.js'
```

**Problems with this approach:**
- Hides the actual source of functions
- Creates coupling between unrelated modules
- Makes tree-shaking less effective
- Violates one-element-per-file principle

### Correct: Direct Imports from Service Files

```typescript
// ✅ CORRECT: Import directly from service files
import { regexParserService } from '#src/business/service/regex-parser-service.js'
import { dateParserService } from '#src/business/service/date-parser-service.js'
import { errorParserService } from '#src/business/service/error-parser-service.js'

// Usage
const regex = regexParserService.parse({ value: input })
const date = dateParserService.parse({ value: input })
```

### When index.ts IS Acceptable

- **A strategy interface** in `business/component/<name>/index.ts` or `business/service/<name>/index.ts` (the interface only, not a barrel)
- **Type definitions** in `src/business/model/` (grouping related types)
- **Component entry files** for multi-backend components (`data-store/common.ts` re-exporting from `_common/`)
- **npm package entry points** (package.json "main" field)

## Decision Flowchart

```
I need to place new logic
    ↓
Is it domain-aware (imports business/model/, operates on domain shapes)?
    ├─ No
    │   ├─ Wraps a third-party library / infrastructure? → src/lib/<vendor>/
    │   ├─ Generic pure helper?                           → src/util/<name>-util.ts
    │   └─ Infrastructure contract interface?             → next to its implementation
    └─ Yes (business logic)
        ↓
        Does it need a public API + private internals in one folder?
        (runtime dispatch by type/kind/enum, grouped pluggables,
         orchestrator + private helpers, exclusive service pair,
         one contract with multiple backends)?
            ├─ Yes → src/business/component/<name>/
            └─ No
                ↓
                Is it a named workflow boundary for a controller?
                    ├─ Yes → src/business/use-case/<name>-use-case.ts
                    └─ No
                        ↓
                        Does it persist data (TypeORM/HTTP)?
                            ├─ Yes → src/business/repo/<name>-repo.ts
                            └─ No  → src/business/service/<name>-service.ts

I'm refactoring existing code to clean architecture
    ↓
Does the code already have a subfolder grouping?
    ├─ Yes → Move the ENTIRE subfolder to the target layer
    │        (e.g., src/formatting-strategy/ → src/business/service/formatting-strategy/)
    └─ No → Place in the correct layer as a flat file
```

## Parser/Utility Module Pattern

Parser modules and utility functions that perform transformations should be implemented as services, NOT as standalone functions.

### Example: Converting Parsers to Services

**Before (Wrong):**
```
src/yaml/types/
├── regex-parser.ts      # exports: parseRegex, isRegexString
├── date-parser.ts       # exports: parseDate, isDateString
├── error-parser.ts      # exports: parseError, isErrorString
├── promise-parser.ts    # exports: parsePromise, isPromiseString
└── index.ts             # barrel exports all functions
```

**After (Correct):**
```
src/business/service/
├── yaml-parser/                     # Subfolder groups all yaml parsers
│   ├── index.ts                     # YamlParserStrategy interface
│   ├── regex.ts                     # exports: YamlParserRegex
│   ├── date.ts                      # exports: YamlParserDate
│   ├── error.ts                     # exports: YamlParserError
│   ├── promise.ts                   # exports: YamlParserPromise
│   └── special-object.ts            # exports: YamlParserSpecialObject
└── secret-service.ts                # Unrelated service as flat file
```

### Service Template for Parsers

```typescript
// src/business/service/[name]-parser-service.ts
export const [name]ParserService = {
  parse(params: { value: unknown }): ParsedType | undefined {
    const { value } = params

    if (typeof value !== 'string') {
      return undefined
    }

    const match = constant.regex.[name]Regex.exec(value)
    if (!match) {
      return undefined
    }

    return { raw: match[0] }
  },

  isString(params: { value: unknown }): boolean {
    const { value } = params

    if (typeof value !== 'string') {
      return false
    }

    return constant.regex.[name]Regex.test(value)
  },
}
```

## Summary Checklist

Before creating a new file, verify:

- [ ] Is the location correct according to the directory structure and the domain-awareness criterion?
- [ ] Am I creating an arbitrary folder outside the allowed set (`app-boot`, `controller`, `business`, `dal`, `ui-component`, `util`, `lib`, `__internal__`, `asset`, `__tests__`)? → STOP. Business logic goes in `src/business/`, project-local helpers in `src/util/`, non-domain third-party wrappers in `src/lib/`
- [ ] Does this unit need a public API + private internals in one folder? → The WHOLE unit goes in `src/business/component/<name>/` (one of the four component shapes)
- [ ] Am I exporting multiple standalone functions? → STOP, group into a service object
- [ ] Am I using object params for all business-layer methods? → MUST use `{ param: value }` syntax (util and lib may go positional for 1-2 params)
- [ ] Am I creating a barrel index.ts? → Only for strategy interfaces, types, component entry files, or package entry points
- [ ] Does the file name use kebab-case? (A single leading `_` marking a private file is allowed.)
- [ ] Does the export use camelCase for singleton or PascalCase for class?
- [ ] Is an enum in `business/enum/` (not `model/`), one per file?
- [ ] Is a constant in `constant.ts` and an env value in `config.ts`, not declared at the top of this file?
- [ ] Is a test-only helper in `__tests__/` rather than next to production code?
- [ ] Does a `-util` file really hold generic logic (domain logic → service, external-system knowledge → lib)?
