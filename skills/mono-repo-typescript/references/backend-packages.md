# Backend Package Patterns

Detailed configuration for backend-focused packages in the monorepo.

## Common Library

Shared business models, utilities, and domain logic. Platform-agnostic.

### Structure

```
packages/common/
├── src/
│   ├── business/
│   │   └── model/           # Domain models (User, Order, etc.)
│   ├── lib/                 # Shared utilities
│   │   ├── zod/             # Zod schemas
│   │   └── util/            # Helper functions
│   └── index.ts
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
    "#src/*": "./dist/*.js"
  },
  "scripts": {
    "build": "node ../../resource/script/npm/clean.js . && tsc -p ./tsconfig.build.json && tsc-alias -p ./tsconfig.build.json",
    "clean": "node ../../resource/script/npm/clean.js .",
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
    "#src/*": "./dist/*.js"
  },
  "scripts": {
    "build": "node ../../resource/script/npm/clean.js . && tsc -p ./tsconfig.build.json && tsc-alias -p ./tsconfig.build.json",
    "clean": "node ../../resource/script/npm/clean.js .",
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
│   ├── app/                 # Application entry
│   │   └── server-app.ts
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
    "#src/*": "./dist/*.js"
  },
  "scripts": {
    "build": "node ../../resource/script/npm/clean.js . && tsc -p ./tsconfig.build.json && tsc-alias -p ./tsconfig.build.json",
    "serve": "NODE_ENV=development nodemon --inspect=0.0.0.0:9229 dist/app/server-app.js",
    "start": "NODE_ENV=production node dist/app/server-app.js",
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

### Entry Point Example (server-app.ts)

```typescript
import express from 'express'
import { userRoute } from '#src/controller/user/user-route.js'

const app = express()
app.use(express.json())

app.use('/api/core/user', userRoute)

const PORT = process.env.PORT || 3000
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`)
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
