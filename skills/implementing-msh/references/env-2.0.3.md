# @beecode/msh-env

Micro-service helper for Node.js environment variable validation and typing. Type-safe env access with validation, defaults, allowed values, and pluggable location/naming strategies.

- **Known version**: `2.0.3` (major 2)
- **Install**: `npm i @beecode/msh-env`
- **Depends on**: `@beecode/msh-config`, `@beecode/msh-logger`, `@beecode/msh-util`, `fast-deep-equal`, `js-base64`, `minimist`, `minimist-options`
- **Module type**: ESM

## Contents

- [Public exports](#public-exports)
- [How resolution works](#how-resolution-works)
- [Basic example](#basic-example)
- [Type converters](#type-converters)
- [Handling the aggregated error](#handling-the-aggregated-error)
- [Allowed values](#allowed-values)
- [Standalone reads](#standalone-reads)
- [mshEnv options](#mshenv-options)
  - [Location strategies (subpath imports)](#location-strategies-subpath-imports)
  - [Naming strategies (subpath imports)](#naming-strategies-subpath-imports)
- [Logger](#logger)
- [Immutability](#immutability)
- [Breaking changes](#breaking-changes)

## Public exports

From the main entry `@beecode/msh-env`:

| Export | Kind | Notes |
|--------|------|-------|
| `mshEnv` | function | `(params?) => MshEnv` - creates the `env(name)` builder factory |
| `mshEnvResolver` | function | `(configObj) => DeepReadonly<...>` - resolves a whole tree, returns a frozen object |
| `MshEnvResolver` | class | The resolver class behind `mshEnvResolver` |
| `MshEnvResolverError` | class | Thrown when one or more leaves fail; message lists every failure |
| `Resolve`, `DeepReadonly` | types | Helper types |

## How resolution works

Building a value is **lazy**. Chaining a converter (`.string`, `.number`, etc.) only *describes* how to read the variable; nothing is resolved yet. Resolution happens in one of two ways:

- **`mshEnvResolver({ ... })`** - the headline form. Pass a config object whose leaves are builders (and/or nested objects / arrays of builders). It walks the whole tree, resolves every leaf in one pass, and returns a fully-typed, deeply-frozen, `readonly` object. If any leaf fails, it collects **all** errors and throws a single `MshEnvResolverError` listing every failing var with its dotted path.
- **`.value`** - the single terminator for a standalone one-off read. Returns a plain, non-frozen value.

Within a builder:

- **Required is the default.** `env('API_KEY').string` is required.
- **`.optional`** is a *getter* (no parens) marking the var optional; the resolved type becomes `T | undefined`.
- **`.default(v)`** is a *method* that sets a fallback and **returns the builder** (it does not return the value), so you keep chaining.

`T` is the type produced by the converter: `string`, `number`, `boolean`, the decoded `string` from `.base64`, or the generic type passed to `.json<T>()`.

## Basic example

```typescript
import { mshEnvResolver, mshEnv } from '@beecode/msh-env'

const env = mshEnv()

export const config = mshEnvResolver({
	apiKey: env('API_KEY').string, // required (default)
	port: env('PORT').number,

	debugMode: env('DEBUG_MODE').boolean.optional, // boolean | undefined

	logLevel: env('LOG_LEVEL').string.default('info'),
	maxRetries: env('MAX_RETRIES').number.default(3),

	dbPassword: env('DB_PASSWORD').base64.default(''),

	featureFlags: env('FEATURE_FLAGS').json<{ darkMode: boolean }>().default({ darkMode: false }),
})
```

## Type converters

| Converter | Input | Output |
|-----------|-------|--------|
| `.string` | Any string | `string` |
| `.number` | Numeric string | `number` |
| `.boolean` | `'true'`, `'false'`, `'1'`, `'0'` | `boolean` |
| `.base64` | Base64-encoded string | `string` (decoded) |
| `.json<T>()` | Valid JSON string | `T` |

## Handling the aggregated error

```typescript
import { mshEnvResolver, MshEnvResolverError, mshEnv } from '@beecode/msh-env'

const env = mshEnv()

try {
	const config = mshEnvResolver({
		apiKey: env('API_KEY').string,
		port: env('PORT').number,
		db: {
			host: env('DB_HOST').string,
		},
	})
} catch (e) {
	if (e instanceof MshEnvResolverError) {
		console.error(e.message) // lists every failure with its dotted path
	}
}
```

Error message shape:

```
msh-env: 3 environment variable(s) failed to resolve:
  - apiKey -> Env[API_KEY] must have value defined
  - port -> Env[PORT] must have value defined
  - db.host -> Env[DB_HOST] "not-a-number" is not a number
```

## Allowed values

Chain `.allowed(...)` before resolution; it validates both the env value and any `.default(...)` fallback:

```typescript
const config = mshEnvResolver({
	logLevel: env('LOG_LEVEL').string.allowed('debug', 'info', 'warn', 'error'),
	environment: env('NODE_ENV').string.allowed('development', 'staging', 'production').default('development'),
})

// standalone one-off
const logLevel = env('LOG_LEVEL').string.allowed('debug', 'info', 'warn', 'error').value
```

## Standalone reads

Terminate a single builder with `.value` (optional/default still apply). Returns a plain, non-frozen value:

```typescript
const dbUrl = env('DATABASE_URL').string.value // required
const analyticsId = env('ANALYTICS_ID').string.optional.value // optional
const nodeEnv = env('NODE_ENV').string.default('development').value // default
```

## mshEnv options

```typescript
mshEnv(params?: {
	locationStrategies?: LocationStrategy[]
	namingStrategies?: NamingStrategy[]
}): MshEnv
```

| Option | Default | Description |
|--------|---------|-------------|
| `locationStrategies` | `[new LocationStrategyEnvironment()]` | Where to look for values; first non-`undefined` match wins |
| `namingStrategies` | `[new NamingStrategySimpleName()]` | How env names are transformed before lookup |

### Location strategies (subpath imports)

| Strategy | Import path |
|----------|-------------|
| `LocationStrategyEnvironment` (default) | `@beecode/msh-env/location-strategy/environment` |
| `LocationStrategyCliArgsMinimist` | `@beecode/msh-env/location-strategy/cli-args-minimist` |
| `LocationStrategyDockerSecrets` | `@beecode/msh-env/location-strategy/docker-secrets` |
| `LocationStrategyImportMetaEnv` | `@beecode/msh-env/location-strategy/import-meta-env` |
| `LocationStrategyCustom` | `@beecode/msh-env/location-strategy/custom` |

### Naming strategies (subpath imports)

| Strategy | Import path |
|----------|-------------|
| `NamingStrategySimpleName` (default) | `@beecode/msh-env/naming-strategy/simple-name` |
| `NamingStrategyPrefixName` | `@beecode/msh-env/naming-strategy/prefix-name` |
| `NamingStrategySuffixName` | `@beecode/msh-env/naming-strategy/suffix-name` |

## Logger

msh-env emits `debug`-level logs while resolving. Silent by default. Call `setEnvLogger()` once at startup, **before** reading any values:

```typescript
import { mshEnv } from '@beecode/msh-env'
import { setEnvLogger } from '@beecode/msh-env/util/logger'
import { LogLevel } from '@beecode/msh-logger'
import { PresetConsoleSimpleString } from '@beecode/msh-logger/controller/preset/console-simple-string'

setEnvLogger(new PresetConsoleSimpleString({ logLevel: LogLevel.DEBUG }))

const env = mshEnv()
```

## Immutability

`mshEnvResolver(...)` returns a deeply-frozen, `readonly` object; do not wrap it in `Object.freeze` again (redundant). `.value` returns a plain, non-frozen value.

## Breaking changes

No major-version migration guide ships with this package as of the known version. If the user has a different major, fetch `https://raw.githubusercontent.com/beecode-rs/msh-env/main/README.md` and `/MIGRATION.md` (see `version-check.md`).
