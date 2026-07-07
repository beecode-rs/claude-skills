---
name: planning-stories
description: "Break down a user story into multiple testable tasks. Use when user mentions: story, ticket, task breakdown, implement feature, plan implementation, create tasks, split into tasks, story breakdown, task decomposition, acceptance criteria, definition of done, sprint planning, backlog, user story, feature breakdown, ralph, ralph loop, autonomous implementation, .TASK.md, progress.txt, run through ralph. Each task must be independently verifiable. NOTE: Ralph-loop task files (.TASK.md) are generated ONLY when explicitly requested — never automatically during normal story creation."
allowed-tools: Read, Write, Grep, Glob, Task, AskUserQuestion

---

# Planning Stories

Break down user stories into independently testable tasks. Each task is a small, verifiable unit of work that, when completed, contributes to the overall story completion.

---

## ⚠️ Two Modes — Read This First

This skill operates in **two modes**. Know which one you are in before doing anything.

### 1. Default — Story Planning (what normally happens)

Produces a **`STORY.<name>.md`** planning file (and, optionally, a `STORY.<name>.TECH-SPEC.md`). This is the planning artifact a human reads. It is **not** executed autonomously. This is the mode used whenever the user asks to plan, break down, or decompose a story.

### 2. Explicit Only — Ralph Task Generation

Produces **Ralph-loop files** (`<task-name>.TASK.md` + `<task-name>.progress.txt`) that the `ralph.sh` script runs autonomously, one story per iteration.

### CRITICAL RULE

**Never generate Ralph task files unless the user EXPLICITLY asks.** Trigger only on direct requests such as:

- "break this into Ralph tasks"
- "generate the .TASK.md files"
- "make this runnable by Ralph" / "run this through ralph"
- "create a task breakdown for the ralph loop"

During normal story creation, **do NOT** emit `.TASK.md` / `.progress.txt` files. Producing `STORY.<name>.md` planning tasks (Step 1–5 below) is fine and expected — that is planning, not Ralph execution.

When mode 2 is explicitly requested, follow the full workflow in [ralph-tasks.md](ralph-tasks.md).

---

## The Job

**Default mode (story planning):**

1. Receive a story description from the user
2. Ask clarifying questions if needed
3. Break down the story into small, testable tasks
4. Save to `STORY.<name>.md`
5. **Spawn a writing-tech-specs subagent** to create `STORY.<name>.TECH-SPEC.md`

**Ralph mode (explicit only):** Follow [ralph-tasks.md](ralph-tasks.md) — generate `<task-name>.TASK.md` + `<task-name>.progress.txt` next to the story file. Do not enter this mode unless explicitly requested (see the CRITICAL RULE above).

---

## Core Principles

### Task Independence

Each task must be:

- **Completable in isolation** - no dependencies on incomplete tasks
- **Testable** - has clear verification criteria
- **Non-breaking** - app continues to work after each task
- **Small** - completable in one context window (~10 min of AI work)

### Task Ordering (Critical)

**ALWAYS order by dependency to avoid breaking changes:**

1. **Database/Schema changes** - migrations, new columns, new tables
2. **Backend/Repository layer** - data access, queries, mutations
3. **API/Service layer** - endpoints, business logic
4. **Frontend/UI** - components, screens, forms

**Wrong order causes broken builds!**

---

## Step 1: Analyze the Story

Understand what the user is asking for:

- **New feature**: Adding new functionality
- **Update/Modify**: Changing existing behavior
- **Bug fix**: Correcting incorrect behavior
- **Refactor**: Improving code without changing behavior

### Ask Clarifying Questions If:

- Scope is unclear
- Multiple interpretations possible
- Breaking change risk exists
- Testing strategy is ambiguous

### Example Clarifying Questions

```
- "What should happen when [edge case]?"
- "Is this a breaking change, or should existing behavior still work?"
- "Are there any constraints on [field/feature]?"
- "Should this work for all users or just [specific role]?"
- "What's the rollback strategy if something goes wrong?"
```

---

## Step 2: Break Down Into Tasks

See [examples.md](examples.md) for detailed breakdown patterns.

### Quick Reference

| Story Type | Task Order |
|------------|------------|
| New field | DB → Repository → API → Frontend |
| Update field | Add parallel → Backend → Frontend → Remove old |
| New entity | DB → Repository → API → List UI → Detail UI |
| Bug fix | Identify cause → Add test → Fix → Verify |

---

## Step 3: Define Verification Criteria

Each task MUST have testable verification criteria.

### Good Criteria (Verifiable)

```markdown
- [ ] Migration runs successfully
- [ ] Unit test: new column exists with correct type
- [ ] Typecheck passes
- [ ] App starts without errors
```

### Bad Criteria (Vague)

