# TypeORM

Everything TypeORM-specific: TypeORM DAL classes (`TypeormCommonDal`, QueryBuilder, DataSource) and TypeORM entities (decorators, `BaseEntity`, relations, `TableNameMapper`).

## Contents

- [TypeORM In This Skill's Layers](#typeorm-in-this-skills-layers)
- [TypeORM Data Access Layer](#typeorm-data-access-layer)
  - [Framework](#framework)
  - [Naming Convention](#naming-convention)
  - [Purpose](#purpose)
  - [Structure](#structure)
  - [Fixed Filters](#fixed-filters)
  - [TypeORM QueryBuilder Patterns](#typeorm-querybuilder-patterns)
  - [Entity-Model Conversion](#entity-model-conversion)
  - [TypeORM Repository Access](#typeorm-repository-access)
  - [Data Source Singleton](#data-source-singleton)
  - [Architectural Rules](#architectural-rules)
  - [Testing TypeORM DAL](#testing-typeorm-dal)
  - [Relationship with Other Layers](#relationship-with-other-layers)
- [TypeORM Entity Layer](#typeorm-entity-layer)
  - [Framework](#framework-1)
  - [Naming Convention](#naming-convention-1)
  - [Purpose](#purpose-1)
  - [Structure](#structure-1)
  - [TypeORM Decorators](#typeorm-decorators)
  - [Column Types](#column-types)
  - [Table Name Mapping](#table-name-mapping)
  - [BaseEntity Fields](#baseentity-fields)
  - [Constructor Pattern](#constructor-pattern)
  - [Architectural Rules](#architectural-rules-1)
  - [Migrations](#migrations)
  - [Testing Entities](#testing-entities)
  - [Relationship with Other Layers](#relationship-with-other-layers-1)

## TypeORM In This Skill's Layers

| Layer | Pattern | Location |
|-------|---------|----------|
| **DAL** | Class | `src/dal/`, `src/dal/typeorm/` |
| **Entity** | Class | `src/dal/typeorm/entity/` |

- **Data access MUST be in `src/dal/`** (`typeorm/` for TypeORM DALs)
- Feature layout: `src/dal/typeorm/feature-name-dal.ts` and `src/dal/typeorm/entity/feature-name-entity.ts`
- `null` exists only in the DAL/Entity layer (database compatibility with TypeORM); the DAL converts `null` to `undefined` for the business layer
- Implement TypeORM entities with proper relations

## TypeORM Data Access Layer

TypeORM Data Access Layer (DAL) classes extend `TypeormCommonDal` for database operations using TypeORM. Part of the **Data Access Layer (DAL)** for SQL database access.

### Framework

This implementation uses:
- **TypeORM** - ORM for SQL databases (PostgreSQL, MySQL, SQLite, etc.)
- **TypeormCommonDal** - Base class providing common CRUD operations
- **QueryBuilder** - For complex queries
- **DataSource** - Database connection management

### Naming Convention

- **File:** `kebab-case` (e.g., `project-dal.ts`)
- **Export:** `PascalCase` class (always)
- **Interface:** `I`-prefix PascalCase (e.g., `IProjectDal`)
- **Usage:** Instantiate with `new` operator
- **Location:** `src/dal/typeorm/[domain]-dal.ts`

### Purpose

The TypeORM DAL encapsulates TypeORM-specific data access code, isolating it from the Repository Layer. It provides:
- Custom query methods using TypeORM QueryBuilder
- Entity-to-model conversion
- Fixed filter support for automatic query filtering
- Framework isolation (TypeORM changes don't affect business layer)

### Structure

#### Basic DAL Implementation

```typescript
// src/dal/typeorm/project-dal.ts
import {
  type ProjectModel,
  type ProjectModelCreate,
  type ProjectModelEdit,
} from '@app/common/business/model/core/project-model'
import { type ObjectType, type StringKeyObject } from '@app/node-common/business/component/data-store/_common/types'
import { TypeormCommonDal } from '@app/node-common/business/component/data-store/typeorm'

import { type IProjectDal } from '#src/business/repo/project-repo'
import { ProjectEntity, type ProjectEntityCreate, type ProjectEntityEdit } from '#src/dal/typeorm/entity/project-entity'
import { typeormDataSourceSingleton } from '#src/lib/typeorm/data-source-singleton'

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
  constructor(params: { fixedFilter?: StringKeyObject } = {}) {
    const { fixedFilter } = params

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
    return {
      createdAt: entity.createdAt,
      id: entity.id,
      name: entity.name,
      ownerId: entity.ownerId,
      sourceType: entity.sourceType,
      sourceUrl: entity.sourceUrl,
      updatedAt: entity.updatedAt,
    }
  }
}
```

#### DAL with Custom Query Methods

```typescript
// src/dal/typeorm/project-dal.ts
import { ProjectStatus } from '@app/common/business/enum/project-status-enum'
import { type ProjectModel } from '@app/common/business/model/core/project-model'
import { TypeormCommonDal } from '@app/node-common/business/component/data-store/typeorm'

import { type IProjectDal } from '#src/business/repo/project-repo'
import { ProjectEntity } from '#src/dal/typeorm/entity/project-entity'
import { typeormDataSourceSingleton } from '#src/lib/typeorm/data-source-singleton'

export class ProjectDal extends TypeormCommonDal<...> implements IProjectDal {
  constructor(params: { fixedFilter?: StringKeyObject } = {}) {
    // ... constructor implementation
  }

  // Custom query: Find projects by owner with status
  async findByOwnerAndStatus(params: {
    ownerId: string
    status: ProjectStatus
  }): Promise<ProjectModel[]> {
    const { ownerId, status } = params

    const entities = await this._repo
      .createQueryBuilder('project')
      .where('project.ownerId = :ownerId', { ownerId })
      .andWhere('project.status = :status', { status })
      .orderBy('project.createdAt', 'DESC')
      .getMany()

    return entities.map((entity) => {
      return this.entityToModel(entity)
    })
  }

  // Custom query: Find projects with related entities
  async findWithSecrets(params: { projectId: string }): Promise<ProjectModel | undefined> {
    const { projectId } = params

    const entity = await this._repo
      .createQueryBuilder('project')
      .leftJoinAndSelect('project.secrets', 'secret')
      .where('project.id = :projectId', { projectId })
      .getOne()

    if (!entity) {
      return undefined
    }

    return this.entityToModel(entity)
  }

  // Custom query: Aggregate data
  async countByStatus(): Promise<{ status: ProjectStatus; count: number }[]> {
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
    return {
      createdAt: entity.createdAt,
      id: entity.id,
      name: entity.name,
      ownerId: entity.ownerId,
      sourceType: entity.sourceType,
      sourceUrl: entity.sourceUrl,
      updatedAt: entity.updatedAt,
    }
  }
}
```

#### DAL with Transaction Support

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
      const secretEntities = secrets.map((secret) => {
        return new SecretEntity(secret)
      })
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

### Fixed Filters

DALs can accept fixed filters for automatic query filtering:

```typescript
// Create DAL with fixed filter for owner
const dal = new ProjectDal({
  fixedFilter: { ownerId: currentUserId }
})

// All queries will automatically filter by ownerId
const projects = await dal.findMany() // Only returns current user's projects
```

### TypeORM QueryBuilder Patterns

#### Basic Select Query

```typescript
const entities = await this._repo
  .createQueryBuilder('project')
  .where('project.ownerId = :ownerId', { ownerId })
  .getMany()
```

#### Query with Relations

```typescript
const entity = await this._repo
  .createQueryBuilder('project')
  .leftJoinAndSelect('project.secrets', 'secret')
  .leftJoinAndSelect('project.parseDatas', 'parseData')
  .where('project.id = :id', { id })
  .getOne()
```

#### Query with Pagination

```typescript
const [entities, total] = await this._repo
  .createQueryBuilder('project')
  .where('project.status = :status', { status })
  .skip((page - 1) * limit)
  .take(limit)
  .getManyAndCount()
```

#### Complex Where Conditions

```typescript
const entities = await this._repo
  .createQueryBuilder('project')
  .where('project.ownerId = :ownerId', { ownerId })
  .andWhere(
    new Brackets(qb => {
      qb.where('project.status = :active', { active: ProjectStatus.ACTIVE })
        .orWhere('project.status = :pending', { pending: ProjectStatus.PENDING })
    })
  )
  .getMany()
```

#### Aggregate Queries

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

#### Raw SQL Query

```typescript
const result = await this._repo.query(
  'SELECT * FROM project WHERE owner_id = $1 AND status = $2',
  [ownerId, status]
)
```

### Entity-Model Conversion

The DAL is responsible for converting between database entities and domain models:

#### Model to Entity (for persistence)

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

#### Entity to Model (for business layer)

```typescript
entityToModel(entity: ProjectEntity): ProjectModel {
  return {
    createdAt: entity.createdAt,
    id: entity.id,
    name: entity.name,
    ownerId: entity.ownerId,
    sourceType: entity.sourceType,
    sourceUrl: entity.sourceUrl,
    updatedAt: entity.updatedAt,
  }
}
```

The model is a plain `type`, so the DAL builds it field by field (converting database `null` to `undefined` where a field is optional) instead of calling a model constructor.

### TypeORM Repository Access

The DAL accesses the TypeORM repository via `this._repo`:

```typescript
// Direct repository methods
await this._repo.save(entity)
await this._repo.findOne({ where: { id } })
await this._repo.remove(entity)

// QueryBuilder
await this._repo.createQueryBuilder('alias').getMany()
```

### Data Source Singleton

```typescript
// src/lib/typeorm/data-source-singleton.ts
import { DataSource } from 'typeorm'
import { singletonPattern } from '@beecode/msh-util/singleton/pattern'

import { config } from '#src/util/config'

export const typeormDataSourceSingleton = singletonPattern(() => {
  return new DataSource({
    type: 'postgres',
    host: config.db.host,
    port: config.db.port,
    username: config.db.user,
    password: config.db.password,
    database: config.db.name,
    entities: [ProjectEntity, SecretEntity],
    synchronize: false,
    logging: config.db.isLoggingEnabled,
  })
})
```

Connection values come from `config` (the only reader of `process.env`), never from `process.env` directly.

### Architectural Rules

#### ✅ DO

- Keep all TypeORM-specific code in DAL
- Implement the interface declared in the repo file, so the repo depends on a contract rather than TypeORM
- Take configuration values only in the constructor (`fixedFilter`), with defaults in the signature
- Use QueryBuilder for complex queries
- Handle entity-to-model conversion in DAL
- Return models from conversion methods (not entities)
- Support data source abstraction
- Use fixed filters for automatic query filtering
- Instantiate with `new ProjectDal()`
- Use transactions for multi-step operations
- Access TypeORM repository via `this._repo`

#### ❌ DON'T

- Include business logic in DAL
- Expose TypeORM-specific types to Repository Layer
- Access DAL directly from Service/Use Case layers (use Repository instead)
- Skip entity-to-model conversion
- Return entities to Repository Layer (always convert to models)
- Hardcode database connections (use singleton)
- Mix concerns (keep DAL focused on data access only)

### Testing TypeORM DAL

```typescript
// src/dal/typeorm/project-dal.test.ts
import { ProjectSourceType } from '@app/common/business/enum/project-source-type-enum'

import { ProjectDal } from '#src/dal/typeorm/project-dal'
import { typeormDataSourceSingleton } from '#src/lib/typeorm/data-source-singleton'

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
      sourceType: ProjectSourceType.GIT,
    })

    const found = await dal.findOneById({ id: created.id })

    expect(found).toBeDefined()
    expect(found?.name).toBe('Test Project')
  })
})
```

### Relationship with Other Layers

```
Repository → DAL (TypeORM) → TypeORM Repository → Database
                  ↓
             Entity-Model Conversion
             Query Execution
             Transaction Management
```

The TypeORM DAL provides a clean abstraction over TypeORM, ensuring that ORM-specific implementation details don't leak into the business layer while providing powerful query capabilities when needed.

## TypeORM Entity Layer

TypeORM entities extend `BaseEntity` with TypeORM decorators to define database table structure. Part of the **Model Layer (ML)** for SQL database persistence.

### Framework

This implementation uses:
- **TypeORM** - ORM for SQL databases (PostgreSQL, MySQL, SQLite, etc.)
- **Decorators** - @Entity, @Column, @OneToMany, @ManyToMany, etc.
- **BaseEntity** - Provides id, createdAt, updatedAt, deletedAt fields
- **TableNameMapper** - Centralized table name management

### Naming Convention

- **File:** `kebab-case` (e.g., `project-entity.ts`)
- **Export:** `PascalCase` class (always)
- **Usage:** Instantiate with `new` operator (typically in DAL)
- **Location:** `src/dal/typeorm/entity/[domain]-entity.ts`

### Purpose

TypeORM entities define the database schema and structure for SQL databases. They:
- Map TypeScript classes to database tables
- Define column types, constraints, and relationships
- Store only necessary properties (no computed values)
- Provide a bridge between database and domain models

### Structure

#### Basic Entity

```typescript
// src/dal/typeorm/entity/project-entity.ts
import { ParserType } from '@app/common/business/enum/parser-type-enum'
import { ProjectSourceType } from '@app/common/business/enum/project-source-type-enum'
import {
  type ProjectModel,
  type ProjectModelCreate,
  type ProjectModelEdit,
  type ProjectParserPayload,
} from '@app/common/business/model/core/project-model'
import { AppendNullToUndefined, baseModelService } from '@app/common/business/service/base-model-service'
import { BaseEntity } from '@app/node-common/business/component/data-store/typeorm'
import { Column, Entity, Unique } from 'typeorm'

import { TableNameMapper } from '#src/lib/typeorm/table-name-mapper-enum'

export interface IProjectEntity<PARSER_TYPE extends ParserType = any>
  extends AppendNullToUndefined<ProjectModel<PARSER_TYPE>> {}

@Unique(['ownerId', 'sourceUrl'])
@Entity({ name: TableNameMapper.PROJECT })
export class ProjectEntity<PARSER_TYPE extends ParserType = any>
  extends BaseEntity
  implements IProjectEntity
{
  constructor(params?: IProjectEntity) {
    super(params)
    if (!params) {
      return
    }

    const nullableParams = baseModelService.convertUndefinedToNull(params)
    const { name, ownerId, sourceUrl, sourceType, parserType, parserPayload } = nullableParams

    this.name = name
    this.ownerId = ownerId
    this.sourceUrl = sourceUrl
    this.sourceType = sourceType
    this.parserType = parserType
    this.parserPayload = parserPayload as ProjectParserPayload<PARSER_TYPE>
  }

  @Column()
  name!: string

  @Column()
  ownerId!: string

  @Column()
  sourceUrl!: string

  @Column({ enum: ProjectSourceType, type: 'enum' })
  sourceType!: ProjectSourceType

  @Column({ enum: ParserType, type: 'enum' })
  parserType!: PARSER_TYPE

  @Column({ type: 'jsonb' })
  parserPayload!: ProjectParserPayload<PARSER_TYPE>
}

export type ProjectEntityCreate = ProjectModelCreate
export type ProjectEntityEdit = ProjectModelEdit
```

#### Entity with Relationships

```typescript
// src/dal/typeorm/entity/project-entity.ts
import { BaseEntity } from '@app/node-common/business/component/data-store/typeorm'
import { Column, Entity, JoinTable, ManyToMany, OneToMany, Relation, Unique } from 'typeorm'

import { ProjectParseDataEntity } from '#src/dal/typeorm/entity/project-parse-data-entity'
import { SecretEntity } from '#src/dal/typeorm/entity/secret-entity'
import { TableNameMapper } from '#src/lib/typeorm/table-name-mapper-enum'

@Unique(['ownerId', 'sourceUrl'])
@Entity({ name: TableNameMapper.PROJECT })
export class ProjectEntity extends BaseEntity {
  constructor(params?: IProjectEntity) {
    super(params)
    if (!params) {
      return
    }

    const nullableParams = baseModelService.convertUndefinedToNull(params)
    const { name, ownerId, sourceUrl, sourceType, parserType, parserPayload, projectParseDatas, secrets } = nullableParams

    this.name = name
    this.ownerId = ownerId
    this.sourceUrl = sourceUrl
    this.sourceType = sourceType
    this.parserType = parserType
    this.parserPayload = parserPayload

    // Initialize relationships
    if (projectParseDatas) {
      this.projectParseDatas = projectParseDatas.map((data) => new ProjectParseDataEntity(data))
    }

    if (secrets) {
      this.secrets = secrets.map((secret) => new SecretEntity(secret))
    }
  }

  @Column()
  name!: string

  @Column()
  ownerId!: string

  @Column()
  sourceUrl!: string

  @Column({ enum: ProjectSourceType, type: 'enum' })
  sourceType!: ProjectSourceType

  @Column({ enum: ParserType, type: 'enum' })
  parserType!: ParserType

  @Column({ type: 'jsonb' })
  parserPayload!: ProjectParserPayload

  // One-to-Many relationship
  @OneToMany(() => ProjectParseDataEntity, (projectParseData) => projectParseData.project)
  projectParseDatas?: Relation<ProjectParseDataEntity[]>

  // Many-to-Many relationship
  @ManyToMany(() => SecretEntity, (secret) => secret.projects)
  @JoinTable({ name: 'project_to_secret' })
  secrets?: Relation<SecretEntity[]>
}

export type ProjectEntityCreate = ProjectModelCreate
export type ProjectEntityEdit = ProjectModelEdit
```

#### Entity with Custom Column Options

```typescript
// src/dal/typeorm/entity/user-entity.ts
import { BaseEntity } from '@app/node-common/business/component/data-store/typeorm'
import { Column, Entity, Index, Unique } from 'typeorm'

import { TableNameMapper } from '#src/lib/typeorm/table-name-mapper-enum'

@Entity({ name: TableNameMapper.USER })
@Unique(['email'])
@Index(['lastName', 'firstName'])
export class UserEntity extends BaseEntity {
  @Column({ length: 255 })
  firstName!: string

  @Column({ length: 255 })
  lastName!: string

  @Column({ unique: true })
  email!: string

  @Column({ nullable: true, default: null })
  phoneNumber!: string | null

  @Column({ type: 'boolean', default: false })
  isActive!: boolean

  @Column({ type: 'timestamp', nullable: true })
  lastLoginAt!: Date | null

  @Column({ type: 'text', nullable: true })
  bio!: string | null

  @Column({ type: 'integer', default: 0 })
  loginCount!: number

  @Column({ type: 'decimal', precision: 10, scale: 2, nullable: true })
  balance!: number | null
}
```

### TypeORM Decorators

#### Entity Decorators

```typescript
// Define entity with table name
@Entity({ name: 'projects' })
class ProjectEntity extends BaseEntity {}

// Add unique constraint
@Unique(['email'])
@Unique(['ownerId', 'sourceUrl'])

// Add index
@Index(['lastName', 'firstName'])
@Index('idx_user_email', ['email'])
```

#### Column Decorators

```typescript
// Basic column
@Column()
name!: string

// Column with type
@Column({ type: 'varchar', length: 255 })
title!: string

// Nullable column
@Column({ nullable: true })
description?: string | null

// Column with default value
@Column({ default: 'active' })
status!: string

// Enum column
@Column({ enum: ProjectStatus, type: 'enum' })
status!: ProjectStatus

// JSON column
@Column({ type: 'jsonb' })
metadata!: object

// Timestamp column
@Column({ type: 'timestamp', default: () => 'CURRENT_TIMESTAMP' })
createdAt!: Date

// Boolean column
@Column({ type: 'boolean', default: false })
isActive!: boolean

// Numeric column
@Column({ type: 'decimal', precision: 10, scale: 2 })
price!: number
```

#### Relationship Decorators

##### One-to-Many

```typescript
@OneToMany(() => ProjectParseDataEntity, (parseData) => parseData.project)
parseDatas?: Relation<ProjectParseDataEntity[]>
```

##### Many-to-One

```typescript
@ManyToOne(() => ProjectEntity, (project) => project.parseDatas)
@JoinColumn({ name: 'project_id' })
project?: Relation<ProjectEntity>
```

##### Many-to-Many

```typescript
// Owner side (with join table)
@ManyToMany(() => SecretEntity, (secret) => secret.projects)
@JoinTable({ name: 'project_to_secret' })
secrets?: Relation<SecretEntity[]>

// Inverse side
@ManyToMany(() => ProjectEntity, (project) => project.secrets)
projects?: Relation<ProjectEntity[]>
```

##### One-to-One

```typescript
// Owner side
@OneToOne(() => ProfileEntity, (profile) => profile.user)
@JoinColumn({ name: 'profile_id' })
profile?: Relation<ProfileEntity>

// Inverse side
@OneToOne(() => UserEntity, (user) => user.profile)
user?: Relation<UserEntity>
```

### Column Types

#### PostgreSQL Types

```typescript
@Column({ type: 'varchar', length: 255 })
@Column({ type: 'text' })
@Column({ type: 'integer' })
@Column({ type: 'bigint' })
@Column({ type: 'decimal', precision: 10, scale: 2 })
@Column({ type: 'boolean' })
@Column({ type: 'timestamp' })
@Column({ type: 'date' })
@Column({ type: 'time' })
@Column({ type: 'jsonb' })
@Column({ type: 'uuid' })
@Column({ type: 'enum', enum: MyEnum })
```

### Table Name Mapping

```typescript
// src/lib/typeorm/table-name-mapper.ts
export const TableNameMapper = {
  PROJECT: 'project',
  USER: 'user',
  SECRET: 'secret',
  PROJECT_PARSE_DATA: 'project_parse_data',
  PROJECT_TO_SECRET: 'project_to_secret',
} as const
```

### BaseEntity Fields

All entities extend `BaseEntity` which provides:

```typescript
class BaseEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string

  @CreateDateColumn({ type: 'timestamp' })
  createdAt!: Date

  @UpdateDateColumn({ type: 'timestamp' })
  updatedAt!: Date

  @DeleteDateColumn({ type: 'timestamp', nullable: true })
  deletedAt!: Date | null
}
```

### Constructor Pattern

```typescript
constructor(params?: IProjectEntity) {
  super(params) // Initialize base fields
  if (!params) {
    return
  }

  // Convert undefined to null for database compatibility
  const nullableParams = baseModelService.convertUndefinedToNull(params)
  const { name, ownerId, sourceUrl } = nullableParams

  // Assign properties
  this.name = name
  this.ownerId = ownerId
  this.sourceUrl = sourceUrl

  // Initialize relationships if provided
  if (nullableParams.secrets) {
    this.secrets = nullableParams.secrets.map((s) => new SecretEntity(s))
  }
}
```

### Architectural Rules

#### ✅ DO

- Store only necessary properties in entities
- Compute derived properties in domain models
- Use proper TypeORM decorators for relationships
- Keep entities focused on data structure
- Use entities only in DAL layer (converted to models for Repository)
- Define entity interfaces for type safety
- Use type aliases for Create and Edit operations
- Handle nullable properties correctly (AppendNullToUndefined)
- Use enums from common library for type safety
- Use TableNameMapper for centralized table names
- Extend BaseEntity for standard fields

#### ❌ DON'T

- Store computed/derived values that can be calculated
- Include business logic in entities
- Use entities directly in Service/Use Case layers (DAL converts to models)
- Mix entity concerns with transport concerns
- Skip null handling in constructor
- Hardcode table names (use TableNameMapper)
- Use TypeORM outside of DAL layer

### Migrations

#### Creating Migrations

```bash
npm run typeorm migration:generate -- -n CreateProjectTable
```

#### Running Migrations

```bash
npm run typeorm migration:run
```

#### Reverting Migrations

```bash
npm run typeorm migration:revert
```

#### Example Migration

```typescript
// src/migration/1234567890-CreateProjectTable.ts
import { MigrationInterface, QueryRunner, Table } from 'typeorm'

export class CreateProjectTable1234567890 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.createTable(
      new Table({
        name: 'project',
        columns: [
          {
            name: 'id',
            type: 'uuid',
            isPrimary: true,
            default: 'uuid_generate_v4()',
          },
          {
            name: 'name',
            type: 'varchar',
            length: '255',
          },
          {
            name: 'owner_id',
            type: 'uuid',
          },
          {
            name: 'source_url',
            type: 'varchar',
          },
          {
            name: 'created_at',
            type: 'timestamp',
            default: 'CURRENT_TIMESTAMP',
          },
          {
            name: 'updated_at',
            type: 'timestamp',
            default: 'CURRENT_TIMESTAMP',
          },
        ],
        indices: [
          {
            columnNames: ['owner_id', 'source_url'],
            isUnique: true,
          },
        ],
      }),
      true
    )
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.dropTable('project')
  }
}
```

### Testing Entities

For testing patterns and examples, use the **test-typescript** skill.

### Relationship with Other Layers

```
DAL (TypeORM) → Entity (TypeORM) → Database Table
                    ↓
               Schema Definition
               Type Mapping
               Relationship Definition
```

TypeORM entities provide the schema definition and type mapping between TypeScript classes and database tables, ensuring type safety and proper data structure throughout the persistence layer.
