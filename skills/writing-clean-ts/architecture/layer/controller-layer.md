# Controller Layer

Controllers are the unified entry point for ALL external interactions with your application, handling both frontend and backend interfaces. Part of the **Controller Layer (CL)** in application architecture.

## Framework Implementations

This is an abstract layer pattern. See framework-specific implementations:
- **[Express Controllers](./controller-layer/express.md)** - REST API endpoints (HTTP)
- **[React Router Controllers](./controller-layer/react-router.md)** - Frontend routing (React)
- **[RxJS Bus Controllers](./controller-layer/rxjs-bus.md)** - Internal event handlers
- **[RabbitMQ Controllers](./controller-layer/rmq.md)** - Message queue handlers

## Naming Convention

**See [naming-convention.md](../../style/naming-convention.md) for complete naming standards.**

### Backend Controllers
- **File:** `kebab-case` (e.g., `get-projects-all.ts`, `post-project.ts`, `audit-log.ts`)
- **Export:** `camelCase` singleton object (always)
- **Pattern:** Always singleton objects with interface-specific methods
- **Location:** `src/controller/[interface-type]/[domain]/`

### Frontend Controllers
- **File:** `kebab-case.tsx` (e.g., `list.tsx`, `detail.tsx`, `create.tsx`)
- **Component:** `PascalCase` function component (e.g., `ProjectList`, `ProjectDetail`)
- **Location:** `src/controller/[router-type]/[domain]/`

## Purpose

The Controller Layer provides centralized entry points for all external actions, translating external interface concerns into clean interactions with the business layer.

### Backend Controllers
- **REST API** - HTTP endpoints for web services
- **Event Bus** - Internal event subscriptions for reactive systems
- **Message Queue** - External message handlers for distributed systems
- **Cron Jobs** - Scheduled tasks

### Frontend Controllers
- **Router Integration** - Connection between URL routing and UI components
- **Context Bridge** - Translating global context (auth, theme, i18n) into component props
- **Parameter Extraction** - Converting URL params and query strings to clean props

**Key Concept**: Controllers are the ONLY layer that knows about external interfaces. They translate external parameters (HTTP requests, URL routes, events, messages) into clean calls to the Business Layer.

## Controller Types

### 1. HTTP API Controllers

HTTP endpoint handlers that validate requests and route to business logic.

**Key Responsibilities:**
- Validate request inputs (headers, params, query, body)
- Transform data between HTTP format and business format
- Delegate to Service/Use Case layers
- Return structured HTTP responses

**Framework Implementation**: See [controller-layer-express.md](./controller-layer/express.md) for Express implementation.

**Conceptual Structure:**
```typescript
// Abstract concept - not framework-specific
export const getResourcesAll = {
  handler: async (request) => {
    // 1. Validate request inputs
    const { filter, pagination, sort } = validateInput(request.query)

    // 2. Delegate to business layer
    const { data, pagination: result } = await repository.findMany({
      filter,
      pagination,
      sort,
    })

    // 3. Return structured response
    return { data, meta: { pagination: result } }
  },
  schema: {
    // API documentation schema
  }
}
```

### 2. Frontend Router Controllers

Route handlers that connect the router to UI components.

**Key Responsibilities:**
- Extract URL parameters and query strings
- Bridge global context (auth, theme) to components
- Handle loading states
- Apply screen-level layout

**Framework Implementation**: See [controller-layer-react-router.md](./controller-layer/react-router.md) for React Router implementation.

**Conceptual Structure:**
```typescript
// Abstract concept - not framework-specific
export const ResourceListController = () => {
  // 1. Extract context
  const { userId } = getGlobalContext()

  // 2. Handle loading states
  if (!userId) {
    return <LoadingSpinner />
  }

  // 3. Pass clean props to UI component
  return (
    <Layout>
      <ResourceList userId={userId} />
    </Layout>
  )
}
```

### 3. Event Bus Controllers

Event handlers that subscribe to internal application events.

**Key Responsibilities:**
- Subscribe to internal application events
- Process events asynchronously
- Handle errors without crashing
- Provide lifecycle management (register/unregister)

**Framework Implementation**: See [controller-layer-rxjs-bus.md](./controller-layer/rxjs-bus.md) for RxJS implementation.

