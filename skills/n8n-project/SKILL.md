---
name: n8n-project
description: Scaffold and maintain a project folder for building n8n automations. Local-first workflow JSON as the source of truth, upload and verify through the n8n MCP tools, a CLAUDE.md inventory table that tracks every workflow, research and suggestion docs kept separate from baseline facts, resource inventories, frozen version snapshots, an eval harness, and a go-live runbook. Make sure to use this skill whenever the user wants to start, scaffold, organize, or work inside a project that builds n8n workflows or automations of any kind (email classification, LinkedIn or social content generation, content pipelines, syncing, scraping, digest or notification flows, any recurring automation), asks where n8n project files go, how to track n8n workflow changes, or how to research and propose n8n improvements, even when the words "project" or "n8n" are not used.
---

# n8n Project

One n8n automation = one self-contained project folder. The folder holds the
workflow JSON (the source of truth), the deployment record, and every design
decision, so work can stop and resume cold, and nothing lives only inside the
n8n instance.

This skill governs the project around the workflows: folder structure,
naming, change tracking, research, and deployment discipline. For node-level
work inside a single workflow, switch to the node skills instead:
n8n-mcp-tools-expert, n8n-workflow-patterns, n8n-agents, n8n-code-javascript,
n8n-error-handling.

## The project folder

```
<project-name>/
├── CLAUDE.md              rules, workflow inventory table, folder map
├── backup-v<N>/           frozen snapshot of the previous version's workflows
├── workflows/             working copy of the n8n workflow JSON
│   └── <domain>/          one subfolder per subsystem of the automation
├── db/
│   └── migrations/        idempotent DDL, numbered (001-..., 002-...)
└── resource/
    ├── doc/               all project docs: baselines, suggestions,
    │                      architecture, runbook, eval notes
    └── models/            inventories of resources the project depends on
```

The folder is the memory. The n8n instance holds running copies; the repo
holds the truth. Anything not written into this folder is lost the moment a
session ends.

## Scaffold a new project

