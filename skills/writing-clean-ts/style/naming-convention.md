# Naming Conventions

This document defines naming standards for all layers in the TypeScript codebase.

## File Naming

All files and folders use **kebab-case** (dashed-case):

| Type            | Example                                                   |
| --------------- | --------------------------------------------------------- |
| Controller      | `ipc-controller.ts`, `project-controller.ts`              |
| Service         | `secret-service.ts` (business service layer ONLY)         |
| Repository      | `project-repo.ts`                                         |
| DAL             | `project-dal.ts`                                          |
| Entity          | `project-entity.ts`                                       |
| Use Case        | `git-use-case.ts`                                         |
| Handler         | `get-projects-all.ts`, `post-project.ts` (Express routes) |
| Util            | `lang-util.ts`, `object-util.ts`, `path-util.ts`         |
| Lib             | `tray.ts`, `piper-engine.ts` (no suffix)                  |
| Types/Models    | `project-model.ts`, `feature-types.ts`                    |
| Folders         | `some-folder/`, `service/`                                |

### Layer File Suffixes

The file suffix tells a reader which layer a file belongs to before they open it. The `-service` suffix belongs **exclusively** to the business service layer (`src/business/service/`) — anywhere else it is misleading, because utils, DALs, controllers, and lib modules are not business services. Each layer uses its own suffix:

| Layer               | Folder                    | Suffix        | Example File        | Example Export                                |
| ------------------- | ------------------------- | ------------- | ------------------- | --------------------------------------------- |
| Controller module   | `src/controller/`         | `-controller` | `ipc-controller.ts` | `ipcController` (camelCase singleton)         |
| Service             | `src/business/service/`   | `-service`    | `tts-service.ts`    | `TtsService` class / `ttsService` singleton   |
| Repository          | `src/business/repo/`      | `-repo`       | `project-repo.ts`   | `ProjectRepo` class                           |
| Use Case            | `src/business/use-case/`  | `-use-case`   | `git-use-case.ts`   | `gitUseCase` singleton                        |
| DAL                 | `src/dal/`                | `-dal`        | `history-dal.ts`    | `HistoryDal` class                            |
| Entity              | `src/dal/*/entity/`       | `-entity`     | `project-entity.ts` | `ProjectEntity` class                         |
| Util                | `src/util/`               | `-util`       | `lang-util.ts`      | `langUtil` (camelCase singleton)              |
| Lib                 | `src/lib/`                | none          | `tray.ts`           | `Tray` class / `tray` singleton               |

A `*-service.ts` file outside `src/business/service/` is a naming violation — rename it to its layer's suffix (or drop the suffix entirely, for lib).

#### Util Layer Exceptions

Four well-known utility files do not take the `-util` suffix because their names are already unambiguous:

- `config.ts`
- `constants.ts`
- `logger.ts`
- `error.ts`

Every other util file ends in `-util` (`lang-util.ts`, `object-util.ts`, `path-util.ts`, `date-util.ts`) and exports a camelCase singleton named `<name>Util` (`langUtil`, `objectUtil`, `pathUtil`).

#### Lib Layer — No Suffix, Never `-service`

Lib code wraps infrastructure and external systems (Electron tray and global shortcuts, external process engines, DB or message-broker connections). It contains no business logic, so it is not a service — neither in the filename nor in the export name:

- ❌ `src/lib/tray-service.ts` exporting `TrayService` → ✅ `src/lib/tray.ts` exporting `Tray`
- ❌ `src/lib/piper-engine-service.ts` → ✅ `src/lib/piper-engine.ts`

#### Express Endpoint Files

Files under `src/controller/express/` keep their endpoint-based handler names (`get-projects-all.ts`, `post-project.ts`) — see [rest-api-url-conventions.md](../architecture/rest-api-url-conventions.md). The `-controller` suffix applies to controller modules that implement a whole interface or domain in one file (IPC, event bus, message queue, cron), e.g. `ipc-controller.ts` exporting `ipcController`.

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

**IMPORTANT:** See [class-vs-object.md](../architecture/class-vs-object.md) for the complete decision guide on when to use classes vs singleton objects.

The codebase uses two patterns:

- **Classes**: PascalCase exports, instantiated with `new ClassName()`
- **Singleton Objects**: camelCase exports, used directly without instantiation

