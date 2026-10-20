# Class vs Plain Object Decision Guide

This guide helps you choose between **classes** and **plain objects** (camelCase object literals, often called "singleton objects" in older docs), and when a class earns the `singletonPattern`.

## Quick Decision Tree

```
Does the layer REQUIRE a specific pattern?
├─ Yes → Follow the layer's requirement
│   ├─ Repository → ALWAYS class
│   ├─ DAL → ALWAYS class
│   ├─ Entity → ALWAYS class
│   ├─ Life cycle (app-boot) → ALWAYS class (extends msh LifeCycle)
│   ├─ Use Case → ALWAYS plain object (stateless)
│   └─ Handler → ALWAYS plain object
│
└─ No (Service, Util, Lib) → Choose based on what the code needs
    ├─ Needs helper functions? → Helpers become protected `_` methods → class
    ├─ Methods call each other via `this`, or carry constructor state? → class
    ├─ Builds a value/config, no methods on `this`? → factory function
    └─ Methods independent, logic simple, no helpers? → plain object

Is it a class that must have exactly ONE instance?
├─ Does the instance hold memory a fresh instance would not have
│  (cached data, subscriptions, a window handle, loaded settings)?
│   ├─ Yes → `_ClassName` + `singletonPattern` accessor in one `-singleton.ts` file
│   └─ No  → no singleton: `new ClassName()` at the call site
```

## Layer-Specific Requirements

### Always Use Classes

| Layer | Reason | Example |
|-------|--------|---------|
| **Repository** | Holds its DAL as a protected field, may extend a common repo | `export class ProjectRepo` |
| **DAL** | Extends or composes a common DAL for its storage framework | `export class ProjectDal` |
| **Entity** | ORM requirement (TypeORM decorators) | `export class ProjectEntity` |
| **Life cycle** | Extends msh `LifeCycle` (`_createFn` / `_destroyFn`) | `export class SettingsLifeCycle` |

### Always Use Plain Objects

| Layer | Reason | Example |
|-------|--------|---------|
| **Use Case** | Stateless call; prevents nesting use cases within other use cases | `export const authUseCase` |
| **Handler** | Simple object with handler and schema properties | `export const getProjectsAll` |

A use case is a stateless call: a plain object literal, never a class, and never wrapped in `singletonPattern`. There is nothing to keep between calls, so there is nothing for a singleton to hold.

### Choose Based on Implementation

| Pattern | When to Use | Example |
|---------|-------------|---------|
| **Plain Object** | Methods are independent, no state, no helpers needed | `export const calculationService` |
| **Class** | Constructor state (`protected readonly _` fields), methods reference each other via `this`, needs `protected _` helper decomposition, extends a base, or per-request context | `export class SecretService` |
| **Factory Function** | Builds a value or config; no methods on `this` | `export const dbConfigFactory` |

**Roughly half of real services are classes.** "Plain object preferred" is misleading: measured across the etalon, class methods average 9.7 lines because they decompose into `protected _` helpers, while plain-object methods average 13.6 and stay whole. Reaching for the class is how this codebase makes room for helpers; a plain object is a statement that the logic is simple enough not to need them.

## Helper Functions Mean Class

A file exports exactly **one element** (a class or a plain object) and **never declares module-level (root-of-file) helper functions alongside it**. Any helper becomes a `protected` method with a single underscore prefix, called via `this`:

```typescript
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

**A plain object never has `_` members.** An object literal cannot hide anything: an `_parse` property on a plain object is still public, still callable by every consumer, and the underscore is only a hope. So when a plain object has (or needs) `_`-prefixed functions, convert it to a class and make each of them `protected`:

```typescript
// ❌ WRONG - "private" helpers on a plain object are still public
export const versionCompareUtil = {
  isNewerVersion(params: { current: string; candidate: string }): boolean {
    const { current, candidate } = params

    return versionCompareUtil._compare(candidate, current) > 0
  },
  _compare(left: string, right: string): number { ... },
}

