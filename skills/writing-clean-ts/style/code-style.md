# Code Style Guide

## Purpose

Define code formatting rules that ensure accurate code coverage reporting and maintainable code.

## Multi-Line Code Requirement

### Why Multi-Line Code Matters for Coverage

Code coverage tools (Istanbul, c8, etc.) report coverage at the line level. When multiple logical branches exist on a single line, coverage tools cannot distinguish between them, leading to **false positive coverage reports**.

**Example of the problem:**
```typescript
const value = something && anotherThing
```

Single-line expressions with branches hide which path was taken, leading to false positive coverage reports.

### Mandatory Multi-Line Formatting

#### No Ternary Operators

Ternary operators are prohibited. They compress conditional logic into a single expression, hiding branches from coverage tools and reducing readability. Use `if/else` or extract to a named function.

**Why ternary operators are prohibited:**
- Coverage tools report at the line level — ternaries hide branch visibility regardless of formatting
- They inline conditional logic into expressions, making code harder to scan
- Named functions make the intent self-documenting — the function name explains what the conditional resolves

**Alternative 1 — Use `if/else` directly:**

When the result feeds into the rest of the function, restructure with early returns:

```typescript
if (condition) {
  return trueValue
}

return falseValue
```

**Alternative 2 — Extract to a local function:**

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
- **Local arrow function** — when used once inside a function body
- **Class method** — when used inside a class (private if only used internally)
- **File-level or service method** — when reused across multiple places

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

Each case should be on its own line:

```typescript
switch (status) {
  case 'active':
    handleActive()
    break

  case 'inactive':
    handleInactive()
    break

  default:
    handleDefault()
}
```

### Code Coverage Benefits

By following multi-line formatting:

| Pattern | Before (Hidden Coverage) | After (Visible Coverage) |
|---------|-------------------------|-------------------------|
| Ternary | PROHIBITED — use if/else or extract to function | Each branch gets own line |
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

## CRITICAL: No For Loops - Use Functional Array Methods

**FOR LOOPS ARE PROHIBITED. Use `.map()` or `.reduce()` instead.**

This is not a preference or recommendation - it is a mandatory rule. For loops (`for`, `for...of`, `for...in`) are never allowed.

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

1. **Ternary operators**: PROHIBITED — use `if/else` or extract to a named function
2. **If statements**: Always use blocks `{}`, never single-line
3. **Arrow functions**: ALWAYS use block syntax `{ return ... }` — no inline arrow expressions, no exceptions
4. **Logical operators**: Expand to multiple lines or use explicit conditionals
5. **Each statement**: One logical operation per line for coverage visibility
6. **No comments**: Never add comments except temporary TODOs with removal conditions
