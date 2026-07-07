# React UI Component Layer

React UI Components are reusable, presentational components that handle rendering, user interaction, and local state management using React. Part of the **Presentation Layer (PL)** in frontend architecture.

**See [ui-component-layer.md](../ui-component-layer.md) for the abstract UI component pattern that applies to all UI frameworks.**

## Framework

This implementation uses:
- **React** - UI library for building user interfaces
- **MUI (Material-UI)** - React component library
- **React Query (@tanstack/react-query)** - Data fetching and caching
- **React Hooks** - useState, useEffect, useContext, etc.
- **TypeScript** - Type safety for props and state

## Naming Convention

**See [naming-convention.md](../../../style/naming-convention.md) for complete naming standards.**

- **File:** `kebab-case` (e.g., `list.tsx`, `detail.tsx`, `modal-form.tsx`)
- **Component:** `PascalCase` with domain prefix (e.g., `ProjectList`, `ProjectDetail`, `ProjectCommitSelectInput`)
- **Location:** `src/ui-component/[domain]/` or `src/component/[domain]/`

## Purpose

React UI Components implement reusable, composable UI elements that:
- Handle presentation logic and rendering
- Manage local UI state (form inputs, modals, tabs, etc.)
- Fetch data using React Query or similar libraries
- Respond to user interactions with event handlers
- Display loading states and error messages
- Compose smaller components into larger ones

## Structure

### Simple Presentational Component

```typescript
// src/ui-component/[domain]/status.tsx
import { Box, Typography } from '@mui/material'
import { OwnProjectParseDataStatus } from '@app/common/business/model/core/own-project-parse-data-model'
import { enumService } from '@app/common/business/service/enum-service'
import { Spinner, SpinnerSize } from '@app/react-common/component/util/spinner'
import React from 'react'

import { logger } from '#src/util/logger'

export const ProjectParseDataStatus = (props: { parseDataStatus: OwnProjectParseDataStatus }): React.ReactElement => {
  const { parseDataStatus } = props

  switch (parseDataStatus) {
    case OwnProjectParseDataStatus.PARSED:
      return (
        <Typography color="green">
          {enumService.ownProjectParseDataStatusToReadable(OwnProjectParseDataStatus.PARSED)}
        </Typography>
      )
    case OwnProjectParseDataStatus.ERROR:
      return (
        <Typography color="error">
          {enumService.ownProjectParseDataStatusToReadable(OwnProjectParseDataStatus.ERROR)}
        </Typography>
      )
    case OwnProjectParseDataStatus.PENDING:
      return (
        <Box display="flex" alignItems="center" gap={1}>
          <Typography color="primary">
            {enumService.ownProjectParseDataStatusToReadable(OwnProjectParseDataStatus.PENDING)}
          </Typography>
          <Spinner size={SpinnerSize.XS} />
        </Box>
      )
    default:
      logger().error(`Unknown ProjectSourceType ${parseDataStatus}`)
      return <Typography color="error">Unknown</Typography>
  }
}
```

