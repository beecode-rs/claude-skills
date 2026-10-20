# Service Pattern

Services implement core business logic using **singleton objects**, **classes**, or **factory functions**. Part of the **Service Layer (SL)** in the Business Layer.

## Naming Convention

- **File:** `kebab-case` (e.g., `secret-service.ts`)
- **Export:** `camelCase` singleton OR `PascalCase` class
- **When to use class vs singleton:** see below

## Purpose

The Service Layer implements reusable, single-purpose business logic functions. It's framework-agnostic and focuses purely on business rules without transport or persistence concerns.

A service is domain-aware logic you call directly by name: a flat file with no private folder internals. The moment logic needs a public API plus private internals hidden in a folder, it is a component.

## The Three Service Shapes

| Shape | When | Examples |
|---|---|---|
| **Singleton object** | stateless namespace of related functions, no helpers needed | `passwordService`, `jwtService`, `enumService` |
| **Class** | constructor state (`protected readonly _` fields), `this`-chaining, extends a base, per-request context | `SecretService`, `GitService`, `AbstractSyntaxTreeService` |
| **Factory function** | builds a value or config, no methods on `this` | `authConfigFactory`, `dbConfigFactory`, `permissionService(): PermissionService` |

**The class is the splitting mechanism.** Measured across the etalon: class methods average 9.7 lines because they decompose into `protected _` helpers; singleton-object methods average 13.6; bare exported functions average 17.3. Reaching for the class is how this codebase makes room for helpers; a singleton object is a statement that no helpers are needed. Do not default to "singleton preferred": choose the class precisely when a body needs to be broken into named helpers or needs state.

## Structure

### Singleton Object Pattern

Use singleton objects when methods are independent and the logic is simple enough not to need helpers.

```typescript
// src/business/service/[domain]/[feature]-service.ts
import { nodeError } from '#src/util/error'
import { logger } from '#src/util/logger'

export const calculationService = {
  calculateTotal: async (params: { items: Item[] }): Promise<number> => {
    const { items } = params
    return items.reduce((sum, item) => { return sum + item.price }, 0)
  },

  calculateTax: async (params: { amount: number }): Promise<number> => {
    const { amount } = params
    return amount * 0.2
  },
}
```

**Usage:**

```typescript
const total = await calculationService.calculateTotal({ items })
```

### Class Pattern

Use classes when methods need to reference each other using `this`, the service carries constructor state, or bodies need `protected _` helpers. **Export the class itself, NOT an instantiated object.**

```typescript
// src/business/service/secret-service.ts
import { type SecretModel } from '@app/common/business/model/core/secret-model'
import { config } from '#src/util/config'
import { cryptoUtil } from '#src/util/crypto-util'

export class SecretService {
  decryptSecret(params: { secret: string }): string {
    const { secret } = params
    const { key } = config.projectSecret.encryption

    return cryptoUtil.decrypt({ key, text: secret })
  }

  decryptModelSecret(params: { model: SecretModel }): SecretModel {
    const { model } = params
    const decrypted = this.decryptSecret({ secret: model.secret })

    return { ...model, secret: decrypted }
  }

  encryptSecret(params: { secret: string }): string {
    const { secret } = params
    const { ivLength, key } = config.projectSecret.encryption

    return cryptoUtil.encrypt({ ivLength, key, text: secret })
  }
}
```

**Usage:**

```typescript
// ✅ CORRECT: Instantiate at the call site
const decryptedModel = await new SecretService().decryptModelSecret({ model })
```

**Anti-patterns to avoid:**

```typescript
// ❌ NEVER do this - don't export instantiated class objects
export const secretService = new SecretService()

// ❌ NEVER do this - don't export instantiated class objects
const service = new SecretService()
export { service as secretService }
```

A class that must have exactly one instance, because the instance holds memory (a cache, a running poll timer, open connections), lives in a `-singleton.ts` file as `_ClassName` with the accessor at the end:

```typescript
// src/business/service/sessions/service-singleton.ts
export class _SessionsService {
  protected _sessionById: Map<string, SessionModel> = new Map()
  ...
}

export const sessionsServiceSingleton = singletonPattern(() => {
  return new _SessionsService()
})

// Usage
sessionsServiceSingleton().fetchAll()
```

A service without such memory is not a singleton: instantiate it with `new` at the call site. When unsure, ask.

### Factory Function Pattern

Use a factory function when the export builds a value or config rather than exposing methods:

```typescript
// src/business/service/config/db-config-factory.ts
export const dbConfigFactory = (params: { env: Env }): DbConfig => {
  const { env } = params

  return { host: env.dbHost, port: env.dbPort }
}
```

Also covers service constructors that need per-app wiring: `permissionService()` returns the configured `PermissionService` instance.

## Key Characteristics

- **Choose the shape by need**: object for stateless simple logic, class for state/helpers/`this`-chaining, factory for value building
- Pure async functions/methods
- **Framework-agnostic**: No framework-specific code (Express, TypeORM, etc.)
- **Single-purpose**: Each function does one thing well
- **Clear naming**: Function names must clearly describe their purpose
- Handle business logic and validation
- Use the repository layer for persistence (direct DAL singletons only for infrastructure storage where no repo exists, see below)
- Use `logger()` for structured logging
- Use `nodeError` for error handling

## Service-to-Service Dependencies

Services MAY depend on other services, with a scope rule:

**Allowed:**
- **Facade/aggregation**: `tokenService` aggregating `accessTokenService` + `refreshTokenService`
- **Intra-subfolder composition**: services inside one `business/service/<name>/` subfolder composing each other
- **Same-domain chains within one package**: `astParseTagService` calling `astParseService`

