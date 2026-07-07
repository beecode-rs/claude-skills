# Ralph Task Generation (Explicit Mode)

> **This is an OPTIONAL mode of the `planning-stories` skill.** It is invoked **only when the user explicitly asks** to generate files for the Ralph loop — e.g. *"break this into Ralph tasks"*, *"generate the .TASK.md files"*, *"make this runnable by Ralph"*, *"run this through ralph"*.
>
> During normal story creation, **do NOT** use this mode. The default `planning-stories` workflow produces `STORY.<name>.md` planning files; it never silently emits Ralph task files. See the **⚠️ Two Modes** section in [SKILL.md](SKILL.md).

Create detailed task documents that are clear, actionable, and suitable for autonomous AI implementation via the Ralph loop.

---

## About the Ralph Loop

The Ralph loop (`ralph.sh`) is an autonomous implementation process where:

- Each user story spawns a fresh AI instance with no memory of previous work
- Stories execute sequentially, one per iteration
- The AI reads the task file, implements the story, verifies acceptance criteria, and commits

This means stories must be **small enough to complete in one context window** (~10 min of AI work) and **ordered by dependency** so earlier work doesn't rely on later work.

**Invocation:** The user runs the script against a generated task file:

```bash
ralph.sh <task-name>.TASK.md [max-iterations] [sleep-seconds]
# Example: ralph.sh task-1-add-currency-table.TASK.md 50 3
```

The script **requires** the file to end in `.TASK.md`, and auto-derives a sibling `<task-name>.progress.txt` from the same base name in the same directory. So both files below must be created together, in the same location.

---

## Output Files

This mode creates TWO files:

1. **`<task-name>.TASK.md`** - The task breakdown document
2. **`<task-name>.progress.txt`** - Empty progress tracking file

### File Naming Convention

**The task name MUST include a short descriptive identifier.** Do not use only a number.

| Format | Status | Example |
|--------|--------|---------|
| `task-<number>-<description>.TASK.md` | ✅ **PREFERRED** | `task-1-add-currency-table.TASK.md` |
| `<description>.TASK.md` | ⚠️ Acceptable | `user-authentication.TASK.md` |
| `task-<number>.TASK.md` | ❌ NOT allowed | `task-1.TASK.md` |

**Prefer the numbered format** (`task-<number>-<description>`) as it:
- Maintains clear execution order when multiple tasks exist
- Makes it easy to see task sequence at a glance
- Helps avoid naming conflicts

The description should be:
- Short (2-4 words)
- Kebab-case (lowercase with hyphens)
- Descriptive of what the task accomplishes

**Good examples:**
- `task-1-setup-database.TASK.md` (preferred)
- `task-2-add-login-form.TASK.md` (preferred)
- `task-3-implement-search.TASK.md` (preferred)
- `user-authentication.TASK.md` (acceptable)

**Bad examples:**
- `task-1.TASK.md` (no description - NOT allowed)
- `task-2-new.TASK.md` (too vague)
- `Task-3-Authentication.TASK.md` (wrong case)

**Default Location Rule:** Both files MUST be created in the **same directory as the story file** that the task is based on, unless the user explicitly instructs a different location.

If no story file is present or identifiable, ask the user where to save the files.

---

## The Job

1. Ask for the **task name** (used for file naming: `<task-name>.TASK.md`)
2. Ask for the **output directory** (where to save files)
3. Receive a feature description from the user
4. Use the AskUserQuestion tool to ask 3–5 essential clarifying questions
5. Generate a structured task document based on answers
6. Save both files

---

## CRITICAL RULES - READ FIRST

**This mode is READ-ONLY except for two files:**

1. **CREATE** `<task-name>.TASK.md` - The task breakdown document
2. **CREATE** `<task-name>.progress.txt` - Empty progress tracking file

**File Location Rule:**
- Both files MUST be created **next to the story file** by default
- Only use a different location if the user explicitly instructs otherwise
- If no story file is present, ask the user where to save the files

**ABSOLUTELY DO NOT:**

- Modify any existing files in the codebase
- Create any files other than the .TASK.md and .progress.txt files
- Start implementing the feature
- Write any code, migrations, or tests
- Create directories, components, or services
- Run any build, test, or typecheck commands

**Your ONLY job is to plan. Implementation is handled by the Ralph loop.**

---

## Step 1: Gather Task Info

First, ask the user:

