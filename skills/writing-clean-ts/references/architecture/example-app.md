# Example App: the assembled shape

A complete, real project in the canonical shape, so that creating from scratch,
extending, and cleanup all aim at the same target. Every file below comes from
an app that was verified end to end: `pnpm build` clean, `pnpm lint` exit 0, and
a full runtime smoke pass (create, nested reads, cascade updates, deletes,
graceful shutdown). Files repeated per domain (the second entity, the second
DAL, the remaining endpoints) are elided with a note; nothing shown is
pseudocode.

Read this when starting a new project (after `references/architecture/project-scaffold.md`),
or when restructuring, so the whole assembled result matches what the cleanup
command expects to find. Each file carries a "demonstrates" note naming the
rules it satisfies; the per-file starter shapes also exist in `templates/`.

Stack: Express 5 + TypeORM (better-sqlite3) + Zod, standalone single package
(no monorepo shared packages), msh utilities for boot/config/logging.

## Tree

```
src/
├── main.ts                                  # entry: starts the flow, nothing else
├── app-boot/
│   ├── todo-app.ts                          # AppFlow: ordered life cycles
│   └── life-cycle/
│       ├── database-life-cycle.ts           # init/destroy the DataSource singleton
│       └── express-life-cycle.ts            # assemble app, listen, close
├── controller/express/
│   ├── router.ts                            # expressRouter.registerRoutes(): whole route table
│   ├── schema/
│   │   ├── id-param-schema.ts               # shared :id param schema
│   │   └── todo-title-body-schema.ts        # shared title body schema (limits from constant)
│   ├── todo-list/                           # one file per endpoint, export { handler }
│   │   ├── get-todo-lists.ts
│   │   ├── post-todo-list.ts
│   │   ├── get-todo-list-by-id.ts
│   │   └── delete-todo-list-by-id.ts
│   ├── todo-item/
│   │   ├── post-todo-item.ts
│   │   ├── post-todo-item-sub-item.ts
│   │   ├── patch-todo-item-by-id.ts
│   │   └── delete-todo-item-by-id.ts
│   ├── not-found-middleware.ts
│   └── error-mapping-middleware.ts
├── business/
│   ├── model/
│   │   ├── todo-list-model.ts               # type TodoListModel
│   │   ├── todo-item-model.ts               # type TodoItemModel + TodoItemModelEdit
│   │   ├── todo-item-node.ts                # type TodoItemNode (self-referencing)
│   │   └── todo-list-detail.ts              # type TodoListDetail
│   ├── repo/
│   │   ├── todo-list-repo.ts                # TodoListRepo class + ITodoListDal interface
│   │   └── todo-item-repo.ts                # TodoItemRepo class + ITodoItemDal interface
│   └── service/
│       ├── todo-list-service.ts             # todoListService (plain object)
│       ├── todo-item-service.ts             # todoItemService (plain object)
│       ├── build-todo-item-node-service.ts  # class (recursion via this + protected _ helper)
│       └── find-descendant-ids-service.ts   # class (recursion via this)
├── dal/typeorm/
│   ├── entity/
│   │   ├── todo-list-entity.ts
│   │   └── todo-item-entity.ts
│   ├── todo-list-dal.ts                     # TodoListDal implements ITodoListDal
│   └── todo-item-dal.ts                     # TodoItemDal implements ITodoItemDal
├── lib/typeorm/
│   └── data-source-singleton.ts             # todoAppDataSourceSingleton
└── util/
    ├── config.ts                            # only reader of process.env (mshEnvResolver)
    ├── constant.ts                          # one constant object, nested keys
    ├── logger.ts                            # logger() over the msh preset
    ├── validation-util.ts                   # validationUtil.parse
    ├── not-found-error.ts                   # generic error classes live in util/
    └── conflict-error.ts
```

## Entry and boot

**`src/main.ts`** - demonstrates: the entry point only starts the flow
(`references/architecture/app-boot-layer.md`); no business logic, no signal
handling (`AppStarter` owns SIGTERM/SIGINT), no `console` (logger), and
`reflect-metadata` imported before anything that loads entities.

