# Commit Message Rules

Generate commit messages in conventional commit format. NEVER generate plain descriptive sentences.

## Required Format
```
{type}: {description}

{body}
```

**You MUST start every commit message with a type from the allowed list, followed by a colon and space.**

## Allowed Types

Use ONLY these types:

- feat — new feature
- fix — bug fix
- chore — maintenance tasks
- docs — documentation only
- test — adding or updating tests
- ci — CI/CD changes
- build — build system or dependencies
- perf — performance improvement
- refactor — code change that neither fixes nor adds
- revert — reverting previous commit
- style — code formatting (whitespace, semicolons), not CSS

## Subject Line Rules

- MUST start with type and colon: `feat: `, `fix: `, `chore: `
- Use lowercase throughout
- Use imperative mood: "add" not "added" or "adding"
- Keep under 50 characters
- Do not end with a period
- Summarize the primary change only

## Body (Optional)

- Separate from subject with a blank line
- Use when multiple changes need explanation
- List secondary changes here, not in subject
- For breaking changes: add `!` after type and include `BREAKING CHANGE:` in body

## Examples

<example>
<input>Added login page and fixed header bug</input>
<output>
feat: add login page

Also fixes header alignment bug.
</output>
</example>

<example>
<input>Remove old Dockerfiles and add devcontainer</input>
<output>
chore: add devcontainer configuration

Remove legacy Docker templates and documentation.
</output>
</example>

<example>
<input>Updated dependencies</input>
<output>
chore: update dependencies</output>
</example>

<example>
<input>Fixed memory leak in websocket</input>
<output>
fix: resolve memory leak in websocket handler

Connection pool was not releasing closed connections.
</output>
</example>

## Invalid Formats — NEVER Generate These

❌ `Add devcontainer configuration and base image builder script`
   → Missing type prefix, too long, not imperative

❌ `feat: add new auth system with JWT tokens and refresh logic`
   → Too long — move details to body

❌ `feat: added login page`
   → Wrong tense

❌ `Added new feature for users`
   → Missing type, wrong tense, vague

## Output Rules

1. ALWAYS start with `{type}: `
2. ALWAYS keep subject under 50 characters
3. Pick ONE primary change for the subject
4. Put additional context in the body