1. **Task name** - A short identifier for file naming
   - **PREFERRED format:** `task-<number>-<description>` (e.g., "task-1-user-auth", "task-2-add-login-form")
   - Acceptable: just `<description>` (e.g., "dashboard-metrics")
   - This becomes `<task-name>.TASK.md` and `<task-name>.progress.txt`
   - **MUST include a descriptive name** - see File Naming Convention above
   - Do NOT accept names like `task-1` alone - require `task-1-add-currency-table` format
2. **Output directory** - Where to save the files
   - **DEFAULT:** Same directory as the story file (if one exists)
   - Only ask for a different location if no story file is present or the user wants to override the default

---

## Step 2: Clarifying Questions

Ask only critical questions where the initial prompt is ambiguous. Focus on:

- **Problem/Goal:** What problem does this solve?
- **Core Functionality:** What are the key actions?
- **Scope/Boundaries:** What should it NOT do?
- **Success Criteria:** How do we know it's done?

### Format Questions Like This:

```
1. What is the primary goal of this feature?
   A. Improve user onboarding experience
   B. Increase user retention
   C. Reduce support burden
   D. Other: [please specify]

2. Who is the target user?
   A. New users only
   B. Existing users only
   C. All users
   D. Admin users only

3. What is the scope?
   A. Minimal viable version
   B. Full-featured implementation
   C. Just the backend/API
   D. Just the UI
```

---

## Step 3: Story Sizing (THE NUMBER ONE RULE)

**Each story must be completable in ONE context window (~10 min of AI work).**

Ralph spawns a fresh instance per iteration with no memory of previous work. If a story is too big, the AI runs out of context before finishing and produces broken code.

### Right-sized stories:

- Add a database column and migration
- Add a single UI component to an existing page
- Update a server action with new logic
- Add a filter dropdown to a list

### Too big (MUST split):

| Too Big               | Split Into                                         |
| --------------------- | -------------------------------------------------- |
| "Build the dashboard" | Schema, queries, UI components, filters            |
| "Add authentication"  | Schema, middleware, login UI, session handling     |
| "Add drag and drop"   | Drag events, drop zones, state update, persistence |
| "Refactor the API"    | One story per endpoint or pattern                  |

**Rule of thumb:** If you cannot describe the change in 2-3 sentences, it is too big.

---

## Step 4: Story Ordering (Dependencies First)

Stories execute in priority order. Earlier stories must NOT depend on later ones.

**Correct order:**

1. Schema/database changes (migrations)
2. Server actions / backend logic
3. UI components that use the backend
4. Dashboard/summary views that aggregate data

**Wrong order:**

```
US-001: UI component (depends on schema that doesn't exist yet!)
US-002: Schema change
```

---

## Step 5: Acceptance Criteria (Must Be Verifiable)

Each criterion must be something Ralph can CHECK, not something vague.

### Good criteria (verifiable):

- "Add `status` column to tasks table with default 'pending'"
- "Filter dropdown has options: All, Active, Completed"
- "Clicking delete shows confirmation dialog"
- "Typecheck passes"
- "Unit tests pass"

### Bad criteria (vague):

- "Works correctly"
- "User can do X easily"
- "Good UX"
- "Handles edge cases"

### Always include as final criteria:

```
"Typecheck passes"
"Unit tests pass"
```

### For stories that change UI, also include:

```
"Verify changes work in browser"
```

---

## Task Document Structure

Generate the task document with these sections:

### 1. Introduction

Brief description of the feature and the problem it solves.

### 2. Goals

Specific, measurable objectives (bullet list).

### 3. Success Metrics

How will we measure if this feature is successful? Include:
- Key performance indicators (KPIs)
- Measurable outcomes
- How/when to measure

Example:
```markdown
## Success Metrics
- 30% reduction in support tickets related to task management within 30 days
- 80% of users set a priority within first week of feature launch
- Filter usage rate of 50%+ among active users
```

### 4. User Stories

Each story needs:

- **ID:** Sequential (US-001, US-002, etc.)
- **Title:** Short descriptive name
- **Description:** "As a [user], I want [feature] so that [benefit]"
- **Acceptance Criteria:** Verifiable checklist

**Format:**
```markdown
### US-001: [Title]
**Description:** As a [user], I want [feature] so that [benefit].

**Acceptance Criteria:**
- [ ] Specific verifiable criterion
- [ ] Another criterion
- [ ] Typecheck passes
- [ ] Unit tests pass
- [ ] [UI stories] Verify changes work in browser
```

### 5. Risks & Mitigations

What could go wrong and how do we prevent it?

Example:
```markdown
## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Priority overload - users mark everything high | Consider limiting high-priority count or adding guidance |
| Filter state lost on refresh | Persist filter in URL params |
| Performance with large task lists | Add pagination if list exceeds 100 items |
```

