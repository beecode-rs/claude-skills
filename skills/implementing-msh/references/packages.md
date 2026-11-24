# Package dispatch (the switch)

Use this table to route a user request to the right MSH package(s). Match on the user's intent and the keywords they used. Many real requests touch more than one package, so read down the whole table before deciding.

## Contents

- [Intent to package](#intent-to-package)
- [Keyword index](#keyword-index)
- [Multi-package patterns](#multi-package-patterns)
- [If nothing matches](#if-nothing-matches)

## Intent to package

| The user wants to... | Primary package | Often also needs |
|----------------------|-----------------|------------------|
| Initialize an app, compose startup/shutdown units, run in order, reverse on destroy, graceful shutdown on SIGTERM/SIGINT | app-boot | logger (inject a logger via `setAppBootLogger`) |
| Validate and type environment variables, defaults, allowed values, read config from env / CLI args / docker secrets | env | logger (`setEnvLogger`), util |
| Throw HTTP-aware errors, build an error for a status code, Express error-handling middleware, inspect `httpCode`/`payload` | error | (standalone) |
| Logging: console, JSON, pino, log levels, child loggers, custom format+transport | logger | (standalone, but app-boot/env/node-session all accept a logger) |
| Request-scoped context per request: store transaction manager / auth user, CLS, async-local-storage, Express/Fastify middleware | node-session | util (`singletonPattern` for the session util), error |
| Singletons (sync/async), memoize, timeout/sleep, time/date helpers, deep clone, pick, joi validation wrapper, UUID, exhaustive-switch guard, class factory, regex uuid | util | (standalone, foundational) |
| Shared ESLint config, Prettier config, semantic-release config for an msh-style project | config | (standalone) |

## Keyword index

When the user says one of these, route to the package on the right. Keywords are taken from the actual public API names.

- **app-boot**: `AppFlow`, `AppStarter`, `LifeCycle`, `FlowList`, `setAppBootLogger`, graceful shutdown, SIGTERM, SIGINT, app init, app lifecycle, startup order
- **env**: `mshEnv`, `mshEnvResolver`, `MshEnvResolverError`, env var, environment variable, config from env, `.string`/`.number`/`.boolean`/`.base64`/`.json`, `.optional`, `.default`, `.allowed`, `.value`, location strategy, naming strategy, docker secrets, cli args env
- **error**: `errorFactory`, `errorHOF`, `ErrorBaseModel`, `HttpResponseCodeMapper`, `expressMiddleware`, throw 403/401/404/500, HTTP error, error with payload
- **logger**: `LogLevel`, `LoggerStrategy`, `PresetConsoleSimpleString`, `PresetConsoleJson`, `PresetPino`, `PresetVoid`, `FormattingStrategy`, `TransportingStrategy`, `LoggerStrategyBase`, `clone`, pino logger, structured logs
- **node-session**: `NodeSessionUtil`, `SessionStrategy`, `FastAlsStrategy`, `ClsHookedStrategy`, `AsyncLocalStorageStrategy`, `createAsyncSession`, `createSession`, request context, CLS, continuation-local storage, transaction per request, `fastifyHelperFactory`, `expressFastAlsHelperFactory`, `expressClsHookedHelperFactory`, `expressAsyncLocalStorageHelperFactory`
- **util**: `singletonPattern`, `SingletonAsync`, `memoizeFactory`, `timeout`, `TimeUtil`, `DurationUnit`, `ObjectUtil`, `JoiUtil`, `ErrorWithPayload`, `stringUtil`, `generateUUID`, `regexUtil`, `typeUtil`, `exhaustiveError`, `exhaustiveMessage`, `classFactoryPattern`, `SingleThresholdPromise`, `expressErrorHandler`
- **config**: `msh-config`, eslint config, prettier config, semantic-release config, `msh-update-lock-version`

## Multi-package patterns

These combinations come up often. When you see one, load every reference involved:

- **Bootstrap a service**: app-boot (lifecycle) + logger (visible logs) + env (config) + error (throw in handlers). app-boot defaults to a no-op logger, so users almost always pair it with `setAppBootLogger(new PresetConsoleSimpleString(...))`.
- **Request-scoped transaction/auth**: node-session (context) + util (`singletonPattern` to hold the session util instance) + error (throw if context missing). The classic shape is a `SessionUtil extends NodeSessionUtil` stored in a `singletonPattern`.
- **Env with visible resolution logs**: env + logger (`setEnvLogger`).
- **Validated config object**: env (`mshEnvResolver`) produces a frozen config; pair with util (`JoiUtil`) only if validating non-env input.

## If nothing matches

If the user's keywords do not appear above, they are probably not asking about an MSH package. Re-read their request; if it is genuinely MSH-adjacent but uncategorized, ask which package they mean rather than guessing.
