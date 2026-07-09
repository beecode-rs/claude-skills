# Clean Architecture Command

Scoped **architecture-only** review: validate TypeScript against the layered architecture only — where code lives and how layers depend. Line-level style is out of scope here — use `/clean-style` for that, or `/cleanup` for both. Assume the `style/` rules but do not enforce them in this pass.

## Usage

When the user says: "review the architecture", "clean-arch", "check structure", "is this in the right layer", or explicitly wants only structure feedback.

## Scope

Load and apply ONLY the `architecture/` docs:

- [layer/](../architecture/layer/) — each layer's contract (controller, service, repository, use-case, component, DAL, entity, UI component, app-boot)
- [file-organization-pattern.md](../architecture/file-organization-pattern.md) — where files go, module structure
- [class-vs-object.md](../architecture/class-vs-object.md) — singleton vs class per layer
- [model-vs-entity.md](../architecture/model-vs-entity.md) — the Entity↔Model (DAL↔business) boundary
- [null-undefined-pattern.md](../architecture/null-undefined-pattern.md) — `undefined` in business, `null` only in DAL/entity
- [rest-api-url-conventions.md](../architecture/rest-api-url-conventions.md), [express-handler-pattern.md](../architecture/express-handler-pattern.md), [validation-pattern.md](../architecture/validation-pattern.md) — controller layer

Do **not** load `style/*` for this pass.

## Checklist

Run each check; report violations with `file:line`.

1. **File placement** — business logic in `src/business/`, data access in `src/dal/`, handlers in `src/controller/`, project-local utilities in `src/util/`, reusable extractable infrastructure in `src/lib/`; no arbitrary top-level folders outside the allowed set (`app-boot`, `controller`, `business`, `dal`, `ui-component`, `util`, `lib`)
2. **Class vs object** — repositories/DAL/entity = class; controllers/use-cases = singleton; no exported instances
3. **Layer dependencies** — a controller handler calls ONE business function; UI components contain no routing hooks or business logic
4. **Entity↔Model boundary** — the DAL converts; business code uses models, not entities
5. **null vs undefined** — `undefined` in business layers, `null` only in DAL/entity
6. **Templates** — new code matches a starter scaffold under [architecture/templates/](../architecture/templates/)

## Output

Report grouped by file. Each finding: `file:line`, the rule, and the fix.
