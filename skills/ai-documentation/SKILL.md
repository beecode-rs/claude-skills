---
name: ai-documentation
description: Investigate a codebase and write business-logic documentation for non-developers — how things work, what flows through the system, who talks to whom — as a hub-and-spoke suite in resource/ai-doc/ with Mermaid flows and per-file code anchors. Make sure to use this skill whenever the user asks to document a project or codebase, explain a system to stakeholders, PMs, founders, or support, onboard someone non-technical, capture or write up business flows, produce architecture or system overview docs, or refresh an existing ai-doc suite — even if they never say "ai-doc" or "business logic documentation".
allowed-tools: Read, Write, Edit, Grep, Glob, Bash, Agent, ToolSearch
---

# AI Documentation

Investigate a codebase and write documentation that explains **how the system
behaves** rather than how the code is written. The reader is a product manager,
founder, support lead, or new team member who needs an accurate mental model of
the product without reading a single line of code.

This runs in the main conversation on purpose: the investigation depends on
fanning out to `code-explorer` subagents, and a subagent cannot spawn subagents.
Delegating the reading is what keeps enough context free to actually write well.

## The two readers, and why the format is shaped this way

Every file you write serves two audiences at once:

- **A person** who wants to understand the product. They get flowing prose,
  business vocabulary, and diagrams. Code paths and class names mean nothing to
  them and break their reading.
- **A future AI agent** loading these docs to orient in the codebase fast. It
  needs the opposite: exact file paths to jump to.

Serving both in the same paragraph ruins the doc for both. So the two are
**physically separated**: the body of each topic file is pure business prose with
no identifiers at all, and a single `## Where this lives in the code` section at
the bottom carries every path and symbol name. The person stops reading before
that section; the agent skips straight to it. Respect that boundary — a file path
leaking into the prose is a real defect, not a stylistic nit.

## Where the docs go

Default output is `resource/ai-doc/` relative to the repository root (find it with
`git rev-parse --show-toplevel`; if that fails, use the directory you were pointed
at). If the user named a different path, use theirs.

**If a suite already exists there, you are updating it, not replacing it.** Read
every existing file first. Then:

- Correct anything the code now contradicts, and keep the rest of the wording
  intact — gratuitous rewrites destroy the reader's familiarity and make the diff
  unreviewable.
- Add files for areas that appeared since the last pass; delete files for areas
  that are genuinely gone (say so in your report).
- Refresh the README's navigation table so it still matches what's on disk.

Use `Edit` for targeted corrections and `Write` only for new files or a file whose
subject changed wholesale.

## Investigate before you write a word

Documentation that is confidently wrong is worse than no documentation, because
it gets quoted in meetings. Everything you write must be something you traced in
the code.

1. **Orient.** Read the repo's own README, `package.json`/manifest, and directory
   layout to learn what the product claims to be and where the code lives. Treat
   these as claims to verify, not facts — a stale README is the most common source
   of wrong documentation.
2. **Check for codegraph.** If `.codegraph/` exists at or above the repo root,
   load `codegraph_explore` via `ToolSearch` and use it: one call returns the
   relevant symbols' source plus the call paths between them, including dynamic
   dispatch that grep cannot follow. This is much faster than a grep-and-read
   loop for tracing a flow end to end.
3. **Fan out with `code-explorer`.** Spawn several `code-explorer` agents in a
   single message — one per subsystem you've identified (auth, payments,
   notifications, whatever the repo actually has). Each returns findings rather
   than file dumps, which keeps your own context free for writing. Ask each one
   specific questions: what triggers this, what does it do in order, what does it
   call, what does it store, what happens when it fails. Ask for `file:line`
   anchors in the answer — you need those for the code-anchor tables, and
   re-deriving them later costs another pass.
4. **Trace the flows yourself for anything load-bearing.** For the handful of
   flows at the heart of the product, read the actual entry points and follow them.
   Delegated summaries are good for breadth; your own reading is what makes the
   central flows trustworthy.

**When the code contradicts a comment, a README, or a ticket, the code wins** —
and say in your final report that you found the contradiction. Those are often the
most valuable thing you surface.

Never document behavior you only inferred from a name. `retryFailedPayments`
might not retry anything. If you could not confirm how something works, either
leave it out or mark it explicitly (see *Being honest about gaps*).

## Translate mechanics into outcomes

The move is always from *what the machine does* to *what it means for someone*:

| In the code | In your docs |
| --- | --- |
| Database query | Looking up the customer's saved details |
| Authentication middleware | Checking that you are who you say you are |
| Event queue | A waiting list of jobs the system works through in order |
| API endpoint | The door where another system hands us a request |
| Cache invalidation | Throwing away a saved answer because it's now out of date |
| Webhook | The other service calling us back when it's finished |
| Retry with backoff | Trying again, waiting a little longer each time |

Two habits make this land:

- **Why before how.** Open each section with the reason the thing exists. "Orders
  are held for review before charging so that a human can catch fraud" tells the
  reader more than three paragraphs of the review pipeline ever will.
