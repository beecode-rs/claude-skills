# App Boot Layer (ABL)

The App Boot Layer manages application initialization and shutdown, ensuring proper setup of resources and graceful cleanup when the application terminates.

## Implementation Package

This pattern is implemented using the **[msh-app-boot](https://github.com/beecode-rs/msh-app-boot)** package, which provides a structured approach to managing application lifecycle with support for sequential and parallel task execution.

## Purpose

The ABL handles the complete lifecycle of your application:

- **Startup**: Initialize connections, register services, and activate interfaces before the application serves traffic
- **Shutdown**: Gracefully deactivate listeners, complete ongoing processes, and cleanup resources

## Core Principles

**Asynchronous Process Execution**: The ABL supports both sequential and parallel execution of initialization/shutdown tasks.

**Flexible Initialization Modes**: Define different startup configurations based on the execution context (e.g., skip RestAPI during unit tests, bypass database connections when not needed).

**Graceful Shutdown**: Never forcefully terminate the application. Always allow ongoing processes to complete and cleanup resources properly.

## Startup Sequence

The typical startup sequence follows a dependency-based order:

1. **Foundation Layer** (Sequential)
   - Establish database connections
   - Run database migrations
   - Register internal EventBus (e.g., RxJS-based)

   These must complete before external interfaces are activated because they provide the foundation for the application.

2. **Interface Layer** (Parallel)
   - Activate RestAPI endpoints
   - Start MessageQueue listeners
   - Enable CronJob schedulers

   These can be initialized simultaneously as they depend only on the foundation layer.

### Example Startup

```typescript
// app-boot/startup.ts
export const appStartup = {
  async start() {
    // Sequential: Foundation must be ready first
    await databaseConnection.connect()
    await databaseMigration.run()
    await internalEventBus.register()

    // Parallel: Interfaces can start simultaneously
    await Promise.all([
      restApiInterface.activate(),
      messageQueueInterface.activate(),
      cronJobInterface.activate(),
    ])
  }
}
```

## Shutdown Sequence

The shutdown sequence is critical for preventing data loss and ensuring process completion:

1. **Deactivate Listeners** (Parallel)
   - Stop accepting new RestAPI requests
   - Stop consuming from MessageQueues
   - Stop triggering CronJobs

   This prevents new work from entering the system.

2. **Wait for Completion** (Sequential)
   - Allow in-flight HTTP requests to complete
   - Let queued messages finish processing
   - Wait for running cron jobs to finish

   This ensures no work is lost.

3. **Cleanup Resources** (Sequential)
   - Close database connections
   - Flush logs and metrics
   - Release external resources

### Example Shutdown

```typescript
// app-boot/shutdown.ts
export const appShutdown = {
  async stop() {
    try {
      // Parallel: Stop all listeners immediately
      await Promise.all([
        restApiInterface.deactivate(),
        messageQueueInterface.deactivate(),
        cronJobInterface.deactivate(),
      ])

      // Sequential: Wait for processes to complete
      await activeProcesses.waitForCompletion()

      // Sequential: Cleanup resources
      await databaseConnection.close()
      await logger.flush()
    } catch (error) {
      // CRITICAL: Always log shutdown errors
      logger.error('Shutdown error:', error)
      throw error
    }
  }
}
```

## Why Graceful Shutdown Matters

**Data Integrity**: Forceful termination can result in:
- Lost database transactions
- Incomplete message processing
- Corrupted file writes
- Orphaned background jobs

**Traffic Redirection Limitations**: Cloud platforms (AWS, Azure, Google Cloud) may redirect HTTP traffic during deployments, but they don't handle:
- Active MessageQueue consumers
- Running CronJobs
- WebSocket connections
- Background workers

**Best Practice**: Always deactivate listeners first, then let the application finish its current work before closing connections.

## File Organization

```
src/app-boot/
├── startup.ts        # Application initialization logic
├── shutdown.ts       # Application cleanup logic
├── interface/        # External interface managers
│   ├── rest-api-interface.ts
│   ├── message-queue-interface.ts
│   └── cron-job-interface.ts
└── index.ts         # Main boot orchestrator
```

## Implementation Pattern

### Using msh-app-boot Package

The recommended implementation uses the `msh-app-boot` package to manage the application lifecycle:

```typescript
// app-boot/index.ts
import { AppBoot } from '@beecode/msh-app-boot'

export const appBoot = new AppBoot({
  startStrategy: [
    // Sequential: Foundation layer
    [
      databaseConnection.connect,
      databaseMigration.run,
      internalEventBus.register,
    ],
    // Parallel: Interface layer
    [
      restApiInterface.activate,
      messageQueueInterface.activate,
      cronJobInterface.activate,
    ],
  ],
  stopStrategy: [
    // Parallel: Deactivate all listeners
    [
      restApiInterface.deactivate,
      messageQueueInterface.deactivate,
      cronJobInterface.deactivate,
    ],
    // Sequential: Wait and cleanup
    [
      activeProcesses.waitForCompletion,
      databaseConnection.close,
      logger.flush,
    ],
  ],
})

// Main application entry
export const startApp = async () => {
  await appBoot.start()
}

export const stopApp = async () => {
  await appBoot.stop()
}
```

### Strategy Definition

The `msh-app-boot` package uses a strategy array where:
- **Each inner array** represents tasks that run in **parallel**
- **Each outer array index** represents a **sequential step**

**Example:**
```typescript
[
  [task1, task2, task3],  // Step 1: task1, task2, task3 run in parallel
  [task4],                 // Step 2: task4 runs after step 1 completes
  [task5, task6],          // Step 3: task5 and task6 run in parallel after step 2
]
```

### Manual Implementation (Without Package)

If not using the package, implement with singleton objects:

```typescript
// app-boot/index.ts
export const appBoot = {
  async start() {
    await appStartup.start()
  },

  async stop() {
    await appShutdown.stop()
  }
}
```

### Interface Managers

Each external interface should have an activate/deactivate pattern:

```typescript
// app-boot/interface/rest-api-interface.ts
export const restApiInterface = {
  async activate() {
    // Start Express server
    await server.listen(PORT)
  },

  async deactivate() {
    // Stop accepting new connections
    await server.close()
  }
}
```

```typescript
// app-boot/interface/message-queue-interface.ts
export const messageQueueInterface = {
  async activate() {
    // Start consuming messages
    await consumer.connect()
    await consumer.subscribe()
  },

  async deactivate() {
    // Stop consuming, wait for current messages
    await consumer.disconnect()
  }
}
```

```typescript
// app-boot/interface/cron-job-interface.ts
export const cronJobInterface = {
  async activate() {
    // Start cron schedulers
    cronScheduler.start()
  },

  async deactivate() {
    // Stop scheduling, wait for running jobs
    await cronScheduler.stop()
  }
}
```

## Error Handling

Always log errors during shutdown to identify issues that may cause problems in production.

### With msh-app-boot Package

```typescript
// index.ts or main.ts
import { appBoot } from '#src/app-boot'

const main = async () => {
  try {
    await appBoot.start()
  } catch (error) {
    logger.error('Failed to start application:', error)
    process.exit(1)
  }
}

// Graceful shutdown on signals
const shutdown = async (signal: string) => {
  logger.info(`Received ${signal}, shutting down gracefully...`)
  try {
    await appBoot.stop()
    logger.info('Application stopped successfully')
    process.exit(0)
  } catch (error) {
    logger.error('Failed to shutdown gracefully:', error)
    process.exit(1)
  }
}

process.on('SIGTERM', () => shutdown('SIGTERM'))
process.on('SIGINT', () => shutdown('SIGINT'))

main()
```

### Without Package

```typescript
// Main application entry point
process.on('SIGTERM', async () => {
  try {
    await appBoot.stop()
    process.exit(0)
  } catch (error) {
    logger.error('Failed to shutdown gracefully:', error)
    process.exit(1)
  }
})

process.on('SIGINT', async () => {
  try {
    await appBoot.stop()
    process.exit(0)
  } catch (error) {
    logger.error('Failed to shutdown gracefully:', error)
    process.exit(1)
  }
})
```

## Testing Considerations

The ABL should support different initialization modes for testing:

```typescript
// app-boot/startup.ts
export const appStartup = {
  async start(options?: { skipDatabase?: boolean; skipRestApi?: boolean }) {
    // Foundation Layer
    if (!options?.skipDatabase) {
      await databaseConnection.connect()
      await databaseMigration.run()
    }
    await internalEventBus.register()

    // Interface Layer
    const interfaces = []
    if (!options?.skipRestApi) {
      interfaces.push(restApiInterface.activate())
    }
    interfaces.push(messageQueueInterface.activate())
    interfaces.push(cronJobInterface.activate())

    await Promise.all(interfaces)
  }
}
```

### Unit Test Example

```typescript
// test/integration/app-boot.test.ts
describe('App Boot', () => {
  test('should start without database and REST API', async () => {
    await appStartup.start({
      skipDatabase: true,
      skipRestApi: true
    })

    // Test only EventBus, MessageQueue, and CronJob
    expect(internalEventBus.isRegistered()).toBe(true)
  })
})
```

## Common Patterns

### Database Connection with Retry

```typescript
// app-boot/foundation/database-connection.ts
export const databaseConnection = {
  async connect(retries = 3) {
    for (let i = 0; i < retries; i++) {
      try {
        await dataSource.initialize()
        logger.info('Database connected')
        return
      } catch (error) {
        logger.warn(`Database connection attempt ${i + 1} failed`, error)
        if (i === retries - 1) throw error
        await new Promise(resolve => setTimeout(resolve, 1000 * (i + 1)))
      }
    }
  },

  async close() {
    await dataSource.destroy()
    logger.info('Database connection closed')
  }
}
```

### Active Process Tracking

```typescript
// app-boot/foundation/active-processes.ts
export const activeProcesses = {
  count: 0,

  increment() {
    this.count++
  },

  decrement() {
    this.count--
  },

  async waitForCompletion(timeoutMs = 30000) {
    const startTime = Date.now()
    while (this.count > 0) {
      if (Date.now() - startTime > timeoutMs) {
        logger.warn(`Timeout waiting for ${this.count} processes`)
        break
      }
      await new Promise(resolve => setTimeout(resolve, 100))
    }
  }
}
```

## Key Takeaways

1. **Use msh-app-boot Package**: The recommended approach is to use the `@beecode/msh-app-boot` package for managing application lifecycle
2. **Sequential vs Parallel**: Foundation must be sequential, interfaces can be parallel
3. **Strategy Arrays**: In msh-app-boot, each inner array runs in parallel, each outer array index is sequential
4. **Graceful Shutdown**: Always deactivate listeners → wait for completion → cleanup
5. **Error Logging**: Log all shutdown errors for debugging
6. **Flexible Modes**: Support different startup configurations for different environments
7. **Singleton Pattern**: ABL components use singleton objects, not classes
8. **Signal Handling**: Listen to SIGTERM and SIGINT for graceful shutdown