### 6. Dependencies

Other features, teams, or systems this relies on.

Example:
```markdown
## Dependencies
- Requires existing task management system
- Database must support enum types for priority field
- UI component library must have badge/dropdown components
```

### 7. Non-Goals

What this feature will NOT include. Critical for scope.

### 8. Technical Considerations (Optional)

- Known constraints
- Existing components to reuse

---

## Example Task Document

```markdown
# Task: Task Priority System

## Introduction

Add priority levels to tasks so users can focus on what matters most. Tasks can be marked as high, medium, or low priority, with visual indicators and filtering.

## Goals

- Allow assigning priority (high/medium/low) to any task
- Provide clear visual differentiation between priority levels
- Enable filtering by priority
- Default new tasks to medium priority

## Success Metrics

- 80% of users set a priority within first week of feature launch
- Filter usage rate of 50%+ among active users
- No increase in page load time for task list

## User Stories

### US-001: Add priority field to database
**Description:** As a developer, I need to store task priority so it persists across sessions.

**Acceptance Criteria:**
- [ ] Add priority column: 'high' | 'medium' | 'low' (default 'medium')
- [ ] Generate and run migration successfully
- [ ] Typecheck passes
- [ ] Unit tests pass

### US-002: Display priority indicator on task cards
**Description:** As a user, I want to see task priority at a glance so I know what needs attention first.

**Acceptance Criteria:**
- [ ] Each task card shows colored priority badge (red=high, yellow=medium, gray=low)
- [ ] Priority visible without hovering or clicking
- [ ] Typecheck passes
- [ ] Unit tests pass
- [ ] Verify changes work in browser

### US-003: Add priority selector to task edit
**Description:** As a user, I want to change a task's priority when editing it.

**Acceptance Criteria:**
- [ ] Priority dropdown in task edit modal
- [ ] Shows current priority as selected
- [ ] Saves immediately on selection change
- [ ] Typecheck passes
- [ ] Unit tests pass
- [ ] Verify changes work in browser

### US-004: Filter tasks by priority
**Description:** As a user, I want to filter the task list to see only high-priority items when I'm focused.

**Acceptance Criteria:**
- [ ] Filter dropdown with options: All | High | Medium | Low
- [ ] Filter persists in URL params
- [ ] Empty state message when no tasks match filter
- [ ] Typecheck passes
- [ ] Unit tests pass
- [ ] Verify changes work in browser

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Priority overload - users mark everything high | Consider limiting high-priority count in future iteration |
| Filter state lost on refresh | Persist filter in URL params (included in US-004) |

## Dependencies

- Requires existing task management system
- Database must support enum types for priority field
- UI component library must have badge/dropdown components

## Non-Goals

- No priority-based notifications or reminders
- No automatic priority assignment based on due date
- No priority inheritance for subtasks

## Technical Considerations

- Reuse existing badge component with color variants
- Filter state managed via URL search params
```

---

## Output Files

### `<task-name>.TASK.md`

Save the task breakdown document to the specified output directory.

### `<task-name>.progress.txt`

Create an empty progress tracking file:
```markdown
# Progress Log

## Learnings
(Patterns discovered during implementation)

---
```

---

## Checklist Before Saving

- [ ] This mode was **explicitly requested** by the user (not auto-triggered during story creation)
- [ ] Asked for task name (used for file naming)
- [ ] Task name includes descriptive identifier (NOT just `task-1`, MUST be like `task-1-add-currency-table`)
- [ ] Output directory: same as story file (default) OR user-specified location
- [ ] Asked clarifying questions with lettered options
- [ ] Incorporated user's answers
- [ ] User stories use US-001 format
- [ ] Each story completable in ONE iteration (small enough)
- [ ] Stories ordered by dependency (schema -> backend -> frontend)
- [ ] All criteria are verifiable (not vague)
- [ ] Every story has "Typecheck passes" and "Unit tests pass" as criteria
- [ ] UI stories have "Verify changes work in browser"
- [ ] Success Metrics section defines measurable outcomes
- [ ] Risks & Mitigations section addresses potential issues
- [ ] Dependencies section lists external requirements
- [ ] Non-goals section defines clear boundaries
- [ ] Saved `<task-name>.TASK.md` and `<task-name>.progress.txt` next to story file (or user-specified location)
- [ ] **NO OTHER FILES WERE CREATED OR MODIFIED**
- [ ] **NO CODE WAS WRITTEN OR IMPLEMENTED**