// ✅ CORRECT - class with a protected helper
export class VersionCompareUtil {
  isNewerVersion(params: { current: string; candidate: string }): boolean {
    const { current, candidate } = params

    return this._compare(candidate, current) > 0
  }

  protected _compare(left: string, right: string): number { ... }
}
```

This applies to every layer (services, utils, libs), not only services.

**Object params on helper methods**: The object-params rule governs the public API. `protected _` helpers are internal implementation detail, so a single positional domain value is acceptable (e.g. `_decryptData(data?: string)`, matching the class service template); multiple inputs still use object params.

## No Constructor Dependency Injection

Collaborators (services, repos, DALs, libs) are never passed in through constructor params. A module that needs `fooService` imports it with a normal `import`; a class that needs its own instance of a collaborator creates it in a protected field initializer:

```typescript
// ❌ WRONG - collaborators injected through the constructor
export class TriggerRunnerService {
  constructor(
    protected readonly _settingsRepo: SettingsRepo,
    protected readonly _schedulingService: SchedulingService,
  ) {}
}

// ✅ CORRECT - node import for shared modules, field initializer for owned instances
import { schedulingServiceSingleton } from '#src/business/service/scheduling-service-singleton'
import { SettingsDal } from '#src/dal/settings-dal'

export class SettingsRepo {
  protected readonly _dal: ISettingsDal = new SettingsDal()
}
```

Why: constructor injection spreads wiring across every call site (`new TriggerRunnerService(new SettingsRepo(new SettingsDal()), ...)`), hides which module a class really depends on, and adds nothing tests need, because contract tests and Vitest mock modules directly. The import line is the single, searchable statement of the dependency.

**Constructors take configuration values only**: a file path, a `fixedFilter`, a `projectId`. When a base class needs a collaborator through `super(...)`, build it inside the constructor from those config values instead of accepting it as a param:

```typescript
export class ProjectRepo extends CommonRepo<...> {
  constructor(params: { fixedFilter?: object } = {}) {
    const { fixedFilter } = params

    super({ dal: new ProjectDal({ fixedFilter }) })
  }
}
```

## Pattern Details

### Class Services: Constructor, Singleton, and Factory Patterns

#### Constructor Initialization

If a class needs logic to run before first use, use the constructor. Defaults go in the signature:

```typescript
export class ClassService {
  protected readonly _memory: { [k: string]: string }

  public constructor(params: { initialMemory?: { [k: string]: string } } = { initialMemory: {} }) {
    const { initialMemory } = params

    this._memory = { ...initialMemory }
  }

  protected _methodOne(): string {
    return this._memory['one']
  }

  public methodTwo(): string {
    return this._methodOne() + this._memory['two']
  }
}
```

**Important:** Constructors cannot use async functions.

#### Factory Pattern

Use a factory function to create new instances with the same parameters as the constructor. Name it with the class name in camelCase plus the `Factory` suffix:

```typescript
export const classServiceFactory = (
  ...params: ConstructorParameters<typeof ClassService>
): ClassService => {
  return new ClassService(...params)
}
```

**When to use:** When you need multiple independent instances or when refactoring from a plain object to a class (avoids adding `new` keyword everywhere).

#### Singleton Pattern

A singleton is justified by **memory**: the instance holds something a fresh instance would not have (loaded settings, a cache, active subscriptions, a window handle, a running poll timer). If `new X()` would behave exactly like the shared instance, the singleton adds nothing but indirection: remove it and instantiate at the call site. When unsure whether a class holds such memory, ask.

The class and its accessor live in **one** `<name>-singleton.ts` file. The class is exported with a leading `_` so nobody instantiates it directly; the accessor comes last:

```typescript
// src/business/repo/settings-repo-singleton.ts
import { singletonPattern } from '@beecode/msh-util/singleton/pattern'

export class _SettingsRepo {
  protected readonly _dal: ISettingsDal = new SettingsDal()
  ...
}