```typescript
import 'reflect-metadata'

import { AppStarter, setAppBootLogger } from '@beecode/msh-app-boot'

import { TodoApp } from '#src/app-boot/todo-app.js'
import { logger } from '#src/util/logger.js'

setAppBootLogger(logger())

new AppStarter(new TodoApp()).start().catch((error: unknown) => {
  logger().error('Todo app failed to start', error)
  process.exit(1)
})
```

**`src/app-boot/todo-app.ts`** - demonstrates: AppFlow lists life cycles in
dependency order; destroy runs the list reversed, so express stops before the
database closes.

```typescript
import { AppFlow } from '@beecode/msh-app-boot'

import { DatabaseLifeCycle } from '#src/app-boot/life-cycle/database-life-cycle.js'
import { ExpressLifeCycle } from '#src/app-boot/life-cycle/express-life-cycle.js'

export class TodoApp extends AppFlow {
  constructor() {
    super(new DatabaseLifeCycle(), new ExpressLifeCycle())
  }
}
```

**`src/app-boot/life-cycle/database-life-cycle.ts`** - demonstrates: a life
cycle delegates to a lib/business singleton and does nothing else
(`_createFn`/`_destroyFn` only).

```typescript
import { LifeCycle } from '@beecode/msh-app-boot'

import { todoAppDataSourceSingleton } from '#src/lib/typeorm/data-source-singleton.js'
import { logger } from '#src/util/logger.js'

export class DatabaseLifeCycle extends LifeCycle {
  constructor() {
    super({ name: 'Database' })
  }

  protected async _createFn(): Promise<void> {
    await todoAppDataSourceSingleton().initialize()
    logger().info('Database connection opened')
  }

  protected async _destroyFn(): Promise<void> {
    await todoAppDataSourceSingleton().destroy()
    logger().info('Database connection closed')
  }
}
```

The express life cycle follows the same shape (assemble `express()` with
`express.json()`, `expressRouter.registerRoutes()`, the two middleware, listen
on `config.port`, `await once(server, 'listening')`; `_destroyFn` closes and
awaits `'close'`), holding the server in `protected _server?: Server`.

## util and lib

**`src/util/config.ts`** - demonstrates: the only reader of `process.env`,
defaults in the declaration, frozen result (`references/architecture/constant-config-pattern.md`).

```typescript
import { mshEnv, mshEnvResolver } from '@beecode/msh-env'

const env = mshEnv()

export const config = mshEnvResolver({
  db: {
    name: env('DATABASE_NAME').string.default('todo-app.sqlite'),
  },
  port: env('PORT').number.default(3000),
})
```

**`src/util/constant.ts`** - demonstrates: one export, nested keys, min/max
under the value they describe; schema limits reference it instead of magic numbers.

```typescript
export const constant = {
  todoTitle: {
    length: {
      max: 255,
      min: 1,
    },
  },
}
```

**`src/util/logger.ts`** - demonstrates: the well-known util file invoked as
`logger()`; one instance behind `singletonPattern`; import msh packages through
their main entry (confirm exact paths with the `implementing-msh` skill).

```typescript
import { type LoggerStrategy, LogLevel } from '@beecode/msh-logger'
import { PresetConsoleSimpleString } from '@beecode/msh-logger/controller/preset/console-simple-string'
import { singletonPattern } from '@beecode/msh-util'

const loggerSingleton = singletonPattern((): LoggerStrategy => {
  return new PresetConsoleSimpleString({ logLevel: LogLevel.INFO })
})

export const logger = (): LoggerStrategy => {
  return loggerSingleton()
}
```

**`src/util/validation-util.ts`** - demonstrates: every controller interface
parses through one wrapper so all validation errors share a shape
(`references/frameworks/zod.md`).

```typescript
import { type z } from 'zod'

export const validationUtil = {
  parse<S extends z.ZodType>(data: unknown, schema: S): z.infer<S> {
    return schema.parse(data)
  },
}
```

