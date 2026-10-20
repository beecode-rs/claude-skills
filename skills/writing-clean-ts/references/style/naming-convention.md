# Naming Conventions

This document defines naming standards for all layers in the TypeScript codebase.

## File Naming

All files and folders use **kebab-case** (dashed-case):

| Type            | Example                                                   |
| --------------- | --------------------------------------------------------- |
| Controller      | `controller/ipc/router.ts`, `controller/ipc/update.ts`    |
| Service         | `secret-service.ts` (business service layer ONLY)         |
| Repository      | `project-repo.ts`                                         |
| DAL             | `project-dal.ts`, `common-file-dal.ts`                    |
| Entity          | `project-entity.ts`                                       |
| Use Case        | `git-use-case.ts`                                         |
| Handler         | `get-projects-all.ts`, `post-project.ts` (Express routes) |
| Util            | `lang-util.ts`, `object-util.ts`, `path-util.ts`         |
| Lib             | `tray.ts`, `piper-engine.ts` (no suffix)                  |
| Model           | `project-model.ts`                                        |
| Enum            | `os-enum.ts`, `sound-name-mapper-enum.ts`                 |
| Life cycle      | `app-boot/life-cycle/settings-life-cycle.ts`              |
| Singleton       | `app-window-store-singleton.ts`                           |
| Folders         | `some-folder/`, `service/`                                |

### Layer File Suffixes

The file suffix tells a reader which layer a file belongs to before they open it. The `-service` suffix belongs **exclusively** to the business service layer (`src/business/service/`) - anywhere else it is misleading, because utils, DALs, controllers, and lib modules are not business services. Each layer uses its own suffix:

| Layer               | Folder                    | Suffix        | Example File        | Example Export                                |
| ------------------- | ------------------------- | ------------- | ------------------- | --------------------------------------------- |
| Controller router   | `src/controller/<interface>/` | `router.ts` | `ipc/router.ts`   | `ipcRouter` (camelCase object)                |
| Service             | `src/business/service/`   | `-service`    | `tts-service.ts`    | `TtsService` class / `ttsService` object      |
| Repository          | `src/business/repo/`      | `-repo`       | `project-repo.ts`   | `ProjectRepo` class                           |
| Use Case            | `src/business/use-case/`  | `-use-case`   | `git-use-case.ts`   | `gitUseCase` object                           |
| Model               | `src/business/model/`     | `-model`      | `usage-model.ts`    | `UsageModel` type (or class)                  |
| Enum                | `src/business/enum/`      | `-enum` / `-mapper-enum` | `os-enum.ts` | `OS` enum / `SoundNameMapper` enum     |
| DAL                 | `src/dal/`                | `-dal`        | `history-dal.ts`    | `HistoryDal` class                            |
| Entity              | `src/dal/*/entity/`       | `-entity`     | `project-entity.ts` | `ProjectEntity` class                         |
| Life cycle          | `src/app-boot/life-cycle/`| `-life-cycle` | `settings-life-cycle.ts` | `SettingsLifeCycle` class                |
| Util                | `src/util/`               | `-util`       | `lang-util.ts`      | `langUtil` (camelCase object)                 |
| Lib                 | `src/lib/`                | none          | `tray.ts`           | `Tray` class / `tray` object                  |

A `*-service.ts` file outside `src/business/service/` is a naming violation - rename it to its layer's suffix (or drop the suffix entirely, for lib).

#### Util Layer Exceptions

Four well-known utility files do not take the `-util` suffix. The reason is name recognition: these names are well known for their behaviour, so the name alone states what the file does and the suffix would add nothing:

- `config.ts` (the frozen `config` object from `mshEnvResolver`, the only reader of `process.env`)
- `constant.ts` (singular: one exported `constant` object whose keys are the constants - never `constants.ts`)
- `logger.ts` (invoked as `logger()`)
- `error.ts` (usually a one-line re-export of `errorFactory`, invoked as `error()`)

`constant.ts` and `config.ts` follow their own shape and naming rules: keys nest by shared prefix, regex keys end in `Regex`, time keys are milliseconds ending in `Ms`, and there are no `UPPER_CASE` exports.

Every other util file ends in `-util` (`lang-util.ts`, `object-util.ts`, `path-util.ts`, `date-util.ts`).

Utils come in both export shapes: PascalCase classes (`FilePathUtil`, `StringUtil`, `HttpUtil`, `TimeUtil`) and camelCase singleton objects (`objectUtil`, `validationUtil`, `cryptoUtil`, `regexUtil`). Pick the shape by the same class-vs-object rule as services.

