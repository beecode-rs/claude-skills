# Component Layer (CompL)

## Purpose

The Component Layer encapsulates complex and reusable domain logic that doesn't fit cleanly into Services or Use Cases. It combines Use Case Layer rules (singleton objects with independent methods) for public interfaces with Service Layer flexibility (methods can reference each other) for private implementation.

## Component vs Service Decision

The boundary between Component and Service can be unclear. Use this decision tree to guide your choice:

### Decision Flowchart

```
Start: Need to implement business logic
  ↓
Do several files form a closed pattern (one main entry + multiple private strategies)?
  ├─ Yes → Use COMPONENT (one folder, only index.ts public — see "Strategy Pattern Component")
  └─ No
      ↓
      Does it have 3+ internal states/rules?
      ├─ No → Use SERVICE
      └─ Yes
          ↓
          Does it need state transition validation?
          ├─ No → Use SERVICE
          └─ Yes
              ↓
              Can it be self-contained (no external deps)?
              ├─ No → Use SERVICE or USE CASE
              └─ Yes
                  ↓
                  Need to hide complex implementation?
                  ├─ No → Use SERVICE
                  └─ Yes → Use COMPONENT
```

### Use COMPONENT when ALL of these are true:

1. **Complex Internal State** - Logic has 3+ internal states/rules/conditions
2. **State Validation** - State transitions have validation requirements
3. **Self-Contained** - Logic needs to be isolated with no external dependencies (ideally doesn't call other layers)
4. **Hidden Implementation** - You want to hide implementation details behind a clean public API
5. **Domain-Specific** - Logic is specific to a particular business domain concept

**Examples:**
- ✅ Invoice status machine (draft → created → submitted → approved)
- ✅ Order lifecycle manager (pending → processing → shipped → delivered)
- ✅ Document approval workflow
- ✅ Permission calculator with complex rules

### Use SERVICE when ANY of these are true:

1. **Single-Purpose** - Simple transformation or calculation
2. **External Dependencies** - Needs to call repositories or other services
3. **Reusable Logic** - Logic is reusable across different contexts
4. **No State Management** - No complex internal state transitions
5. **Stateless Operation** - Pure business logic without state

**Examples:**
- ✅ Calculate invoice total
- ✅ Format user address
- ✅ Validate email format
- ✅ Encrypt/decrypt secrets
- ✅ Generate report data

### Quick Comparison

| Scenario | Component or Service? | Reason |
|----------|----------------------|---------|
| Invoice status transitions (draft/submitted/approved) | **Component** | 3+ states, validation rules, state machine |
| Calculate tax on invoice | **Service** | Single calculation, no state |
| Order fulfillment workflow | **Component** | Multiple states, transition rules |
| Format address for display | **Service** | Simple transformation, stateless |
| Permission checker with role hierarchy | **Component** | Complex rules, multiple conditions |
| Encrypt/decrypt user data | **Service** | Stateless operation, reusable |
| Document approval chain | **Component** | State transitions, validation per state |
| Parse CSV file | **Service** | Single-purpose, no state management |

## When to Use Component Layer

Use the Component Layer when you need to:

- **Encapsulate a closed pattern implementation** — a main entry file plus multiple strategy/collaborator services where one thing is exposed and the rest are private (see "Strategy Pattern Component" below)
- **Encapsulate complex state transition logic** (e.g., invoice status workflows, order lifecycle)
- **Hide intricate business rules** that are too complex for a simple service method
- **Create modular, self-contained logic** that has strict internal rules
- **Expose a clean public API** while keeping complex implementation details private
- **Implement domain-specific validation or business rule engines**

## When NOT to Use

Avoid the Component Layer when:

- Logic can be a simple service method (use Service Layer instead)
- Orchestrating multiple services (use Use Case Layer instead)
- Logic needs to be reused across multiple components (use Service Layer instead)
- Simple CRUD operations (use Repository Layer instead)

## Architecture Position

```
Use Case → Component → Service → Repository → DAL → Entity
           └─────────> (can also call Repository directly)
```

**IMPORTANT RULES:**

- Components should ideally NOT use logic from other layers (RL, SL) to avoid creating tightly coupled code
- Components are self-contained and expose only what's necessary through public interfaces
- The internal complexity is hidden from consumers

## File Structure

```
src/
├── business/
│   ├── component/
│   │   └── invoice-status/
│   │       ├── rule/
│   │       │   ├── draft.ts
│   │       │   ├── created.ts
│   │       │   ├── submitted.ts
│   │       │   └── cancelled.ts
│   │       ├── index.ts        # Public API - exposed endpoints only
│   │       └── service.ts      # Private implementation - switches between rules
```

An alternative way to keep private files flat while still signaling privacy is to prefix them with a leading underscore instead of grouping them in a `rule/` subfolder:

```
src/business/component/todo-status/
├── _todo.ts            # private rule (todo)
├── _in-progress.ts     # private rule (in-progress)
├── _done.ts            # private rule (done)
├── _cancelled.ts       # private rule (cancelled)
├── index.ts            # Public API
└── service.ts          # Private implementation, imports the _ files
```

Both layouts are valid. Use a `rule/` subfolder when you want several private files grouped together; use the `_` prefix when you want flat files but still want to signal "do not import me from outside this folder".

## Naming Conventions

| Element | File Name | Export Pattern | Usage Example |
|---------|-----------|----------------|---------------|
| **Component** | `kebab-case/` (folder) | Via `index.ts` | `invoiceStatusComponent.canChangeTo()` |
| **Component Service** | `service.ts` | Not exported (private) | Internal use only |
| **Component Rules** | `_kebab-case.ts` (flat) or `rule/kebab-case.ts` (subfolder) | Not exported (private) | Internal use only |
| **Public API** | `index.ts` | `camelCase` singleton object | `invoiceStatusComponent` |

## Pattern

### 1. Public Interface (index.ts)

The public interface exposes only the necessary functions as a singleton object, following Use Case Layer rules.

```typescript
// src/business/component/invoice-status/index.ts
import type { Invoice } from '#src/dal/typeorm/entity/invoice-entity'
import { InvoiceStatusService } from './service'

/**
 * Invoice status component - encapsulates status transition rules
 */
export const invoiceStatusComponent = {
  /**
   * Check if invoice can change to a new status
   */
  canChangeTo(params: { invoice: Invoice; newStatus: string }): boolean {
    const service = new InvoiceStatusService()
    return service.canChangeTo(params)
  },

  /**
   * Get allowed next statuses for an invoice
   */
  getAllowedNextStatuses(invoice: Invoice): string[] {
    const service = new InvoiceStatusService()
    return service.getAllowedNextStatuses(invoice)
  },

  /**
   * Validate status transition and throw if invalid
   */
  validateStatusChange(params: { invoice: Invoice; newStatus: string }): void {
    const service = new InvoiceStatusService()
    service.validateStatusChange(params)
  },
}
```

### 2. Private Service (service.ts)

The service implements the complex logic, using private methods that can reference each other via `this`.

```typescript
// src/business/component/invoice-status/service.ts
import type { Invoice } from '#src/dal/typeorm/entity/invoice-entity'
import { draftRule } from './rule/draft'
import { createdRule } from './rule/created'
import { submittedRule } from './rule/submitted'
import { cancelledRule } from './rule/cancelled'

const INVOICE_STATUS = {
  DRAFT: 'DRAFT',
  CREATED: 'CREATED',
  SUBMITTED: 'SUBMITTED',
  CANCELLED: 'CANCELLED',
} as const

type InvoiceStatus = typeof INVOICE_STATUS[keyof typeof INVOICE_STATUS]

interface IStatusRule {
  canChangeTo(newStatus: string, invoice: Invoice): boolean
  getAllowedNextStatuses(invoice: Invoice): string[]
}

export class InvoiceStatusService {
  /**
   * Check if invoice can change to a new status
   */
  canChangeTo(params: { invoice: Invoice; newStatus: string }): boolean {
    const { invoice, newStatus } = params
    const rule = this.getRuleForStatus(invoice.status)
    return rule.canChangeTo(newStatus, invoice)
  }

  /**
   * Get allowed next statuses for an invoice
   */
  getAllowedNextStatuses(invoice: Invoice): string[] {
    const rule = this.getRuleForStatus(invoice.status)
    return rule.getAllowedNextStatuses(invoice)
  }

  /**
   * Validate status transition and throw if invalid
   */
  validateStatusChange(params: { invoice: Invoice; newStatus: string }): void {
    const { invoice, newStatus } = params

    if (!this.canChangeTo(params)) {
      const allowed = this.getAllowedNextStatuses(invoice)
      throw new Error(
        `Cannot change invoice status from ${invoice.status} to ${newStatus}. ` +
        `Allowed transitions: ${allowed.join(', ')}`
      )
    }
  }

  /**
   * Get the status rule handler for a given status
   * @private
   */
  private getRuleForStatus(status: string): IStatusRule {
    switch (status) {
      case INVOICE_STATUS.DRAFT:
        return draftRule
      case INVOICE_STATUS.CREATED:
        return createdRule
      case INVOICE_STATUS.SUBMITTED:
        return submittedRule
      case INVOICE_STATUS.CANCELLED:
        return cancelledRule
      default:
        throw new Error(`Unknown invoice status: ${status}`)
    }
  }
}
```

### 3. Private Rules (rule/*.ts)

Each rule implements the specific transition logic for a status. These are singleton objects that are not exported from the component.

An alternative to the `rule/` subfolder is to keep the rule files flat in the component folder and mark them private with a leading underscore instead (for example `_draft.ts`, `_created.ts`). The leading `_` signals "private to this folder", so `service.ts` then imports `./_draft.js`, `./_created.js`, and so on, and nothing outside the component ever imports them. Both approaches are valid; pick whichever reads best for the number of rules you have.

```typescript
// src/business/component/invoice-status/rule/draft.ts
import type { Invoice } from '#src/dal/typeorm/entity/invoice-entity'

const INVOICE_STATUS = {
  DRAFT: 'DRAFT',
  CREATED: 'CREATED',
  CANCELLED: 'CANCELLED',
} as const

/**
 * Rules for DRAFT status invoices
 * @private - Not exported from component
 */
export const draftRule = {
  canChangeTo(newStatus: string, invoice: Invoice): boolean {
    // Draft can only go to CREATED or CANCELLED
    return [INVOICE_STATUS.CREATED, INVOICE_STATUS.CANCELLED].includes(newStatus as any)
  },

  getAllowedNextStatuses(invoice: Invoice): string[] {
    return [INVOICE_STATUS.CREATED, INVOICE_STATUS.CANCELLED]
  },
}
```

```typescript
// src/business/component/invoice-status/rule/created.ts
import type { Invoice } from '#src/dal/typeorm/entity/invoice-entity'

const INVOICE_STATUS = {
  SUBMITTED: 'SUBMITTED',
  CANCELLED: 'CANCELLED',
} as const

/**
 * Rules for CREATED status invoices
 * @private - Not exported from component
 */
export const createdRule = {
  canChangeTo(newStatus: string, invoice: Invoice): boolean {
    // Created can go to SUBMITTED or CANCELLED
    return [INVOICE_STATUS.SUBMITTED, INVOICE_STATUS.CANCELLED].includes(newStatus as any)
  },

  getAllowedNextStatuses(invoice: Invoice): string[] {
    return [INVOICE_STATUS.SUBMITTED, INVOICE_STATUS.CANCELLED]
  },
}
```

```typescript
// src/business/component/invoice-status/rule/submitted.ts
import type { Invoice } from '#src/dal/typeorm/entity/invoice-entity'

/**
 * Rules for SUBMITTED status invoices
 * @private - Not exported from component
 */
export const submittedRule = {
  canChangeTo(newStatus: string, invoice: Invoice): boolean {
    // Submitted is a terminal state - no transitions allowed
    return false
  },

  getAllowedNextStatuses(invoice: Invoice): string[] {
    return []
  },
}
```

```typescript
// src/business/component/invoice-status/rule/cancelled.ts
import type { Invoice } from '#src/dal/typeorm/entity/invoice-entity'

/**
 * Rules for CANCELLED status invoices
 * @private - Not exported from component
 */
export const cancelledRule = {
  canChangeTo(newStatus: string, invoice: Invoice): boolean {
    // Cancelled is a terminal state - no transitions allowed
    return false
  },

  getAllowedNextStatuses(invoice: Invoice): string[] {
    return []
  },
}
```

## Usage Example

### From Use Case

```typescript
// src/business/use-case/invoice-use-case.ts
import { invoiceStatusComponent } from '#src/business/component/invoice-status'
import { InvoiceRepo } from '#src/business/repo/invoice-repo'

export const invoiceUseCase = {
  async updateInvoiceStatus(params: {
    invoiceId: string
    newStatus: string
    ownerId: string
  }): Promise<void> {
    const { invoiceId, newStatus, ownerId } = params

    // Get invoice
    const invoiceRepo = new InvoiceRepo()
    const invoice = await invoiceRepo.findByIdOrThrow({ id: invoiceId, ownerId })

    // Validate status change using component
    invoiceStatusComponent.validateStatusChange({ invoice, newStatus })

    // Update status
    invoice.status = newStatus
    await invoiceRepo.update({ id: invoiceId, ownerId, data: invoice })
  },

  async getAvailableStatusTransitions(params: {
    invoiceId: string
    ownerId: string
  }): Promise<string[]> {
    const { invoiceId, ownerId } = params

    const invoiceRepo = new InvoiceRepo()
    const invoice = await invoiceRepo.findByIdOrThrow({ id: invoiceId, ownerId })

    // Get allowed transitions from component
    return invoiceStatusComponent.getAllowedNextStatuses(invoice)
  },
}
```

### From Service

```typescript
// src/business/service/invoice-service.ts
import { invoiceStatusComponent } from '#src/business/component/invoice-status'
import type { Invoice } from '#src/dal/typeorm/entity/invoice-entity'

export const invoiceService = {
  canSubmitInvoice(invoice: Invoice): boolean {
    return invoiceStatusComponent.canChangeTo({
      invoice,
      newStatus: 'SUBMITTED',
    })
  },
}
```

## Key Principles

### 1. Encapsulation

The component hides all internal complexity. Consumers only see the public interface in `index.ts`.

```typescript
// ✅ GOOD - Using public interface
import { invoiceStatusComponent } from '#src/business/component/invoice-status'

const canChange = invoiceStatusComponent.canChangeTo({ invoice, newStatus: 'SUBMITTED' })
```

```typescript
// ❌ BAD - Accessing internal implementation
import { InvoiceStatusService } from '#src/business/component/invoice-status/service'

const service = new InvoiceStatusService() // Don't access private service directly
```

### 2. Self-Contained Logic

Components should ideally not depend on other layers (Services, Repositories) to avoid creating tightly coupled spaghetti code.

```typescript
// ✅ GOOD - Self-contained logic
export const orderStatusComponent = {
  canChangeTo(params: { order: Order; newStatus: string }): boolean {
    // All logic is self-contained within the component
    const rule = getRuleForStatus(order.status)
    return rule.canChangeTo(newStatus, order)
  },
}
```

```typescript
// ❌ BAD - Depending on services and repositories
export const orderStatusComponent = {
  async canChangeTo(params: { orderId: string; newStatus: string }): Promise<boolean> {
    // Don't fetch data from repositories
    const orderRepo = new OrderRepo()
    const order = await orderRepo.findById({ id: params.orderId })

    // Don't call services
    const validated = await orderService.validateOrder(order)

    return validated
  },
}
```

### 3. Public vs Private

- **Public (index.ts)**: Singleton object with independent methods (UCL rules)
- **Private (service.ts)**: Class with methods that can reference each other via `this` (SL rules)
- **Private (rules)**: Singleton objects implementing specific business rules

### 4. Modularity

Each component should focus on ONE domain concept (e.g., invoice status, order lifecycle, payment workflow).

## Common Patterns

### Strategy Pattern Component

When a few files together form a pattern implementation (strategy pattern, chain of responsibility, rule engine — any pattern of this shape), the **whole bunch lives in ONE folder** in the component layer. The nature of such patterns is that exactly one thing is exposed (the main entry) and the other things are private, not accessible from outside — which is the component layer's encapsulation contract, so the file structure must mirror it:

```
src/business/component/text-formatting/
├── _json.ts              # private strategy (leading `_` = never imported outside this folder)
├── _simple-string.ts     # private strategy
├── service.ts            # private implementation — selects/switches between the strategies
└── index.ts              # the ONLY public entry point
```

An alternative to `_`-prefixed flat files is a `strategy/` subfolder, exactly like the `rule/` subfolder alternative described above.

**Rules:**
- Entry, all strategy files, and the tightly-coupled shared interface go in the same component folder — never split across layers or folders
- Only `index.ts` is public; strategy files must never be imported from outside the component
- If each strategy is meant to be independently picked by outside callers, it is NOT a closed pattern — use an open subfolder grouping in `src/business/service/` instead (see [file-organization-pattern.md](../file-organization-pattern.md))

```typescript
// src/business/component/text-formatting/index.ts — the ONLY public file
import { textFormattingService } from './service'

export const textFormattingComponent = {
  format(params: { value: string }): string {
    return textFormattingService.format(params)
  },
}
```

### State Machine Component

```typescript
// src/business/component/order-lifecycle/index.ts
export const orderLifecycleComponent = {
  canTransitionTo(params: { order: Order; newState: string }): boolean { },
  getNextStates(order: Order): string[] { },
  validateTransition(params: { order: Order; newState: string }): void { },
}
```

### Validation Engine Component

```typescript
// src/business/component/payment-validator/index.ts
export const paymentValidatorComponent = {
  validateAmount(params: { payment: Payment }): ValidationResult { },
  validatePaymentMethod(params: { payment: Payment }): ValidationResult { },
  validateAll(payment: Payment): ValidationResult { },
}
```

### Business Rule Component

```typescript
// src/business/component/pricing-rules/index.ts
export const pricingRulesComponent = {
  calculateDiscount(params: { order: Order; customer: Customer }): number { },
  applyPromotions(params: { order: Order; promotions: string[] }): Order { },
  validatePricing(order: Order): boolean { },
}
```

## Best Practices

1. **Keep it focused**: One component = one domain concept
2. **Hide complexity**: Only expose what's necessary through `index.ts`
3. **Avoid dependencies**: Don't call other services or repositories when possible
4. **Use singleton objects for public API**: Follow UCL rules for exposed methods
5. **Use classes for private implementation**: Use SL rules when methods need to reference each other
6. **Document the domain logic**: Complex rules deserve clear comments
7. **Make it modular**: Components should be self-contained and reusable

## Common Pitfalls

- **Over-using components**: Not everything needs a component. Simple logic belongs in services
- **Creating dependencies**: Don't make components call other services/repos (creates tight coupling)
- **Exposing internals**: Never export the service class or rule objects
- **Making it async unnecessarily**: Components should generally work with data passed to them, not fetch data
- **Mixing concerns**: Keep each component focused on a single domain concept