### Smart Component with Data Fetching

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
      const { projectId, commit } = params
      return coreRepoSingleton().authorised.createOwnProjectParseDataByCommit({
        commit,
        ownerId,
        projectId,
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

### Form Input Component with Ref

```typescript
// src/ui-component/[domain]/select-input.tsx
import RefreshIcon from '@mui/icons-material/Refresh'
import { Alert, Box, FormControl, IconButton, InputLabel, MenuItem, Select, Skeleton, Tooltip } from '@mui/material'
import { useQuery } from '@tanstack/react-query'
import { selectedIdentityIdService } from '@app/react-common/business/service/token/selected-identity-id-service'
import { axiosError } from '@app/react-common/lib/axios/axios-error'
import React, { Ref, forwardRef, useImperativeHandle } from 'react'

import { coreRepoSingleton } from '#src/business/repo/rest/core-repo-singleton.ts'

export interface ProjectCommitSelectInputRefObject {
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
      staleTime: 1000 * 60 * 60 * 2,
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

## React Hooks Patterns

### useState for Local State

```typescript
const [count, setCount] = useState(0)
const [isOpen, setIsOpen] = useState(false)
const [formData, setFormData] = useState({ name: '', email: '' })
```

### useEffect for Side Effects

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

### useContext for Global State

```typescript
const { ownerId, isAuthenticated } = useContext(AuthContext)
const { theme, toggleTheme } = useContext(ThemeContext)
```

### Custom Hooks

```typescript
// src/hooks/use-projects.ts
import { useQuery } from '@tanstack/react-query'

export const useProjects = (ownerId: string) => {
  const { data, isLoading, error } = useQuery({
    queryKey: ['projects', ownerId],
    queryFn: () => projectRepo.getAll({ ownerId }),
  })

  return {
    projects: data ?? [],
    isLoading,
    error,
  }
}

// Usage in component
const { projects, isLoading } = useProjects(ownerId)
```

## React Query Patterns

### useQuery for Data Fetching

```typescript
const { data, isLoading, isError, error, refetch } = useQuery({
  queryKey: ['projects', ownerId],
  queryFn: async () => {
    return projectRepo.getAll({ ownerId })
  },
  staleTime: 1000 * 60 * 5, // 5 minutes
  refetchOnMount: false,
})
```

### useMutation for Data Modification

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

### Query Invalidation

```typescript
import { useQueryClient } from '@tanstack/react-query'

const queryClient = useQueryClient()

// Invalidate specific query
queryClient.invalidateQueries(['projects', ownerId])

// Invalidate all project queries
queryClient.invalidateQueries(['projects'])
```

## Component Categories

### 1. Presentational Components

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

### 2. Smart Components

Components that fetch data and manage state.

```typescript
export const ProjectList = (props: { ownerId: string }): React.ReactElement => {
  const { ownerId } = props
  const { data, isLoading } = useQuery(...)

  if (isLoading) return <Spinner />

  return <div>{data.map(p => <ProjectCard project={p} />)}</div>
}
```

### 3. Form Components

Components that handle form inputs and validation.

```typescript
export const ProjectCreateForm = (props: {
  onSubmit: (data: ProjectData) => void
}): React.ReactElement => {
  const [formData, setFormData] = useState({ name: '', sourceUrl: '' })

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    props.onSubmit(formData)
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

### 4. Layout Components

Components that structure other components.

```typescript
export const DashboardLayout = (props: {
  children: React.ReactNode
}): React.ReactElement => {
  return (
    <Box sx={{ display: 'flex', minHeight: '100vh' }}>
      <Sidebar />
      <Box component="main" sx={{ flexGrow: 1, p: 3 }}>
        {props.children}
      </Box>
    </Box>
  )
}
```

## Common Patterns

### Conditional Rendering

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

### Event Callbacks

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

### forwardRef Pattern

```typescript
export const CustomInput = forwardRef<HTMLInputElement, { label: string }>(
  (props, ref) => {
    return <input ref={ref} placeholder={props.label} />
  }
)
```

### useImperativeHandle Pattern

```typescript
export interface CustomInputRef {
  focus: () => void
  getValue: () => string
}

export const CustomInput = forwardRef<CustomInputRef, { label: string }>(
  (props, ref) => {
    const inputRef = useRef<HTMLInputElement>(null)

    useImperativeHandle(ref, () => ({
      focus: () => inputRef.current?.focus(),
      getValue: () => inputRef.current?.value ?? '',
    }))

    return <input ref={inputRef} placeholder={props.label} />
  }
)
```

## Folder Structure

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

## Architectural Rules

### ✅ DO

- Accept all data as props (never use routing hooks)
- Fetch data using React Query or similar libraries
- Manage local UI state with `useState`, `useReducer`
- Use TypeScript interfaces for props
- Handle loading and error states
- Use MUI components for consistent styling
- Compose smaller components into larger ones
- Use `forwardRef` and `useImperativeHandle` when exposing methods
- Use callback props for user interactions
- Keep components focused on single responsibility
- Use custom hooks for reusable logic
- Log errors using logger utilities

### ❌ DON'T

- Use routing hooks (`useParams`, `useNavigate`, `useLocation`)
- Access URL parameters or query strings directly
- Include routing logic
- Hardcode API endpoints (use repository layer)
- Access DAL or entities directly
- Use console.log (use logger instead)
- Make components too generic (prefer specific, clear naming)
- Create god components (split into smaller pieces)
- Put business logic in components (use services/use-cases)

## Testing React Components

For testing patterns and examples, use the **test-typescript** skill.

## Relationship with Other Layers

```
Screen → UI Component → Repository → Business Layer
            ↓
       Data Fetching (React Query)
       Local State Management
       User Interaction
```

React UI Components provide the presentation layer, handling rendering, user interactions, and data fetching while staying decoupled from routing and business logic.
