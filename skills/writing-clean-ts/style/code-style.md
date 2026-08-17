# Code Style Guide

## Purpose

Define code formatting rules that ensure accurate code coverage reporting and maintainable code.

Rules marked `[lint]` are also enforced by the lint script (see [../linting/eslint-rules.md](../linting/eslint-rules.md)). `[lint, auto-fix]` rules are rewritten automatically by `lint-fix`; plain `[lint]` rules are reported by lint and fixed manually. They stay documented so code is written correctly the first time - the linter is the safety net, not a replacement for knowing them.

## Multi-Line Code Requirement

### Why Multi-Line Code Matters for Coverage

Code coverage tools (Istanbul, c8, etc.) report coverage at the line level. When multiple logical branches exist on a single line, coverage tools cannot distinguish between them, leading to **false positive coverage reports**.

**Example of the problem:**
```typescript
const value = something && anotherThing
```

Single-line expressions with branches hide which path was taken, leading to false positive coverage reports.

### Mandatory Multi-Line Formatting

#### No Ternary Operators `[lint]`

Ternary operators are prohibited. They compress conditional logic into a single expression, hiding branches from coverage tools and reducing readability. Use `if/else` or extract to a named function. The lint script enforces this (`no-ternary`: error in the Node flavor, warn in React); it is not auto-fixable, so rewrite manually when lint reports it.

**Why ternary operators are prohibited:**
- Coverage tools report at the line level, so ternaries hide branch visibility regardless of formatting
- They inline conditional logic into expressions, making code harder to scan
- Named functions make the intent self-documenting: the function name explains what the conditional resolves

**Alternative 1 - use `if/else` directly:**

When the result feeds into the rest of the function, restructure with early returns:

```typescript
if (condition) {
  return trueValue
}

return falseValue
```

**Alternative 2 - extract to a local function:**

When you need to assign a `const`, extract the conditional into a named function. The function name documents the intent, and each branch gets its own coverage line.

```typescript
const getStatus = () => {
  if (isActive) {
    return 'active'
  }

  return 'inactive'
}

const status = getStatus()
```

**Scope the function at the narrowest level that works:**
- **Local arrow function** - when used once inside a function body
- **Class method** - when used inside a class (`protected` with a `_` prefix if only used internally)
- **Service method** - when reused across multiple places. In a file that exports a service (class or singleton object), a helper MUST be a member of that service - a `protected _` method on the class called via `this` - never a root-of-file function. Module-scope helper functions next to a service export are prohibited

#### If Statements

Never use single-line if statements:

```typescript
if (condition) {
  doSomething()
}
```

**Avoid:**
```typescript
if (condition) doSomething()
```

**Avoid:**
```typescript
if (condition) { doSomething() }
```

Missing braces are auto-fixed by lint (`curly`). The single-line-braces form passes the linter but still hides branch coverage, so keep if statements multi-line.

#### Arrow Functions

ALL arrow functions must use block syntax with explicit `return`. There are no exceptions — not for "simple" transformations, not for `.map()` callbacks, not for one-liners.

Inline arrow expressions like `(x) => x + 1` hide return branches from coverage tools, producing false positive coverage reports.

```typescript
const getValue = (params: { input: string }) => {
  return params.input.toUpperCase()
}
```

```typescript
const double = (n: number) => {
  return n * 2
}
```

This applies to ALL contexts — `.map()`, `.reduce()`, `.filter()`, `.find()`, `Array.from()`, callbacks, event handlers, etc:

```typescript
const names = users.map((user) => {
  return user.name
})
```

```typescript
const total = items.reduce((sum, item) => {
  return sum + item.price
}, 0)
```

#### Object/Array Destructuring with Defaults

```typescript
const {
  value = defaultValue,
  nested
} = params
```

#### Logical Operators for Assignment

Avoid single-line logical operator assignments with conditions:

```typescript
const value = something && anotherThing
```

Extract to a named function with explicit `if/else`:

```typescript
const getValue = () => {
  if (something) {
    return anotherThing
  }

  return undefined
}

const value = getValue()
```

#### Switch/Case Statements

Each case uses its own braced block and `return`s — switches are always encapsulated in a function (full rule in the "No `let` — `const` Only, Switch Over If/Else Chains" section below):

```typescript
const resolveStatusLabel = (params: { status: string }) => {
  switch (params.status) {
    case 'active': {
      return 'Active'
    }

    case 'inactive': {
      return 'Inactive'
    }

    default: {
      throw new Error(`unsupported status: ${params.status}`)
    }
  }
}
```

