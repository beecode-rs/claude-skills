# Clean Style Command

Scoped **style-only** review: validate TypeScript against line-level clean-code rules only. Architecture (layers, file placement, class-vs-object) is out of scope here — use `/clean-arch` for that, or `/cleanup` for both.

## Usage

When the user says: "review the style", "clean-style", "check readability", "style-only review", or explicitly wants only style feedback.

## Scope

Apply ONLY the line-level style rules: code style (no ternary, no inline arrows, no for-loops, multi-line, no comments), naming (files, functions, vars, booleans, exports), function guidelines (error handling, name-covers-behavior, exhaustive switches), function size (one responsibility, early returns, extract helpers), object params in business layers, and timestamp handling (Unix ms, `At` suffix, no `Date`). Architecture rules are out of scope for this pass.

In an Expo project (`expo` / `expo-router` dependency), `src/app/` route filenames, `index.tsx` routes, `@/` imports, and platform-variant files are exempt from the naming, barrel, and import checks.

If the project has no `lint` / `lint-fix` scripts (or no ESLint config), set linting up first following `references/linting.md` ("Setting Up Linting"), then run. Run `lint-fix`, then `lint`: items marked `[lint]` below are verified ONLY by the lint report, never by reading the code or asking an AI agent or AI reviewer to judge them - fix what the report flags and re-run until clean. The unmarked items are the manual style review the scripts cannot replace.

## Checklist

Run each check; report violations with `file:line`.

1. **Comments** — none (only `// TODO: Remove when [condition]` is temporary)
2. **For-loops** — none (use `.map()` / `.reduce()` / `.filter()`) `[lint]`
3. **Ternary & inline arrows** — none (multi-line `if/else`, block-syntax arrows); ternary is lint-enforced (`no-ternary`), inline arrows are manual
4. **Naming** — kebab-case files, action verbs, boolean prefixes (`is`/`has` only, incl. `Promise<boolean>` returns, and the prefix comes first: `isNewerVersion` not `resolveIsNewerVersion`; DOM-mirror props like `disabled`/`checked` exempt), `At` timestamp suffix, falsy boolean defaults (no `= true` flags, no `!== false` / `=== true` checks; invert the name instead); names describe what a thing is, not where it is used; enum files `-enum.ts` / `-mapper-enum.ts` with no `Enum` suffix on the export; `type` not `interface` for shapes, no `I` on types; constant keys nested, regex keys end in `Regex`, time keys in `Ms`
5. **Function size** — one responsibility, early returns, extracted helpers
6. **Object params** — business layers use object params (even 1 param); utility layer conditional; `params`/`props` destructured on the first line with no `params.x` reads after it; defaults in the signature, never in the destructure
7. **Exports** — one element per file, no barrel `index.ts`, no exported instances, no module-level helpers or constants, no `_` members on plain objects
8. **Functional style** — no mutation of params or anything reachable from them; return new values
9. **Exhaustive switches** — a switch covering every enum member throws `typeUtil.exhaustiveError` in `default`

## Output

Report grouped by file. Each finding: `file:line`, the rule, and the fix.
