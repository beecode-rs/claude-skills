# Express Controller Layer

Express controllers handle REST API endpoints with Zod validation and structured error handling. Part of the **Controller Layer (CL)** for HTTP interfaces.

**See [controller-layer.md](../controller-layer.md) for the abstract controller pattern that applies to all interface types.**

## Framework

This implementation uses:
- **Express** - HTTP server framework
- **Zod** - Schema validation
- **HttpUtil** - Response wrapper and error handling
- **Swagger** - API documentation generation

## Naming Convention

**See [naming-convention.md](../../../style/naming-convention.md) for complete naming standards.**

- **File:** `kebab-case` (e.g., `get-projects-all.ts`, `post-project.ts`)
- **Export:** `camelCase` singleton object (always)
- **Pattern:** Always singleton objects (handler + schema properties for Express)
- **Location:** `src/controller/express/[domain]/`

## Purpose

Express controllers provide REST API endpoints that:
- Validate HTTP request inputs (headers, params, query, body)
- Transform data between HTTP format and business format
- Delegate business logic to Service/Use Case layers
- Return structured HTTP responses with proper status codes
- Generate Swagger/OpenAPI documentation

## Structure

### Complete Template

See [express-handler-pattern.md](../../express-handler-pattern.md) for detailed Express handler implementation patterns.

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

### POST Endpoint Example

```typescript
// src/controller/express/[domain]/post-[resource].ts
import { type Request, type Response, type NextFunction } from 'express'
import { z } from '@app/common/lib/zod-wrapper'
import { type HttpResponse } from '@app/common/util/http-util'
import { validationUtil } from '@app/common/util/validation-util'
import { HttpUtil } from '@app/node-common/util/http-util'
import { swaggerUtil } from '@app/node-common/util/swagger-util'

import { ProjectRepo } from '#src/business/repo/project-repo'

const reqBodySchema = z.object({
  name: z.string(),
  sourceUrl: z.string().url(),
  sourceType: z.enum(['GIT', 'FILE']),
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

## Router Integration

```typescript
// src/controller/express/router.ts
import { Router } from 'express'
import { expressGuard } from '@app/node-common/business/service/express-guard'

import { getProjectsAll, postProject, getProjectById } from './project/index'

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

## Folder Structure

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

## Key Characteristics

- **HTTP-specific validation**: Handles request/response concerns
- **Routing and validation only**: No business logic
- **Zod schemas**: Path params, query params, body, and response data
- **HttpUtil wrapper**: Error handling and response formatting
- **Swagger integration**: Auto-generated API documentation
- **Type safety**: Full TypeScript type inference
- **Singleton objects**: Always export as singleton objects (never classes)

## Request Validation

### Path Parameters

```typescript
const reqPathParamsSchema = z.object({
  projectId: z.string().uuid(),
})

const { projectId } = validationUtil.parse(req.params, reqPathParamsSchema)
```

### Query Parameters

```typescript
const reqQueryParamsSchema = z.object({
  status: z.enum(['active', 'inactive']).optional(),
  limit: z.number().int().positive().optional(),
})

const { status, limit } = validationUtil.parse(
  new HttpUtil().expressQueryToJsonParser(req.query),
  reqQueryParamsSchema
)
```

### Request Body

```typescript
const reqBodySchema = z.object({
  name: z.string().min(1),
  email: z.string().email(),
})

const body = validationUtil.parse(req.body, reqBodySchema)
```

### Request Headers

```typescript
const reqHeadersSchema = z.object({
  'x-api-key': z.string(),
})

const headers = validationUtil.parse(req.headers, reqHeadersSchema)
```

## Response Formats

### Simple Response

```typescript
return { data: result }
```

### Array Response

```typescript
return { data: results }
```

### Paginated Response

```typescript
const resMetaSchema = z.object({
  pagination: paginationResultSchema,
})

type ResMeta = z.infer<typeof resMetaSchema>

return { data, meta: { pagination: paginationResult } }
```

## Architectural Rules

### ✅ DO

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

### ❌ DON'T

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

## Relationship with Other Layers

```
HTTP Request → Express Router → Express Controller → Service/Use Case → Repository → DAL → Database
                                      ↓
                                 Validation
                                 Transform
                                 Route
```

Express controllers are the entry point for HTTP traffic, validating inputs and delegating to the business layer, ensuring clean separation between transport and business logic.
