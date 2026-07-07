# Timestamp Handling

This document defines the standard approach for handling timestamps in the TypeScript codebase to avoid Date object serialization issues.

## The Problem with Date Objects

When using Date objects in models and sending them through HTTP requests in JSON format, the Date object gets automatically converted to an ISO string format (e.g., `'2022-09-05T11:56:49.769Z'`). This creates problems:

1. The receiving end must convert the string back to a Date object
2. Displaying dates in different formats requires additional parsing
3. Type safety is lost during JSON serialization
4. Timezone handling becomes error-prone

## The Solution: Unix Timestamps in Milliseconds

**Use integer timestamps (Unix time in milliseconds) instead of Date objects.**

Unix timestamp is a way to track time as a running total of milliseconds since the Unix Epoch (January 1st, 1970 at UTC). We use milliseconds because that is the minimal time segment in JavaScript.

### Example Conversion

```typescript
new Date()                                    // => 2022-09-05T12:03:36.614Z
new Date('2022-09-05T12:03:36.614Z').getTime() // => 1662379416614
```

## TypeORM Entity Implementation

### Basic Pattern

All timestamp fields in entities use `number` type with a transformer that handles conversion between JavaScript Date objects (used by TypeORM/PostgreSQL) and Unix timestamps (used in application code).

```typescript
import { typeormUtil } from './util'
import { CreateDateColumn, UpdateDateColumn, DeleteDateColumn, Column } from 'typeorm'

export class ExampleEntity {
  @CreateDateColumn({ ...typeormUtil.timestampColumnOptions })
  createdAt!: number

  @UpdateDateColumn({ ...typeormUtil.timestampColumnOptions })
  updatedAt!: number

  @DeleteDateColumn({ ...typeormUtil.timestampColumnOptions, nullable: true })
  deletedAt?: number | null

  @Column({ ...typeormUtil.timestampColumnOptions, nullable: true })
  disabledAt?: number | null
}
```

### Timestamp Column Options

The `typeormUtil.timestampColumnOptions` provides standard configuration:

```typescript
export const typeormUtil = {
  timestampColumnOptions: {
    type: 'timestamp' as ColumnType,
    precision: 3,  // millisecond precision
    transformer: typeormTransformer.timestampToUnix,
  },
}
```

### Timestamp Transformer

The transformer handles bidirectional conversion between Date and Unix timestamp:

```typescript
export const typeormTransformer = {
  timestampToUnix: {
    // FROM database (Date) TO application (number)
    from(date?: Date): number | undefined {
      if (date === undefined || date === null) {
        return date
      }
      return new TimeUtil().dateToUnix(date)
    },

    // TO database (Date) FROM application (number)
    to(unix?: number | unknown): Date | unknown | undefined {
      const timeUtil = new TimeUtil()
      if (unix === undefined || unix === null) {
        return unix
      }
      if (typeof unix === 'number') {
        return timeUtil.unixToDate(unix)
      }
      // Handle TypeORM FindOperator for query conditions
      if (unix instanceof FindOperator) {
        return new FindOperator(
          unix.type,
          timeUtil.unixToDate(unix.value),
          unix.useParameter,
          unix.multipleParameters,
          unix.getSql,
          unix.objectLiteralParameters
        )
      }
      logger().warn('timestampToUnix transformer unable to format unix', { unix })
      return unix
    },
  } as ValueTransformer,
}
```

## Field Naming Convention

**CRITICAL:** All fields that hold Unix timestamps in milliseconds must use the suffix `At`.

### Standard Names

| Field Name | Purpose | Example Value |
|------------|---------|---------------|
| `createdAt` | When record was created | `1662379416614` |
| `updatedAt` | When record was last updated | `1662379416614` |
| `deletedAt` | When record was soft-deleted | `1662379416614` |
| `disabledAt` | When record was disabled | `1662379416614` |
| `startAt` | When something started | `1662379416614` |
| `endAt` | When something ended | `1662379416614` |
| `verifiedAt` | When something was verified | `1662379416614` |
| `publishedAt` | When something was published | `1662379416614` |

### Distinguishing Between Timestamps

You can use plain `at` when you need to distinguish between creation time and event time:

```typescript
class GpsLocation {
  id: string
  createdAt: number    // When record was saved to database
  lon: number
  lat: number
  at: number           // When GPS location was actually recorded
}
```

## Model Implementation

