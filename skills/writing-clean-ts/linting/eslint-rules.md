# ESLint Rule Set

The complete rule inventory extracted from the reference monorepo (`~/code/visualiser`, shared config package `@app/config`). When generating an ESLint config for any new project, reproduce this rule set with the newest released tool versions. The rules are the fixed part; versions are always current at generation time.

One addition beyond the reference repo: `no-relative-import-paths` enforces the skill's absolute-import policy (internal imports go through the `#src` alias only, never `./` or `../`).

## Two Flavors

| Flavor | Factory | Use For | Config Source |
|--------|---------|---------|---------------|
| **Node.js backend** | `createNodeEslintConfig` | Express services, RMQ consumers, CLI packages, GraphQL | `src/eslint/node.mjs` |
| **React frontend** | `createReactEslintConfig` | React apps and React shared packages | `src/eslint/react.mjs` |

The two flavors are ~95% identical. Both are plain TypeScript strictness configs; notably the React flavor uses NO React-specific plugins (no `eslint-plugin-react`, no `eslint-plugin-react-hooks`). Pick the flavor by the package's runtime, then apply the deltas listed at the end of this file.

## Dependencies

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

## Baseline Presets

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

## Naming Convention Table

`@typescript-eslint/naming-convention` is configured with this exact table (this is the enforced source of the naming rules in [../style/naming-convention.md](../style/naming-convention.md)):

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

## Shared Rules (Both Flavors)

### TypeScript Rules

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

### Import Rules

| Rule | Setting | Notes |
|------|---------|-------|
| `import/namespace` | `error`, `allowComputed: true` | |
| `import/newline-after-import` | `error` | |
| `import/no-unresolved` | `off` | TypeScript handles resolution |
| `import/order` | `error`, see below | |
| `no-relative-import-paths/no-relative-import-paths` | `error`, `allowSameFolder: false` | absolute imports via `#src` alias only; blocks ALL relative imports (`./` and `../`) |
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

### Code Rules

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

## Flavor Deltas

### Node.js Backend Only

| Rule | Setting | Notes |
|------|---------|-------|
| `@typescript-eslint/consistent-type-imports` | `error`, `fixStyle: inline-type-imports` | `import { type X }` inline style |
| `@typescript-eslint/no-empty-object-type` | `off` | `{}` allowed |
| `no-ternary` | `error` | ternary PROHIBITED |

### React Frontend Differences

| Rule | Setting | Difference vs Node |
|------|---------|--------------------|
| `no-ternary` | `warn` | downgraded from `error` |
| `@typescript-eslint/consistent-type-imports` | not set | |
| `@typescript-eslint/no-empty-object-type` | not set | stays on from strict preset |

Everything else is identical to the Node flavor.

## Standard Ignores

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

## Complete Config Template

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

For a monorepo: move the template into a factory (`createNodeEslintConfig` / `createReactEslintConfig`) exported from the root `eslint.config.js`, merge package-specific `ignores` into the standard list, and reduce each package config to a factory call (see [linting-workflow.md](linting-workflow.md)).
