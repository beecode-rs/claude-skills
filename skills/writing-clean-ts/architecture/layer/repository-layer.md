# Repository Pattern

Repositories extend `CommonRepo` for entity-model conversion and provide a clean interface for data access. Part of the **Repository Layer (RL)** in the Business Layer.

## Naming Convention

**See [naming-convention.md](../../style/naming-convention.md) for complete naming standards.**

- **File:** `kebab-case` (e.g., `project-repo.ts`)
- **Export:** `PascalCase` class (always)
- **Usage:** Instantiate with `new` operator

## Purpose

The Repository Layer abstracts data persistence and retrieval, shielding the Business Layer from storage mechanisms (database, files, memory, external APIs, etc.). It converts between database entities and domain models.

## Structure

```typescript
// src/business/repo/project-repo.ts
import {
  type ProjectModel,
  type ProjectModelCreate,
  type ProjectModelEdit,
} from '@app/common/business/model/core/project-model'
import { CommonRepo, type ICommonDal } from '@app/node-common/business/component/data-store/common'

import {
  type ProjectEntity,
  type ProjectEntityCreate,
  type ProjectEntityEdit
} from '#src/dal/typeorm/entity/project-entity'
import { ProjectDal } from '#src/dal/typeorm/project-dal'

export interface IProjectDal extends ICommonDal<
  ProjectEntity,
  ProjectEntityCreate,
  ProjectEntityEdit,
  ProjectModel,
  ProjectModelCreate,
  ProjectModelEdit
> {}

export class ProjectRepo extends CommonRepo<
  ProjectEntity,
  ProjectEntityCreate,
  ProjectEntityEdit,
  ProjectModel,
  ProjectModelCreate,
  ProjectModelEdit
> {
  protected readonly _dal: IProjectDal

  constructor(params?: { dal?: IProjectDal }) {
    const { dal = new ProjectDal() } = params ?? {}
    super({ dal })
    this._dal = dal
  }
}
```

## Key Characteristics

- **Always uses class pattern** (required for constructor and DAL injection)
- Extends `CommonRepo<Entity, EntityCreate, EntityEdit, Model, ModelCreate, ModelEdit>`
- **Abstraction layer**: Shields Business Layer from storage implementation details
- **Data source agnostic**: Can wrap databases, files, memory, or external APIs
- Accepts DAL interface in constructor for dependency injection
- Instantiated with `new` operator (e.g., `new ProjectRepo()`)
- Supports custom light ORM for simple queries (inherited from CommonRepo)
- DAL handles entity-to-model conversion (not the repository itself)

## Usage

Repositories are instantiated directly with the `new` operator:

```typescript
// In controllers, use cases, or services
const { data, pagination } = await new ProjectRepo().findMany({
  filter: { status: 'active' },
  pagination: { page: 1, limit: 10 }
})

const project = await new ProjectRepo().findOneById(id)
const created = await new ProjectRepo().create({ name: 'New Project', sourceUrl: 'https://...' })
await new ProjectRepo().editById(id, { name: 'Updated Name' })
await new ProjectRepo().deleteById(id)
```

## Repository Specialization

Repositories can be extended for specific use cases:

```typescript
// src/business/repo/own-project-repo.ts
import { type IProjectDal, ProjectRepo } from '#src/business/repo/project-repo'
import { ProjectDal } from '#src/dal/typeorm/project-dal'
import { controllerSessionSingleton } from '#src/util/controller-session-singleton'

export class OwnProjectRepo extends ProjectRepo {
  constructor(params?: { dal?: IProjectDal }) {
    const { dal = new ProjectDal({
      fixedFilter: { ownerId: controllerSessionSingleton().getOwnerId() }
    })} = params ?? {}
    super({ dal })
  }
}
```

**Usage:**
```typescript
// Automatically filters by current user's ownerId
const myProjects = await new OwnProjectRepo().findMany()
```

## Null vs Undefined

**Repository Layer uses `undefined` only — never `null`.**

```typescript
// ✅ CORRECT: Use undefined when record not found
findOneById(params: { id: string }): Promise<ProjectModel | undefined>

// ❌ WRONG: Never return null from repository
findOneById(params: { id: string }): Promise<ProjectModel | null>
```

**Why:** The Repository is part of the Business Layer. `null` is only used in the DAL/Entity layer for database compatibility. The DAL handles the conversion from `null` (database) to `undefined` (business).

See [null-undefined-pattern.md](../null-undefined-pattern.md) for complete guidance.

## Architectural Rules

### ✅ DO
- Use Repository as the only data access point from Business Layer
- **Return `undefined` when record not found** — never `null`
- Let DAL handle entity-to-model conversion
- Handle data source switching without affecting Business Layer
- Use DAL for complex queries and custom methods
- Keep repository methods focused on data operations (CRUD + queries)
- Instantiate repositories with `new ProjectRepo()`
- Pass DAL interface to constructor for dependency injection when needed
- Extend repositories for specialized filtering (e.g., OwnProjectRepo)

### ❌ DON'T
- Include business logic in repositories
- Expose entities directly to Service/Use Case layers (DAL converts to models)
- Make repositories depend on other repositories
- Access framework-specific code (use DAL for that)
- Create factory functions (just use `new` directly)
- Implement entity-to-model conversion in repository (DAL handles this)
- **Return `null`** — always return `undefined` when record not found (DAL handles null conversion)
