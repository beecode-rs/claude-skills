# claude-skills

A collection of shared [Claude Code Skills](https://docs.claude.com/en/docs/claude-code/skills) — drop-in packages that teach Claude how to handle specific workflows, from customer-discovery interviews to TypeScript monorepo architecture.

Each skill lives under `skills/<name>/` as a `SKILL.md` (with frontmatter describing when it activates) plus supporting references, templates, and scripts.

Standalone shell tools live under `scripts/<name>/`, each with its own README and install instructions.

Subagents for Claude Code live under `agents/<name>.md`, each with frontmatter that sets its description, tools, and model.

## Table of contents

<!-- toc -->

- [Available skills](#available-skills)
  - [Skill installation](#skill-installation)
- [Available agents](#available-agents)
  - [Agent installation](#agent-installation)
- [Available scripts](#available-scripts)
- [License](#license)

<!-- tocstop -->

## Available skills

| Skill | What it does |
|-------|--------------|
| [ai-documentation](skills/ai-documentation/) | Investigates a codebase and writes **business documentation for non-developers** (PMs, founders, support, new team members): how the system behaves, what flows through it, and what happens when things fail. Produces a hub-and-spoke suite in `resource/ai-doc/` with a navigation README, topic files whose prose stays free of code identifiers, Mermaid flow diagrams, and a per-file "Where this lives in the code" anchor table for developers and AI agents. Refreshes an existing suite in place instead of rewriting it. |
| [commit-message](skills/commit-message/) | Generates **conventional commit messages** for staged changes and **squash PR merge messages** from the branch's commit log: reads the actual diff (or the PR's commits), applies its rules file (`{type}: {subject}` under 50 chars, lowercase, imperative), shows every message in chat first, and requires an explicit yes before any commit. Never pushes, never overrides the local author, and asks an extra are-you-sure before committing to `main`/`master`. |
| [mom-test-coach](skills/mom-test-coach/) | Validates product/startup ideas using **The Mom Test** — shapes the idea, finds the riskiest assumptions, crafts interview questions that surface facts (not compliments), debriefs raw notes, and reaches a proceed / pivot / kill verdict. Includes a mock-interview practice mode. |
| [mono-repo-typescript](skills/mono-repo-typescript/) | TypeScript monorepo architecture with **pnpm workspaces** — package organization, shared libraries, ES module path aliases, centralized config, and Docker Compose orchestration. |
| [orchestrating-ts-agents](skills/orchestrating-ts-agents/) | Plans and **runs multi-agent work** in a TypeScript / pnpm monorepo: routes each piece to the right specialist (`ts-implementer`, `ts-tester`, `ts-reviewer`, `code-explorer`, `Plan`, `general-purpose`), picks a pipeline or fan-out shape from the data dependencies, writes self-contained agent prompts with exact targets and carried-forward context, spawns the agents, then triages their reports and relays one coherent result. Use it before hand-rolling a large TS task (feature + tests + review, multi-package refactor, migration, audit) in the main thread. |
| [planning-ralph-task](skills/planning-ralph-task/) | Writes a **single-file autonomous task document** for the Ralph loop: the whole requirement in one `<task-name>.TASK.md`, split into ordered, verifiable tasks, plus a `<task-name>.progress.txt` tracker that lets each fresh iteration resume where the last one stopped. Runs a mandatory Open Questions Review until a full pass finds zero open questions, so the unattended executor never has to guess, and opens every document with a no-commit rule that leaves the diff for a human to review. For a story planned for humans, use [planning-stories](skills/planning-stories/) instead. |
| [planning-stories](skills/planning-stories/) | Breaks a user story into **independently testable tasks** — produces a `STORY.<name>.md` plan (and optional tech-spec), plus Ralph-loop `.TASK.md` files for autonomous implementation when requested. |
| [plantuml-diagramming](skills/plantuml-diagramming/) | Translates textual descriptions into **PlantUML diagrams** — sequence, class, activity, use case, state, component, object, and flowchart diagrams for processes, architectures, and workflows. |
| [speed-dating](skills/speed-dating/) | Scaffolds and maintains projects using the **speed dating method**: one self-contained kebab-case folder per project with a short `CLAUDE.md`, numbered source-of-truth files (`00-`, `01-`), `YYYY-MM-DD` date-prefixed deliverables, and `_`-prefixed support folders, so any project can be dropped mid-work and picked up cold later. |
| [writing-clean-shell](skills/writing-clean-shell/) | Organizes **shell scripts** (bash, zsh, sh, PowerShell) so anyone can read, update, and maintain them: every behavior becomes a function with a verb-first snake_case name, guard clauses come first, a steps-array orchestrator at the bottom doubles as the script's outline, and parameters get a `print_usage` help screen plus a consistent output vocabulary. Includes a cleanup command that reviews a script against every rule and fixes violations. |
| [writing-clean-ts](skills/writing-clean-ts/) | TypeScript code patterns for backend and frontend — services, repositories, DALs, entities, controllers, use cases, and React components following a strict layered clean-architecture convention. |
| [writing-tech-specs](skills/writing-tech-specs/) | Generates **lightweight technical specs** that capture WHAT changes — API endpoints, schema changes, and architecture deltas — with concise PlantUML diagrams, not implementation detail. |
| [writing-woodpecker-ci](skills/writing-woodpecker-ci/) | Migrates CI/CD pipelines **to Woodpecker CI** from GitHub Actions, GitLab CI, Jenkins, Semaphore, and Drone — translates pipeline steps, writes/debugs `.woodpecker.yml`, and sets up plugins, services, matrix builds, secrets, and when-conditions. |

### Skill installation

Install a skill with `npx skills add` (no global install needed).

**Choose from a list** — runs interactively and lets you pick which skill(s) to install:

```bash
npx skills add beecode-rs/claude-skills
```

**Install a single skill directly** — skip the list by appending `@<skill-name>`:

```bash
npx skills add beecode-rs/claude-skills@mom-test-coach
```

**Update installed skills** to the latest version:

```bash
npx skills update
```

Claude auto-discovers skills on startup and activates them based on the `description` in each `SKILL.md` — you don't need to configure anything else.


## Available agents

A small team of [Claude Code subagents](https://code.claude.com/docs/en/sub-agents): three `ts-*` specialists for TypeScript work in a pnpm monorepo, plus `code-explorer` for read-only code investigation and `ts-planner` for planning. Each one runs a delegated task in its own context window, with its own system prompt, tools, and model, and hands only its final report back to the main thread.

| Agent | What it does |
|-------|--------------|
| [code-explorer](agents/code-explorer.md) | **Read-only code investigation** and the first stop for any question about code you have not read yet: locates symbols, traces call paths and data flow, maps subsystems and module boundaries, and answers "where is X", "who calls Y", "how does this flow work", and "what breaks if I change Z". Uses codegraph for one-round-trip cross-file analysis when the project is indexed and Grep/Glob/Read when it is not, and returns navigable findings (`file:line`, call chains) instead of file dumps, so the caller's context stays lean. Never modifies anything. Runs on Haiku. |
| [ts-implementer](agents/ts-implementer.md) | Implements a **well-scoped TypeScript task end to end** in a pnpm monorepo: invokes the `writing-clean-ts` and `mono-repo-typescript` skills, reads the target package, and mirrors its naming, structure, and comment density. Stays inside the task's scope and adds no dependencies without asking. Before finishing, it runs typecheck/build for the touched package and reports the result, a short summary of what changed, and any decisions or open questions. Runs on Sonnet with full tool access. |
| [ts-planner](agents/ts-planner.md) | **Breaks a TypeScript task into an orchestration plan** instead of writing code: inspects the repo to see which packages and areas are involved, routes each piece of work to the best-fit agent (the `ts-*` specialists or the built-in `Explore`, `Plan`, `general-purpose`, and `claude-code-guide` agents), picks a sequential pipeline, a parallel fan-out, or a single agent based on the data dependencies, and drops any agent that adds no value. Returns a ready-to-run plan with the exact prompt for each step; it never spawns agents itself, because only the main thread can. Runs on Opus. |
| [ts-reviewer](agents/ts-reviewer.md) | Skeptical **read-only reviewer** for diffs and existing code: applies the `writing-clean-ts` and `mono-repo-typescript` skills to find correctness bugs (logic, edge cases, async, types), reuse and simplification opportunities, dead code, and missing or weak test coverage checked against the `contract.yaml` conventions. Reports only findings it can justify, marks uncertain ones as uncertain, cites every finding as `file:line`, and leads with the highest-severity items. Never edits files. Runs on Opus. |
| [ts-tester](agents/ts-tester.md) | Writes **automated tests for a TypeScript change**, preferring `contract.yaml` tests through the `contract-testing-ts` skill over Vitest unit tests, and falling back to Vitest only for cases contracts cannot express (complex async sequences, dynamic assertions, internal call-order mocking). Reads the code under test and the package's existing tests and matches their style, naming, and fixtures. Before finishing, it runs the tests for the touched package and reports a short summary of the tests added plus any coverage gaps or open questions. Runs on Sonnet with full tool access. |

`ts-implementer` and `ts-reviewer` invoke the [writing-clean-ts](skills/writing-clean-ts/) and [mono-repo-typescript](skills/mono-repo-typescript/) skills while they work, so install those as well. To run several of these agents on one task (implement, test, then review), use the [orchestrating-ts-agents](skills/orchestrating-ts-agents/) skill in the main thread: it plans who does what and in what order, then spawns the agents, since only the main thread can spawn subagents. Use `ts-planner` when you want that plan on its own, without running it.

### Agent installation

`npx skills add` installs skills, not agents. Claude Code loads subagents from `.claude/agents/` (current project) or `~/.claude/agents/` (all your projects), so copy the agent files into one of those directories.

**From a local clone**, install every agent into the project:

```bash
mkdir -p .claude/agents
cp agents/*.md .claude/agents/
```

**Without a clone**, download a single agent:

```bash
mkdir -p ~/.claude/agents
curl -fsSL -o ~/.claude/agents/ts-implementer.md https://raw.githubusercontent.com/beecode-rs/claude-skills/main/agents/ts-implementer.md
```

## Available scripts

| Script | What it does |
|--------|--------------|
| [ralph.sh](scripts/ralph/ralph.sh) | Runs Claude Code **autonomously** in a bash loop against a `*.TASK.md` file: each iteration spawns a headless `claude` session that implements exactly one task, verifies it with the project's test and typecheck commands, marks it `[x]` or `[!]`, and appends learnings to a progress file for later iterations. Streams agent activity to the terminal, logs every iteration to disk, appends a run report (`<name>.report.md`) with cost and outcome, and exits on completion, stall, or safety limits. |
| [ralpho.sh](scripts/ralph/ralpho.sh) | The same loop driven by **opencode** instead of Claude Code: each iteration spawns a headless `opencode run` session with a model chosen from an interactive picker (Z.AI Coding Plan and Ollama models) or set through the optional `[model]` argument or `OPENCODE_MODEL`. Same task-file format, progress file, logs, and exit conditions as `ralph.sh`; its run report also records token counts. |

Both scripts live in `scripts/ralph/`; see its [README](scripts/ralph/) for requirements, installation, usage, and configuration. Task files (`*.TASK.md`) come from the [planning-ralph-task](skills/planning-ralph-task/) skill, or from [planning-stories](skills/planning-stories/) when you explicitly ask it for Ralph-loop files.

## License

All skills are licensed under the MIT License. Each skill folder contains its own `LICENSE.txt` (e.g. [`skills/mom-test-coach/LICENSE.txt`](skills/mom-test-coach/LICENSE.txt)) — copy, modify, and use freely, including commercially.
