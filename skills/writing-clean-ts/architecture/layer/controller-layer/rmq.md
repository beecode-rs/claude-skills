# RabbitMQ Controller Layer

RabbitMQ controllers handle external message queue communications for asynchronous processing and inter-service communication. Part of the **Controller Layer (CL)** for message-driven interfaces.

**See [controller-layer.md](../controller-layer.md) for the abstract controller pattern that applies to all interface types.**

## Framework

This implementation uses:
- **RabbitMQ** - Message broker for distributed systems
- **amqplib** - AMQP client library for Node.js
- **Channel** - RabbitMQ channel for message consumption
- **Singleton Pattern** - For controller registration

## Naming Convention

**See [naming-convention.md](../../../style/naming-convention.md) for complete naming standards.**

- **File:** `kebab-case` (e.g., `project-created.ts`, `user-updated.ts`)
- **Export:** `camelCase` singleton object (always)
- **Pattern:** Always singleton objects with `register()` method
- **Location:** `src/controller/rmq/[domain]/`

## Purpose

RabbitMQ controllers provide message queue handlers that:
- Consume messages from external queues
- Validate incoming message payloads
- Process messages asynchronously
- Acknowledge successful processing (ack)
- Reject failed messages (nack) with retry logic
- Handle errors with dead letter queues

## Structure

### Basic Message Handler

```typescript
// src/controller/rmq/project-created.ts
import { type Channel, type ConsumeMessage } from 'amqplib'
import { z } from '@app/common/lib/zod-wrapper'
import { validationUtil } from '@app/common/util/validation-util'
import { logger } from '#src/util/logger'
import { projectService } from '#src/business/service/project-service'

const messagePayloadSchema = z.object({
  projectId: z.string().uuid(),
  ownerId: z.string().uuid(),
  name: z.string(),
})

export const rmqProjectCreated = {
  register: async (channel: Channel): Promise<void> => {
    const queue = 'project.created'

    await channel.assertQueue(queue, {
      durable: true,
    })

    await channel.consume(queue, async (msg: ConsumeMessage | null) => {
      if (!msg) return

      try {
        const payload = validationUtil.parse(
          JSON.parse(msg.content.toString()),
          messagePayloadSchema
        )

        await projectService.handleCreated(payload)

        channel.ack(msg)
        logger().info(`Processed project.created message: ${payload.projectId}`)
      } catch (err: unknown) {
        logger().error('Failed to process project.created message', err)
        channel.nack(msg, false, false) // Don't requeue, send to DLQ
      }
    })

    logger().info(`RMQ consumer registered for queue: ${queue}`)
  },
}
```

### Message Handler with Retry Logic

```typescript
// src/controller/rmq/user-notification.ts
import { type Channel, type ConsumeMessage } from 'amqplib'
import { z } from '@app/common/lib/zod-wrapper'
import { validationUtil } from '@app/common/util/validation-util'
import { logger } from '#src/util/logger'
import { notificationService } from '#src/business/service/notification-service'

const messagePayloadSchema = z.object({
  userId: z.string().uuid(),
  message: z.string(),
  type: z.enum(['EMAIL', 'SMS', 'PUSH']),
})

const MAX_RETRIES = 3

export const rmqUserNotification = {
  register: async (channel: Channel): Promise<void> => {
    const queue = 'user.notification'

    await channel.assertQueue(queue, {
      durable: true,
      arguments: {
        'x-dead-letter-exchange': 'dlx.exchange',
        'x-dead-letter-routing-key': 'dlq.user.notification',
      },
    })

    await channel.consume(queue, async (msg: ConsumeMessage | null) => {
      if (!msg) return

      try {
        const payload = validationUtil.parse(
          JSON.parse(msg.content.toString()),
          messagePayloadSchema
        )

        const retryCount = (msg.properties.headers?.['x-retry-count'] || 0) as number

        await notificationService.send(payload)

        channel.ack(msg)
        logger().info(`Notification sent to user: ${payload.userId}`)
      } catch (err: unknown) {
        const retryCount = (msg.properties.headers?.['x-retry-count'] || 0) as number

        if (retryCount < MAX_RETRIES) {
          // Retry: Requeue with incremented retry count
          channel.nack(msg, false, false)

          await channel.publish(
            '',
            queue,
            msg.content,
            {
              headers: {
                'x-retry-count': retryCount + 1,
              },
            }
          )

          logger().warn(`Retrying notification (attempt ${retryCount + 1}/${MAX_RETRIES})`, err)
        } else {
          // Max retries exceeded: Send to DLQ
          channel.nack(msg, false, false)
          logger().error(`Failed to send notification after ${MAX_RETRIES} retries`, err)
        }
      }
    })

    logger().info(`RMQ consumer registered for queue: ${queue}`)
  },
}
```

