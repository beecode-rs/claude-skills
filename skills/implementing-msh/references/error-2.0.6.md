# @beecode/msh-error

Micro-service helper: errors with HTTP codes. Throw typed, HTTP-aware errors with optional payload, and a ready-made Express error-handling middleware.

- **Known version**: `2.0.6` (major 2)
- **Install**: `npm i @beecode/msh-error`
- **Depends on**: `@beecode/msh-config`, `express`
- **Module type**: ESM

## Contents

- [Public exports](#public-exports)
- [errorFactory](#errorfactory)
- [errorHOF](#errorhof)
- [Express middleware](#express-middleware)
- [ErrorBaseModel](#errorbasemodel)
- [HttpResponseCodeMapper](#httpresponsecodemapper)
- [Breaking changes (v1 to v2)](#breaking-changes-v1-to-v2)

## Public exports

From the main entry `@beecode/msh-error`:

| Export | Kind | Notes |
|--------|------|-------|
| `errorFactory` | function | `errorFactory().client.forbidden(...)` etc.; the headline API |
| `errorHOF` | function | Lower-level: takes an `HttpResponseCodeMapper`, returns a closure that creates `ErrorBaseModel` |

Other public symbols (`ErrorBaseModel`, `HttpResponseCodeMapper`, `expressMiddleware`, `httpResponseCodeUtil`) are reachable via subpath imports under `dist/business/...` (see Migration below). Prefer the main entry for `errorFactory`/`errorHOF`.

## errorFactory

The factory is grouped by HTTP category (`client`, `server`) and method-named by status. Each method accepts: no args, a string message, or `{ message, payload }`.

```typescript
import { errorFactory } from '@beecode/msh-error'

// default message
throw errorFactory().client.forbidden()
// FORBIDDEN: 403 - FORBIDDEN
// { httpCode: 403, payload: undefined }

// custom message
throw errorFactory().client.forbidden('Some custom message')

// message + payload
throw errorFactory().client.forbidden({ message: 'Some custom message', payload: { some: 'custom', data: 'here' } })
// { httpCode: 403, payload: { some: 'custom', data: 'here' } }
```

Common methods include `.client.unauthorized()` (401), `.client.forbidden()` (403), `.client.notFound()` (404), `.client.badRequest()` (400), `.server.internalServerError()` (500). The full set mirrors `HttpResponseCodeMapper`.

## errorHOF

`errorHOF` is the lower-level building block behind `errorFactory`. Use it for a status code the factory's predefined methods do not cover. It takes an `HttpResponseCodeMapper` enum value and returns a closure that creates `ErrorBaseModel` instances.

```typescript
import { errorHOF, HttpResponseCodeMapper } from '@beecode/msh-error'

const serviceUnavailable = errorHOF(HttpResponseCodeMapper.SERVICE_UNAVAILABLE)

throw serviceUnavailable('Service is down for maintenance')
throw serviceUnavailable('Service is down', { retryAfter: 60 })
```

## Express middleware

`expressMiddleware` is a ready-made Express error-handling middleware. It catches thrown `ErrorBaseModel` instances and responds with the matching HTTP status and a JSON body. Unknown errors fall back to 500. Register it as the last middleware (a 4-argument error handler).

```typescript
import express from 'express'
import { expressMiddleware, errorFactory } from '@beecode/msh-error'

const app = express()
// ... your routes ...

app.use(expressMiddleware) // last

app.get('/protected', (_req, _res) => {
	throw errorFactory().client.unauthorized()
	// Responds: { "code": 401, "message": "UNAUTHORIZED: 401 - UNAUTHORIZED", "status": "error" }
})
```

## ErrorBaseModel

The base error class all package errors extend. Extends native `Error` and adds `httpCode` and `payload`. Use `instanceof` to identify these in catch blocks.

```typescript
import { ErrorBaseModel } from '@beecode/msh-error'

try {
	// something that throws
} catch (err) {
	if (err instanceof ErrorBaseModel) {
		console.log(err.httpCode) // e.g. 403
		console.log(err.payload) // e.g. { some: 'data' }
	}
}
```

Construct one directly:

```typescript
import { ErrorBaseModel, HttpResponseCodeMapper } from '@beecode/msh-error'

const error = new ErrorBaseModel({
	httpCode: HttpResponseCodeMapper.BAD_REQUEST,
	message: 'Invalid input',
	payload: { field: 'email', reason: 'required' },
})
```

## HttpResponseCodeMapper

Enum of standard HTTP status codes (1xx to 5xx). Use with `errorHOF` or when constructing `ErrorBaseModel` directly.

```typescript
import { HttpResponseCodeMapper } from '@beecode/msh-error'
// HttpResponseCodeMapper.BAD_REQUEST           // 400
// HttpResponseCodeMapper.UNAUTHORIZED          // 401
// HttpResponseCodeMapper.FORBIDDEN             // 403
// HttpResponseCodeMapper.NOT_FOUND             // 404
// HttpResponseCodeMapper.INTERNAL_SERVER_ERROR // 500
```

## Breaking changes (v1 to v2)

v2 restructured internals into clean architecture layers (`business/model/`, `business/service/`). The main entry point is **unchanged**; only direct subpath imports moved.

| Old path | New path |
|---|---|
| `dist/error/factory` | `dist/business/service/error-factory` |
| `dist/error/hof` | `dist/business/service/error-hof` |
| `dist/error/base-model` | `dist/business/model/error-base-model` |
| `dist/http-response-code` | `dist/business/model/http-response-code-mapper` |
| `dist/express/middleware` | `dist/business/service/express-middleware` |
| `dist/util/string-util` | removed |

`stringUtil.codeNameFromEnum()` moved to `httpResponseCodeUtil.codeNameFromEnum()` at `dist/business/model/http-response-code-mapper`.

If the user imports only `errorFactory`/`errorHOF` from the main entry, no migration is needed. If they import from subpaths, update to the `business/...` paths. Full guide: `https://raw.githubusercontent.com/beecode-rs/msh-error/main/MIGRATION.md`.
