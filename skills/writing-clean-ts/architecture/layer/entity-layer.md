# Entity Layer

Entities define the structure of data for persistence mechanisms. Part of the **Model Layer (ML)** used for data persistence.

## Framework Implementations

This is an abstract layer pattern. See framework-specific implementations:
- **[TypeORM Entity](./entity-layer/typeorm.md)** - SQL database entities using TypeORM decorators

## Naming Convention

**See [naming-convention.md](../../style/naming-convention.md) for complete naming standards.**

- **File:** `kebab-case` (e.g., `project-entity.ts`)
- **Export:** `PascalCase` class (always)
- **Usage:** Instantiate with `new` operator (typically in DAL)
- **Location:** `src/dal/[framework]/entity/[domain]-entity.ts`

## Purpose

Entities define domain objects for persistence storage. They represent the data structure in the persistence layer (Repository/DAL) and are distinct from domain models used in the Business Layer.

**Key Distinction:**
- **Entity**: For persistence/storage (database, file, API)
- **Domain Model**: For business logic and operations
- **Transport Object**: For API requests/responses

## Structure

**Framework Implementation**: See [entity-layer-typeorm.md](./entity-layer/typeorm.md) for TypeORM implementation.

**Conceptual Structure:**
```typescript
// Abstract concept - not framework-specific
import {
  ProjectModelCreate,
  ProjectModelEdit,
  ProjectModelInterface,
} from '@app/common/business/model/core/project-model'

export interface ProjectEntityInterface extends ProjectModelInterface {
  // Entity-specific properties
  relatedEntities?: RelatedEntity[]
}

export class ProjectEntity implements ProjectEntityInterface {
  constructor(params?: ProjectEntityInterface) {
    if (!params) return

    // Handle nullable properties (undefined → null for databases)
    const nullableParams = convertUndefinedToNull(params)
    const { name, ownerId, sourceUrl, sourceType, relatedEntities } = nullableParams

    // Assign properties
    this.name = name
    this.ownerId = ownerId
    this.sourceUrl = sourceUrl
    this.sourceType = sourceType

    // Initialize relationships if provided
    if (relatedEntities) {
      this.relatedEntities = relatedEntities.map((e) => new RelatedEntity(e))
    }
  }

  // Base fields (typically provided by base class)
  id!: string
  createdAt!: Date
  updatedAt!: Date
  deletedAt?: Date | null

  // Domain-specific fields
  name!: string
  ownerId!: string
  sourceUrl!: string
  sourceType!: string

  // Relationships (optional)
  relatedEntities?: RelatedEntity[]
}

export type ProjectEntityCreate = ProjectModelCreate
export type ProjectEntityEdit = ProjectModelEdit
```

## Key Characteristics

- **Always uses class pattern** (required for most persistence frameworks)
- **Extends base entity class** (typically provides id, createdAt, updatedAt, deletedAt)
- **For persistence only**: Represents storage structure
- **Store only necessary properties**: Derived properties should be computed on demand
- Uses framework-specific decorators/annotations for schema definition
- Uses relationships definitions (one-to-many, many-to-many, etc.)
- Uses unique constraints and indexes
- Constructor accepts partial object for initialization
- PascalCase class naming: `ProjectEntity`
- Type aliases for Create and Edit operations

## Model Layer Concepts

### Entity vs Domain Model vs Transport Object

1. **Entity**: For Repository/DAL storage
   - Persistence representation
   - Contains only stored properties
   - Used by DAL layer (converted to/from models)
   - Lives in `src/dal/[framework]/entity/`
   - Framework-specific (TypeORM, Mongoose, Prisma, etc.)

2. **Domain Model**: For Business Layer
   - Business representation
   - May include computed/derived properties
   - Used by Service and Use Case layers
   - Lives in `@app/common/business/model/`
   - Framework-agnostic

3. **Transport Object**: For Controller responses
   - API representation
   - Uses validation schemas (Zod, Joi, etc.)
   - May reshape data for client consumption
   - Used by Controller layer
   - Framework-specific to API library

## Common Entity Patterns

### Base Entity Fields

Most entities extend a base class providing:
```typescript
class BaseEntity {
  id: string | number          // Primary key
  createdAt: Date             // Creation timestamp
  updatedAt: Date             // Last update timestamp
  deletedAt?: Date | null     // Soft delete timestamp
}
```

### Relationships

Entities typically define relationships:
- **One-to-Many**: One project has many parse data records
- **Many-to-One**: Many parse data records belong to one project
- **Many-to-Many**: Projects have many secrets, secrets belong to many projects
- **One-to-One**: User has one profile, profile belongs to one user

### Nullable Properties

Entities must handle nullable vs undefined properties:
```typescript
// undefined → null for database compatibility
const nullableParams = convertUndefinedToNull(params)
```

## Architectural Rules

### ✅ DO
- Store only necessary properties in entities
- Compute derived properties in domain models
- Use framework-specific decorators/annotations for schema
- Keep entities focused on data structure
- Use entities only in DAL layer (converted to models for Repository)
- Define entity interfaces for type safety
- Use type aliases for Create and Edit operations
- Handle nullable properties correctly
- Use enums from common library for type safety

### ❌ DON'T
- Store computed/derived values that can be calculated
- Include business logic in entities
- Use entities directly in Service/Use Case layers (DAL converts to models)
- Mix entity concerns with transport concerns
- Skip null handling in constructor
- Use framework-specific code outside DAL layer
