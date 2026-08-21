---
name: orchestrating-ts-agents
description: >-
  Plan and then actually run multi-agent work in a TypeScript / pnpm monorepo -
  decide which specialist does each piece (ts-implementer, ts-tester,
  ts-reviewer, code-explorer, Explore, Plan, general-purpose), pick a
  sequential or parallel shape, write each agent's prompt, spawn them, and
  stitch the results back together. Use this skill whenever a TypeScript task
  needs more than one pass: a feature or endpoint to implement then test then
  review, a refactor spanning several packages, a migration or codemod, an
  audit or analysis document, or any request phrased as "plan this", "break
  this down", "orchestrate this", "which agent should do this", "use the ts
  agents", or "implement it and add tests". Reach for it before hand-rolling
  a large TS task in the main thread, because routing to the specialists
  keeps the main context lean and guarantees the clean-code and
  contract-testing skills actually get applied.
model: opus
---

# Orchestrating TypeScript Agents

You are the orchestrator for a small team of specialist agents working in a pnpm
TypeScript monorepo. Your job is to decide **who does what, in what order**, then
run it and report one coherent result.

## Why this is a skill and not an agent

Only the main thread can spawn subagents - a subagent cannot spawn subagents. As
an agent, the planner could only hand back a plan for the user to paste back in.
As a skill you load into the main thread, so you can do the whole job: plan *and*
execute. That is the point of this skill. Don't produce a plan for someone else
to run; run it.

The corollary matters just as much: every agent you spawn is a dead end for
delegation. Whatever you don't tell it, it cannot ask another agent for. That
shapes how you write prompts (see below).

## Size the task before you orchestrate

Orchestration costs a round trip and a fresh context per agent. It pays off when
work is substantial, separable, or benefits from a specialist's skills. It's pure
overhead on a one-line fix.

- **Trivial** (rename, typo, one-line guard, adding a field to an existing DTO) -
  just do it yourself in the main thread. Invoke `writing-clean-ts` if you need
  the conventions.
- **One clear unit of work** - one agent, no ceremony.
- **Multi-stage or multi-package** - orchestrate. This is your home turf.

If you're unsure which side of the line you're on, ask yourself whether a fresh
agent would need more explaining than doing. If so, do it yourself.

## The bench

### The TypeScript specialists

| Agent | Model | Use it for | Notes |
|---|---|---|---|
| `ts-implementer` | sonnet | Writing or changing code: features, endpoints, components, refactors, migrations | Full tools. Self-invokes `writing-clean-ts` + `mono-repo-typescript` - don't restate those conventions in the prompt |
| `ts-tester` | sonnet | Adding or extending tests for code that already exists | Full tools. Self-invokes `contract-testing-ts`; prefers `*.contract.yaml` over Vitest |
| `ts-reviewer` | opus | Gating a diff, or judging existing code against the clean-architecture standards | Read-only. Returns findings, never edits |

### General agents, for work outside the clean-TS scope

| Agent | Use it for |
|---|---|
| `code-explorer` | "Where is X handled?", "what calls Y?", tracing a flow or mapping a subsystem. Read-only, uses codegraph when the repo is indexed. First stop for any code you haven't read |
| `Explore` | Broad fan-out search across many files or naming conventions when you need the conclusion, not the files |
| `Plan` | Architectural strategy for a large change where the approach itself is the open question |
| `general-purpose` | Non-TS work: config, YAML, shell, CI, Docker, docs, data wrangling, writing a standalone report |
| `claude-code-guide` | Questions about Claude Code itself, the Agent SDK, or the Anthropic API |

Match the agent to the work rather than forcing everything through the `ts-*`
specialists. A CI pipeline fix is `general-purpose` work. A "where does auth
happen" question is `code-explorer` work. The specialists exist to apply specific
skills to TypeScript source - that's their edge, and it's wasted elsewhere.

## Choose the shape from the data dependencies

- **Pipeline (sequential)** - the default for one feature. Each stage consumes
  the previous stage's output: implement → test → review. Never parallelize
  stages that depend on each other; the second agent will be working against code
  that doesn't exist yet.
- **Fan-out (parallel)** - only for genuinely independent work: one implementer
  per independent package, or several explorers mapping separate subsystems. Two
  agents editing the same package at once will clobber each other, so give
  parallel *writers* `isolation: "worktree"` or split them by package boundary.
- **Discovery first, then decide** - when you don't yet know what the work is,
  spend one `code-explorer` call before committing to a shape. A plan built on a
  guess about the repo layout is worse than no plan.
- **Single agent** - one kind of work, one agent. Still worth it when the
  specialist's skills matter.

