# Model vs Entity Pattern

This document explains the distinction between Models and Entities in the TypeScript architecture, when to use each, and how to transform between them.

## Quick Reference

| Concept | Layer | Purpose | Database Aware |
|---------|-------|---------|----------------|
| **Entity** | DAL (TypeORM) | Database table mapping | Yes - ORM decorators |
| **Model** | Business/Controller | Data transfer object | No - plain TypeScript |

## Definitions

### Entity

An **Entity** is a class decorated with TypeORM decorators that maps directly to a database table.

- **Location**: `src/dal/typeorm/entity/`
- **Pattern**: Class with TypeORM decorators
- **Naming**: `PascalCase` with `Entity` suffix (e.g., `ProjectEntity`)
- **Purpose**: Database persistence and querying

```typescript
// src/dal/typeorm/entity/project-entity.ts
import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn } from 'typeorm'

@Entity('project')
export class ProjectEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string

  @Column({ type: 'varchar', length: 255 })
  name!: string

  @Column({ type: 'text', nullable: true })
  description!: string | null

  @CreateDateColumn({ type: 'bigint' })
  createdAt!: number

  @UpdateDateColumn({ type: 'bigint' })
  updatedAt!: number
}
```

### Model

A **Model** is a plain TypeScript `type` that represents data as it moves through the business and controller layers.

- **Location**: `src/business/model/` (in a multi-process app, `src/shared/business/model/` for models both sides use)
- **Pattern**: `type` (never `interface`: an interface exists only for a class to implement). A class only when the model constructs its own defaults (see "Model Classes" below)
- **Naming**: `PascalCase` with the `Model` suffix (`ProjectModel`), file `<name>-model.ts`
- **Purpose**: Data shape for business logic, transfer, and API responses

```typescript
// src/business/model/project-model.ts
export type ProjectModel = {
  id: string
  name: string
  description?: string
  createdAt: number
  updatedAt: number
}
```

## Why Separate Them?

### 1. Decoupling

Entities are tightly coupled to TypeORM and database structure. Models are pure TypeScript, free from ORM concerns.

```
Database Schema ←→ Entity (TypeORM) ←→ Model (Pure TS) ←→ API Response
     ↑                  ↑                  ↑
  PostgreSQL         TypeORM           Business Logic
  specific          specific           and Controllers
```

### 2. Flexibility

- Change database schema → update Entity only
- Change API response shape → update Model only
- Business logic remains unchanged

### 3. Security

Entities may contain sensitive fields (passwords, internal flags). Models expose only what's needed.

### 4. Testing

Models are easy to mock and test without database. Entities require database or complex mocking.

## Transformation Pattern

### DAL Layer: Entity ↔ Model

The DAL layer is responsible for converting between Entities and Models.

```typescript
// src/dal/typeorm/project-dal.ts
export class ProjectDal extends CommonDal<ProjectEntity, ProjectModel> {
  protected _entityToModel(entity: ProjectEntity): ProjectModel {
    return {
      id: entity.id,
      name: entity.name,
      description: entity.description,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    }
  }

  protected _modelToEntity(model: Partial<ProjectModel>): Partial<ProjectEntity> {
    return {
      id: model.id,
      name: model.name,
      description: model.description,
    }
  }
}
```

### Transformation Rules

| Direction | Where | Method |
|-----------|-------|--------|
| Entity → Model | DAL layer | `_entityToModel()` |
| Model → Entity | DAL layer | `_modelToEntity()` |
| Never in | Controller, Service, Use Case | — |

## Model Types

### The Model Triple (co-located, zod-inferred)

A model file exports the base model plus its Create and Edit inputs as `z.infer` of co-located schemas:

```typescript
// src/business/model/core/project-model.ts
const projectModelSchema = z.object({
  id: z.string(),
  name: z.string(),
  createdAt: z.number(),
})
const projectModelCreateSchema = z.object({
  name: z.string(),
  sourceUrl: z.string(),
})
const projectModelEditSchema = z.object({
  name: z.string().optional(),
  sourceUrl: z.string().optional(),
})

export type ProjectModel = z.infer<typeof projectModelSchema>
export type ProjectModelCreate = z.infer<typeof projectModelCreateSchema>
export type ProjectModelEdit = z.infer<typeof projectModelEditSchema>
```

- `XxxModel`: the full representation
- `XxxModelCreate`: the create input (required subset)
- `XxxModelEdit`: the edit input (optional subset)

### Filter Model

Query parameters for filtering:

```typescript
export type ProjectFilterModel = {
  status?: ProjectStatus
  search?: string
  createdAfter?: number
}
```

