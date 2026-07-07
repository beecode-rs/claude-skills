# Service Pattern

Services implement core business logic using **singleton objects** (preferred) or **classes** (when methods need to reference each other). Part of the **Service Layer (SL)** in the Business Layer.

## Naming Convention

**See [naming-convention.md](../../style/naming-convention.md) for complete naming standards.**

- **File:** `kebab-case` (e.g., `secret-service.ts`)
- **Export:** `camelCase` singleton OR `PascalCase` class
- **When to use class vs singleton:** See naming convention guide

## Purpose

The Service Layer implements reusable, single-purpose business logic functions. It's framework-agnostic and focuses purely on business rules without transport or persistence concerns.

## Structure

### Preferred: Singleton Object Pattern

Use singleton objects when methods are independent and don't need to call each other.

```typescript
// src/business/service/[domain]/[feature]-service.ts
import { nodeError } from '../../../util/error'
import { logger } from '../../../util/logger'

export const calculationService = {
  calculateTotal: async (params: { items: Item[] }): Promise<number> => {
    const { items } = params
    return items.reduce((sum, item) => sum + item.price, 0)
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

### Alternative: Class Pattern

Use classes when methods need to reference each other using `this`. **Export the class itself, NOT an instantiated object.**

```typescript
// src/business/service/secret-service.ts
import { type SecretModel } from '@app/common/business/model/core/secret-model'
import { config } from '#src/util/config'
import { cryptoUtil } from '#src/util/crypto-util'

export class SecretService {
  decryptSecret(secret: string): string {
    const { key } = config().projectSecret.encryption
    return cryptoUtil.decrypt({ key, text: secret })
  }

  decryptModelSecret(projectSecret: SecretModel): SecretModel {
    const { secret } = projectSecret
    // Calls another method using this
    return { ...projectSecret, secret: this.decryptSecret(secret) }
  }

  encryptSecret(secret: string): string {
    const { ivLength, key } = config().projectSecret.encryption
    return cryptoUtil.encrypt({ ivLength, key, text: secret })
  }
}
```

**Usage:**

```typescript
// ✅ CORRECT: Instantiate at the call site
const decryptedModel = await new SecretService().decryptModelSecret(model)
```

**Anti-patterns to avoid:**

```typescript
// ❌ NEVER do this - don't export instantiated class objects
export const secretService = new SecretService()

// ❌ NEVER do this - don't export instantiated class objects
const service = new SecretService()
export { service as secretService }
```

## Key Characteristics

- **Prefer singleton objects** for simplicity and stateless operations
- **Use classes** when methods need to call each other via `this`
- Pure async functions/methods
- **Framework-agnostic**: No framework-specific code (Express, TypeORM, etc.)
- **Single-purpose**: Each function does one thing well
- **Clear naming**: Function names must clearly describe their purpose
- Handle business logic and validation
- Use repository layer for data access (never DAL directly)
- Use `logger()` for structured logging
- Use `nodeError` for error handling

## Null vs Undefined

**Business Layer uses `undefined` only — never `null`.**

```typescript
// ✅ CORRECT: Use undefined for optional values
async getById(params: { id: string }): Promise<UserModel | undefined>

// ❌ WRONG: Never use null in business layers
async getById(params: { id: string }): Promise<UserModel | null>
```

**Why:** `undefined` is the TypeScript convention for missing values. `null` is reserved for the DAL/Entity layer (database compatibility with TypeORM).

See [null-undefined-pattern.md](../null-undefined-pattern.md) for complete guidance.

## Architectural Rules

### ✅ DO

- **Prefer singleton objects** when methods are independent
- **Use `undefined` for optional/missing values** — never `null`
- Use classes when methods need to reference each other via `this`
- Keep services reusable across different contexts
- Name functions descriptively (e.g., `validateAndProcessOrder`, `calculateTotalPrice`)
- Access data only through Repository Layer
- Implement pure business logic
- Use services from Use Cases or Controllers
- Instantiate service classes with `new ServiceName()` when using class pattern

### ❌ DON'T

- Include transport-specific logic (HTTP, SQS, etc.)
- Access DAL or Entities directly (use Repository Layer)
- Embed framework-specific code
- Use console.log (use logger instead)
- Make services dependent on other services (use Use Cases for orchestration)
- Use classes if singleton objects are sufficient
- **Export instantiated class objects** — `export const x = new X()` is an anti-pattern. Export the class and instantiate at the call site with `new ClassName()`
- **Use `null`** — always use `undefined` for optional/missing values in business layers