export const settingsRepoSingleton = singletonPattern(() => {
  return new _SettingsRepo()
})

// Usage
settingsRepoSingleton().fetch()
```

**CRITICAL: Never export instantiated objects directly.** If you need singleton behavior, ALWAYS use `singletonPattern` from `@beecode/msh-util/singleton/pattern` - never `export const x = new X()`.

#### Handling Async Initialization

Constructors cannot be async. Do not make every call async just because loading happens once. Instead, give the singleton one async `init()` that app boot calls, and keep every other method sync:

```typescript
// src/business/repo/settings-repo-singleton.ts
export class _SettingsRepo {
  protected readonly _dal: ISettingsDal = new SettingsDal()

  async init(): Promise<void> {
    const rawSettings = await this._dal.readSettingsFile()
    await this._dal.writeSettings({ settings: new SettingsModel({ rawSettings }) })
  }

  fetch(): SettingsModel {
    const settings = this._dal.readSettings()
    if (!settings) {
      throw new Error('settings are not initialized')
    }

    return settings
  }
}

// src/app-boot/life-cycle/settings-life-cycle.ts
export class SettingsLifeCycle extends LifeCycle {
  protected async _createFn(): Promise<void> {
    await settingsRepoSingleton().init()
  }
}

// Everywhere else - sync
const settings = settingsRepoSingleton().fetch()
```

The async work happens once, in the app-boot layer, and the rest of the application reads synchronously.

#### Naming Conventions for Class Services

```typescript
// ❌ WRONG - unclear what this returns
export const classService = (): ClassService => {
  return new ClassService()
}

// ✅ CORRECT - the suffix states the instantiation pattern
export const classServiceFactory = (...params: ConstructorParameters<typeof ClassService>): ClassService => {
  return new ClassService(...params)
}

export const classServiceSingleton = singletonPattern(() => {
  return new _ClassService()
})
```

### Plain Object Pattern

**When to use:**
- ✅ Methods are completely independent
- ✅ No shared internal state needed
- ✅ No helper functions needed (a module that needs helpers is a class - see "Helper Functions Mean Class")
- ✅ You want to prevent reuse (use cases in other use cases)

**Instantiation:** None needed - import and use directly

```typescript
export const calculationService = {
  calculateTotal(params: { items: Item[] }): number {
    const { items } = params

    return items.reduce((sum, item) => {
      return sum + item.price
    }, 0)
  },

  calculateTax(params: { amount: number }): number {
    const { amount } = params

    return amount * constant.tax.rate
  },
}

// Usage
const total = calculationService.calculateTotal({ items })
```

### Class Pattern

**When to use:**
- ✅ Methods need to reference each other via `this`
- ✅ The module needs helper functions (they become `protected _` methods called via `this`)
- ✅ Working with ORM patterns (entities) or extending a base class (repos, DALs, life cycles)
- ✅ You need constructor logic or per-instance state

**Instantiation:** `new ClassName()` at the call site (or the `-singleton` accessor when the instance holds memory)

```typescript
export class SecretService {
  decryptSecret(params: { secret: string }): string {
    const { secret } = params
    // implementation
  }

  decryptModelSecret(params: { model: SecretModel }): SecretModel {
    const { model } = params

    return { ...model, secret: this.decryptSecret({ secret: model.secret }) }
  }
}

// Usage
const result = new SecretService().decryptModelSecret({ model })
```

## Special Case: Use Cases

**Use cases are always stateless plain objects.** They orchestrate services and repositories, never other use cases, and they keep nothing between calls. Code that runs once at application startup (loading settings, registering handlers, seeding state) is not a use case at all: it is an app-boot life cycle.

```typescript
// ✅ CORRECT - stateless plain object, collaborators imported
export const orderUseCase = {
  async processOrder(params: { orderId: string }): Promise<void> {
    const { orderId } = params

    await orderService.validate({ orderId })
    await paymentService.charge({ orderId })
    await notificationService.send({ orderId })
  },
}

