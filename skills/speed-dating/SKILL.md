---
name: speed-dating
description: Scaffold and maintain projects using the speed dating method, one self-contained kebab-case folder per project with a short CLAUDE.md, numbered source-of-truth files (00-, 01-), YYYY-MM-DD date-prefixed deliverables, and underscore-prefixed support folders. Use this skill whenever the user wants to create, start, or scaffold any new project (newsletter, course, research, writing, plan, side business, any body of work kept in files), mentions speed dating or juggling projects with AI, asks how to name or organize project files, decides between a number prefix and a date prefix, adds files to an existing project, archives one, or runs the jump-back-in test. Trigger even when the method is not named, like "make me a project for my newsletter", "set up a folder for this course", "where does this file go".
---

# Speed Dating Method

All projects live under one root. Each project is one self-contained kebab-case folder holding everything it needs. The folder carries the context so nobody has to remember anything: any project can be dropped mid-work and picked up cold later.

Work lives in markdown files. Read the file, change the file, report briefly.

## Create a new project

1. Kebab-case name, no spaces: `weekly-newsletter/`.
2. Create this shape, renaming the generic parts to fit:

```
<project-name>/
  CLAUDE.md
  00-<source-of-truth>.md
  01-<backlog>.md
  <deliverables>/
  _research/
```

Example:

```
weekly-newsletter/
  CLAUDE.md
  00-newsletter-strategy.md
  01-post-ideas.md
  issues/
    2026-08-14-one-read-one-try-one-think.md
  _research/
```

- `CLAUDE.md`: the few rules true only for this project (cadence, format, hard limits like "never send without my okay"). The user creates and maintains it. When scaffolding, skip this file. Never write it unless the user explicitly asks.
- `00-`: source of truth, the rules of the work. Check output against it.
- `01-`: the living backlog.
- `<deliverables>/`: the actual output, one file per deliverable, date-prefixed name.
- `_`-prefixed folders: fuel (research, notes, raw dumps), never the deliverable. The underscore sorts them away from the output.

## Naming: numbers versus dates

Kebab-case everywhere. Descriptive names, filename matches its first heading. ALL-CAPS only for signposts like `CLAUDE.md`.

- **Number prefix = reading order or phase.** `00-strategy.md`, `01-ideas.md` sort into read order. For developing thinking, each higher number is a later stage of the same idea (`00-audience-ideas.md`, `01-audience-ideas-busy-parents.md`, `02-busy-parents-reading-habits.md`). The highest number is the current state; resume from there.
- **Date prefix = schedule.** `2026-08-14-one-read-one-try-one-think.md`, always `YYYY-MM-DD`. The date is the planned ship date, often in the future, not the day of writing.
- Unscheduled ideas get `<name>-DRAFT.md`. When a date is picked, rename to the date prefix and drop the `-DRAFT`.
- **Never mix numbers and dates in one folder.** A folder either reads in order or ships on a schedule.
- **Not sure which prefix fits? Ask, don't guess.** A number says reading order, a date says schedule, and a wrong pick breaks the folder's sort logic. Ask the user one question ("does this file read in order or ship on a schedule?") before creating it.

## Working in an existing project

Session start read order: the `00-` file, then the latest work (newest dated deliverable or highest-numbered phase file). Do the work in the files. Skills live in the central `~/.claude/skills/` pool; projects reference them by name, never copy them in.

## Archiving

Done or paused: move the folder into `archive/`, never rename it. Inside `archive/` means finished, outside means active.
