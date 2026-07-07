# Function Size & Structure

## Overview

A function should do **one named thing**. If you need "and" to describe what a function does, it does more than one thing and should be split. This is the single most effective readability lever — more than comments (which are prohibited) or formatting.

The goal is not a hard line count. It is: each function reads top-to-bottom as one coherent operation, with no hidden responsibilities and no deeply nested branches.

## Signals a function is too big

Split when any of these appear:

- You describe the function with **"and"** ("it validates the input *and* saves it *and* sends an email" → three functions)
- It has **nested `if`** blocks more than two levels deep
- It has a **`switch` or `if/else` chain** where each branch is more than a few lines
- A block of lines would need a **comment** to explain it (comments are banned — extract a named function instead)
- It takes many **object params** because it orchestrates several distinct operations
- You have to scroll to hold the whole function in your head

## Rules

### 1. One responsibility

If a function performs step A then step B, and A and B are each independently meaningful, extract each into its own function and let the caller sequence them.

```typescript
export const orderUseCase = {
  async place(params: { items: OrderItem[]; userId: string }): Promise<Order> {
    const validated = this.validate({ items: params.items })
    const saved = await this.persist({ items: validated, userId: params.userId })
    return saved
  },

  validate(params: { items: OrderItem[] }): OrderItem[] {
    return params.items.filter((item) => item.quantity > 0)
  },

  async persist(params: { items: OrderItem[]; userId: string }): Promise<Order> {
    return await orderRepo.create({ items: params.items, userId: params.userId })
  },
}
```

### 2. Prefer early returns (guard clauses)

Return early for invalid states instead of nesting the happy path inside an `if`. Flat reads better than nested.

```typescript
export const userController = {
  resolve(params: { user?: User }): User {
    if (!params.user) {
      return anonymousUser
    }

    if (!params.user.isActive) {
      return inactiveUser
    }

    return params.user
  },
}
```

### 3. Extract nested conditionals into named helpers

When a conditional's intent is not obvious, move the condition (or each branch) into a named function or a well-named boolean. The name replaces the comment you would have written.

```typescript
export const accessService = {
  canEdit(params: { user: User; doc: Document }): boolean {
    return this.isOwner({ user: params.user, doc: params.doc }) || params.user.isAdmin
  },

  isOwner(params: { user: User; doc: Document }): boolean {
    return params.doc.ownerId === params.user.id
  },
}
```

### 4. Extract "comment-worthy" blocks

Anywhere you feel the urge to write `// calculate the discount`, that is a signal to extract `calculateDiscount(...)` instead. The function name **is** the documentation.

### 5. No hard limit, but watch the signals

There is no line-count ceiling. A function that does one thing may legitimately be long — a flat `switch` mapping every enum value, or a single linear transformation. Use the signals above, not a number, as your guide.

## Common pitfalls

- ❌ Nested guards burying the happy path → ✅ early-return guard clauses
- ❌ One function that validates, transforms, persists, and notifies → ✅ split and sequence at the caller
- ❌ Unnamed boolean expressions (`if (a && !b && (c || d))`) → ✅ extract a named helper or boolean
- ❌ Extracting single-use functions with no clear name → ✅ keep them inline; extraction should improve naming, not just relocate lines

## Summary

- A function does **one named thing** — split when you need "and".
- **Early returns** over nesting.
- **Extract** named helpers for complex conditions and comment-worthy blocks (the name replaces the banned comment).
- Let **signals**, not line counts, decide.
