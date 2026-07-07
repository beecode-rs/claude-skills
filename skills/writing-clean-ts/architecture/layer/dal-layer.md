# Data Access Layer (DAL)

Data Access Layer (DAL) classes provide an abstraction over data persistence mechanisms, isolating framework-specific data access code from the Repository Layer. This is the **Data Access Layer (DAL)** that wraps framework-specific implementations and handles entity-model conversion.

## Framework Implementations

This is an abstract layer pattern. See framework-specific implementations:
- **[TypeORM DAL](./dal-layer/typeorm.md)** - SQL database access using TypeORM ORM

## Naming Convention

**See [naming-convention.md](../../style/naming-convention.md) for complete naming standards.**

- **File:** `kebab-case` (e.g., `project-dal.ts`)
- **Export:** `PascalCase` class (always)
- **Interface:** `I`-prefix PascalCase (e.g., `IProjectDal`)
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

**Framework Implementation**: See [dal-layer-typeorm.md](./dal-layer/typeorm.md) for TypeORM implementation.

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
- Always define an interface (defined in repository file) for dependency injection
- Constructor accepts configuration (fixedFilter, connection details, etc.)
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

## Architectural Rules

### ✅ DO
- Keep all framework-specific code in DAL
- Implement interface (defined in repo file) for dependency injection
- Use framework-specific query utilities for complex queries
- **Handle entity-to-model conversion** in DAL
- Return models from conversion methods (not entities)
- Support data source abstraction (DB, files, memory, API)
- Use fixed filters for automatic query filtering
- Instantiate with `new ProjectDal()`

### ❌ DON'T
- Include business logic in DAL
- Expose framework-specific types to Repository Layer
- Access DAL directly from Service/Use Case layers (use Repository instead)
- Skip entity-to-model conversion (this is DAL's responsibility)
- Mix different data source concerns in a single DAL