A closed set of values is an enum from `business/enum/`, never an inline string union (`status?: 'active' | 'inactive'`).

### Type-Only Model Files

Model files that are plain types (not zod-backed record shapes) carry NO `-model` suffix: `pagination.ts` (`PaginationParam`, `PaginationResult`), `sort.ts` (`Sort`).

### Model Classes

A model may be a class when it owns how a valid instance is built: its defaults and the normalization of raw input. The settings model is the typical case: the constructor turns whatever was read from storage (or nothing) into a complete, valid settings object, so no separate "default settings" service is needed.

```typescript
// src/shared/business/model/settings-model.ts
export class SettingsModel {
  readonly trackers: TrackerModel[]
  readonly isLaunchedAtLogin: boolean

  constructor(params: { rawSettings?: unknown } = { rawSettings: undefined }) {
    const { rawSettings } = params
    const parsed = settingsSchema.partial().parse(rawSettings ?? {})

    this.trackers = parsed.trackers ?? []
    this.isLaunchedAtLogin = parsed.isLaunchedAtLogin ?? false
  }
}
```

Construction is the only logic a model class holds. Anything that decides, orchestrates, or talks to other modules is business logic and belongs in a service.

## What a Model File May Contain

The model folder holds models and nothing else. When a model file contains any of the following, split it:

| Found in a model file | Moves to |
|---|---|
| Business logic (planning, calculating, deciding) | a service in `business/service/`; the model file keeps only the types |
| An API client, request builder, or endpoint definitions | the service/repo layer that calls that API |
| An enum | `business/enum/<name>-enum.ts` (one enum per file, export without `Enum` suffix) |
| Hardcoded values (defaults, limits, env-tunable settings) | `util/constant.ts` or `util/config.ts` |
| A type or class named `XxxEntity` | rename to `XxxModel`: entities exist only in the DAL |
| An `interface` | a `type` (unless a class implements it, in which case it is a contract that lives next to that class) |

## File Organization

```
src/
├── dal/
│   └── typeorm/
│       ├── entity/
│       │   └── project-entity.ts        # TypeORM class
│       └── project-dal.ts               # Entity ↔ Model conversion
└── business/
    └── model/
        ├── core/
        │   ├── project-model.ts         # Model triple (Model + Create + Edit, zod-inferred)
        │   └── __tests__/
        │       └── project-model-fake-factory.ts
        └── pagination.ts                # Type-only file (no -model suffix)
```

Models live in domain subfolders (`model/auth/`, `model/core/`, `model/common/`) with `__tests__/` fake factories next to them.

## Common Patterns

### Related Models

When entities have relations, models should represent the flattened or nested structure:

```typescript
// Entity with relation
@Entity('task')
export class TaskEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string

  @Column()
  projectId!: string

  @ManyToOne(() => ProjectEntity)
  project!: ProjectEntity
}

// Model with nested relation (if needed)
export type TaskWithProjectModel = TaskModel & {
  project: ProjectModel
}

// Or flattened (if relation not needed)
export type TaskModel = {
  id: string
  projectId: string
  // project data not included
}
```

### Model vs DTO

| Term | Usage | Location |
|------|-------|----------|
| **Model** | Internal data representation | `src/business/model/` |
| **DTO** | API request/response shapes | Defined in controller schemas |
| **Entity** | Database mapping | `src/dal/typeorm/entity/` |

In this architecture, Zod schemas in controllers often serve as DTOs, while Models are the internal representation.

## Best Practices

### DO

- Transform Entity → Model in DAL layer only
- Keep Models as plain TypeScript `type`s (or a class that only constructs its defaults)
- Keep the model folder models-only: enums in `business/enum/`, logic in services, values in `constant`/`config`
- Use Models in Service, Repository, Use Case, and Controller layers
- Create specific Model types for different use cases (Model, ModelCreate, ModelEdit, plus filter params when needed)

### DON'T

- Use Entities outside the DAL layer
- Put business logic in Entities
- Expose database-specific types in Models
- Transform in Controllers (receive Models from business layer)

## Summary

| Aspect | Entity | Model |
|--------|--------|-------|
| **Type** | Class with decorators | `type` (class only for construction defaults) |
| **ORM** | TypeORM | None |
| **Location** | `src/dal/typeorm/entity/` | `src/business/model/` |
| **Used by** | DAL only | Repository, Service, Use Case, Controller |
| **Transforms** | In DAL only | — |
| **Testing** | Requires DB or mocks | Easy to mock |