### Message Handler with Prefetch

```typescript
// src/controller/rmq/data-processing.ts
import { type Channel, type ConsumeMessage } from 'amqplib'
import { z } from '@app/common/lib/zod-wrapper'
import { validationUtil } from '@app/common/util/validation-util'
import { logger } from '#src/util/logger'
import { dataProcessingService } from '#src/business/service/data-processing-service'

const messagePayloadSchema = z.object({
  dataId: z.string().uuid(),
  type: z.string(),
})

export const rmqDataProcessing = {
  register: async (channel: Channel): Promise<void> => {
    const queue = 'data.processing'

    await channel.assertQueue(queue, {
      durable: true,
    })

    // Set prefetch to limit concurrent processing
    await channel.prefetch(5) // Process max 5 messages concurrently

    await channel.consume(queue, async (msg: ConsumeMessage | null) => {
      if (!msg) return

      try {
        const payload = validationUtil.parse(
          JSON.parse(msg.content.toString()),
          messagePayloadSchema
        )

        await dataProcessingService.process(payload)

        channel.ack(msg)
        logger().info(`Processed data: ${payload.dataId}`)
      } catch (err: unknown) {
        logger().error('Failed to process data', err)
        channel.nack(msg, false, true) // Requeue for retry
      }
    })

    logger().info(`RMQ consumer registered for queue: ${queue}`)
  },
}
```

## Router Integration

```typescript
// src/controller/rmq/router.ts
import { type Channel } from 'amqplib'
import { singletonPattern } from '@beecode/msh-util/singleton/pattern'

import { rmqProjectCreated } from './project-created'
import { rmqUserNotification } from './user-notification'
import { rmqDataProcessing } from './data-processing'
import { logger } from '#src/util/logger'

export class RmqRouter {
  protected _channel: Channel | null = null

  async register(channel: Channel): Promise<void> {
    this._channel = channel

    await rmqProjectCreated.register(channel)
    await rmqUserNotification.register(channel)
    await rmqDataProcessing.register(channel)

    logger().info('All RMQ consumers registered')
  }

  async unregister(): Promise<void> {
    if (this._channel) {
      await this._channel.close()
      this._channel = null
      logger().info('RMQ channel closed')
    }
  }
}

export const rmqRouterSingleton = singletonPattern(() => {
  return new RmqRouter()
})
```

## Folder Structure

```
src/
  controller/
    rmq/                               # Message queue handlers
      project-created.ts               # Handle project creation messages
      user-notification.ts             # Handle user notifications
      data-processing.ts               # Handle data processing tasks
      order-fulfilled.ts               # Handle order fulfillment
      router.ts                        # Registration/deregistration
```

## Key Characteristics

- **External messaging**: Handle messages from external systems
- **Acknowledgment**: Manual ack/nack for reliable delivery
- **Payload validation**: Validate incoming message structure
- **Error recovery**: Dead letter queues and retry logic
- **Singleton objects**: Always export as singleton objects (never classes)
- **Prefetch control**: Limit concurrent message processing
- **Durable queues**: Ensure messages survive broker restarts

## Message Acknowledgment Patterns

### Acknowledge Success

```typescript
channel.ack(msg) // Remove message from queue
```

### Reject and Don't Requeue (Send to DLQ)

```typescript
channel.nack(msg, false, false) // Don't requeue, send to dead letter queue
```

### Reject and Requeue

```typescript
channel.nack(msg, false, true) // Requeue for retry
```

### Reject Multiple Messages