```markdown
- [ ] Works correctly
- [ ] User can see the change
- [ ] Good UX
```

### Required Criteria for Every Task

```markdown
- [ ] Typecheck passes
- [ ] All tests pass
- [ ] App runs without errors
```

### BDD Format (Optional, for complex flows)

```markdown
Given [context]
When [action]
Then [expected result]
```

---

## Step 4: Generate STORY.<name>.md

### File Naming

- Use uppercase STORY prefix with kebab-case name: `STORY.add-user-profile-picture.md`
- Remove articles: "the", "a", "an"
- Be descriptive but concise

### Template Structure

```markdown
# Story: [Title]

## Overview

[Brief description of what this story accomplishes]

## Dependencies

- [List any existing features/systems this depends on]
- [None if standalone]

---

## Tasks

### Task 1: [Title]

**Layer:** database | backend | api | frontend | cleanup

**Description:**
[What this task does]

**Changes:**
- [Specific file/table/function being changed]

**Verification:**
- [ ] [Specific testable criterion]
- [ ] Typecheck passes
- [ ] All tests pass
- [ ] App runs without errors

---

### Task 2: [Title]

[Same structure as Task 1]

---

## Completion Criteria

The story is complete when:

- [ ] All tasks are verified complete
- [ ] End-to-end flow works as expected
- [ ] No breaking changes to existing functionality

## Rollback Plan

[If something goes wrong, how to revert]

---

## Notes

[Any additional context, assumptions, or decisions made]
```

---

## Step 5: Spawn a writing-tech-specs subagent

After creating `STORY.<name>.md`, spawn a subagent to create the technical specification.

### Subagent Prompt Template

```
Read the file STORY.<name>.md and use the writing-tech-specs skill to create a detailed technical specification.

The tech-spec should include:
1. Model changes (database schema)
2. Flow diagrams (backend/frontend flows)
3. API endpoints
4. Happy path description
5. Backwards compatibility notes

Save the output to STORY.<name>.TECH-SPEC.md
```

**Note:** The tech-spec file uses the same `<name>` as the story file with `.TECH-SPEC.md` appended. For example, if the story is `STORY.add-user-auth.md`, the tech-spec becomes `STORY.add-user-auth.TECH-SPEC.md`.

**Note:** If the writing-tech-specs skill is not available, skip this step and note it in the story file.

---

## Step 6 (OPTIONAL — Explicit Only): Generate Ralph Task Files

**Only perform this step if the user explicitly asks for Ralph-loop task files.** If they did not, stop here — the story planning is complete.

When explicitly requested, switch to the Ralph workflow documented in [ralph-tasks.md](ralph-tasks.md) and generate:

- `<task-name>.TASK.md` — the task breakdown document
- `<task-name>.progress.txt` — empty progress tracking file

Both files are created next to the story file by default, and `<task-name>` must follow the `task-<number>-<description>` naming convention (e.g. `task-1-add-currency-table.TASK.md`). The user then runs `ralph.sh <task-name>.TASK.md` to execute.

**Reminder:** This step is opt-in. Never produce these files during ordinary story planning.

---

## When NOT to Break Down

A story is already a good single task if:

- Single file/component change
- No database changes
- No API changes
- Completable in <30 minutes
- Has only one verification path

In this case, just create the story file without breaking into subtasks.

---

## Anti-Patterns to Avoid

| Anti-Pattern | Problem |
|--------------|---------|
| Too granular | "Create file", "Add import" - not real tasks |
| Too broad | "Implement feature" - can't verify in one sitting |
| Mixed layers | Database + frontend in same task |
| Vague verification | "Works correctly" - how do you know? |
| Missing rollback | No way to undo a database migration |
| Forward dependencies | Task 2 depends on Task 5 |

---

## Common Patterns

See [patterns.md](patterns.md) for detailed patterns:

- Adding a New Field
- Updating an Existing Field
- Adding a New Entity
- Adding a New Relationship

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Story seems too large | Break into smaller subtasks, or split into multiple stories |
| Breaking change detected | Add parallel field/endpoint first, update frontend, then remove old |
| Unclear testing strategy | Ask user for clarification, add manual verification steps |

---

## Checklist Before Saving

- [ ] Story is broken into small, testable tasks
- [ ] Each task has clear layer (database/backend/api/frontend)
- [ ] Tasks are ordered by dependency (no forward dependencies)
- [ ] Each task has specific verification criteria
- [ ] Every task includes typecheck, tests, and app runs checks
- [ ] Breaking changes use parallel fields or phased rollout
- [ ] Completion criteria covers the full story
- [ ] Rollback plan exists
- [ ] File is named `STORY.<name>.md`
- [ ] Did **NOT** generate Ralph `.TASK.md` / `.progress.txt` files (unless the user explicitly asked for them)
