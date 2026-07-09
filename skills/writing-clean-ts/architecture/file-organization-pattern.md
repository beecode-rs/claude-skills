# File Organization Pattern

This document defines where files must be placed and how modules should be structured. Following these rules prevents misplaced code and maintains architectural integrity.

## Directory Structure

### Backend Structure

```
src/
├── app-boot/                    # Application initialization and lifecycle
├── controller/
│   ├── express/                 # REST API handlers
│   └── react-router/            # Frontend route controllers
├── business/
│   ├── component/               # Complex domain logic (state machines, validators)
│   ├── service/                 # Simple business logic functions
│   ├── use-case/                # Orchestration of multiple services
│   ├── repo/                    # Repository classes
│   └── model/                   # Type definitions and models
├── dal/
│   └── typeorm/
│       ├── entity/              # TypeORM entities
│       └── *-dal.ts             # Data Access Layer classes
├── ui-component/                # React UI components
├── util/                        # Pure utility functions (project-local, NO business logic)
└── lib/                         # Reusable infrastructure (NO business logic) — staging area until extracted to a shared package
```

### Where to Place Code

| Code Type | Location | Example Path |
|-----------|----------|--------------|
| REST API endpoint | `src/controller/express/` | `src/controller/express/get-projects-all.ts` |
| Business logic (simple) | `src/business/service/` | `src/business/service/calculation-service.ts` |
| Business logic (complex) | `src/business/component/` | `src/business/component/invoice-status/` |
| Orchestration | `src/business/use-case/` | `src/business/use-case/auth-use-case.ts` |
| Data access | `src/business/repo/` | `src/business/repo/project-repo.ts` |
| Database operations | `src/dal/typeorm/` | `src/dal/typeorm/project-dal.ts` |
| Database entities | `src/dal/typeorm/entity/` | `src/dal/typeorm/entity/project-entity.ts` |
| Type definitions | `src/business/model/` | `src/business/model/project-model.ts` |
| React components | `src/ui-component/` | `src/ui-component/project-list.tsx` |
| Pure utilities | `src/util/` | `src/util/date-util.ts` |
| Reusable infrastructure (no business logic, multi-microservice, destined for extraction) | `src/lib/` | `src/lib/typeorm/index.ts` |

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
| Multiple implementations of one interface | Subfolder | `src/business/service/formatting-strategy/json.ts` |
| Preconfigured entry points (presets) | Subfolder in controller | `src/controller/preset/console-simple-string.ts` |
| Domain with multiple endpoints | Subfolder in controller | `src/controller/express/project/get-projects-all.ts` |

### Strategy Pattern Example

When a concept has an interface and multiple implementations, the interface can either live in `model/` or stay inside the subfolder alongside its implementations.

**Option A — Interface in model/ (when interface is used broadly):**
```
src/business/
├── model/
│   └── formatting-strategy.ts          # FormattingStrategy interface
└── service/
    └── formatting-strategy/
        ├── json.ts                     # FormattingStrategyJson class
        └── simple-string.ts            # FormattingStrategySimpleString class
```

**Option B — Interface in subfolder (when interface is tightly coupled to implementations):**
```
src/business/service/
└── formatting-strategy/
    ├── formatting-strategy.ts          # FormattingStrategy interface
    ├── json.ts                         # FormattingStrategyJson class
    └── simple-string.ts               # FormattingStrategySimpleString class
```

Both options are valid. Choose Option A when other layers import the interface independently. Choose Option B when the interface is only meaningful within the context of its implementations.

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

### Mock and Test Placement in Subfolders

Mocks and tests follow their source files into the subfolder:

```
src/business/service/
└── formatting-strategy/
    ├── json.ts
    ├── json.test.ts
    ├── simple-string.ts
    ├── simple-string.test.ts
    └── __mocks__/
        └── formatting-strategy-mock.ts
```

## CRITICAL: Forbidden Locations

