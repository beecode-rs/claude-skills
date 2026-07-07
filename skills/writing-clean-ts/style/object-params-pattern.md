# Object Params Pattern

## Overview

Pass parameters as object properties instead of multiple individual parameters. This improves code readability, maintainability, and makes function calls self-documenting.

## Quick Decision Tree

```
Is this a Business Logic Layer?
(Service/Repository/Use Case/Component/DAL/Controller)
  ├─ Yes → ALWAYS use object params (even for 1 parameter)
  └─ No (Utility Layer)
      ↓
  Single parameter?
      ├─ Yes → SKIP object params
      └─ No (2+ parameters)
          ↓
      Does function name clearly imply parameter names?
      (e.g., truncate(text, maxLength), encrypt(data, key))
          ├─ Yes → SKIP object params
          └─ No (e.g., format(), process(), handle())
              ↓
          → USE object params
```

## Rules by Layer

### ✅ ALWAYS Use Object Params (Business Logic Layers)

These layers MUST use object params for **ALL functions** (including single parameter):

- **Service Layer** - Business logic methods
- **Repository Layer** - Data access methods
- **Use Case Layer** - Orchestration functions
- **Component Layer** - Complex domain logic
- **DAL Layer** - Database access methods
- **Controller Layer** - Request handlers (except framework signatures)

**Why:**
- Business logic changes frequently - today's single parameter often becomes multiple parameters
- Consistency across the business layer makes code more predictable
- Easier to extend without breaking changes
- Self-documenting at call sites

### 🤔 Conditional Use (Utility Layer)

**Use object params when:**
- Function has 2+ parameters AND parameter names are NOT obvious from function name
- Parameters are of similar types (multiple strings, multiple numbers)
- Parameters might need to grow or change

**Skip object params when:**
- Function name clearly implies parameter names (e.g., `truncate(text, maxLength)`)
- Function is a simple transformation with 1-2 parameters
- Similar to standard library functions (e.g., `map`, `filter`)
- Framework callbacks (onClick, onChange, etc.)

### ❌ Never Use Object Params

- **Utility Layer** - Single parameter functions
- **Framework requirements** - When framework expects specific signatures (e.g., Express middleware, React callbacks)

## Examples by Layer

| Layer | Function Example | Parameters | Use Object Params? | Reason |
|-------|------------------|------------|-------------------|---------|
| **Service** | `invoiceService.calculateTotal(items)` | 1 | ✅ YES | Business logic - ALWAYS |
| **Service** | `invoiceService.create(ownerId, amount, dueDate)` | 3 | ✅ YES | Business logic - ALWAYS |
| **Repository** | `projectRepo.findOneById(id)` | 1 | ✅ YES | Business logic - ALWAYS |
| **Repository** | `projectRepo.findByFilters(ownerId, status, date)` | 3 | ✅ YES | Business logic - ALWAYS |
| **Use Case** | `orderUseCase.processOrder(orderId, userId, items)` | 3 | ✅ YES | Business logic - ALWAYS |
| **Component** | `invoiceStatus.canTransition(from, to, user)` | 3 | ✅ YES | Business logic - ALWAYS |
| **Controller** | `getProjectsAll.handler(req, res, next)` | 3 | ❌ NO | Framework signature |
| **Util** | `stringUtil.capitalize(str)` | 1 | ❌ NO | Utility - single param |
| **Util** | `stringUtil.truncate(text, maxLength)` | 2 | ❌ NO | Name implies params |
| **Util** | `stringUtil.format(text, prefix, suffix, uppercase)` | 4 | ✅ YES | Not obvious from name |
| **Util** | `cryptoUtil.encrypt(data, key)` | 2 | ❌ NO | Name implies params |

## Pattern

### ❌ Multiple Parameters (Avoid)

```typescript
function setupDatabase(host: string, port: number, databaseName: string) {
  // some logic
}

// Usage - unclear what each value represents
setupDatabase("localhost", 4567, "core")
```

**Problems:**
- Parameter order must be memorized
- Easy to mix up similar types (strings, numbers)
- Adding parameters breaks existing calls
- Not self-documenting at call site

