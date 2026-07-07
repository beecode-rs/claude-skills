# Validation Pattern (Zod)

This document defines validation patterns using Zod schemas for request validation, type inference, and error handling.

## Core Principles

- **Validate at boundaries**: All external inputs (HTTP requests, messages, events) must be validated
- **Single source of truth**: Zod schemas define both validation AND TypeScript types
- **Fail fast**: Reject invalid requests before they reach business logic
- **Clear error messages**: Errors must be actionable for API consumers

## Schema Organization

### File Structure

```
src/
├── controller/
│   └── express/
│       └── feature-name/
│           ├── get-feature-all.ts      # Schemas inline for simple cases
│           └── schemas/                # Folder for complex/shared schemas
│               └── feature-schemas.ts
```

### When to Inline vs Extract

| Scenario | Approach |
|----------|----------|
| Schema used once | Inline in handler file |
| Schema reused across handlers | Extract to `schemas/` folder |
| Schema shared with other layers | Extract to `src/model/` |

## Schema Definition Patterns

### Request Query Parameters

```typescript
import { z } from 'zod'

const reqQueryParamsSchema = z.object({
  filter: z
    .object({
      status: z.enum(['active', 'inactive']).optional(),
      search: z.string().optional(),
    })
    .optional(),
  pagination: z
    .object({
      page: z.coerce.number().int().min(1).default(1),
      limit: z.coerce.number().int().min(1).max(100).default(20),
    })
    .optional(),
})

type ReqQueryParams = z.infer<typeof reqQueryParamsSchema>
```

### Request Body

```typescript
const createProjectBodySchema = z.object({
  name: z.string().min(1).max(255),
  description: z.string().max(2000).optional(),
  sourceUrl: z.string().url(),
  tags: z.array(z.string()).max(10).optional(),
})

type CreateProjectBody = z.infer<typeof createProjectBodySchema>
```

### Path Parameters

```typescript
const pathParamsSchema = z.object({
  projectId: z.string().uuid(),
})

type PathParams = z.infer<typeof pathParamsSchema>
```

### Response Schema

```typescript
const projectResponseSchema = z.object({
  id: z.string().uuid(),
  name: z.string(),
  description: z.string().nullable(),
  createdAt: z.number(),
  updatedAt: z.number(),
})

const projectListResponseSchema = z.object({
  data: z.array(projectResponseSchema),
  meta: z.object({
    pagination: z.object({
      page: z.number(),
      limit: z.number(),
      total: z.number(),
      totalPages: z.number(),
    }),
  }),
})
```

## Validation in Handlers

### Standard Pattern

```typescript
import { validationUtil } from '@app/node-common/util/validation'

export const getProjectsAll = {
  handler: new HttpUtil().expressEndPoint(async (req) => {
    const { filter, pagination } = validationUtil.parse(
      new HttpUtil().expressQueryToJsonParser(req.query),
      reqQueryParamsSchema
    )

    const result = await new ProjectRepo().findMany({ filter, pagination })

    return result
  }),
  schema: {
    querystring: reqQueryParamsSchema,
    response: {
      200: projectListResponseSchema,
    },
  },
}
```

### Validation Utility Pattern

If your project has a validation utility, follow its pattern:

```typescript
validationUtil.parse(data, schema)
```

This typically:
1. Parses the data against the schema
2. Throws a structured validation error on failure
3. Returns the typed result on success

## Common Schema Patterns

### Optional Fields with Defaults

```typescript
const schema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  sortBy: z.enum(['createdAt', 'name']).default('createdAt'),
  sortOrder: z.enum(['asc', 'desc']).default('desc'),
})
```

### Nullable vs Optional

```typescript
const schema = z.object({
  name: z.string(),                    // Required, cannot be null/undefined
  description: z.string().optional(),  // Can be undefined, but not null
  deletedAt: z.number().nullable(),    // Can be null, but not undefined
  notes: z.string().nullable().optional(), // Can be null OR undefined
})
```

### String Formats

```typescript
const schema = z.object({
  email: z.string().email(),
  url: z.string().url(),
  uuid: z.string().uuid(),
  date: z.string().datetime(),
  phone: z.string().regex(/^\+?[1-9]\d{1,14}$/),
})
```

### Array Validation

```typescript
const schema = z.object({
  tags: z.array(z.string()).min(1).max(10),
  ids: z.array(z.string().uuid()).nonempty(),
  items: z.array(
    z.object({
      id: z.string(),
      quantity: z.number().int().positive(),
    })
  ),
})
```

### Discriminated Unions

```typescript
const schema = z.discriminatedUnion('type', [
  z.object({
    type: z.literal('email'),
    email: z.string().email(),
  }),
  z.object({
    type: z.literal('phone'),
    phone: z.string(),
  }),
])
```

### Transform and Refine

```typescript
const schema = z.object({
  email: z.string().email().transform((val) => val.toLowerCase()),
  startDate: z.string().transform((val) => new Date(val).getTime()),
  confirmPassword: z.string(),
}).refine(
  (data) => data.password === data.confirmPassword,
  { message: 'Passwords do not match', path: ['confirmPassword'] }
)
```

## Error Handling

### Validation Error Response

Validation errors should return structured responses:

```typescript
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid request parameters",
    "details": [
      {
        "field": "body.email",
        "message": "Invalid email format",
        "code": "invalid_string_email"
      },
      {
        "field": "body.age",
        "message": "Number must be greater than or equal to 18",
        "code": "too_small"
      }
    ]
  }
}
```

### Custom Error Messages

```typescript
const schema = z.object({
  email: z.string().email('Please enter a valid email address'),
  password: z
    .string()
    .min(8, 'Password must be at least 8 characters')
    .regex(/[A-Z]/, 'Password must contain at least one uppercase letter')
    .regex(/[0-9]/, 'Password must contain at least one number'),
})
```

## Type Inference

### Single Source of Truth

Always derive TypeScript types from Zod schemas:

```typescript
const createProjectSchema = z.object({
  name: z.string().min(1),
  description: z.string().optional(),
})

type CreateProjectInput = z.infer<typeof createProjectSchema>

const processProject = async (input: CreateProjectInput) => {
  // TypeScript knows the exact shape
}
```

### Never Duplicate Types

```typescript
type CreateProjectInput = z.infer<typeof createProjectSchema>

type CreateProjectInput = {  // ❌ NEVER do this
  name: string
  description?: string
}
```

## Best Practices

### DO

- Validate all external inputs at controller layer
- Use `z.coerce` for query parameters (strings from URL)
- Derive types with `z.infer<typeof schema>`
- Use descriptive error messages
- Keep schemas close to where they're used

### DON'T

- Validate in business logic layer (already validated at boundary)
- Duplicate type definitions
- Use overly permissive schemas (`z.any()`, `z.record(z.unknown())`)
- Skip validation for "internal" APIs
- Put business rules in validation schemas (use business layer instead)

## Schema Naming Conventions

| Schema Type | Naming Pattern | Example |
|-------------|----------------|---------|
| Request query | `reqQueryParamsSchema` | `reqQueryParamsSchema` |
| Request body | `<action>BodySchema` | `createProjectBodySchema` |
| Path params | `pathParamsSchema` | `pathParamsSchema` |
| Response | `<resource>ResponseSchema` | `projectResponseSchema` |
| Response list | `<resource>ListResponseSchema` | `projectListResponseSchema` |

## Related Patterns

- [express-handler-pattern.md](express-handler-pattern.md) - How to use schemas in handlers
- [function-guidelines.md](../style/function-guidelines.md) - Error handling patterns
