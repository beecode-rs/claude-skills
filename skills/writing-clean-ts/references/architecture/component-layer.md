# Component Layer (CompL)

## Purpose

A component is an **isolated folder that encapsulates one unit of business logic**. The folder exposes a public API, and everything else inside it is private: `_`-prefixed files and `protected _` methods that are called only from within the folder.

This is the one idea behind every component. The strategy pattern is the most common instance, not the definition:

- **Public**: a few files at the folder boundary that consumers import directly (usually `service.ts`, sometimes plus `index.ts` and named entry files)
- **Private**: everything else, marked with a leading `_`, never imported from outside the folder

A service, by contrast, is logic you call directly by name: a flat file with no private folder internals.

## Component vs Service Decision

Ask these questions in order:

1. **Does anything get selected at runtime based on a type/kind/enum?** A selector that dispatches on a discriminator (`strategyByStatementKindIfParsable(...)`, `entityToStrategy(...)`, `getStrategyFrom(...)`) is the signature of a component: one selector plus several interchangeable implementations belongs in one folder. → **Component** (Shape A)
2. **Are there several pluggable pieces sharing a generate/verify/parse-style shape, each imported individually by consumers?** → **Component** (Shape B)
3. **Is one public service supported by private helper services that nothing else calls?** → **Component** (Shape C, the target of the service-layer exclusivity check)
4. **Is there one contract with multiple backends (typeorm + memory, REST + GraphQL)?** → **Component** (Shape D)
5. **None of the above: the logic is a flat, directly-called unit** → **Service**

Do NOT reach for a component because of "states" or "complexity" alone. Complexity that has no dispatch, no pluggables, no private helpers, and no multiple backends is just a class service with `protected _` methods.

## The Four Component Shapes

### Shape A: strategy + selector (the canonical component)

Folder = `index.ts` (interface only) + `service.ts` (selector) + strategy files.

```
src/business/component/entity-parser-strategy/
├── index.ts        # export interface EntityParserStrategy { parse(): EntityModel }
├── service.ts      # export const entityParserStrategyService = { strategyByStatementKindIfParsable }
├── _class.ts       # export class EntityParserStrategyClass implements EntityParserStrategy
├── _enum.ts
├── _interface.ts
├── _object.ts
└── _type.ts
```

**Why the files are named just `index.ts` and `service.ts`: the export name is the folder name + file name concatenated.** Layer path segments (`src/`, `business/`, `component/`) never enter the name, and the `_` privacy prefix is skipped. `index.ts` contributes nothing, so its export is named exactly after the folder: the interface `EntityParserStrategy`. `service.ts` contributes `Service`, so its export is `entityParserStrategyService` (or class `EntityParserStrategyService`); the file does not need to be called `entity-parser-strategy-service.ts` because the export name already carries the folder. Every other file concatenates normally: `_class.ts` → `EntityParserStrategyClass`, `_enum.ts` → `EntityParserStrategyEnum`. The same rule holds in Shape C: `authentication/service.ts` exports `authenticationService` (folder + `Service`).

**`index.ts` contains ONLY the strategy interface** (3-6 lines). It is not a barrel, and it is not a wrapper object. It exists if and only if the component defines a strategy interface. There is no `xxxComponent` export anywhere; consumers import `service.ts` (or a strategy file) directly.

**`service.ts` exports a singleton object** whose method is a switch or map from a discriminator to `new Strategy(...)`:

```typescript
// src/business/component/entity-format-strategy/service.ts
import { typeUtil } from '@beecode/msh-util/type-util'

import { EntityFormatStrategyClass } from '#src/business/component/entity-format-strategy/_class'
import { EntityFormatStrategyEnum } from '#src/business/component/entity-format-strategy/_enum'
import { EntityFormatStrategyInterface } from '#src/business/component/entity-format-strategy/_interface'
import { EntityFormatStrategyObject } from '#src/business/component/entity-format-strategy/_object'
import { EntityFormatStrategyType } from '#src/business/component/entity-format-strategy/_type'
import type { EntityFormatStrategy } from '#src/business/component/entity-format-strategy/index'
import { EntityType } from '#src/business/enum/entity-type-enum'
import type { EntityModel } from '#src/business/model/core/entity-model'

export const entityFormatStrategyService = {
  entityToStrategy(params: { entityType: EntityType; entity: EntityModel }): EntityFormatStrategy {
    const { entityType, entity } = params

    switch (entityType) {
      case EntityType.CLASS: {
        return new EntityFormatStrategyClass({ entity })
      }
      case EntityType.ENUM: {
        return new EntityFormatStrategyEnum({ entity })
      }
      case EntityType.INTERFACE: {
        return new EntityFormatStrategyInterface({ entity })
      }
      case EntityType.OBJECT: {
        return new EntityFormatStrategyObject({ entity })
      }
      case EntityType.TYPE: {
        return new EntityFormatStrategyType({ entity })
      }
      default: {
        throw typeUtil.exhaustiveError('unknown entity type', entityType)
      }
    }
  },
}
```

Strategy files are `_`-prefixed **when the in-folder selector chooses among them**: consumers never import a strategy directly, they call the selector.

The selector is normally a stateless singleton object. The one exception: when the selector carries per-request constructor state, it becomes a class that takes its context via constructor object params and implements the same role.

### Shape B: grouped pluggables (no interface, no selector)

A folder of standalone pieces that share a shape but are individually imported by consumers. Examples: a `token/` folder of seven token classes sharing a generate/verify contract, a `data-loader/` folder of three DataLoader factory functions, a folder of strategy classes whose selector lives elsewhere (for example in a controller).