### ✅ Params Object (Preferred)

```typescript
function setupDatabase(params: {
  host: string
  port: number
  databaseName: string
}) {
  const { host, port, databaseName } = params
  // some logic
}

// Usage - self-documenting and order-independent
setupDatabase({
  host: "localhost",
  port: 4567,
  databaseName: "core"
})
```

**Benefits:**
- Self-documenting at call site
- Order-independent
- Easy to add optional parameters
- TypeScript autocomplete shows parameter names
- Similar to React props pattern

## Examples

### Service Layer

```typescript
// ❌ Avoid - even single parameter in business logic
export const invoiceService = {
  calculateTotal(items: InvoiceItem[]) {
    // implementation
  },

  create(ownerId: string, amount: number, dueDate: Date, description: string) {
    // implementation
  }
}

// ✅ Prefer - ALWAYS use object params in business logic
export const invoiceService = {
  calculateTotal(params: { items: InvoiceItem[] }) {
    const { items } = params
    // implementation
  },

  create(params: {
    ownerId: string
    amount: number
    dueDate: Date
    description: string
  }) {
    const { ownerId, amount, dueDate, description } = params
    // implementation
  }
}

// Usage - consistent pattern across all business logic
invoiceService.calculateTotal({ items })

invoiceService.create({
  ownerId: '123',
  amount: 100.50,
  dueDate: new Date(),
  description: 'Monthly subscription'
})
```

### Repository Layer

```typescript
// ✅ Good - ALWAYS use object params, even for single parameter
export class ProjectRepo extends CommonRepo<ProjectEntity, ProjectModel> {
  // Single parameter - still use object params
  async findOneById(params: { id: string }): Promise<ProjectModel | null> {
    const { id } = params
    // implementation
  }

  // Multiple parameters - use object params
  async findByFilters(params: {
    ownerId: string
    status?: ProjectStatus
    startDate?: Date
    endDate?: Date
  }): Promise<ProjectModel[]> {
    const { ownerId, status, startDate, endDate } = params
    // implementation
  }
}

// Usage - consistent pattern
const project = await new ProjectRepo().findOneById({ id: '123' })

const projects = await new ProjectRepo().findByFilters({
  ownerId: '123',
  status: 'active',
  startDate: new Date('2024-01-01')
})
```

### Use Case Layer

```typescript
// ✅ Good - orchestration with multiple dependencies
export const projectUseCase = {
  async createWithTeam(params: {
    ownerId: string
    projectName: string
    teamMembers: string[]
    budget?: number
  }): Promise<ProjectModel> {
    const { ownerId, projectName, teamMembers, budget } = params
    // orchestration logic
  }
}

// Usage
const project = await projectUseCase.createWithTeam({
  ownerId: '123',
  projectName: 'New Website',
  teamMembers: ['user1', 'user2'],
  budget: 50000
})
```

### Utility Layer Examples

```typescript
export const stringUtil = {
  // ✅ SKIP object params - function name implies parameter names
  convertToCamelCase(str: string): string {
    return str.replace(/-([a-z])/g, (g) => g[1].toUpperCase())
  },

  // ✅ SKIP object params - "truncate(text, maxLength)" is obvious
  truncate(text: string, maxLength: number): string {
    return text.length > maxLength ? text.slice(0, maxLength) + '...' : text
  },

  // ✅ SKIP object params - single parameter
  capitalize(str: string): string {
    return str.charAt(0).toUpperCase() + str.slice(1)
  },

  // ❌ USE object params - parameters not obvious from name
  format(params: {
    text: string
    prefix: string
    suffix: string
    uppercase: boolean
  }): string {
    const { text, prefix, suffix, uppercase } = params
    let result = text
    if (uppercase) result = result.toUpperCase()
    return `${prefix}${result}${suffix}`
  }
}

// Usage
const camelCase = stringUtil.convertToCamelCase('my-string')
const truncated = stringUtil.truncate('long text', 10)
const formatted = stringUtil.format({
  text: 'hello',
  prefix: '[',
  suffix: ']',
  uppercase: true
})
```

