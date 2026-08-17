# Linting Workflow

How linting and formatting are done in every TypeScript project. The full ESLint rule inventory lives in [eslint-rules.md](eslint-rules.md); this file covers the tools, the scripts, and the policy.

## The Rule: Tools Lint, Not The Agent

Linting is NEVER done by hand. The agent never "fixes" lint or formatting issues by editing files when a lint tool can fix them, and never "simulates" linting by visually checking style. Formatting decisions belong to the tools.

| Action | Status |
|--------|--------|
| Run `lint-fix` scripts after writing or changing code | ✅ ALWAYS |
| Hand-edit code to fix something `eslint --fix`, `prettier --write`, or `jsonsort` can fix | ❌ NEVER |
| Report a lint error the tools cannot auto-fix, then fix the code manually | ✅ ONLY THIS |
| Skip setting up lint scripts because the project is small or new | ❌ NEVER |
| Decide formatting (quotes, width, sort order) case by case | ❌ NEVER |

Why: manual fixes drift from the project's rules and waste time. The tools are deterministic, so their output is always consistent with the configuration. The agent's job is to write code that already follows the rules (see [eslint-rules.md](eslint-rules.md)), then let the tools verify and correct.

## The Three Tools

| Tool | Scope | Fix | Check |
|------|-------|-----|-------|
| **ESLint** | TypeScript/JavaScript code rules (no loops, no ternary, naming, import order) | `eslint --fix` | `eslint --quiet` |
| **Prettier** | File formatting (quotes, width, semicolons) | `prettier --write` | `prettier --check` |
| **json-sort-cli** | JSON key sorting in `.json` files | `jsonsort -t` | `jsonsort -t -c` |

ESLint and Prettier are separate tools running side by side: ESLint owns code rules, Prettier owns formatting. Neither is wired through the other. JSON files are not covered by Prettier; `json-sort-cli` sorts their keys, which keeps object keys stable everywhere (the same idea as the `sort-keys-fix` ESLint rule for source code).

## package.json Scripts

Every TypeScript project has a `package.json`, and every one of them gets lint scripts. There are no exceptions for small or new projects.

### Single Project

```json
{
	"scripts": {
		"lint": "pnpm run lint:prettier && pnpm run lint:eslint && pnpm run lint:json",
		"lint-fix": "pnpm run lint-fix:prettier && pnpm run lint-fix:eslint && pnpm run lint-fix:json",
		"lint:eslint": "eslint ./ --quiet --no-error-on-unmatched-pattern",
		"lint-fix:eslint": "eslint ./ --fix",
		"lint:prettier": "prettier --check {**/*,*}.{js,ts,jsx,tsx,cjs,cts,mjs,mts,html}",
		"lint-fix:prettier": "prettier --write {**/*,*}.{js,ts,jsx,tsx,cjs,cts,mjs,mts,html}",
		"lint:json": "pnpm run lint-fix:json -c",
		"lint-fix:json": "jsonsort -t *.json '!./node_modules' '!./**/.env*'"
	}
}
```

### Monorepo (pnpm Workspaces)

Root `package.json` orchestrates; each package keeps its own ESLint scripts.

Root:

```json
{
	"scripts": {
		"lint": "pnpm run lint:prettier && pnpm run lint:eslint && pnpm run lint:packages && pnpm run lint:json",
		"lint-fix": "pnpm run lint-fix:prettier && pnpm run lint-fix:eslint && pnpm run lint-fix:packages && pnpm run lint-fix:json",
		"lint:eslint": "eslint ./ --quiet --no-error-on-unmatched-pattern",
		"lint-fix:eslint": "pnpm run lint:eslint --fix",
		"lint:packages": "pnpm -r run lint:eslint",
		"lint-fix:packages": "pnpm -r run lint-fix:eslint",
		"lint:prettier": "prettier --check {**/*,*}.{js,ts,jsx,tsx,cjs,cts,mjs,mts,html}",
		"lint-fix:prettier": "prettier --write {**/*,*}.{js,ts,jsx,tsx,cjs,cts,mjs,mts,html}",
		"lint:json": "pnpm run lint-fix:json -c",
		"lint-fix:json": "jsonsort -t *.json '!./packages' '!./node_modules' '!./**/.env*'"
	}
}
```

Each package:

```json
{
	"scripts": {
		"lint:eslint": "eslint ./ --quiet",
		"lint-fix:eslint": "eslint ./ --fix"
	}
}
```

In a monorepo, the ESLint configs come from a shared factory exported by the root `eslint.config.js` (`createNodeEslintConfig` / `createReactEslintConfig`), so a package config is only:

```javascript
import { createNodeEslintConfig } from '../../eslint.config.js'

export default createNodeEslintConfig({
	ignores: ['node_modules', 'coverage', 'dist', 'build', 'test/node_modules', 'test/dist', 'resource/*'],
})
```

## Prettier Configuration

`.prettierrc` (as a file, or a shared `*.mjs` module referenced from it in a monorepo):

```json
{
	"singleQuote": true,
	"trailingComma": "all",
	"tabWidth": 2,
	"semi": false,
	"printWidth": 120,
	"bracketSpacing": true,
	"arrowParens": "always",
	"endOfLine": "lf"
}
```

Pair it with a `.prettierignore` covering at least: `node_modules`, lockfiles (`pnpm-lock.yaml`, `package-lock.json`), build output (`dist`, `build`, `coverage`), `.env*` files (keep `!.env*.example`), and `.history`.

## Setting Up Linting In A New Project

When creating or scaffolding any TypeScript application:

1. Pick the flavor: **Node.js backend** or **React frontend** (see the flavor table in [eslint-rules.md](eslint-rules.md)). Match the package's runtime, not its folder name.
2. Write `eslint.config.js` (flat config) from the rule inventory in [eslint-rules.md](eslint-rules.md).
3. Write `.prettierrc` and `.prettierignore` as above.
4. Add the lint scripts to `package.json` as above.
5. Install the dev dependencies listed in [eslint-rules.md](eslint-rules.md).
6. Run `lint-fix` once over the codebase and verify `lint` passes clean before finishing.

Use the newest released versions of the tools and plugins when generating a config. The rule set is what stays fixed; the tool versions are always current at generation time (known-good floors: ESLint 9 flat config, typescript-eslint 8, Prettier 3, json-sort-cli 4). If a rule was renamed or folded into a newer preset, use its newest equivalent with the same intent, never silently drop it.

## Workflow During Development

After writing or editing code, ALWAYS:

1. Run the project's `lint-fix` script (or the targeted `lint-fix:eslint` / `lint-fix:prettier` / `lint-fix:json`).
2. Run the `lint` script and confirm it passes.
3. Only fix manually what the tools report but cannot auto-fix (for example a `no-console` violation needs a logger call, a naming-convention violation needs a rename). Fix the code, not the rule.
4. Never disable or downgrade a rule to make lint pass. If a rule genuinely cannot be satisfied, surface it to the user.

## What Linting Does NOT Replace

The lint tools enforce line-level style. They cannot see architecture: layer placement, naming suffixes per layer, object params discipline, barrel-file avoidance, controller thinness. Those checks stay manual review work (see [../commands/cleanup.md](../commands/cleanup.md)). Lint first, then review for architecture.
