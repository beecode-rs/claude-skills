# Infrastructure & Configuration

Docker Compose, build scripts, and centralized configuration.

## Docker Compose Development

### compose.yml Structure

```yaml
name: project-name

services:
  # Reverse proxy
  proxy:
    image: traefik:v3.3
    ports:
      - "443:443"
      - "8080:8080"  # Dashboard
    volumes:
      - ./resource/traefik:/etc/traefik
      - ./resource/cert:/cert
    healthcheck:
      test: ["CMD", "traefik", "healthcheck"]
      interval: 10s
      timeout: 5s

  # Database
  pg:
    image: postgres:17-alpine
    environment:
      POSTGRES_DB: app
      POSTGRES_USER: app
      POSTGRES_PASSWORD: app
    ports:
      - "54321:5432"
    volumes:
      - pg_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U app"]
      interval: 10s

  # Message Queue
  rmq:
    image: rabbitmq:4-management-alpine
    ports:
      - "15672:15672"  # Management UI
    healthcheck:
      test: ["CMD", "rabbitmq-diagnostics", "-q", "ping"]

  # Backend Microservice
  node-core:
    build:
      context: .
      dockerfile: resource/docker/Dockerfile.node-base
    command: pnpm run serve
    working_dir: /app/packages/node-core
    volumes:
      - ./:/app:ro
      - node_modules:/app/node_modules
    environment:
      NODE_ENV: development
      DATABASE_URL: postgres://app:app@pg:5432/app
      RMQ_URL: amqp://guest:guest@rmq:5672
    depends_on:
      pg: { condition: service_healthy }
      rmq: { condition: service_healthy }
    labels:
      - "traefik.http.routers.node-core.rule=PathPrefix(`/api/core`)"
      - "traefik.http.middlewares.strip-core.stripprefix.prefixes=/api/core"
      - "traefik.http.routers.node-core.middlewares=strip-core"

  # Frontend App
  react-admin:
    build:
      context: .
      dockerfile: resource/docker/Dockerfile.node-base
    command: pnpm run serve
    working_dir: /app/packages/react-admin
    volumes:
      - ./:/app:ro
    labels:
      - "traefik.http.routers.react-admin.rule=PathPrefix(`/admin`)"

volumes:
  pg_data:
  node_modules:

networks:
  default:
    driver: bridge
    ipam:
      config:
        - subnet: 172.221.0.0/16
```

### Dockerfile (Node Base)

**resource/docker/Dockerfile.node-base:**

```dockerfile
FROM node:22-alpine

ENV APP_PATH=/app
ENV PORT=3000
ENV NODE_ENV=development

# Enable pnpm via corepack
RUN corepack enable && corepack prepare pnpm@latest --activate

WORKDIR ${APP_PATH}

# Copy lock files first for better caching
COPY pnpm-lock.yaml pnpm-workspace.yaml package.json ./
COPY packages/*/package.json ./packages/*/

# Install dependencies
RUN pnpm install --frozen-lockfile

# Copy source (mounted as volume in dev, but needed for production builds)
COPY . .

USER node
EXPOSE ${PORT}

CMD ["pnpm", "start"]
```

### Traefik Labels Pattern

```yaml
labels:
  # Route definition
  - "traefik.http.routers.service-name.rule=PathPrefix(`/api/service`)"
  - "traefik.http.routers.service-name.entrypoints=web-secure"
  - "traefik.http.routers.service-name.tls=true"

  # Strip path for internal routing
  - "traefik.http.middlewares.strip-service.stripprefix.prefixes=/api/service"
  - "traefik.http.routers.service-name.middlewares=strip-service"
```

---

## Build Scripts

### resource/script/npm/clean.js

```javascript
import { rm } from 'fs/promises'
import { join } from 'path'

const packageDir = process.argv[2]
if (!packageDir) {
  console.error('Usage: clean.js <package-directory>')
  process.exit(1)
}

const distPath = join(process.cwd(), packageDir, 'dist')
await rm(distPath, { recursive: true, force: true })
console.log(`Cleaned ${distPath}`)
```

### resource/script/npm/build-esm-fix.js

Fixes ESM import paths in built files (for React packages):

```javascript
import { readFile, writeFile } from 'fs/promises'
import { join } from 'path'
import { glob } from 'glob'

const packageDir = process.argv[2]
if (!packageDir) process.exit(1)

const distPath = join(process.cwd(), packageDir, 'dist')
const files = await glob(`${distPath}/**/*.js`)

for (const file of files) {
  let content = await readFile(file, 'utf-8')
  // Fix imports without extensions
  content = content.replace(
    /from ['"](\.[^'"]+)['"]/g,
    (match, p1) => {
      if (!p1.endsWith('.js')) {
        return `from '${p1}.js'`
      }
      return match
    }
  )
  await writeFile(file, content)
}

console.log(`Fixed ESM imports in ${files.length} files`)
```

---

## Centralized Configuration

### Directory Structure

