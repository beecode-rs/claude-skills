# RxJS Bus Controller Layer

RxJS Bus controllers handle internal application events through a reactive event bus system. Part of the **Controller Layer (CL)** for event-driven interfaces.

**See [controller-layer.md](../controller-layer.md) for the abstract controller pattern that applies to all interface types.**

## Framework

This implementation uses:
- **RxJS** - Reactive Extensions for JavaScript
- **Event Bus Service** - Internal event subscription system
- **Singleton Pattern** - For controller registration

## Naming Convention

**See [naming-convention.md](../../../style/naming-convention.md) for complete naming standards.**

- **File:** `kebab-case` (e.g., `audit-log.ts`, `notification.ts`)
- **Export:** `camelCase` singleton object (always)
- **Pattern:** Always singleton objects with `register()` method
- **Location:** `src/controller/rxjs-bus/[domain]/`

## Purpose

RxJS Bus controllers provide event-driven handlers that:
- Subscribe to internal application events
- Process events asynchronously without blocking
- Handle errors gracefully without crashing the application
- Provide lifecycle management (register/unregister)
- Decouple event publishers from event handlers

## Structure

### Basic Event Handler

```typescript
// src/controller/rxjs-bus/audit-log.ts
import { modelEventBusService } from '@app/node-common/business/service/model-event-bus'
import { rmqService } from '@app/node-common/lib/rmq/service'

import { rmqInstanceSingleton } from '#src/lib/rmq/instance'
import { logger } from '#src/util/logger'

export const rxjsBusAuditLog = {
  register: (): { unsubscribe: () => void } => {
    return modelEventBusService().subscribe({}, async (message) => {
      const { model, action, entityName } = message

      rmqInstanceSingleton()
        .publish({
          payload: { entityName, model },
          routingKey: rmqService.composeRoutingKey({
            action: 'AUDIT_LOG',
            option1: action,
            option2: entityName,
          }),
        })
        .catch((err: unknown) => {
          logger().error(err)
        })
    })
  },
}
```

### Filtered Event Handler

```typescript
// src/controller/rxjs-bus/project-created-notification.ts
import { modelEventBusService } from '@app/node-common/business/service/model-event-bus'
import { logger } from '#src/util/logger'
import { notificationService } from '#src/business/service/notification-service'

export const rxjsBusProjectCreatedNotification = {
  register: (): { unsubscribe: () => void } => {
    // Only subscribe to PROJECT.CREATED events
    return modelEventBusService().subscribe(
      {
        entityName: 'PROJECT',
        action: 'CREATED'
      },
      async (message) => {
        try {
          const { model } = message
          await notificationService.sendProjectCreatedEmail({ projectId: model.id })
          logger().info(`Notification sent for project ${model.id}`)
        } catch (err: unknown) {
          logger().error('Failed to send notification', err)
        }
      }
    )
  },
}
```

### Multiple Event Types Handler

```typescript
// src/controller/rxjs-bus/cache-invalidation.ts
import { modelEventBusService } from '@app/node-common/business/service/model-event-bus'
import { cacheService } from '#src/business/service/cache-service'
import { logger } from '#src/util/logger'

export const rxjsBusCacheInvalidation = {
  register: (): { unsubscribe: () => void } => {
    return modelEventBusService().subscribe(
      {
        action: ['UPDATED', 'DELETED'] // Listen to multiple actions
      },
      async (message) => {
        try {
          const { entityName, model } = message
          await cacheService.invalidate({ entityName, id: model.id })
          logger().info(`Cache invalidated for ${entityName}:${model.id}`)
        } catch (err: unknown) {
          logger().error('Cache invalidation failed', err)
        }
      }
    )
  },
}
```

## Router Integration

```typescript
// src/controller/rxjs-bus/router.ts
import { singletonPattern } from '@beecode/msh-util/singleton/pattern'

import { rxjsBusAuditLog } from './audit-log'
import { rxjsBusProjectCreatedNotification } from './project-created-notification'
import { rxjsBusCacheInvalidation } from './cache-invalidation'

export class RxjsBusRouter {
  protected readonly _subscriptions: { unsubscribe: () => void }[] = []

  register(): void {
    this._subscriptions.push(rxjsBusAuditLog.register())
    this._subscriptions.push(rxjsBusProjectCreatedNotification.register())
    this._subscriptions.push(rxjsBusCacheInvalidation.register())
  }

  unregister(): void {
    this._subscriptions.forEach((subscription) => {
      subscription.unsubscribe()
    })
    this._subscriptions.length = 0
  }
}

export const rxjsBusRouterSingleton = singletonPattern(() => {
  return new RxjsBusRouter()
})
```

## Folder Structure

