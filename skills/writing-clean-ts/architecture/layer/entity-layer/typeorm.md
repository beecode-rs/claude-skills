# TypeORM Entity Layer

TypeORM entities extend `BaseEntity` with TypeORM decorators to define database table structure. Part of the **Model Layer (ML)** for SQL database persistence.

**See [entity-layer.md](../entity-layer.md) for the abstract entity pattern that applies to all persistence implementations.**

## Framework

This implementation uses:
- **TypeORM** - ORM for SQL databases (PostgreSQL, MySQL, SQLite, etc.)
- **Decorators** - @Entity, @Column, @OneToMany, @ManyToMany, etc.
- **BaseEntity** - Provides id, createdAt, updatedAt, deletedAt fields
- **TableNameMapper** - Centralized table name management

## Naming Convention

**See [naming-convention.md](../../../style/naming-convention.md) for complete naming standards.**

- **File:** `kebab-case` (e.g., `project-entity.ts`)
- **Export:** `PascalCase` class (always)
- **Usage:** Instantiate with `new` operator (typically in DAL)
- **Location:** `src/dal/typeorm/entity/[domain]-entity.ts`

## Purpose

TypeORM entities define the database schema and structure for SQL databases. They:
- Map TypeScript classes to database tables
- Define column types, constraints, and relationships
- Store only necessary properties (no computed values)
- Provide a bridge between database and domain models

## Structure

### Basic Entity

```typescript
// src/dal/typeorm/entity/project-entity.ts
import { ParserType } from '@app/common/business/model/core/parser-type'
import {
  ProjectModelCreate,
  ProjectModelEdit,
  ProjectModelInterface,
  ProjectParserPayload,
  ProjectSourceType,
} from '@app/common/business/model/core/project-model'
import { AppendNullToUndefined, baseModelService } from '@app/common/business/service/base-model-service'
import { BaseEntity } from '@app/node-common/business/component/data-store/typeorm'
import { Column, Entity, Unique } from 'typeorm'

import { TableNameMapper } from '#src/lib/typeorm/index'

export interface ProjectEntityInterface<PARSER_TYPE extends ParserType = any>
  extends AppendNullToUndefined<ProjectModelInterface<PARSER_TYPE>> {}

@Unique(['ownerId', 'sourceUrl'])
@Entity({ name: TableNameMapper.PROJECT })
export class ProjectEntity<PARSER_TYPE extends ParserType = any>
  extends BaseEntity
  implements ProjectEntityInterface
{
  constructor(params?: ProjectEntityInterface) {
    super(params)
    if (!params) return

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

### Entity with Relationships

```typescript
// src/dal/typeorm/entity/project-entity.ts
import { BaseEntity } from '@app/node-common/business/component/data-store/typeorm'
import { Column, Entity, JoinTable, ManyToMany, OneToMany, Relation, Unique } from 'typeorm'

import { ProjectParseDataEntity } from '#src/dal/typeorm/entity/project-parse-data-entity'
import { SecretEntity } from '#src/dal/typeorm/entity/secret-entity'
import { TableNameMapper } from '#src/lib/typeorm/index'

@Unique(['ownerId', 'sourceUrl'])
@Entity({ name: TableNameMapper.PROJECT })
export class ProjectEntity extends BaseEntity {
  constructor(params?: ProjectEntityInterface) {
    super(params)
    if (!params) return

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

### Entity with Custom Column Options

```typescript
// src/dal/typeorm/entity/user-entity.ts
import { BaseEntity } from '@app/node-common/business/component/data-store/typeorm'
import { Column, Entity, Index, Unique } from 'typeorm'

import { TableNameMapper } from '#src/lib/typeorm/index'

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

## TypeORM Decorators

### Entity Decorators

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

### Column Decorators

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

### Relationship Decorators

#### One-to-Many

```typescript
@OneToMany(() => ProjectParseDataEntity, (parseData) => parseData.project)
parseDatas?: Relation<ProjectParseDataEntity[]>
```

#### Many-to-One

```typescript
@ManyToOne(() => ProjectEntity, (project) => project.parseDatas)
@JoinColumn({ name: 'project_id' })
project?: Relation<ProjectEntity>
```

#### Many-to-Many

```typescript
// Owner side (with join table)
@ManyToMany(() => SecretEntity, (secret) => secret.projects)
@JoinTable({ name: 'project_to_secret' })
secrets?: Relation<SecretEntity[]>

// Inverse side
@ManyToMany(() => ProjectEntity, (project) => project.secrets)
projects?: Relation<ProjectEntity[]>
```

#### One-to-One

```typescript
// Owner side
@OneToOne(() => ProfileEntity, (profile) => profile.user)
@JoinColumn({ name: 'profile_id' })
profile?: Relation<ProfileEntity>

// Inverse side
@OneToOne(() => UserEntity, (user) => user.profile)
user?: Relation<UserEntity>
```

## Column Types

### PostgreSQL Types

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

## Table Name Mapping

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

## BaseEntity Fields

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

## Constructor Pattern

```typescript
constructor(params?: ProjectEntityInterface) {
  super(params) // Initialize base fields
  if (!params) return

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

## Architectural Rules

### ✅ DO

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

### ❌ DON'T

- Store computed/derived values that can be calculated
- Include business logic in entities
- Use entities directly in Service/Use Case layers (DAL converts to models)
- Mix entity concerns with transport concerns
- Skip null handling in constructor
- Hardcode table names (use TableNameMapper)
- Use TypeORM outside of DAL layer

## Migrations

### Creating Migrations

```bash
npm run typeorm migration:generate -- -n CreateProjectTable
```

### Running Migrations

```bash
npm run typeorm migration:run
```

### Reverting Migrations

```bash
npm run typeorm migration:revert
```

### Example Migration

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

## Testing Entities

For testing patterns and examples, use the **test-typescript** skill.

## Relationship with Other Layers

```
DAL (TypeORM) → Entity (TypeORM) → Database Table
                    ↓
               Schema Definition
               Type Mapping
               Relationship Definition
```

TypeORM entities provide the schema definition and type mapping between TypeScript classes and database tables, ensuring type safety and proper data structure throughout the persistence layer.
