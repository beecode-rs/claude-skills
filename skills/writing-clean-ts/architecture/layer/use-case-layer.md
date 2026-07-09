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

## When to Use a Use Case (and When Not To)

A use-case function gives a **concise name to a complex operation**: an operation that does several things and would need an unwieldy name to describe everything it does in one word.

The complexity lives in the **body**. A use-case is a sequence of well-named steps, where each step is a call to a service, repository, or component whose own name describes what that step does. The reader understands the whole operation by reading those step names, which is why the use-case itself can carry a short, high-level name.

### The single-call rule

A use-case function must orchestrate **two or more** business-layer operations. If a use-case calls only **one** service/repo/component and forwards its result, it is a useless wrapper: it adds a layer and a name without adding any behavior.

The Controller Layer can call **any** business layer directly (use-case, service, repo, or component). A use-case is not a bridge the controller needs in order to reach a service. If there is only one step, there is nothing to orchestrate, so the controller calls that one business function itself.

```typescript
// ❌ WRONG - use-case that only wraps one service call (useless wrapper)
export const projectUseCase = {
  getProject: async (params: { id: string }): Promise<ProjectModel> => {
    return await projectService.findOneById(params)
  },
}

// ✅ CORRECT - controller calls the business layer directly
const project = await projectService.findOneById({ id: params.id })

// ✅ CORRECT - a real use-case orchestrates multiple steps under a concise name
export const projectUseCase = {
  cloneProject: async (params: { id: string; userId: string }): Promise<ProjectModel> => {
    const source = await projectService.findOneById({ id: params.id })
    const copy = await projectService.create({ name: `${source.name} (copy)` })
    await auditService.logClone({ userId: params.userId, fromId: source.id, toId: copy.id })
    return copy
  },
}
```

### Decision: use-case or not?

Ask one question: **does this need more than one business call?**

- **One call** -> no use-case. Call the service/repo/component directly from the controller.
- **Several calls, or a conditional workflow** -> use-case. Give it a short name and let the step names in the body explain the detail.

The only valid reason to create a use-case is multi-step orchestration. "The controller should not call the service directly" is **not** a valid reason; a controller calling a single business function is the expected pattern.

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
- **Concise naming**: The use-case name is short and high-level; the body's step names (the service/repo calls) carry the detail
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
| **Purpose** | Orchestrate complex multi-step workflows | Implement single-purpose logic |
| **Pattern** | Always singleton object | Singleton OR class (if methods call each other) |
| **Naming** | Short, high-level (the body's step names carry the detail) | Must be descriptive and self-contained |
| **Calls** | **Two or more** services/repos/components (never one; one is a wrapper) | Repositories, DALs, utilities |
| **Complexity** | Multi-step, conditional | Single-purpose, focused |
| **Understood by** | Reading the step names in the body | Reading the function name |
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
- Orchestrate **two or more** Service Layer operations (a use-case with a single call is a wrapper)
- Handle complex business scenarios with conditional logic
- Call repositories directly when needed
- Call services (both class-based and singleton)
- Let the step names in the body document the workflow (names, not comments)
- Keep use cases framework-agnostic
- Use use cases for multi-service coordination
- Instantiate service classes with `new` when needed

### ❌ DON'T
- Include transport-specific logic (HTTP, SQS, etc.)
- Access DAL or Entities directly (use Repository Layer)
- Duplicate business logic that should be in Service Layer
- **Create a use-case that wraps a single service/repo/component call** (a useless wrapper). If there is only one step, the controller calls that business function directly; there is nothing to orchestrate
- Embed framework-specific code
- **Use classes for use cases** (always use singleton objects)
- **Call other use cases from within a use case** (orchestrate services instead)
- **Use `null`** — always use `undefined` for optional/missing values in business layers