- **Answer the questions a reader actually has.** What happens when a user signs
  up? Where does their data go and who else sees it? What happens when a payment
  fails, and does the customer find out? Which parts of this depend on a company
  we don't control? Documentation organized around those questions gets read;
  documentation organized around the module tree doesn't.

## Suite structure

### `README.md` — the hub

This is the only file that links to other files. Hub-and-spoke means each topic
file can be regenerated or moved without hunting for links that now point
nowhere, and it means the reader always has one reliable place to navigate from.

```markdown
# <Product name> — how it works

<Two or three sentences: what this product does and for whom.>

**Documented from:** commit <short sha> on <date>

## The shape of the system
<A short orientation — the major moving parts and how they relate. One Mermaid
diagram at the highest useful altitude.>

## Documentation map

| Document | What it covers |
| --- | --- |
| [Signing in and permissions](authentication.md) | How people prove who they are and what each role can do |
| ... | ... |

## Where to start
<Point the reader at the two or three documents that matter most for them.>
```

Get the commit and date with `git rev-parse --short HEAD` and `git log -1 --format=%cs`.
A reader six months from now needs to know how stale this is.

### Topic files

One subject per file, named for what a reader would search for
(`authentication.md`, `payments.md`, `notifications.md`,
`external-integrations.md`, `data-storage.md`). Group by *what it does for the
user*, not by folder — if login logic is spread across four directories, it is
still one document.

```markdown
# <Subject, in the reader's words>

## Why this exists
<The business need. Two to four sentences.>

## How it works
<The flow, in order, in prose. Then a Mermaid diagram of it.>

## What can go wrong
<Failure cases the business cares about, and what the system does about each.
This section is usually the most-read one — do not skip it.>

## Rules and limits
<Business rules a stakeholder would be surprised by: thresholds, timeouts,
who-can-do-what, hard-coded limits.>

## Where this lives in the code
<The only place in this file where paths appear. See below.>
```

Adapt the headings when the subject calls for it — a document about a third-party
integration might want "What we depend on them for." The four core moves (why,
how, failure, rules) should survive in some form, because that's the set of
questions readers keep having.

Aim for something a reader finishes in five to ten minutes. If a file grows past
that, it's two subjects.

### The code-anchor section

Close every topic file with a table, and put nothing after it:

```markdown
## Where this lives in the code

*For developers and AI agents — the rest of this document deliberately avoids code references.*

| What | Where |
| --- | --- |
| Login request comes in | `src/routes/auth.ts` |
| Password checking | `src/services/auth/verify-credentials.ts` |
| Session storage | `src/repository/session.ts` |
```

Paths must be real and repo-relative — verify each one exists before you write it.
A wrong path here costs an agent more time than an empty table would.

## Diagrams

Use Mermaid, in fenced ```mermaid blocks — it renders in GitHub, VS Code, and
Claude artifacts without any tooling.

- `flowchart TD` for a process with branches — the workhorse.
- `sequenceDiagram` when the point is *who talks to whom in what order*, especially
  across services or with a third party.
- `stateDiagram-v2` for a lifecycle (an order moving from placed to delivered).

What makes a diagram useful to a non-technical reader:

- **Label nodes in business language.** `Check who you are`, not `authMiddleware`.
  The diagram has to work for someone who skipped the prose.
- **Keep it to roughly a dozen nodes.** Past that, nobody traces it. Split into
  two diagrams at different altitudes instead.
- **Show the unhappy path.** Where the flow branches on failure, draw the branch —
  that's usually the part the reader came for.
- **Keep it renderable.** Quote any label containing parentheses, commas, colons,
  or quotes (`A["Charge card (with retry)"]`), give every node a short id, and
  don't nest subgraphs more than one deep. A diagram that fails to render is worse
  than a paragraph.

One diagram per major flow. A diagram that just restates the paragraph above it in
boxes is noise — drop it.

## Being honest about gaps

You will hit code you can't fully resolve in reasonable time: a hairy legacy path,
a config-driven branch, dead code you can't prove is dead. Marking those is a
feature of the document, not an admission of failure — it tells the team exactly
where to point an expert.

Mark it inline where the reader would otherwise be misled:

> **Unverified:** Refunds appear to be capped at the original charge amount, but the
> check happens in a shared helper that several other flows also use, so this may
> behave differently for partial refunds. Worth confirming with engineering.

Never smooth over uncertainty with confident prose. And never invent a business
rationale for something you don't understand — say the flow exists and that its
purpose is unclear.

## When you're done, report back

Close the turn with this summary in the conversation, so the user knows what to
trust and what to check:

```markdown
## What I documented
<Two or three sentences on the scope of this pass, and the commit it reflects.>

## Files
| File | Covers |
| --- | --- |
| `resource/ai-doc/README.md` | Entry point and navigation |
| ... | ... |

## Coverage
<What you documented thoroughly, what you covered only at a high level, and what
you deliberately left out and why.>

## Contradictions found
<Places where the code disagreed with an existing README, comment, or doc. Omit
this section only if there were none.>

## Open questions for product and engineering
<The specific things a human needs to answer, phrased so they can be answered
without reading code. Name the file each question affects.>
```

Lead with what's uncertain rather than burying it — the value of this pass is as
much in the honest map of what's unclear as in the prose itself.
