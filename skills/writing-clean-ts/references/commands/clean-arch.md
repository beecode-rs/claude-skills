# Clean Architecture Command

Scoped **architecture-only** review: validate TypeScript against the layered architecture only — where code lives and how layers depend. Line-level style is out of scope here — use `/clean-style` for that, or `/cleanup` for both. Assume the style rules but do not enforce them in this pass.

**Expo projects:** if the package is an Expo app (`expo` / `expo-router` dependency, `"main": "expo-router/entry"`, or an `expo` key in `app.json` / `app.config.ts`), do not report the framework-mandated Expo patterns: files in `src/app/` without layer suffixes, with `[param]`/`(group)`/`+name`/`_layout` names, or exporting a default component; `index.tsx` in `src/app/`; `src/app/` as a top-level folder (never suggest renaming it to `app-boot/`); `@/` imports, or a missing `"type": "module"` / `imports` field / `#src` paths; platform-variant files (`x.web.ts` next to `x.ts`). Still report relative imports, business logic or routing hooks inside screens, non-route code placed in `src/app/`, and route files that do more than read router params and pass props.

## Usage

When the user says: "review the architecture", "clean-arch", "check structure", "is this in the right layer", or explicitly wants only structure feedback.

## Scope

Apply ONLY the architecture rules: each layer's contract (controller, service, repository, use-case, component, DAL, entity, UI component, app-boot), where files go and module structure, singleton vs class per layer, the Entity↔Model (DAL↔business) boundary and models-only model folders, constants/config/runtime state/platform detection, `undefined` in business vs `null` only in DAL/entity, and the controller-layer rules (REST URL conventions, Express handlers, validation). Line-level style rules are out of scope for this pass.

## Checklist

Run each check; report violations with `file:line`.

1. **File placement** - domain-aware logic in `src/business/`, data access in `src/dal/`, handlers in `src/controller/`, generic helpers in `src/util/`, non-domain third-party wrappers in `src/lib/`; no arbitrary top-level folders outside the allowed set (`app-boot`, `controller`, `business`, `dal`, `ui-component`, `util`, `lib`, `__internal__`, `asset`, `__tests__`)
2. **Class vs object** - repositories/DAL/entity/life cycles = class; controllers/use-cases = plain object; services/utils/libs = object, class (state/helpers), or factory; a plain object with `_` members is converted to a class; no exported instances
3. **Layer dependencies**: a controller handler calls ONE business function; a use-case usually orchestrates two or more steps (a thin one-call use-case is acceptable when it gives the controller a stable domain-named entry point or hides the implementing layer; any other single-call use-case is a wrapper to remove); a use-case never calls another use-case and is never a class; services compose only same-package/same-domain services (cross-domain orchestration belongs in a use-case); run the exclusivity check on service-to-service dependencies; UI components contain no routing hooks or business logic
4. **Entity↔Model boundary** — the DAL converts; business code uses models, not entities
5. **null vs undefined** — `undefined` in business layers, `null` only in DAL/entity
6. **Templates** — new code matches the starter template for its layer
7. **Placement of values and types** — constants in `util/constant.ts`, env reads only in `util/config.ts` (config immutable), enums one per file in `business/enum/`, the model folder holds only models (no logic, no API clients, no enums, no `Entity` names)
8. **Singletons and wiring** — `singletonPattern` only for classes holding memory, class `_`-prefixed in the same `-singleton.ts` file; no constructor dependency injection (import collaborators); use cases stateless plain objects; startup work in `app-boot/life-cycle/`, life cycles expose only create/destroy
9. **Repo/DAL split** — repos speak business words and know nothing about files or paths; each repo has its own DAL; shared storage mechanics in `common-*-dal.ts`
10. **Util vs lib vs service** — `-util` files are generic; domain logic is a service; external-system knowledge (another tool's formats) and the app event bus are lib
11. **Controller wiring** — one router per interface with a single `register()`, callbacks in per-domain files, zod validation on every payload; event subscriptions in `controller/rxjs-bus/` instead of listener arrays in services
12. **Test-only code** — harnesses, fakes, and fixtures in `__tests__/`; `*.contract.yaml` / `*.test.ts` next to the source

## Output

Report grouped by file. Each finding: `file:line`, the rule, and the fix.
