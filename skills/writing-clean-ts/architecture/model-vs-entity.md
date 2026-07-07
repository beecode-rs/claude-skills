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

A **Model** is a plain TypeScript type/interface that represents data as it moves through the business and controller layers.

- **Location**: `src/business/model/`
- **Pattern**: TypeScript interface or type
- **Naming**: `PascalCase` with optional `Model` suffix (e.g., `Project`, `ProjectModel`)
- **Purpose**: Data transfer, business logic, API responses

```typescript
// src/business/model/project-model.ts
export interface ProjectModel {
  id: string
  name: string
  description: string | null
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

### Base Model

Full representation of a resource:

```typescript
export interface ProjectModel {
  id: string
  name: string
  description: string | null
  createdAt: number
  updatedAt: number
}
```

### Create Model

Input for creating new records:

```typescript
export interface ProjectCreateModel {
  name: string
  description?: string
}
```

### Update Model

Input for updating records:

```typescript
export interface ProjectUpdateModel {
  name?: string
  description?: string | null
}
```

### Filter Model

Query parameters for filtering:

```typescript
export interface ProjectFilterModel {
  status?: 'active' | 'inactive'
  search?: string
  createdAfter?: number
}
```

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
        ├── project-model.ts             # Base model
        ├── project-create-model.ts      # Create input
        ├── project-update-model.ts      # Update input
        └── project-filter-model.ts      # Filter params
```

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
export interface TaskWithProjectModel extends TaskModel {
  project: ProjectModel
}

// Or flattened (if relation not needed)
export interface TaskModel {
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
- Keep Models as plain TypeScript interfaces/types
- Use Models in Service, Repository, Use Case, and Controller layers
- Create specific Model types for different use cases (Create, Update, Filter)

### DON'T

- Use Entities outside the DAL layer
- Put business logic in Entities
- Expose database-specific types in Models
- Transform in Controllers (receive Models from business layer)

## Summary

| Aspect | Entity | Model |
|--------|--------|-------|
| **Type** | Class with decorators | Interface/Type |
| **ORM** | TypeORM | None |
| **Location** | `src/dal/typeorm/entity/` | `src/business/model/` |
| **Used by** | DAL only | Repository, Service, Use Case, Controller |
| **Transforms** | In DAL only | — |
| **Testing** | Requires DB or mocks | Easy to mock |
