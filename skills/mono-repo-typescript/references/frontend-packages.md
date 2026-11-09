# Frontend Package Patterns

Detailed configuration for frontend-focused packages in the monorepo.

## React-Common Library

Shared React components, hooks, and utilities used across web and mobile apps.

### Structure

```
packages/react-common/
├── src/
│   ├── ui-component/        # Shared UI components
│   │   ├── auth/
│   │   │   └── login-form.tsx
│   │   ├── input/
│   │   │   ├── text-field.tsx
│   │   │   └── select.tsx
│   │   ├── modal/
│   │   │   └── confirm-dialog.tsx
│   │   ├── nav/
│   │   │   └── sidebar.tsx
│   │   └── tab/
│   │       └── tab-panel.tsx
│   ├── lib/
│   │   ├── axios/           # Axios interceptors
│   │   │   └── api-client.ts
│   │   └── react-admin/     # React-admin utilities
│   ├── business/
│   │   └── hook/            # Shared hooks
│   │       ├── use-auth.ts
│   │       └── use-form.ts
│   ├── screen/              # Shared screen components
│   │   └── error-boundary.tsx
│   ├── asset/               # SCSS assets
│   │   └── variables.scss
│   └── util/
├── .storybook/
│   └── main.ts
├── package.json
└── tsconfig.json
```

### package.json

```json
{
  "name": "@app/react-common",
  "type": "module",
  "exports": {
    "./*": {
      "import": "./dist/*.js",
      "types": "./src/*.ts"
    },
    "./*.scss": {
      "import": "./dist/*.scss"
    },
    "./__internal__/*": null
  },
  "imports": {
    "#src/*.js": "./dist/*.js"
  },
  "scripts": {
    "build": "node ../../resource/script/npm/clean.js . && tsc -p ./tsconfig.build.json && pnpm run build-css",
    "build-css": "sass src/:dist/ --no-source-map",
    "clean": "node ../../resource/script/npm/clean.js .",
    "lint:eslint": "eslint ./ --quiet",
    "lint-fix:eslint": "eslint ./ --fix",
    "test": "vitest run -c ../../config/vitest/vitest.config.unit.base.js",
    "storybook": "storybook dev -p 6006",
    "build-storybook": "storybook build"
  },
  "dependencies": {
    "@app/common": "workspace:*",
    "@app/config": "workspace:*",
    "@mui/material": "catalog:",
    "@emotion/react": "catalog:",
    "@emotion/styled": "catalog:",
    "react-router-dom": "catalog:",
    "react-hook-form": "catalog:",
    "zod": "catalog:",
    "axios": "catalog:"
  },
  "devDependencies": {
    "@storybook/react": "catalog:",
    "@storybook/react-vite": "catalog:",
    "@types/react": "catalog:",
    "react": "catalog:",
    "sass": "catalog:",
    "typescript": "catalog:",
    "vite": "catalog:"
  },
  "peerDependencies": {
    "react": "^18.0.0 || ^19.0.0"
  }
}
```

### tsconfig.json

```json
{
  "extends": "../../config/typescript/tsconfig.react.base.json",
  "compilerOptions": {
    "outDir": "./dist",
    "rootDir": "./src",
    "paths": {
      "#src": ["./src"],
      "#src/*": ["./src/*"]
    }
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", ".storybook"]
}
```

---

## Frontend Web App (Vite + React)

Admin dashboard or main web application.

### Structure

```
packages/react-admin/
├── src/
│   ├── app/
│   │   └── app.tsx
│   ├── screen/
│   │   ├── dashboard/
│   │   │   └── dashboard-screen.tsx
│   │   └── user/
│   │       └── user-list-screen.tsx
│   ├── component/
│   │   └── layout/
│   │       └── main-layout.tsx
│   ├── lib/
│   │   └── query-client.ts
│   ├── route/
│   │   └── routes.tsx
│   ├── util/
│   ├── main.tsx
│   └── vite-env.d.ts
├── public/
├── index.html
├── vite.config.ts
├── package.json
└── tsconfig.json
```

### package.json

```json
{
  "name": "@app/react-admin",
  "type": "module",
  "scripts": {
    "build": "tsc --noEmit && vite build",
    "lint:eslint": "eslint ./ --quiet",
    "lint-fix:eslint": "eslint ./ --fix",
    "serve": "vite",
    "start": "vite preview",
    "test": "vitest run -c ../../config/vitest/vitest.config.unit.base.js",
    "test:e2e": "vitest run -c ../../config/vitest/vitest.config.e2e.base.js"
  },
  "dependencies": {
    "@app/common": "workspace:*",
    "@app/react-common": "workspace:*",
    "@app/config": "workspace:*",
    "react": "catalog:",
    "react-dom": "catalog:",
    "@mui/material": "catalog:",
    "react-router-dom": "catalog:",
    "@tanstack/react-query": "catalog:",
    "react-admin": "catalog:",
    "axios": "catalog:"
  },
  "devDependencies": {
    "@types/react": "catalog:",
    "@types/react-dom": "catalog:",
    "@vitejs/plugin-react": "catalog:",
    "typescript": "catalog:",
    "vite": "catalog:",
    "vite-tsconfig-paths": "catalog:",
    "vitest": "catalog:",
    "sass": "catalog:"
  }
}
```