**`src/lib/typeorm/data-source-singleton.ts`** - demonstrates: infrastructure
with no business logic lives in `lib/`; never `export const x = new X()`; the
connection values come from `config`, never `process.env`
(`references/frameworks/typeorm.md`).

```typescript
import 'reflect-metadata'

import { DataSource } from 'typeorm'
import { singletonPattern } from '@beecode/msh-util'

import { TodoItemEntity } from '#src/dal/typeorm/entity/todo-item-entity.js'
import { TodoListEntity } from '#src/dal/typeorm/entity/todo-list-entity.js'
import { config } from '#src/util/config.js'

export const todoAppDataSourceSingleton = singletonPattern((): DataSource => {
  return new DataSource({
    database: config.db.name,
    entities: [TodoListEntity, TodoItemEntity],
    synchronize: true,
    type: 'better-sqlite3',
  })
})
```

## Models

**`src/business/model/todo-item-model.ts`** - demonstrates: models are `type`,
never `interface` (`references/architecture/model-vs-entity.md`); booleans carry
the `is*` prefix; the business layer uses `undefined`, never `null`; the Edit
input of the model triple lives beside the model.

```typescript
export type TodoItemModel = {
  id: number
  isDone: boolean
  listId: number
  parentItemId?: number
  title: string
}

export type TodoItemModelEdit = {
  isDone?: boolean
  title?: string
}
```

The other models (`TodoListModel` with `createdAt: number`, the
self-referencing `TodoItemNode` with `subItem?: TodoItemNode`,
`TodoListDetail`) follow the same shape. Note `createdAt` is a unix-milliseconds
`number`, not a `Date` (`references/style/timestamp-handling.md`).

## Repository

**`src/business/repo/todo-item-repo.ts`** - demonstrates: the repo is a class
that owns its DAL as a protected field initializer (no constructor injection of
collaborators); the DAL contract `ITodoItemDal` is declared in the repo file;
the repo speaks business words (`create`/`edit`/`remove`/`find`) and converts
the DAL's `null` to `undefined` (`references/architecture/repository-layer.md`).

```typescript
import { type TodoItemModel, type TodoItemModelEdit } from '#src/business/model/todo-item-model.js'
import { TodoItemDal } from '#src/dal/typeorm/todo-item-dal.js'

export interface ITodoItemDal {
  readItemById(params: { id: number }): Promise<TodoItemModel | null>
  readItemsByListId(params: { listId: number }): Promise<TodoItemModel[]>
  readSubItemByParentItemId(params: { parentItemId: number }): Promise<TodoItemModel | null>
  removeItemsByIds(params: { ids: number[] }): Promise<void>
  writeItem(params: { listId: number; parentItemId?: number; title: string }): Promise<TodoItemModel>
  writeItemById(params: { changes: TodoItemModelEdit; id: number }): Promise<TodoItemModel | null>
}

export class TodoItemRepo {
  protected readonly _dal: ITodoItemDal = new TodoItemDal()

  async createItem(params: { listId: number; parentItemId?: number; title: string }): Promise<TodoItemModel> {
    return await this._dal.writeItem(params)
  }

  async editItemById(params: { changes: TodoItemModelEdit; id: number }): Promise<TodoItemModel | undefined> {
    const model = await this._dal.writeItemById(params)

    return model ?? undefined
  }

  async findItemById(params: { id: number }): Promise<TodoItemModel | undefined> {
    const model = await this._dal.readItemById(params)

    return model ?? undefined
  }

  async findItemsByListId(params: { listId: number }): Promise<TodoItemModel[]> {
    return await this._dal.readItemsByListId(params)
  }

  async findSubItemByParentItemId(params: { parentItemId: number }): Promise<TodoItemModel | undefined> {
    const model = await this._dal.readSubItemByParentItemId(params)

    return model ?? undefined
  }

  async removeItemsByIds(params: { ids: number[] }): Promise<void> {
    await this._dal.removeItemsByIds(params)
  }
}
```

## DAL and entity