```typescript
channel.nack(msg, true, false) // Reject this and all previous unacked messages
```

## Queue Configuration

### Basic Durable Queue

```typescript
await channel.assertQueue('queue.name', {
  durable: true, // Survive broker restart
})
```

### Queue with Dead Letter Exchange

```typescript
await channel.assertQueue('queue.name', {
  durable: true,
  arguments: {
    'x-dead-letter-exchange': 'dlx.exchange',
    'x-dead-letter-routing-key': 'dlq.queue.name',
    'x-message-ttl': 60000, // Message TTL in ms
  },
})
```

### Queue with Max Length

```typescript
await channel.assertQueue('queue.name', {
  durable: true,
  arguments: {
    'x-max-length': 10000, // Max queue length
    'x-overflow': 'reject-publish', // Reject new messages when full
  },
})
```

## Error Handling Strategies

### Strategy 1: Immediate DLQ

```typescript
catch (err: unknown) {
  logger().error('Processing failed, sending to DLQ', err)
  channel.nack(msg, false, false) // Send to dead letter queue
}
```

### Strategy 2: Requeue Once

```typescript
catch (err: unknown) {
  const redelivered = msg.fields.redelivered

  if (redelivered) {
    // Already tried once, send to DLQ
    logger().error('Processing failed after retry, sending to DLQ', err)
    channel.nack(msg, false, false)
  } else {
    // First attempt, requeue
    logger().warn('Processing failed, requeuing', err)
    channel.nack(msg, false, true)
  }
}
```

### Strategy 3: Custom Retry Count

```typescript
catch (err: unknown) {
  const retryCount = (msg.properties.headers?.['x-retry-count'] || 0) as number

  if (retryCount < MAX_RETRIES) {
    // Republish with incremented retry count
    await channel.publish('', queue, msg.content, {
      headers: { 'x-retry-count': retryCount + 1 },
    })
    channel.nack(msg, false, false)
  } else {
    // Max retries exceeded
    channel.nack(msg, false, false)
  }
}
```

## Architectural Rules

### ✅ DO

- Acknowledge messages after successful processing
- Implement error handling and retry logic
- Validate message payloads with Zod
- Use dead letter queues for failed messages
- Set appropriate prefetch limits
- Use durable queues for important messages
- Log all errors for debugging
- Use singleton objects for exports
- Close channels on application shutdown

### ❌ DON'T

- Auto-acknowledge messages before processing
- Ignore errors (implement proper error handling)
- Process messages synchronously if they're expensive
- Use classes for RMQ controllers (always use singleton objects)
- Skip message validation
- Requeue indefinitely (use max retry limits)
- Block the event loop with heavy processing
- Forget to close channels on shutdown

## Lifecycle Management

### Application Startup

```typescript
// app-boot/startup.ts
import { rmqConnectionSingleton } from '#src/lib/rmq/connection'
import { rmqRouterSingleton } from '#src/controller/rmq/router'

export const appStartup = {
  async start() {
    // ... other startup tasks

    // Connect to RabbitMQ and register consumers
    const connection = await rmqConnectionSingleton().connect()
    const channel = await connection.createChannel()

    await rmqRouterSingleton().register(channel)

    logger().info('RMQ consumers registered')
  }
}
```

### Application Shutdown

```typescript
// app-boot/shutdown.ts
import { rmqRouterSingleton } from '#src/controller/rmq/router'
import { rmqConnectionSingleton } from '#src/lib/rmq/connection'

export const appShutdown = {
  async stop() {
    // Unregister consumers and close channel
    await rmqRouterSingleton().unregister()

    // Close connection
    await rmqConnectionSingleton().disconnect()

    logger().info('RMQ connection closed')
  }
}
```

## Testing Message Handlers

For testing patterns and examples, use the **test-typescript** skill.

## Relationship with Other Layers

```
External System → Message Queue → RMQ Controller → Service/Use Case
                                        ↓
                                   Validation
                                   Async Processing
                                   Ack/Nack
```

RabbitMQ controllers enable asynchronous, distributed processing by consuming messages from external queues, ensuring reliable message delivery with acknowledgments and retry logic.