```
config/
├── typescript/
│   ├── tsconfig.base.json
│   ├── tsconfig.react.base.json
│   └── tsconfig.build.base.json
├── vitest/
│   ├── vitest.config.unit.base.js
│   ├── vitest.config.int.base.js
│   └── vitest.config.e2e.base.js
└── eslint/
    └── eslint.config.base.js
```

### TypeScript Base Config

**config/typescript/tsconfig.base.json:**

```json
{
  "compilerOptions": {
    "strict": true,
    "target": "ESNext",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "esModuleInterop": true,
    "experimentalDecorators": true,
    "emitDecoratorMetadata": true,
    "inlineSourceMap": true,
    "inlineSources": true,
    "resolveJsonModule": true,
    "resolvePackageJsonImports": true,
    "declarationMap": true,
    "skipLibCheck": true
  },
  "exclude": ["**/resource/*", "**/dist/*", "**/node_modules/*"]
}
```

### TypeScript React Base Config

**config/typescript/tsconfig.react.base.json:**

```json
{
  "extends": "./tsconfig.base.json",
  "compilerOptions": {
    "lib": ["ESNext", "DOM", "DOM.Iterable"],
    "jsx": "react-jsx",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "noEmit": true
  }
}
```

### Vitest Unit Config

**config/vitest/vitest.config.unit.base.js:**

```javascript
export default {
  test: {
    globals: true,
    environment: 'node',
    include: ['**/__tests__/**/*.test.ts'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      exclude: ['node_modules/', '**/*.test.ts', '**/__tests__/**']
    }
  }
}
```

### Vitest Integration Config

**config/vitest/vitest.config.int.base.js:**

```javascript
export default {
  test: {
    globals: true,
    environment: 'node',
    include: ['**/__tests__/**/*.int.test.ts'],
    testTimeout: 30000,
    setupFiles: ['../../config/vitest/setup.int.js']
  }
}
```

### ESLint Base Config

**config/eslint/eslint.config.base.js:**

```javascript
import js from '@eslint/js'

export default [
  js.configs.recommended,
  {
    rules: {
      'no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
      'no-console': 'warn'
    }
  }
]
```

---

## Shared Config Package

### packages/config/package.json

```json
{
  "name": "@app/config",
  "type": "commonjs",
  "exports": {
    "./eslint": "./eslint/index.js",
    "./prettier": "./prettier/index.js",
    "./lint-staged": "./lint-staged.js"
  }
}
```

### packages/config/eslint/index.js

```javascript
import baseConfig from '../../config/eslint/eslint.config.base.js'

export default [
  ...baseConfig,
  {
    ignores: ['dist/', 'node_modules/', 'coverage/']
  }
]
```

### packages/config/prettier/index.js

```javascript
export default {
  semi: false,
  singleQuote: true,
  trailingComma: 'none',
  printWidth: 100
}
```

---

## Environment Management

### Root .env.example

```env
NODE_ENV=development
LOG_LEVEL=debug

# Database
DATABASE_URL=postgres://app:app@pg:5432/app

# Message Queue
RMQ_URL=amqp://guest:guest@rmq:5672

# Security
JWT_SECRET=your-jwt-secret
ENCRYPTION_KEY=your-encryption-key
```

### Package .env Pattern

Each package can have its own `.env` for local overrides:

```env
PORT=3000
DATABASE_URL=postgres://app:app@pg:5432/app
```

### Secret Encryption

For encrypted secrets in version control:

```bash
# Encrypt secrets
pnpm run secret-encrypt

# Decrypt secrets
pnpm run secret-decrypt
```

Secrets stored in `resource/secret/.env.dev.enc`

---

## pnpm Catalog

**pnpm-workspace.yaml:**

```yaml
packages:
  - packages/*

catalog:
  # Core
  typescript: ^5.7
  vitest: ^3.0
  eslint: ^9.22
  prettier: ^3.5

  # Node
  "@types/node": ^22
  express: ^5.0
  typeorm: ^0.3
  pg: ^8
  amqplib: ^0.10
  jsonwebtoken: ^9

  # React
  react: ^19
  react-dom: ^19
  "@types/react": ^19
  "@types/react-dom": ^19
  "@mui/material": ^7
  "@emotion/react": ^11
  "@emotion/styled": ^11
  react-router-dom: ^7
  react-hook-form: ^7
  "@tanstack/react-query": ^5
  vite: ^6
  "@vitejs/plugin-react": ^4
  vite-tsconfig-paths: ^5

  # Mobile
  expo: ^52
  expo-router: ^4
  react-native: ^0.76

  # Web
  next: ^15

  # Dev
  nodemon: ^3
  sass: ^1

catalogProtocols:
  # Example: Link to external monorepo packages
  # This is for linking to packages outside this monorepo
  # msh-internal: link:
```

---

## Common Docker Commands

```bash
# Start all services
docker compose up -d

# View logs
docker compose logs -f node-core

# Rebuild a service
docker compose up -d --build node-core

# Stop all services
docker compose down

# Reset everything (including volumes)
docker compose down -v

# Run command in service
docker compose exec node-core pnpm test
```
