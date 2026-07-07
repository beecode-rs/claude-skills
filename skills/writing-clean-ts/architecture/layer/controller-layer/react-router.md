# React Router Controller Pattern

React Router controllers bridge the routing system and UI components in React/React Native/Expo applications. Part of the **Controller Layer (CL)** in frontend architecture, parallel to Express Controllers in backend architecture.

**See [controller-layer.md](../controller-layer.md) for the unified controller pattern across all interface types.**

## Naming Convention

**See [naming-convention.md](../../../style/naming-convention.md) for complete naming standards.**

- **File:** `kebab-case.tsx` (e.g., `list.tsx`, `detail.tsx`, `create.tsx`)
- **Component:** `PascalCase` function component (e.g., `ProjectList`, `ProjectDetail`, `ProjectCreate`)
- **Location:** `src/controller/react-router/[domain]/`

## Purpose

React Router controllers translate routing concerns (URL parameters, query strings, navigation context) into clean props for UI components, keeping components decoupled from routing implementation details.

### Responsibilities
- **Extract URL parameters** from the router (`useParams`)
- **Extract query parameters** from the URL (`useSearchParams`)
- **Bridge global context** (auth, theme, i18n) to components
- **Handle loading states** while waiting for required data
- **Validate route requirements** (missing params, auth checks)
- **Apply screen-level layout** (containers, padding, etc.)
- **Compose UI components** together for a complete screen

## Basic Structure

### Simple Controller

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

### Controller with URL Parameters

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

### Controller with Query Parameters

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

## Common Patterns

### Authentication Guard

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

### Multiple Components Composition

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

### Tab Navigation

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

### Error Boundary

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

## Router Integration

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

## Folder Structure

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

## Key Characteristics

- **Router adapter**: Extracts data from URL params, query strings, and navigation state
- **Minimal logic**: Only handles routing translation and basic validation
- **Context bridge**: Connects global context (auth, theme, etc.) to components
- **Loading states**: Shows spinners or placeholders while checking auth/context
- **Error boundaries**: Handles missing required parameters gracefully
- **Layout wrapper**: Applies screen-level layout (padding, containers, etc.)
- **Component composition**: Combines one or more UI components
- **Route-specific**: Not reusable, designed for specific routes

## Architectural Rules

### ✅ DO

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

### ❌ DON'T

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

## Comparison with Express Controllers

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

## Relationship with Other Layers

```
Router → Controller (React Router) → UI Component → Business Layer (if needed)
           ↓
       Parameter Extraction
       Context Bridge
       Layout Wrapper
```

### Flow Breakdown

1. **Router** provides URL params and query strings
2. **Controller** extracts and validates them
3. **Controller** accesses global context (auth, theme, etc.)
4. **Controller** translates everything into clean props
5. **UI Component** receives pure data and callbacks
6. **UI Component** may interact with business layer (services, hooks)

### Benefits of Separation

- **Modular components**: UI components are self-contained and reusable
- **Reusable components**: Same component can be used in multiple screens
- **Framework-agnostic**: Easy to switch from React Router to another solution
- **Clear responsibilities**: Routing concerns isolated from UI logic
- **Type safety**: Full TypeScript support with clear prop interfaces

## Integration with Business Layer

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
export const ProjectList = ({ ownerId }: Props): React.ReactElement => {
  const { projects, loading } = useProjects(ownerId) // Hook accesses service

  if (loading) return <Spinner />

  return <div>{projects.map(p => <ProjectCard project={p} />)}</div>
}
```

## Testing Controllers

For testing patterns and examples, use the **test-typescript** skill.

## Best Practices

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
