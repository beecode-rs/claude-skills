# Null vs Undefined Pattern

## The Rule

**Business Logic Layer uses ONLY `undefined`. `null` lives ONLY in the DAL/Entity layer.**

This is a strict boundary rule that applies across all business layers:
- Service Layer
- Repository Layer
- Component Layer
- Use Case Layer

## Layer Boundaries

```
┌─────────────────────────────────────────────────────────────────┐
│                    BUSINESS LOGIC LAYER                         │
│  (Service, Repository, Component, Use Case)                     │
│                                                                 │
│  ✅ Use: undefined                                              │
│  ❌ Never use: null                                             │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ Boundary conversion
                              │ undefined ↔ null
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    DAL / ENTITY LAYER                           │
│  (TypeORM, database-specific code)                              │
│                                                                 │
│  ✅ Use: null (for database compatibility)                      │
└─────────────────────────────────────────────────────────────────┘
```

## Why This Matters

1. **TypeScript convention**: `undefined` is the idiomatic way to represent missing values in TypeScript
2. **Database compatibility**: SQL databases use `NULL`, TypeORM expects `null`
3. **Clear boundaries**: Explicit conversion at the DAL boundary makes data flow obvious
4. **Consistency**: All business logic code uses the same convention

## Business Logic Layer (✅ undefined)

All business layers use `undefined` for optional/missing values:

```typescript
// ✅ CORRECT - Service Layer
export const userService = {
  async findByIdIfExists(params: { id: string }): Promise<User | undefined> {
    return userRepo.findOneByIdIfExists(params).catch(() => undefined)
  }
}

// ✅ CORRECT - Repository Layer
export class UserRepo {
  async findOneByIdIfExists(params: { id: string }): Promise<User | undefined> {
    const entity = await this.dal.findOneById(params)
    return entity ? this.entityToModel(entity) : undefined
  }
}

// ✅ CORRECT - Component Layer
export const userComponent = {
  getDisplayName(params: { user: User | undefined }): string {
    return params.user?.name ?? 'Unknown'
  }
}

// ✅ CORRECT - Use Case Layer
export const userUseCase = {
  async getProfile(params: { userId: string }): Promise<UserProfile | undefined> {
    const user = await userService.findByIdIfExists({ id: params.userId })
    if (!user) return undefined
    return profileService.buildProfile({ user })
  }
}
```

## DAL / Entity Layer (null allowed here)

The DAL/Entity layer converts between `undefined` (business) and `null` (database):

```typescript
// ✅ CORRECT - Entity converts undefined → null for database
export class UserEntity extends BaseEntity {
  constructor(params?: UserEntityInterface) {
    super(params)
    if (!params) return

    // Convert undefined → null for database compatibility
    const nullableParams = baseModelService.convertUndefinedToNull(params)
    const { name, email, bio } = nullableParams

    this.name = name
    this.email = email
    this.bio = bio  // Will be null if undefined was passed
  }

  @Column({ nullable: true })
  bio!: string | null
}

// ✅ CORRECT - DAL returns null for not found (TypeORM convention)
export class UserDal extends TypeormCommonDal<...> {
  async findOneById(params: { id: string }): Promise<UserModel | null> {
    const entity = await this._repo.findOne({ where: { id: params.id } })
    return entity ? this.entityToModel(entity) : null
  }
}

// ✅ CORRECT - Repository converts null → undefined at boundary
export class UserRepo {
  async findOneByIdIfExists(params: { id: string }): Promise<UserModel | undefined> {
    const model = await this.dal.findOneById(params)
    return model ?? undefined  // Convert null → undefined at boundary
  }
}
```

## Type Definitions

### Business Models (business/model/ folders)

Business models are the core domain types. They must NEVER use `null`:

```typescript
// ✅ CORRECT - Business model with optional properties
export type UserModel = {
  id: string
  name: string
  bio?: string        // Optional = undefined (preferred)
  phone?: string      // Optional = undefined (preferred)
}

// ✅ CORRECT - Alternative: explicit undefined
export type UserModel = {
  id: string
  name: string
  bio: string | undefined
  phone: string | undefined
}

// ❌ WRONG - Never use null in business models
export type UserModel = {
  id: string
  name: string
  bio: string | null    // ❌ NO - use optional instead
  phone: string | null  // ❌ NO - use optional instead
}
```

**Rule**: Prefer optional properties (`?:`) over explicit `| undefined` in business models for cleaner syntax.

### Business Layer Types

```typescript
// ✅ CORRECT - Business layer types use undefined
export type UserModel = {
  id: string
  name: string
  bio?: string  // Optional = undefined
}

export type UserCreate = {
  name: string
  email: string
  phone?: string  // Optional = undefined
}
```

### DAL / Entity Layer Types

```typescript
// ✅ CORRECT - Entity types can use null for database mapping
export interface UserEntityInterface {
  id: string
  name: string
  bio: string | null  // Database nullable column
}

// The AppendNullToUndefined utility helps with conversion
export interface UserEntityInterface
  extends AppendNullToUndefined<UserModelInterface> {}
```

## Summary Table

| Layer | Optional Value Type | Example Return Type |
|-------|---------------------|---------------------|
| Business Model | `undefined` (optional `?`) | `{ name: string, bio?: string }` |
| Service | `undefined` | `User \| undefined` |
| Repository | `undefined` | `User \| undefined` |
| Component | `undefined` | `User \| undefined` |
| Use Case | `undefined` | `User \| undefined` |
| DAL | `null` | `UserModel \| null` |
| Entity | `null` | `string \| null` |

## Architectural Rules

### ✅ DO
- Use `undefined` for optional values in all business layers
- Use optional properties (`?`) in business models (preferred over `| undefined`)
- Convert `undefined` → `null` at Entity constructor boundary
- Convert `null` → `undefined` at Repository/DAL boundary
- Use optional properties (`?`) in business layer types
- Use `AppendNullToUndefined` utility in Entity interfaces

### ❌ DON'T
- Use `null` in business models (any `business/model/` folder)
- Use `null` in Service, Repository, Component, or Use Case layers
- Return `null` from business logic methods
- Define business layer types with `| null`
- Mix `null` and `undefined` in the same layer
- Skip boundary conversion between DAL and business layers
