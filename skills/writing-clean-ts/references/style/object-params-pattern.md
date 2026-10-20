# Object Params Pattern

## Overview

Pass parameters as object properties instead of multiple individual parameters. This improves code readability, maintainability, and makes function calls self-documenting.

Three rules shape every params object:

1. **Business logic always takes a params object**, even for one value
2. **Destructure on the first body line** and never read `params.x` afterwards
3. **Defaults live in the signature**, never in the destructuring line

## Quick Decision Tree

```
Is this a Business Logic Layer?
(Service/Repository/Use Case/Component/DAL/Controller)
  ├─ Yes → ALWAYS use object params (even for 1 parameter)
  └─ No (Utility or Lib layer)
      ↓
  One or two parameters?
      ├─ Yes → Positional params are fine (an object stays welcome
      │        when names are not obvious from the call)
      └─ No (3+ parameters, or names not obvious)
          ↓
          → USE object params
```

## Rules by Layer

### ✅ ALWAYS Use Object Params (Business Logic Layers)

These layers MUST use object params for **ALL functions** (including single parameter):

- **Service Layer** - Business logic methods
- **Repository Layer** - Data access methods
- **Use Case Layer** - Orchestration functions
- **Component Layer** - Complex domain logic
- **DAL Layer** - Database access methods
- **Controller Layer** - Request handlers (except framework signatures)

**Why:**
- Business logic changes frequently - today's single parameter often becomes multiple parameters
- Consistency across the business layer makes code more predictable
- Easier to extend without breaking changes
- Self-documenting at call sites

### 🤔 Optional (Utility and Lib Layers)

A params object is optional when the function needs one or two params. Positional params are fine there; the object remains welcome when names are not obvious from the call. Both shapes coexist legitimately:

```typescript
stringUtil.camelCase(name)                                              // positional
stringUtil.uniqueEntityHash(params: { name; uniquePath })               // object
timeUtil.dateTimeISOToDate(dateTimeISO)                                 // positional
timeUtil.unixToFormat(params: { unix; dateTimeFormat?; timeZone? })     // object
```

**Use object params when:**
- Parameter names are NOT obvious from the function name
- Parameters are of similar types (multiple strings, multiple numbers)
- Parameters might need to grow or change

**Positional is fine when:**
- Function name clearly implies parameter names (e.g., `truncate(text, maxLength)`)
- Single-value transforms (`camelCase(name)`, `dateTimeISOToDate(dateTimeISO)`)
- AST/library node params, framework signatures, storage CRUD with one string

### ❌ Never Use Positional-Only Workarounds

- **Framework signatures** are respected as-is (Express middleware `(req, res, next)`, React callbacks), but that is the only place a business-layer signature bends

## Destructure on the First Line

The first line of the body destructures the params object. After that line, the body works with plain local names and never reads `params.x`:

```typescript
// ❌ WRONG - dot-reads scattered through the body
editTrigger(params: { triggerId: string; preset: ScheduleTriggerPreset }): ScheduleTriggerModel {
  const trigger = this._findTrigger(params.triggerId)
  if (!trigger) {
    throw new Error(`unknown trigger: ${params.triggerId}`)
  }

  return { ...trigger, preset: params.preset }
}

// ✅ CORRECT - one destructuring line, then plain names
editTrigger(params: { triggerId: string; preset: ScheduleTriggerPreset }): ScheduleTriggerModel {
  const { triggerId, preset } = params

  const trigger = this._findTrigger(triggerId)
  if (!trigger) {
    throw new Error(`unknown trigger: ${triggerId}`)
  }

  return { ...trigger, preset }
}
```

Why: the destructuring line is the function's input list. A reader sees everything the function uses in one place, and an unused key shows up as an unused variable. Scattered `params.x` reads hide which inputs matter and invite accidental mutation of the caller's object.

- It applies to `props` in React components the same way: `const { size, onClose } = props` on the first line
- When a destructured name would shadow an outer binding, rename it in the destructure (`const { settings: nextSettings } = params`) instead of falling back to `params.settings`
- Passing the whole object straight through is fine (`return this._repo.save(params)`): that is not a dot-read

## Defaults Live in the Signature

A default value is part of the function's contract, so it goes in the args section, where callers and readers look for it. The destructuring line stays a plain destructure with no `= value` defaults:

```typescript
// ❌ WRONG - default hidden in the destructuring line
resolve(params?: { platform?: OS }): SchedulingStrategy {
  const { platform = osUtil.resolvePlatform() } = params ?? {}
  ...
}

// ❌ WRONG - default merged in the body
resolve(params: { platform?: OS }): SchedulingStrategy {
  const { platform } = { platform: osUtil.resolvePlatform(), ...params }
  ...
}

// ✅ CORRECT - default in the args section, plain destructure in the body
resolve(params: { platform?: OS } = { platform: osUtil.resolvePlatform() }): SchedulingStrategy {
  const { platform } = params
  ...
}
```

