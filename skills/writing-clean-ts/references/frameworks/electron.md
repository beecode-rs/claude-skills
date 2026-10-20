# Electron

Everything Electron-specific: the multi-process layout and the IPC controller interface.

## Layout

**Multi-process apps** (Electron) repeat the layer tree per process: `src/main/`, `src/renderer/src/`, and `src/shared/` for models, enums, constants, and utils both sides use.

**Multi-process apps** (Electron) repeat this tree per process: `src/main/` (Node main process), `src/renderer/src/` (React renderer), and `src/shared/` (models, enums, constants, and pure utils both sides import). Something used by both processes lives in `src/shared/` under the same layer name (`src/shared/business/enum/`, `src/shared/util/constant.ts`); something used by one process lives in that process's tree.

| Layer | Pattern | Location |
|-------|---------|----------|
| **Controller** (IPC) | `router.ts` + one handler file per domain | `src/controller/ipc/` (in `src/main/`) |

| Layer | File | Export | Example |
|-------|------|--------|---------|
| Controller interface (IPC) | `controller/ipc/router.ts` + `<domain>.ts` | `camelCase` object | `ipcRouter.register()` / `ipcUpdate.check` |

- Electron tray, global shortcuts, and window handles are lib code (`src/lib/`), never services
- A class holding a window handle is a legitimate `-singleton` (it holds memory a fresh instance would not have)

## IPC Router

An Electron main process exposes its IPC interface through one router. The router has a **single `register()`** containing every `ipcMain.handle(...)` / `ipcMain.on(...)` line, grouped by domain. The handler callbacks themselves live in one file per domain; the router only wires channel → callback:

```typescript
// src/main/controller/ipc/router.ts
import { ipcMain } from 'electron'

import { IpcChannelMapper } from '#src/shared/business/enum/ipc-channel-mapper-enum'
import { ipcSettings } from '#src/main/controller/ipc/settings'
import { ipcUpdate } from '#src/main/controller/ipc/update'
import { ipcUsage } from '#src/main/controller/ipc/usage'

export const ipcRouter = {
  register(): void {
    // Usage
    ipcMain.handle(IpcChannelMapper.USAGE_REFRESH_TRACKER, ipcUsage.refreshTracker)
    ipcMain.handle(IpcChannelMapper.USAGE_FETCH_ALL, ipcUsage.fetchAll)

    // Settings
    ipcMain.handle(IpcChannelMapper.SETTINGS_FETCH, ipcSettings.fetch)
    ipcMain.handle(IpcChannelMapper.SETTINGS_SAVE, ipcSettings.save)

    // Update
    ipcMain.handle(IpcChannelMapper.UPDATE_CHECK, ipcUpdate.check)
    ipcMain.on(IpcChannelMapper.UPDATE_INSTALL, ipcUpdate.install)
  },
}
```

```typescript
// src/main/controller/ipc/update.ts
export const ipcUpdate = {
  async check(): Promise<UpdateStatusModel> {
    return await new UpdateService().check()
  },

  install(): void {
    new UpdateService().install()
  },
}
```

- **One `register()`**, not a `registerUsage()` / `registerSettings()` / ... per domain. The domain groups are separated by a one-word title comment (`// Usage`), the one sanctioned use of comments outside TODOs: in a flat list of registrations a title line is the clearest grouping and there is no function to name
- **The `ipcMain.handle(channel, ...)` lines stay in the router**; only the callback moves out to the domain file. Reading the router shows the whole IPC surface in one screen
- Each callback follows the controller rules: validate the payload (zod), make one business call, return the result
- The app-boot life cycle calls `ipcRouter.register()` and nothing else
- Services come from `import`s; the router never receives them as arguments

## Validating IPC Payloads

Every controller interface validates its input the same way, not only Express. An Electron IPC handler receives `unknown` from the renderer; it parses that payload with a zod schema through the shared validation util before calling the business layer. Hand-rolled checks on a raw record (`typeof raw.id === 'string' && ...`) are replaced by a schema:

```typescript
// src/main/controller/ipc/usage.ts
const refreshTrackerPayloadSchema = z.object({
  trackerId: z.string(),
})

export const ipcUsage = {
  async refreshTracker(_event: IpcMainInvokeEvent, rawPayload: unknown): Promise<UsageModel> {
    const { trackerId } = validationUtil.parse(rawPayload, refreshTrackerPayloadSchema)

    return await usagePollServiceSingleton().refreshTracker({ trackerId })
  },
}
```

Use the project's existing validation wrapper (`validationUtil.parse` from the common/node-common lib, or the equivalent in the project's `util/`) instead of calling `schema.parse` directly, so every interface produces the same error shape. If the project has no wrapper yet, add one in `util/validation-util.ts` before writing the first handler.
