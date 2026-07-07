# Express Handler Pattern

Express handlers use Zod validation and HttpUtil wrapper to process HTTP requests in REST API endpoints. Part of the **Controller Layer (CL)**.

## Naming Convention

**See [naming-convention.md](../style/naming-convention.md) for complete naming standards.**

- **File:** `kebab-case` (e.g., `get-projects-all.ts`, `post-project.ts`)
- **Export:** `camelCase` singleton object (always)
- **Pattern:** Always singleton objects (handler + schema properties)

## Purpose

The Controller Layer provides centralized entry points for all actions (RestAPI, MessageQueue, CronJob, EventBus). Handlers manage routing, validation, data transformation, and delegate business logic to the Business Layer.

## Full Template Structure

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

## Simplified Example (POST with minimal validation)

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

## Key Characteristics

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

## Response Formats

### Simple Response (without pagination)

```typescript
return { data: [result], meta: {} }
```

### Paginated Response

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

## Query Parameters

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

## Controller Layer Responsibilities

The Controller Layer handles:

1. **REST API controllers** (`controller/express/`)
2. **Event bus handlers** (`controller/rxjs-bus/`)
3. **Message queue handlers** (`controller/rmq/`)
4. **Cron job handlers**

All controllers share the same principle: validate input, call Business Layer, transform output.

## Architectural Rules

### ✅ DO

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

### ❌ DON'T

- Include business logic in handlers
- Access Repository or DAL directly (use Service/Use Case)
- Skip validation (all inputs must be validated)
- Use entities or domain models directly (use Transport Objects if needed)
- Mix concerns (keep HTTP logic separate from business logic)
- Use Joi (use Zod instead)
- Use `httpUtil()` or `validationUtil()` as functions (they are not functions)
