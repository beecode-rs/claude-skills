# claude-skills

A collection of shared [Claude Code Skills](https://docs.claude.com/en/docs/claude-code/skills) — drop-in packages that teach Claude how to handle specific workflows, from customer-discovery interviews to TypeScript monorepo architecture.

Each skill lives under `skills/<name>/` as a `SKILL.md` (with frontmatter describing when it activates) plus supporting references, templates, and scripts.

Standalone shell tools live under `scripts/<name>/`, each with its own README and install instructions.

## Table of contents

<!-- toc -->

- [Available skills](#available-skills)
  - [Skill installation](#skill-installation)
- [Available scripts](#available-scripts)
- [License](#license)

<!-- tocstop -->

## Available skills

| Skill | What it does |
|-------|--------------|
| [mom-test-coach](skills/mom-test-coach/) | Validates product/startup ideas using **The Mom Test** — shapes the idea, finds the riskiest assumptions, crafts interview questions that surface facts (not compliments), debriefs raw notes, and reaches a proceed / pivot / kill verdict. Includes a mock-interview practice mode. |
| [writing-clean-ts](skills/writing-clean-ts/) | TypeScript code patterns for backend and frontend — services, repositories, DALs, entities, controllers, use cases, and React components following a strict layered clean-architecture convention. |
| [mono-repo-typescript](skills/mono-repo-typescript/) | TypeScript monorepo architecture with **pnpm workspaces** — package organization, shared libraries, ES module path aliases, centralized config, and Docker Compose orchestration. |
| [planning-stories](skills/planning-stories/) | Breaks a user story into **independently testable tasks** — produces a `STORY.<name>.md` plan (and optional tech-spec), plus Ralph-loop `.TASK.md` files for autonomous implementation when requested. |
| [writing-tech-specs](skills/writing-tech-specs/) | Generates **lightweight technical specs** that capture WHAT changes — API endpoints, schema changes, and architecture deltas — with concise PlantUML diagrams, not implementation detail. |
| [plantuml-diagramming](skills/plantuml-diagramming/) | Translates textual descriptions into **PlantUML diagrams** — sequence, class, activity, use case, state, component, object, and flowchart diagrams for processes, architectures, and workflows. |
| [writing-woodpecker-ci](skills/writing-woodpecker-ci/) | Migrates CI/CD pipelines **to Woodpecker CI** from GitHub Actions, GitLab CI, Jenkins, Semaphore, and Drone — translates pipeline steps, writes/debugs `.woodpecker.yml`, and sets up plugins, services, matrix builds, secrets, and when-conditions. |
| [speed-dating](skills/speed-dating/) | Scaffolds and maintains projects using the **speed dating method**: one self-contained kebab-case folder per project with a short `CLAUDE.md`, numbered source-of-truth files (`00-`, `01-`), `YYYY-MM-DD` date-prefixed deliverables, and `_`-prefixed support folders, so any project can be dropped mid-work and picked up cold later. |
| [writing-clean-shell](skills/writing-clean-shell/) | Organizes **shell scripts** (bash, zsh, sh, PowerShell) so anyone can read, update, and maintain them: every behavior becomes a function with a verb-first snake_case name, guard clauses come first, a steps-array orchestrator at the bottom doubles as the script's outline, and parameters get a `print_usage` help screen plus a consistent output vocabulary. Includes a cleanup command that reviews a script against every rule and fixes violations. |
| [ai-documentation](skills/ai-documentation/) | Investigates a codebase and writes **business documentation for non-developers** (PMs, founders, support, new team members): how the system behaves, what flows through it, and what happens when things fail. Produces a hub-and-spoke suite in `resource/ai-doc/` with a navigation README, topic files whose prose stays free of code identifiers, Mermaid flow diagrams, and a per-file "Where this lives in the code" anchor table for developers and AI agents. Refreshes an existing suite in place instead of rewriting it. |
| [orchestrating-ts-agents](skills/orchestrating-ts-agents/) | Plans and **runs multi-agent work** in a TypeScript / pnpm monorepo: routes each piece to the right specialist (`ts-implementer`, `ts-tester`, `ts-reviewer`, `code-explorer`, `Plan`, `general-purpose`), picks a pipeline or fan-out shape from the data dependencies, writes self-contained agent prompts with exact targets and carried-forward context, spawns the agents, then triages their reports and relays one coherent result. Use it before hand-rolling a large TS task (feature + tests + review, multi-package refactor, migration, audit) in the main thread. |
| [commit-message](skills/commit-message/) | Generates **conventional commit messages** for staged changes and **squash PR merge messages** from the branch's commit log: reads the actual diff (or the PR's commits), applies its rules file (`{type}: {subject}` under 50 chars, lowercase, imperative), shows every message in chat first, and requires an explicit yes before any commit. Never pushes, never overrides the local author, and asks an extra are-you-sure before committing to `main`/`master`. |

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


## Available scripts

| Script | What it does |
|--------|--------------|
| [ralph](scripts/ralph/) | Runs Claude Code **autonomously** in a bash loop against a `*.TASK.md` file (produced by the planning-stories skill): each iteration spawns a headless `claude` session that implements exactly one task, verifies it with the project's test and typecheck commands, marks it `[x]` or `[!]`, and appends learnings to a progress file for later iterations. Streams agent activity to the terminal, logs every iteration to disk, and exits on completion, stall, or safety limits. |

## License

All skills are licensed under the MIT License. Each skill folder contains its own `LICENSE.txt` (e.g. [`skills/mom-test-coach/LICENSE.txt`](skills/mom-test-coach/LICENSE.txt)) — copy, modify, and use freely, including commercially.
