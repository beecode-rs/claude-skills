# @beecode/msh-node-session

Micro-service helper: request-scoped session context (continuation-local storage). Store per-request data (transaction manager, auth user) and retrieve it anywhere in the call chain without passing it through every function.

- **Known version**: `4.0.5` (major 4)
- **Install**: `npm i @beecode/msh-node-session`
- **Depends on**: `@beecode/msh-config`, `cls-hooked`, `express`, `fast-als`, `fastify-plugin`
- **Module type**: ESM

## Contents

- [IMPORTANT: corrections to the upstream README](#important-corrections-to-the-upstream-readme)
- [Public exports (subpath imports - there is no barrel index)](#public-exports-subpath-imports---there-is-no-barrel-index)
- [SessionStrategy contract](#sessionstrategy-contract)
- [NodeSessionUtil](#nodesessionutil)
- [Holding the singleton instance (corrected)](#holding-the-singleton-instance-corrected)
- [Express middleware](#express-middleware)
  - [AsyncLocalStorage (preferred)](#asynclocalstorage-preferred)
  - [FastAls](#fastals)
  - [ClsHooked](#clshooked)
- [Fastify middleware](#fastify-middleware)
- [Which strategy to pick](#which-strategy-to-pick)
- [Breaking changes](#breaking-changes)

## IMPORTANT: corrections to the upstream README

The published README for this package has two stale spots. Follow this reference, not the README, for these:

1. **The README imports `cacheUtil.singleton` from `@beecode/msh-node-util/lib/cache-util.js`.** That package and path no longer exist. The current, correct way to hold a singleton session util is `singletonPattern` from `@beecode/msh-util` (sync) or `SingletonAsync` (async). See the example below and `references/util-3.0.1.md`.
2. **The README only documents `FastAlsStrategy` and `ClsHookedStrategy`.** A third strategy, `AsyncLocalStorageStrategy` (built on Node's native `node:async_hooks`), also exists and is generally the best default for new code because it has no native dependencies. Its Express helper is `expressAsyncLocalStorageHelperFactory`. Use it unless the user has a reason to pick cls-hooked or fast-als.

## Public exports (subpath imports - there is no barrel index)

This package has no main entry index; import each piece by its subpath.

| Export | Import path | Notes |
|--------|-------------|-------|
| `NodeSessionUtil` | `@beecode/msh-node-session/util/node-session-util` | Base class to extend |
| `SessionStrategy` (interface) | `@beecode/msh-node-session/business/service/session-strategy` | The strategy contract |
| `AsyncLocalStorageStrategy` | `@beecode/msh-node-session/business/service/session-strategy/async-local-storage-strategy` | Native Node ALS, no deps (preferred default) |
| `FastAlsStrategy` | `@beecode/msh-node-session/business/service/session-strategy/fast-als-strategy` | fast-als based |
| `ClsHookedStrategy` | `@beecode/msh-node-session/business/service/session-strategy/cls-hooked-strategy` | cls-hooked based (the `NodeSessionUtil` default if none passed) |
| `fastifyHelperFactory` | `@beecode/msh-node-session/business/service/helper/fastify-helper` | Fastify plugin factory |
| `expressAsyncLocalStorageHelperFactory` | `@beecode/msh-node-session/business/service/helper/express-async-local-storage-helper` | Express middleware (ALS) |
| `expressFastAlsHelperFactory` | `@beecode/msh-node-session/business/service/helper/express-fast-als-helper` | Express middleware (fast-als) |
| `expressClsHookedHelperFactory` | `@beecode/msh-node-session/business/service/helper/express-cls-hooked-helper` | Express middleware (cls-hooked) |

## SessionStrategy contract

```typescript
interface SessionStrategy {
	get<T>(key: string): T | undefined
	set<T>(key: string, value: T): void
	clear(key: string): void
	createSession(callback: () => void, options?: { defaultValue?: Record<string, unknown> }): void
}
```

## NodeSessionUtil

`NodeSessionUtil` wraps a strategy and exposes `createAsyncSession` (promise-returning) and `createSession` (sync). It defaults to `ClsHookedStrategy` if you do not pass one. Subclass it to add typed accessors for your session data.

```typescript
import { NodeSessionUtil } from '@beecode/msh-node-session/util/node-session-util'
import { AsyncLocalStorageStrategy } from '@beecode/msh-node-session/business/service/session-strategy/async-local-storage-strategy'
import { type SessionStrategy } from '@beecode/msh-node-session/business/service/session-strategy'

export class SessionUtil extends NodeSessionUtil {
	constructor(params?: { sessionStrategy?: SessionStrategy }) {
		const { sessionStrategy } = params ?? {}
		super({ sessionStrategy })
	}

	public getTransactionManager(): EntityManager | undefined {
		try {
			return this._strategy.get<EntityManager>('typeorm-entity-manager')
		} catch {
			return undefined
		}
	}

	protected _setTransactionManager(em: EntityManager): void {
		this._strategy.set<EntityManager>('typeorm-entity-manager', em)
	}

	public async startTransaction<T>(cb: (em: EntityManager) => Promise<T>): Promise<T> {
		return this.createAsyncSession(() => {
			const existing = this.getTransactionManager()
			if (existing) return cb(existing)
			return databaseService.getConnection().transaction<T>((newEm: EntityManager) => {
				this._setTransactionManager(newEm)
				return cb(newEm)
			})
		})
	}
}
```

## Holding the singleton instance (corrected)

Use `singletonPattern` from `@beecode/msh-util` (NOT the removed `cacheUtil.singleton`):

```typescript
import { singletonPattern } from '@beecode/msh-util'
import { AsyncLocalStorageStrategy } from '@beecode/msh-node-session/business/service/session-strategy/async-local-storage-strategy'
import { SessionUtil } from './session-util'

export const sessionStrategy = new AsyncLocalStorageStrategy()
export const sessionUtil = singletonPattern(() => new SessionUtil({ sessionStrategy }))
// usage: sessionUtil().getTransactionManager()
```

## Express middleware

Pick the helper that matches your strategy.

### AsyncLocalStorage (preferred)

```typescript
import express from 'express'
import { expressAsyncLocalStorageHelperFactory } from '@beecode/msh-node-session/business/service/helper/express-async-local-storage-helper'
import { sessionStrategy } from './util/session-util'

const app = express()
const helper = expressAsyncLocalStorageHelperFactory({ asyncLocalStorageStrategy: sessionStrategy })
app.use((req, res, next) => helper.expressMiddleware(req, res, next))
// ...other middlewares/routes...
```

### FastAls

```typescript
import { expressFastAlsHelperFactory } from '@beecode/msh-node-session/business/service/helper/express-fast-als-helper'
const helper = expressFastAlsHelperFactory({ fastAlsStrategy: sessionStrategy })
app.use((req, res, next) => helper.expressMiddleware(req, res, next))
```

### ClsHooked

Cls-hooked needs an extra emitter-binding middleware:

```typescript
import { expressClsHookedHelperFactory } from '@beecode/msh-node-session/business/service/helper/express-cls-hooked-helper'
const helper = expressClsHookedHelperFactory({ fastAlsStrategy: sessionStrategy })
app.use((req, res, next) => helper.expressMiddleware(req, res, next))
app.use((req, res, next) => helper.expressMiddlewareBindEmitter(req, res, next))
```

## Fastify middleware

```typescript
import Fastify from 'fastify'
import { fastifyHelperFactory } from '@beecode/msh-node-session/business/service/helper/fastify-helper'
import { sessionStrategy } from './util/session-util'

const fastify = Fastify()
const helper = fastifyHelperFactory({ sessionStrategy })
await fastify.register(helper.beecodeSessionContextPluginFactory())
```

## Which strategy to pick

- **`AsyncLocalStorageStrategy`** - preferred for new code. Uses Node's built-in `AsyncLocalStorage`; no extra dependencies; works across async boundaries including native promises.
- **`ClsHookedStrategy`** - the `NodeSessionUtil` default if none is passed. Mature, but `cls-hooked` relies on async hooks monkey-patching and can be fragile with some native APIs.
- **`FastAlsStrategy`** - fast-als based; lighter than cls-hooked but less standard than native ALS.

If the user does not specify, default to `AsyncLocalStorageStrategy` and mention why.

## Breaking changes

No major-version migration guide ships with this package as of the known version. If the user has a different major, fetch `https://raw.githubusercontent.com/beecode-rs/msh-node-session/main/README.md` and `/MIGRATION.md` (see `version-check.md`). If the fetched README still shows the stale `cacheUtil.singleton` import, treat it as a doc bug and use `singletonPattern` from `@beecode/msh-util` as shown above.
