---
name: writing-tech-specs
description: Generate lightweight technical specification documents with PlantUML diagrams. Use this skill whenever the user asks to design a feature, plan an implementation, document architecture changes, specify database schema changes, describe API endpoints, or needs to capture WHAT changes across services - even if they don't explicitly say "tech spec" or "specification".
allowed-tools: Read, Write
model: sonnet
---

# Writing Tech Specs

## Purpose

Generate **lightweight, concise** technical specification documents that describe WHAT changes - using PlantUML diagrams and brief descriptions. These specs focus on the changes being made, not implementation details.

## When to Use

- User requests "tech spec", "technical specification", "tech-spec"
- User mentions "create spec", "write spec", "implementation spec"
- User wants to document feature changes before implementation
- User needs to communicate design decisions across a team

## Process

### 1. Gather Requirements

Ask the user for the essential details. If they don't know something, help them work through it:

- **Feature/Task title**: What is being built or changed?
- **Scope**: What services are affected? (node-core, node-auth, frontend, etc.)
- **Key changes**:
  - New or modified API endpoints
  - Database schema changes (new tables, columns)
  - New or changed business flows
  - Frontend changes (screens, components)

### 2. Generate Spec Structure

Use this template structure:

```markdown
# [tech-spec] <Title>

* 1 [Infrastructure](#Infrastructure)
  * 1.1 [<service-name>](#<service-name>)
* 2 [Model](#Model)
  * 2.1 [<service-name>](#<service-name>)
    * 2.1.1 [<EntityName>](#<EntityName>)
* 3 [Flow](#Flow)
  * 3.1 [Backend](#Backend)
    * 3.1.1 [<service-name>](#<service-name>)
* 4 [Happy path](#Happy-path)
* 5 [Backwards compatibility](#Backwards-compatibility)

# Infrastructure

## <service-name>

<API endpoints, permissions, cron jobs>

# Model

## <service-name>

### <EntityName>

<PlantUML class diagram in code block>

# Flow

## Backend

### <service-name>

<PlantUML activity/sequence diagram in code block>

# Happy path

<Brief description or test scenarios>

# Backwards compatibility

<Notes if applicable, omit if not needed>
```

### 3. Write Sections

#### Infrastructure Section

List API endpoints with brief details:

```markdown
* POST /users/me/terms-and-conditions/latest/accept
  * response `{"successful": true}`
```

Or with body:

```markdown
* PATCH /tenant-benefits/:tenantBenefitId/order
  * body: { direction: up/down }
```

#### Model Section

Use **PlantUML class diagrams in code blocks**. Use `...` for existing unchanged fields:

```markdown
### Appointment

```
@startuml
class Appointment {
  ...
  status: string [enum: scheduled, in_progress, completed]
}
@enduml
```
```

For new tables, list all fields:

```markdown
### IntegrationMapping (new table)

```
@startuml
class IntegrationMapping {
  id: uuid
  integrationSystem: enum
  type: string
  key: string
  value: string
}
@enduml
```
```

#### Flow Section

Use **PlantUML activity diagrams in code blocks** for backend flows:

```markdown
### Claim item correct/incorrect flow

```
@startuml
(*) --> "Claim Submitted for Review" #lightblue
if "Is correct?" then
  --> [Yes] "Update correct fields"
  --> (*)
else
  --> [No] "Update incorrect fields"
  --> "Returned to Patient" #lightblue
  --> (*)
@enduml
```
```

Use sequence diagrams for cross-service communication:

```markdown
```
@startuml
actor "User" as user
participant "Service A" as a
participant "Service B" as b
user -> a: Request
a -> b: Call
b --> a: Response
a --> user: Result
@enduml
```
```

#### Happy Path Section

Brief description or test scenarios:

```markdown
Check that the user cannot use the app if he doesn't accept the latest T&C.
After accepting, the user should be able to use the app with no restrictions.
```

Or bullet points:

```markdown
* Check if an appointment can be flagged for did-not-attend successfully.
* Verify that an error is thrown when trying to flag a cancelled appointment.
```

#### Backwards Compatibility Section

Only include if needed. Keep brief:

```markdown
Migration: Create repository records from unique combinations, then add FK.
```

### 4. Save and Output

- Create the directory if needed: `mkdir -p resource/tech-spec`
- Write to `resource/tech-spec/<tech-spec-title>.md` (use kebab-case)
- Return the file path to the user

## Critical Rules

These rules keep specs focused and readable:

1. **NO file structure comparisons** - Specs describe what changes, not where files live
2. **NO file mapping tables** - That's implementation detail, not specification
3. **NO import update strategies** - That belongs in the implementation, not the spec
4. **NO code examples** - PlantUML diagrams are more universal and less language-specific
5. **NO checklists** - That's for tasks/stories; specs describe the system state
6. **NO step-by-step implementation instructions** - Specs describe WHAT, not HOW
7. **Keep it brief** - 1-2 sentences per item; use diagrams for complex flows
8. **Use code blocks for PlantUML** - Better readability and formatting

## Scope Guidance

If the spec becomes too large, consider splitting:

- More than 3 services affected? Consider separate specs per service
- More than 8 model changes? Consider splitting by domain
- More than 4 complex flows? Consider splitting by user journey

## Examples

### Minimal Spec

```markdown
# [tech-spec] Custom order for tenant benefits

* 1 [Infrastructure](#Infrastructure)
  * 1.1 [node-core](#node-core)
* 2 [Model](#Model)
  * 2.1 [node-core](#node-core.1)

# Infrastructure

## node-core

* PATCH /tenant-benefits/:tenantBenefitId/order
  * body: { direction: up/down }

# Model

## node-core

```
@startuml
class TenantBenefit {
  ...
  order: number
}
@enduml
```
```

### Spec with Flow

```markdown
# [tech-spec] Claim item locking

* 1 [Model](#Model)
  * 1.1 [node-core](#node-core)
* 2 [Flow](#Flow)
  * 2.1 [Backend](#Backend)
* 3 [Happy path](#Happy-path)

# Model

## node-core

### ReimbursementClaimItem

```
@startuml
class ReimbursementClaimItem {
  ...
  incorrectAt?: number
  incorrectById?: string
  incorrectReason?: string
  correctAt?: number
  correctById?: string
}
@enduml
```

# Flow

## Backend

### Claim item correct/incorrect flow

```
@startuml
(*) --> "Claim Submitted for Review" #lightblue
if "Is correct?" then
  --> [Yes] "Update correct fields"
  --> (*)
else
  --> [No] "Update incorrect fields"
  --> "Returned to Patient" #lightblue
  --> (*)
@enduml
```

# Happy path

Advisor marks claim items as correct/incorrect. Patient sees which items need correction.
```

## Section Reference

| Section | When to Include | Content |
|---------|-----------------|---------|
| Infrastructure | New/changed endpoints, crons, permissions | Brief API listing |
| Model | Database schema changes | PlantUML class diagrams |
| Flow | New or changed business logic | PlantUML activity/sequence diagrams |
| Happy path | Always | Brief description or test scenarios |
| Backwards compatibility | Breaking changes | Migration notes |
| Deployment | Special deployment needs | Only if necessary |

## More Examples

See `./examples` folder for complete reference specs covering:
- API design patterns
- Cross-service communication
- Complex state machines
- Frontend flows
