# Use Case Pattern

Use cases are the controller-facing named boundary for a business operation. Part of the **Use Case Layer (UCL)** in the Business Layer.

## Naming Convention

- **File:** `kebab-case` (e.g., `git-use-case.ts`)
- **Export:** `camelCase` plain object (always - never a class, never wrapped in `singletonPattern`)
- **Why a plain object only:** A use-case has no need for private functions, internal state, or per-run context. The body is a flat sequence of named steps delegating to collaborators; the simple object does the work. Anything that wants `protected _` helpers or per-run state is a service or a component, not a use-case

## Purpose

A use-case sequences business calls into one business transaction, owned by the controller layer. It gives a workflow a stable, domain-named entry point and hides which layer implements each step.

A use-case is NOT a place for logic of its own: the body is a flat sequence of well-named steps, where each step is a call to a service, repository, component, or DAL whose own name describes what that step does. The reader understands the whole operation by reading those step names, which is why the use-case itself can carry a short, high-level name.

## When to Create a Use Case

The default: a use-case orchestrates **two or more** business calls (for example: repo find + token generate + repo save). If the operation is a single call with nothing to sequence, calling that business function directly from the controller is the expected pattern.

A **thin use-case** (one call) is acceptable when it does one of these two jobs:

1. **A stable, domain-named entry point for the controller**: the controller keeps calling `formatUseCase.formatEntities` while the underlying implementation evolves
2. **Hiding which layer implements the operation**: `formatEntities` hides whether a service, a component, or a DAL does the work; that indirection is the value, not the call count

```typescript
// ✅ Acceptable thin use-case: named boundary that hides the implementing layer
export const formatUseCase = {
  pumlContentToSvg: async (params: { content: string }): Promise<PlantUmlSvg> => {
    return await new PlantUmlDal().contentToSvg(params)
  },
}
```

The controller calls `formatUseCase.pumlContentToSvg` and never learns that a DAL does the work; the boundary is the value, not the call count.

If a single-call use-case does neither (it just renames one service call and nothing is hidden or stabilized), it is a useless wrapper: delete it and let the controller call the business function directly.

### Two hard rules

1. **A use-case is always a stateless plain object, never a class and never a `singletonPattern` accessor.** Each call is independent; there is nothing to remember between calls. Collaborators come from `import`s, never from constructor injection. It has no need for private functions or internal calls; the simple object does the work. A class use-case that decomposes into `protected _` helpers is misfiled logic: move that logic to a service or component and let the use-case delegate to it
2. **A use-case never calls another use-case.** Compose by calling the underlying services, components, repos, and DALs directly. A workflow composing workflows hides the real collaborators and couples packages to workflow names instead of the operations behind them
3. **Startup work is not a use-case.** Code that runs once while the app boots (loading settings into memory, syncing schedules, registering handlers) is an app-boot life cycle in `app-boot/life-cycle/`. A use-case is triggered by a controller in response to something external

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

    const project = await new OwnProjectRepo().findOneById({ id: projectId })

    const accessToken = await new OwnIsolatedProjectRepo({ projectId: project.id })
      .secretFindMany({ secretType: SecretType.GIT_ACCESS_TOKEN })
      .then((secrets) => {
        const [secret] = secrets
        if (!secret) {
          return undefined
        }
        return new SecretService().decryptSecret({ secret: secret.secret })
      })
      .catch(() => { return undefined })

    const gitDal = new GitDal({ accessToken, gitUrl: project.sourceUrl })
    return gitDal.getAvailableCommits()
  },
}
```

## Key Characteristics

- **Always singleton objects** (never classes) - the shape enforces the no-nesting rule
- **Controller-facing named boundary**: the workflow's stable public name; usually orchestrates 2+ calls, thin when the boundary itself is the value
- **Calls collaborators directly**: repos, services, components, DALs, and libs - whatever implements the step
- **Concise naming**: the use-case name is short and high-level; the body's step names (the service/repo calls) carry the detail
- **No domain logic in the body**: steps delegate; logic lives in the collaborators
- **Longest methods in the business layer are legitimate here**: the body is a flat, named-step pipeline. A long declarative config literal inside a step is data, not branching complexity
- camelCase naming: `gitUseCase`
- Pure async functions
- **Framework-agnostic**: No framework-specific code

## Why Use Cases Must Be Plain Objects

Using plain objects (instead of classes) keeps use cases from growing internal structure that belongs elsewhere:

```typescript
// ❌ BAD - Class pattern invites helpers, state, and nesting
export class OrderUseCase {
  async processOrder(params: { orderId: string }) {
    const order = await this._findOrder(params) // use-cases have no private helpers
  }