**Conceptual Structure:**
```typescript
// Abstract concept - not framework-specific
export const eventBusHandler = {
  register: () => {
    return eventBus.subscribe({}, async (message) => {
      try {
        await processEvent(message)
      } catch (err) {
        logError(err)
      }
    })
  },
}
```

### 4. Message Queue Controllers

Message queue handlers for external messaging systems.

**Key Responsibilities:**
- Consume messages from external queues
- Validate incoming message payloads
- Acknowledge successful processing
- Handle errors with retry logic

**Framework Implementation**: See [controller-layer-rmq.md](./controller-layer/rmq.md) for RabbitMQ implementation.

**Conceptual Structure:**
```typescript
// Abstract concept - not framework-specific
export const messageQueueHandler = {
  register: async (channel) => {
    await channel.consume('queue.name', async (msg) => {
      try {
        const payload = validateMessage(msg)
        await businessService.process(payload)
        channel.ack(msg)
      } catch (err) {
        logError(err)
        channel.nack(msg)
      }
    })
  },
}
```

## Router Integration

Controllers must be registered with their respective routers/registries.

### HTTP API Router

Registers HTTP endpoints with routes and middleware (authentication, permissions).

**Framework Implementation**: See framework-specific files for details.

**Conceptual Structure:**
```typescript
// Abstract concept
export const apiRouter = {
  registerRoutes: () => {
    // Public routes
    register('GET', '/', healthCheckHandler)

    // Protected routes (with authentication)
    register('GET', '/resources', authMiddleware, getResourcesHandler)
    register('POST', '/resources', authMiddleware, createResourceHandler)
    register('GET', '/resources/:id', authMiddleware, getResourceByIdHandler)
  },
}
```

### Frontend Router

Registers route paths with controller components.

**Framework Implementation**: See framework-specific files for details.

**Conceptual Structure:**
```typescript
// Abstract concept
export const frontendRouter = createRouter([
  {
    path: '/resources',
    component: ResourceListController,
  },
  {
    path: '/resources/:id',
    component: ResourceDetailController,
  },
])
```

### Event Bus Router

Registers event handlers with lifecycle management.

**Framework Implementation**: See framework-specific files for details.

**Conceptual Structure:**
```typescript
// Abstract concept
export class EventBusRouter {
  protected subscriptions = []

  register() {
    this.subscriptions.push(handler1.register())
    this.subscriptions.push(handler2.register())
  }

  unregister() {
    this.subscriptions.forEach(sub => sub.unsubscribe())
  }
}
```

## Folder Structure

### Backend Controllers
```
src/
  controller/
    [interface-type]/                  # e.g., express, rmq, rxjs-bus
      [domain]/                        # Domain-based grouping
        handler1.ts                    # Specific handler
        handler2.ts                    # Specific handler
        index.ts                       # Re-exports for router
      router.ts                        # Registration logic
```

**Example (HTTP API):**
```
src/
  controller/
    express/                           # or fastify, koa, etc.
      project/
        get-projects-all.ts
        post-project.ts
        get-project-by-id.ts
      user/
        get-users-all.ts
        post-user.ts
      router.ts
```

### Frontend Controllers
```
src/
  controller/
    [router-type]/                     # e.g., react-router, vue-router
      [domain]/                        # Domain-based grouping
        list.tsx
        detail.tsx
        create.tsx
      router.tsx                       # Route configuration
```

**Example (React Router):**
```
src/
  controller/
    react-router/
      project/
        list.tsx
        detail.tsx
        create.tsx
      user/
        profile.tsx
      router.tsx
```

## Key Characteristics

### HTTP API Controllers
- **Request validation**: Validates all incoming request data
- **Routing and validation only**: No business logic
- **Schema-based validation**: Type-safe input/output validation
- **Error handling**: Structured error responses
- **API documentation**: Schema-driven documentation
- **Type safety**: Full type inference throughout

### Frontend Router Controllers
- **Router adapter**: Extracts data from URL and navigation state
- **Minimal logic**: Only handles routing translation
- **Context bridge**: Connects global context to UI components
- **Loading states**: Shows loading indicators while preparing
- **Error boundaries**: Handles missing required parameters
- **Layout wrapper**: Applies screen-level layout
- **Component composition**: Combines UI components

### Event Bus Controllers
- **Event subscription**: Listen to internal application events
- **Async handling**: Non-blocking event processing
- **Error handling**: Catch and log errors without crashing
- **Lifecycle management**: Register/unregister subscriptions