### vite.config.ts

```typescript
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tsconfigPaths from 'vite-tsconfig-paths'

export default defineConfig({
  plugins: [
    react(),
    tsconfigPaths()
  ],
  server: {
    port: 3001,
    host: true
  }
})
```

### tsconfig.json

```json
{
  "extends": "../../config/typescript/tsconfig.react.base.json",
  "compilerOptions": {
    "noEmit": true,
    "paths": {
      "#src": ["./src"],
      "#src/*": ["./src/*"]
    }
  },
  "include": ["src/**/*", "vite.config.ts"],
  "exclude": ["node_modules", "dist"]
}
```

---

## Mobile App (React Native / Expo)

Mobile application sharing code with web apps. It is an Expo Router app, so it follows
`writing-clean-ts` `references/frameworks/expo.md`: no `"type": "module"`, no `exports` or
`imports` field, `"main": "expo-router/entry"`, and the `@/*` tsconfig alias instead of `#src`
(`import { userService } from '@/business/service/user-service'`, no `.js`). Only the
workspace rules (dependencies, versions, cross-package imports) are the same as every other
package.

### Structure

```
packages/mobile-app/
├── src/
│   ├── app/                 # Expo Router routes only (path = URL)
│   │   ├── _layout.tsx      # Root layout: the composition root
│   │   ├── (tabs)/
│   │   │   ├── _layout.tsx
│   │   │   ├── index.tsx
│   │   │   └── settings.tsx
│   │   └── user/
│   │       └── [id].tsx
│   ├── app-boot/
│   ├── business/
│   ├── ui-component/        # Screens and components, plain props
│   │   └── user/
│   │       └── detail.tsx
│   ├── lib/
│   │   └── storage.ts
│   └── util/
├── app.json
├── package.json
└── tsconfig.json
```

### package.json

```json
{
  "name": "@app/mobile-app",
  "main": "expo-router/entry",
  "scripts": {
    "start": "expo start",
    "android": "expo start --android",
    "ios": "expo start --ios",
    "web": "expo start --web",
    "build": "expo export",
    "lint:eslint": "eslint ./ --quiet",
    "lint-fix:eslint": "eslint ./ --fix",
    "test": "vitest run -c ../../config/vitest/vitest.config.unit.base.js"
  },
  "dependencies": {
    "@app/common": "workspace:*",
    "@app/react-common": "workspace:*",
    "expo": "catalog:",
    "expo-router": "catalog:",
    "react": "catalog:",
    "react-native": "catalog:",
    "@react-navigation/native": "catalog:",
    "expo-secure-store": "catalog:",
    "axios": "catalog:"
  },
  "devDependencies": {
    "@types/react": "catalog:",
    "typescript": "catalog:",
    "vitest": "catalog:"
  }
}
```

### tsconfig.json

```json
{
  "extends": "expo/tsconfig.base",
  "compilerOptions": {
    "strict": true,
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["src/**/*", "*.config.ts"],
  "exclude": ["node_modules"]
}
```

---

## Website (Next.js)

Marketing site or public-facing website.

### Structure

```
packages/website/
├── src/
│   ├── app/
│   │   ├── layout.tsx
│   │   ├── page.tsx
│   │   └── globals.css
│   ├── component/
│   │   └── hero.tsx
│   └── lib/
├── public/
├── next.config.ts
├── package.json
└── tsconfig.json
```

### package.json

```json
{
  "name": "@app/website",
  "type": "module",
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint:eslint": "eslint ./ --quiet",
    "lint-fix:eslint": "eslint ./ --fix",
    "test": "vitest run -c ../../config/vitest/vitest.config.unit.base.js"
  },
  "dependencies": {
    "@app/common": "workspace:*",
    "@app/react-common": "workspace:*",
    "next": "catalog:",
    "react": "catalog:",
    "react-dom": "catalog:"
  },
  "devDependencies": {
    "@types/react": "catalog:",
    "@types/react-dom": "catalog:",
    "typescript": "catalog:",
    "vitest": "catalog:"
  }
}
```

---

## Package Dependency Rules

```
                    @app/common
                          │
                          ▼
                    @app/react-common
                          │
          ┌───────────────┼───────────────┐
          │               │               │
          ▼               ▼               ▼
      react-admin     react-core     mobile-app
```

**Never:**
- Let `react-common` depend on a specific app
- Create circular dependencies between apps
- Share app-specific code in `react-common`
