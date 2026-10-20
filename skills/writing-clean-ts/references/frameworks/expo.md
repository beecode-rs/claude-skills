# Expo

Rules to skip or replace when the project is an Expo (React Native + expo-router) app.

## Contents

- [Summary](#summary)
- [Detecting an Expo project](#detecting-an-expo-project)
- [Exception 1: Frontend routing structure](#exception-1-frontend-routing-structure)
- [Exception 2: Allowed top-level folders](#exception-2-allowed-top-level-folders)
- [Exception 3: File naming for route files](#exception-3-file-naming-for-route-files)
- [Exception 4: `index.tsx` is a route, not a barrel](#exception-4-indextsx-is-a-route-not-a-barrel)
- [Exception 5: `@/` alias instead of `#src` and `"type": "module"`](#exception-5--alias-instead-of-src-and-type-module)
- [Exception 6: Root `_layout.tsx` as the composition root](#exception-6-root-_layouttsx-as-the-composition-root)
- [Exception 7: Platform variant files](#exception-7-platform-variant-files)
- [Reviewing an Expo project](#reviewing-an-expo-project)

## Summary

Expo Router is file-based and Metro resolves imports, so a few rules in this skill conflict with the framework. The short version:

- Routes live in `src/app/` (path = URL). A route file is the controller: it reads `useLocalSearchParams` and passes props to a screen in `src/ui-component/`. No `src/controller/react-router/`
- `app/` is an allowed top-level folder (routes only). Never rename it to `app-boot/`
- Route filenames (`index.tsx`, `_layout.tsx`, `[param].tsx`, `(group)/`, `+not-found.tsx`) are framework syntax, exempt from suffix and barrel rules
- Absolute imports use `@/` from tsconfig `paths`, not `#src`. No `"type": "module"` and no `imports` field. Skip the `#src` / `"type": "module"` / `imports` setup entirely; the no-relative-imports rule still applies
- `index.tsx` inside `src/app/` is a route, not a barrel
- The root `src/app/_layout.tsx` is the composition root that starts `app-boot/`
- Platform variants of one module (`x.web.ts`, `x.native.tsx`) are allowed, including under the one-element-per-file rule

Every other rule in this skill applies unchanged to Expo projects.

Rules to skip or replace when the project is an Expo (React Native +
expo-router) app. **Everything not listed here applies unchanged**: layers,
object params, no comments, no loops, no ternaries, naming outside
`src/app/`, and the rest.

Reference implementation: relay (`~/code/relay`).

Facts verified against Expo SDK 57 docs (2026-09-29):
https://docs.expo.dev/router/basics/core-concepts.md ,
https://docs.expo.dev/router/basics/notation.md

## Detecting an Expo project

Treat the project as Expo when any of these is true:

- `package.json` depends on `expo` or `expo-router`
- `package.json` has `"main": "expo-router/entry"`
- `app.json` / `app.config.ts` exists with an `expo` key

In a monorepo, check the package being worked on, not the root: only that
package gets these exceptions. A plain React Native app without expo-router
does NOT get Exceptions 1, 3, 4, or 6 (no file-based router).

## Exception 1: Frontend routing structure

**Skill rules replaced:**
- The React Router controller location `src/controller/react-router/`
- The "Frontend Feature" layout (`controller/react-router/feature-name/list.tsx` + `ui-component/feature-name/list.tsx`)
- The React Router controller pattern and its React controller starter template

**Why:** Expo Router is file-based. Route files must live in `src/app/`, the
file path IS the URL, and routes cannot be moved to a controller folder.

**Instead:** a route file in `src/app/` is the controller. It stays thin:
it reads `useLocalSearchParams` / `router` / `Link`, then passes plain props to
a screen that lives outside `src/app/` (in `src/ui-component/`). The rule
"routing hooks only in controllers" still holds, with controller = route file.
Screens still take plain props and never call routing hooks.

```
src/
├── app/                                  # Expo Router: path = URL
│   ├── _layout.tsx                       # Root navigator + providers
│   ├── index.tsx                         # /
│   └── project/
│       ├── index.tsx                     # /project
│       └── [projectId].tsx               # /project/:projectId
└── ui-component/project/
    ├── list.tsx                          # <ProjectList /> - plain props
    └── detail.tsx                        # <ProjectDetail /> - plain props
```

```typescript
// src/app/project/[projectId].tsx
import { useLocalSearchParams } from 'expo-router'

import { ErrorView } from '@/ui-component/error-view'
import { ProjectDetail } from '@/ui-component/project/detail'

export default function ProjectDetailRoute(): React.ReactElement {
  const { projectId } = useLocalSearchParams<{ projectId: string }>()

  if (!projectId) {
    return <ErrorView />
  }

  return <ProjectDetail projectId={projectId} />
}
```

Expo Router requires the route component as the file's **default export**.
This is framework syntax, not a naming or export-pattern violation.

## Exception 2: Allowed top-level folders

**Skill rule not enforced as written:** "NEVER create arbitrary top-level
folders. Allowed: `app-boot/`, `controller/`, `business/`, `dal/`,
`ui-component/`, `util/`, `lib/`, `__internal__/`, `asset/`, `__tests__/`".

Also void: the file-organization rename hint that treats
`src/app/` as an old name for `src/app-boot/`. In Expo, never rename `src/app/`;
that breaks every route.

**Why:** `src/app/` is required by the framework and is missing from the set.

**Instead:** in Expo projects `app/` is an allowed top-level folder. All other
folders outside `src/app/` follow the layer rules unchanged. `src/app/` holds
route files only (plus the root layout, see Exception 6). Services, hooks,
components, and utils never go there.

## Exception 3: File naming for route files

**Skill rules that do not apply inside `src/app/`:** kebab-case with a layer
suffix, name-what-it-is renames, freedom to name the one-element file anything.

**Why:** route filenames are URL segments, and the reserved names are exact
framework syntax that cannot be renamed or given a suffix:

| Name | Meaning |
|---|---|
| `index.tsx` | Directory's default route |
| `_layout.tsx` | Navigator for the directory; required at the `src/app/` root |
| `[param].tsx` | Dynamic segment (read via `useLocalSearchParams`) |
| `(group)/` | Route group, left out of the URL |
| `+not-found.tsx`, `+html.tsx`, `+native-intent.tsx`, `+middleware.tsx` | Special router files |

Some route names are reserved outright (e.g. `assets`). The `_layout.tsx`
underscore is NOT the skill's private-file marker. Suffix and naming rules apply
unchanged to every file outside `src/app/`.

## Exception 4: `index.tsx` is a route, not a barrel

**Skill rule:** "No index.ts barrel files".

**Exception:** `index.tsx` inside `src/app/` is a route (the directory's
default route), not a barrel. The ban still applies outside `src/app/`.

## Exception 5: `@/` alias instead of `#src` and `"type": "module"`

**Skill rules replaced:** the ES modules / `#src` import setup and the
"ABSOLUTE IMPORTS VIA `#src`" rule: `#src/*` subpath imports, `"type": "module"`, the package.json `imports`
field, and Node-runtime resolution.

**Why:** that setup exists for plain Node. Expo bundles through Metro/Babel,
which resolves tsconfig `paths` directly, and the package entry is
`"main": "expo-router/entry"`. Adding `"type": "module"` or an `imports`
field serves no purpose there, so do not add them.

**Instead:** absolute imports go through the `@/*` tsconfig alias (the Expo
convention; relay uses `@/`). The no-relative-imports rule still holds, with
`@/` in place of `#src`:

```json
{
  "extends": "expo/tsconfig.base",
  "compilerOptions": {
    "strict": true,
    "paths": {
      "@/*": ["./src/*"]
    }
  }
}
```

```typescript
import { projectService } from '@/business/service/project-service'
```

Do not add `.js` extensions (bundler resolution). The ESLint
`no-relative-import-paths` rule still applies; set its `prefix` option to
`@` and `rootDir` to `src` so its auto-fix writes `@/` paths.

## Exception 6: Root `_layout.tsx` as the composition root

**Skill rule relaxed:** app-boot layer, where the `AppFlow` is the app's entry
point.

**Why:** in Expo the process entry is `expo-router/entry`, and the composition
root is the root `src/app/_layout.tsx` (providers, fonts, splash screen). That
layout file must live inside `src/app/`.

**Instead:** `src/app-boot/` classes and life cycles still exist outside the
app dir and are started from the root `_layout.tsx`. The root layout is the one
file inside `src/app/` allowed to hold that wiring. Everything else that is not
a route stays out of `src/app/`.

## Exception 7: Platform variant files

**Skill rule with an exception:** one class/object/component per file, and
suffix naming.

**Why:** Expo's module resolution picks platform variants of the same module
automatically (`.native.tsx`, `.web.tsx`, `.ios.tsx`, `.android.tsx`).

**Instead:** platform-variant files of one module are allowed and are not a
naming or duplication violation (e.g. relay's `ssh2-shell-client.web.ts` next
to the base client). Each variant exports the same element with the same name,
and callers import the base path without the platform segment.

---

## Reviewing an Expo project

When running `/cleanup`, `/clean-arch`, or `/clean-style` on an Expo project,
do not report these as violations:

- Files in `src/app/` without layer suffixes, with `[param]`/`(group)`/`+name`/`_layout` names, or exporting a default component
- `index.tsx` in `src/app/`
- `src/app/` as a top-level folder (and never suggest renaming it to `app-boot/`)
- `@/` imports, or a missing `"type": "module"` / `imports` field / `#src` paths
- Platform-variant files (`x.web.ts` next to `x.ts`)

Still report these as violations: relative imports, business logic or routing
hooks inside screens, non-route code placed in `src/app/`, and route files
that do more than read router params and pass props (the thin-controller rule).
