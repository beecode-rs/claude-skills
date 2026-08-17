# Class vs Singleton Object Decision Guide

This guide helps you choose between using **classes** and **singleton objects** when implementing TypeScript code patterns.

## Quick Decision Tree

```
Does the layer REQUIRE a specific pattern?
├─ Yes → Follow the layer's requirement
│   ├─ Repository → ALWAYS use class
│   ├─ DAL → ALWAYS use class
│   ├─ Entity → ALWAYS use class
│   ├─ Use Case → ALWAYS use singleton object
│   └─ Handler → ALWAYS use singleton object
│
└─ No (Service layer) → Choose based on method dependencies
    ├─ Does the service need helper functions? → Helpers become protected `_` methods → Use class
    ├─ Do methods call each other via `this`? → Use class
    └─ Are methods independent? → Use singleton object (preferred)
```

## Layer-Specific Requirements

### Always Use Classes

These layers **must** use PascalCase classes:

| Layer | Reason | Example |
|-------|--------|---------|
| **Repository** | Requires constructor for DAL injection | `export class ProjectRepo` |
| **DAL** | Requires constructor for entity and data source setup | `export class ProjectDal` |
| **Entity** | ORM requirement (TypeORM decorators) | `export class ProjectEntity` |

### Always Use Singleton Objects

These layers **must** use camelCase singleton objects:

| Layer | Reason | Example |
|-------|--------|---------|
| **Use Case** | Prevents nesting use cases within other use cases | `export const authUseCase` |
| **Handler** | Simple object with handler and schema properties | `export const getProjectsAll` |

### Choose Based on Implementation

Only the **Service layer** allows choosing between patterns:

| Pattern | When to Use | Example |
|---------|-------------|---------|
| **Singleton Object** (Preferred) | Methods are independent, no need for `this`, no helper functions | `export const calculationService` |
| **Class** | Methods need to reference each other via `this`, or the service needs helper functions | `export class SecretService` |

### Service Helper Functions

A service file exports exactly **one element** (a class or a singleton object) and **never declares module-level (root-of-file) helper functions alongside it**. Any helper that serves the service becomes a member of the service itself:

- **On a class**: a `protected` method prefixed with a single underscore, called via `this`:

```typescript
export class SecretService {
  decrypt(params: { secret: string }): string {
    return this._internalDecrypt(params.secret)
  }

  protected _internalDecrypt(value: string): string {
    // implementation
  }
}
```

- **On a singleton object**: an underscore-prefixed property that is never exposed to consumers (convention only — it is still technically reachable, which is why the class pattern is preferred).

**The presence of helpers is itself a signal to choose the class pattern**: `protected _` methods give real encapsulation and let helpers call each other via `this`, so a service that needs helpers should be a class.

**Object params on helper methods**: The object-params rule ("Service: always") governs the public API. `protected _` helpers are internal implementation detail, so a single positional domain value is acceptable (e.g. `_decryptData = (data?: string) => { ... }`, matching the class service template); multiple inputs still use object params.

## Pattern Details

### Class Services: Constructor, Singleton, and Factory Patterns

When using classes for services, you have several instantiation patterns available depending on your needs.

#### Constructor Initialization

If a service needs logic to run before first use, use the class constructor:

```typescript
export class ClassService {
  protected readonly _memory: { [k: string]: string }

  public constructor(params?: { initialMemory?: { [k: string]: string } }) {
    const { initialMemory = {} } = params ?? {}
    this._memory = initialMemory
  }

  protected _methodOne(): string {
    return this._memory["one"]
  }

  public methodTwo(): string {
    return this._methodOne() + this._memory["two"]
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

// Usage
const service = classServiceFactory({ initialMemory: { one: "1" } })
```

**When to use:** When you need multiple independent instances or when refactoring from singleton to class pattern (avoids adding `new` keyword everywhere).

#### Singleton Pattern

Use memoization to ensure only one instance is created and always return the same object. Name it with the class name in camelCase plus the `Singleton` suffix:

```typescript
import { singletonPattern } from '@beecode/msh-util/singleton/pattern'

export const classServiceSingleton = singletonPattern(() => new ClassService())

// Usage
classServiceSingleton().methodTwo()
```

**When to use:** When a class service acts as a wrapper for functional functions and should maintain shared state across the application.

**CRITICAL: Never export instantiated objects directly.** If you need singleton behavior, ALWAYS use `singletonPattern` from `@beecode/msh-util/singleton/pattern` - never do `export const x = new X()`.

**Note:** While traditional singletons are considered an anti-pattern, this memoization approach provides similar benefits without the drawbacks.

#### Handling Async Initialization

Since constructors cannot be async, you have two options:

**Option 1: Async Factory/Singleton (Simple but Less Efficient)**

```typescript
export const classServiceSingletonAsync = async (): Promise<ClassService> => {
  const asyncData = await fetchInitialData()
  return new ClassService({ initialMemory: asyncData })
}

// Usage - every call is async
const service = await classServiceSingletonAsync()
```

**Drawback:** Every call to the service becomes async, even though only the first initialization needs it.

**Option 2: App Layer Initialization (Recommended)**

Use the app layer to initialize the service during app setup, then provide sync access:

```typescript
// app-layer setup
const initialData = await fetchInitialData()
export const classServiceSingleton = singletonPattern(
  () => new ClassService({ initialMemory: initialData })
)

// Usage - sync calls after initialization
classServiceSingleton().methodTwo()
```

**Benefit:** Async functionality is handled once during app initialization, allowing synchronous service calls throughout the application.

#### Naming Conventions for Class Services

Always add the appropriate suffix to indicate the instantiation pattern:

```typescript
// ❌ WRONG - unclear what this returns
export const classService = (): ClassService => new ClassService()

// ✅ CORRECT - clear patterns
export const classServiceFactory = (...params: ConstructorParameters<typeof ClassService>): ClassService =>
  new ClassService(...params)

export const classServiceSingleton = singletonPattern(() => new ClassService())
```

### Singleton Object Pattern

**When to use:**
- ✅ Methods are completely independent
- ✅ No shared internal state needed
- ✅ No helper functions needed (a service that needs helpers should be a class — see "Service Helper Functions" above)
- ✅ Simpler, functional approach is sufficient
- ✅ You want to prevent reuse (use cases in other use cases)

**Instantiation:** None needed - import and use directly

**Example:**

```typescript
// Service with independent methods
export const calculationService = {
  calculateTotal: async (items: Item[]): Promise<number> => {
    return items.reduce((sum, item) => sum + item.price, 0)
  },

  calculateTax: async (amount: number): Promise<number> => {
    return amount * 0.2
  },
}

// Usage
const total = await calculationService.calculateTotal(items)
```

### Class Pattern

**When to use:**
- ✅ Methods need to reference each other via `this`
- ✅ The service needs helper functions (they become `protected _` methods called via `this`)
- ✅ Dependency injection is required (repositories, DALs)
- ✅ Working with ORM patterns (entities)
- ✅ You need constructor logic

**Instantiation:** Use `new ClassName()`

**Example:**

```typescript
// Service with interdependent methods
export class SecretService {
  decryptSecret(secret: string): string {
    // implementation
  }

  decryptModelSecret(model: SecretModel): SecretModel {
    // Calls another method via this
    return { ...model, secret: this.decryptSecret(model.secret) }
  }
}

// Usage
const result = await new SecretService().decryptModelSecret(model)
```

## Special Case: Use Cases

**Always use singleton objects for use cases** to prevent them from being reused inside other use cases. Use cases should orchestrate services and repositories, not other use cases.

```typescript
// ✅ CORRECT - Use case as singleton object
export const orderUseCase = {
  processOrder: async (params: { orderId: string }) => {
    await orderService.validate(params.orderId)
    await paymentService.charge(params.orderId)
    await notificationService.send(params.orderId)
  },
}

// ❌ INCORRECT - Use case as class (allows reuse in other use cases)
export class OrderUseCase {
  async processOrder(params: { orderId: string }) {
    // This can be instantiated and called from other use cases - BAD!
  }
}
```

## Decision Examples

### Example 1: Simple Service

**Scenario:** Creating a calculation service with independent math functions.

**Decision:** ✅ Singleton object

**Reasoning:** Methods don't call each other, simpler approach is sufficient.

```typescript
export const mathService = {
  add: (a: number, b: number) => a + b,
  multiply: (a: number, b: number) => a * b,
}
```

### Example 2: Service with Method Dependencies

**Scenario:** Creating a secret service where one method calls another.

**Decision:** ✅ Class

**Reasoning:** `decryptModelSecret` needs to call `decryptSecret` via `this`.

```typescript
export class SecretService {
  decryptSecret(secret: string): string {
    return decrypt(secret)
  }

  decryptModelSecret(model: SecretModel): SecretModel {
    return { ...model, secret: this.decryptSecret(model.secret) }
  }
}
```

### Example 3: Repository Layer

**Scenario:** Creating a project repository.

**Decision:** ✅ Class (mandatory)

**Reasoning:** Layer requirement - repositories always use classes for DAL injection.

```typescript
export class ProjectRepo extends CommonRepo<...> {
  constructor(protected _dal: IProjectDal = new ProjectDal()) {
    super({ dal })
  }
}
```