**`src/dal/typeorm/entity/todo-item-entity.ts`** - demonstrates: every plain
`@Column` carries an explicit `type`. This is mandatory, not decoration: for a
nullable union like `number | null` the reflected design type is `Object` and
TypeORM throws `Data type "Object" ... is not supported` at schema sync; and
`tsx` (esbuild) emits no decorator metadata at all in dev, so reflection can
never be relied on (`references/frameworks/typeorm.md`).

```typescript
import { Column, Entity, PrimaryGeneratedColumn } from 'typeorm'

@Entity('todo_items')
export class TodoItemEntity {
  @PrimaryGeneratedColumn()
  id!: number

  @Column({ type: 'varchar' })
  title!: string

  @Column({ default: false, name: 'is_done', type: 'boolean' })
  isDone!: boolean

  @Column({ name: 'list_id', type: 'integer' })
  listId!: number

  @Column({ name: 'parent_item_id', nullable: true, type: 'integer', unique: true })
  parentItemId!: number | null
}
```

**`src/dal/typeorm/todo-item-dal.ts`** (abridged: the remaining read methods
follow `readItemById`) - demonstrates: the DAL implements the contract declared
in the repo file; repository access is a lazy protected getter through the lib
singleton (so app boot initializes the DataSource before any query); storage
vocabulary (`read`/`write`/`remove`); `undefined` to `null` conversion toward
the entity; entity-to-model conversion is a `protected _entityToModel` method,
never a module-level helper; no defaults are applied here (the column default
owns `isDone`).

```typescript
import { type Repository } from 'typeorm'

import { type TodoItemModel, type TodoItemModelEdit } from '#src/business/model/todo-item-model.js'
import { type ITodoItemDal } from '#src/business/repo/todo-item-repo.js'
import { TodoItemEntity } from '#src/dal/typeorm/entity/todo-item-entity.js'
import { todoAppDataSourceSingleton } from '#src/lib/typeorm/data-source-singleton.js'

export class TodoItemDal implements ITodoItemDal {
  protected get _repository(): Repository<TodoItemEntity> {
    return todoAppDataSourceSingleton().getRepository(TodoItemEntity)
  }

  async readItemById(params: { id: number }): Promise<TodoItemModel | null> {
    const { id } = params

    const entity = await this._repository.findOneBy({ id })
    if (entity === null) {
      return null
    }

    return this._entityToModel(entity)
  }

  async writeItem(params: { listId: number; parentItemId?: number; title: string }): Promise<TodoItemModel> {
    const { listId, parentItemId, title } = params

    const entity = this._repository.create({
      listId,
      parentItemId: parentItemId ?? null,
      title,
    })
    const savedEntity = await this._repository.save(entity)

    return this._entityToModel(savedEntity)
  }

  async writeItemById(params: { changes: TodoItemModelEdit; id: number }): Promise<TodoItemModel | null> {
    const { changes, id } = params

    await this._repository.update({ id }, changes)

    return await this.readItemById({ id })
  }

  protected _entityToModel(entity: TodoItemEntity): TodoItemModel {
    return {
      id: entity.id,
      isDone: entity.isDone,
      listId: entity.listId,
      parentItemId: entity.parentItemId ?? undefined,
      title: entity.title,
    }
  }
}
```

## Services

**`src/business/service/todo-item-service.ts`** (abridged to two methods) -
demonstrates: a plain-object service (methods independent, no state, no
helpers); repos instantiated at the call site, never constructor-injected;
business verbs (`edit`, `remove`) with names that cover the behavior
(`removeItemAndDescendants`); object params with a first-line destructure;
numbers never interpolated into template literals directly (`String(...)`
satisfies `restrict-template-expressions` without weakening the rule).