## Parameter Object Patterns

### Inline Type Definition

```typescript
// ✅ Good for simple, single-use params
export const userService = {
  register(params: {
    email: string
    password: string
    name: string
  }) {
    // implementation
  }
}
```

### Named Interface (Local)

```typescript
// ✅ Good for complex params or reuse within same file
interface ICreateInvoiceParams {
  ownerId: string
  items: IInvoiceItem[]
  dueDate: Date
  notes?: string
}

export const invoiceService = {
  create(params: ICreateInvoiceParams) {
    const { ownerId, items, dueDate, notes } = params
    // implementation
  }
}
```

### Shared Interface (Separate File)

```typescript
// ✅ Good when shared across multiple files
// In src/business/model/invoice-params.ts
export interface ICreateInvoiceParams {
  ownerId: string
  items: IInvoiceItem[]
  dueDate: Date
  notes?: string
}

// In src/business/service/invoice-service.ts
import type { ICreateInvoiceParams } from '#src/business/model/invoice-params'

export const invoiceService = {
  create(params: ICreateInvoiceParams) {
    // implementation
  }
}
```

## Optional Parameters

Object params make optional parameters clearer:

```typescript
// ✅ Optional properties are self-documenting
export const searchService = {
  search(params: {
    query: string
    filters?: {
      category?: string
      minPrice?: number
      maxPrice?: number
    }
    pagination?: {
      page: number
      limit: number
    }
  }) {
    const { query, filters, pagination } = params
    // implementation with defaults
    const page = pagination?.page ?? 1
    const limit = pagination?.limit ?? 10
  }
}

// Usage - only provide what you need
searchService.search({
  query: 'laptop'
})

searchService.search({
  query: 'laptop',
  filters: { minPrice: 500 },
  pagination: { page: 2, limit: 20 }
})
```

## React Props Analogy

This pattern mirrors React component props:

```typescript
// React Component
interface ProjectListProps {
  ownerId: string
  status?: ProjectStatus
  onSelect?: (project: ProjectModel) => void
}

export function ProjectList(props: ProjectListProps) {
  const { ownerId, status, onSelect } = props
  // component logic
}

// Service Function (same pattern)
interface IFindProjectsParams {
  ownerId: string
  status?: ProjectStatus
  includeArchived?: boolean
}

export const projectService = {
  find(params: IFindProjectsParams) {
    const { ownerId, status, includeArchived } = params
    // service logic
  }
}
```

## Migration Strategy

When refactoring existing code:

1. **Identify functions with 2+ parameters**
2. **Create params object type**
3. **Update function signature**
4. **Destructure params at function start**
5. **Update all call sites**

```typescript
// Before
function createUser(email: string, name: string, role: string) {
  // logic
}

// After
function createUser(params: {
  email: string
  name: string
  role: string
}) {
  const { email, name, role } = params
  // same logic
}
```

## Summary

### Mandatory Rules
- **Business Logic Layers** (Service/Repository/Use Case/Component/DAL/Controller):
  - ✅ ALWAYS use object params for ALL functions (even single parameter)
  - ❌ EXCEPTION: Framework signatures (e.g., Express middleware `(req, res, next)`)

- **Utility Layer**:
  - ✅ Use object params when parameters NOT obvious from function name
  - ❌ Skip for single parameters
  - ❌ Skip when function name implies parameters (e.g., `truncate(text, maxLength)`)

### Why Business Logic ALWAYS Uses Object Params
1. **Future-proof**: Single parameter today often becomes multiple parameters tomorrow
2. **Consistency**: All business logic follows same pattern - easier to read and maintain
3. **Self-documenting**: Clear what data is being passed at call sites
4. **Easy extension**: Adding parameters doesn't break existing code structure

### Benefits
- **Self-documenting** - parameter names visible at call site
- **Flexible** - easy to add optional parameters without breaking changes
- **Type-safe** - TypeScript enforces parameter names and types
- **Consistent** - matches React props pattern
- **Maintainable** - refactoring business logic is safer
- **Predictable** - same pattern across entire business layer
