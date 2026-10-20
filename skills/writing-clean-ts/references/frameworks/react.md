# React

Everything React-specific: React Router controllers (the frontend controller layer), React UI components (MUI, React Query, hooks), and React/Vite import setup. In an Expo Router project the React Router controller part is replaced by Expo route files; the React UI component part still applies.

## Contents

- [React In This Skill's Layers](#react-in-this-skills-layers)
- [React Router Controller Pattern](#react-router-controller-pattern)
  - [Naming Convention](#naming-convention)
  - [Purpose](#purpose)
  - [Basic Structure](#basic-structure)
  - [Common Patterns](#common-patterns)
  - [Router Integration](#router-integration)
  - [Folder Structure](#folder-structure)
  - [Key Characteristics](#key-characteristics)
  - [Architectural Rules](#architectural-rules)
  - [Comparison with Express Controllers](#comparison-with-express-controllers)
  - [Relationship with Other Layers](#relationship-with-other-layers)
  - [Integration with Business Layer](#integration-with-business-layer)
  - [Testing Controllers](#testing-controllers)
  - [Best Practices](#best-practices)
- [React UI Component Layer](#react-ui-component-layer)
  - [Framework](#framework)
  - [Naming Convention](#naming-convention-1)
  - [Purpose](#purpose-1)
  - [Structure](#structure)
  - [React Hooks Patterns](#react-hooks-patterns)
  - [React Query Patterns](#react-query-patterns)
  - [Component Categories](#component-categories)
  - [Common Patterns](#common-patterns-1)
  - [Folder Structure](#folder-structure-1)
  - [Architectural Rules](#architectural-rules-1)
  - [Testing React Components](#testing-react-components)
  - [Relationship with Other Layers](#relationship-with-other-layers-1)

## React In This Skill's Layers

| Layer | Pattern | Location |
|-------|---------|----------|
| **Controller** (React Router) | Function Component | `src/controller/react-router/` |
| **UI Component** | Function Component | `src/ui-component/` |

| Layer | File | Export | Example |
|-------|------|--------|---------|
| Controller (React Router) | `kebab-case.tsx` | `PascalCase` component | `<ProjectListController />` |
| UI Component | `kebab-case.tsx` | `PascalCase` component | `<ProjectList />` |

- **Order of creation (frontend)**: Controller (React Router) → UI Component
- **Controllers**: React Router → function components that translate URL → props. They translate URL params/query strings into UI component props
- Shared React hooks live in `src/business/hook/`
- Expo Router projects do not use `src/controller/react-router/`: route files in `src/app/` are the controllers

**Frontend Feature layout** (React Router):
```
src/
├── controller/react-router/feature-name/
│   ├── list.tsx                                 # /feature-name
│   ├── detail.tsx                               # /feature-name/:id
│   ├── create.tsx                               # /feature-name/create
│   └── edit.tsx                                 # /feature-name/:id/edit
└── ui-component/feature-name/
    ├── list.tsx
    ├── detail.tsx
    ├── create-form.tsx
    └── edit-form.tsx
```

**React Router controller shape:**
```typescript
// React Router Controller - Extracts routing params
export const ProjectDetailController = (): React.ReactElement => {
  const { projectId } = useParams<{ projectId: string }>()
  const { ownerId } = useContext(AuthContext)

  if (!projectId || !ownerId) return <ErrorView />

  return (
    <Box sx={{ p: 1 }}>
      <ProjectDetail projectId={projectId} ownerId={ownerId} />
    </Box>
  )
}
```

**Imports in React/Vite projects:** use `"module": "ESNext"` with `"moduleResolution": "Bundler"` and the same `#src` `paths` entry (`"#src": ["./src"]`, `"#src/*": ["./src/*"]`). Bundler resolution omits the `.js` extensions on internal imports. Make Vite resolve `#src` with the `vite-tsconfig-paths` plugin or an equivalent `resolve.alias` entry mapping `#src` to `./src`.

**Frontend pitfalls:**
- ❌ Using routing hooks in UI components → ✅ Only controllers use routing hooks
- ❌ Making controllers reusable → ✅ One controller per route
- ❌ Not extracting URL params in controller → ✅ Controllers translate router → props
- ❌ Business logic in UI components → ✅ Use services/repositories
- ❌ Relative imports (`from '../ui-component/foo'`) → ✅ Absolute `#src` alias imports only `[lint]`

## React Router Controller Pattern

> **Expo Router projects:** this React Router controller section does not apply. Routes live in `src/app/` and the route file is the controller.

React Router controllers bridge the routing system and UI components in React/React Native/Expo applications. Part of the **Controller Layer (CL)** in frontend architecture, parallel to Express Controllers in backend architecture.

### Naming Convention

- **File:** `kebab-case.tsx` (e.g., `list.tsx`, `detail.tsx`, `create.tsx`)
- **Component:** `PascalCase` function component (e.g., `ProjectList`, `ProjectDetail`, `ProjectCreate`)
- **Location:** `src/controller/react-router/[domain]/`

### Purpose

React Router controllers translate routing concerns (URL parameters, query strings, navigation context) into clean props for UI components, keeping components decoupled from routing implementation details.

#### Responsibilities
- **Extract URL parameters** from the router (`useParams`)
- **Extract query parameters** from the URL (`useSearchParams`)
- **Bridge global context** (auth, theme, i18n) to components
- **Handle loading states** while waiting for required data
- **Validate route requirements** (missing params, auth checks)
- **Apply screen-level layout** (containers, padding, etc.)
- **Compose UI components** together for a complete screen

### Basic Structure

#### Simple Controller

```typescript
// src/controller/react-router/project/list.tsx
import { Box } from '@mui/material'
import { AuthContext } from '@app/react-common/business/context/auth-context'
import { Spinner } from '@app/react-common/component/util/spinner'
import React, { useContext } from 'react'

import { ProjectList } from '#src/ui-component/project/list'

export const ProjectListController = (): React.ReactElement => {
  const { ownerId } = useContext(AuthContext)

  if (!ownerId) {
    return <Spinner />
  }

  return (
    <Box sx={{ mt: 1, p: 1 }}>
      <ProjectList ownerId={ownerId} />
    </Box>
  )
}
```

#### Controller with URL Parameters

```typescript
// src/controller/react-router/project/detail.tsx
import { Box } from '@mui/material'
import { AuthContext } from '@app/react-common/business/context/auth-context'
import React, { useContext } from 'react'
import { useParams } from 'react-router-dom'

import { ProjectDetail } from '#src/ui-component/project/detail'

export const ProjectDetailController = (): React.ReactElement => {
  const { projectId } = useParams<{ projectId: string }>()
  const { ownerId } = useContext(AuthContext)

  if (!projectId) {
    return <div>Project ID not found</div>
  }

  if (!ownerId) {
    return <div>Owner ID not found</div>
  }

  return (
    <Box sx={{ mt: 1, p: 1 }}>
      <ProjectDetail projectId={projectId} ownerId={ownerId} />
    </Box>
  )
}
```

#### Controller with Query Parameters

```typescript
// src/controller/react-router/project/create.tsx
import { Box } from '@mui/material'
import { AuthContext } from '@app/react-common/business/context/auth-context'
import React, { useContext } from 'react'
import { useSearchParams } from 'react-router-dom'

import { ProjectCreate } from '#src/ui-component/project/create'

export const ProjectCreateController = (): React.ReactElement => {
  const [searchParams] = useSearchParams()
  const { ownerId } = useContext(AuthContext)
  const templateId = searchParams.get('templateId')

  if (!ownerId) {
    return <div>Owner ID not found</div>
  }

  return (
    <Box sx={{ mt: 1, p: 1 }}>
      <ProjectCreate ownerId={ownerId} templateId={templateId ?? undefined} />
    </Box>
  )
}
```

### Common Patterns

#### Authentication Guard

```typescript
export const ProtectedController = (): React.ReactElement => {
  const { ownerId, isLoading } = useContext(AuthContext)

  if (isLoading) {
    return <Spinner />
  }

  if (!ownerId) {
    return <Navigate to="/login" replace />
  }

  return <ProtectedContent ownerId={ownerId} />
}
```

#### Multiple Components Composition

```typescript
export const DashboardController = (): React.ReactElement => {
  const { ownerId } = useContext(AuthContext)

  return (
    <Box sx={{ p: 2 }}>
      <UserProfile ownerId={ownerId} />
      <RecentActivity ownerId={ownerId} />
      <Statistics ownerId={ownerId} />
    </Box>
  )
}
```

#### Tab Navigation

```typescript
export const ProjectTabEditController = (): React.ReactElement => {
  const { projectId, tab } = useParams<{ projectId: string; tab: string }>()
  const { ownerId } = useContext(AuthContext)

  if (!projectId || !tab) {
    return <Navigate to="/projects" replace />
  }

  return (
    <Box sx={{ p: 1 }}>
      <ProjectTabEditor projectId={projectId} activeTab={tab} ownerId={ownerId} />
    </Box>
  )
}
```

#### Error Boundary

```typescript
export const ProjectDetailController = (): React.ReactElement => {
  const { projectId } = useParams<{ projectId: string }>()
  const { ownerId } = useContext(AuthContext)
  const navigate = useNavigate()

  if (!projectId) {
    return (
      <Box sx={{ p: 2 }}>
        <Alert severity="error">
          Project ID is required
          <Button onClick={() => navigate('/projects')}>Go to Projects</Button>
        </Alert>
      </Box>
    )
  }

  if (!ownerId) {
    return <Navigate to="/login" replace />
  }

  return (
    <Box sx={{ mt: 1, p: 1 }}>
      <ProjectDetail projectId={projectId} ownerId={ownerId} />
    </Box>
  )
}
```

### Router Integration

```typescript
// src/controller/react-router/router.tsx
import { createBrowserRouter } from 'react-router-dom'
import { ProjectCreateController } from './project/create'
import { ProjectDetailController } from './project/detail'
import { ProjectListController } from './project/list'
import { HomeController } from './home'

export const router = createBrowserRouter([
  {
    path: '/',
    element: <HomeController />,
  },
  {
    path: '/projects',
    element: <ProjectListController />,
  },
  {
    path: '/projects/create',
    element: <ProjectCreateController />,
  },
  {
    path: '/projects/:projectId',
    element: <ProjectDetailController />,
  },
  {
    path: '/projects/:projectId/edit',
    element: <ProjectEditController />,
  },
])
```

### Folder Structure

```
src/
  controller/
    react-router/
      home.tsx                         # Root/home route controller
      project/                         # Domain-based grouping
        list.tsx                       # /projects
        detail.tsx                     # /projects/:projectId
        create.tsx                     # /projects/create
        edit.tsx                       # /projects/:projectId/edit
        parse-data/                    # Nested feature
          puml.tsx                     # /projects/:projectId/parse-data/puml
      user/
        profile.tsx                    # /user/profile
        settings.tsx                   # /user/settings
      route-alias.ts                   # Route path constants
      router.tsx                       # Route configuration
```

### Key Characteristics

- **Router adapter**: Extracts data from URL params, query strings, and navigation state
- **Minimal logic**: Only handles routing translation and basic validation
- **Context bridge**: Connects global context (auth, theme, etc.) to components
- **Loading states**: Shows spinners or placeholders while checking auth/context
- **Error boundaries**: Handles missing required parameters gracefully
- **Layout wrapper**: Applies screen-level layout (padding, containers, etc.)
- **Component composition**: Combines one or more UI components
- **Route-specific**: Not reusable, designed for specific routes

### Architectural Rules

#### ✅ DO

- Extract URL parameters using `useParams()`
- Extract query parameters using `useSearchParams()`
- Access global context (auth, theme, i18n) and pass as props to components
- Show loading spinners while waiting for required context data
- Display error messages for missing required URL parameters
- Apply screen-level layout wrappers (Box, Container, etc.)
- Keep components pure by translating router concerns into clean props
- Name files with `-screen.tsx` suffix
- Return early for loading/error states
- Connect multiple components when needed
- Use `Navigate` component for redirects
- Handle null/undefined checks for required parameters
- Keep screens focused on a single route

#### ❌ DON'T

- Include business logic (use services/use-cases instead)
- Make API calls directly (components should handle data fetching)
- Access DAL, Repository, or Service layers
- Pass router hooks (`useParams`, `useNavigate`) to child components
- Put complex state management in screens
- Style individual elements (use components for styling)
- Make screens reusable (they're route-specific by design)
- Include complex conditional rendering (move to components)
- Skip parameter validation
- Use screens for non-route-related logic

### Comparison with Express Controllers

| Aspect | Express Controller | React Router Controller |
|--------|-------------------|------------------------|
| **Interface** | HTTP (Express) | React Router |
| **Input** | Request (params, query, body) | URL params, query strings, context |
| **Validation** | Zod schemas | TypeScript types + null checks |
| **Output** | HTTP Response | React Element |
| **Error Handling** | HTTP status codes | Error components / redirects |
| **Location** | `src/controller/express/` | `src/controller/react-router/` |
| **Export** | Singleton object | React component |
| **Documentation** | Swagger/OpenAPI | Type definitions |

### Relationship with Other Layers

```
Router → Controller (React Router) → UI Component → Business Layer (if needed)
           ↓
       Parameter Extraction
       Context Bridge
       Layout Wrapper
```

#### Flow Breakdown

1. **Router** provides URL params and query strings
2. **Controller** extracts and validates them
3. **Controller** accesses global context (auth, theme, etc.)
4. **Controller** translates everything into clean props
5. **UI Component** receives pure data and callbacks
6. **UI Component** may interact with business layer (services, hooks)

#### Benefits of Separation

- **Modular components**: UI components are self-contained and reusable
- **Reusable components**: Same component can be used in multiple screens
- **Framework-agnostic**: Easy to switch from React Router to another solution
- **Clear responsibilities**: Routing concerns isolated from UI logic
- **Type safety**: Full TypeScript support with clear prop types

### Integration with Business Layer

Controllers should NOT directly access business logic. Instead:

```typescript
// ❌ BAD: Controller accessing service directly
export const ProjectListController = (): React.ReactElement => {
  const [projects, setProjects] = useState([])

  useEffect(() => {
    projectService.getAll().then(setProjects) // DON'T DO THIS
  }, [])

  return <div>{projects.map(p => <div>{p.name}</div>)}</div>
}

// ✅ GOOD: Controller delegates to UI component, component uses hook/service
export const ProjectListController = (): React.ReactElement => {
  const { ownerId } = useContext(AuthContext)

  return (
    <Box sx={{ p: 1 }}>
      <ProjectList ownerId={ownerId} />
    </Box>
  )
}

// UI Component handles business logic
export const ProjectList = (props: { ownerId: string }): React.ReactElement => {
  const { ownerId } = props
  const { projects, isLoading } = useProjects({ ownerId })

  if (isLoading) {
    return <Spinner />
  }

  return <div>{projects.map(p => <ProjectCard project={p} />)}</div>
}
```

### Testing Controllers

For testing patterns and examples, use the **test-typescript** skill.

### Best Practices

1. **Keep controllers thin**: Only routing translation, no business logic
2. **Validate early**: Check for required parameters at the top
3. **Use early returns**: Handle error/loading states immediately
4. **Consistent layout**: Apply standard padding/containers at controller level
5. **Type safety**: Always type `useParams` and `useSearchParams`
6. **Context usage**: Extract only what's needed from context
7. **Component delegation**: Let UI components handle data fetching and state
8. **Error handling**: Show user-friendly error messages, not crashes
9. **Loading states**: Always show feedback while waiting for auth/context
10. **Navigation**: Use `Navigate` component for redirects, not `navigate()` in render

This pattern ensures a clean separation between routing concerns and UI logic, making your application more maintainable, testable, and easier to refactor.

## React UI Component Layer

React UI Components are reusable, presentational components that handle rendering, user interaction, and local state management using React. Part of the **Presentation Layer (PL)** in frontend architecture.

### Framework

This implementation uses:
- **React** - UI library for building user interfaces
- **MUI (Material-UI)** - React component library
- **React Query (@tanstack/react-query)** - Data fetching and caching
- **React Hooks** - useState, useEffect, useContext, etc.
- **TypeScript** - Type safety for props and state

### Naming Convention

- **File:** `kebab-case` (e.g., `list.tsx`, `detail.tsx`, `modal-form.tsx`)
- **Component:** `PascalCase` with domain prefix (e.g., `ProjectList`, `ProjectDetail`, `ProjectCommitSelectInput`)
- **Location:** `src/ui-component/[domain]/` or `src/component/[domain]/`

### Purpose

React UI Components implement reusable, composable UI elements that:
- Handle presentation logic and rendering
- Manage local UI state (form inputs, modals, tabs, etc.)
- Fetch data using React Query or similar libraries
- Respond to user interactions with event handlers
- Display loading states and error messages
- Compose smaller components into larger ones

### Structure

#### Simple Presentational Component

```typescript
// src/ui-component/[domain]/status.tsx
import { Box, Typography } from '@mui/material'
import { OwnProjectParseDataStatus } from '@app/common/business/enum/own-project-parse-data-status-enum'
import { enumService } from '@app/common/business/service/enum-service'
import { Spinner, SpinnerSize } from '@app/react-common/component/util/spinner'
import { typeUtil } from '@beecode/msh-util/type-util'
import React from 'react'

export const ProjectParseDataStatus = (props: { parseDataStatus: OwnProjectParseDataStatus }): React.ReactElement => {
  const { parseDataStatus } = props

  switch (parseDataStatus) {
    case OwnProjectParseDataStatus.PARSED: {
      return (
        <Typography color="green">
          {enumService.ownProjectParseDataStatusToReadable(OwnProjectParseDataStatus.PARSED)}
        </Typography>
      )
    }
    case OwnProjectParseDataStatus.ERROR: {
      return (
        <Typography color="error">
          {enumService.ownProjectParseDataStatusToReadable(OwnProjectParseDataStatus.ERROR)}
        </Typography>
      )
    }
    case OwnProjectParseDataStatus.PENDING: {
      return (
        <Box display="flex" alignItems="center" gap={1}>
          <Typography color="primary">
            {enumService.ownProjectParseDataStatusToReadable(OwnProjectParseDataStatus.PENDING)}
          </Typography>
          <Spinner size={SpinnerSize.XS} />
        </Box>
      )
    }
    default: {
      throw typeUtil.exhaustiveError('unknown parse data status', parseDataStatus)
    }
  }
}
```

#### Smart Component with Data Fetching

```typescript
// src/ui-component/[domain]/list.tsx
import { Box, Button, Table, TableBody, TableCell, TableContainer, TableHead, TableRow } from '@mui/material'
import { useMutation, useQuery } from '@tanstack/react-query'
import { GetOwnProjectParseDatasDocument } from '@app/common/__generated__/codegen'
import { SkeletonTableRow } from '@app/react-common/component/util/skeleton-table-row'
import { TableErrorDataRow } from '@app/react-common/component/util/table-error-data-row'
import { TableNoDataRow } from '@app/react-common/component/util/table-no-data-row'
import { reactQueryKey } from '@app/react-common/lib/react-query/key'
import React from 'react'

import { gqlRepoSingleton } from '#src/business/repo/gql-repo-singleton'
import { coreRepoSingleton } from '#src/business/repo/rest/core-repo-singleton'
import { ProjectParseDataStatus } from '#src/ui-component/project/parse-data/status'
import { toasterUtil } from '#src/util/toaster-util'

export const ProjectParseDataList = (props: {
  projectId: string
  uniqueId?: string
  ownerId: string
}): React.ReactElement => {
  const { projectId, uniqueId, ownerId } = props

  const {
    data: getOwnProjectParseDatasResponse,
    isLoading,
    isError,
  } = useQuery({
    queryFn: async () => {
      return gqlRepoSingleton().query({
        query: GetOwnProjectParseDatasDocument,
        variables: { ownerId, projectId, filter: { uniqueId } }
      })
    },
    queryKey: reactQueryKey.gqlOwnProjectParseDatas({ ownerId, projectId, filter: { uniqueId } }),
    refetchOnMount: false,
  })

  const parseDatas = getOwnProjectParseDatasResponse?.getOwnProjectParseDatas.data ?? []

  const { mutate, isPending } = useMutation({
    mutationFn: async (params: { commit: string; projectId: string }) => {
      const { projectId: parseProjectId, commit } = params

      return coreRepoSingleton().authorised.createOwnProjectParseDataByCommit({
        commit,
        ownerId,
        projectId: parseProjectId,
      })
    },
    onError: toasterUtil().axiosErrorHandler,
    onSuccess: () => {
      toasterUtil().success('Parse project started')
    },
  })

  const handleParseProjectData = (): void => {
    if (!uniqueId) {
      toasterUtil().error('Missing unique id')
      return
    }
    mutate({ commit: uniqueId, projectId })
  }

  if (isLoading) {
    return <SkeletonTableRow columns={3} />
  }

  if (isError) {
    return <TableErrorDataRow columns={3} />
  }

  return (
    <TableContainer>
      <Table>
        <TableHead>
          <TableRow>
            <TableCell>Unique ID</TableCell>
            <TableCell>Status</TableCell>
            <TableCell>Action</TableCell>
          </TableRow>
        </TableHead>
        <TableBody>
          {parseDatas.length === 0 ? (
            <TableNoDataRow columns={3}>
              <Button onClick={handleParseProjectData} disabled={isPending}>
                Parse Data
              </Button>
            </TableNoDataRow>
          ) : (
            parseDatas.map((parseData) => (
              <TableRow key={parseData.id}>
                <TableCell>{parseData.uniqueId}</TableCell>
                <TableCell>
                  <ProjectParseDataStatus parseDataStatus={parseData.status} />
                </TableCell>
                <TableCell>
                  <Button disabled={isPending}>PUML</Button>
                </TableCell>
              </TableRow>
            ))
          )}
        </TableBody>
      </Table>
    </TableContainer>
  )
}
```

#### Form Input Component with Ref

```typescript
// src/ui-component/[domain]/select-input.tsx
import RefreshIcon from '@mui/icons-material/Refresh'
import { Alert, Box, FormControl, IconButton, InputLabel, MenuItem, Select, Skeleton, Tooltip } from '@mui/material'
import { useQuery } from '@tanstack/react-query'
import { selectedIdentityIdService } from '@app/react-common/business/service/token/selected-identity-id-service'
import { axiosError } from '@app/react-common/lib/axios/axios-error'
import React, { Ref, forwardRef, useImperativeHandle } from 'react'

import { coreRepoSingleton } from '#src/business/repo/rest/core-repo-singleton.ts'

export type ProjectCommitSelectInputRefObject = {
  getSelectedValue: () => string
}

export const ProjectCommitSelectInput = forwardRef(
  (
    props: { projectId: string; onChange?: (commit?: string) => void },
    ref: Ref<ProjectCommitSelectInputRefObject>
  ): React.ReactElement => {
    const { projectId, onChange } = props

    const {
      data: commits,
      isLoading,
      isError,
      error,
      refetch,
    } = useQuery({
      queryFn: async () => {
        return coreRepoSingleton().authorised.getOwnProjectCommits({
          ownerId: await selectedIdentityIdService.get(),
          projectId
        })
      },
      queryKey: ['projectCommits', projectId],
      staleTime: constant.projectCommit.cacheStaleMs,
    })

    const [selectedCommit, setSelectedCommit] = React.useState('')

    const getCommitHash = (value: string): string => {
      const [commitHash] = value.split('|')
      return commitHash
    }

    const handleChange = (value: string): void => {
      setSelectedCommit(value)
      onChange?.(getCommitHash(value))
    }

    useImperativeHandle(ref, () => ({
      getSelectedValue: () => getCommitHash(selectedCommit),
    }))

    if (isLoading) {
      return <Skeleton variant="rectangular" height={56} />
    }

    if (isError) {
      return (
        <Alert severity="error">
          <b>Select commit input control error:</b>
          <br />
          {axiosError.getMessage(error)}
        </Alert>
      )
    }

    return (
      <Box display="flex" justifyContent="space-between" alignItems="center">
        <FormControl fullWidth>
          <InputLabel id="commit-select-label">Commit</InputLabel>
          <Select
            labelId="commit-select-label"
            value={selectedCommit}
            label="Commit"
            onChange={(event) => handleChange(event.target.value)}
          >
            {commits?.map((commit, ix) => (
              <MenuItem key={ix} value={`${commit.commitHash}|${commit.name}`}>
                {commit.type}: {commit.name}
              </MenuItem>
            ))}
          </Select>
        </FormControl>
        <Tooltip title="Refresh commits" placement="top">
          <IconButton onClick={() => refetch()}>
            <RefreshIcon />
          </IconButton>
        </Tooltip>
      </Box>
    )
  }
)
```

### React Hooks Patterns

#### useState for Local State

```typescript
const [count, setCount] = useState(0)
const [isOpen, setIsOpen] = useState(false)
const [formData, setFormData] = useState({ name: '', email: '' })
```

#### useEffect for Side Effects

```typescript
useEffect(() => {
  // Run on mount and when projectId changes
  fetchProjectData(projectId)
}, [projectId])

useEffect(() => {
  // Run once on mount
  initializeComponent()
}, [])

useEffect(() => {
  // Cleanup on unmount
  return () => {
    cleanup()
  }
}, [])
```

#### useContext for Global State

```typescript
const { ownerId, isAuthenticated } = useContext(AuthContext)
const { theme, toggleTheme } = useContext(ThemeContext)
```

#### Custom Hooks

```typescript
// src/business/hook/use-projects.ts
import { useQuery } from '@tanstack/react-query'

export const useProjects = (params: { ownerId: string }) => {
  const { ownerId } = params

  const { data, isLoading, error } = useQuery({
    queryKey: ['projects', ownerId],
    queryFn: () => {
      return projectRepo.getAll({ ownerId })
    },
  })

  return {
    projects: data ?? [],
    isLoading,
    error,
  }
}

// Usage in component
const { projects, isLoading } = useProjects({ ownerId })
```

### React Query Patterns

#### useQuery for Data Fetching

```typescript
const { data, isLoading, isError, error, refetch } = useQuery({
  queryKey: ['projects', ownerId],
  queryFn: async () => {
    return projectRepo.getAll({ ownerId })
  },
  staleTime: constant.project.cacheStaleMs,
  refetchOnMount: false,
})
```

#### useMutation for Data Modification

```typescript
const { mutate, isPending, isError } = useMutation({
  mutationFn: async (data: ProjectCreate) => {
    return projectRepo.create(data)
  },
  onSuccess: (data) => {
    toaster.success('Project created')
    queryClient.invalidateQueries(['projects'])
  },
  onError: (error) => {
    toaster.error('Failed to create project')
  },
})

// Trigger mutation
mutate({ name: 'New Project', sourceUrl: '...' })
```

#### Query Invalidation

```typescript
import { useQueryClient } from '@tanstack/react-query'

const queryClient = useQueryClient()

// Invalidate specific query
queryClient.invalidateQueries(['projects', ownerId])

// Invalidate all project queries
queryClient.invalidateQueries(['projects'])
```

### Component Categories

#### 1. Presentational Components

Pure components that only render based on props (no data fetching).

```typescript
export const UserAvatar = (props: { name: string; imageUrl?: string }): React.ReactElement => {
  const { name, imageUrl } = props
  return (
    <Avatar src={imageUrl} alt={name}>
      {name[0].toUpperCase()}
    </Avatar>
  )
}
```

#### 2. Smart Components

Components that fetch data and manage state.

```typescript
export const ProjectList = (props: { ownerId: string }): React.ReactElement => {
  const { ownerId } = props
  const { data, isLoading } = useQuery(...)

  if (isLoading) return <Spinner />

  return <div>{data.map(p => <ProjectCard project={p} />)}</div>
}
```

#### 3. Form Components

Components that handle form inputs and validation.

```typescript
export const ProjectCreateForm = (props: {
  onSubmit: (data: ProjectData) => void
}): React.ReactElement => {
  const { onSubmit } = props
  const [formData, setFormData] = useState({ name: '', sourceUrl: '' })

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    onSubmit(formData)
  }

  return (
    <form onSubmit={handleSubmit}>
      <TextField
        label="Name"
        value={formData.name}
        onChange={(e) => setFormData({ ...formData, name: e.target.value })}
      />
      <Button type="submit">Create</Button>
    </form>
  )
}
```

#### 4. Layout Components

Components that structure other components.

```typescript
export const DashboardLayout = (props: {
  children: React.ReactNode
}): React.ReactElement => {
  const { children } = props

  return (
    <Box sx={{ display: 'flex', minHeight: '100vh' }}>
      <Sidebar />
      <Box component="main" sx={{ flexGrow: 1, p: 3 }}>
        {children}
      </Box>
    </Box>
  )
}
```

### Common Patterns

#### Conditional Rendering

```typescript
export const DataTable = (props: { data: Item[]; isLoading: boolean }): React.ReactElement => {
  const { data, isLoading } = props

  if (isLoading) {
    return <SkeletonTableRow columns={4} />
  }

  if (data.length === 0) {
    return <TableNoDataRow columns={4}>No items found</TableNoDataRow>
  }

  return <Table>{/* Render data */}</Table>
}
```

#### Event Callbacks

```typescript
export const TodoItem = (props: {
  item: TodoModel
  onComplete: (id: string) => void
  onDelete: (id: string) => void
}): React.ReactElement => {
  const { item, onComplete, onDelete } = props

  return (
    <Box>
      <Typography>{item.title}</Typography>
      <Button onClick={() => onComplete(item.id)}>Complete</Button>
      <Button onClick={() => onDelete(item.id)}>Delete</Button>
    </Box>
  )
}
```

#### forwardRef Pattern

```typescript
export const CustomInput = forwardRef<HTMLInputElement, { label: string }>(
  (props, ref) => {
    const { label } = props

    return <input ref={ref} placeholder={label} />
  }
)
```

#### useImperativeHandle Pattern

```typescript
export type CustomInputRef = {
  focus: () => void
  getValue: () => string
}

export const CustomInput = forwardRef<CustomInputRef, { label: string }>(
  (props, ref) => {
    const { label } = props
    const inputRef = useRef<HTMLInputElement>(null)

    useImperativeHandle(ref, () => ({
      focus: () => inputRef.current?.focus(),
      getValue: () => inputRef.current?.value ?? '',
    }))

    return <input ref={inputRef} placeholder={label} />
  }
)
```

### Folder Structure

```
src/
  ui-component/              # or component/
    project/                 # Domain grouping
      list.tsx              # ProjectList
      detail.tsx            # ProjectDetail
      create-form.tsx       # ProjectCreateForm
      commit-select-input.tsx
      parse-data/           # Nested feature
        list.tsx            # ProjectParseDataList
        status.tsx          # ProjectParseDataStatus
        puml-view.tsx       # ProjectParseDataPumlView
      secret/
        modal-form.tsx      # ProjectSecretModalForm
    user/
      avatar.tsx            # UserAvatar
      profile-card.tsx      # UserProfileCard
    util/                   # Shared utilities
      spinner.tsx
      skeleton-table-row.tsx
      table-error-data-row.tsx
```

### Architectural Rules

#### ✅ DO

- Accept all data as props (never use routing hooks)
- Fetch data using React Query or similar libraries
- Manage local UI state with `useState`, `useReducer`
- Type props with an inline `type` (never `interface`), destructure them on the first line, and put defaults in the signature
- Handle loading and error states
- Use MUI components for consistent styling
- Compose smaller components into larger ones
- Use `forwardRef` and `useImperativeHandle` when exposing methods
- Use callback props for user interactions
- Keep components focused on single responsibility
- Use custom hooks for reusable logic
- Log errors using logger utilities

#### ❌ DON'T

- Use routing hooks (`useParams`, `useNavigate`, `useLocation`)
- Access URL parameters or query strings directly
- Include routing logic
- Hardcode API endpoints (use repository layer)
- Access DAL or entities directly
- Use console.log (use logger instead)
- Make components too generic (prefer specific, clear naming)
- Create god components (split into smaller pieces)
- Put business logic in components (use services/use-cases)

### Testing React Components

For testing patterns and examples, use the **test-typescript** skill.

### Relationship with Other Layers

```
Screen → UI Component → Repository → Business Layer
            ↓
       Data Fetching (React Query)
       Local State Management
       User Interaction
```

React UI Components provide the presentation layer, handling rendering, user interactions, and data fetching while staying decoupled from routing and business logic.