### Code Coverage Benefits

By following multi-line formatting:

| Pattern | Before (Hidden Coverage) | After (Visible Coverage) |
|---------|-------------------------|-------------------------|
| Ternary | PROHIBITED - use if/else or extract to function `[lint]` | Each branch gets own line |
| If/else | Single line hides else | Each branch visible |
| Short-circuit | Hidden branches | Explicit conditions |
| Arrow functions | Hidden returns | Explicit return paths |

## Falsy Default Values

When defining default values for parameters, prefer **falsy defaults** when possible. This makes it predictable whether a parameter was explicitly set or is using its default.

### Preferred Falsy Defaults

| Type | Default Value |
|------|---------------|
| `string` | `''` (empty string) |
| `boolean` | `false` |
| `number` | `0` |

### Why Falsy Defaults

```typescript
// ✅ Good - falsy defaults make checks predictable
function processItem(params: { name: string; count: number; isActive: boolean }) {
  const { name = '', count = 0, isActive = false } = params

  // Can reliably check if value was provided or is default
  if (!name) {
    // name was either not provided OR provided as empty string
  }
}

// ❌ Avoid - truthy defaults hide intent
function processItem(params: { status: string; retryCount: number }) {
  const { status = 'active', retryCount = 3 } = params

  // Can't distinguish between default and explicitly set
  if (status === 'active') {
    // Was this the default or explicitly set to 'active'?
  }
}
```

### Boolean Flags: Invert the Name, Not the Check

For optional boolean flags, never encode a truthy default through an inverted check. If the common case is "on", invert the flag's name so the default stays falsy:

```typescript
// ❌ Bad - implicit truthy default hidden behind a double negative
speak(params: { recordHistory?: boolean }) {
  if (params.recordHistory !== false) { ... }  // Default is silently `true`
}

// ✅ Good - falsy default, positive check
speak(params: { shouldSkipHistory?: boolean }) {
  if (!params.shouldSkipHistory) { ... }  // Default is visibly `false`
}
```

### When Truthy Defaults Are Acceptable

This rule is not strict. Use truthy defaults when business logic requires it:

```typescript
// ✅ Acceptable - sensible defaults that match business requirements
const { page = 1, limit = 20 } = pagination  // Pagination typically starts at 1
const { timeout = 30000 } = config           // Reasonable default timeout
const { sortOrder = 'desc' } = options       // Most recent first is common
```

### Summary

- **Prefer falsy** when the default represents "no value" or "disabled"
- **Use truthy** when the default is a sensible business default (pagination, timeouts, common settings)
- The goal is predictability, not dogmatism

## CRITICAL: No For Loops - Use Functional Array Methods `[lint]`

**FOR LOOPS ARE PROHIBITED. Use `.map()` or `.reduce()` instead.**

This is not a preference or recommendation - it is a mandatory rule. For loops (`for`, `for...of`, `for...in`) are never allowed. The lint script enforces this (`no-loops/no-loops`: error); it is not auto-fixable, so when lint reports a loop, rewrite it with the functional methods below.

### Why Functional Methods

1. **Immutability**: `.map()` and `.reduce()` encourage immutable patterns
2. **Expressiveness**: The intent is clear - transformation or aggregation
3. **Testability**: Pure functions are easier to test
4. **Composability**: Functional methods chain naturally

### Mandatory Patterns

#### Transformation → Use `.map()`

```typescript
// ❌ WRONG - for loop
const names: string[] = []
for (const user of users) {
  names.push(user.name)
}

// ✅ CORRECT - use .map()
const names = users.map((user) => {
  return user.name
})
```

```typescript
// ❌ WRONG - for loop with transformation
const doubled: number[] = []
for (let i = 0; i < numbers.length; i++) {
  doubled.push(numbers[i] * 2)
}

// ✅ CORRECT - use .map()
const doubled = numbers.map((n) => {
  return n * 2
})
```

#### Aggregation → Use `.reduce()`

```typescript
// ❌ WRONG - for loop with accumulator
let total = 0
for (const item of items) {
  total += item.price
}

// ✅ CORRECT - use .reduce()
const total = items.reduce((sum, item) => {
  return sum + item.price
}, 0)
```

```typescript
// ❌ WRONG - for loop building object
const map: Record<string, User> = {}
for (const user of users) {
  map[user.id] = user
}

// ✅ CORRECT - use .reduce()
const map = users.reduce((acc, user) => {
  return {
    ...acc,
    [user.id]: user,
  }
}, {} as Record<string, User>)
```

