# Backend Package Patterns

Detailed configuration for backend-focused packages in the monorepo.

## Common Library

Shared business models, utilities, and domain logic. Platform-agnostic.

### Structure

```
packages/common/
├── src/
│   ├── business/
│   │   ├── model/           # Domain models (User, Order, etc.)
│   │   └── schema/          # Zod schemas shared by frontend and backend
│   ├── lib/                 # Shared utilities
│   │   ├── zod/             # Zod wrapper (zod-wrapper.ts)
│   │   └── util/            # Helper functions
├── package.json
└── tsconfig.json
```

### package.json

```json
{
  "name": "@app/common",
  "type": "module",
  "exports": {
    "./*": {
      "import": "./dist/*.js",
      "types": "./src/*.ts"
    },
    "./__internal__/*": null
  },
  "imports": {
    "#src/*.js": "./dist/*.js"
  },
  "scripts": {
    "build": "node ../../resource/script/npm/clean.js . && tsc -p ./tsconfig.build.json",
    "clean": "node ../../resource/script/npm/clean.js .",
    "lint:eslint": "eslint ./ --quiet",
    "lint-fix:eslint": "eslint ./ --fix",
    "test": "vitest run -c ../../config/vitest/vitest.config.unit.base.js"
  },
  "dependencies": {
    "zod": "catalog:"
  },
  "devDependencies": {
    "@app/config": "workspace:*",
    "typescript": "catalog:",
    "vitest": "catalog:"
  }
}
```

### tsconfig.json

