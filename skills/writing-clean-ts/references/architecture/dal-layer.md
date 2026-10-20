# Data Access Layer (DAL)

Data Access Layer (DAL) classes provide an abstraction over data persistence mechanisms, isolating framework-specific data access code from the Repository Layer. This is the **Data Access Layer (DAL)** that wraps framework-specific implementations and handles entity-model conversion.

## Framework Implementations

This is an abstract layer pattern. Known implementation: **TypeORM DAL** - SQL database access using TypeORM ORM.

## Naming Convention

- **File:** `kebab-case` (e.g., `project-dal.ts`)
- **Export:** `PascalCase` class (always)
- **Interface:** `I`-prefix PascalCase (e.g., `IProjectDal`), declared in the repo file that uses it
- **Usage:** Instantiate with `new` operator
- **Location:** `src/dal/[framework]/[domain]-dal.ts`

## Purpose

The DAL encapsulates framework-specific data access code, isolating it from the Repository Layer. It provides:
- Framework abstraction (database, file system, external API, etc.)
- Custom query methods when needed
- Entity-to-model conversion
- Data source abstraction
- Protection from framework changes affecting the Business Layer

## Structure

**Conceptual Structure:**
```typescript
// Abstract concept - not framework-specific
import {
  ProjectModel,
  type ProjectModelCreate,
  type ProjectModelEdit,
} from '@app/common/business/model/core/project-model'

import { type IProjectDal } from '#src/business/repo/project-repo'
import { ProjectEntity, type ProjectEntityCreate, type ProjectEntityEdit } from '#src/dal/[framework]/entity/project-entity'

export class ProjectDal implements IProjectDal {
  constructor(params?: { fixedFilter?: object }) {
    // Initialize data source connection
    // Set up fixed filters for automatic query filtering
  }

  // Entity-to-Model conversion
  modelToEntity(model: ProjectModel): ProjectEntity {
    return new ProjectEntity(model)
  }

  modelToEntityEdit(model: ProjectModelEdit): ProjectEntityEdit {
    return model
  }

  modelToEntityCreate(model: ProjectModelCreate): ProjectEntityCreate {
    return model
  }

  entityToModel(entity: ProjectEntity): ProjectModel {
    return new ProjectModel(entity)
  }

  // Custom query methods
  async findByCustomCriteria(params: object): Promise<ProjectModel[]> {
    // Framework-specific query implementation
    // Convert entities to models before returning
  }
}
```

## Key Characteristics

- **Always uses class pattern** (required for framework integration)
- **Framework isolation**: Contains all framework-specific code
- **Handles entity-model conversion**: Implements conversion methods between entities and models
- Implements custom query methods when needed
- Always implement an interface declared in the repository file, so the repo depends on a contract rather than a storage framework
- Constructor accepts configuration values only (fixedFilter, a file path, connection details), never collaborators
- Speaks storage words: `read`, `write` (the repo above it speaks business words)
- Provides abstraction over data sources (database, files, memory, API)

## Entity-Model Conversion

The DAL is responsible for converting between persistence entities and domain models:

```typescript
// Converting model to entity (for persistence)
modelToEntity(model: ProjectModel): ProjectEntity {
  return new ProjectEntity(model)
}

// Converting entity to model (for business layer)
entityToModel(entity: ProjectEntity): ProjectModel {
  return new ProjectModel(entity)
}
```

## Fixed Filters

DALs can accept fixed filters for automatic query filtering:

```typescript
// DAL with fixed filter for owner
const dal = new ProjectDal({
  fixedFilter: { ownerId: currentUserId }
})

// All queries will automatically filter by ownerId
const projects = await dal.findMany() // Only returns current user's projects
```

## Data Source Abstraction

The DAL can wrap different types of data sources:

### Database
- SQL databases (PostgreSQL, MySQL, SQLite)
- NoSQL databases (MongoDB, Redis)
- ORM frameworks (TypeORM, Prisma, Mongoose)

### File System
- Local file storage
- Distributed file systems
- Cloud storage (S3, Azure Blob)

### External APIs
- REST APIs
- GraphQL endpoints
- gRPC services

### In-Memory
- Cache layers (Redis, Memcached)
- In-process memory stores

## File and Memory DALs

Not every DAL wraps a database. Desktop and CLI apps persist to JSON files and keep runtime values in memory. The storage mechanics repeat, so they live in two common base classes in `src/dal/`, and each repo gets one small DAL built on them:

```
src/dal/
├── common-file-dal.ts        # CommonFileDal: _readJsonFile / _writeJsonFile, atomic writes, missing-file handling
├── common-memory-dal.ts      # CommonMemoryDal<T>: _readValue / _writeValue
├── settings-dal.ts           # SettingsDal: file + memory for the settings repo
└── trigger-run-log-dal.ts    # TriggerRunLogDal: file-backed log for its repo
```

```typescript
// src/dal/settings-dal.ts
export class SettingsDal extends CommonFileDal implements ISettingsDal {
  protected readonly _memory = new CommonMemoryDal<SettingsModel>()
  protected readonly _settingsFilePath: string

  constructor(params: { settingsFilePath?: string } = { settingsFilePath: join(app.getPath('userData'), 'settings.json') }) {
    const { settingsFilePath } = params
    super()
    this._settingsFilePath = settingsFilePath
  }

  async readSettingsFile(): Promise<unknown> {
    return await this._readJsonFile({ filePath: this._settingsFilePath })
  }

  readSettings(): SettingsModel | undefined {
    return this._memory.readValue()
  }

  async writeSettings(params: { settings: SettingsModel }): Promise<void> {
    const { settings } = params

    this._memory.writeValue({ value: settings })
    await this._writeJsonFile({ filePath: this._settingsFilePath, value: settings })
  }
}
```

- The **file path lives in the DAL**, never in the repo; the constructor param exists so tests can point it at a temp file
- **No business logic**: no defaults, no sanitizing, no domain events. The DAL stores and returns exactly what it is given; the repo decides what that is
- The common bases hold the mechanics once (JSON parsing, directory creation, missing file → `undefined`); per-repo DALs only name what they store
- Common DAL files carry the `common-` prefix (`common-file-dal.ts`, `common-memory-dal.ts`)

## Architectural Rules

### ✅ DO
- Keep all framework-specific code in DAL
- Implement the interface declared in the repo file, so the repo depends on a contract
- Use framework-specific query utilities for complex queries
- **Handle entity-to-model conversion** in DAL
- Return models from conversion methods (not entities)
- Support data source abstraction (DB, files, memory, API)
- Use fixed filters for automatic query filtering
- Instantiate with `new ProjectDal()`

### ❌ DON'T
- Include business logic in DAL (defaults, sanitizing, events belong to the repo)
- Let file paths, `fs` calls, or JSON parsing leak up into the repo
- Expose framework-specific types to Repository Layer
- Access DAL directly from Service/Use Case layers (use Repository instead)
- Skip entity-to-model conversion (this is DAL's responsibility)
- Mix different data source concerns in a single DAL
