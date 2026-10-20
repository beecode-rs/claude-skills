# Express

Everything Express-specific: where Express controllers live, how they are named, the controller pattern, and the full handler implementation pattern (Zod validation, HttpUtil, Swagger).

## Contents

- [Express In This Skill's Layers](#express-in-this-skills-layers)
- [Express Controller Layer](#express-controller-layer)
  - [Framework](#framework)
  - [Naming Convention](#naming-convention)
  - [Purpose](#purpose)
  - [Structure](#structure)
  - [Router Integration](#router-integration)
  - [Folder Structure](#folder-structure)
  - [Key Characteristics](#key-characteristics)
  - [Request Validation](#request-validation)
  - [Response Formats](#response-formats)
  - [Architectural Rules](#architectural-rules)
  - [Relationship with Other Layers](#relationship-with-other-layers)
- [Express Handler Pattern](#express-handler-pattern)
  - [Naming Convention](#naming-convention-1)
  - [Purpose](#purpose-1)
  - [Full Template Structure](#full-template-structure)
  - [Simplified Example (POST with minimal validation)](#simplified-example-post-with-minimal-validation)
  - [Key Characteristics](#key-characteristics-1)
  - [Response Formats](#response-formats-1)
  - [Query Parameters](#query-parameters-1)
  - [Controller Layer Responsibilities](#controller-layer-responsibilities)
  - [Architectural Rules](#architectural-rules-1)

## Express In This Skill's Layers

| Layer | Pattern | Location |
|-------|---------|----------|
| **Controller** (Express) | Singleton | `src/controller/express/` |

| Layer | File | Export | Example |
|-------|------|--------|---------|
| Controller (Express endpoint) | endpoint-based `.ts` | `camelCase` singleton | `getProjectsAll.handler` |

- **HTTP handlers MUST be in `src/controller/express/`**
- Express controllers are always singleton plain objects (`handler` + `schema`), never classes
- Every payload is validated with zod through the validation util

**Backend Feature layout** (`featureName`):
```
src/
├── controller/express/feature-name.ts          # All endpoints in one file
├── controller/preset/feature-name-preset.ts    # Preconfigured entry points (if applicable)
├── dal/typeorm/
│   ├── entity/feature-name-entity.ts
│   └── feature-name-dal.ts
└── business/
    ├── repo/feature-name-repo.ts
    ├── service/feature-name-service.ts          # or component/ for an encapsulated unit
    ├── service/feature-name/                    # Subfolder when multiple related implementations
    │   ├── impl-a.ts
    │   └── impl-b.ts
    ├── use-case/feature-name-use-case.ts
    └── model/feature-name-model.ts
```

**Express controller shape:**
```typescript
// Express Controller - Always singleton
export const getProjectsAll = {
  handler: new HttpUtil().expressEndPoint(async (req) => {
    const { filter, pagination } = validationUtil.parse(
      new HttpUtil().expressQueryToJsonParser(req.query),
      reqQueryParamsSchema
    )
    return await new ProjectRepo().findMany({ filter, pagination })
  }),
  schema: { /* Swagger schema */ }
}
```

## Express Controller Layer

Express controllers handle REST API endpoints with Zod validation and structured error handling. Part of the **Controller Layer (CL)** for HTTP interfaces.

### Framework

This implementation uses:
- **Express** - HTTP server framework
- **Zod** - Schema validation
- **HttpUtil** - Response wrapper and error handling
- **Swagger** - API documentation generation

### Naming Convention

- **File:** `kebab-case` (e.g., `get-projects-all.ts`, `post-project.ts`)
- **Export:** `camelCase` plain object (always)
- **Pattern:** Always plain objects (handler + schema properties for Express)
- **Location:** `src/controller/express/[domain]/`

### Purpose

Express controllers provide REST API endpoints that:
- Validate HTTP request inputs (headers, params, query, body)
- Transform data between HTTP format and business format
- Delegate business logic to Service/Use Case layers
- Return structured HTTP responses with proper status codes
- Generate Swagger/OpenAPI documentation

### Structure

#### Complete Template

```typescript
// src/controller/express/[domain]/get-[resources]-all.ts
import { type Request, type Response, type NextFunction } from 'express'
import { z } from '@app/common/lib/zod-wrapper'
import { type HttpResponse } from '@app/common/util/http-util'
import { validationUtil } from '@app/common/util/validation-util'
import { HttpUtil } from '@app/node-common/util/http-util'
import { swaggerUtil } from '@app/node-common/util/swagger-util'

import { ProjectRepo } from '#src/business/repo/project-repo'

const reqQueryParamsSchema = z.object({
  filter: z.object({}).loose().optional(),
  pagination: paginationParamSchema.optional(),
  sort: sortSchema.optional(),
})

const resDataSchema = projectModelSchema

type ResData = z.infer<typeof resDataSchema>

const resMetaSchema = z.object({
  pagination: paginationResultSchema,
})

type ResMeta = z.infer<typeof resMetaSchema>

const schema = {
  summary: 'Get all projects',
  tags: ['project'],
  parameters: [...swaggerUtil.objectToParams(reqQueryParamsSchema, 'query')],
  responses: {
    '2xx': swaggerUtil.responseSchema(
      {
        type: 'object',
        required: ['data'],
        properties: {
          data: {
            type: 'array',
            items: swaggerUtil.contentSchema(resDataSchema),
          },
          meta: swaggerUtil.contentSchema(resMetaSchema),
        },
      },
      { description: 'Success' }
    ),
    default: {
      description: 'Error message',
    },
  },
}

export const getProjectsAll = {
  handler: new HttpUtil().expressEndPoint(
    async (req: Request): Promise<HttpResponse<{ data: ResData; meta: ResMeta }>> => {
      const { filter, pagination, sort } = validationUtil.parse(
        new HttpUtil().expressQueryToJsonParser(req.query),
        reqQueryParamsSchema
      )

      const { data, pagination: paginationResult } = await new ProjectRepo().findMany({
        filter,
        pagination,
        sort,
      })

      return { data, meta: { pagination: paginationResult } }
    },
    { dataSchema: resDataSchema }
  ) as (req: Request, res: Response, next: NextFunction) => Promise<void>,
  schema,
}
```

#### POST Endpoint Example

```typescript
// src/controller/express/[domain]/post-[resource].ts
import { type Request, type Response, type NextFunction } from 'express'
import { z } from '@app/common/lib/zod-wrapper'
import { type HttpResponse } from '@app/common/util/http-util'
import { validationUtil } from '@app/common/util/validation-util'
import { HttpUtil } from '@app/node-common/util/http-util'
import { swaggerUtil } from '@app/node-common/util/swagger-util'

import { ProjectSourceType } from '#src/business/enum/project-source-type-enum'
import { ProjectRepo } from '#src/business/repo/project-repo'

const reqBodySchema = z.object({
  name: z.string(),
  sourceUrl: z.string().url(),
  sourceType: z.nativeEnum(ProjectSourceType),
})

const resDataSchema = projectModelSchema

type ResData = z.infer<typeof resDataSchema>

const schema = {
  summary: 'Create project',
  tags: ['project'],
  requestBody: swaggerUtil.contentSchema(reqBodySchema),
  responses: {
    '2xx': swaggerUtil.responseSchema(
      {
        type: 'object',
        required: ['data'],
        properties: {
          data: swaggerUtil.contentSchema(resDataSchema),
        },
      },
      { description: 'Success' }
    ),
    default: {
      description: 'Error message',
    },
  },
}

export const postProject = {
  handler: new HttpUtil().expressEndPoint(
    async (req: Request): Promise<HttpResponse<{ data: ResData }>> => {
      const body = validationUtil.parse(req.body, reqBodySchema)

      const project = await new ProjectRepo().create(body)

      return { data: project }
    },
    { dataSchema: resDataSchema }
  ) as (req: Request, res: Response, next: NextFunction) => Promise<void>,
  schema,
}
```

### Router Integration

```typescript
// src/controller/express/router.ts
import { Router } from 'express'
import { expressGuard } from '@app/node-common/business/service/express-guard'

import { getProjectById } from '#src/controller/express/project/get-project-by-id'
import { getProjectsAll } from '#src/controller/express/project/get-projects-all'
import { postProject } from '#src/controller/express/project/post-project'

export const expressRouter = {
  registerRoutes: (): Router => {
    const router = Router()

    // Public routes
    router.get('/', getHealthCheck.handler)

    // Protected routes
    router.use('/projects', expressGuard.accessToken)
    router
      .route('/projects')
      .get(expressGuard.permission('PROJECT.VIEW'), getProjectsAll.handler)
      .post(expressGuard.permission('PROJECT.CREATE'), postProject.handler)

    router
      .route('/projects/:projectId')
      .get(expressGuard.permission('PROJECT.VIEW'), getProjectById.handler)

    return router
  },
}
```

### Folder Structure

```
src/
  controller/
    express/                           # REST API controllers
      project/                         # Domain-based grouping
        get-projects-all.ts            # GET /projects
        post-project.ts                # POST /projects
        get-project-by-id.ts           # GET /projects/:projectId
        patch-project-by-id.ts         # PATCH /projects/:projectId
        delete-project-by-id.ts        # DELETE /projects/:projectId
        swagger-project.ts             # Swagger schema aggregation
        index.ts                       # Re-exports for router
      own/                             # Owner-scoped resources
        project/
          get-own-projects-all.ts      # GET /owns/:ownerId/projects
          post-own-project.ts          # POST /owns/:ownerId/projects
          index.ts
      protected/                       # Internal/service-to-service
        get-protected-health-check.ts
        index.ts
      root/
        get-health-check.ts            # GET /
        swagger-root.ts
      guard.ts                         # Authentication/authorization guards
      router.ts                        # Route registration
      swagger-config.ts                # OpenAPI configuration
```

### Key Characteristics

- **HTTP-specific validation**: Handles request/response concerns
- **Routing and validation only**: No business logic
- **Zod schemas**: Path params, query params, body, and response data
- **HttpUtil wrapper**: Error handling and response formatting
- **Swagger integration**: Auto-generated API documentation
- **Type safety**: Full TypeScript type inference
- **Singleton objects**: Always export as singleton objects (never classes)

### Request Validation

#### Path Parameters

```typescript
const reqPathParamsSchema = z.object({
  projectId: z.string().uuid(),
})

const { projectId } = validationUtil.parse(req.params, reqPathParamsSchema)
```

#### Query Parameters

```typescript
const reqQueryParamsSchema = z.object({
  status: z.nativeEnum(ProjectStatus).optional(),
  limit: z.number().int().positive().optional(),
})

const { status, limit } = validationUtil.parse(
  new HttpUtil().expressQueryToJsonParser(req.query),
  reqQueryParamsSchema
)
```

#### Request Body

```typescript
const reqBodySchema = z.object({
  name: z.string().min(1),
  email: z.string().email(),
})

const body = validationUtil.parse(req.body, reqBodySchema)
```

#### Request Headers

```typescript
const reqHeadersSchema = z.object({
  'x-api-key': z.string(),
})

const headers = validationUtil.parse(req.headers, reqHeadersSchema)
```

### Response Formats

#### Simple Response

```typescript
return { data: result }
```

#### Array Response

```typescript
return { data: results }
```

#### Paginated Response

```typescript
const resMetaSchema = z.object({
  pagination: paginationResultSchema,
})

type ResMeta = z.infer<typeof resMetaSchema>

return { data, meta: { pagination: paginationResult } }
```

### Architectural Rules

#### ✅ DO

- Validate all request inputs with Zod schemas
- Define response schemas for type safety
- Use `validationUtil.parse()` for validation
- Use `new HttpUtil().expressEndPoint()` wrapper
- Generate Swagger schemas with `swaggerUtil`
- Return `HttpResponse<{ data: T; meta?: object }>`
- Use singleton objects for handler exports
- Create `index.ts` for re-exports in each domain folder
- Delegate all business logic to Service/Use Case layers
- Organize by domain within express folder
- **Call only ONE business layer function per handler** - if multiple calls are needed, create a new service/use-case that orchestrates them
- Keep handlers light: validate → delegate → format response

#### ❌ DON'T

- Include business logic (use Services/Use Cases)
- Access DAL directly (use Repository layer)
- Use classes for Express controllers (always use singleton objects)
- Skip validation (all inputs must be validated)
- Use entities or domain models in responses (use models/DTOs)
- Call `httpUtil()` or `validationUtil()` as functions
- Use Joi (use Zod instead)
- Access Repository in simple CRUD (use Service for consistency)
- **Call multiple business layer functions in one handler** - create a service/use-case to orchestrate multiple operations
- Put business logic in handlers (validate → delegate → format only)

### Relationship with Other Layers

```
HTTP Request → Express Router → Express Controller → Service/Use Case → Repository → DAL → Database
                                      ↓
                                 Validation
                                 Transform
                                 Route
```

Express controllers are the entry point for HTTP traffic, validating inputs and delegating to the business layer, ensuring clean separation between transport and business logic.

## Express Handler Pattern

Express handlers use Zod validation and HttpUtil wrapper to process HTTP requests in REST API endpoints. Part of the **Controller Layer (CL)**.

### Naming Convention

- **File:** `kebab-case` (e.g., `get-projects-all.ts`, `post-project.ts`)
- **Export:** `camelCase` plain object (always)
- **Pattern:** Always plain objects (handler + schema properties)

### Purpose

The Controller Layer provides centralized entry points for all actions (RestAPI, MessageQueue, CronJob, EventBus). Handlers manage routing, validation, data transformation, and delegate business logic to the Business Layer.

### Full Template Structure

Complete REST API endpoint template with all request/response types:

```typescript
// src/controller/express/[domain]/post-[action].ts
import { type Request, type Response, type NextFunction } from 'express'
import { z } from '@app/common/lib/zod-wrapper'
import { type HttpResponse } from '@app/common/util/http-util'
import { validationUtil } from '@app/common/util/validation-util'
import { HttpUtil } from '@app/node-common/util/http-util'
import { swaggerUtil } from '@app/node-common/util/swagger-util'
import { featureService } from '../../../business/service/feature-service'

// Request Headers Schema
export const reqHeadersSchema = z.object({
  // Add header validation here (e.g., authorization, content-type)
})
export type ReqHeaders = z.infer<typeof reqHeadersSchema>

// Path Parameters Schema
export const reqPathParamsSchema = z.object({
  featureId: z.string().uuid()
})
export type ReqPathParams = z.infer<typeof reqPathParamsSchema>

// Query Parameters Schema
export const reqQueryParamsSchema = z.object({
  // Add query params here (e.g., filter, sort)
})
export type ReqQueryParams = z.infer<typeof reqQueryParamsSchema>

// Request Body Schema
export const reqBodySchema = z.object({
  name: z.string(),
  description: z.string().optional(),
})
export type ReqBody = z.infer<typeof reqBodySchema>

// Response Data Schema
export const resDataSchema = z.object({
  id: z.string().uuid(),
  successful: z.boolean(),
})
export type ResData = z.infer<typeof resDataSchema>

const schema = {
  summary: 'Create or update feature',
  tags: ['feature'],
  requestBody: swaggerUtil.contentSchema(reqBodySchema),
  parameters: [
    ...swaggerUtil.objectToParams(reqHeadersSchema, 'header'),
    ...swaggerUtil.objectToParams(reqPathParamsSchema, 'path'),
    ...swaggerUtil.objectToParams(reqQueryParamsSchema, 'query'),
  ],
  responses: {
    // eslint-disable-next-line @typescript-eslint/naming-convention
    '2xx': swaggerUtil.responseSchema(
      {
        type: 'object',
        required: ['data'],
        properties: {
          data: {
            type: 'array',
            items: swaggerUtil.contentSchema(resDataSchema),
          },
        },
      },
      { description: 'Success response' }
    ),
    default: {
      description: 'Error message',
    },
  },
}

export const postFeatureAction = {
  handler: new HttpUtil().expressEndPoint(
    async (req: Request): Promise<HttpResponse<{ data: ResData }>> => {
      // Validate all request parts
      const {} = validationUtil.parse(req.headers, reqHeadersSchema)
      const { featureId } = validationUtil.parse(req.params, reqPathParamsSchema)
      const {} = validationUtil.parse(new HttpUtil().expressQueryToJsonParser(req.query), reqQueryParamsSchema)
      const body = validationUtil.parse(req.body, reqBodySchema)

      // Call business layer
      const result = await featureService.doSomething({ id: featureId, ...body })

      // Return response - single result
      return { data: [result] }

      // OR for multiple results:
      // const results = await featureService.doSomethingMany(...)
      // return { data: results }
    },
    { dataSchema: resDataSchema }
  ) as (req: Request, res: Response, next: NextFunction) => Promise<void>,
  schema,
}
```

### Simplified Example (POST with minimal validation)

```typescript
// src/controller/express/[domain]/post-[action].ts
import { type Request, type Response, type NextFunction } from 'express'
import { z } from '@app/common/lib/zod-wrapper'
import { type HttpResponse } from '@app/common/util/http-util'
import { validationUtil } from '@app/common/util/validation-util'
import { HttpUtil } from '@app/node-common/util/http-util'
import { swaggerUtil } from '@app/node-common/util/swagger-util'
import { featureService } from '../../../business/service/feature-service'

const reqPathParamsSchema = z.object({
  featureId: z.string().uuid()
})

const reqBodySchema = z.object({
  name: z.string(),
  description: z.string().optional(),
})

const resDataSchema = z.object({
  id: z.string().uuid(),
  successful: z.boolean(),
})

type ResData = z.infer<typeof resDataSchema>

const schema = {
  summary: 'Update feature',
  tags: ['feature'],
  parameters: [...swaggerUtil.objectToParams(reqPathParamsSchema, 'path')],
  requestBody: swaggerUtil.contentSchema(reqBodySchema),
  responses: {
    '2xx': swaggerUtil.responseSchema(
      {
        type: 'object',
        properties: {
          data: {
            type: 'array',
            items: swaggerUtil.contentSchema(resDataSchema),
          },
        },
        required: ['data'],
      },
      { description: 'Success' }
    ),
    default: {
      description: 'Error message',
    },
  },
}

export const postFeatureAction = {
  handler: new HttpUtil().expressEndPoint(
    async (req: Request): Promise<HttpResponse<{ data: ResData }>> => {
      const { featureId } = validationUtil.parse(req.params, reqPathParamsSchema)
      const body = validationUtil.parse(req.body, reqBodySchema)

      const result = await featureService.doSomething({ id: featureId, ...body })

      return { data: [result] }
    },
    { dataSchema: resDataSchema }
  ) as (req: Request, res: Response, next: NextFunction) => Promise<void>,
  schema,
}
```

### Key Characteristics

- **Transport-specific validation**: Handles HTTP request/response concerns
- **Routing and validation only**: No business logic
- Zod schemas for path params, query params, body, and response data
- Uses `validationUtil.parse()` to validate inputs
- Wrapped with `new HttpUtil().expressEndPoint()` for error handling
- Returns `HttpResponse<{ data: T; meta?: object }>` structure
- Export object with `handler` and `schema` properties
- camelCase naming: `postFeatureAction`
- Swagger schema generation with `swaggerUtil`
- Type inference with `z.infer<typeof schema>`

### Response Formats

#### Simple Response (without pagination)

```typescript
return { data: [result], meta: {} }
```

#### Paginated Response

```typescript
const resMetaSchema = z.object({
  pagination: paginationResultSchema,
})

type ResMeta = z.infer<typeof resMetaSchema>

// In handler
const { data, pagination: paginationResult } = await new FeatureRepo().findMany({
  filter,
  pagination
})

return { data, meta: { pagination: paginationResult } }
```

### Query Parameters

For GET endpoints with query parameters, use `expressQueryToJsonParser`:

```typescript
const reqQueryParamsSchema = z.object({
  filter: z.object({}).loose().optional(),
  pagination: paginationParamSchema.optional(),
  sort: sortSchema.optional(),
})

export const getFeatures = {
  handler: new HttpUtil().expressEndPoint(
    async (req: Request): Promise<HttpResponse<{ data: ResData; meta: ResMeta }>> => {
      const { filter, pagination, sort } = validationUtil.parse(
        new HttpUtil().expressQueryToJsonParser(req.query),
        reqQueryParamsSchema
      )

      const { data, pagination: paginationResult } = await new FeatureRepo().findMany({
        filter,
        pagination,
        sort
      })

      return { data, meta: { pagination: paginationResult } }
    },
    { dataSchema: resDataSchema }
  ) as (req: Request, res: Response, next: NextFunction) => Promise<void>,
  schema,
}
```

### Controller Layer Responsibilities

The Controller Layer handles:

1. **REST API controllers** (`controller/express/`)
2. **Event bus handlers** (`controller/rxjs-bus/`)
3. **Message queue handlers** (`controller/rmq/`)
4. **Cron job handlers**

All controllers share the same principle: validate input, call Business Layer, transform output.

### Architectural Rules

#### ✅ DO

- Handle routing and transport-specific validation
- Transform data between transport format and business format
- Delegate all business logic to Service/Use Case layers
- Validate request parameters and body with Zod
- Define response schemas for type safety
- Keep handlers thin and focused on HTTP concerns
- Use `validationUtil.parse()` for all validation
- Use `new HttpUtil().expressEndPoint()` wrapper
- Use `z.infer<typeof schema>` for type inference
- Generate Swagger schemas with `swaggerUtil`
- Instantiate repositories with `new FeatureRepo()`

#### ❌ DON'T

- Include business logic in handlers
- Access Repository or DAL directly (use Service/Use Case)
- Skip validation (all inputs must be validated)
- Use entities or domain models directly (use Transport Objects if needed)
- Mix concerns (keep HTTP logic separate from business logic)
- Use Joi (use Zod instead)
- Use `httpUtil()` or `validationUtil()` as functions (they are not functions)