The same shape applies to every function with defaults, including ones that mix required and optional keys, class constructors, and React components (which use `props`):

```typescript
findMany(params: { ownerId: string; limit?: number } = { ownerId: '', limit: constant.pagination.limit.default }): ProjectModel[] {
  const { ownerId, limit } = params
  ...
}

constructor(params: { settingsFilePath?: string } = { settingsFilePath: config.settings.filePath }) {
  const { settingsFilePath } = params
  ...
}

export const ProviderIcon = (props: { size?: number } = { size: constant.icon.size.default }): ReactElement => {
  const { size } = props
  ...
}
```

A signature default applies when the caller passes nothing for the whole object. A caller that passes a partial object (and React, which always passes a props object) gets `undefined` for the keys it leaves out. So optional keys stay typed optional (`limit?: number`), and the body handles `undefined` where it matters.

Default values that are business constants come from `constant` (`constant.pagination.limit.default`), not inline magic numbers.

## Never Mutate the Params

A function never changes the objects or arrays it receives. Build and return a new value instead (`{ ...trigger, preset }`, `[...items, item]`, `.map()`), so callers can trust that passing a value in does not change it.

## Callbacks

A callback may sit as the **second positional parameter next to a params object**. This is the established shape in lib and controller wiring, where the signature mirrors the underlying framework:

```typescript
// lib/rmq/controller-router-base.ts - and every controller/rmq router
route(filter: { appName?: string; action?: string }, callback: (payload: Payload) => Promise<void>): void

// util/controller-session.ts
entityManagerSideCall(entityManager: EntityManager, callback: () => Promise<void>): Promise<void>
startTransaction(callback: () => Promise<void>): Promise<void>
```

**In business logic, the callback goes INSIDE the params object under the key `callback`:**

```typescript
export const importService = {
  process(params: { path: string; callback: (entity: EntityModel) => void }): void {
    const { path, callback } = params

    const entities = entityParserService.parsePath({ path })
    entities.forEach(callback)
  },
}
```

Business logic owns its signature, so the object wins there; lib and controller wiring keep the positional form because the framework dictates it.

## Examples by Layer

| Layer | Function Example | Parameters | Use Object Params? | Reason |
|-------|------------------|------------|-------------------|---------|
| **Service** | `invoiceService.calculateTotal(items)` | 1 | ✅ YES | Business logic - ALWAYS |
| **Service** | `invoiceService.create(ownerId, amount, dueDate)` | 3 | ✅ YES | Business logic - ALWAYS |
| **Repository** | `projectRepo.findOneById(id)` | 1 | ✅ YES | Business logic - ALWAYS |
| **Repository** | `projectRepo.findByFilters(ownerId, status, date)` | 3 | ✅ YES | Business logic - ALWAYS |
| **Use Case** | `orderUseCase.processOrder(orderId, userId, items)` | 3 | ✅ YES | Business logic - ALWAYS |
| **Component** | `entityFormatStrategyService.entityToStrategy(entityType, entity)` | 2 | ✅ YES | Business logic - ALWAYS |
| **Controller** | `getProjectsAll.handler(req, res, next)` | 3 | ❌ NO | Framework signature |
| **Util** | `stringUtil.capitalize(str)` | 1 | ❌ NO | Utility - single param |
| **Util** | `stringUtil.truncate(text, maxLength)` | 2 | ❌ NO | Name implies params |
| **Util** | `stringUtil.wrap(text, prefix, suffix)` | 3 | ✅ YES | Not obvious from name |
| **Util** | `cryptoUtil.encrypt(data, key)` | 2 | ❌ NO | Name implies params |

## Pattern

### ❌ Multiple Parameters (Avoid)

```typescript
setupDatabase(host: string, port: number, databaseName: string): void

// Usage - unclear what each value represents
setupDatabase('localhost', 4567, 'core')
```

**Problems:**
- Parameter order must be memorized
- Easy to mix up similar types (strings, numbers)
- Adding parameters breaks existing calls
- Not self-documenting at call site

### ✅ Params Object (Preferred)

```typescript
setupDatabase(params: { host: string; port: number; databaseName: string }): void {
  const { host, port, databaseName } = params
  // some logic
}

// Usage - self-documenting and order-independent
setupDatabase({ host: 'localhost', port: 4567, databaseName: 'core' })
```

## Examples

### Service Layer