```json
{
  "extends": "../../config/typescript/tsconfig.base.json",
  "compilerOptions": {
    "outDir": "./dist",
    "rootDir": "./src",
    "paths": {
      "#src": ["./src"],
      "#src/*": ["./src/*"]
    }
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

### tsconfig.build.json

```json
{
  "extends": "./tsconfig.json",
  "compilerOptions": {
    "declaration": true,
    "declarationMap": true
  }
}
```

---

## Node-Common Library

Node.js-specific infrastructure: database connections, logging, messaging, etc.

### Structure

```
packages/node-common/
├── src/
│   ├── lib/
│   │   ├── axios/           # Axios client configuration
│   │   ├── connection/      # Database connections
│   │   ├── logger/          # Logger strategies (Winston, Pino)
│   │   ├── rmq/             # RabbitMQ configuration
│   │   └── typeorm/         # TypeORM configurations
│   ├── util/
│   └── __internal__/
├── package.json
└── tsconfig.json
```

### package.json

```json
{
  "name": "@app/node-common",
  "type": "module",
  "exports": {
    "./*": {
      "import": "./dist/*.js",
      "types": "./src/*.ts"
    },
    "./__internal__/*": null
  },
  "imports": {
    "#src/*.js": "./dist/*.js"
  },
  "scripts": {
    "build": "node ../../resource/script/npm/clean.js . && tsc -p ./tsconfig.build.json",
    "clean": "node ../../resource/script/npm/clean.js .",
    "lint:eslint": "eslint ./ --quiet",
    "lint-fix:eslint": "eslint ./ --fix",
    "test": "vitest run -c ../../config/vitest/vitest.config.unit.base.js"
  },
  "dependencies": {
    "@app/common": "workspace:*",
    "@app/config": "workspace:*",
    "typeorm": "catalog:",
    "express": "catalog:",
    "amqplib": "catalog:",
    "jsonwebtoken": "catalog:",
    "axios": "catalog:",
    "winston": "catalog:"
  },
  "devDependencies": {
    "@types/amqplib": "catalog:",
    "@types/jsonwebtoken": "catalog:",
    "typescript": "catalog:",
    "vitest": "catalog:"
  }
}
```

---

## Backend Microservice

Individual microservice with controllers, services, repositories.

### Structure

```
packages/node-core/
├── src/
│   ├── main.ts              # Entry point: starts the app flow, nothing else
│   ├── app-boot/            # AppFlow and life cycles (see writing-clean-ts app-boot layer)
│   │   └── core-app.ts
│   ├── controller/          # Express controllers
│   │   └── user/
│   │       ├── user-controller.ts
│   │       └── user-route.ts
│   ├── business/            # Domain logic
│   │   ├── service/
│   │   │   └── user/
│   │   │       └── user-service.ts
│   │   └── repo/
│   │       └── user/
│   │           └── user-repo.ts
│   ├── dal/                 # Data access layer
│   │   └── typeorm/
│   │       └── entity/
│   │           └── user/
│   │               └── user-entity.ts
│   ├── lib/                 # Infrastructure
│   │   ├── typeorm/
│   │   │   └── datasource.ts
│   │   └── rmq/
│   │       └── consumer.ts
│   └── util/
├── resource/
│   ├── doc/
│   └── secret/
├── package.json
├── tsconfig.json
└── tsconfig.build.json
```

### package.json

```json
{
  "name": "@app/node-core",
  "type": "module",
  "exports": {
    "./*": {
      "import": "./dist/*.js",
      "types": "./src/*.ts"
    }
  },
  "imports": {
    "#src/*.js": "./dist/*.js"
  },
  "scripts": {
    "build": "node ../../resource/script/npm/clean.js . && tsc -p ./tsconfig.build.json",
    "clean": "node ../../resource/script/npm/clean.js .",
    "lint:eslint": "eslint ./ --quiet",
    "lint-fix:eslint": "eslint ./ --fix",
    "serve": "NODE_ENV=development nodemon --inspect=0.0.0.0:9229 dist/main.js",
    "start": "NODE_ENV=production node dist/main.js",
    "test": "vitest run -c ../../config/vitest/vitest.config.unit.base.js",
    "test:int": "vitest run -c ../../config/vitest/vitest.config.int.base.js",
    "migration:generate": "typeorm migration:generate -d dist/lib/typeorm/datasource.js",
    "migration:run": "typeorm migration:run -d dist/lib/typeorm/datasource.js",
    "migration:revert": "typeorm migration:revert -d dist/lib/typeorm/datasource.js"
  },
  "dependencies": {
    "@app/common": "workspace:*",
    "@app/node-common": "workspace:*",
    "@app/config": "workspace:*",
    "express": "catalog:",
    "typeorm": "catalog:",
    "pg": "catalog:",
    "swagger-ui-express": "catalog:",
    "amqplib": "catalog:"
  },
  "devDependencies": {
    "@types/express": "catalog:",
    "@types/swagger-ui-express": "catalog:",
    "typescript": "catalog:",
    "vitest": "catalog:",
    "nodemon": "catalog:"
  }
}
```

### tsconfig.json

```json
{
  "extends": "../../config/typescript/tsconfig.base.json",
  "compilerOptions": {
    "outDir": "./dist",
    "rootDir": "./src",
    "paths": {
      "#src": ["./src"],
      "#src/*": ["./src/*"]
    },
    "experimentalDecorators": true,
    "emitDecoratorMetadata": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "resource"]
}
```

### Entry Point Example (main.ts)

The entry point only starts the app flow. The flow and its life cycles live in
`src/app-boot/` and follow the `writing-clean-ts` app-boot layer (Express starts inside a
life cycle, config comes from `#src/util/config.js`, logging goes through `logger()`, never
`console`).

```typescript
import 'reflect-metadata'

import { AppStarter, setAppBootLogger } from '@beecode/msh-app-boot'

import { CoreApp } from '#src/app-boot/core-app.js'
import { logger } from '#src/util/logger.js'

setAppBootLogger(logger())

new AppStarter(new CoreApp()).start().catch((error: unknown) => {
  logger().error('Core app failed to start', error)
  process.exit(1)
})
```

---

## Package Dependency Rules

```
                    @app/common
                    (no dependencies)
                          │
                          ▼
                    @app/node-common
                    (depends on common)
                          │
                          ▼
                    @app/node-{service}
                    (depends on common, node-common)
```

**Never:**
- Let `common` depend on `node-common` or any service
- Let `node-common` depend on a specific service
- Create circular dependencies between services