```typescript
export const todoItemService = {
  createItem: async (params: { listId: number; title: string }): Promise<TodoItemNode> => {
    const { listId, title } = params

    const list = await new TodoListRepo().findListById({ id: listId })
    if (list === undefined) {
      throw new NotFoundError(`Todo list ${String(listId)} was not found`)
    }

    const item = await new TodoItemRepo().createItem({ listId, title })

    return new BuildTodoItemNodeService().build({ item, items: [] })
  },

  removeItemAndDescendants: async (params: { id: number }): Promise<void> => {
    const { id } = params

    const item = await new TodoItemRepo().findItemById({ id })
    if (item === undefined) {
      throw new NotFoundError(`Todo item ${String(id)} was not found`)
    }
    const items = await new TodoItemRepo().findItemsByListId({ listId: item.listId })
    const descendantIds = new FindDescendantIdsService().find({ fromId: id, items })

    await new TodoItemRepo().removeItemsByIds({ ids: [id, ...descendantIds] })
  },
}
```

`build-todo-item-node-service.ts` is the counterpart case: its logic recurses,
so it is a class with recursion through `this` and a `protected _buildNode`
helper (`references/architecture/class-vs-object.md`: helpers or self-reference
mean class, never self-reference by export name).

## Controller

**`src/controller/express/todo-list/post-todo-list.ts`** - demonstrates: one
endpoint per file, camelCase plain object `{ handler }`; validate via
`validationUtil.parse`, exactly one business call, respond; services imported,
never passed in as parameters (the standalone variant described in
`references/frameworks/express.md`).

```typescript
import { type Request, type Response } from 'express'

import { todoListService } from '#src/business/service/todo-list-service.js'
import { todoTitleBodySchema } from '#src/controller/express/schema/todo-title-body-schema.js'
import { validationUtil } from '#src/util/validation-util.js'

export const postTodoList = {
  handler: async (req: Request, res: Response): Promise<void> => {
    const { title } = validationUtil.parse(req.body, todoTitleBodySchema)
    const todoList = await todoListService.createList({ title })
    res.status(201).json(todoList)
  },
}
```

**`src/controller/express/router.ts`** - demonstrates: the whole route table in
one place; the router wires `handler`s and holds nothing else.

```typescript
import { Router } from 'express'

import { deleteTodoItemById } from '#src/controller/express/todo-item/delete-todo-item-by-id.js'
import { patchTodoItemById } from '#src/controller/express/todo-item/patch-todo-item-by-id.js'
import { postTodoItemSubItem } from '#src/controller/express/todo-item/post-todo-item-sub-item.js'
import { postTodoItem } from '#src/controller/express/todo-item/post-todo-item.js'
import { deleteTodoListById } from '#src/controller/express/todo-list/delete-todo-list-by-id.js'
import { getTodoListById } from '#src/controller/express/todo-list/get-todo-list-by-id.js'
import { getTodoLists } from '#src/controller/express/todo-list/get-todo-lists.js'
import { postTodoList } from '#src/controller/express/todo-list/post-todo-list.js'

export const expressRouter = {
  registerRoutes(): Router {
    const router = Router()
    router.post('/todo-lists', postTodoList.handler)
    router.get('/todo-lists', getTodoLists.handler)
    router.get('/todo-lists/:id', getTodoListById.handler)
    router.delete('/todo-lists/:id', deleteTodoListById.handler)
    router.post('/todo-lists/:listId/todo-items', postTodoItem.handler)
    router.post('/todo-items/:id/sub-item', postTodoItemSubItem.handler)
    router.patch('/todo-items/:id', patchTodoItemById.handler)
    router.delete('/todo-items/:id', deleteTodoItemById.handler)

    return router
  },
}
```

Shared schemas live in `controller/express/schema/` (used by 2+ endpoints);
single-use schemas (a `listId` path schema, a PATCH body with a
`.refine(...)`) are `const` declarations inside their one endpoint file
(`references/frameworks/zod.md`).

## What a fresh cleanup pass finds here

Nothing structural: no relative imports, no folder-per-file, no bare function
exports, no constructor DI, no `interface` models, no `null` in business
shapes, no module-level helpers, no hardcoded tunables, no `console`, no `let`,
no comments. That is the round-trip guarantee this example exists to teach:
generate by these references and the cleanup checklist
(`references/commands/cleanup.md`) has nothing left to say except what only
the scripts can judge (run `lint`).
