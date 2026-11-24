---
name: planning-ralph-task
description: "Write a single-file autonomous task document for the Ralph loop: the whole requirement in one <task-name>.TASK.md, split into ordered verifiable tasks, plus a <task-name>.progress.txt tracker. Use whenever the user mentions ralph, ralph loop, ralph task, .TASK.md, .progress.txt, autonomous implementation, 'write/plan/create a task for ralph', 'make this runnable by ralph', 'prepare a task for the ralph loop', or wants one task document an AI can execute end-to-end without stopping. Resolves every open question during planning so the executor never guesses. For breaking a story into a planning document for humans, use planning-stories instead."
allowed-tools: Read, Write, Grep, Glob, AskUserQuestion
---

# Planning Ralph Tasks

One requirement. One task file. Zero open questions.

Turn a requirement into a single `<task-name>.TASK.md` that the Ralph loop executes autonomously from start to finish, plus a `<task-name>.progress.txt` that lets each fresh iteration resume where the last one stopped.

## Why This Skill Exists

The Ralph loop runs unattended. Once it starts, it does not stop until every task is done, and no human is available mid-run. Any question that surfaces during execution gets answered by the executor on the spot, and an on-the-spot guess is how autonomous runs produce confident, wrong implementations.

Planning time is the only time questions can be answered by a human. So this skill front-loads all question answering: write the full document first, then walk through every task hunting for open questions, resolve each one with the user or with a marked recommended default, and bake the answers into the document. The document is not done until a full review pass finds zero open questions.

Two rules travel into every generated document as its Operating Rules section:

1. **No commits.** The executor never commits. A human reviews the full diff and commits.
2. **Recommended option.** Any question that still comes up mid-run is answered with the recommended option (the most conventional, lowest-risk choice), recorded in the progress file, never blocked on.

## Difference from planning-stories

|                          | planning-stories                                    | planning-ralph-task                                  |
| ------------------------ | --------------------------------------------------- | ---------------------------------------------------- |
| Output                   | `STORY.<name>.md` planning file                     | Exactly one `.TASK.md` + one `.progress.txt`         |
| Shape                    | Story broken into stories/tasks for ralph iterations | Whole requirement in one file, split into internal tasks |
| Executor commits         | Yes, per story                                      | Never                                                |
| Open questions           | Clarified at planning start                         | Every question resolved before save, with audit trail |

Use planning-stories when the user wants a story planned for humans. Use this skill when the user wants one runnable file for the ralph loop.

## The Job

1. Gather task name, output directory, and the requirement
2. Explore the codebase so tasks reference real files and conventions
3. Ask scope-level clarifying questions
4. Draft the full document
5. Run the Open Questions Review until a pass finds zero open questions
6. Create the progress file
7. Run the final checklist

## CRITICAL RULES: READ FIRST

This skill is READ-ONLY except for the two files it creates:

1. CREATE `<task-name>.TASK.md`
2. CREATE `<task-name>.progress.txt`

Do not modify any existing file. Do not write code, migrations, or tests. Do not create any other files or directories. Do not run builds, tests, or typechecks. Your only job is to plan. Implementation belongs to the Ralph loop.

---

## Step 1: Gather Task Info

Collect from the user:

1. **The requirement** - what should get built, changed, or fixed
2. **Task name** - used for both file names
3. **Output directory** - default is the current working directory (where ralph will run); only ask when this is ambiguous

### File Naming Convention

The task name must include a short descriptive identifier. Never a bare number.

| Format                              | Status          | Example                                  |
| ----------------------------------- | --------------- | ---------------------------------------- |
| `task-<number>-<description>.TASK.md` | PREFERRED     | `task-1-add-currency-table.TASK.md`      |
| `<description>.TASK.md`             | Acceptable      | `user-authentication.TASK.md`            |
| `task-<number>.TASK.md`             | Not allowed     | `task-1.TASK.md`                         |

If the user does not give a number, look at existing `task-*.TASK.md` files in the output directory and use the next number; use `1` when none exist. The description is 2-4 kebab-case words describing what the task accomplishes.

Both files must share the same base name and live in the same directory. `ralph.sh` requires the `.TASK.md` suffix and derives the sibling progress file from that base name:

```
task-1-add-priority-field.TASK.md
task-1-add-priority-field.progress.txt
```

---

## Step 2: Explore the Codebase

A task that names real files, real commands, and real conventions is executable. A task that guesses ("update the user service") is a trap, because the executor cannot ask which file you meant.

Before drafting:

- Locate the files, tables, and components the requirement touches
- Note existing conventions: naming, layering, folder structure, error handling
- Capture the exact verification commands (typecheck script, test script, lint script from `package.json` or equivalent)
- When the requirement references something you cannot find, ask the user instead of inventing it

---

## Step 3: Clarify Scope

Ask 3-5 questions, only where the requirement is genuinely ambiguous. Use AskUserQuestion with lettered options, putting your recommended option first. Focus on:

- **Problem/Goal:** What problem does this solve?
- **Core functionality:** What are the key actions?
- **Boundaries:** What should this NOT do?
- **Success criteria:** How do we know it is done?

This round decides WHAT gets built. Deep implementation-detail questions (defaults, edge cases, formats) are deliberately left for Step 5, after the draft exists. Asking everything now would duplicate that pass and exhaust the user's attention on questions a draft would answer by itself.

---

## Step 4: Draft the Document

Write the complete `<task-name>.TASK.md` using this structure. The whole requirement lives in this one file: the executor arrives with zero context and nowhere else to look (referencing real repo paths is fine and encouraged; referencing conversations or outside documents is not).

```markdown
# Task: [Title]

## Operating Rules (read before starting any task)

[The six rules below, verbatim]

## Introduction

[The problem and the solution in a few sentences. The executor arrives with zero context.]

## Goals

- [Specific, verifiable objectives]

## Non-Goals

- [What this run explicitly does not include. This is the scope fence the executor uses when self-answering questions.]

## Dependencies and Constraints

- [Systems, files, and services this relies on]
- [Conventions that must be respected]

## Tasks

### Task 1: [Title]

[Task format below]

### Task 2: [Title]

[...]

## Answered Questions

[Filled during the Open Questions Review: one line per question, marked USER or DEFAULT]
```

### The Operating Rules Section

Every generated document opens with these rules. Include them in substance (adjust wording to the project, keep every rule):

```markdown
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
```

Why each rule exists: rule 1 keeps the human in control of history; rules 2 and 6 are what make unattended execution survivable; rules 3-5 make the run resumable, because every Ralph iteration is a fresh context that knows only this document and the progress file.

### Task Format

Each task inside the document follows this format:

```markdown
### Task N: [Title]

**Layer:** database | backend | api | frontend | cleanup

**Description:**
[What this task does and why, 2-4 sentences]

**Changes:**
- [Exact file, function, table, or component being changed]

**Acceptance Criteria:**
- [ ] [Specific verifiable criterion: a command that passes or a checkable behavior]
- [ ] Typecheck passes
- [ ] Tests pass
```

For tasks that change UI, also include `- [ ] Verify changes work in the browser`.

Good criteria name a command or a checkable behavior: "GET /tasks?priority=high returns only high-priority tasks", "`pnpm typecheck` exits 0". Bad criteria are unverifiable: "works correctly", "good UX", "handles edge cases".

### Sizing and Ordering

- **Order by dependency:** schema before backend, backend before API, API before frontend, cleanup last. A fresh iteration that finds a forward dependency builds on code that does not exist yet, with no one watching.
- **One layer per task.** Mixed-layer tasks hide partial progress and make the progress file lie.
- **Each task is small:** completable and verifiable in one focused sitting (~10 minutes of work), so every iteration ends on a clean, resumable increment.
- **The file as a whole may be large.** Unlike story-per-file planning, the total work is not capped at one context window: Ralph iterates, and the progress file carries state across fresh contexts.
- **One requirement per file.** If the request is really several unrelated features, suggest to the user one task file per feature, then apply this skill per file.

---

## Step 5: The Open Questions Review (Mandatory)

This pass is what separates a runnable document from a wishlist. Do not skip it, and do not do it from memory of what you wrote: re-read the document, task by task.