```
src/business/component/token/
├── access.ts       # export class TokenAccess - imported directly by consumers
├── refresh.ts      # export class TokenRefresh
└── verify-email.ts # export class TokenVerifyEmail
```

Files here are NOT `_`-prefixed: they are the public API, each imported by name. A shared interface, when one exists, goes in `index.ts` as in Shape A.

### Shape C: orchestrator + private helpers

One public `service.ts` singleton plus `_`-prefixed private helper files that only it calls:

```
src/business/component/authentication/
├── service.ts                  # export const authenticationService = { check, internalCheck, partialCheck }
├── _first-factor.ts            # private singleton
├── _generate-access-tokens.ts  # private singleton
├── _user-exists.ts             # private singleton
└── _user-verified.ts           # private singleton
```

```
src/business/component/ts-config/
├── service.ts          # public
└── _path-service.ts    # private
```

No `index.ts`: there is no strategy interface to export. This is also where an exclusive service-to-service dependency belongs (the service-layer exclusivity check): when a controller-facing service depends on a same-domain service that nothing else calls, the pair becomes `service.ts` (the public one) + `_b-service.ts` (the private one).

### Shape D: multi-backend abstraction (re-export entry files)

One contract, several backends, more than one public face. Several short named entry files (each a small re-export) front `_`-prefixed private implementation subfolders:

```
src/business/component/data-store/
├── common.ts        # public entry: re-exports from _common/
├── typeorm.ts       # public entry: re-exports from _typeorm/
├── memory.ts        # public entry: re-exports from _memory/
├── _common/         # interfaces + abstract CommonRepo
├── _typeorm/        # TypeormCommonDal
└── _memory/         # MemoryCommonDal
```

This is the answer to "a component with more than one public face": several named entry files instead of one `index.ts`.

## The `_` Prefix Rule

The `_` prefix marks files a consumer should never import. Applied consistently per component:

| Situation | Prefix strategies with `_`? |
|---|---|
| An in-folder `service.ts` selector chooses among them (Shape A) | **Yes** |
| Consumers (or a selector outside the folder) import them directly (Shape B) | **No** |
| Private helpers of an in-folder orchestrator (Shape C) | **Yes** |
| Private implementation subfolders behind public entry files (Shape D) | **Yes** |

What is NOT private is `service.ts` itself. Consumers import `#src/business/component/authentication/service` directly, even from controllers. The old rule "only index.ts is public" is too strong: `index.ts` holds the interface, `service.ts` is the callable API, and both are public.

## Strategy Class Anatomy

Strategy and pluggable classes follow one anatomy:

- **Constructor takes an object param** with the context, stored as `protected readonly _` fields: `protected readonly _astStatement`, `protected readonly _parseContext`
- **Public methods = the interface contract**: `parse()`, `format()`, `formatAssociations()`, `execute()`, `process()`, `pathToAbsolute()`. Nothing else is public; helpers that a consumer would want are a sign the contract is wrong or the piece should be a separate pluggable
- **Decomposition helpers are `protected _` methods**: `_removeComments`, `_heritageParse`, `_formatChildrenBodyLines`, `_generateRefreshToken`, `_unixExpDate`
- **`protected readonly _isEnabled`-style fields** back interface getters (`get isEnabled`)
- **Rare `static` methods are type guards**: `TokenRefresh.HasRefreshTokenHeaderTag()`, `ImportParserStrategyService.IsImportDeclaration()` (PascalCase)

Strategies are classes even when the selector is a singleton object. The class-vs-object decision inside a component: strategies carry per-call state in the constructor, so they are classes; the selector is stateless, so it is an object.

## Usage Examples

### From a use-case or service (calling the selector)

```typescript
import { entityFormatStrategyService } from '#src/business/component/entity-format-strategy/service'

const strategy = entityFormatStrategyService.entityToStrategy({ entityType, entity })
const formatted = strategy.format()
```

### From a controller (calling the public service directly)

```typescript
// src/controller/express/protected/get-access-token.ts
import { authenticationService } from '#src/business/component/authentication/service'

export const getAccessToken = {
  handler: new HttpUtil().expressEndPoint(async (req) => {
    return await authenticationService.check({ request: req })
  }),
}
```

### Importing a pluggable directly (Shape B)

```typescript
import { TokenRefresh } from '#src/business/component/token/refresh'

const isValid = TokenRefresh.HasRefreshTokenHeaderTag(headers)
```

## Key Principles

1. **Encapsulation**: the folder boundary is the API. Public files are imported from outside; `_`-prefixed files never are
2. **One unit of business logic per folder**: one dispatch family, one pluggable group, one orchestrated operation, or one multi-backend contract
3. **Dispatch is usual, not required**: polymorphic selection is the common trigger, but grouped pluggables and orchestrators are components too
4. **Strategy classes decompose into `protected _` helpers**: the class IS the splitting mechanism

## Common Pitfalls

- **Wrapper-object index.ts**: exporting a `xxxComponent` object that forwards to a private service. The etalon has none; consumers import `service.ts` directly
- **Barrel index.ts**: re-exporting everything. `index.ts` holds the strategy interface only
- **`_`-prefixing individually imported pluggables**: the prefix means "never imported outside"; do not put it on public files
- **Flattening a closed pattern into `business/service/`**: selector + strategies belong in one folder, or (if consumers pick strategies themselves) in a `business/service/<name>/` subfolder without a selector
- **Components calling controllers**: never; business layer never calls the controller layer
- **Grouping different domains into one folder** just because one calls the other: same-domain only; cross-domain composition goes through a use-case
