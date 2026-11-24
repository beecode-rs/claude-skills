# @beecode/msh-config

Micro-service helper: shared configuration. Exports ESLint (flat config), Prettier, and semantic-release configs plus a small CLI to bump lockfile versions. Not a runtime library - it is consumed by config files.

- **Known version**: `1.2.2` (major 1)
- **Install**: `npm i -D @beecode/msh-config`
- **Module type**: CommonJS (`"type": "commonjs"`), but the ESLint config is an `.mjs` ESM module
- **Peer deps you usually need**: `eslint`, `prettier`, `typescript`, `typescript-eslint`, `joi`, etc. (install as needed; the package declares many as regular dependencies)

## Contents

- [Exports (subpath imports)](#exports-subpath-imports)
- [Prettier config](#prettier-config)
- [ESLint config](#eslint-config)
- [semantic-release config](#semantic-release-config)
- [What to do when the user asks about config](#what-to-do-when-the-user-asks-about-config)
- [Breaking changes](#breaking-changes)

## Exports (subpath imports)

| Subpath | File | Exports |
|---------|------|---------|
| `@beecode/msh-config/eslint-config` | `src/eslint-config.mjs` | default flat ESLint config |
| `@beecode/msh-config/prettier-config` | `src/prettier-config.js` | default Prettier config object |
| `@beecode/msh-config/semantic-release-config` | `src/semantic-release-config.js` | default semantic-release config object |

Bin: `msh-update-lock-version` (`bin/update-lock-version.js`) - bumps the version inside `package-lock.json`; used by the semantic-release `prepareCmd`.

## Prettier config

The enforced style. Match this in any code you generate for an msh-based project:

```js
{
	arrowParens: 'always',
	bracketSpacing: true,
	printWidth: 120,
	semi: false,
	singleQuote: true,
	tabWidth: 2,
	trailingComma: 'es5',
	useTabs: true,
	endOfLine: 'lf',
}
```

In practice: **tabs** (width 2), **single quotes**, **no semicolons**, **print width 120**, trailing comma `es5`, LF line endings. (The repo's top-level CLAUDE.md mentions 130 chars, but the actual enforced prettier width is 120; defer to 120 when in doubt.)

Consume it in `.prettierrc.cjs`:

```js
module.exports = require('@beecode/msh-config/prettier-config')
```

## ESLint config

A flat config (`eslint.config.mjs`) using `defineConfig` from `eslint/config`. It composes:

- `@eslint/js` recommended
- `typescript-eslint` `recommendedTypeChecked`, `strictTypeChecked`, `stylisticTypeChecked` (with `projectService: true`)
- plugins: `no-loops`, `no-only-tests`, `eslint-plugin-import-x`
- `eslint-config-prettier` (disables formatting rules that conflict with prettier)

Notable rules this enforces (so generated code should already comply):

- `explicit-function-return-type: error` with `allowExpressions: true`
- `explicit-member-accessibility: error` with `accessibility: 'no-public'` (omit the `public` keyword)
- `naming-convention`: protected members `camelCase` with leading underscore; private members prefixed `__`; enums `PascalCase`; enum members `UPPER_CASE`; static class methods `PascalCase`; static class properties `UPPER_CASE`
- `consistent-type-imports: error` with `fixStyle: 'inline-type-imports'` (use `import { type X }`)
- `no-floating-promises: error`
- `no-console: error`, `no-ternary: error`, `no-loops/no-loops: error`, `no-only-tests/no-only-tests: error`
- `import/order: error` (alphabetized, grouped, newlines between groups), `sort-keys`, `sort-imports` (ignore declaration sort)
- unused vars/args/caught errors ignored when prefixed with `_`

Consume it in `eslint.config.mjs`:

```js
import mshEslintConfig from '@beecode/msh-config/eslint-config'

export default mshEslintConfig
```

Because type-checked rules use `projectService: true`, the consuming project needs a `tsconfig.json` that includes the linted files.

## semantic-release config

Releases from `main` using the Angular commit preset. The `@semantic-release/exec` prepare step writes `version.txt`, runs `npm version`, and runs `msh-update-lock-version` to sync the lockfile. Assets committed: `package.json`, `package-lock.json`, `CHANGELOG.md`.

Consume it in `.releaserc.cjs`:

```js
module.exports = require('@beecode/msh-config/semantic-release-config')
```

## What to do when the user asks about config

Most config requests are "set up linting/formatting/release for an msh-style project" or "why is my code failing this rule". For setup, point them at the three consume snippets above and remind them that the ESLint config is type-checked (needs a tsconfig). For rule questions, the rules of interest are listed above; the full set is in the package source if a specific rule is unclear.

## Breaking changes

No migration guide ships with this package as of the known version. The ESLint config moved to flat config (`eslint.config.mjs`) at some point, so users on very old versions may still reference `.eslintrc` style. If the user has a different major, fetch `https://raw.githubusercontent.com/beecode-rs/msh-config/main/README.md` and `/MIGRATION.md` (see `version-check.md`).