For each task, put yourself in the executor's position mid-run, with no human available, and ask: **what would I have to decide that this document does not tell me?** Hunt where questions hide:

| Where questions hide  | What to look for                                                        |
| -------------------- | ----------------------------------------------------------------------- |
| Unnamed specifics    | file paths, identifiers, defaults, formats, error messages, magic values |
| Unhandled cases      | empty lists, missing data, failures, duplicates, boundary values         |
| Scope boundaries     | does Task 3 include X, or is X a later task or a non-goal?               |
| Implicit tech choices| which library, pattern, or approach when several would work              |
| Environment assumptions | commands, ports, env vars, services that must already exist           |
| Verification gaps    | criteria with no command behind them ("works correctly")                 |
| Ordering hazards     | a task assuming something no earlier task provides                       |

Collect every question from the full sweep before resolving anything. Then resolve each one in exactly one of three ways:

1. **Ask the user.** Batch all questions into a single AskUserQuestion round. For each, put your recommended option first, labeled Recommended. Ask about anything that changes what gets built or risks rework.
2. **Self-answer with a default.** For small conventional details (exact wording, fallback behavior, label text), choose the recommended option yourself and mark it DEFAULT.
3. **Convert to a non-goal.** When the honest answer is "not in this run", move it to Non-Goals so the executor never considers building it.

Then bake every answer into the document twice: into the task description, changes, or criteria where it belongs, and into the Answered Questions section as the audit trail, one line per question:

```markdown
## Answered Questions

- What happens to existing tasks with no priority? -> DEFAULT: column defaults to 'medium', no backfill needed.
- Should the filter persist across reloads? -> USER: yes, via URL search params.
```

Then run the pass again on the updated document. New specifics create new questions, and a freshly named default can contradict a later task. Repeat until a full pass finds zero open questions.

The test of done: a competent developer who has never seen this project could read only this file and implement the change without asking anyone anything.

---

## Step 6: Create the Progress File

Create `<task-name>.progress.txt` next to the task document, pre-listing every task:

```markdown
# Progress Log

Source of truth for where the work stands. The executor updates this file
after every task; each fresh Ralph iteration reads it before touching any code.

## Task Status

Mark each task PENDING, DONE, or BLOCKED (with a one-line reason).

Task 1 - [title]: PENDING
Task 2 - [title]: PENDING

## Decisions

Questions answered mid-run with the recommended option. One line each:
question -> chosen answer.

## Learnings

Conventions, pitfalls, and patterns discovered during implementation that
later tasks and later iterations should know.
```

---

## Handoff

Tell the user how to run the loop:

```bash
ralph.sh <task-name>.TASK.md [max-iterations] [sleep-seconds]
# Example: ralph.sh task-1-add-priority-field.TASK.md 50 3
```

After the run finishes, the working tree holds all changes uncommitted for review.

---

## Troubleshooting

| Problem                         | Solution                                                             |
| ------------------------------- | -------------------------------------------------------------------- |
| Requirement feels huge          | Split into more tasks inside the file; only suggest multiple files for unrelated features |
| Cannot find the code a requirement mentions | Ask the user for the location; never invent paths          |
| User answers "you decide"       | Use your recommended option, mark it DEFAULT, continue               |
| Two tasks keep referencing each other | Reorder by dependency, or extract the shared piece into an earlier task |

---

## Checklist Before Saving

- [ ] Exactly two files created: `<task-name>.TASK.md` and `<task-name>.progress.txt`
- [ ] Naming follows `task-<number>-<description>` (or at least `<description>`), both files share the base name, same directory
- [ ] Operating Rules open the document and include the no-commit rule and the recommended-option rule
- [ ] Tasks ordered by dependency, one layer each, no forward references
- [ ] Every acceptance criterion is verifiable (a command or a checkable behavior)
- [ ] Open Questions Review ran on the finished draft; the final pass found zero open questions
- [ ] Every question resolved as USER, DEFAULT, or moved to Non-Goals, all recorded in Answered Questions
- [ ] Progress file lists every task as PENDING
- [ ] No existing file was modified, no code was written, no other files were created

See [example.md](example.md) for a complete generated task document.