**Quick Reference:**

| When to Use | Pattern | Example |
|-------------|---------|---------|
| Methods call each other via `this` | Class | `export class SecretService` |
| Methods are independent | Singleton | `export const calculationService` |
| Repository, DAL, Entity (mandatory) | Class | `export class ProjectRepo` |
| Use Case, Handler (mandatory) | Singleton | `export const authUseCase` |

For detailed decision-making guidance, examples, and common mistakes, see [class-vs-object.md](../architecture/class-vs-object.md).

## Naming Convention Summary Table

| Layer                     | Pattern   | Naming              | Example Export                    | Usage Example                    |
| ------------------------- | --------- | ------------------- | --------------------------------- | -------------------------------- |
| **Service** (with `this`) | Class     | PascalCase          | `export class SecretService`      | `new SecretService().decrypt()`  |
| **Service** (independent) | Singleton | camelCase           | `export const calculationService` | `calculationService.calculate()` |
| **Util**                  | Singleton | camelCase           | `export const langUtil`           | `langUtil.detectLang()`          |
| **Lib**                   | Class or Singleton | PascalCase / camelCase | `export class Tray`       | `new Tray()`                     |
| **Repository**            | Class     | PascalCase          | `export class ProjectRepo`        | `new ProjectRepo().findMany()`   |
| **Use Case**              | Singleton | camelCase           | `export const gitUseCase`         | `gitUseCase.getCommits()`        |
| **DAL**                   | Class     | PascalCase          | `export class ProjectDal`         | `new ProjectDal()`               |
| **Entity**                | Class     | PascalCase          | `export class ProjectEntity`      | `new ProjectEntity()`            |
| **Handler**               | Singleton | camelCase           | `export const getProjectsAll`     | `getProjectsAll.handler`         |
| **Interface**             | Interface | I-prefix PascalCase | `export interface IProjectDal`    | `dal: IProjectDal`               |


## Method Naming

All methods use **camelCase** `[lint]`. Member casing and underscore prefixes (`protected _`, private `__`) are enforced by the ESLint `@typescript-eslint/naming-convention` rule (see [../linting/eslint-rules.md](../linting/eslint-rules.md)); the naming semantics below are not lint-checkable:

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

### Standard Method Examples

```typescript
// Services
async decryptSecret(secret: string): string
async validateAndProcessOrder(order: Order): Promise<void>
async createUserAccount(data: UserCreate): Promise<User>
async editUserEmail(userId: string, email: string): Promise<void>

// Repositories
async findOneById(id: string): Promise<Model>
async findMany(options: FilterOptions): Promise<Model[]>
async create(data: ModelCreate): Promise<Model>
async update(id: string, data: Partial<Model>): Promise<Model>

// Use Cases
async getCommitsByOwnProjectId(params: { projectId: string }): Promise<Commit[]>
async createProject(data: ProjectCreate): Promise<Project>
async editProjectSettings(projectId: string, settings: Settings): Promise<void>
async removeProjectMember(projectId: string, userId: string): Promise<void>
```

### Use Case Function Names

**Use Cases are the only layer where shorter function names are allowed.**

A use-case name is short *because* the operation is complex: too complex to capture in one name without making it unwieldy. The detail is carried by the **body**. Each step is a call to a service/repo/component whose own name describes that step, so the reader understands the whole operation by reading those step names.

Use case functions should be:
- Self-documenting through the body (calls to other service functions with longer, descriptive names)
- **Created only when they orchestrate two or more steps.** A use-case that calls a single service function is a useless wrapper: the controller can call that service directly, so there is nothing to orchestrate. See [use-case-layer.md](../architecture/layer/use-case-layer.md)

**Example:**
```typescript
// authorization-use-case.ts

async authorize(params: { email: string; password: string }): Promise<AuthResult> {
  const user = await userService.findUserByEmailAndValidatePassword(params)
  const tokens = await tokenService.generateAccessAndRefreshTokens(user.id)
  await sessionService.createUserSessionRecord(user.id, tokens.refreshToken)
  return tokens
}
```

The single word `authorize` is acceptable only because the three steps below it make the operation unambiguous. A one-line body that forwards a single call would not justify the name, or the use-case, at all.

## Timestamp Field Naming

