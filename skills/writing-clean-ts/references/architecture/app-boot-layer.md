# App Boot Layer (ABL)

The App Boot Layer owns application startup and shutdown: it brings resources up in dependency order before the app serves anything, and takes them down gracefully when the app stops.

## Implementation Package

The layer is built on **[`@beecode/msh-app-boot`](https://github.com/beecode-rs/msh-app-boot)**: `LifeCycle` (one init/destroy unit), `AppFlow` (the ordered list of life cycles), and `AppStarter` (runs the flow and wires `SIGTERM`/`SIGINT` to a graceful stop). **Before writing app-boot code, use the `implementing-msh` skill** to get the exact API for the installed version; the snippets below show the shape, not a pinned API.

## What Belongs Here

Anything that must happen **once, while the app starts or stops**:

- Loading persisted state into memory (`settingsRepoSingleton().init()`)
- Opening connections, running migrations
- Registering controllers (`ipcRouter.register()`, `rxjsBusRouterSingleton().register()`)
- Starting pollers, schedulers, windows, trays
- Tearing all of that down in reverse order

A "use case" or "service" whose only job is to run at startup is misfiled: it is a life cycle. Conversely, a life cycle holds **no business logic** of its own. It calls into the business, controller, or lib layer. Reusable logic found inside a life cycle is extracted to a service (domain-aware) or lib module (infrastructure), and when that logic must keep state across calls it becomes a `-singleton` there.

## File Organization

```
src/app-boot/
├── desktop-app.ts                   # the AppFlow: the ordered list of life cycles
└── life-cycle/
    ├── settings-life-cycle.ts       # SettingsLifeCycle - first: loads settings into memory
    ├── ipc-router-life-cycle.ts     # IpcRouterLifeCycle - calls ipcRouter.register()
    ├── app-window-life-cycle.ts     # AppWindowLifeCycle
    ├── usage-poll-life-cycle.ts     # UsagePollLifeCycle
    └── sessions-poll-life-cycle.ts  # SessionsPollLifeCycle
```

- Every life cycle is a class in `app-boot/life-cycle/`, file `<name>-life-cycle.ts`, export `<Name>LifeCycle`
- The flow file is named for **what the app is** (`desktop-app.ts`, `api-server.ts`, `worker.ts`), never after the project (`usage-pulse-app-flow.ts`)
- The process entry point (`src/index.ts`, `src/main/index.ts`) only starts the flow

## Life Cycle Shape

```typescript
// src/app-boot/life-cycle/settings-life-cycle.ts
import { LifeCycle } from '@beecode/msh-app-boot'

import { settingsRepoSingleton } from '#src/business/repo/settings-repo-singleton'
import { schedulingServiceSingleton } from '#src/business/service/scheduling-service-singleton'
import { logger } from '#src/util/logger'

export class SettingsLifeCycle extends LifeCycle {
  constructor() {
    super({ name: 'Settings' })
  }

  protected async _createFn(): Promise<void> {
    await settingsRepoSingleton().init()
    await schedulingServiceSingleton().syncRegistrations().catch((err: unknown) => {
      logger().error('schedule sync failed on boot', err)
    })
  }

  protected async _destroyFn(): Promise<void> {
    return undefined
  }
}
```

```typescript
// src/app-boot/life-cycle/ipc-router-life-cycle.ts
export class IpcRouterLifeCycle extends LifeCycle {
  constructor() {
    super({ name: 'IpcRouter' })
  }

  protected async _createFn(): Promise<void> {
    ipcRouter.register()
  }

  protected async _destroyFn(): Promise<void> {
    ipcRouter.unregister()
  }
}
```

Rules:

- **`_createFn` / `_destroyFn` only.** A life cycle exposes nothing else. No public getters (`getWindow()`) for other modules to reach into: when other code needs something a life cycle created (a window handle, a connection), that thing is owned by a `-singleton` in the lib or business layer, the life cycle sets it up, and consumers read it from the singleton
- **Delegate, don't implement.** Registration code (which channel maps to which handler) lives in the controller layer; the life cycle only calls `register()`. Loading logic lives in the repo; the life cycle only calls `init()`
- **Collaborators come from imports**, not from constructor params
- **Settings (or whatever everything else reads) goes first.** Every later life cycle may call `settingsRepoSingleton().fetch()` synchronously

## Flow Order

```typescript
// src/app-boot/desktop-app.ts
import { AppFlow } from '@beecode/msh-app-boot'

export class DesktopApp extends AppFlow {
  constructor() {
    super(
      new SettingsLifeCycle(),
      new IpcRouterLifeCycle(),
      [new UsagePollLifeCycle(), new SessionsPollLifeCycle()],
      new AppWindowLifeCycle(),
    )
  }
}
```

- A single life cycle entry runs alone; an array entry runs its members in parallel
- The list runs top to bottom on start and in reverse on stop, so what started last stops first
- Order by dependency: **foundation** (state, connections, migrations, event bus) sequentially, then **interfaces** (routers, pollers, windows, HTTP, queues, cron) in parallel where they are independent

## Graceful Shutdown

Never kill the app mid-work. On stop:

1. **Deactivate listeners**: stop accepting HTTP requests, stop consuming queues, stop cron triggers, unregister routers
2. **Wait for in-flight work** to finish
3. **Release resources**: close connections, flush logs

`AppStarter` wires `SIGTERM`/`SIGINT` to this sequence. Shutdown errors are always logged, because a failure there is otherwise invisible until data is lost.

## Testing Considerations

Tests boot only the life cycles they need by building a smaller flow (for example settings + IPC router, without windows or pollers). Because life cycles have no public API beyond create/destroy, the behavior under test is observed through the singletons and routers they set up. For test patterns, use the `contract-testing-ts` skill.

## Key Takeaways

1. **Use `@beecode/msh-app-boot`**, and check the installed version with the `implementing-msh` skill
2. **One life cycle per concern**, in `app-boot/life-cycle/`, class `<Name>LifeCycle`
3. **Life cycles delegate**: they call `init()` / `register()` / `start()` on other layers and hold no business logic
4. **No public getters on life cycles**: shared state lives in a lib/business `-singleton`
5. **Startup work belongs here**, not in use cases
6. **Order by dependency**: foundation sequentially, interfaces in parallel; shutdown runs in reverse
