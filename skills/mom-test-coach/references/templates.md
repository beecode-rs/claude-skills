# Workspace File Templates

Templates for every file in the idea workspace. Fill them with the user's actual content - drop sections that genuinely don't apply, keep the structure otherwise so files stay comparable across ideas and across time.

## Contents

1. [00-idea.md - Idea brief](#00-ideamd)
2. [01-big-questions.md - Riskiest assumptions](#01-big-questionsmd)
3. [02-interview-script.md - Questions + cheat sheet](#02-interview-scriptmd)
4. [interviews/NN-who.md - Debrief](#interviewsnn-whomd)
5. [03-synthesis.md - Evidence + verdict](#03-synthesismd)

## 00-idea.md

```markdown
# Idea: <short name>

*Created: <date>. Status: exploring | interviewing | synthesized | killed | proceeding*

## Problem hypothesis
<One or two sentences. The problem, not the solution.>

## Who has it (customer slice)
<The specific segment after slicing. One sentence someone could use to point at a real person.>

- Wants it most because: ...
- Would pay first because: ...
- Found at: <specific communities/places>

## What they do about it today (guess)
<Current tools, workarounds, "nothing">

## Why I believe this
<Personal pain / observed / hunch - be honest about which>

## The solution I'm imagining (parked)
<One sentence, then ignore it until the problem is validated. It stays out of interviews.>
```

## 01-big-questions.md

```markdown
# The Three Big Questions

*The assumptions that kill the idea if wrong. Ranked by risk. Every interview must serve at least one.*

## 1. <Riskiest assumption, as a question>
- Why it's critical: ...
- Current evidence: <usually "none, just a hunch">
- What I'm afraid to hear: ...
- Status: unknown | strengthening | weakening | validated | invalidated

## 2. ...
## 3. ...
```

## 02-interview-script.md

```markdown
# Interview Script - <idea name>

## Opening frame (advice-seeking, not pitching)
"<Their exact casual ask, e.g.: 'You deal with X way more than I do - I'm trying to
understand how people handle it. Got 20 minutes for a coffee?'>"

## Questions
<5-8 questions. Each tagged with which Big Question it serves.>

1. <question> *(BQ1)*
2. ...

## Digging follow-ups
Why? / How so? / When was the last time? / What happened next? / Can you show me?

## Deflections
- Compliment → "Thanks - so back to <their current workaround>..."
- Fluff ("I always/would...") → "When was the last time? Walk me through it."
- Feature idea → "Why do you want that? What would it let you do?"

## Closers
- "What else should I have asked?"
- "Who else should I talk to about this?"
- (If it got serious) push for commitment: <the concrete next-step ask>

---
# Cheat sheet (print / second screen)

**BQ1:** <one line> · **BQ2:** <one line> · **BQ3:** <one line>

Q1 ... Q2 ... Q3 ... (short forms)

⚡ pain 🎯 goal 🔨 workaround 💰 money 😠/😍 emotion 💡 idea ☁️ fluff ⭐ next step

TALK LESS. Past, not future. Their life, not my idea.
```

## interviews/NN-who.md

```markdown
# Interview NN - <name/role>, <date>

**Context:** <where/how, warm or cold, how casual>
**Big questions targeted:** BQ1, BQ2

## Facts (the only data)
- <concrete past behavior, numbers, exact quotes>

## Signals
- ⚡ Pains: ...
- 🔨 Workarounds / current spend: ...
- 💰 Money: ...
- 😠 Emotions worth following up: ...

## Discarded
- Compliments: <listed so we're honest they happened>
- Fluff: <generic/future claims - note any we failed to anchor to a past instance>
- Feature ideas: <the request + the underlying why, if dug>

## Commitment / advancement
<What did they give up or agree to? Time / reputation / money. "None" is an answer.>

## Big question updates
- BQ1: <stronger / weaker / unchanged - why>
- BQ2: ...

## Interviewer coaching
<Where they pitched, fished, or accepted fluff; what worked; 1-2 fixes for next time>

## New leads
<"Who else should I talk to" results>
```

## 03-synthesis.md

```markdown
# Synthesis - <idea name>

*Based on interviews 01-NN, <date range>*

## Verdict: PROCEED | PIVOT / RE-SLICE | KILL

<Two or three sentences of plain-language justification.>

## Big question conclusions
| # | Big question | Conclusion | Evidence (interview #s) |
|---|---|---|---|
| 1 | ... | validated / invalidated / unknown | ... |

## Evidence strength check
- Problem occurs, described unprompted, recently: <yes/no - by whom>
- Money/time already spent on it: <yes/no - specifics>
- Commitments obtained: <list, or "none">

## Patterns across interviews
<Recurring pains, recurring workarounds, surprises, contradictions (possible slicing failure)>

## Next step
- PROCEED → smallest testable thing to build/offer next, and to whom
- PIVOT → the new problem/segment hypothesis; restart at 00-idea.md
- KILL → what was learned; better problems that surfaced along the way
```