Models mirror the entity structure but use the same `number` type for timestamps:

```typescript
export interface ProjectModel {
  id: string
  name: string
  createdAt: number      // Unix timestamp in milliseconds
  updatedAt: number      // Unix timestamp in milliseconds
  deletedAt?: number     // Unix timestamp in milliseconds (optional)
}
```

## DAL Entity-Model Conversion

The DAL layer converts between entities (with transformers) and models (plain numbers):

```typescript
export class ProjectDal {
  private toModel(entity: ProjectEntity): ProjectModel {
    return {
      id: entity.id,
      name: entity.name,
      createdAt: entity.createdAt,  // Already number from transformer
      updatedAt: entity.updatedAt,  // Already number from transformer
      deletedAt: entity.deletedAt,  // Already number from transformer
    }
  }

  private toEntity(model: Partial<ProjectModel>): Partial<ProjectEntity> {
    return {
      id: model.id,
      name: model.name,
      createdAt: model.createdAt,  // Number, transformer handles conversion
      updatedAt: model.updatedAt,  // Number, transformer handles conversion
      deletedAt: model.deletedAt,  // Number, transformer handles conversion
    }
  }
}
```

## Working with Timestamps

### Creating Records

```typescript
// Application code - work with numbers
const now = Date.now()  // Returns Unix timestamp in milliseconds

const newProject = {
  name: 'My Project',
  createdAt: now,
  updatedAt: now,
}

// TypeORM will convert to Date automatically via transformer
await projectDal.create(newProject)
```

### Querying with Timestamps

```typescript
import { LessThan, Between } from 'typeorm'

// Find records created in the last 24 hours
const oneDayAgo = Date.now() - (24 * 60 * 60 * 1000)

const recentProjects = await projectRepo.find({
  where: {
    createdAt: LessThan(oneDayAgo)  // Transformer handles conversion
  }
})

// Find records in date range
const startDate = new Date('2024-01-01').getTime()
const endDate = new Date('2024-12-31').getTime()

const projectsInRange = await projectRepo.find({
  where: {
    createdAt: Between(startDate, endDate)  // Transformer handles both
  }
})
```

### Displaying Timestamps

Since timestamps are numbers, you must convert them for display:

```typescript
import { formatUtil } from '@app/common/util/format-util'

// Convert to readable format
const readableDate = formatUtil.timestampToDate(project.createdAt)

// Convert to specific timezone
const londonTime = formatUtil.timestampToDate(project.createdAt, 'Europe/London')

// Relative time (e.g., "2 hours ago")
const relativeTime = formatUtil.timestampToRelative(project.createdAt)
```

## Benefits of This Approach

1. **Type Safety**: Timestamps are always `number` in application code
2. **Serialization**: JSON serialization works seamlessly without conversion
3. **Timezone Awareness**: Forces explicit timezone handling for display
4. **Consistency**: Same type throughout all layers (model, entity, API)
5. **Performance**: No string parsing overhead
6. **Math Operations**: Easy to calculate time differences and ranges

## Important Notes

### Transformer Limitations

The transformer works with:
- Direct property access (entity create/update/read)
- TypeORM FindOperator queries (LessThan, GreaterThan, Between, etc.)

The transformer does NOT work with:
- QueryBuilder when using raw SQL
- Custom raw SQL queries

For QueryBuilder with timestamps:

```typescript
// ✅ GOOD - Use FindOperator (transformer works)
await projectRepo.find({
  where: { createdAt: LessThan(timestamp) }
})

// ❌ BAD - QueryBuilder requires manual conversion
await projectRepo
  .createQueryBuilder('project')
  .where('project.createdAt < :timestamp', {
    timestamp: new TimeUtil().unixToDate(timestamp)  // Manual conversion
  })
  .getMany()
```

### Migration from Date to Unix Timestamps

If migrating existing code:

1. Update entity field types from `Date` to `number`
2. Add `typeormUtil.timestampColumnOptions` to column decorators
3. Update model interfaces to use `number` instead of `Date`
4. Update any code that expects Date objects
5. Database columns remain `timestamp` type (no migration needed)

## Related Documentation

- [naming-convention.md](naming-convention.md) - Complete naming standards
- [entity-layer.md](../architecture/layer/entity-layer.md) - Entity layer patterns
- [dal-layer.md](../architecture/layer/dal-layer.md) - DAL layer patterns