When the user starts a new n8n automation ("build me a LinkedIn content
generator", "automate my invoicing"), scaffold before building:

1. Create the folder above (skip `backup-v<N>/` when there is nothing to
   snapshot; skip `db/` when the project needs no database).
2. If an older version of the automation already exists in n8n, export its
   workflows into `backup-v<N>/` with the export date recorded in the folder
   map, and deactivate its triggers in n8n to freeze it. Never edit anything
   inside the snapshot afterwards.
3. Copy `assets/project-claude-md-template.md` from this skill into the
   project root as `CLAUDE.md` and fill in every `<placeholder>`: the n8n
   instance and its MCP server prefix, the n8n folder tree, the DB prefix,
   the source systems the automation reads from.
4. Record what exists: list the workflows already in n8n for this domain
   into the inventory table, inventory the models and other resources the
   host provides into `resource/models/`, note the database and schema.
5. Only then start the research loop below.

Facts before design. A scaffolded project whose CLAUDE.md table is empty
while n8n already runs five related workflows is already out of sync.

## Research and suggestions

Design work follows a fixed doc flow in `resource/doc/`. Each doc names its
inputs and separates observed facts from proposals; later docs amend earlier
ones explicitly instead of silently superseding them.

1. **Baseline doc** (`<domain>-v<N>.md`): describe the existing system as it
   runs today. Sources: the frozen JSON in `backup-v<N>/`, read queries
   against the live database, the resource inventories. When sources
   disagree, the exported JSON is ground truth; say so where it corrected
   a belief.
2. **Suggestions doc** (`<topic>-suggestions.md`): how the new version
   should work. Shape: goals, baseline facts (carried from step 1, with
   evidence), proposal, data model, model or service assignments, open
   questions, migration plan from the old version.
3. **Architecture doc** (`n8n-architecture.md`): the workflow-level
   decisions. Which workflows exist, what each owns, the call graph, the
   typed contracts, the error strategy, the test harness, the build order.
   When it contradicts a suggestions doc, state the amendment in both the
   architecture doc and the deviations list in CLAUDE.md.
4. **Runbook** (`<version>-runbook.md`): the exact first-live-runs sequence.
   Prechecks (models present, credentials, database reachable), how to seed
   eval data, how to run the eval, how to start with a small range before
   full volume, known first-run caveats.
5. **Resource inventories** (`resource/models/`): dated snapshots of what
   the host provides (installed models with specs, available credentials,
   external service quotas). Record removals too, with the reason and the
   kept replacement, so a later session does not wonder where something
   went.

The point of this split: a future session (or a future version) can tell
what was measured, what was decided, and what was only suggested at the
time it reads the docs.

## Eval harness

Any workflow with a judgment component (classification, generation,
extraction, scoring) gets an eval before it goes live. The proven shape:

- A **case store** (n8n Data Table or prefixed DB table) holding inputs and
  expected outputs. Two column owners: machine-filled input columns, and
  human-labeled expected columns plus an `enabled` flag.
- A **fill workflow** (`controller-manual-fill-eval-cases`) that loads real
  inputs from the source system by filter. It upserts on the natural key
  and never maps the human-owned columns, so re-running the fill can never
  overwrite hand labels.
- An **eval runner** (`test-<unit>-eval`) that reads enabled cases, calls
  the production service per case (through a `model` input override so
  benchmarks run the real path), scores each dimension (exact, ordinal by
  distance, or judged), writes one row per case x model into a results
  table and per-model aggregates into a runs table, and reports.

Score exact-match dimensions strictly and ordinal dimensions by distance;
record the scoring rule in the doc, not only in the workflow.

## Workflow naming and shape

Every workflow name states its role first:

| Prefix | Role | Rules |
|---|---|---|
| `controller-<trigger>-<what>` | Entry point | Trigger, fan-out, notify. No real logic. Trigger vocabulary: `cron`, `manual`, `webhook`, the source event (`imap`, `rss`, ...). |
| `service-<what>` | Logic unit | Called by controllers and tests. Typed input and output contract. Stateless where possible. |
| `util-<what>` | Leaf helper | Must earn its place: at least two real callers, or it is the unit under test. |
| `model-<what>` | LLM wrapper | Wraps one model call, no domain logic. |
| `test-<what>` | Eval harness | Never active in production. |

Shape rules, learned the hard way:

- Max call depth 2: controller -> service -> leaf util. Deeper chains made
  the previous version unmanageable.
- One write path per store: everything that inserts or updates a given
  table goes through one service; controllers dedupe before calling, the
  service upserts so a retry cannot duplicate.
- Every project gets one `util-error-alert` Error Trigger workflow, and
  every workflow in the project points `settings.errorWorkflow` at it.
- The typed contract lives in the `description` field of the local JSON:
  trigger inputs, returned fields, defaults, failure behavior. The n8n API
  does not persist workflow descriptions, so the repo file is the only
  place the contract can live. Keep it current with the nodes.

Subfolders under `workflows/` mirror the subsystems (one per domain of the
automation, plus `shared/` and `test/`), and mirror the n8n folder tree so
a file path maps 1:1 to a place in the instance.

## Build and deploy loop

Local-first, always:

1. Edit or create the workflow JSON in `workflows/<subfolder>/`.
2. Upload with the instance's `n8n_update_full_workflow` MCP tool, using
   the workflow ID from the inventory table (the `id` field inside the
   JSON matches).
3. Verify the upload succeeded before considering the change done.
4. Update the inventory table and folder map in the same change: new
   workflow, rename, move to another folder, activation flip, retirement.

Never edit a workflow directly in the n8n UI and never let the repo copy
drift behind the instance; a workflow whose JSON in `workflows/` differs
from what runs has no source of truth. If the instance turns out to hold a
newer state, re-export into `workflows/` first and say so in CLAUDE.md.

## Change tracking

The project CLAUDE.md is the ledger. It stays current in the same change
that touches the thing it describes:

- Workflow created, renamed, moved, activated, deactivated, or retired ->
  the inventory table (columns: Workflow, ID, Active, What it does).
- File or folder added, renamed, moved, or retired -> the folder map.
- Built system diverging from a design doc -> the deviations list, with
  the reason (for example: a platform limitation discovered mid-build, a
  user decision with its date).
- Database migration applied -> the migration entry, with the date and
  whether idempotency was verified.

When a change invalidates a doc statement, amend the doc or record the
deviation; a doc that contradicts the built system is worse than no doc.

## Lifecycle

The full arc of a version, in order:

1. Scaffold (folder, snapshot, CLAUDE.md, inventories)
2. Baseline doc: facts about the existing system
3. Suggestions doc: goals and design for the new version
4. Architecture doc: workflow set, contracts, eval plan, build order
5. Schema: idempotent migrations with the project prefix, applied and
   verified idempotent by running twice
6. Build: local JSON -> upload -> verify -> table, following the build
   order from the architecture doc
7. Eval: fill cases, hand-label, run the eval, iterate until good enough
8. Go live per the runbook: prechecks, small range first, then full
   volume, then activate the event triggers
9. Track: every subsequent change through the build and deploy loop

A version is done when the runbook's steps have all run, not when the last
workflow was uploaded.