```
src/
  controller/
    rxjs-bus/                          # Event bus handlers
      audit-log.ts                     # Audit logging handler
      project-created-notification.ts  # Project creation notifications
      cache-invalidation.ts            # Cache invalidation on updates
      analytics-tracking.ts            # Analytics event tracking
      router.ts                        # Registration/deregistration
```

## Key Characteristics

- **Event subscription**: Listen to internal application events
- **Async handling**: Non-blocking event processing
- **Error handling**: Catch and log errors without crashing
- **Lifecycle management**: Register/unregister subscriptions
- **Singleton objects**: Always export as singleton objects (never classes)
- **Filtered subscriptions**: Subscribe to specific event types/entities
- **Decoupled**: Publishers don't know about handlers

## Event Message Structure

```typescript
interface EventMessage {
  entityName: string    // e.g., 'PROJECT', 'USER'
  action: string        // e.g., 'CREATED', 'UPDATED', 'DELETED'
  model: any           // The entity model
  metadata?: object    // Optional additional data
}
```

## Subscription Filters

### Subscribe to All Events

```typescript
modelEventBusService().subscribe({}, async (message) => {
  // Handle all events
})
```

### Subscribe to Specific Entity

```typescript
modelEventBusService().subscribe(
  { entityName: 'PROJECT' },
  async (message) => {
    // Handle all PROJECT events
  }
)
```

### Subscribe to Specific Action

```typescript
modelEventBusService().subscribe(
  { action: 'CREATED' },
  async (message) => {
    // Handle all CREATED events
  }
)
```

### Subscribe to Specific Entity + Action

```typescript
modelEventBusService().subscribe(
  {
    entityName: 'PROJECT',
    action: 'DELETED'
  },
  async (message) => {
    // Handle PROJECT.DELETED events only
  }
)
```

## Error Handling Patterns

### Graceful Error Handling

```typescript
export const rxjsBusHandler = {
  register: (): { unsubscribe: () => void } => {
    return modelEventBusService().subscribe({}, async (message) => {
      try {
        await someAsyncOperation(message)
      } catch (err: unknown) {
        // Log error but don't throw - keeps event bus running
        logger().error('Event handler failed', { message, err })
      }
    })
  },
}
```

### Retry Logic

```typescript
export const rxjsBusHandlerWithRetry = {
  register: (): { unsubscribe: () => void } => {
    return modelEventBusService().subscribe({}, async (message) => {
      let retries = 3
      while (retries > 0) {
        try {
          await someAsyncOperation(message)
          break // Success, exit loop
        } catch (err: unknown) {
          retries--
          if (retries === 0) {
            logger().error('Event handler failed after retries', { message, err })
          } else {
            await new Promise(resolve => setTimeout(resolve, 1000))
          }
        }
      }
    })
  },
}
```

## Architectural Rules

### ✅ DO

- Export `register()` method that returns unsubscribe function
- Handle errors without crashing the application
- Use async/await for event processing
- Keep event handlers focused and simple
- Log errors for debugging
- Use filters to subscribe to specific events
- Store subscriptions for cleanup
- Unsubscribe on application shutdown
- Use singleton objects for exports

### ❌ DON'T

- Block the event loop with synchronous operations
- Throw unhandled errors (catch and log instead)
- Create tight coupling between event publishers and handlers
- Use classes for RxJS Bus controllers (always use singleton objects)
- Skip error handling
- Forget to unsubscribe on shutdown
- Process expensive operations synchronously
- Share state between event handlers

## Lifecycle Management

### Application Startup

```typescript
// app-boot/startup.ts
import { rxjsBusRouterSingleton } from '#src/controller/rxjs-bus/router'

export const appStartup = {
  async start() {
    // ... other startup tasks

    // Register all event handlers
    rxjsBusRouterSingleton().register()

    logger().info('RxJS Bus handlers registered')
  }
}
```

### Application Shutdown

```typescript
// app-boot/shutdown.ts
import { rxjsBusRouterSingleton } from '#src/controller/rxjs-bus/router'

export const appShutdown = {
  async stop() {
    // Unsubscribe all event handlers
    rxjsBusRouterSingleton().unregister()

    logger().info('RxJS Bus handlers unregistered')
  }
}
```

## Testing Event Handlers

For testing patterns and examples, use the **test-typescript** skill.

## Relationship with Other Layers

```
Event Publisher → Event Bus → RxJS Bus Controller → Service/Use Case
                                      ↓
                                 Async Processing
                                 Error Handling
                                 Side Effects
```

RxJS Bus controllers enable reactive, event-driven architecture by decoupling event producers from consumers, ensuring the application can respond to internal events without tight coupling.
