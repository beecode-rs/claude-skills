# Example: Task Priority System

Input from the user:

```
Add a priority field to tasks, high medium or low. Users set it when
creating or editing, tasks show their priority, and the list can be
filtered by priority. Make it a ralph task.
```

Generated files: `task-1-add-priority-field.TASK.md` and `task-1-add-priority-field.progress.txt`.

---

## task-1-add-priority-field.TASK.md

```markdown
# Task: Task Priority System

## Operating Rules (read before starting any task)

You are an autonomous executor. Once you start, you do not stop until every
task in this document is done. No human is available mid-run. These rules
apply to every task below and override anything else you infer:

1. **Never commit.** Do not run `git commit`, `git push`, or create commits
   any other way. Leave all changes in the working tree. A human reviews the
   full diff and commits after the run.
2. **Answer questions with the recommended option.** If anything is ambiguous
   or a decision is missing from this document, choose the recommended
   option: the most conventional, lowest-risk choice that stays consistent
   with the rest of the codebase. Record the question and your chosen answer
   under `Decisions` in the progress file, then continue. Never block on a
   question and never guess silently.
3. **Resume, do not restart.** Read the progress file first. Completed tasks
   stay done. Start from the first task not marked DONE.
4. **Verify before advancing.** A task is DONE only when every one of its
   acceptance criteria passes. If a criterion fails, fix it before moving on.
5. **Log as you go.** After finishing each task, update the progress file:
   mark the task DONE and note anything the next iteration needs (files
   touched, decisions, learnings).
6. **Do not spin.** If a task genuinely cannot be completed after real
   attempts, mark it BLOCKED in the progress file with the reason, and
   continue with the tasks that do not depend on it.

## Introduction

Tasks currently have no notion of importance, so urgent work drowns in the
list. This change adds a priority level (high, medium, low) to every task:
stored in the database, editable in the create and edit forms, shown as a
colored badge on each card, and filterable from the list toolbar.

## Goals

- Every task stores a priority of 'high', 'medium', or 'low'
- Priority is settable when creating and editing a task
- Priority is visible at a glance on every task card
- The task list can be filtered to a single priority

## Non-Goals

- No priority-based notifications or reminders
- No automatic priority assignment from due dates
- No priority sorting (the list keeps its current sort order)
- No priority on subtasks

## Dependencies and Constraints

- Tasks table `tasks` already exists (migration 0003)
- Repository layer convention: one repository class per entity in `src/dal/`
- Test framework is Vitest, run with `pnpm test`; typecheck with `pnpm typecheck`
- Badge component `src/ui/Badge.tsx` supports color variants, reuse it

## Tasks

### Task 1: Add priority column to tasks table

**Layer:** database

**Description:**
Store priority on every task. Add a nullable-free enum column with a default
so existing rows get a value without a backfill step.

**Changes:**
- New migration `0007_add_task_priority.ts`: add column `priority`
  ENUM('high', 'medium', 'low') NOT NULL DEFAULT 'medium' to `tasks`
- Update the Task entity/type to include `priority`

**Acceptance Criteria:**
- [ ] Migration `0007_add_task_priority.ts` runs without errors
- [ ] `SELECT priority FROM tasks LIMIT 1` returns 'medium' for pre-existing rows
- [ ] Migration rollback drops the column cleanly
- [ ] `pnpm typecheck` passes
- [ ] `pnpm test` passes

### Task 2: Handle priority in the task repository

**Layer:** backend

**Description:**
Make the repository layer carry priority through create and update, and
support filtering by it for the list endpoint.

**Changes:**
- `src/dal/task-repository.ts`: accept `priority` in create and update inputs
- `src/dal/task-repository.ts`: add optional `priority` filter to the list query

**Acceptance Criteria:**
- [ ] Creating a task without priority persists 'medium'
- [ ] Updating only the priority leaves other fields untouched
- [ ] List query filtered by 'high' returns only high-priority tasks
- [ ] Unit tests cover all three behaviors above
- [ ] `pnpm typecheck` passes
- [ ] `pnpm test` passes

### Task 3: Expose priority in the task API

**Layer:** api

**Description:**
Carry priority through the REST endpoints so the frontend can read and write
it and the list endpoint can filter by it.

**Changes:**
- `src/api/task-handler.ts`: include `priority` in create/update request
  validation (reject values outside high/medium/low with 400)
- `src/api/task-handler.ts`: include `priority` in task responses
- `GET /tasks` accepts `?priority=high|medium|low`, absent means no filter

**Acceptance Criteria:**
- [ ] POST /tasks with priority 'low' persists and returns it
- [ ] POST /tasks with priority 'urgent' returns 400
- [ ] GET /tasks?priority=high returns only high-priority tasks
- [ ] GET /tasks without the param behaves exactly as before
- [ ] `pnpm typecheck` passes
- [ ] `pnpm test` passes

### Task 4: Priority selector in task forms

**Layer:** frontend

**Description:**
Let the user set priority when creating and editing a task. One shared
selector component used by both forms.

**Changes:**
- New `src/ui/PrioritySelect.tsx`: dropdown with High / Medium / Low
- Integrate into `TaskCreateForm` and `TaskEditForm`, submit `priority` on save

**Acceptance Criteria:**
- [ ] Selector shows three options, Medium preselected on create
- [ ] Edit form opens with the task's current priority selected
- [ ] Chosen priority is sent on create and on edit
- [ ] `pnpm typecheck` passes
- [ ] `pnpm test` passes
- [ ] Verify changes work in the browser

### Task 5: Priority badge on task cards

**Layer:** frontend

**Description:**
Show priority on every card in the list so it is readable without clicking.

**Changes:**
- `src/ui/TaskCard.tsx`: render Badge with the task's priority
- Colors: red = high, yellow = medium, gray = low (Badge variants exist)

**Acceptance Criteria:**
- [ ] Every card shows its priority badge, visible without hover
- [ ] Colors match the mapping above
- [ ] `pnpm typecheck` passes
- [ ] `pnpm test` passes
- [ ] Verify changes work in the browser

### Task 6: Priority filter in the list toolbar

**Layer:** frontend

**Description:**
Filter the task list by priority from the toolbar, with the choice kept in
the URL so a reload keeps the filter.

**Changes:**
- Toolbar dropdown with All / High / Medium / Low
- Selected filter written to URL search param `priority` and read on load
- Empty state message when the filter matches nothing

**Acceptance Criteria:**
- [ ] Selecting High shows only high-priority tasks
- [ ] Reloading with ?priority=high keeps the filter applied and selected
- [ ] All restores the unfiltered list
- [ ] Filtered-to-empty shows the empty state message
- [ ] `pnpm typecheck` passes
- [ ] `pnpm test` passes
- [ ] Verify changes work in the browser

## Answered Questions

- What happens to existing tasks with no priority? -> DEFAULT: column defaults to 'medium', no backfill needed.
- Can priority be left unset when creating a task? -> USER: yes, optional in the form, persists as 'medium'.
- Should the filter survive a page reload? -> USER: yes, via URL search param 'priority'.
- Badge colors? -> USER: red / yellow / gray using existing Badge variants.
- Does the list also sort by priority? -> USER: no, sorting stays out of scope (see Non-Goals).
- What does the API do with an invalid priority value? -> DEFAULT: reject with 400.
```

---

## task-1-add-priority-field.progress.txt

```markdown
# Progress Log

Source of truth for where the work stands. The executor updates this file
after every task; each fresh Ralph iteration reads it before touching any code.

## Task Status

Mark each task PENDING, DONE, or BLOCKED (with a one-line reason).

Task 1 - Add priority column to tasks table: PENDING
Task 2 - Handle priority in the task repository: PENDING
Task 3 - Expose priority in the task API: PENDING
Task 4 - Priority selector in task forms: PENDING
Task 5 - Priority badge on task cards: PENDING
Task 6 - Priority filter in the list toolbar: PENDING

## Decisions

Questions answered mid-run with the recommended option. One line each:
question -> chosen answer.

## Learnings

Conventions, pitfalls, and patterns discovered during implementation that
later tasks and later iterations should know.
```
