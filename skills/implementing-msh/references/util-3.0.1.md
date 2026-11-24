# @beecode/msh-util

Micro-service helper: shared utilities. Singletons (sync and async), memoize, timeout, time/date helpers, deep clone, joi wrapper, UUID, exhaustive-switch guards, class factory, and an Express error-handler decorator.

- **Known version**: `3.0.1` (major 3)
- **Install**: `npm i @beecode/msh-util`
- **Depends on**: `@beecode/msh-config`, `date-fns`, `date-fns-tz`, `joi`, `lodash.clonedeep`, `rxjs`
- **Module type**: ESM

## Contents

- [Public exports](#public-exports-main-entry-beecodemsh-util)
- [singletonPattern (sync)](#singletonpattern-sync)
- [SingletonAsync (async)](#singletonasync-async)
- [memoizeFactory](#memoizefactory)
- [SingleThresholdPromise](#singlethresholdpromise)
- [timeout](#timeout)
- [TimeUtil](#timeutil)
- [ObjectUtil](#objectutil)
- [JoiUtil](#joiutil)
- [stringUtil / regexUtil / typeUtil](#stringutil--regexutil--typeutil)
- [classFactoryPattern](#classfactorypattern)
- [expressErrorHandler (decorator)](#expresserrorhandler-decorator)
- [Breaking changes](#breaking-changes)

## Public exports (main entry `@beecode/msh-util`)

| Export | Kind | One-line |
|--------|------|----------|
| `singletonPattern` | function | Wrap a factory so its result is computed once and cached (sync) |
| `SingletonAsync` | class | Same for async factories, with cache inspection and cache clearing |
| `memoizeFactory` | function | Memoize a function by its arguments |
| `SingleThresholdPromise` | class | Coalesce concurrent calls to one in-flight promise |
| `timeout` | function | `Promise<void>` that resolves after `ms` |
| `TimeUtil` | class | Date/unix conversions, add-to-date |
| `DurationUnit`, `DurationUnitType` | enum, type | Time units for `addToDate` |
| `ObjectUtil` | class | deepClone, pick, deepStringify, deepEqual, deepNullToUndefined |
| `ObjectType` | type | `Record<string, any>` |
| `JoiUtil` | class | Joi validate/sanitize wrapper that throws `ErrorWithPayload` |
| `ErrorWithPayload` | class | `Error` with a `payload` field |
| `stringUtil` | object | `generateUUID()` |
| `regexUtil` | object | `uuid` regex string |
| `typeUtil` | object | `exhaustiveError`, `exhaustiveMessage` |
| `classFactoryPattern` | function | Turn a class into a `() => new Class(...)` factory |
| `expressErrorHandler` | decorator | Wrap an async Express method so rejections call `next` |
| `ClassType` | type | Constructor type |

## singletonPattern (sync)

Wrap a no-arg factory; the result is computed once and cached. This is the correct replacement for the removed `cacheUtil.singleton`.

```typescript
import { singletonPattern } from '@beecode/msh-util'

export const config = singletonPattern(() => ({ env: process.env.NODE_ENV } as const))
// usage: config().env  // 'prod'
```

## SingletonAsync (async)

Caches an async factory's resolved value. Inspect the cache with `cached()`, drop it with `cleanCache()`.

```typescript
import { SingletonAsync, timeout } from '@beecode/msh-util'

export const configSingleton = new SingletonAsync(async () => {
	await timeout(3000)
	return { env: process.env.NODE_ENV } as const
})

// configSingleton().cache()       // undefined before first resolve
// await configSingleton().promise() // resolves, caches
// configSingleton().cached()      // { env: 'prod' }
```

Note: `SingletonAsync` exposes `cached()` (not `cache()`) and `cleanCache()`. (Older docs may show `cache()`; use `cached()`.)

## memoizeFactory

Memoize by `JSON.stringify(args)`:

```typescript
import { memoizeFactory } from '@beecode/msh-util'

const sum = memoizeFactory((a: number, b: number): number => a + b)
sum(5, 10) // 15, computed
sum(5, 10) // 15, cached
```

## SingleThresholdPromise

Coalesce concurrent calls: while one promise is in flight, later callers share it.

```typescript
import { SingleThresholdPromise } from '@beecode/msh-util'

const refreshTokenSingleThreshold = new SingleThresholdPromise(async () => {
	const old = await refreshTokenService.get()
	return authService.refreshToken({ refreshToken: old })
})

export const authService = {
	refreshToken: async () => refreshTokenSingleThreshold.promise(),
}
```

## timeout

```typescript
import { timeout } from '@beecode/msh-util'

await timeout(3000) // wait 3 seconds
```

## TimeUtil

```typescript
import { TimeUtil, DurationUnit } from '@beecode/msh-util'

const t = new TimeUtil()
t.now()                                  // Date
t.dateToUnix(t.now())                    // ms since epoch
t.dateToUnixSec(t.now())                 // seconds since epoch
t.unixToDate(1678304701991)              // Date from ms
t.unixSecToDate(1678304701)              // Date from seconds
t.addToDate({ date: t.now(), unit: DurationUnit.DAY, value: 1 }) // +1 day
t.addToDate({ date: t.now(), unit: 'MONTH', value: -1 })         // -1 month
```

`DurationUnit` members: `MILLISECOND`, `SECOND`, `MINUTE`, `HOUR`, `DAY`, `WEEK`, `MONTH`, `YEAR`.

## ObjectUtil

```typescript
import { ObjectUtil } from '@beecode/msh-util'

const o = new ObjectUtil()
o.deepClone({ a: 1 })                                   // deep copy (lodash.clonedeep)
o.pickByList({ a: 1, b: 2, c: 3 }, ['a', 'c'])          // { a: 1, c: 3 } (first level only)
o.pickByObjectKeys({ a: 1, b: 2 }, { b: 2 })            // { b: 2 }
o.deepStringify({ a: 1 })                               // deeper than JSON.stringify
o.deepStringify(obj, { isSorted: true, isPrettyPrinted: true, prettyPrintCompactLevel: 0 })
o.deepEqual({ a: 1 }, { a: 1 })                         // true, via sorted stringify
o.deepNullToUndefined({ a: null, b: { c: null } })      // { a: undefined, b: { c: undefined } }
```

## JoiUtil

Wraps Joi. `validate` checks only schema properties; `sanitize` also strips unknown keys (`stripUnknown: true`). Both throw `ErrorWithPayload` on failure.

```typescript
import { JoiUtil } from '@beecode/msh-util'
import Joi from 'joi'

type SomeType = { a: string; b: number }
const schema = Joi.object<SomeType>().keys({
	a: Joi.string().required(),
	b: Joi.number().required(),
}).required()

const joiUtil = new JoiUtil()
const valid = joiUtil.validate({ a: 'a', b: 1 }, schema)       // { a: 'a', b: 1 }
const cleaned = joiUtil.sanitize({ a: 'a', b: 1, extra: 'x' }, schema) // extra stripped
```

`ErrorWithPayload<T>` extends `Error` with a `payload: T` field (the Joi validation error).

## stringUtil / regexUtil / typeUtil

```typescript
import { stringUtil, regexUtil, typeUtil } from '@beecode/msh-util'

stringUtil.generateUUID() // '69bfda25-df3f-46b4-8bbb-955cf5193426'

regexUtil.uuid // UUID regex string for route params: `/users/:userId(${regexUtil.uuid})`

// Exhaustive switch guard - returns Error/never for an unhandled case
type Animal = 'cat' | 'dog' | 'bird'
function makeSound(a: Animal): string {
	switch (a) {
		case 'cat': return 'Meow'
		case 'dog': return 'Woof'
		case 'bird': return 'Tweet'
		default: throw typeUtil.exhaustiveError('Unknown animal', a) // `a` is `never` here
	}
}
// typeUtil.exhaustiveMessage(msg, _) returns the message string instead of throwing
```

## classFactoryPattern

Convert `new Class(...args)` into a function call `factory(...args)`:

```typescript
import { classFactoryPattern } from '@beecode/msh-util'

class SomeClass {
	constructor(protected _a: string) {}
	get param(): string { return this._a }
}
const someClassFactory = classFactoryPattern(SomeClass)
const instance = someClassFactory('test') // same as new SomeClass('test')
```

## expressErrorHandler (decorator)

Wraps an async Express route/controller method so a rejected promise calls `next(err)` instead of hanging the response.

```typescript
import { expressErrorHandler } from '@beecode/msh-util'
import { type Request, type Response } from 'express'

class RootController {
	@expressErrorHandler
	async login(req: Request, res: Response): Promise<void> {
		const { username, password } = validationUtil().sanitize(req.body, postLoginBodySchema)
		const result = await authorizationUseCase.login({ username, password })
		res.json(result)
	}
}
```

## Breaking changes

No major-version migration guide ships with this package as of the known version. If the user has a different major, fetch `https://raw.githubusercontent.com/beecode-rs/msh-util/main/README.md` and `/MIGRATION.md` (see `version-check.md`). Note: older `@beecode/msh-node-util` code that used `cacheUtil.singleton` should migrate to `singletonPattern` / `SingletonAsync` here.
