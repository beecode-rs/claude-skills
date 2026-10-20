# Constant, Config, and Runtime State

A value in code is one of three kinds, and each kind has exactly one home. Mixing them is how hidden coupling creeps in: a `const MAX_ITEMS = 5` buried in a service, a `process.env.FOO` read deep inside a lib, a config field flipped while the app runs. Each of those makes it impossible to answer "where does this value come from?" by looking in one place.

| Kind | Who can change it | Home | Shape |
|---|---|---|---|
| **Constant**: fixed by the code (limits, regexes, fixed timeouts, preset ids) | Nobody. Changing it is a code change | `util/constant.ts` | one exported `constant` object |
| **Config**: chosen at startup from `.env` or CLI args | The operator, before the app starts | `util/config.ts` | the frozen object returned by `mshEnvResolver` |
| **Runtime state**: changes while the app runs | The app itself | a util memory module (or a repo when it must survive a restart) | an in-memory variable seeded at startup |

The test for constant vs config: *would anyone ever want to change this without a code change?* Yes → config (env-settable). No → constant.

## constant.ts

```typescript
// src/util/constant.ts
export const constant = {
  regex: {
    digitSequenceRegex: /\d+/,
    semverRegex: /^(\d+)\.(\d+)\.(\d+)$/,
  },
  scheduleTrigger: {
    durationMs: {
      default: 5 * 60 * 60 * 1000,
      max: 24 * 60 * 60 * 1000,
      min: 60 * 1000,
    },
    maxWindowPreset: ScheduleTriggerPreset.MAX_WINDOW,
    run: {
      log: {
        limit: 200,
      },
      timeoutMs: 30 * 1000,
    },
  },
  sessionTranscript: {
    cacheEntryLimit: 50,
  },
}
```

Rules:

- **One export.** The file exports a single `constant` object and every constant is a key inside it. No `export const UPPER_CASE_NAME`, no per-constant exports, and no module-level constants anywhere else: a `const CACHE_ENTRY_LIMIT = 50` at the top of a service, a regex at the top of a parser, a hardcoded number inside a model file all move into `constant`.
- **camelCase keys, nested by shared prefix.** When several keys start with the same words, the words become a parent key: `scheduleTriggerRunTimeoutMs` + `scheduleTriggerRunLogLimit` → `scheduleTrigger.run.timeoutMs` + `scheduleTrigger.run.log.limit`. Reads then mirror the domain: `constant.scheduleTrigger.run.log.limit`.
- **Bounds and defaults sit under the value they describe.** `min`, `max`, and `default` hang off the value itself (`scheduleTrigger.durationMs.min`), never off the feature (`scheduleTrigger.minDurationMs`). The reader should find every fact about `durationMs` in one place.
- **Name by what the value is, not what uses it.** A key survives when a second caller appears. `constant.sessionTranscript.cacheEntryLimit` is fine because the value really is the transcript cache's limit; a regex that matches digits is `digitSequenceRegex`, not `versionCompareRegex`.
- **Regexes live here, every one of them**, and every regex key ends with `Regex` (never `Pattern`, `Re`, or `Matcher`). The name says what the regex matches: `semverRegex`, `digitSequenceRegex`, `ansiEscapeRegex`.
- **Time is always milliseconds**, and every time key ends with `Ms` (or is a `min`/`max`/`default` child of an `...Ms` key). No seconds, minutes, or hours in constants; an arithmetic expression that produces milliseconds (`5 * 60 * 1000`) is fine and is easier to read than `300000`.
- **Test the regexes.** Regex constants get contract tests (see the `contract-testing-ts` skill); any adapter harness goes in `__tests__/` next to `constant.ts`.

In a multi-process app (Electron `src/main` / `src/renderer` / `src/shared`), a constant used by more than one process lives in `src/shared/util/constant.ts`; a constant only one process uses lives in that process's own `util/constant.ts`.

## config.ts

```typescript
// src/util/config.ts
import { env, mshEnvResolver } from '@beecode/msh-env'

export const config = mshEnvResolver({
  logLevel: env('LOG_LEVEL').string.default('info').required,
  update: {
    feedUrl: env('UPDATE_FEED_URL').string.optional,
  },
})

export const processEnv = (): NodeJS.ProcessEnv => {
  return process.env
}
```

The builder syntax above is illustrative. Check the `implementing-msh` skill for the exact `@beecode/msh-env` API of the installed version before writing it.

Rules:

- **`config.ts` is the only file that reads `process.env`.** Everything else imports `config`. A `process.env.X` anywhere else is a violation: add the key to `config` and read it from there.
- **Every env key is declared in the resolver**, not in hand-written getters. `mshEnvResolver` validates all keys in one pass and returns a typed, deeply frozen object; no `.value` calls are needed on the result.
- **Config is immutable.** It describes how the app was started. Nothing writes to it after startup, not even "just this one flag". If a value must change at runtime, it is runtime state (below).
- **Raw environment passthrough is separate.** When code needs the raw environment as a whole (for example to forward it to a child process), it calls `processEnv()` from `config.ts`. The raw env never becomes part of the `config` object.
- Group config keys the same way as constants: nested by the part of the app that uses them, named by what the value is.

## Runtime State

When a value must change while the app runs (a "re-exec already done" flag, the currently selected provider), keep it as an in-memory variable in the util layer: seed it from `config` at startup and expose named functions to read and change it.

```typescript
// src/util/sandbox-state-util.ts
const sandboxState = {
  isNoSandboxReexecDone: config.sandbox.isNoSandboxReexecDone,
}

export const sandboxStateUtil = {
  isNoSandboxReexecDone(): boolean {
    return sandboxState.isNoSandboxReexecDone
  },

  markNoSandboxReexecDone(): void {
    sandboxState.isNoSandboxReexecDone = true
  },
}
```

This is the one sanctioned piece of mutable module state in the util layer, and it lives behind named functions so every write can be found with one search. When the state must survive a restart, it is not a util: it is a repo backed by a memory + file DAL.

## Platform Detection

`process.platform` is read in exactly one place, `osUtil.resolvePlatform()`, which returns the `OS` enum (`OS.MACOS`, `OS.WINDOWS`, `OS.LINUX`, keys equal to values). Everything else switches on `OS` with an exhaustive `default`: `default: { throw typeUtil.exhaustiveError('...', value) }`. Raw platform strings (`'darwin'`, `'win32'`) never appear outside `os-util.ts`.

## Checklist

- [ ] No `export const UPPER_CASE` anywhere; every constant is a key of `constant`
- [ ] No module-level constants (numbers, strings, regexes) in services, libs, models, components, or controllers
- [ ] Every regex is in `constant.ts`, its key ends with `Regex`, and the name says what it matches
- [ ] Every time value is in milliseconds with an `Ms` key
- [ ] `min`/`max`/`default` sit under the value they describe
- [ ] `process.env` appears only in `config.ts`; `process.platform` only in `os-util.ts`
- [ ] Nothing writes to `config` after startup; runtime changes go through a util memory module or a repo
