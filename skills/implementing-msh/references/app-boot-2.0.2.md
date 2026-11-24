# @beecode/msh-app-boot

Micro-service helper: application initializer. Compose an app from self-contained lifecycle units, declare the order they start (and the reverse order they stop), and let `AppStarter` wire up graceful shutdown on `SIGTERM`/`SIGINT`.

- **Known version**: `2.0.2` (major 2)
- **Install**: `npm i @beecode/msh-app-boot`
- **Depends on**: `@beecode/msh-config`, `@beecode/msh-logger` (defaults to a no-op logger)
- **Module type**: ESM

## Contents

- [Public exports](#public-exports)
- [Concepts](#concepts)
- [Logging](#logging)
- [Minimal example](#minimal-example)
- [Ordered + parallel units](#ordered--parallel-units)
- [Breaking changes](#breaking-changes)

## Public exports

From the main entry `@beecode/msh-app-boot`:

| Export | Kind | Notes |
|--------|------|-------|
| `LifeCycle` | abstract class | Subclass and implement `_createFn()` and `_destroyFn()` |
| `AppFlow` | abstract class | Subclass; pass a `FlowList` to `super(...)` |
| `FlowList` | type | `(LifeCycle \| LifeCycle[])[]` |
| `FlowDirectionMapper` | enum | `CREATE` / `DESTROY` |
| `AppStarter` | class | `start()` runs the flow and registers signal handlers |
| `AppStarterStatusMapper` | enum | `STARTED` / `STOPPED` |
| `setAppBootLogger` | function | Inject a `LoggerStrategy` from msh-logger |

## Concepts

- **`LifeCycle`** is the atomic init/destroy unit. Implement the abstract `protected async _createFn()` and `protected async _destroyFn()`. Each call is wrapped with `DEBUG` log lines (`<name> Create START` / `... END`, same for Destroy).
- **`AppFlow`** orchestrates a `FlowList`. Each top-level entry is either a single `LifeCycle` (runs alone) or an array of `LifeCycle`s (run together via `Promise.all`). On `create()` the list runs **in order**, awaiting each top-level entry before the next; items inside an array entry run **in parallel**. On `destroy()` the same logic runs against `_destroyFn` but the **top-level** list is **reversed** first, so things that started last stop first.
- **`AppStarter`** runs the flow. `start()` calls `AppFlow.create()` and registers `SIGTERM`/`SIGINT` handlers that trigger a graceful `stop()` (which calls `destroy()`) before exiting. If `create()` throws, the error is logged, the app is stopped, and the process exits with code `1`.

## Logging

App-boot defaults to a no-op logger (`PresetVoid`), so by default nothing prints. To see the `DEBUG` create/destroy lines, inject a logger before starting:

```typescript
import { setAppBootLogger } from '@beecode/msh-app-boot'
import { LogLevel } from '@beecode/msh-logger'
import { PresetConsoleSimpleString } from '@beecode/msh-logger/controller/preset/console-simple-string'

setAppBootLogger(new PresetConsoleSimpleString({ logLevel: LogLevel.DEBUG }))
```

Any `LoggerStrategy` from msh-logger works (`PresetConsoleJson`, `PresetPino`, etc.).

## Minimal example

```typescript
import { AppFlow, AppStarter, LifeCycle, setAppBootLogger } from '@beecode/msh-app-boot'
import { LogLevel } from '@beecode/msh-logger'
import { PresetConsoleSimpleString } from '@beecode/msh-logger/controller/preset/console-simple-string'

class MyService extends LifeCycle {
	constructor() {
		super({ name: 'My service' })
	}

	protected async _createFn(): Promise<void> {
		console.log('starting...') // eslint-disable-line no-console
	}

	protected async _destroyFn(): Promise<void> {
		console.log('stopping...') // eslint-disable-line no-console
	}
}

class App extends AppFlow {
	constructor() {
		super(new MyService())
	}
}

setAppBootLogger(new PresetConsoleSimpleString({ logLevel: LogLevel.DEBUG }))
new AppStarter(new App()).start().catch((err) => console.error(err)) // eslint-disable-line no-console
```

## Ordered + parallel units

A single `LifeCycle` runs alone; an array entry runs in parallel. On destroy the top-level order is reversed.

```typescript
// FirstInitiable finishes, then SecondInitiable and ThirdInitiable run in parallel.
class App extends AppFlow {
	constructor() {
		super(new FirstInitiable(), [new SecondInitiable(), new ThirdInitiable()])
	}
}
```

Each unit:

```typescript
import { LifeCycle } from '@beecode/msh-app-boot'

export class FirstInitiable extends LifeCycle {
	constructor() {
		super({ name: 'First initiable' })
	}

	protected async _createFn(): Promise<void> {
		/* start resources */
	}

	protected async _destroyFn(): Promise<void> {
		/* stop resources */
	}
}
```

## Breaking changes

No major-version migration guide ships with this package as of the known version. If the user has a different major, fetch `https://raw.githubusercontent.com/beecode-rs/msh-app-boot/main/README.md` and `/MIGRATION.md` (see `version-check.md`).
