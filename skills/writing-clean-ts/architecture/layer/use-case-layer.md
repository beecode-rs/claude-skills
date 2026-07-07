# Use Case Pattern

Use cases orchestrate multiple services to implement complex business workflows. Part of the **Use Case Layer (UCL)** in the Business Layer.

## Naming Convention

**See [naming-convention.md](../../style/naming-convention.md) for complete naming standards.**

- **File:** `kebab-case` (e.g., `git-use-case.ts`)
- **Export:** `camelCase` singleton object (always - never use classes)
- **Why singleton only:** Prevents use cases from being reused inside other use cases

## Purpose

The Use Case Layer orchestrates business scenarios and dynamic logic by coordinating multiple Service Layer functions. It handles complex multi-step workflows that involve multiple services and repositories.

**IMPORTANT:** Use cases must always be singleton objects (never classes) to prevent them from being nested within other use cases. Use cases should orchestrate services and repositories, not other use cases.

## Structure

```typescript
// src/business/use-case/git-use-case.ts
import { type GitCommitModel } from '@app/common/business/model/core/git-commit-model'
import { SecretType } from '@app/common/business/model/core/secret-model'

import { OwnIsolatedProjectRepo } from '#src/business/repo/own-isolated-project-repo'
import { OwnProjectRepo } from '#src/business/repo/own-project-repo'
import { SecretService } from '#src/business/service/secret-service'
import { GitDal } from '#src/dal/git-dal'

export const gitUseCase = {
  getCommitsByOwnProjectId: async (params: { projectId: string }): Promise<GitCommitModel[]> => {
    const { projectId } = params

    // Orchestrates multiple repositories and services
    const project = await new OwnProjectRepo().findOneById(projectId)

    const accessToken = await new OwnIsolatedProjectRepo({ projectId: project.id })
      .secretFindMany({ secretType: SecretType.GIT_ACCESS_TOKEN })
      .then((secrets) => {
        const [secret] = secrets
        if (!secret) return undefined
        return new SecretService().decryptSecret(secret.secret)
      })
      .catch(() => undefined)

    const gitDal = new GitDal({ accessToken, gitUrl: project.sourceUrl })
    return gitDal.getAvailableCommits()
  },
}
```

## Key Characteristics

- **Always singleton objects** (never classes) - this is enforced to prevent use case nesting
- **Orchestrates business scenarios**: Coordinates multiple services and repositories
- **Dynamic logic**: Handles conditional workflows and multi-step processes
- **Descriptive naming encouraged**: Names can be concise but should include documentation
- Handle complex multi-step business workflows
- Use structured logging to track workflow progress
- camelCase naming: `gitUseCase`
- Pure async functions
- **Framework-agnostic**: No framework-specific code

## Why Use Cases Must Be Singleton Objects

Using singleton objects (instead of classes) prevents use cases from being instantiated and called within other use cases:

```typescript
// ❌ BAD - Class pattern allows nesting use cases
export class OrderUseCase {
  async processOrder(orderId: string) {
    // This can be called from other use cases
  }
}

// Another use case could do this (anti-pattern):
const orderUseCase = new OrderUseCase()
await orderUseCase.processOrder(orderId)

// ✅ GOOD - Singleton object prevents nesting
export const orderUseCase = {
  processOrder: async (params: { orderId: string }) => {
    // Can only be called directly, not nested in other use cases
  },
}
```

## Use Case vs Service

| Aspect | Use Case Layer | Service Layer |
|--------|---------------|---------------|
| **Purpose** | Orchestrate workflows | Implement single-purpose logic |
| **Pattern** | Always singleton object | Singleton OR class (if methods call each other) |
| **Naming** | Can be concise with docs | Must be descriptive |
| **Calls** | Multiple services/repos | Repositories and utilities |
| **Complexity** | Multi-step, conditional | Single-purpose, focused |
| **Documentation** | Thorough documentation | Self-documenting names |
| **Reusability** | Not reusable in other use cases | Reusable across use cases |

## Null vs Undefined

**Use Case Layer uses `undefined` only — never `null`.**

```typescript
// ✅ CORRECT: Use undefined for optional values
getProjectById: async (params: { id: string }): Promise<ProjectModel | undefined> => {
  const project = await new ProjectRepo().findOneById(params.id)
  return project // already undefined if not found
}

// ❌ WRONG: Never use null in use cases
getProjectById: async (params: { id: string }): Promise<ProjectModel | null> => {
  const project = await new ProjectRepo().findOneById(params.id)
  return project ?? null
}
```

**Why:** Use Cases are part of the Business Layer, which uses `undefined` for missing values. `null` is reserved for the DAL/Entity layer only.

See [null-undefined-pattern.md](../null-undefined-pattern.md) for complete guidance.

## Architectural Rules

### ✅ DO
- **Always use singleton objects** (never classes) for use cases
- **Use `undefined` for optional/missing values** — never `null`
- Orchestrate multiple Service Layer functions
- Handle complex business scenarios with conditional logic
- Call repositories directly when needed
- Call services (both class-based and singleton)
- Document workflows thoroughly
- Keep use cases framework-agnostic
- Use use cases for multi-service coordination
- Instantiate service classes with `new` when needed

### ❌ DON'T
- Include transport-specific logic (HTTP, SQS, etc.)
- Access DAL or Entities directly (use Repository Layer)
- Duplicate business logic that should be in Service Layer
- Create use cases for simple single-service operations (use Service directly)
- Embed framework-specific code
- **Use classes for use cases** (always use singleton objects)
- **Call other use cases from within a use case** (orchestrate services instead)
- **Use `null`** — always use `undefined` for optional/missing values in business layers
