# @beecode/msh-logger

Micro-service helper: logging abstraction using the Strategy Pattern. Decouples formatting from transport with pluggable strategies and ready-made presets.

- **Known version**: `2.0.2` (major 2)
- **Install**: `npm i @beecode/msh-logger`
- **Depends on**: `@beecode/msh-config`, `@beecode/msh-util`, `pino`
- **Module type**: ESM

## Contents

- [Public exports](#public-exports)
- [Log levels](#log-levels)
- [Presets (easiest way in)](#presets-easiest-way-in)
  - [Quick start](#quick-start)
  - [PresetConsoleSimpleString params](#presetconsolesimplestring-params)
- [Formatting strategies](#formatting-strategies)
- [Transporting strategies](#transporting-strategies)
- [Custom LoggerStrategyBase](#custom-loggerstrategybase)
- [Child loggers (clone)](#child-loggers-clone)
- [Breaking changes (v1 to v2)](#breaking-changes-v1-to-v2)

## Public exports

From the main entry `@beecode/msh-logger`:

| Export | Kind | Notes |
|--------|------|-------|
| `LogLevel` | enum | `FATAL`, `ERROR`, `WARN`, `INFO`, `DEBUG`, `TRACE` |
| `LoggerStrategy` | interface | Contract for all logger implementations |
| `LoggerStrategyParams` | type | Params for configuring loggers and `clone()` |
| `ObjectType` | type | `Record<string, unknown>` - metadata bag |

Presets, strategies, and the base class are imported via subpaths (see below).

## Log levels

Higher numeric value = more severe. A logger emits anything at or above its configured level; lower levels are dropped. Default level is `LogLevel.ERROR`.

| Level | Value | Use |
|-------|-------|-----|
| `LogLevel.FATAL` | 60 | Unrecoverable; process must terminate |
| `LogLevel.ERROR` | 50 | Unexpected failure; feature failed, process continues |
| `LogLevel.WARN` | 40 | Degraded but recoverable |
| `LogLevel.INFO` | 30 | Business-significant events |
| `LogLevel.DEBUG` | 20 | Diagnostic detail |
| `LogLevel.TRACE` | 10 | Fine-grained flow |

## Presets (easiest way in)

Each preset pre-wires a formatting + transporting combination.

| Preset | Formatting | Transporting |
|--------|-----------|-------------|
| `PresetConsoleSimpleString` | `FormattingStrategySimpleString` | `TransportingStrategyConsole` |
| `PresetConsoleJson` | `FormattingStrategyJson` | `TransportingStrategyConsole` |
| `PresetPino` | `FormattingStrategyJson` | `TransportingStrategyPino` |
| `PresetVoid` | - | - (no-op) |

Subpath imports:

| Import path | Export |
|-------------|--------|
| `@beecode/msh-logger/controller/preset/console-simple-string` | `PresetConsoleSimpleString` |
| `@beecode/msh-logger/controller/preset/console-json` | `PresetConsoleJson` |
| `@beecode/msh-logger/controller/preset/pino` | `PresetPino` |
| `@beecode/msh-logger/controller/preset/void` | `PresetVoid` |

### Quick start

```typescript
import { LogLevel } from '@beecode/msh-logger'
import { PresetConsoleSimpleString } from '@beecode/msh-logger/controller/preset/console-simple-string'

const logger = new PresetConsoleSimpleString({ logLevel: LogLevel.INFO })

logger.debug('This is hidden') // filtered out (below INFO)
logger.info('Server started', { port: 3000 })
logger.warn('Deprecation warning')
logger.error('Something went wrong', new Error('boom'))
```

Output:

```
2026-05-30T12:00:00.000Z - INFO: Server started { port: 3000 }
2026-05-30T12:00:00.000Z - WARN: Deprecation warning
2026-05-30T12:00:00.000Z - ERROR: Something went wrong Error: boom
```

### PresetConsoleSimpleString params

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `logLevel` | `LogLevel` | `LogLevel.ERROR` | Minimum level to emit |
| `category` | `string` | `undefined` | Category label added to every entry |
| `meta` | `ObjectType` | `undefined` | Metadata attached to every entry |

```typescript
const logger = new PresetConsoleSimpleString({
	logLevel: LogLevel.DEBUG,
	category: 'my-app',
	meta: { service: 'api', version: '1.0.0' },
})
// Output: 2026-05-30T12:00:00.000Z - INFO: [my-app] Hello world
```

`PresetConsoleJson` and `PresetPino` take the same params. `PresetPino` adds `pinoLogger?: pino.Logger` (defaults to `pino()`).

## Formatting strategies

| Strategy | Import path | Output |
|----------|-------------|--------|
| `FormattingStrategySimpleString` | `@beecode/msh-logger/business/service/formatting-strategy/simple-string` | `TIMESTAMP - LEVEL: [category] message` |
| `FormattingStrategyJson` | `@beecode/msh-logger/business/service/formatting-strategy/json` | JSON object with `level`, `timestamp`, `category`, `message` |

## Transporting strategies

| Strategy | Import path | Destination |
|----------|-------------|-------------|
| `TransportingStrategyConsole` | `@beecode/msh-logger/business/service/transporting-strategy/console` | `console.*` |
| `TransportingStrategyPino` | `@beecode/msh-logger/business/service/transporting-strategy/pino` | A pino logger |
| `TransportingStrategyStream` | `@beecode/msh-logger/business/service/transporting-strategy/stream` | Any `NodeJS.WritableStream` |
| `TransportingStrategyVoid` | `@beecode/msh-logger/business/service/transporting-strategy/void` | nowhere |

## Custom LoggerStrategyBase

Combine any formatting strategy with any transporting strategy:

```typescript
import { LogLevel } from '@beecode/msh-logger'
import { LoggerStrategyBase } from '@beecode/msh-logger/business/service/logger-strategy/base'
import { FormattingStrategyJson } from '@beecode/msh-logger/business/service/formatting-strategy/json'
import { TransportingStrategyStream } from '@beecode/msh-logger/business/service/transporting-strategy/stream'
import { createWriteStream } from 'node:fs'

const logger = new LoggerStrategyBase({
	formattingStrategy: new FormattingStrategyJson(),
	transportingStrategy: new TransportingStrategyStream(createWriteStream('./app.log')),
	logLevel: LogLevel.DEBUG,
	category: 'my-service',
	meta: { env: 'production' },
})
```

`LoggerStrategyBaseParams`: `formattingStrategy` (required), `transportingStrategy` (required), `logLevel` (default `ERROR`), `category`, `meta`.

## Child loggers (clone)

`clone()` inherits settings with optional overrides. Meta is shallow-merged:

```typescript
const parent = new PresetConsoleSimpleString({ logLevel: LogLevel.INFO, category: 'app', meta: { service: 'api' } })
const child = parent.clone({ category: 'app:router', meta: { route: '/users' } })
child.info('User listed') // meta: { service: 'api', route: '/users' }
```

## Breaking changes (v1 to v2)

v2 decoupled formatting from transport, renamed concepts, and expanded log levels. Quick reference:

| v1 | v2 |
|----|----|
| `new LoggerStrategyConsole()` | `new PresetConsoleSimpleString()` or `new PresetConsoleJson()` |
| `new LoggerStrategyVoid()` | `new PresetVoid()` |
| `ConsoleLogStrategySimple` | `FormattingStrategySimpleString` + `TransportingStrategyConsole` |
| `ConsoleLogStrategyNewRelicJson` | `FormattingStrategyJson` + `TransportingStrategyConsole` |
| `ConsoleLogStrategyPino` | `FormattingStrategyJson` + `TransportingStrategyPino` |
| `messagePrefix` option | `category` option |
| `consoleLogStrategy` constructor option | removed; compose a `LoggerStrategyBase` directly |
| `LogLevel` 0 to 3 ascending | `LogLevel` 10 to 60 descending (higher = more severe); added `FATAL`/`TRACE` |
| JSON key `logtype` | JSON key `level` |
| `logger.fatal` / `logger.trace` | new methods in v2 (add them if you implemented `LoggerStrategy` directly) |

Import path changes:

| v1 | v2 |
|----|----|
| `@beecode/msh-logger/logger-strategy/void` | `@beecode/msh-logger/preset/void` |
| `@beecode/msh-logger/logger-strategy/console` | `@beecode/msh-logger/preset/console-simple-string` |
| `@beecode/msh-logger/logger-strategy/console/log-strategy/simple` | `@beecode/msh-logger/preset/console-simple-string` |
| `@beecode/msh-logger/logger-strategy/console/log-strategy/new-relic-json` | `@beecode/msh-logger/preset/console-json` |
| `@beecode/msh-logger/logger-strategy/console/log-strategy/pino` | `@beecode/msh-logger/preset/pino` |

Full guide: `https://raw.githubusercontent.com/beecode-rs/msh-logger/main/MIGRATION.md`.