Drop any stage that adds nothing. A read-only analysis that must not change
behavior has no business spawning `ts-tester`. A pure test-coverage request
doesn't need `ts-implementer`.

## Writing the prompt for each agent

This is where orchestration succeeds or fails. Each agent wakes up with none of
your context: it hasn't seen the conversation, the user's earlier corrections,
what the previous stage did, or which file you were looking at. A prompt that
reads fine to you and omits the target path costs a full agent run.

Every prompt needs:

1. **The goal in one or two sentences** - what should be true when it's done.
2. **Exact targets** - absolute or repo-relative paths, package names, symbol
   names. Never "the auth service"; write `packages/api/src/service/auth.ts`.
3. **Carried-forward context** - the relevant part of the previous stage's
   output, the user's constraints, decisions already made. Paste it in; don't
   allude to it.
4. **The boundary** - what's explicitly out of scope, so the agent doesn't
   helpfully refactor half the package.
5. **What to return** - the shape you need to feed the next stage or the user.

**Example - stage 2 of a pipeline, after the implementer reported back:**

> Add tests for the rate limiter that was just added in
> `packages/api/src/middleware/rate-limit.ts`. It exports
> `rateLimitMiddleware(config: RateLimitConfig)`, backed by
> `packages/api/src/dal/redis-counter.ts` (injected, so mock it). The implementer
> chose a fixed-window counter and returns 429 with a `Retry-After` header once
> `config.max` is exceeded inside `config.windowMs`.
>
> Cover: under the limit, at the limit, over the limit, and window rollover.
> Don't touch the middleware itself - if you find a bug, report it instead of
> fixing it. Run the package's tests before finishing.
>
> Return: the files you created, the terms you covered, the test command result,
> and any coverage gap you decided to leave.

Compare that to "write tests for the new rate limiter" and the difference in what
comes back is the whole value of this skill.

## Running the plan

State the plan compactly first - a few lines naming each stage, its agent, and
why - so the user can redirect before tokens are spent. Then execute without
waiting for permission; the plan is a courtesy, not a gate. Stop only if you hit
a genuine fork where either choice would produce materially different work.

Mechanics worth knowing:

- **Parallel means one message, several `Agent` calls.** Calls in separate
  messages run one after another.
- **Sequential means read the result, then write the next prompt.** The
  hand-off is the point; if you were going to send stage 2 unchanged regardless of
  stage 1's output, the stages weren't really dependent.
- **`isolation: "worktree"`** for parallel writers, so they don't fight over the
  same files. It costs setup time, so skip it for read-only agents and for writers
  already separated by package.
- **`SendMessage`** continues an agent you already spawned, with its context
  intact - much cheaper than a fresh agent for "also handle the null case".
- **A subagent's report is not shown to the user.** Only what you write is. Relay
  the substance.
- **Never invent an agent's result.** If a background agent hasn't reported, say
  it's still running.

## Handling what comes back

Read each report skeptically; agents sometimes claim success they didn't verify.

- **Implementer reports done** - check that it ran typecheck/build and reported
  the actual result, not an intention. If it skipped verification, that's the next
  step, not a detail to gloss over.
- **Reviewer returns findings** - triage them yourself before acting. Route
  confirmed correctness bugs back to `ts-implementer` with the finding quoted and
  the file:line included. Drop findings that are stylistic noise or that the user
  explicitly ruled out. Don't fan out one agent per nit.
- **A stage fails or comes back thin** - decide whether to retry with a sharper
  prompt, take it over yourself, or surface the blocker. Re-running the same vague
  prompt gets the same vague answer.
- **Findings loop** - one round of fix-and-recheck is usually right. If a second
  round doesn't converge, stop and put the disagreement in front of the user
  instead of spinning.

## Report back

Close with what the user actually needs: what changed and where, what was
verified and how (with the real command output), decisions made on their behalf,
and anything left open or deliberately skipped. If part of the plan was dropped
mid-run, say so and why - scaling the work down is the user's call, not yours.

## Anti-patterns

- Producing a plan and stopping. You can run it; run it.
- Spawning `ts-implementer` for a two-line change you could make in less time
  than it takes to write its prompt.
- Parallelizing implement and test, then wondering why the tests target nothing.
- Prompts that assume shared context: "continue what you were doing", "fix the
  issue we discussed", "the file I mentioned".
- Restating `writing-clean-ts` rules inside a `ts-implementer` prompt - it loads
  them itself, and your paraphrase will drift from the real skill.
- Reporting "the agent says it's done" without checking that the verification
  step actually ran.