  protected _findOrder(params: { orderId: string }) { ... }
}

// Another use case could do this (anti-pattern):
const orderUseCase = new OrderUseCase()
await orderUseCase.processOrder({ orderId })

// ✅ GOOD - Plain object: flat steps, no helpers, no nesting
export const orderUseCase = {
  processOrder: async (params: { orderId: string }) => {
    const { orderId } = params

    const order = await orderRepo.findOneById({ id: orderId })
    await paymentService.charge({ order })
    await notificationService.sendOrderConfirmation({ order })
  },
}
```

## Use Case vs Service

| Aspect | Use Case Layer | Service Layer |
|--------|---------------|---------------|
| **Purpose** | Named workflow boundary owned by the controller | Reusable logic with a single responsibility |
| **Pattern** | Always singleton object | Singleton object, class, or factory function |
| **Naming** | Short, high-level (the body's step names carry the detail) | Must be descriptive and self-contained |
| **Calls** | Usually 2+ collaborators; thin allowed for a named boundary | Repos, components, DALs, utils, other same-package services |
| **Complexity** | Flat sequence of named steps | Single-purpose, focused (may decompose into `protected _` helpers) |
| **Understood by** | Reading the step names in the body | Reading the function name |
| **Reusability** | Not reusable in other use cases | Reusable across contexts |

## Null vs Undefined

**Use Case Layer uses `undefined` only - never `null`.**

```typescript
// ✅ CORRECT: Use undefined for optional values
getProjectById: async (params: { id: string }): Promise<ProjectModel | undefined> => {
  const { id } = params

  return await new ProjectRepo().findOneById({ id })
}

// ❌ WRONG: Never use null in use cases
getProjectById: async (params: { id: string }): Promise<ProjectModel | null> => {
  const { id } = params
  const project = await new ProjectRepo().findOneById({ id })

  return project ?? null
}
```

**Why:** Use Cases are part of the Business Layer, which uses `undefined` for missing values. `null` is reserved for the DAL/Entity layer only.

## Architectural Rules

### ✅ DO
- **Always use stateless plain objects** (never classes, never `singletonPattern`) for use cases
- **Use `undefined` for optional/missing values** - never `null`
- Give the controller a stable, domain-named entry point (thin use-cases are fine for this)
- Hide which layer implements an operation behind the use-case name
- Let the step names in the body document the workflow (names, not comments)
- Call repos, services, components, DALs, and libs directly
- Keep use cases framework-agnostic
- Instantiate service and repo classes with `new` when needed

### ❌ DON'T
- Include transport-specific logic (HTTP, SQS, etc.)
- Put domain logic in the use-case body (delegate to a service/component)
- **Use classes or `singletonPattern` for use cases** (always a stateless plain object)
- Put app startup work in a use-case (it is an app-boot life cycle)
- Receive collaborators through a constructor (import them)
- **Call other use cases from within a use case** (call the underlying services/components/repos/DALs directly)
- Keep a single-call use-case that neither stabilizes an entry point nor hides the implementing layer (that one is a wrapper; delete it)
- **Use `null`** - always use `undefined` for optional/missing values in business layers