### Message Queue Controllers
- **External messaging**: Handle messages from external systems
- **Acknowledgment**: Reliable delivery with ack/nack
- **Payload validation**: Validate incoming message structure
- **Error recovery**: Retry logic and dead letter queues

## Architectural Rules

### ✅ DO

#### All Controllers
- Handle routing/interface-specific validation and data transformation
- Delegate all business logic to Service/Use Case layers
- Keep controllers thin and focused on interface concerns
- Organize by domain within interface type folders
- Use singleton objects for handler exports (backend)
- Create `index.ts` for re-exports in each domain folder

#### HTTP API Controllers
- Validate all request inputs with schemas
- Define response schemas for type safety
- Use validation utilities consistently
- Wrap handlers with error handling utilities
- Generate API documentation from schemas
- Return structured response formats
- **Call only ONE business layer function per handler** - if multiple calls are needed, create a new service/use-case that orchestrates them
- Keep handlers light: validate → delegate → format response

#### Frontend Router Controllers
- Extract URL parameters using router utilities
- Extract query parameters from URLs
- Access global context and pass as props to UI components
- Show loading states while waiting for required data
- Display error messages for missing required parameters
- Apply screen-level layout wrappers
- Keep UI components pure by translating router concerns
- Return early for loading/error states
- Connect multiple UI components when needed

#### Event Bus Controllers
- Export `register()` method that returns unsubscribe function
- Handle errors without crashing the application
- Use async/await for event processing
- Keep event handlers focused and simple

#### Message Queue Controllers
- Acknowledge messages after successful processing
- Implement error handling and retry logic
- Validate message payloads
- Use dead letter queues for failed messages

### ❌ DON'T

#### All Controllers
- Include business logic (use Services/Use Cases)
- Access DAL directly (use Repository layer)
- Mix controller types or concerns
- Use classes for backend controllers (use singleton objects)

#### HTTP API Controllers
- Skip validation (all inputs must be validated)
- Use entities or domain models in responses (use models/DTOs)
- Access Repository directly in simple CRUD (use Service for consistency)
- Return unstructured responses
- **Call multiple business layer functions in one handler** - create a service/use-case to orchestrate multiple operations
- Put business logic in handlers (validate → delegate → format only)

#### Frontend Router Controllers
- Include business logic (use services/use-cases instead)
- Make API calls directly (UI components should handle data fetching)
- Access DAL, Repository, or Service layers
- Pass router hooks to child UI components
- Put complex state management in controllers
- Style individual elements (use UI components for styling)
- Make controllers reusable (they're route-specific by design)
- Include complex conditional rendering (move to UI components)

#### Event Bus Controllers
- Block the event loop with synchronous operations
- Throw unhandled errors (catch and log instead)
- Create tight coupling between event publishers and handlers

#### Message Queue Controllers
- Auto-acknowledge messages before processing
- Ignore errors (implement proper error handling)
- Process expensive messages synchronously

## Relationship with Other Layers

### Backend Flow
```
External Interface → Controller → Business Layer (Service/Use Case/Repository) → DAL → Database
                       ↓
                  Validation
                  Transform
                  Route
```

- **HTTP API** → **Controller** → **Service/Use Case** → **Repository** → **DAL** → **Entity**
- **Event Bus** → **Controller** → **Service/Use Case**
- **Message Queue** → **Controller** → **Service/Use Case**

### Frontend Flow
```
Router → Controller → UI Component → Business Layer (if needed)
           ↓
       Parameter Extraction
       Context Bridge
       Layout Wrapper
```

- **Router** → **Controller** → **UI Component**
  - Router provides URL params and query strings
  - Controller translates them into clean props
  - UI Component receives pure data and callbacks

- **Context** → **Controller** → **UI Component**
  - Global context (auth, theme, i18n)
  - Controller extracts needed values
  - UI Component receives as props

### Controller Responsibilities by Type
- **HTTP API**: Request validation, response formatting, API documentation
- **Frontend Router**: URL parameter extraction, context bridging, layout wrapping
- **Event Bus**: Internal event subscription, async event handling
- **Message Queue**: External message handling, acknowledgment, retry logic

This separation ensures a clean architecture where ALL external interface concerns are isolated in the Controller Layer, making the system testable, maintainable, and adaptable to different transport mechanisms.