A file named `-util` must actually be a util. If it knows the domain (imports `business/model/`, works on domain shapes), it is a service and moves to `business/service/` under a `-service` name. If it encodes knowledge of an external system (another tool's file format, a vendor protocol), it is lib code and moves to `lib/<name>/`.

#### The `-singleton` Suffix

A `<name>-singleton.ts` file holds a class that must have exactly one instance, and its accessor. Both live in the **same file**: the class first, exported with a leading underscore so every reader knows not to instantiate it directly, and the `singletonPattern` accessor at the end of the file:

```typescript
// src/lib/app-window-store-singleton.ts
import { singletonPattern } from '@beecode/msh-util/singleton/pattern'

export class _AppWindowStore {
  protected _window: BrowserWindow | undefined = undefined

  fetchWindow(): BrowserWindow | undefined {
    return this._window
  }
}

export const appWindowStoreSingleton = singletonPattern(() => {
  return new _AppWindowStore()
})
```

Never split the class and its singleton into two files (`app-window-store.ts` + `app-window-store-singleton.ts`). The `_` class is exported only so types and tests can reach it; application code always goes through the accessor. Use the suffix only when the instance holds memory a fresh instance would not have.

#### Lib Layer - No Suffix, Never `-service` (one exception: the lib's own service.ts)

Lib code wraps infrastructure and external systems (Electron tray and global shortcuts, external process engines, DB or message-broker connections). It contains no business logic, so it is not a service - neither in the filename nor in the export name:

- ❌ `src/lib/tray-service.ts` exporting `TrayService` → ✅ `src/lib/tray.ts` exporting `Tray`
- ❌ `src/lib/piper-engine-service.ts` → ✅ `src/lib/piper-engine.ts`

**The one exception: `service.ts` inside a `lib/<vendor>/` subfolder.** The lib layer is meant to be exported as an external lib, and an external lib can have its own service layer. `src/lib/dockerode/service.ts` exporting `dockerodeService`, `src/lib/rmq/service.ts` exporting `rmqService`, `src/lib/typeorm/service.ts` exporting `typeormService`: each is that wrapper library's own service, its operational API. The file is always named exactly `service.ts` (never a vendor-prefixed `-service` name), and the `-service` suffix ban keeps applying to every other lib file name.

#### Express Endpoint Files

Files under `src/controller/express/` keep their endpoint-based handler names (`get-projects-all.ts`, `post-project.ts`).

Every other controller interface (IPC, event bus, message queue, cron) is a folder `src/controller/<interface>/` holding a `router.ts` that registers everything, plus one file per domain holding that domain's handler callbacks (`controller/ipc/update.ts`, `controller/ipc/settings.ts`).

### Private Files (Leading Underscore)

A single leading underscore (`_`) on a filename is an allowed **visibility marker**: the file is **private to its folder/component** and must only be imported by other files inside that same folder. It must never be imported from outside the component.

- The text **after** the underscore is still kebab-case, so `_in-progress.ts` is valid.
- The underscore is a visibility marker, not part of the name.
- This mirrors the `_` prefix convention for protected members in classes and objects (for example `protected _internalDecrypt`).

**Structure:**
```
src/business/component/todo-status/
├── _todo.ts           # private rule, exports todoRule
├── _in-progress.ts    # private rule, exports inProgressRule
├── _done.ts           # private rule, exports doneRule
├── _cancelled.ts      # private rule, exports cancelledRule
└── service.ts         # the only file that imports the _ files
```

Nothing outside the `todo-status/` folder imports the `_`-prefixed files.

This is **optional** and most common in the Component layer, where it is an alternative to a `rule/` subfolder for keeping private rule files flat while still signaling "do not import me from outside this folder".

### Subfolder Naming Convention (All Layers)

When organizing related files in a **subfolder** within any layer (`src/business/service/`, `src/business/component/`, `src/controller/`, etc.), use this naming convention:

**Structure:**
```
src/business/service/formatting-strategy/
├── formatting-strategy.ts   # FormattingStrategy interface (optional, can also be in model/)
├── json.ts                  # FormattingStrategyJson class
└── simple-string.ts         # FormattingStrategySimpleString class
```

**Naming Pattern:**

| Element | Pattern | Example |
|---------|---------|---------|
| **Folder** | `kebab-case/` | `formatting-strategy/`, `yaml-parser/` |
| **File** | `kebab-case.ts` (no suffix) | `json.ts`, `date.ts`, `console.ts` |
| **Class** | `PascalCase` with folder prefix | `FormattingStrategyJson`, `YamlParserDate` |
| **Singleton** | `camelCase` with folder prefix | `formattingStrategyJson`, `yamlParserDate` |

**Class Naming Formula:** `<FolderContextPascal><DomainPascal>`
- Folder: `formatting-strategy` → Prefix: `FormattingStrategy`
- File: `json.ts` → Domain: `Json`
- Result: `FormattingStrategyJson`

**Singleton Naming Formula:** `<folderContextCamel><DomainPascal>`
- Folder: `formatting-strategy` → Prefix: `formattingStrategy`
- File: `json.ts` → Domain: `Json`
- Result: `formattingStrategyJson`

**The master rule: the export name is the folder name + file name concatenated.** Two segments are never part of the name:

1. **Layer path segments are skipped**: `src/`, `business/`, `component/`, `service/`, `dal/`, `controller/` and friends group files, they never name them. `business/component/entity-parser-strategy/service.ts` exports `entityParserStrategyService`, not `BusinessComponentEntityParserStrategyService`.
2. **The `_` privacy prefix is skipped**: `_class.ts` contributes `Class`, not `_Class`.

The file name's segment always lands at the end and carries the role suffix (`Service`, `Class`, `Enum`, `Controller`, `Dal`, ...), which is why flat files outside subfolders carry the suffix in the filename itself (`secret-service.ts` → `SecretService`).

**Reserved file names.** Inside a subfolder, two file names are reserved so the folder's primary files don't repeat the folder name in the filename:

| File | Name contribution | Export in `entity-parser-strategy/` |
|------|-------------------|-------------------------------------|
| `index.ts` | Nothing: the export is named exactly after the folder | `EntityParserStrategy` (the strategy interface, same name as the folder) |
| `service.ts` | `Service` | `entityParserStrategyService` (singleton) or `EntityParserStrategyService` (class) |

Use `index.ts` when the folder's strategy interface is named the same as the folder (the usual case for a strategy family). Use `service.ts` for the folder's public service: the file stays `service.ts` because the export name `entityParserStrategyService` already says everything the filename would. Every other file in the folder concatenates normally: `_class.ts` → `EntityParserStrategyClass`, `_enum.ts` → `EntityParserStrategyEnum`.

**Why this convention:**
- **Simple file names**: Files in subfolders don't need `-service` suffix since the folder already provides context
- **Unique class names**: Prefix prevents naming conflicts across different subfolders
- **Self-documenting**: `FormattingStrategyJson` immediately tells you it's the JSON implementation of the formatting strategy

**Examples across different layers:**

```
src/business/service/
├── formatting-strategy/           # Strategy implementations
│   ├── json.ts                    # FormattingStrategyJson
│   └── simple-string.ts           # FormattingStrategySimpleString
├── transporting-strategy/         # Strategy implementations
│   ├── console.ts                 # TransportingStrategyConsole
│   ├── pino.ts                    # TransportingStrategyPino
│   └── void.ts                    # TransportingStrategyVoid
└── secret-service.ts              # Unrelated service as flat file

src/controller/
└── preset/                        # Preset entry points
    ├── console-simple-string.ts   # PresetConsoleSimpleString
    ├── console-json.ts            # PresetConsoleJson
    └── void.ts                    # PresetVoid

src/business/component/
└── yaml-parser/                   # Complex component with subfiles
    ├── date.ts                    # YamlParserDate
    ├── error.ts                   # YamlParserError
    └── index.ts                   # Re-exports for convenience
```

### Domain Folders: Strip the Prefix from File Names

When a group of flat files sharing a prefix (`sessions-service-singleton.ts`, `sessions-poll-service.ts`, `ssh-sessions-service-singleton.ts`) grows into a folder, the folder takes the prefix and the file names drop it. The export names keep it, because the export name is always folder + file:

```
Before                                                After
business/service/sessions-service-singleton.ts        business/service/sessions/service-singleton.ts      → sessionsServiceSingleton
business/service/sessions-poll-service.ts             business/service/sessions/poll-service.ts           → SessionsPollService
business/service/ssh-sessions-service-singleton.ts    business/service/sessions/ssh-service-singleton.ts  → sessionsSshServiceSingleton
business/service/sessions-focus-*.ts                  business/service/sessions/focus/<name>.ts           → SessionsFocus<Name>
```

A file name never repeats its folder name (`sessions/sessions-poll-service.ts` is wrong), and the word order follows the folder path (`sessions/ssh-service.ts`, not `ssh-sessions-service.ts`).

### When to use subfolders vs. flat files

| Scenario | Approach | Example |
|----------|----------|---------|
| Single, standalone service | Flat file | `src/business/service/secret-service.ts` |
| Multiple implementations of one interface | Subfolder | `src/business/service/formatting-strategy/json.ts` |
| Complex component with sub-parts | Subfolder | `src/business/component/yaml-parser/date.ts` |
| Related controller presets | Subfolder | `src/controller/preset/console-simple-string.ts` |
| Domain with multiple endpoints | Subfolder | `src/controller/express/project/get-projects-all.ts` |

### Singular vs Plural

**Use singular whenever possible** for files, folders, database table names, classes, and other entities.

**Plural exceptions:**
- **REST API endpoints** - Standard convention (e.g., `/api/users`, `/api/projects`)
- **Variable/Function names** - When descriptive clarity requires it (e.g., `getUsers()`, `allProjects`)
- **Database table columns** - When the column stores an array or collection (e.g., `tags_array`, `permissions_json`)

## Export Naming

### Classes vs Singleton Objects

The codebase uses two patterns:

- **Classes**: PascalCase exports, instantiated with `new ClassName()`
- **Singleton Objects**: camelCase exports, used directly without instantiation

**Quick Reference:**

| When to Use | Pattern | Example |
|-------------|---------|---------|
| Methods call each other via `this`, or need `_` helpers | Class | `export class SecretService` |
| Methods are independent, no helpers | Plain object | `export const calculationService` |
| Repository, DAL, Entity (mandatory) | Class | `export class ProjectRepo` |
| Use Case, Handler (mandatory) | Plain object | `export const authUseCase` |
| One instance holding memory | `_Class` + `singletonPattern` in a `-singleton.ts` file | `export const settingsRepoSingleton` |

## Naming Convention Summary Table

| Layer                     | Pattern   | Naming              | Example Export                    | Usage Example                    |
| ------------------------- | --------- | ------------------- | --------------------------------- | -------------------------------- |
| **Service** (with `this`) | Class     | PascalCase          | `export class SecretService`      | `new SecretService().decrypt()`  |
| **Service** (independent) | Plain object | camelCase        | `export const calculationService` | `calculationService.calculate()` |
| **Service** (builds a value) | Factory function | camelCase | `export const dbConfigFactory`   | `dbConfigFactory({ env })`       |
| **Service** (one stateful instance) | `_Class` + accessor | camelCase + `Singleton` | `export const sessionsServiceSingleton` | `sessionsServiceSingleton().fetch()` |
| **Util**                  | Object or Class | camelCase / PascalCase | `export const langUtil` / `export class FilePathUtil` | `langUtil.detectLang()` / `new FilePathUtil()` |
| **Lib**                   | Class or Object | PascalCase / camelCase | `export class Tray`       | `new Tray()`                     |
| **Repository**            | Class     | PascalCase          | `export class ProjectRepo`        | `new ProjectRepo().findMany()`   |
| **Use Case**              | Plain object | camelCase        | `export const gitUseCase`         | `gitUseCase.getCommits()`        |
| **DAL**                   | Class     | PascalCase          | `export class ProjectDal`         | `new ProjectDal()`               |
| **Entity**                | Class     | PascalCase          | `export class ProjectEntity`      | `new ProjectEntity()`            |
| **Handler**               | Plain object | camelCase        | `export const getProjectsAll`     | `getProjectsAll.handler`         |
| **Model**                 | Type (class only when it constructs defaults) | PascalCase + `Model` | `export type UsageModel` | `const usage: UsageModel` |
| **Enum**                  | Enum      | PascalCase, no `Enum` suffix | `export enum OS`        | `OS.MACOS`                       |
| **Interface** (a class implements it) | Interface | I-prefix PascalCase | `export interface IProjectDal` | `class ProjectDal implements IProjectDal` |

## Naming Principles

These apply to every name: files, folders, exports, enums, constant keys, types, and variables.

### Name What It Is, Not Where It Is Used

A name describes the thing itself. A name that describes its current caller breaks the moment a second caller appears, and it misleads readers into thinking the thing belongs to that caller.

| ❌ Named after its user | ✅ Named after what it is | Why |
|---|---|---|
| `SessionSoundMapper` | `SoundNameMapper` | It maps sound names; sessions just happen to be the first user |
| `versionCompareRegex` | `digitSequenceRegex` | It matches digit sequences, wherever that is needed |
| `settingsUseCase` (runs once on boot) | `SettingsLifeCycle` in `app-boot/life-cycle/` | It is startup setup, so it is a life cycle, not a use case |
| `session-transcript-util.ts` (parses Claude Code files) | `lib/claude-transcript-reader/` | It is a reader for an external tool's format |
| `usage-pulse-app-flow.ts` | `desktop-app.ts` | The project name adds nothing; the file is the desktop app flow |

Two corollaries:

- **Never prefix with the project or product name.** Everything in the repo belongs to the project; the prefix carries no information.
- **Specific enough to be unambiguous.** When the domain has several kinds of a thing, the generic word is too vague. An app with schedule triggers, usage-reload triggers, and session-reload triggers has no `TriggerModel`: it has `ScheduleTriggerModel`, and the others get their own qualified names.

### One Meaning Per Word

When one word means two different things in the project, qualify both everywhere. "Token" in an LLM app means both the *access token* used to authenticate and the *LLM token* that is counted for usage. So `ClaudeTokenSource` (where the access token comes from) becomes `ClaudeAccessTokenSource`, and `tokenSource` becomes `accessTokenSource`, in every file, identifier, and property, not only in the file where the confusion was noticed.

### Renames Propagate Everywhere

A rename is complete only when every reference follows: the file name, the export, every import, every caller's variable and property names, function names that embed the old name (`getUsageStatus` → `getUsageActivityStatus`), and test files. Search the whole source tree for the old name (both camelCase and kebab-case forms) before calling a rename done.

## Method Naming

All methods use **camelCase** `[lint]`. Member casing and underscore prefixes (`protected _`, private `__`) are enforced by the ESLint `@typescript-eslint/naming-convention` rule; the naming semantics below are not lint-checkable:

### Action-Based Naming

**CRITICAL:** Every function must specify the action it performs. Function names must include an action verb.

**Bad Examples:**
```typescript
users()           // ✗ Missing action verb
user()            // ✗ Missing action verb
project()         // ✗ Missing action verb
```

**Good Examples:**
```typescript
getUsers()        // ✓ Clear action: retrieval
editUserFullName() // ✓ Clear action: modification
createProject()   // ✓ Clear action: creation
```

### Business Logic Verb Conventions

**IMPORTANT:** Avoid ORM/database-specific verbs in business logic. Use business-friendly verbs instead.

| Avoid (DB-specific) | Use (Business logic) | Context |
|---------------------|---------------------|---------|
| `insertUser()` | `createUser()` | Creating new records |
| `updateUser()` | `editUser()` | Modifying existing records |
| `deleteUser()` | `removeUser()` | Removing records |
| `writeSettings()` | `saveSettings()` | Persisting a whole value |
| `readSettings()` | `fetchSettings()` / `loadSettings()` | Getting a stored value |

**The vocabulary splits at the repo/DAL boundary.** Repos and everything above them speak business words (`create`, `edit`, `remove`, `save`, `fetch`, `find`, `load`, `init`). DALs speak storage words (`read`, `write`, `readJsonFile`, `writeValue`), because the DAL is where the storage framework lives. A repo method named `readFile` or a DAL method named `saveSettings` is in the wrong layer's language.

**Examples:**

```typescript
// ✗ Bad: Database-centric naming
async insertProject(data: ProjectCreate): Promise<Project>
async updateProjectName(id: string, name: string): Promise<void>
async deleteProject(id: string): Promise<void>

// ✓ Good: Business-centric naming
async createProject(data: ProjectCreate): Promise<Project>
async editProjectName(id: string, name: string): Promise<void>
async removeProject(id: string): Promise<void>
```

### REST Endpoint Alignment

Function names should align with REST endpoint semantics:

**PUT Endpoints (Full Object Mutation - Backoffice Only):**
```typescript
// PUT /admin/users/:id - Backoffice: mutate entire user object
async editUser(id: string, data: UserUpdate): Promise<User>
```

**PATCH Endpoints (Partial Update - End Users):**
```typescript
// PATCH /users/:id/name - End user: update specific field
async editUserName(id: string, name: string): Promise<void>

// PATCH /users/:id/profile - End user: update profile section
async editUserProfile(id: string, profile: ProfileUpdate): Promise<void>
```

**POST Endpoints (Creation):**
```typescript
// POST /users - Create new user
async createUser(data: UserCreate): Promise<User>
```

**DELETE Endpoints (Removal):**
```typescript
// DELETE /users/:id - Remove user
async removeUser(id: string): Promise<void>
```

### Established Name Patterns

These recurring name shapes are load-bearing conventions:

- **`IfExists` suffix** (`getTextIfExists`, `getModifiersIfExists`, `_printBodyLinesIfExists`): "decorate only when present" helpers. Use it whenever a function returns or skips gracefully because a value is absent
- **`By` mid-name** (`getCommitsByOwnProjectId`, `SortByName`, `FilterByType`, `FindById`): names the discriminator the function selects by
- **`And` conjunctions** (`breakAndIndentParameterList`, `getPasswordScoreAndFeedback`, `_splitGroupAndRestChildren`): rare and legitimate only when the pair is genuinely one operation. The default remains "the name covers everything; split when you need And"
- **PascalCase `static` utility methods on classes** (`Clone`, `Parse`, `SortByName`, `FilterByType`, `FindById`, `IsImportDeclaration`, `HasRefreshTokenHeaderTag`): class-level operations and type guards, distinct from the camelCase instance API
- **Layer vocabulary gradient**: repo method names are the longest and endpoint-mirroring (`postProtectedProjectParseDataEntities`), strategy contract methods are one-word (`format`, `execute`, `parse`, `value`), and services sit between. Name at the altitude of your layer
- **Selector methods name the dispatch**: `entityToStrategy`, `getStrategyFrom`, `strategyByStatementKindIfParsable`
- **Recurring verb pairs encode domain contracts**: `generate`/`verify` across token classes, `format`/`formatAssociations` across entity-format strategies, `parse` as the universal strategy contract method

### Standard Method Examples

```typescript
// Services
decryptSecret(params: { secret: string }): string
async validateAndProcessOrder(params: { order: OrderModel }): Promise<void>
async createUserAccount(params: { user: UserModelCreate }): Promise<UserModel>
async editUserEmail(params: { userId: string; email: string }): Promise<void>

// Repositories
async findOneById(params: { id: string }): Promise<Model>
async findMany(params: { filter: FilterModel }): Promise<Model[]>
async create(params: { model: ModelCreate }): Promise<Model>
async editById(params: { id: string; model: ModelEdit }): Promise<Model>

// Use Cases
async getCommitsByOwnProjectId(params: { projectId: string }): Promise<CommitModel[]>
async createProject(params: { project: ProjectModelCreate }): Promise<ProjectModel>
async editProjectSettings(params: { projectId: string; settings: ProjectSettingsModel }): Promise<void>
async removeProjectMember(params: { projectId: string; userId: string }): Promise<void>
```

### Use Case Function Names

**Use Cases are the only layer where shorter function names are allowed.**

A use-case name is short *because* the operation is complex: too complex to capture in one name without making it unwieldy. The detail is carried by the **body**. Each step is a call to a service/repo/component whose own name describes that step, so the reader understands the whole operation by reading those step names.

Use case functions should be:
- Self-documenting through the body (calls to other service functions with longer, descriptive names)
- **Created only when they orchestrate two or more steps.** A use-case that calls a single service function is a useless wrapper: the controller can call that service directly, so there is nothing to orchestrate.

**Example:**
```typescript
// authorization-use-case.ts

async authorize(params: { email: string; password: string }): Promise<AuthResultModel> {
  const { email, password } = params

  const user = await userService.findUserByEmailAndValidatePassword({ email, password })
  const tokens = await tokenService.generateAccessAndRefreshTokens({ userId: user.id })
  await sessionService.createUserSessionRecord({ userId: user.id, refreshToken: tokens.refreshToken })

  return tokens
}
```

The single word `authorize` is acceptable only because the three steps below it make the operation unambiguous. A one-line body that forwards a single call would not justify the name, or the use-case, at all.

## Model File Conventions

A model file `<name>-model.ts` exports the model triple as zod-inferred types of co-located schemas:

- `XxxModel`: the full representation
- `XxxModelCreate`: the create input (required subset)
- `XxxModelEdit`: the edit input (optional subset)

```typescript
// src/business/model/core/user-model.ts
const userModelSchema = z.object({
  id: z.string(),
  email: z.string(),
  createdAt: z.number(),
})
const userModelCreateSchema = z.object({
  email: z.string(),
})
const userModelEditSchema = z.object({
  email: z.string().optional(),
})

export type UserModel = z.infer<typeof userModelSchema>
export type UserModelCreate = z.infer<typeof userModelCreateSchema>
export type UserModelEdit = z.infer<typeof userModelEditSchema>
```

Type-only model files carry NO `-model` suffix when they are not zod-backed record shapes: `pagination.ts` (`PaginationParam`, `PaginationResult`), `sort.ts` (`Sort`).

A model folder holds only models. Every export in it is a model: named `XxxModel`, never `XxxEntity` (entities exist only in the DAL), declared with `type` (never `interface`), and free of business logic. Enums do not live in `model/`; they live in the sibling `enum/` folder (see "Enum Naming" below).

Models live in domain subfolders (`model/auth/`, `model/core/`, `model/common/`) with `__tests__/` fake factories next to them (`user-model-fake-factory.ts`).

## Timestamp Field Naming

**CRITICAL:** All fields that hold Unix timestamps (in milliseconds) must use the suffix `At`.

### Standard Timestamp Field Names

| Field Name | Purpose | Type |
|------------|---------|------|
| `createdAt` | When record was created | `number` |
| `updatedAt` | When record was last updated | `number` |
| `deletedAt` | When record was soft-deleted | `number \| null` |
| `disabledAt` | When record was disabled | `number \| null` |
| `startAt` | When something started | `number` |
| `endAt` | When something ended | `number` |
| `verifiedAt` | When something was verified | `number` |
| `publishedAt` | When something was published | `number` |
| `at` | Event timestamp (when distinct from creation) | `number` |

### Examples

```typescript
// Entity
export class ProjectEntity {
  @CreateDateColumn({ ...typeormUtil.timestampColumnOptions })
  createdAt!: number

  @UpdateDateColumn({ ...typeormUtil.timestampColumnOptions })
  updatedAt!: number

  @DeleteDateColumn({ ...typeormUtil.timestampColumnOptions, nullable: true })
  deletedAt?: number | null
}

// Model
export type ProjectModel = {
  id: string
  name: string
  createdAt: number      // Unix timestamp in milliseconds
  updatedAt: number      // Unix timestamp in milliseconds
  deletedAt?: number     // Unix timestamp in milliseconds (optional)
}

// Distinguishing between creation and event time
export type GpsLocationModel = {
  id: string
  createdAt: number    // When record was saved to database
  lon: number
  lat: number
  at: number           // When GPS location was actually recorded
}
```

## Boolean Naming Conventions

Boolean variables, properties, and methods that return boolean values must use descriptive prefixes that clearly indicate they represent a true/false state.

### Standard Prefixes

Two prefixes are used in practice; stick to them:

| Prefix | Purpose | Example |
|--------|---------|---------|
| `is*` | State or condition check | `isActive`, `isVerified`, `isEnabled`, `isOwner` |
| `has*` | Possession or containment | `hasPermission`, `hasChildren`, `hasNoBooleanCliArgSelected` |

`can*`, `should*`, `will*`, and `did*` do not appear in the etalon (0 occurrences against 23 for `is`/`has`); do not introduce them. `checkPermission`-style verb names are also wrong for booleans: use `hasPermission`.

### Variables and Properties

```typescript
// ✓ Good - clear boolean intent
const isVisible: boolean = true
const hasPermission: boolean = false
const project = { ...base, isRemovable: false }

// ✗ Bad - unclear boolean intent
const visible: boolean = true         // What kind of visible?
const permission: boolean = false     // Has permission? Or is permission?
const project = { ...base, canBeDeleted: false } // can* is not a used prefix
```

### Methods Returning Boolean

A function that returns `boolean` (or `Promise<boolean>`) follows the same rule as a boolean variable: its name **starts** with `is` or `has`. The prefix goes first; a verb in front of it (`resolveIs...`, `checkHas...`, `getIs...`) hides the fact that the function is a predicate.

```typescript
// ✓ Good
isValidEmail(params: { email: string }): boolean
hasRequiredPermissions(params: { user: User }): boolean
isNewerVersion(params: { current: string; candidate: string }): boolean
isValidToken(params: { token: string }): Promise<boolean>

// ✗ Bad
validEmail(params: { email: string }): boolean                  // Missing is prefix
checkPermission(params: { user: User }): boolean                // Use hasPermission
resolveIsNewerVersion(params: { ... }): boolean                 // Prefix must come first: isNewerVersion
engineInstalled(): Promise<boolean>                             // Promise<boolean> needs the prefix too: isEngineInstalled
```

### Two-Option Enums Are Booleans

An enum (or string union) with exactly two members that mean yes/no (`SUPPORTED` / `UNSUPPORTED`, `ENABLED` / `DISABLED`) is a boolean in disguise. Replace it with an `is*`/`has*` flag (`isFocusSupported: boolean`) and delete the enum. Keep an enum only when the two members are genuinely two named states and a third is plausible.

### Avoid Negated Names

Prefer positive boolean names over negated ones to avoid double negatives:

```typescript
// ✗ Bad - double negatives are confusing
if (!isNotValid) { /* ... */ }
if (!hasNoErrors) { /* ... */ }
const isNotDisabled = true

// ✓ Good - clear and direct
if (isValid) { /* ... */ }
if (hasErrors) { /* ... */ }
const isEnabled = true
```

### Entity Properties

```typescript
export class UserEntity {
  @Column({ default: true })
  isActive!: boolean

  @Column({ default: false })
  hasVerifiedEmail!: boolean

  @Column({ default: false })
  isNotificationMuted!: boolean
}
```

### Database Column Naming

For database columns, use snake_case with the same prefix:

| TypeScript Property | Database Column |
|---------------------|-----------------|
| `isActive` | `is_active` |
| `hasPermission` | `has_permission` |
| `isEditable` | `is_editable` |

## Type Naming

Types use **PascalCase** and are declared with `type`:

```typescript
type ResData = z.infer<typeof resDataSchema>
type ProjectModelCreate = { name: string; sourceUrl: string }
```

**`type` by default, `interface` only for classes.** Models, params, props, and every other shape are `type`. An `interface` exists only when a class `implements` it (a DAL contract like `IProjectDal`, a strategy contract), and only an interface carries the `I` prefix:

```typescript
export type UsageModel = { providerId: ProviderId; usedTokenCount: number }   // ✓ type, no I
export interface IProjectDal extends ICommonDal<...> {}                       // ✓ a class implements it
export class ProjectDal implements IProjectDal { ... }

export interface UsageModel { ... }   // ✗ a model is a type, not an interface
export type IUsageModel = { ... }     // ✗ a type never takes the I prefix
```

One exception keeps its established name: a strategy interface in a component or service folder's `index.ts` is named exactly after the folder (`EntityParserStrategy`), per the subfolder naming formula, with no `I`.

When you find a `type` starting with `I` (a leftover from when interfaces were converted to types), remove the `I`. If that collides with an existing name, pick a name that says what the type is (`ProviderCatalog` → `ProviderCatalogModel`, `IConfig` → `AppConfig`), never a new prefix.

## Enum Naming

Enums are part of the business model, but they get their own folder so the model folder stays models only.

### Placement and File Names

- **One enum per file**, in `business/enum/` next to `business/model/` (`src/business/enum/`, and in a multi-process app `src/shared/business/enum/`, `src/main/business/enum/`, ...). When an enum is found inside a model file or the `model/` folder, move it to the sibling `enum/` folder.
- **The file name carries the suffix, the enum name does not.** `os-enum.ts` exports `OS`; `usage-activity-status-enum.ts` exports `UsageActivityStatus`. Never `export enum OSEnum`.
- **Keys are `UPPER_CASE`.**

### Rule 1: Identical Keys and Values (Default)

**Use the same name for KEY and VALUE.**

```typescript
// src/business/enum/schedule-trigger-run-phase-enum.ts
export enum ScheduleTriggerRunPhase {
  FINISHED = 'FINISHED',
  RUNNING = 'RUNNING',
  WAITING = 'WAITING',
}
```

### Rule 2: Different Keys and Values (`Mapper`)

**When the value cannot equal the key, the enum is a mapper**: the enum name ends with `Mapper` and the file name ends with `-mapper-enum.ts`.

```typescript
// src/business/enum/sound-name-mapper-enum.ts
export enum SoundNameMapper {
  CHIME = 'chime.wav',
  POP = 'pop.wav',
}

// src/business/enum/ipc-channel-mapper-enum.ts
export enum IpcChannelMapper {
  USAGE_REFRESH_TRACKER = 'usage:refresh-tracker',
}
```

An enum whose keys and values differ but that is not named as a mapper (`SessionSoundId` with values like `'chime.wav'`) is a naming violation: rename it `...Mapper` and move it to a `-mapper-enum.ts` file.

### String Unions Become Enums

A string union type standing for a closed set of domain values (`type ProviderId = 'claude' | 'zai'`, `phase: 'waiting' | 'running' | 'finished'`) is converted to an enum in its own file, and every literal usage (`=== 'claude'`, `providerId: 'zai'`) switches to the enum member (`ProviderId.CLAUDE`). Because enum keys are `UPPER_CASE`, a union of lowercase values usually becomes a mapper (`ProviderIdMapper.CLAUDE = 'claude'`) unless the stored values can be migrated to match the keys.

Unions that are not a closed domain set (a union of object types, `string | undefined`) stay types.

## Code Style Conventions

### If Statements `[lint, auto-fix]`

**IMPORTANT:** Always use curly braces for if statements, even for single-line returns. The lint script enforces this (`curly`) and auto-fixes missing braces.

**Bad:**
```typescript
if (pressed) return 0.7
if (disabled) return 0.4
```

**Good:**
```typescript
if (pressed) {
  return 0.7
}
if (disabled) {
  return 0.4
}
```

## Database Naming Conventions

**CRITICAL:** We use PostgreSQL. All tables and columns must use **snake_case**.

### Database Field Naming

| Field Type | Suffix | Example |
|------------|--------|---------|
| Timestamp | `_at` | `created_at`, `updated_at`, `deleted_at` |
| Date | `_date` | `birth_date`, `start_date` |
| Foreign Key | `_<table>_<property>` | `advisor_person_id`, `patient_user_id` |
| JSONB (any) | `_json` | `metadata_json`, `settings_json` |
| JSONB (object) | `_object` | `config_object`, `preferences_object` |
| JSONB (array) | `_array` | `tags_array`, `permissions_array` |

### Timestamp Fields

Store timestamps as ISO 8601 strings in PostgreSQL:

```sql
created_at: '2021-12-28T10:44:53.274Z'
updated_at: '2021-12-28T10:44:53.274Z'
deleted_at: '2021-12-28T10:44:53.274Z'
```

### Date Fields

Store dates without time component:

```sql
birth_date: '2021-12-28'
start_date: '2021-12-28'
```

### Foreign Key Fields

Format: `[<field_name>_]<table_name>_<property_name>`

**Examples:**

Table `conversation` references `person.id` twice:
```sql
advisor_person_id  -- references person.id
patient_person_id  -- references person.id
```

Table `conversation` references `person.user_id` (which references `user.id`):
```sql
advisor_user_id  -- references person.user_id → user.id
patient_user_id  -- references person.user_id → user.id
```

## Architectural Enforcement

| Layer      | Must Use           | Reason                                                      |
| ---------- | ------------------ | ----------------------------------------------------------- |
| Service    | Object, Class, or Factory | Object for stateless simple logic, class for state/helpers/`this`-chaining, factory when it builds a value |
| Repository | Class              | Holds its DAL as a protected field and may extend a common repo |
| Use Case   | Plain object       | Stateless; prevents nesting use cases within use cases     |
| DAL        | Class              | Extends or composes a common DAL for its storage framework |
| Entity     | Class              | ORM requirement (TypeORM decorators)                        |
| Handler    | Plain object       | Simple object with handler and schema properties            |
