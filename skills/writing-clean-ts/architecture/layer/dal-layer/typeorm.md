# TypeORM Data Access Layer

TypeORM Data Access Layer (DAL) classes extend `TypeormCommonDal` for database operations using TypeORM. Part of the **Data Access Layer (DAL)** for SQL database access.

**See [dal-layer.md](../dal-layer.md) for the abstract DAL pattern that applies to all data access implementations.**

## Framework

This implementation uses:
- **TypeORM** - ORM for SQL databases (PostgreSQL, MySQL, SQLite, etc.)
- **TypeormCommonDal** - Base class providing common CRUD operations
- **QueryBuilder** - For complex queries
- **DataSource** - Database connection management

## Naming Convention

**See [naming-convention.md](../../../style/naming-convention.md) for complete naming standards.**

- **File:** `kebab-case` (e.g., `project-dal.ts`)
- **Export:** `PascalCase` class (always)
- **Interface:** `I`-prefix PascalCase (e.g., `IProjectDal`)
- **Usage:** Instantiate with `new` operator
- **Location:** `src/dal/typeorm/[domain]-dal.ts`

## Purpose

The TypeORM DAL encapsulates TypeORM-specific data access code, isolating it from the Repository Layer. It provides:
- Custom query methods using TypeORM QueryBuilder
- Entity-to-model conversion
- Fixed filter support for automatic query filtering
- Framework isolation (TypeORM changes don't affect business layer)

## Structure

### Basic DAL Implementation

```typescript
// src/dal/typeorm/project-dal.ts
import {
  ProjectModel,
  type ProjectModelCreate,
  type ProjectModelEdit,
} from '@app/common/business/model/core/project-model'
import { type ObjectType, type StringKeyObject } from '@app/node-common/business/component/data-store/_common/types'
import { TypeormCommonDal } from '@app/node-common/business/component/data-store/typeorm'

import { type IProjectDal } from '#src/business/repo/project-repo'
import { ProjectEntity, type ProjectEntityCreate, type ProjectEntityEdit } from '#src/dal/typeorm/entity/project-entity'
import { typeormDataSourceSingleton } from '#src/lib/typeorm/index'

export class ProjectDal
  extends TypeormCommonDal<
    ProjectEntity,
    ProjectEntityCreate,
    ProjectEntityEdit,
    ProjectModel,
    ProjectModelCreate,
    ProjectModelEdit
  >
  implements IProjectDal
{
  constructor(params?: { fixedFilter?: StringKeyObject }) {
    const { fixedFilter } = params ?? {}

    super({
      entity: ProjectEntity,
      fixedFilter,
      repoFn: (entity: ObjectType<ProjectEntity>) => {
        return typeormDataSourceSingleton().repository<ProjectEntity>(entity)
      },
    })
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
}
```

### DAL with Custom Query Methods

```typescript
// src/dal/typeorm/project-dal.ts
import { ProjectModel } from '@app/common/business/model/core/project-model'
import { TypeormCommonDal } from '@app/node-common/business/component/data-store/typeorm'

import { type IProjectDal } from '#src/business/repo/project-repo'
import { ProjectEntity } from '#src/dal/typeorm/entity/project-entity'
import { typeormDataSourceSingleton } from '#src/lib/typeorm/index'

export class ProjectDal extends TypeormCommonDal<...> implements IProjectDal {
  constructor(params?: { fixedFilter?: StringKeyObject }) {
    // ... constructor implementation
  }

  // Custom query: Find projects by owner with status
  async findByOwnerAndStatus(params: {
    ownerId: string
    status: string
  }): Promise<ProjectModel[]> {
    const { ownerId, status } = params

    const entities = await this._repo
      .createQueryBuilder('project')
      .where('project.ownerId = :ownerId', { ownerId })
      .andWhere('project.status = :status', { status })
      .orderBy('project.createdAt', 'DESC')
      .getMany()

    return entities.map(entity => this.entityToModel(entity))
  }

  // Custom query: Find projects with related entities
  async findWithSecrets(projectId: string): Promise<ProjectModel | null> {
    const entity = await this._repo
      .createQueryBuilder('project')
      .leftJoinAndSelect('project.secrets', 'secret')
      .where('project.id = :projectId', { projectId })
      .getOne()

    return entity ? this.entityToModel(entity) : null
  }

  // Custom query: Aggregate data
  async countByStatus(): Promise<{ status: string; count: number }[]> {
    const result = await this._repo
      .createQueryBuilder('project')
      .select('project.status', 'status')
      .addSelect('COUNT(*)', 'count')
      .groupBy('project.status')
      .getRawMany()

    return result
  }

  // Entity-to-Model conversion methods
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
}
```

### DAL with Transaction Support

```typescript
// src/dal/typeorm/project-dal.ts
import { QueryRunner } from 'typeorm'
import { TypeormCommonDal } from '@app/node-common/business/component/data-store/typeorm'

export class ProjectDal extends TypeormCommonDal<...> implements IProjectDal {
  // ... other methods

  async createWithSecrets(params: {
    project: ProjectModelCreate
    secrets: SecretModelCreate[]
  }): Promise<ProjectModel> {
    const { project, secrets } = params

    const queryRunner = typeormDataSourceSingleton().createQueryRunner()
    await queryRunner.connect()
    await queryRunner.startTransaction()

    try {
      // Create project
      const projectEntity = this.modelToEntityCreate(project)
      const savedProject = await queryRunner.manager.save(ProjectEntity, projectEntity)

      // Create secrets
      const secretEntities = secrets.map(s => new SecretEntity(s))
      await queryRunner.manager.save(SecretEntity, secretEntities)

      // Link secrets to project
      savedProject.secrets = secretEntities
      await queryRunner.manager.save(ProjectEntity, savedProject)

      await queryRunner.commitTransaction()

      return this.entityToModel(savedProject)
    } catch (err) {
      await queryRunner.rollbackTransaction()
      throw err
    } finally {
      await queryRunner.release()
    }
  }
}
```

## Fixed Filters

DALs can accept fixed filters for automatic query filtering:

```typescript
// Create DAL with fixed filter for owner
const dal = new ProjectDal({
  fixedFilter: { ownerId: currentUserId }
})

// All queries will automatically filter by ownerId
const projects = await dal.findMany() // Only returns current user's projects
```

## TypeORM QueryBuilder Patterns

### Basic Select Query

```typescript
const entities = await this._repo
  .createQueryBuilder('project')
  .where('project.ownerId = :ownerId', { ownerId })
  .getMany()
```

### Query with Relations

```typescript
const entity = await this._repo
  .createQueryBuilder('project')
  .leftJoinAndSelect('project.secrets', 'secret')
  .leftJoinAndSelect('project.parseDatas', 'parseData')
  .where('project.id = :id', { id })
  .getOne()
```

### Query with Pagination

```typescript
const [entities, total] = await this._repo
  .createQueryBuilder('project')
  .where('project.status = :status', { status })
  .skip((page - 1) * limit)
  .take(limit)
  .getManyAndCount()
```

### Complex Where Conditions

```typescript
const entities = await this._repo
  .createQueryBuilder('project')
  .where('project.ownerId = :ownerId', { ownerId })
  .andWhere(
    new Brackets(qb => {
      qb.where('project.status = :active', { active: 'ACTIVE' })
        .orWhere('project.status = :pending', { pending: 'PENDING' })
    })
  )
  .getMany()
```

### Aggregate Queries

```typescript
const count = await this._repo
  .createQueryBuilder('project')
  .where('project.ownerId = :ownerId', { ownerId })
  .getCount()

const result = await this._repo
  .createQueryBuilder('project')
  .select('COUNT(*)', 'total')
  .addSelect('AVG(project.score)', 'avgScore')
  .where('project.status = :status', { status })
  .getRawOne()
```

### Raw SQL Query

```typescript
const result = await this._repo.query(
  'SELECT * FROM project WHERE owner_id = $1 AND status = $2',
  [ownerId, status]
)
```

## Entity-Model Conversion

The DAL is responsible for converting between database entities and domain models:

### Model to Entity (for persistence)

```typescript
modelToEntity(model: ProjectModel): ProjectEntity {
  return new ProjectEntity(model)
}

modelToEntityCreate(model: ProjectModelCreate): ProjectEntityCreate {
  return model
}

modelToEntityEdit(model: ProjectModelEdit): ProjectEntityEdit {
  return model
}
```

### Entity to Model (for business layer)

```typescript
entityToModel(entity: ProjectEntity): ProjectModel {
  return new ProjectModel(entity)
}
```

## TypeORM Repository Access

The DAL accesses the TypeORM repository via `this._repo`:

```typescript
// Direct repository methods
await this._repo.save(entity)
await this._repo.findOne({ where: { id } })
await this._repo.remove(entity)

// QueryBuilder
await this._repo.createQueryBuilder('alias').getMany()
```

## Data Source Singleton

```typescript
// src/lib/typeorm/index.ts
import { DataSource } from 'typeorm'
import { singletonPattern } from '@beecode/msh-util/singleton/pattern'

export const typeormDataSourceSingleton = singletonPattern(() => {
  return new DataSource({
    type: 'postgres',
    host: process.env.DB_HOST,
    port: Number(process.env.DB_PORT),
    username: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    entities: [ProjectEntity, SecretEntity],
    synchronize: false,
    logging: process.env.NODE_ENV === 'development',
  })
})
```

## Architectural Rules

### ✅ DO

- Keep all TypeORM-specific code in DAL
- Implement interface (defined in repo file) for dependency injection
- Use QueryBuilder for complex queries
- Handle entity-to-model conversion in DAL
- Return models from conversion methods (not entities)
- Support data source abstraction
- Use fixed filters for automatic query filtering
- Instantiate with `new ProjectDal()`
- Use transactions for multi-step operations
- Access TypeORM repository via `this._repo`

### ❌ DON'T

- Include business logic in DAL
- Expose TypeORM-specific types to Repository Layer
- Access DAL directly from Service/Use Case layers (use Repository instead)
- Skip entity-to-model conversion
- Return entities to Repository Layer (always convert to models)
- Hardcode database connections (use singleton)
- Mix concerns (keep DAL focused on data access only)

## Testing TypeORM DAL

```typescript
// test/dal/typeorm/project-dal.test.ts
import { ProjectDal } from '#src/dal/typeorm/project-dal'
import { typeormDataSourceSingleton } from '#src/lib/typeorm'

describe('ProjectDal', () => {
  beforeAll(async () => {
    await typeormDataSourceSingleton().initialize()
  })

  afterAll(async () => {
    await typeormDataSourceSingleton().destroy()
  })

  it('should create and retrieve project', async () => {
    const dal = new ProjectDal()

    const created = await dal.create({
      name: 'Test Project',
      ownerId: 'owner-123',
      sourceUrl: 'https://github.com/test/repo',
      sourceType: 'GIT',
    })

    const found = await dal.findOneById(created.id)

    expect(found).toBeDefined()
    expect(found?.name).toBe('Test Project')
  })
})
```

## Relationship with Other Layers

```
Repository → DAL (TypeORM) → TypeORM Repository → Database
                  ↓
             Entity-Model Conversion
             Query Execution
             Transaction Management
```

The TypeORM DAL provides a clean abstraction over TypeORM, ensuring that ORM-specific implementation details don't leak into the business layer while providing powerful query capabilities when needed.