**CRITICAL:** All fields that hold Unix timestamps (in milliseconds) must use the suffix `At`.

**IMPORTANT:** See [timestamp-handling.md](timestamp-handling.md) for complete guidance on timestamp implementation, TypeORM setup, and best practices.

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
export interface ProjectModel {
  id: string
  name: string
  createdAt: number      // Unix timestamp in milliseconds
  updatedAt: number      // Unix timestamp in milliseconds
  deletedAt?: number     // Unix timestamp in milliseconds (optional)
}

// Distinguishing between creation and event time
export interface GpsLocationModel {
  id: string
  createdAt: number    // When record was saved to database
  lon: number
  lat: number
  at: number           // When GPS location was actually recorded
}
```

For complete details on timestamp handling, TypeORM transformer setup, and usage patterns, see [timestamp-handling.md](timestamp-handling.md).

## Boolean Naming Conventions

Boolean variables, properties, and methods that return boolean values must use descriptive prefixes that clearly indicate they represent a true/false state.

### Standard Prefixes

| Prefix | Purpose | Example |
|--------|---------|---------|
| `is*` | State or condition check | `isActive`, `isValid`, `isAuthenticated` |
| `has*` | Possession or containment | `hasPermission`, `hasChildren`, `hasError` |
| `can*` | Ability or permission | `canEdit`, `canDelete`, `canAccess` |
| `should*` | Recommendation or condition | `shouldRefresh`, `shouldRender`, `shouldShow` |
| `will*` | Future state prediction | `willUpdate`, `willExpire` |
| `did*` | Completed action check | `didLoad`, `didChange` |

### Variables and Properties

```typescript
// ✓ Good - clear boolean intent
let isVisible: boolean = true
const hasPermission: boolean = false
user.isActive = true
project.canBeDeleted = false

// ✗ Bad - unclear boolean intent
let visible: boolean = true           // What kind of visible?
const permission: boolean = false     // Has permission? Or is permission?
user.active = true                    // Is active? Or the active item?
```

### Methods Returning Boolean

```typescript
// ✓ Good
function isValidEmail(email: string): boolean
function hasRequiredPermissions(user: User): boolean
function canUserAccessResource(user: User, resource: Resource): boolean
async function isValidToken(token: string): Promise<boolean>

// ✗ Bad
function validEmail(email: string): boolean       // Missing is prefix
function checkPermission(user: User): boolean     // Use has/can instead
function userAccess(user: User): boolean          // Unclear return type
async function engineInstalled(): Promise<boolean> // Promise<boolean> needs the prefix too
```

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

  @Column({ default: true })
  canReceiveNotifications!: boolean
}
```

### Database Column Naming

For database columns, use snake_case with the same prefix:

| TypeScript Property | Database Column |
|---------------------|-----------------|
| `isActive` | `is_active` |
| `hasPermission` | `has_permission` |
| `canEdit` | `can_edit` |
| `shouldRetry` | `should_retry` |

## Type Naming

Types use **PascalCase**:

```typescript
type ResData = z.infer<typeof resDataSchema>
type ProjectModelCreate = { name: string; sourceUrl: string }
interface IProjectDal extends ICommonDal<...> {}
```

## Enum Naming

### Rule 1: Identical Keys and Values (Default)

**We must use the same name for KEY and VALUE.**

```typescript
enum SomeThing {
  VALUE_ONE   = "VALUE_ONE",
  VALUE_TWO   = "VALUE_TWO",
  VALUE_THREE = "VALUE_THREE",
}
```

### Rule 2: Different Keys and Values (MAPPER suffix)

**If we cannot use the same value for the key and value, we must add a `MAPPER` suffix to the enum name.**

```typescript
enum SomeThingMapper {
  VALUE_ONE   = "value-one",
  VALUE_TWO   = "value-two",
  VALUE_THREE = "value-three",
}
```

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
| Service    | Class OR Singleton | Use class when methods call each other, singleton otherwise |
| Repository | Class              | Requires constructor for DAL injection                      |
| Use Case   | Singleton          | Prevents nesting use cases within use cases                 |
| DAL        | Class              | Requires constructor for entity and data source setup       |
| Entity     | Class              | ORM requirement (TypeORM decorators)                        |
| Handler    | Singleton          | Simple object with handler and schema properties            |
