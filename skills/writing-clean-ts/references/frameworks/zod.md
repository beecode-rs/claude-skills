# Zod Validation

Every payload is validated with zod through the validation util, on every interface (HTTP, IPC, bus, queue).

This document defines validation patterns using Zod schemas for request validation, type inference, and error handling.

## Contents

- [Core Principles](#core-principles)
- [Schema Organization](#schema-organization)
  - [File Structure](#file-structure)
  - [When to Inline vs Extract](#when-to-inline-vs-extract)
- [Schema Definition Patterns](#schema-definition-patterns)
  - [Request Query Parameters](#request-query-parameters)
  - [Request Body](#request-body)
  - [Path Parameters](#path-parameters)
  - [Response Schema](#response-schema)
- [Validation in Handlers](#validation-in-handlers)
  - [Standard Pattern](#standard-pattern)
  - [Validation Utility Pattern](#validation-utility-pattern)
- [Validation Outside HTTP (IPC, Bus, Queue)](#validation-outside-http-ipc-bus-queue)
- [Common Schema Patterns](#common-schema-patterns)
  - [Optional Fields with Defaults](#optional-fields-with-defaults)
  - [Nullable vs Optional](#nullable-vs-optional)
  - [String Formats](#string-formats)
  - [Array Validation](#array-validation)
  - [Discriminated Unions](#discriminated-unions)
  - [Transform and Refine](#transform-and-refine)
- [Error Handling](#error-handling)
  - [Validation Error Response](#validation-error-response)
  - [Custom Error Messages](#custom-error-messages)
- [Type Inference](#type-inference)
  - [Single Source of Truth](#single-source-of-truth)
  - [Never Duplicate Types](#never-duplicate-types)
- [Best Practices](#best-practices)
  - [DO](#do)
  - [DON'T](#dont)
- [Schema Naming Conventions](#schema-naming-conventions)

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
│           └── schema/                 # Folder for schemas shared by this controller's handlers
│               └── feature-schema.ts
└── business/
    ├── model/
    ├── enum/
    └── schema/                         # Schemas the business layer uses (sanitizing stored data, shared shapes)
        └── settings-schema.ts
```

### When to Inline vs Extract

| Scenario | Approach |
|----------|----------|
| Schema used once by one handler | Inline in the handler file |
| Schema reused across handlers | Extract to the controller's `schema/` folder |
| Schema used by the business layer (a repo sanitizing persisted settings, a model class parsing raw input) | `business/schema/<name>-schema.ts`, never declared inside a service file |

Folder names are singular (`schema/`, not `schemas/`), like every other folder.

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

## Validation Outside HTTP (IPC, Bus, Queue)

Every controller interface validates its input the same way, not only Express. An Electron IPC handler receives `unknown` from the renderer; it parses that payload with a zod schema through the shared validation util before calling the business layer. Hand-rolled checks on a raw record (`typeof raw.id === 'string' && ...`) are replaced by a schema:

```typescript
// src/main/controller/ipc/usage.ts
const refreshTrackerPayloadSchema = z.object({
  trackerId: z.string(),
})

export const ipcUsage = {
  async refreshTracker(_event: IpcMainInvokeEvent, rawPayload: unknown): Promise<UsageModel> {
    const { trackerId } = validationUtil.parse(rawPayload, refreshTrackerPayloadSchema)

    return await usagePollServiceSingleton().refreshTracker({ trackerId })
  },
}
```

Use the project's existing validation wrapper (`validationUtil.parse` from the common/node-common lib, or the equivalent in the project's `util/`) instead of calling `schema.parse` directly, so every interface produces the same error shape. If the project has no wrapper yet, add one in `util/validation-util.ts` before writing the first handler.

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
