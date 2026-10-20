# Function Size & Structure

## Overview

A function should do **one named thing**. If you need "and" to describe what a function does, it does more than one thing and should be split. This is the single most effective readability lever - more than comments (which are prohibited) or formatting.

The goal is not a hard line count. It is: each function reads top-to-bottom as one coherent operation, with no hidden responsibilities and no deeply nested branches.

## Measured Reality

Measured over the etalon's business layer (225 non-test files, 11,027 lines, 531 methods):

| Layer | avg | median | max |
|---|---|---|---|
| service/ | 9.0 | 7 | 38 |
| component/ | 11.3 | 9 | 68 |
| use-case/ | 22.6 | 17 | 98 |
| repo/ | 10.0 | 7 | 21* |

(*) excluding one 58-line DI-wiring constructor.

**The practised ceiling is ~30 lines (98th percentile); 81% of methods are 15 lines or fewer.** A function longer than ~30 lines is an outlier that draws attention (15 exist in the whole business layer). This is not a hard limit: a function that does one named thing may legitimately be long when the length is declarative data, not branching (see below). Use the signals, not the number, as your guide.

## The Splitting Move: Extract a Collaborator, Not a Local Helper

Faced with a growing method, this codebase's move is **"extract a named service/repo/strategy class and delegate"**, not "extract a local helper function". The evidence:

- **`protected _camelCase` methods on classes are the only private-helper convention.** 103 `protected _x(...)` methods across the business layer, plus `protected readonly _field` for constructor-config and owned-collaborator fields
- **The `private` keyword appears 0 times.** Encapsulation is always `protected` + a single `_` prefix
- **Module-level helper functions are effectively absent**: 4 in 225 files, zero module-level `function` declarations
- **Nested named functions inside methods: 0.** Inline `.map()`/`.filter()`/`.reduce()` arrows are the pervasive inline style instead
- **Singleton-object exports contain only public members**: no `_` properties, no helpers. Anything non-trivial behind an object method is delegated to a class

This is why class methods average 9.7 lines while singleton-object methods average 13.6 and top-level arrow functions 17.3: **the class + `protected _` helper pattern IS the splitting mechanism**. Reaching for the class is how you make room for helpers; a singleton object is a statement that no helpers are needed.

## Signals a function is too big

Split when any of these appear:

- You describe the function with **"and"** ("it validates the input and saves it and sends an email" → three functions)
- It has **nested `if`** blocks more than two levels deep
- It has a **`switch` or `if/else` chain** where each branch is more than a few lines
- A block of lines would need a **comment** to explain it (comments are banned - extract a named function instead)
- The branching logic itself (not a config literal) pushes past ~30 lines

## Rules

### 1. One responsibility

If a function performs step A then step B, and A and B are each independently meaningful, extract each into its own function (or collaborator) and let the caller sequence them.

```typescript
export const orderUseCase = {
  async place(params: { items: OrderItem[]; userId: string }): Promise<OrderModel> {
    const { items, userId } = params

    const validItems = orderService.filterOrderableItems({ items })
    return await new OrderRepo().create({ items: validItems, userId })
  },
}

export const orderService = {
  filterOrderableItems(params: { items: OrderItem[] }): OrderItem[] {
    const { items } = params

    return items.filter((item) => {
      return item.quantity > 0
    })
  },
}
```

### 2. Prefer early returns (guard clauses)

Return early for invalid states instead of nesting the happy path inside an `if`. Flat reads better than nested.

```typescript
export const userService = {
  resolveUser(params: { user?: UserModel }): UserModel {
    const { user } = params

    if (!user) {
      return constant.user.anonymous
    }

    if (!user.isActive) {
      return constant.user.inactive
    }

    return user
  },
}
```

### 3. Split into siblings or `protected _` helpers, never local functions

When a method grows, decompose it on the same class as `protected _` helpers, or split the responsibility into sibling public methods. Never add module-level or nested named functions:

```typescript
export class AccessService {
  isEditable(params: { user: UserModel; doc: DocumentModel }): boolean {
    const { user } = params

    if (user.isAdmin) {
      return true
    }

    return this._isOwner(params)
  }

  protected _isOwner(params: { user: UserModel; doc: DocumentModel }): boolean {
    const { user, doc } = params

    return doc.ownerId === user.id
  }
}
```

### 4. Extract "comment-worthy" blocks

Anywhere you feel the urge to write `// calculate the discount`, that is a signal to extract `calculateDiscount(...)` instead. The function name **is** the documentation.

### 5. Declarative length is not complexity

Long object-literal config is NOT counted as complexity; "one named thing" may legitimately be long if the length is declarative data, not branching. The etalon's largest function (98 lines, a container-dispatch use-case) is ~60% one declarative config object literal; logic nesting never exceeds 2 levels and it stays readable through:

- **Flat pipelines of named consts**: each step is `const x = await collaborator.step(...)` on one line of hierarchy
- **Guard clauses** up front
- **Delegation** to named collaborators
- **Logging call signs** replacing comments: `logger().debug('dispatchParseContainer - container created')` marks each step without violating the no-comment rule

Use-case methods are the longest in the business layer (avg 22.6) precisely because their bodies are flat named-step sequences; that length is legitimate.

## Common pitfalls

- ❌ Nested guards burying the happy path → ✅ early-return guard clauses
- ❌ One function that validates, transforms, persists, and notifies → ✅ split and sequence at the caller
- ❌ Module-level or nested helper functions next to an export → ✅ `protected _` methods on a class, or a sibling method, or an extracted collaborator class
- ❌ The `private` keyword → ✅ `protected` + single `_` prefix (the etalon has 0 uses of `private`)
- ❌ Counting a long config literal as complexity → ✅ judge branching and nesting, not data
- ❌ Extracting single-use functions with no clear name → ✅ keep them inline; extraction should improve naming, not just relocate lines

## Summary

- A function does **one named thing** - split when you need "and"
- **~30 lines is the practised ceiling**, 15 or fewer is the norm; declarative data does not count toward it
- The splitting move is **extract a named collaborator class and delegate**; within a class, `protected _` helpers
- **Early returns** over nesting; **logging call signs** over comments
- Let **signals** (nesting, "and", comment-worthiness), not line counts alone, decide