#### Filtering → Use `.filter()`

```typescript
// ❌ WRONG - for loop with condition
const active: User[] = []
for (const user of users) {
  if (user.isActive) {
    active.push(user)
  }
}

// ✅ CORRECT - use .filter()
const active = users.filter((user) => {
  return user.isActive
})
```

### Complex Transformations

For complex multi-step transformations, chain methods:

```typescript
// ✅ CORRECT - chained functional methods
const activeUserNames = users
  .filter((user) => {
    return user.isActive
  })
  .map((user) => {
    return user.name
  })
  .sort()
```

### Summary Rules

1. **NEVER use `for` loops** - no `for`, `for...of`, or `for...in`
2. **Transformations** → use `.map()`
3. **Aggregations** → use `.reduce()`
4. **Filtering** → use `.filter()`
5. **Finding** → use `.find()` or `.some()` or `.every()`
6. **Side effects** → if absolutely necessary, use `.forEach()` (but prefer returning values)

## CRITICAL: No `let` — `const` Only, Switch Over If/Else Chains

**`let` is PROHIBITED — every binding is `const`.** When a value depends on branches, extract a well-named function where each branch `return`s. And when those branches compare the **same value** across multiple cases, the function body is a `switch` — never an if/else chain.

### Why

- A `let` accumulated across branches is hidden mutation — readers must trace every write to know the final value
- A `switch` states the dispatch intent directly and enumerates cases exhaustively; `default` makes unsupported values explicit
- The function name documents what the branching produces (`resolveAppDataDir`), and the call site becomes a plain `const`

### ❌ WRONG — if/else chain mutating a `let`

```typescript
let appDataDir
if (platform === 'darwin') {
  appDataDir = path.join(os.homedir(), 'Library', 'Application Support')
} else if (platform === 'win32') {
  appDataDir = process.env.APPDATA
} else if (platform === 'linux') {
  appDataDir = path.join(os.homedir(), '.config')
} else {
  throw new Error(`unsupported platform: ${platform}`)
}
```

### ✅ CORRECT — `switch` encapsulated in a function, called into a `const`

```typescript
const resolveAppDataDir = () => {
  switch (process.platform) {
    case 'darwin': {
      return path.join(os.homedir(), 'Library', 'Application Support')
    }
    case 'win32': {
      return process.env.APPDATA
    }
    case 'linux': {
      return path.join(os.homedir(), '.config')
    }
    default: {
      throw new Error(`unsupported platform: ${process.platform}`)
    }
  }
}

const appDataDir = resolveAppDataDir()
```

### Rules

1. **`const` only** — `let` is never used. Branch-dependent values come from a function that returns per branch
2. **Same value, multiple cases → `switch`** — an if/else chain comparing one variable repeatedly is prohibited. Plain `if/else` remains correct for distinct boolean conditions
3. **Every switch is encapsulated in a function** — never inline in the main flow; the function name says what the switch resolves
4. **Braced case blocks that return or throw** — `case 'x': { return ... }` / `default: { throw ... }`; no `break`, no fallthrough
5. **`default` is explicit** — throw for unsupported values (or return a documented fallback); never rely on silent fallthrough or an uninitialized value

## No Comments Rule

**CRITICAL: No comments are allowed in any code.**

Code must be self-documenting through clear naming:
- Function names should explain what the function does
- Variable names should explain what they contain
- If you feel the need to add a comment, refactor the code instead (extract function, rename variable, simplify logic)

**Only exception**: `// TODO` comments are temporarily allowed but MUST include a clear removal condition. Example:
```typescript
// TODO: Remove after implementing real authentication - currently using mock data
```

### Summary Rules

1. **Ternary operators**: PROHIBITED - use `if/else` or extract to a named function `[lint]`
2. **If statements**: Always use blocks `{}`, never single-line (braces are `[lint, auto-fix]`; the multi-line form is manual)
3. **Arrow functions**: ALWAYS use block syntax `{ return ... }` - no inline arrow expressions, no exceptions
4. **Logical operators**: Expand to multiple lines or use explicit conditionals
5. **Each statement**: One logical operation per line for coverage visibility
6. **No comments**: Never add comments except temporary TODOs with removal conditions
7. **`let`**: PROHIBITED - `const` only; branch-dependent values are returned from an extracted function
8. **If/else chains on one value**: PROHIBITED - use a `switch` encapsulated in a function; braced cases that return, `default` throws