```typescript
// ❌ Avoid - positional params in business logic, even a single one
export const invoiceService = {
  calculateTotal(items: InvoiceItem[]): number { ... },
  create(ownerId: string, amount: number, dueDate: number, description: string): InvoiceModel { ... },
}

// ✅ Prefer - object params, destructured on the first line
export const invoiceService = {
  calculateTotal(params: { items: InvoiceItem[] }): number {
    const { items } = params
    // implementation
  },

  create(params: { ownerId: string; amount: number; dueAt: number; description: string }): InvoiceModel {
    const { ownerId, amount, dueAt, description } = params
    // implementation
  },
}

// Usage
invoiceService.calculateTotal({ items })
invoiceService.create({ ownerId: '123', amount: 100.5, dueAt: Date.now(), description: 'Monthly subscription' })
```

### Repository Layer

```typescript
export class ProjectRepo extends CommonRepo<ProjectEntity, ProjectModel> {
  async findOneById(params: { id: string }): Promise<ProjectModel | undefined> {
    const { id } = params
    // implementation
  }

  async findByFilters(params: {
    ownerId: string
    status?: ProjectStatus
    startAt?: number
    endAt?: number
  }): Promise<ProjectModel[]> {
    const { ownerId, status, startAt, endAt } = params
    // implementation
  }
}

// Usage
const project = await new ProjectRepo().findOneById({ id: '123' })
const projects = await new ProjectRepo().findByFilters({ ownerId: '123', status: ProjectStatus.ACTIVE })
```

### Utility Layer Examples

```typescript
export const stringUtil = {
  convertToCamelCase(str: string): string {
    return str.replace(constant.regex.dashLetterRegex, (match) => {
      return match[1].toUpperCase()
    })
  },

  truncate(text: string, maxLength: number): string {
    if (text.length <= maxLength) {
      return text
    }

    return `${text.slice(0, maxLength)}...`
  },

  wrap(params: { text: string; prefix: string; suffix: string }): string {
    const { text, prefix, suffix } = params

    return `${prefix}${text}${suffix}`
  },
}
```

## Parameter Object Types

### Inline Type (default)

```typescript
export const userService = {
  register(params: { email: string; password: string; name: string }): Promise<UserModel> {
    const { email, password, name } = params
    // implementation
  },
}
```

### Named Local Type

For complex params or reuse within the same file. Declare it with `type` and without an `I` prefix (`interface` is only for contracts a class implements):

```typescript
type CreateInvoiceParams = {
  ownerId: string
  items: InvoiceItemModel[]
  dueAt: number
  notes?: string
}

export const invoiceService = {
  create(params: CreateInvoiceParams): InvoiceModel {
    const { ownerId, items, dueAt, notes } = params
    // implementation
  },
}
```

### Shared Type (Separate File)

When the params shape is shared across files, it is a model: `src/business/model/invoice-model.ts` exporting `InvoiceModelCreate`, imported with `import type`.

## React Props Analogy

This pattern mirrors React component props, and the same three rules apply (object, destructure first, defaults in the signature):

```typescript
export const ProjectList = (props: {
  ownerId: string
  status?: ProjectStatus
  onSelect?: (project: ProjectModel) => void
}): ReactElement => {
  const { ownerId, status, onSelect } = props
  // component logic
}
```

## Migration Strategy

When refactoring existing code:

1. **Identify functions with positional params** in business layers
2. **Create the params object type** (inline `type` or local `type`)
3. **Move every default into the signature**
4. **Destructure on the first line** and replace every `params.x` read with the local name
5. **Update all call sites**

```typescript
// Before
createUser(email: string, name: string, role = UserRole.MEMBER): UserModel

// After
createUser(params: { email: string; name: string; role?: UserRole } = { email: '', name: '', role: UserRole.MEMBER }): UserModel {
  const { email, name, role } = params
  // same logic
}
```

## Summary

### Rules
- **Business Logic Layers** (Service/Repository/Use Case/Component/DAL/Controller):
  - ✅ ALWAYS use object params for ALL functions (even single parameter)
  - ✅ Callbacks go inside the params object under the key `callback`
  - ❌ EXCEPTION: Framework signatures (e.g., Express middleware `(req, res, next)`)
- **Every layer**:
  - ✅ Destructure `params` / `props` on the first body line; no `params.x` reads afterwards
  - ✅ Defaults in the signature (`params: {...} = {...}`), never `= value` in the destructure and never `{ ...defaults, ...params }` merges in the body
  - ✅ Never mutate the params; return new values
- **Utility and Lib Layers**:
  - ✅ Object params optional for one or two params; positional is fine
  - ✅ Use the object when names are not obvious from the call
  - ✅ A callback may be the second positional parameter next to a params object