**NEVER create arbitrary top-level folders outside the defined structure.** The allowed top-level folders under `src/` are: `app-boot/`, `controller/`, `business/`, `dal/`, `ui-component/`, `util/`, and `lib/`. `src/lib/` is explicitly allowed — it holds reusable, non-business-logic infrastructure staged for extraction into a shared package (see "Reusable Infrastructure (`src/lib/`)" below). Any other folder at the `src/` level that does not map to a known layer is forbidden. Subfolders *within* layers are encouraged for grouping related files.

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
✅ src/business/component/special-object-parser/
✅ src/controller/preset/console-simple-string.ts          # Subfolder grouping related presets
✅ src/util/date-util.ts
✅ src/business/model/yaml-contract-model.ts
```

### Reusable Infrastructure (`src/lib/`)

`src/lib/` is the one top-level folder reserved for code that:
- Contains **no business logic**
- Can has a potential to be **reusable across multiple microservices**
- Is **destined to be extracted** into a shared common package (`@app/node-common/`, `@app/common/`) or an external library

It is a staging area: code lives here while it is only being used by the hosted service, and moves out once there is a need to be used by other services.

**`src/lib/` vs `src/util/`:**
- `src/util/` — project-local pure utility functions (stateless helpers that belong to this service)
- `src/lib/` — reusable infrastructure written to be extracted into a shared package (TypeORM `DataSource`, RMQ connections, table mappers)
- When unsure, prefer `src/util/`

```
✅ src/lib/typeorm/index.ts              # TypeORM DataSource singleton
✅ src/lib/typeorm/table-name-mapper.ts  # Table-name mapping
✅ src/lib/rmq/connection.ts             # RabbitMQ connection singleton
```

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
  parse(params: { value: unknown }): RegExp | null {
    if (typeof params.value !== 'string') {
      return null
    }
    
    const match = REGEX_PATTERN.exec(params.value)
    if (!match) {
      return null
    }
    
    const pattern = match[2]
    if (pattern === undefined) {
      return null
    }
    
    const flags = match[4] ?? ''
    
    try {
      return new RegExp(pattern, flags)
    } catch {
      return null
    }
  },

  isString(params: { value: unknown }): params is string {
    if (typeof params.value !== 'string') {
      return false
    }
    
    return REGEX_PATTERN.test(params.value)
  },
}
```

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

**Problems:**
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

### When Barrel Exports ARE Acceptable

Barrel exports are acceptable ONLY for:
- **Type definitions** in `src/business/model/` (grouping related types)
- **Public API of a component** (`src/business/component/*/index.ts`)

## Decision Flowchart

```
I need to create a new file with functions
    ↓
What kind of logic is this?
    ├─ HTTP request handling → src/controller/express/
    ├─ Database operations → src/dal/typeorm/
    ├─ Data transformation (no business rules) → src/util/
    ├─ Reusable infrastructure (no business rules, destined for a shared package) → src/lib/
    └─ Business logic (has rules/validation) → src/business/
        ↓
    How complex is it?
        ├─ Simple functions (1-2 functions) → src/business/service/
        │   └─ Export as singleton object
        ├─ Complex state/rules (3+ states) → src/business/component/
        │   └─ Export via index.ts public API
        └─ Orchestrates multiple services → src/business/use-case/
            └─ Export as singleton object

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
│   ├── regex.ts                     # exports: YamlParserRegex
│   ├── date.ts                      # exports: YamlParserDate
│   ├── error.ts                     # exports: YamlParserError
│   ├── promise.ts                   # exports: YamlParserPromise
│   ├── special-object.ts            # exports: YamlParserSpecialObject
│   └── index.ts                     # Re-exports for convenience
└── secret-service.ts                # Unrelated service as flat file
```

### Service Template for Parsers

```typescript
// src/business/service/[name]-parser-service.ts

const PATTERN = /^...$/

export const [name]ParserService = {
  parse(params: { value: unknown }): ParsedType | null {
    if (typeof params.value !== 'string') {
      return null
    }
    
    const match = PATTERN.exec(params.value)
    if (!match) {
      return null
    }
    
    // Extract and return parsed value
    return createParsedValue(match)
  },

  isString(params: { value: unknown }): params is string {
    if (typeof params.value !== 'string') {
      return false
    }
    
    return PATTERN.test(params.value)
  },
}
```

## Summary Checklist

Before creating a new file, verify:

- [ ] Is the location correct according to the directory structure?
- [ ] Am I creating an arbitrary folder outside the allowed set (`app-boot`, `controller`, `business`, `dal`, `ui-component`, `util`, `lib`)? → STOP. Business logic goes in `src/business/`, project-local helpers in `src/util/`, reusable extractable infrastructure in `src/lib/`
- [ ] Am I exporting multiple standalone functions? → STOP, group into a service object
- [ ] Am I using object params for all service methods? → MUST use `{ param: value }` syntax
- [ ] Am I creating a barrel export (index.ts)? → Only for types or component public API
- [ ] Does the file name use kebab-case? (A single leading `_` marking a private file is allowed.)
- [ ] Does the export use camelCase for singleton or PascalCase for class?
