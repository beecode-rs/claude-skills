# Linting

How linting and formatting are done in every TypeScript project (ESLint, Prettier, json-sort-cli), followed by the complete ESLint rule inventory for generating configs.

## Contents

- [Linting Workflow](#linting-workflow)
  - [The Rule: Tools Lint, Not The Agent](#the-rule-tools-lint-not-the-agent)
  - [The Three Tools](#the-three-tools)
  - [What The Lint Scripts Check](#what-the-lint-scripts-check)
  - [package.json Scripts](#packagejson-scripts)
  - [Prettier Configuration](#prettier-configuration)
  - [Setting Up Linting (New Or Unconfigured Project)](#setting-up-linting-new-or-unconfigured-project)
  - [Workflow During Development](#workflow-during-development)
  - [What Linting Does NOT Replace](#what-linting-does-not-replace)
- [ESLint Rule Set](#eslint-rule-set)
  - [Two Flavors](#two-flavors)
  - [Dependencies](#dependencies)
  - [Baseline Presets](#baseline-presets)
  - [Naming Convention Table](#naming-convention-table)
  - [Shared Rules (Both Flavors)](#shared-rules-both-flavors)
  - [Flavor Deltas](#flavor-deltas)
  - [Standard Ignores](#standard-ignores)
  - [Complete Config Template](#complete-config-template)

## Linting Workflow

How linting and formatting are done in every TypeScript project. This section covers the tools, the scripts, and the policy; the full ESLint rule inventory follows it.

### The Rule: Tools Lint, Not The Agent

Every check the lint scripts can make is made by RUNNING the scripts - never by the agent. The agent runs `lint-fix` and `lint`, reads their output, and fixes what they report. It never "simulates" linting by visually checking style, never re-checks by eye a rule the scripts already enforce, and never delegates a lint check to another AI agent or AI reviewer as a substitute for running the script. For everything the scripts cover, the script's exit status and report are the only valid verdict.

Setup is a precondition, not an option: if the project has no `lint` / `lint-fix` scripts (or no ESLint config), set linting up FIRST using the procedure below, then run it. This applies to existing unconfigured projects, not just new ones, and there is no exception for small or throwaway projects. Falling back to agent judgment because linting is not configured is the exact failure this rule exists to prevent.

| Action | Status |
|--------|--------|
| Run `lint-fix` scripts after writing or changing code | ✅ ALWAYS |
| Set up lint scripts first when the project has none, then run them | ✅ ALWAYS |
| Hand-edit code to fix something `eslint --fix`, `prettier --write`, or `jsonsort` can fix | ❌ NEVER |
| Report a lint error the tools cannot auto-fix, then fix the code manually | ✅ ONLY THIS |
| Check a `[lint]` rule by reading the code instead of running the script | ❌ NEVER |
| Ask an AI agent or AI reviewer to judge lint-enforced style instead of running the script | ❌ NEVER |
| Skip setting up lint scripts because the project is small or new | ❌ NEVER |
| Decide formatting (quotes, width, sort order) case by case | ❌ NEVER |

Why: the tools are deterministic, so their verdict is reproducible and always consistent with the configuration; agent judgment is neither. The agent's job is to write code that already follows the rules, then let the tools verify and correct.

### The Three Tools

| Tool | Scope | Fix | Check |
|------|-------|-----|-------|
| **ESLint** | TypeScript/JavaScript code rules (no loops, no ternary, naming, import order) | `eslint --fix` | `eslint --quiet` |
| **Prettier** | File formatting (quotes, width, semicolons) | `prettier --write` | `prettier --check` |
| **json-sort-cli** | JSON key sorting in `.json` files | `jsonsort -t` | `jsonsort -t -c` |

ESLint and Prettier are separate tools running side by side: ESLint owns code rules, Prettier owns formatting. Neither is wired through the other. JSON files are not covered by Prettier; `json-sort-cli` sorts their keys, which keeps object keys stable everywhere (the same idea as the `sort-keys-fix` ESLint rule for source code).

### What The Lint Scripts Check

The checks are defined as executable scripts - the `package.json` scripts below (a plain shell script wrapping the same commands is equivalent). Each row is verified by RUNNING the script; the agent treats the script's exit status and report as the only valid verdict for that row, and never re-derives it by reading code or asking an AI reviewer.

| Script | Tool | What it verifies | Auto-fix |
|--------|------|------------------|----------|
| `lint:eslint` | ESLint | Every code rule in the inventory below: no loops, no ternary (Node flavor), braces on control flow, member naming conventions, import order/grouping, no relative imports (absolute `#src` only), inline type imports, sorted object keys, no `console`, no `.only` in tests, unused variables, explicit return types and member accessibility, floating promises, plus the type-checked strictness presets | Partially, via `lint-fix:eslint` |
| `lint:prettier` | Prettier | File formatting: quotes, semicolons, print width, tabs, trailing commas, line endings | Fully, via `lint-fix:prettier` |
| `lint:json` | json-sort-cli | Sorted keys in `.json` files | Fully, via `lint-fix:json` |

The conventions this skill marks `[lint]` map to concrete rules like this (the definitive list of what is script-enforced):

| `[lint]` convention | Rule | Auto-fixable |
|---|---|---|
| No for loops | `no-loops/no-loops` | No - rewrite manually |
| No ternary (Node backend) | `no-ternary` | No - rewrite manually |
| Braces on all control flow | `curly` | Yes |
| Sorted, grouped, deduped imports | `import/order`, `sort-imports`, `no-duplicate-imports`, `import/newline-after-import` | Yes |
| Absolute `#src` imports only | `no-relative-import-paths/no-relative-import-paths` | Yes |
| Inline type imports (`import { type X }`) | `@typescript-eslint/consistent-type-imports` | Yes |
| Sorted object keys | `sort-keys-fix/sort-keys-fix` | Yes |
| Member naming (camelCase / PascalCase / UPPER_CASE, underscore rules) | `@typescript-eslint/naming-convention` | No - rename manually |
| No `console` | `no-console` | No - use the project logger |
| Unused variables | `@typescript-eslint/no-unused-vars` (warn) | No |
| Explicit return types and member accessibility | `@typescript-eslint/explicit-function-return-type`, `@typescript-eslint/explicit-member-accessibility` | No |

Not auto-fixable does not mean not script-checked: the linter still REPORTS every violation above. "Not auto-fixable" only decides who edits the code - the agent rewrites it by hand, guided by the lint report.

### package.json Scripts

Every TypeScript project has a `package.json`, and every one of them gets lint scripts. There are no exceptions for small or new projects.

#### Single Project

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

#### Monorepo (pnpm Workspaces)

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

### Prettier Configuration

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

### Setting Up Linting (New Or Unconfigured Project)

Mandatory precondition for ANY code task - writing a feature, reviewing, or "cleaning up": if the package's `package.json` has no `lint` / `lint-fix` scripts, or there is no ESLint config, set linting up FIRST and run it, before any other work. This covers joining an existing project without lint setup, not just scaffolding new ones. Never proceed without the scripts, and never substitute agent review for the missing scripts.

1. Pick the flavor: **Node.js backend** or **React frontend** (see the flavor table in the rule inventory below). Match the package's runtime, not its folder name.
2. Write `eslint.config.js` (flat config) from the rule inventory below.
3. Write `.prettierrc` and `.prettierignore` as above.
4. Add the lint scripts to `package.json` as above.
5. Install the dev dependencies listed in the rule inventory below.
6. Run `lint-fix` once over the codebase and verify `lint` passes clean before finishing.

Use the newest released versions of the tools and plugins when generating a config. The rule set is what stays fixed; the tool versions are always current at generation time (known-good floors: ESLint 9 flat config, typescript-eslint 8, Prettier 3, json-sort-cli 4). If a rule was renamed or folded into a newer preset, use its newest equivalent with the same intent, never silently drop it.

### Workflow During Development

After writing or editing code, ALWAYS:

0. If the project has no `lint` / `lint-fix` scripts, run the "Setting Up Linting" procedure above first - setup always precedes the first run.
1. Run the project's `lint-fix` script (or the targeted `lint-fix:eslint` / `lint-fix:prettier` / `lint-fix:json`).
2. Run the `lint` script and confirm it passes.
3. Only fix manually what the tools report but cannot auto-fix (for example a `no-console` violation needs a logger call, a naming-convention violation needs a rename). Fix the code, not the rule.
4. Never disable or downgrade a rule to make lint pass. If a rule genuinely cannot be satisfied, surface it to the user.

### What Linting Does NOT Replace

The lint tools enforce line-level style. They cannot see architecture: layer placement, naming suffixes per layer, object params discipline, barrel-file avoidance, controller thinness. Those checks stay manual review work. Lint first, then review for architecture.

The split runs both ways: everything in "What The Lint Scripts Check" above is verified ONLY by running the scripts - never by agent review - and everything the scripts do not cover is exactly the part the agent reviews manually.

## ESLint Rule Set

The complete rule inventory extracted from the reference monorepo (`~/code/visualiser`, shared config package `@app/config`). When generating an ESLint config for any new project, reproduce this rule set with the newest released tool versions. The rules are the fixed part; versions are always current at generation time.

One addition beyond the reference repo: `no-relative-import-paths` enforces the skill's absolute-import policy (internal imports go through the `#src` alias only, never `./` or `../`).

### Two Flavors

| Flavor | Factory | Use For | Config Source |
|--------|---------|---------|---------------|
| **Node.js backend** | `createNodeEslintConfig` | Express services, RMQ consumers, CLI packages, GraphQL | `src/eslint/node.mjs` |
| **React frontend** | `createReactEslintConfig` | React apps and React shared packages | `src/eslint/react.mjs` |

The two flavors are ~95% identical. Both are plain TypeScript strictness configs; notably the React flavor uses NO React-specific plugins (no `eslint-plugin-react`, no `eslint-plugin-react-hooks`). Pick the flavor by the package's runtime, then apply the deltas listed at the end of this file.

### Dependencies

```json
{
	"devDependencies": {
		"@eslint/js": "latest",
		"eslint": "latest",
		"eslint-plugin-import": "latest",
		"eslint-plugin-no-loops": "latest",
		"eslint-plugin-no-only-tests": "latest",
		"eslint-plugin-no-relative-import-paths": "latest",
		"eslint-plugin-sort-keys-fix": "latest",
		"globals": "latest",
		"json-sort-cli": "latest",
		"prettier": "latest",
		"typescript-eslint": "latest"
	}
}
```

`eslint-config-prettier` may be kept around as a dependency for turning off stylistic rules that conflict with Prettier, but the current configs do not extend it; conflicting core rules are turned off by hand instead (see the shared rules below).

### Baseline Presets

Every config starts from these; custom rules below layer on top:

```javascript
import eslintJs from '@eslint/js'
import tseslint from 'typescript-eslint'
import { defineConfig } from 'eslint/config'
import globals from 'globals'

// base blocks, in order:
{ files: ['**/*.{js,mjs,cjs,ts}'] }
{ files: ['**/*.{js,mjs,cjs,ts}'], languageOptions: { globals: globals.browser } } // node flavor may use globals.node to match its runtime
{ files: ['**/*.{js,mjs,cjs,ts}'], plugins: { eslintJs }, extends: ['eslintJs/recommended'] }
tseslint.configs.recommendedTypeChecked
tseslint.configs.strictTypeChecked
tseslint.configs.stylisticTypeChecked
{
	languageOptions: {
		parser: tseslint.parser,
		parserOptions: {
			projectService: true,
			tsconfigRootDir: import.meta.dirname,
		},
	},
}
```

The type-checked presets require `projectService: true` (TypeScript project awareness). The custom rules block applies to `files: ['**/*.ts']`.

### Naming Convention Table

`@typescript-eslint/naming-convention` is configured with this exact table (this is the enforced source of the member naming rules):

| Selector | Modifiers | Format | Underscore Rule |
|----------|-----------|--------|-----------------|
| `default` | `public` | any | leading underscore forbidden |
| `default` | `protected` | `camelCase` | leading underscore required |
| `default` | `private` | `camelCase` | `__` prefix |
| `accessor` | `public` | `camelCase` | leading underscore forbidden |
| `accessor` | `protected` | `camelCase` | leading underscore required |
| `accessor` | `private` | `camelCase` | `__` prefix |
| `enum` | | `PascalCase` | |
| `enumMember` | | `UPPER_CASE` | |
| `classMethod`, `accessor` | `public`, `static` | `PascalCase` | leading underscore forbidden |
| `classMethod`, `accessor` | `protected`, `static` | `PascalCase` | leading underscore required |
| `classProperty` | `public`, `static` | `UPPER_CASE` | |
| `objectLiteralProperty`, `objectLiteralMethod` | | `camelCase` | single or double leading underscore allowed |

### Shared Rules (Both Flavors)

#### TypeScript Rules

| Rule | Setting | Notes |
|------|---------|-------|
| `@typescript-eslint/ban-ts-comment` | `warn`, `ts-expect-error: allow-with-description` | |
| `@typescript-eslint/no-misused-spread` | `warn` | |
| `@typescript-eslint/consistent-type-definitions` | `off` | `interface` and `type` both allowed |
| `@typescript-eslint/dot-notation` | `off` | |
| `@typescript-eslint/explicit-function-return-type` | `error`, `allowExpressions: true` | explicit return types |
| `@typescript-eslint/explicit-member-accessibility` | `error`, `accessibility: no-public` | `protected`/`private` required, `public` omitted |
| `@typescript-eslint/naming-convention` | `error`, table above | |
| `@typescript-eslint/no-empty-interface` | `off` | |
| `@typescript-eslint/no-floating-promises` | `error` | |
| `@typescript-eslint/no-non-null-assertion` | `off` | `!` allowed |
| `@typescript-eslint/no-unused-vars` | `warn`, ignore patterns `^_` for args, caught errors, destructured array, vars | |
| `@typescript-eslint/no-unsafe-assignment` | `warn` | |
| `@typescript-eslint/no-unsafe-call` | `warn` | |
| `@typescript-eslint/no-unsafe-member-access` | `warn` | |
| `@typescript-eslint/no-unsafe-return` | `warn` | |
| `@typescript-eslint/no-unsafe-argument` | `warn` | |
| `@typescript-eslint/no-unsafe-enum-comparison` | `warn` | |

#### Import Rules

| Rule | Setting | Notes |
|------|---------|-------|
| `import/namespace` | `error`, `allowComputed: true` | |
| `import/newline-after-import` | `error` | |
| `import/no-unresolved` | `off` | TypeScript handles resolution |
| `import/order` | `error`, see below | |
| `no-relative-import-paths/no-relative-import-paths` | `error`, `allowSameFolder: false` | absolute imports via `#src` alias only; blocks ALL relative imports (`./` and `../`). Expo: add `prefix: '@', rootDir: 'src'` so fixes write `@/` paths |
| `sort-imports` | `error`, `ignoreDeclarationSort: true` | member sorting only; declaration order owned by `import/order` |
| `no-duplicate-imports` | `error` | |

`import/order` options:

```javascript
'import/order': [
	'error',
	{
		alphabetize: { caseInsensitive: false, order: 'asc' },
		groups: [['index', 'sibling', 'parent', 'internal', 'external', 'builtin', 'object']],
		'newlines-between': 'always',
	},
]
```

All import groups are merged into ONE group, so every import sorts together in a single alphabetized block (case-sensitive, ascending).

#### Code Rules

| Rule | Setting | Notes |
|------|---------|-------|
| `curly` | `error` | braces always |
| `lines-between-class-members` | `error`, `always`, `exceptAfterSingleLine: true` | |
| `no-confusing-arrow` | `error` | |
| `no-console` | `error` | use the project logger |
| `no-constant-condition` | `error` | |
| `no-mixed-spaces-and-tabs` | `error` | |
| `padding-line-between-statements` | `error`, see below | |
| `prefer-arrow-callback` | `error` | |
| `prefer-template` | `error` | |
| `no-loops/no-loops` | `error` | FOR LOOPS PROHIBITED |
| `no-only-tests/no-only-tests` | `error` | no `.only` in tests |
| `sort-keys-fix/sort-keys-fix` | `error`, `asc`, `caseSensitive: false`, `natural: true` | object keys sorted |

`padding-line-between-statements` options:

```javascript
'padding-line-between-statements': [
	'error',
	{ blankLine: 'always', next: 'return', prev: '*' },
	{ blankLine: 'always', next: ['cjs-export', 'export'], prev: '*' },
]
```

### Flavor Deltas

#### Node.js Backend Only

| Rule | Setting | Notes |
|------|---------|-------|
| `@typescript-eslint/consistent-type-imports` | `error`, `fixStyle: inline-type-imports` | `import { type X }` inline style |
| `@typescript-eslint/no-empty-object-type` | `off` | `{}` allowed |
| `no-ternary` | `error` | ternary PROHIBITED |

#### React Frontend Differences

| Rule | Setting | Difference vs Node |
|------|---------|--------------------|
| `no-ternary` | `warn` | downgraded from `error` |
| `@typescript-eslint/consistent-type-imports` | not set | |
| `@typescript-eslint/no-empty-object-type` | not set | stays on from strict preset |

Everything else is identical to the Node flavor.

### Standard Ignores

Every package config starts with these ignore patterns (plus package-specific additions):

```
.history
coverage/*
dist/*
eslint.config.js
resource/*
src/**/__mocks__/*
src/**/*.d.ts
src/**/*.d.ts.map
src/**/*.js
src/**/*.test.ts
src/**/*.test.tsx
storybook-static/*
test/*
vite.config.ts
vitest.config.ts
vitest.config.contract.ts
```

Typical package-specific additions: `node_modules`, `.tmp`, `build`, `bin/*`, `jest*.config.js`.

### Complete Config Template

Single-project `eslint.config.js` (Node.js backend flavor; apply the React deltas above for a frontend):

```javascript
import eslintJs from '@eslint/js'
import tseslint from 'typescript-eslint'
import { defineConfig, globalIgnores } from 'eslint/config'
import noLoops from 'eslint-plugin-no-loops'
import sortKeysFix from 'eslint-plugin-sort-keys-fix'
import noOnlyTests from 'eslint-plugin-no-only-tests'
import noRelativeImportPaths from 'eslint-plugin-no-relative-import-paths'
import eslintPluginImport from 'eslint-plugin-import'
import globals from 'globals'

const namingConvention = () => {
	return [
		{ format: null, leadingUnderscore: 'forbid', modifiers: ['public'], selector: ['default'] },
		{ format: ['camelCase'], leadingUnderscore: 'require', modifiers: ['protected'], selector: ['default'] },
		{ format: ['camelCase'], modifiers: ['private'], prefix: ['__'], selector: ['default'] },
		{ format: ['camelCase'], leadingUnderscore: 'forbid', modifiers: ['public'], selector: ['accessor'] },
		{ format: ['camelCase'], leadingUnderscore: 'require', modifiers: ['protected'], selector: ['accessor'] },
		{ format: ['camelCase'], modifiers: ['private'], prefix: ['__'], selector: ['accessor'] },
		{ format: ['PascalCase'], selector: ['enum'] },
		{ format: ['UPPER_CASE'], selector: ['enumMember'] },
		{ format: ['PascalCase'], leadingUnderscore: 'forbid', modifiers: ['public', 'static'], selector: ['classMethod', 'accessor'] },
		{ format: ['PascalCase'], leadingUnderscore: 'require', modifiers: ['protected', 'static'], selector: ['classMethod', 'accessor'] },
		{ format: ['UPPER_CASE'], modifiers: ['public', 'static'], selector: ['classProperty'] },
		{ format: ['camelCase'], leadingUnderscore: 'allowSingleOrDouble', selector: ['objectLiteralProperty', 'objectLiteralMethod'] },
	]
}

export default defineConfig([
	globalIgnores([
		'.history',
		'coverage/*',
		'dist/*',
		'eslint.config.js',
		'resource/*',
		'src/**/__mocks__/*',
		'src/**/*.d.ts',
		'src/**/*.d.ts.map',
		'src/**/*.js',
		'src/**/*.test.ts',
		'src/**/*.test.tsx',
		'storybook-static/*',
		'test/*',
		'vite.config.ts',
		'vitest.config.ts',
		'vitest.config.contract.ts',
	]),
	{ files: ['**/*.{js,mjs,cjs,ts}'] },
	{ files: ['**/*.{js,mjs,cjs,ts}'], languageOptions: { globals: globals.node } },
	{ files: ['**/*.{js,mjs,cjs,ts}'], plugins: { eslintJs }, extends: ['eslintJs/recommended'] },
	tseslint.configs.recommendedTypeChecked,
	tseslint.configs.strictTypeChecked,
	tseslint.configs.stylisticTypeChecked,
	{
		languageOptions: {
			parser: tseslint.parser,
			parserOptions: {
				projectService: true,
				tsconfigRootDir: import.meta.dirname,
			},
		},
	},
	{
		plugins: {
			'@typescript-eslint': tseslint.plugin,
			'no-loops': noLoops,
			'no-only-tests': noOnlyTests,
			'no-relative-import-paths': noRelativeImportPaths,
			'sort-keys-fix': sortKeysFix,
			import: eslintPluginImport,
		},
		files: ['**/*.ts'],
		rules: {
			'@typescript-eslint/ban-ts-comment': ['warn', { 'ts-expect-error': 'allow-with-description' }],
			'@typescript-eslint/no-misused-spread': 'warn',
			'@typescript-eslint/consistent-type-definitions': 'off',
			'@typescript-eslint/consistent-type-imports': ['error', { fixStyle: 'inline-type-imports' }],
			'@typescript-eslint/dot-notation': 'off',
			'@typescript-eslint/explicit-function-return-type': ['error', { allowExpressions: true }],
			'@typescript-eslint/explicit-member-accessibility': ['error', { accessibility: 'no-public' }],
			'@typescript-eslint/naming-convention': ['error', ...namingConvention()],
			'@typescript-eslint/no-empty-interface': 'off',
			'@typescript-eslint/no-empty-object-type': 'off',
			'@typescript-eslint/no-floating-promises': ['error'],
			'@typescript-eslint/no-non-null-assertion': 'off',
			'@typescript-eslint/no-unused-vars': [
				'warn',
				{
					argsIgnorePattern: '^_',
					caughtErrorsIgnorePattern: '^_',
					destructuredArrayIgnorePattern: '^_',
					varsIgnorePattern: '^_',
				},
			],
			'@typescript-eslint/no-unsafe-assignment': 'warn',
			'@typescript-eslint/no-unsafe-call': 'warn',
			'@typescript-eslint/no-unsafe-member-access': 'warn',
			'@typescript-eslint/no-unsafe-return': 'warn',
			'@typescript-eslint/no-unsafe-argument': 'warn',
			'@typescript-eslint/no-unsafe-enum-comparison': 'warn',
			curly: 'error',
			'import/namespace': [
				'error',
				{
					allowComputed: true,
				},
			],
			'import/newline-after-import': 'error',
			'import/no-unresolved': 'off',
			'import/order': [
				'error',
				{
					alphabetize: {
						caseInsensitive: false,
						order: 'asc',
					},
					groups: [['index', 'sibling', 'parent', 'internal', 'external', 'builtin', 'object']],
					'newlines-between': 'always',
				},
			],
			'lines-between-class-members': ['error', 'always', { exceptAfterSingleLine: true }],
			'no-confusing-arrow': 'error',
			'no-console': 'error',
			'no-constant-condition': 'error',
			'no-duplicate-imports': 'error',
			'no-loops/no-loops': 'error',
			'no-mixed-spaces-and-tabs': 'error',
			'no-only-tests/no-only-tests': 'error',
			'no-relative-import-paths/no-relative-import-paths': ['error', { allowSameFolder: false }],
			'no-ternary': 'error',
			'padding-line-between-statements': [
				'error',
				{ blankLine: 'always', next: 'return', prev: '*' },
				{ blankLine: 'always', next: ['cjs-export', 'export'], prev: '*' },
			],
			'prefer-arrow-callback': 'error',
			'prefer-template': 'error',
			'sort-imports': [
				'error',
				{
					ignoreDeclarationSort: true,
				},
			],
			'sort-keys-fix/sort-keys-fix': ['error', 'asc', { caseSensitive: false, natural: true }],
		},
		settings: {
			'import/resolver': {
				node: {
					paths: ['./'],
				},
			},
		},
	},
])
```

For a React frontend: switch `globals.node` to `globals.browser`, drop `consistent-type-imports` and `no-empty-object-type: off`, and downgrade `no-ternary` to `warn`.

For a monorepo: move the template into a factory (`createNodeEslintConfig` / `createReactEslintConfig`) exported from the root `eslint.config.js`, merge package-specific `ignores` into the standard list, and reduce each package config to a factory call.
