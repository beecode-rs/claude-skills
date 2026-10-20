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
  findOneByIdIfExists(params: { id: string }): Promise<UserModel | undefined> {
    return this.findOneById(params).catch(() => {
      return undefined
    })
  }

  // Or use try-catch for more complex code
  async findOneByIdIfExists(params: { id: string }): Promise<UserModel | undefined> {
    try {
      return await this.findOneById(params)
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

This exemption has a hard limit: a use-case must combine **two or more** operations. A use-case that calls only one service function is an unnecessary wrapper, because the controller can call that service directly.

**Examples:**

```typescript
// ✅ GOOD - Name describes exactly what it does
async createUserAndSendWelcomeEmail(params: { user: UserModelCreate }): Promise<UserModel> {
  const { user } = params

  const createdUser = await new UserRepo().create({ model: user })
  await emailService.sendWelcome({ email: createdUser.email })

  return createdUser
}

// ❌ BAD - Name doesn't indicate email is sent
async createUser(params: { user: UserModelCreate }): Promise<UserModel> {
  const { user } = params

  const createdUser = await new UserRepo().create({ model: user })
  await emailService.sendWelcome({ email: createdUser.email }) // Hidden side effect!

  return createdUser
}

// ✅ GOOD - Use Case Layer (exempt from rule)
export const userUseCase = {
  async register(params: { user: UserModelCreate }): Promise<UserModel> {
    const { user } = params

    const createdUser = await userService.createUser({ user })
    await emailService.sendWelcome({ email: createdUser.email })
    await analyticsService.trackRegistration({ userId: createdUser.id })

    return createdUser
  },
}
```

## Exhaustive Enum Switches

**Every `switch` whose cases cover all members of an enum (or a closed union) MUST use `typeUtil.exhaustiveError` from `@beecode/msh-util` in its `default`.** In the `default` branch the switched value has type `never` when every member is handled; passing it to `exhaustiveError(message, value)` turns a forgotten member into a compile-time error at the exact switch that forgot it.

```typescript
import { typeUtil } from '@beecode/msh-util/type-util'

import { LogLevel } from '#src/business/enum/log-level-enum'

const resolveLogLevelRank = (params: { logLevel: LogLevel }): number => {
  const { logLevel } = params

  switch (logLevel) {
    case LogLevel.ERROR: {
      return 0
    }
    case LogLevel.WARN: {
      return 1
    }
    case LogLevel.INFO: {
      return 2
    }
    case LogLevel.DEBUG: {
      return 3
    }
    default: {
      throw typeUtil.exhaustiveError('unknown log level', logLevel)
    }
  }
}
```

If `LogLevel.TRACE` is added later, TypeScript reports `Argument of type 'LogLevel' is not assignable to parameter of type 'never'` on the `default` line until a case is added.

Rules:

- Check the installed `@beecode/msh-util` version's import path via the `implementing-msh` skill; never re-implement `exhaustiveError` locally
- Applies everywhere, including factories that map an enum to a strategy class and components that map an enum to JSX
- A switch that intentionally handles only some members is not exhaustive: its `default` throws a normal error (or returns a documented fallback) instead
- Switching on a raw string where an enum exists is itself a violation: convert the value to the enum first

**Benefits:**
- **Compile-time safety**: TypeScript errors if any enum member is missing
- **Refactoring protection**: Adding an enum member immediately shows every switch that needs updating
- **Runtime error**: If an unexpected value still reaches `default` (bad data from outside), the error message says so

## Do Not Repeat Near-Identical Functions

When two or more functions differ only in the data they touch (three `_ensureUniqueTrackerId` / `_ensureUniqueTriggerId` / `_ensureUniqueSshHostId` bodies that differ only in the list and the id field), extract one generic function and call it three times. Generic over its inputs (no domain imports) means it belongs in `util/` (`idUtil.ensureUniqueIds(...)`); if it must know domain shapes, it is one `protected _` method on the service. Copies drift apart; one function stays correct.

## Delete Code That No Longer Has a Job

Once a migration has run everywhere it needs to, or a placeholder (a dummy provider, a fallback for an old file format) is no longer reachable, delete it along with its tests and wiring. Version control remembers it. Dead branches and "just in case" legacy readers are code every reader must still understand.
