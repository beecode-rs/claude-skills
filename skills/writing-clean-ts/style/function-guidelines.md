# Function Guidelines

## Error Handling (Return Undefined Pattern)

Every function should be treated as if it can throw an error at any moment.

### Basic Rule

If a function returns `User` by providing an ID, and the user with that ID doesn't exist, the function **must throw a 404 error (Not Found)**.

### Swallowing Errors

When business logic requires swallowing errors, handle it like this:

```typescript
userRepo.findOneById('some-id').catch(() => undefined)
```

### Avoiding Code Duplication

Instead of repeating error-swallowing code (a code smell), create wrapper functions that never throw errors:

```typescript
// userRepo
// ...
  findOneByIdIfExists(id: string): Promise<User | undefined> {
    return this.findOneById('some-id').catch(() => undefined)
  }

  // Or use try-catch for more complex code
  async findOneByIdIfExists(id: string): Promise<User | undefined> {
    try {
      // ...
      return await this.findOneById('some-id')
      // ...
    } catch (err) {
      logger().error(err)
      return undefined
    }
  }
// ...
```

**Key Points:**
- Base methods (like `findOneById`) should throw errors when data is not found
- Wrapper methods (like `findOneByIdIfExists`) catch and return `undefined` for optional lookups
- Use `IfExists` suffix for methods that return `undefined` instead of throwing
- This prevents code duplication while maintaining clear error semantics

## Function Naming

When naming a function, ensure the name covers **everything** the function does. This rule prevents creating overly complex functions.

**Exception:** Functions in the **Use Case Layer** are exempt because a use-case only *combines* functionality from other business layers; it holds no business logic of its own. A use-case gets a short name, and the operations it combines are read from the descriptive names of the service/repo calls in its body.

This exemption has a hard limit: a use-case must combine **two or more** operations. A use-case that calls only one service function is an unnecessary wrapper, because the controller can call that service directly. See [use-case-layer.md](../architecture/layer/use-case-layer.md).

**Examples:**

```typescript
// ✅ GOOD - Name describes exactly what it does
async function createUserAndSendWelcomeEmail(userData: UserData): Promise<User> {
  const user = await userRepo.create(userData)
  await emailService.sendWelcome(user.email)
  return user
}

// ❌ BAD - Name doesn't indicate email is sent
async function createUser(userData: UserData): Promise<User> {
  const user = await userRepo.create(userData)
  await emailService.sendWelcome(user.email) // Hidden side effect!
  return user
}

// ✅ GOOD - Use Case Layer (exempt from rule)
const userUseCase = {
  async register(userData: UserData): Promise<User> {
    const user = await userService.createUser(userData)
    await emailService.sendWelcome(user.email)
    await analyticsService.trackRegistration(user.id)
    return user
  }
}
```

## Never Keyword in Enum Switch

Use the `never` type to get compile-time errors when not all enum values are covered in a switch statement.

### Exhaustive Type Checking Utility

```typescript
import { typeUtil } from '@beecode/msh-util/type-util'

const typeUtil = {
  exhaustiveMessage: (message: string, _: never): string => {
    return `${message}`
  },
  exhaustiveError: (message: string, _: never): Error => {
    return new Error(typeUtil.exhaustiveMessage(message, _))
  }
}
```

### Example with Enum

```typescript
enum LogLevelType {
  ERROR = 'ERROR',
  WARN = 'WARN',
  INFO = 'INFO',
  DEBUG = 'DEBUG',
}

const LogLevelToInt = (logLevel: LogLevelType): number => {
  switch (logLevel) {
    case LogLevelType.ERROR:
      return 0
    case LogLevelType.WARN:
      return 1
    case LogLevelType.INFO:
      return 2
    // case LogLevelType.DEBUG:
    //   return 3
    default:
      throw typeUtil.exhaustiveError(`Unknown log level`, logLevel)
      //                                                  ^^^^^^^^
      // If we don't have a case for LogLevelType.DEBUG,
      // TypeScript will throw a compile-time error:
      // Error: Argument of type 'LogLevelType' is not assignable to parameter of type 'never'
  }
}
```

**Benefits:**
- **Compile-time safety**: TypeScript will error if any enum case is missing
- **Refactoring protection**: Adding new enum values will immediately show where switch statements need updating
- **Runtime error**: If somehow an unexpected value reaches the default case, you get a clear error message

**How it works:**
1. When all enum cases are handled, `logLevel` in the default case is type `never` (impossible to reach)
2. When a case is missing (like `DEBUG`), `logLevel` in default could be `LogLevelType.DEBUG`
3. TypeScript errors because `LogLevelType.DEBUG` cannot be assigned to parameter of type `never`

### Applying to Your Code

```typescript
// Example with status transitions
enum InvoiceStatus {
  DRAFT = 'DRAFT',
  SENT = 'SENT',
  PAID = 'PAID',
  CANCELLED = 'CANCELLED',
}

const getNextStates = (status: InvoiceStatus): InvoiceStatus[] => {
  switch (status) {
    case InvoiceStatus.DRAFT:
      return [InvoiceStatus.SENT, InvoiceStatus.CANCELLED]
    case InvoiceStatus.SENT:
      return [InvoiceStatus.PAID, InvoiceStatus.CANCELLED]
    case InvoiceStatus.PAID:
      return []
    case InvoiceStatus.CANCELLED:
      return []
    default:
      throw typeUtil.exhaustiveError(`Unknown invoice status`, status)
  }
}
```
