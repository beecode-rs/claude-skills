# Clean Style Command

Scoped **style-only** review: validate TypeScript against line-level clean-code rules only. Architecture (layers, file placement, class-vs-object) is out of scope here — use `/clean-arch` for that, or `/cleanup` for both.

## Usage

When the user says: "review the style", "clean-style", "check readability", "style-only review", or explicitly wants only style feedback.

## Scope

Load and apply ONLY the `style/` docs:

- [code-style.md](../style/code-style.md) — no ternary, no inline arrows, no for-loops, multi-line, no comments
- [naming-convention.md](../style/naming-convention.md) — files, functions, vars, booleans, exports
- [function-guidelines.md](../style/function-guidelines.md) — error handling, name-covers-behavior, exhaustive switches
- [function-size.md](../style/function-size.md) — one responsibility, early returns, extract helpers
- [object-params-pattern.md](../style/object-params-pattern.md) — object params in business layers
- [timestamp-handling.md](../style/timestamp-handling.md) — Unix ms, `At` suffix, no `Date`

Do **not** load `architecture/*` for this pass.

Run the project's `lint-fix` and `lint` scripts first - items marked `[lint]` below are also enforced by the linter, so auto-fixable issues are already resolved and remaining violations come with a lint report that guides the manual fix.

## Checklist

Run each check; report violations with `file:line`.

1. **Comments** — none (only `// TODO: Remove when [condition]` is temporary)
2. **For-loops** — none (use `.map()` / `.reduce()` / `.filter()`) `[lint]`
3. **Ternary & inline arrows** — none (multi-line `if/else`, block-syntax arrows); ternary is lint-enforced (`no-ternary`), inline arrows are manual
4. **Naming** — kebab-case files, action verbs, boolean prefixes (`is`/`has`/`can`/`should`, incl. `Promise<boolean>` returns; DOM-mirror props like `disabled`/`checked` exempt), `At` timestamp suffix, falsy boolean defaults (no `= true` flags, no `!== false` / `=== true` checks; invert the name instead)
5. **Function size** — one responsibility, early returns, extracted helpers
6. **Object params** — business layers use object params (even 1 param); utility layer conditional
7. **Exports** — one element per file, no barrel `index.ts`, no exported instances

## Output

Report grouped by file. Each finding: `file:line`, the rule, and the fix.