**Not allowed:**
- Depending on services from **other packages** (cross-package coupling goes through exported contracts, not internal service files)
- **Cross-domain orchestration**: sequencing operations from different business domains is what use-cases are for
- Calling controllers (the business layer never calls the controller layer)

## The Exclusivity Check

On every service-to-service dependency, run this check:

1. `aService` depends on `bService`.
2. `aService` is the outside boundary: the controller layer calls it.
3. A full usage scan shows `bService` is not called anywhere else: no other service, component, use-case, repo, or controller imports it, and every one of its functions is reached only through `aService`.

When all three hold, the dependency is exclusive: `bService` exists only to serve `aService`, and the pair is one unit of business logic rather than two reusable services. **Suggest** moving both into the component layer as one encapsulated folder:

```
src/business/component/<name>/
├── service.ts        # aService, the public entry point the controller keeps calling
└── _b-service.ts     # bService, renamed with the _ prefix, private to the folder
```

Guard rails:

- **A suggestion, not a mandate**: a pair that stays in `business/service/` is not a violation
- **Same domain only**: never group services from different domains into one folder just because one calls the other; that is what use-cases are for
- **Exclusivity is the trigger**: if `bService` has any other caller anywhere (including any component), the dependency is ordinary same-package composition and stays as-is

## Fetch What You Need; Don't Receive It

When a service can get a value itself, it does, instead of requiring every caller to fetch and pass it. A scheduling service that needs the current settings calls `settingsRepoSingleton().fetch()`; it does not take `params: { settings }`. Passing shared state down as a parameter makes every caller responsible for having fresh data, and callers drift (one passes a stale copy, another re-fetches). Params are for what the *caller* decides (which trigger, which provider), not for data the service can reach through an import.

## Collaborators Come From Imports

Services import the modules they use (`import { settingsRepoSingleton } from '#src/business/repo/settings-repo-singleton'`) and create owned instances in protected field initializers. They never receive services, repos, or DALs through constructor params.

## No Constants in Service Files

A hardcoded limit, timeout, or regex at the top of a service file (`const CACHE_ENTRY_LIMIT = 50`) moves to `util/constant.ts` under a key that names its owner (`constant.sessionTranscript.cacheEntryLimit`). An env-tunable value goes to `util/config.ts`.

## Direct DAL Access

The default is data access through the Repository Layer. One tolerated exception: **infrastructure-ish storage with no repo layer for that concern** may be accessed via a DAL singleton directly (`storageDalSingleton` for localStorage, `shellDalSingleton` for shell execution). If a repo layer exists for the data, use it.

## Null vs Undefined

**Business Layer uses `undefined` only - never `null`.**

```typescript
// ✅ CORRECT: Use undefined for optional values
async getById(params: { id: string }): Promise<UserModel | undefined>

// ❌ WRONG: Never use null in business layers
async getById(params: { id: string }): Promise<UserModel | null>
```

**Why:** `undefined` is the TypeScript convention for missing values. `null` is reserved for the DAL/Entity layer (database compatibility with TypeORM).

## Service Subfolders

Two or more services sharing an interface, a shape, or forming a composition chain get a subfolder in `business/service/`; a standalone service stays flat:

| Subfolder | Why it is a folder |
|---|---|
| `puml-format/` (+ `element/`) | stateful value-object classes composing each other via inline `new` |
| `ast-parse/` | same-domain cluster with an interface in `index.ts` and internal cross-calls |
| `token/` | 3 services with an identical get/store/clear/onChange shape for different storage keys |
| `config/` | 4 pure factory functions with the same `{ env }` signature |
| `sessions/` (+ `focus/`) | one domain split into focused services; file names drop the `sessions-` prefix, export names keep it (`sessions/poll-service.ts` → `SessionsPollService`) |

A large service file (one class doing transcript parsing, polling, focusing, and SSH) is split into a domain folder of single-purpose services, and only the service that actually holds memory keeps the singleton.

A tightly-coupled interface may live inside the subfolder as its `index.ts` instead of `business/model/`. A shared React concern goes in `business/hook/`.

## Architectural Rules

### ✅ DO

- **Pick the shape by need**: singleton object (stateless, no helpers), class (state, `this`-chaining, `protected _` helpers), factory (builds a value)
- **Use `undefined` for optional/missing values** - never `null`
- Compose other services within the same package/subfolder/domain
- Run the exclusivity check on service-to-service dependencies and suggest the component folder when it triggers
- Keep services reusable across different contexts
- Name functions descriptively (e.g., `validateAndProcessOrder`, `calculateTotalPrice`)
- Use the Repository Layer for persistence (DAL singletons only for infrastructure storage with no repo)
- Instantiate service classes with `new ServiceName()` at the call site

### ❌ DON'T

- Include transport-specific logic (HTTP, SQS, etc.)
- Depend on services from other packages
- Orchestrate across business domains (use a use-case)
- Call controllers
- Use console.log (use logger instead)
- Use the `private` keyword (encapsulation is `protected` + single `_` prefix)
- Receive services, repos, or DALs through constructor params (import them)
- Take data as a param that the service can fetch itself (settings, current state)
- Declare module-level constants (they belong in `constant` / `config`)
- Mutate the objects passed in (return new values)
- **Export instantiated class objects** - `export const x = new X()` is an anti-pattern; export the class and instantiate at the call site, or use `singletonPattern(() => new X())` for a true singleton
- **Use `null`** - always use `undefined` for optional/missing values in business layers