### Example 4: Use Case Orchestration

**Scenario:** Creating a use case that orchestrates multiple services.

**Decision:** ✅ Singleton object (mandatory)

**Reasoning:** Layer requirement - use cases must prevent nesting.

```typescript
export const authUseCase = {
  login: async (params: { userName: string, userPassword: string }) => {
    await userService.validate(params)
    const token = await tokenService.generate(params.userName)
    await sessionService.create(token)
    return token
  },
}
```

## Common Mistakes

### ❌ Module-Level Helper Functions Next to a Service

```typescript
// ❌ WRONG - helper function at module scope, outside the service
const parseUser = (raw: RawUser): UserModel => {
  return { id: raw.id, name: raw.userName }
}

export class UserService {
  getUser(params: { id: string }): UserModel {
    const raw = fetchRaw(params.id)
    return parseUser(raw)
  }
}

// ✅ CORRECT - helper is a protected _ member of the service class
export class UserService {
  getUser(params: { id: string }): UserModel {
    const raw = fetchRaw(params.id)
    return this._parseUser(raw)
  }

  protected _parseUser(raw: RawUser): UserModel {
    return { id: raw.id, name: raw.userName }
  }
}
```

**Why this matters:** A service file must export exactly one element. Module-level helpers leak implementation outside the service boundary, cannot be encapsulated, and are invisible to `this`-based reuse. Their presence also signals the class pattern fits better (see "Service Helper Functions").

### ❌ Using Class for Simple Service

```typescript
// ❌ WRONG - Unnecessary class
export class CalculationService {
  calculateTotal(items: Item[]): number {
    return items.reduce((sum, item) => sum + item.price, 0)
  }
}

// ✅ CORRECT - Use singleton object
export const calculationService = {
  calculateTotal: (items: Item[]): number => {
    return items.reduce((sum, item) => sum + item.price, 0)
  },
}
```

### ❌ Using Singleton for Service with Dependencies

```typescript
// ❌ WRONG - Methods need to call each other
export const secretService = {
  decryptSecret: (secret: string): string => {
    return decrypt(secret)
  },
  decryptModelSecret: (model: SecretModel): SecretModel => {
    // Can't call decryptSecret without awkward self-reference
    return { ...model, secret: secretService.decryptSecret(model.secret) }
  },
}

// ✅ CORRECT - Use class for this
export class SecretService {
  decryptSecret(secret: string): string {
    return decrypt(secret)
  }
  decryptModelSecret(model: SecretModel): SecretModel {
    return { ...model, secret: this.decryptSecret(model.secret) }
  }
}
```

### ❌ Using Class for Use Case

```typescript
// ❌ WRONG - Use cases must be singleton objects
export class OrderUseCase {
  async processOrder(params: { orderId: string }) {
    // This can be reused in other use cases - BAD!
  }
}

// ✅ CORRECT - Singleton prevents nesting
export const orderUseCase = {
  processOrder: async (params: { orderId: string }) => {
    // Cannot be reused in other use cases - GOOD!
  },
}
```

### ❌ Exporting Instantiated Class Objects

```typescript
// ❌ WRONG - Never export instantiated class objects
export const secretService = new SecretService()
// ❌ ALSO WRONG
const service = new SecretService()
export { service as secretService }

// ✅ CORRECT - Export the class and instantiate at call site
export class SecretService {
  decryptSecret(secret: string): string { ... }
}

// Then use it at the call site:
const result = new SecretService().decryptSecret(secret)

// ✅ IF YOU NEED SINGLETON BEHAVIOR - Use singletonPattern
import { singletonPattern } from '@beecode/msh-util/singleton/pattern'

export const secretServiceSingleton = singletonPattern(() => new SecretService())

// Usage:
secretServiceSingleton().decryptSecret(secret)
```

**Why this matters:** Exporting instantiated objects hides dependencies, makes testing harder, and creates implicit singletons. Always export the class and let consumers instantiate it where needed. If singleton behavior is required, use `singletonPattern` from `@beecode/msh-util/singleton/pattern`.

## Summary Table

| Layer | Pattern | Flexibility | Naming Convention |
|-------|---------|-------------|-------------------|
| **Service** | Singleton OR Class | Choose based on method dependencies | `camelCase` OR `PascalCase` |
| **Repository** | Class (mandatory) | No choice | `PascalCase` |
| **Use Case** | Singleton (mandatory) | No choice | `camelCase` |
| **DAL** | Class (mandatory) | No choice | `PascalCase` |
| **Entity** | Class (mandatory) | No choice | `PascalCase` |
| **Handler** | Singleton (mandatory) | No choice | `camelCase` |
