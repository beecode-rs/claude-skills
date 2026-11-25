# <Project Name>

<One paragraph: what this automation does. Which n8n instance it runs on
(host name + URL), reached through the `mcp__n8n-mcp-<instance>__*` MCP
tools. Which source systems it reads from and writes to.>

## Rule: local-first workflow editing

All n8n workflow changes are made locally first, then uploaded to n8n:

1. `backup-v<N>/` is a frozen snapshot of the previous version's workflows
   as exported from n8n on <date>. Never edit anything in it.
2. `workflows/` is the working copy. Edit workflow JSON only here.
3. After editing a file in `workflows/`, upload it to n8n with
   `mcp__n8n-mcp-<instance>__n8n_update_full_workflow` using the workflow
   ID from the table below (the `id` field inside the JSON file matches).
   Verify the upload succeeded before considering the change done.
4. When a brand new workflow is created, save its JSON in `workflows/`
   under the matching subfolder, upload it, and add it to the table below
   with a short explanation of what it is and what it is used for. Also
   update the table when a workflow is renamed, moved to another folder,
   activated, deactivated, or retired.

## Rule: keep the workflow table current

The table below mirrors `workflows/`. When any workflow in this project is
created, renamed, moved, activated, deactivated, or retired, update the
table in the same change.

## Rule: docs live in resource/doc

All project docs (design notes, suggestions, research, runbooks,
write-ups) go into `resource/doc/`. Do not create docs anywhere else in
the repo.

## Rule: keep the folder map current

Whenever a new file or folder is added anywhere in this repo (or an
existing one is renamed, moved, or retired), update the folder map below
in the same change.

## Rule: new database objects carry the project prefix

All tables created for this project must be named with the prefix
`<prefix>_`, for example `<prefix>_item`, `<prefix>_run`. Tables without
the prefix belong to other projects and must stay untouched. Migrations in
`db/migrations/` are idempotent; verify by running twice.

## Rule: contracts live in the local JSON

Typed input/output contracts are documented in the `description` field of
each workflow JSON file in `workflows/`. The n8n API does not persist
workflow descriptions, so the repo files are the contract source of truth.
Keep descriptions current with the nodes.

## Folder structure

- `CLAUDE.md`: this file. Project rules, the workflow inventory table, and
  the folder map.
- `backup-v<N>/`: frozen snapshot of the previous version's workflows,
  exported from n8n on <date>. Never edit anything in it. Subfolders:
  <list>.
- `workflows/`: working copy of the n8n workflows. Edit workflow JSON only
  here. Subfolders: <list, one per subsystem, plus `shared/` and `test/`>.
- `db/`: database schema work, applied to <database and schema>.
  - `migrations/001-<name>.sql`: idempotent DDL for the `<prefix>_`
    tables, their indexes, and seed rows. Applied on <date>; verified
    idempotent by running it twice.
- `resource/doc/`: all project docs.
  - `<domain>-v<N>.md`: baseline description of the previous version,
    written to support planning of the new one.
  - `<topic>-suggestions.md`: suggestions on how the new version should
    work: goals, baseline facts, data model, model or service assignments,
    migration plan.
  - `n8n-architecture.md`: workflow architecture: the workflow set, the
    typed contracts, the error strategy, the eval harness, the build
    order.
  - `<version>-runbook.md`: runbook for the first live runs.
- `resource/models/`: inventories of the resources the project depends on
  (installed models with specs and dates, credentials, quotas), plus
  records of removals with reasons.

## Workflows in n8n (folder `<n8n-folder-tree>`, project <project-id>)

Folder tree: `<root>` with subfolders <list>. Status: <built when, active
or inactive, what follows before go-live>.

### shared (folder `<root>/shared`)

| Workflow | ID | Active | What it does |
|---|---|---|---|
| util-error-alert | <id> | no | Error workflow for every project workflow: Error Trigger extracts the failing workflow, node, execution id and URL from the error payload and sends them to <notification channel>. All project workflows point `settings.errorWorkflow` at this ID. |

### <subsystem> (folder `<root>/<subsystem>`)

| Workflow | ID | Active | What it does |
|---|---|---|---|
| <workflow-name> | <id> | no | <one to three sentences: trigger, what it does, what it calls, where it writes.> |

### Dependencies outside the project folder

| Workflow | ID | Used by |
|---|---|---|
| <workflow-name> (folder <folder>) | <id> | <which project workflows call it, and why.> |

Shared infrastructure: <the external pieces every workflow relies on, for
example databases, vector stores, model servers, notification channels,
Data Tables with their IDs.>

## Database (<host>, database <name>)

Reached through the `mcp__pg-<host-db>__*` MCP tools (<engine and
version>, schema <schema>). Tables as of <date>:

| Table | Rows | Role |
|---|---|---|
| `<prefix>_<name>` | <n> | <role and key columns.> |

## Deviations from the design docs

- <Built system diverging from `resource/doc/`: the point, the divergence,
  and the reason (platform limitation, user decision with date, ...). Keep
  appending; never silently rewrite a doc to match the build.>