// ❌ INCORRECT - class use case (invites state, helpers, and reuse in other use cases)
export class OrderUseCase { ... }

// ❌ INCORRECT - use case wrapped in a singleton (nothing to remember between calls)
export const orderUseCaseSingleton = singletonPattern(() => {
  return new OrderUseCase()
})
```

## Common Mistakes

### ❌ Module-Level Helper Functions Next to an Export

```typescript
// ❌ WRONG - helper function at module scope, outside the service
const parseUser = (raw: RawUser): UserModel => {
  return { id: raw.id, name: raw.userName }
}

export class UserService {
  getUser(params: { id: string }): UserModel {
    const { id } = params

    return parseUser(fetchRaw(id))
  }
}

// ✅ CORRECT - helper is a protected _ member of the class
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

### ❌ `_` Members on a Plain Object

See "Helper Functions Mean Class": convert the object to a class and make the `_` members `protected`.

### ❌ Using a Class for a Simple Module

```typescript
// ❌ WRONG - no state, no helpers, no this
export class CalculationService {
  calculateTotal(params: { items: Item[] }): number { ... }
}

// ✅ CORRECT - plain object
export const calculationService = {
  calculateTotal(params: { items: Item[] }): number { ... },
}
```

### ❌ Plain Object Whose Methods Need Each Other

```typescript
// ❌ WRONG - self-reference by export name
export const secretService = {
  decryptSecret(params: { secret: string }): string { ... },
  decryptModelSecret(params: { model: SecretModel }): SecretModel {
    const { model } = params

    return { ...model, secret: secretService.decryptSecret({ secret: model.secret }) }
  },
}

// ✅ CORRECT - class, reached via this
export class SecretService { ... }
```

### ❌ Singleton Without Memory

```typescript
// ❌ WRONG - the instance holds nothing a new one would not have
export const updateServiceSingleton = singletonPattern(() => {
  return new UpdateService()
})

// ✅ CORRECT - instantiate at the call site
await new UpdateService().checkForUpdate()
```

### ❌ Class and Singleton in Two Files

`app-window-store.ts` (class) + `app-window-store-singleton.ts` (accessor) is one thing split in two. Merge them into `app-window-store-singleton.ts` with `export class _AppWindowStore` and the accessor at the end.

### ❌ Constructor Dependency Injection

See "No Constructor Dependency Injection": import collaborators, or create owned instances in field initializers.

### ❌ Exporting Instantiated Class Objects

```typescript
// ❌ WRONG
export const secretService = new SecretService()
const service = new SecretService()
export { service as secretService }

// ✅ CORRECT - export the class, instantiate at the call site
const result = new SecretService().decryptSecret({ secret })

// ✅ CORRECT - one instance holding memory: _Class + singletonPattern
export const secretServiceSingleton = singletonPattern(() => {
  return new _SecretService()
})
```

**Why this matters:** Exported instances hide dependencies, make testing harder, and create implicit singletons that nobody decided were needed.

## Summary Table

| Layer | Pattern | Flexibility | Naming Convention |
|-------|---------|-------------|-------------------|
| **Service** | Plain object, class, or factory | Choose by helpers/state | `camelCase` or `PascalCase` |
| **Util / Lib** | Plain object or class | Choose by helpers/state | `camelCase` or `PascalCase` |
| **Repository** | Class (mandatory) | No choice | `PascalCase` |
| **Use Case** | Plain object (mandatory, stateless) | No choice | `camelCase` |
| **DAL** | Class (mandatory) | No choice | `PascalCase` |
| **Entity** | Class (mandatory) | No choice | `PascalCase` |
| **Life cycle** | Class (mandatory) | No choice | `PascalCase` + `LifeCycle` |
| **Handler** | Plain object (mandatory) | No choice | `camelCase` |
| **Any one-instance class with memory** | `_Class` + `singletonPattern` in `-singleton.ts` | Only with memory | `_PascalCase` + `camelCaseSingleton` |
