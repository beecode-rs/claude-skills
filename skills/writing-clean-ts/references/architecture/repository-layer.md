# Repository Pattern

Repositories extend `CommonRepo` for entity-model conversion and provide a clean interface for data access. Part of the **Repository Layer (RL)** in the Business Layer.

## Naming Convention

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
  constructor(params: { fixedFilter?: object } = {}) {
    const { fixedFilter } = params

    super({ dal: new ProjectDal({ fixedFilter }) })
  }
}
```

The constructor takes **configuration values only** (here the `fixedFilter` that scopes every query). The repo builds its own DAL from them; nothing is injected. Tests replace the DAL module with a mock instead of passing a fake through the constructor.

## Key Characteristics

- **Always uses class pattern** (required for constructor and DAL injection)
- Extends `CommonRepo<Entity, EntityCreate, EntityEdit, Model, ModelCreate, ModelEdit>`
- **Abstraction layer**: Shields Business Layer from storage implementation details
- **Data source agnostic**: Can wrap databases, files, memory, or external APIs
- Builds its own DAL (field initializer or `super(...)` call); the constructor takes config values only
- Instantiated with `new` operator (e.g., `new ProjectRepo()`), or through a `-singleton` accessor when it holds the data in memory
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
  constructor(params: { fixedFilter?: object } = {}) {
    const { fixedFilter } = params

    super({ fixedFilter: { ...fixedFilter, ownerId: controllerSessionSingleton().getOwnerId() } })
  }
}
```

**Usage:**
```typescript
// Automatically filters by current user's ownerId
const myProjects = await new OwnProjectRepo().findMany()
```

### Scoped Repos (subclass + fixedFilter)

A repo scoped to one aggregate is a subclass whose DAL carries a `fixedFilter` locking every query to that scope:

```typescript
// src/business/repo/own-isolated-project-repo.ts
export class OwnIsolatedProjectRepo extends OwnProjectRepo {
  constructor(params: { projectId: string }) {
    const { projectId } = params

    super({ fixedFilter: { projectId } })
  }
}
```

Every inherited find/create/edit is now incapable of touching a different project. Prefer this over re-passing the scope at each call site.

## The Repo Knows Nothing About Storage

The repo is the business view of stored data; the DAL is where the storage framework lives. The split is strict:

| Concern | Repo | DAL |
|---|---|---|
| Vocabulary | `create`, `edit`, `remove`, `save`, `fetch`, `load`, `init` | `read`, `write` |
| File paths, `fs`, JSON (de)serialization | ❌ never | ✅ |
| Where the data lives (file, memory, DB, API) | ❌ unknown | ✅ |
| Defaults, sanitizing, domain validation | ✅ | ❌ never |
| Emitting domain events after a save | ✅ | ❌ |

Every repo gets its own DAL (`settings-repo` → `settings-dal`), and the `IXxxDal` interface it depends on is declared in the repo file. Repeated storage mechanics live in common DALs that the per-repo DALs extend or compose.

## In-Memory Repos with File Persistence

For data the app reads constantly and changes rarely (settings), the repo keeps the value in memory and writes it through to a file on every change. There is exactly **one** repo for the data; no second "app settings" repo holding a copy:

```typescript
// src/main/business/repo/settings-repo-singleton.ts
export interface ISettingsDal {
  readSettingsFile: () => Promise<unknown>
  readSettings: () => SettingsModel | undefined
  writeSettings: (params: { settings: SettingsModel }) => Promise<void>
}

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

  async save(params: { settings: SettingsModel }): Promise<void> {
    const { settings } = params

    await this._dal.writeSettings({ settings })
    appEventBusSingleton().emit({ payload: settings, type: AppEventType.SETTINGS_SAVED })
  }
}

export const settingsRepoSingleton = singletonPattern(() => {
  return new _SettingsRepo()
})
```

- **`init()` is the only async read**, called once from an app-boot life cycle (the first one, since everything else reads settings)
- **`fetch()` is sync** and serves the memory copy; it throws if `init()` has not run
- **`save()` writes through**: memory and file together, then emits the domain event
- Business code never sees a file: it calls `fetch()` and `save()`
- Services that need the data call `settingsRepoSingleton().fetch()` themselves; callers do not pass settings down as a parameter

## Client-Side REST Repos (frontend)

Frontend packages consume REST APIs through facade repo classes exposing auth-leveled sub-repos:

```typescript
// src/business/repo/rest-core-repo.ts
export class RestCoreRepo {
  public: PublicSubRepo        // no auth
  authorised: AuthorisedSubRepo // user JWT
}
```

`node-common` extends the facade with a third level: `.protected` (internal service-to-service API key). The hierarchy is strict: public < authorised (user JWT) < protected (internal key); each level exposes only its endpoints.

Wiring lives in `<name>-repo-singleton.ts` files exporting `singletonPattern(() => new RestXxxRepo({ baseUrl, ... }))`, with `auth-private-repo-singleton.ts` for internal-only wiring:

```typescript
// src/business/repo/project-repo-singleton.ts
export const projectRepoSingleton = singletonPattern(() => new RestProjectRepo({
  baseUrl: config.apiBaseUrl,
}))
```

## GraphQL Repo

A single Apollo Client class covers queries, watched queries (reactive), and mutations over HTTP + WS links:

```typescript
// src/business/repo/gql-repo.ts
export class GqlRepo {
  query<T>(params: { query: DocumentNode; variables?: T }): Promise<ApolloQueryResult<unknown>> { ... }
  watchQuery<T>(params: { query: DocumentNode; variables?: T }): Observable<ApolloQueryResult<unknown>> { ... }
}
```

No public/authorised split here: the GraphQL transport carries auth itself.

## Null vs Undefined

**Repository Layer uses `undefined` only — never `null`.**

```typescript
// ✅ CORRECT: Use undefined when record not found
findOneById(params: { id: string }): Promise<ProjectModel | undefined>

// ❌ WRONG: Never return null from repository
findOneById(params: { id: string }): Promise<ProjectModel | null>
```

**Why:** The Repository is part of the Business Layer. `null` is only used in the DAL/Entity layer for database compatibility. The DAL handles the conversion from `null` (database) to `undefined` (business).

## Architectural Rules

### ✅ DO
- Use Repository as the only data access point from Business Layer
- **Return `undefined` when record not found** — never `null`
- Let DAL handle entity-to-model conversion
- Handle data source switching without affecting Business Layer
- Use DAL for complex queries and custom methods
- Keep repository methods focused on data operations (CRUD + queries)
- Instantiate repositories with `new ProjectRepo()`
- Build the DAL inside the repo; the constructor takes config values only
- Extend repositories for specialized filtering (e.g., OwnProjectRepo)
- Speak business words (`create`, `edit`, `remove`, `save`, `fetch`, `load`, `init`); `read`/`write` are DAL words

### ❌ DON'T
- Include business logic in repositories
- Expose entities directly to Service/Use Case layers (DAL converts to models)
- Make repositories call other repositories (subCLASSING for scoping is fine: `OwnIsolatedProjectRepo extends OwnProjectRepo` is the scoped-repo pattern, not a dependency)
- Access framework-specific code (use DAL for that)
- Know anything about files: no paths, no `fs`, no JSON parsing, no "read file" / "write file" methods
- Accept collaborators (DALs, services) through constructor params
- Create factory functions for server-side repos (just use `new` directly; client-side REST repo singletons use `singletonPattern` wiring files)
- Implement entity-to-model conversion in repository (DAL handles this)
- **Return `null`** - always return `undefined` when record not found (DAL handles null conversion)
