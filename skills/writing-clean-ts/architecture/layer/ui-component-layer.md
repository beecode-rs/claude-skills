# UI Component Layer

UI Components are reusable, presentational components that handle rendering, user interaction, and local state management. Part of the **Presentation Layer (PL)** in frontend architecture.

## Framework Implementations

This is an abstract layer pattern. See framework-specific implementations:
- **[React UI Components](./ui-component-layer/react.md)** - React components with MUI and React Query

## Naming Convention

**See [naming-convention.md](../../style/naming-convention.md) for complete naming standards.**

- **File:** `kebab-case` (e.g., `list.tsx`, `detail.tsx`, `modal-form.tsx`)
- **Component:** `PascalCase` with domain prefix (e.g., `ProjectList`, `ProjectDetail`, `ProjectCommitSelectInput`)
- **Location:** `src/ui-component/[domain]/` or `src/component/[domain]/`

## Purpose

The UI Component Layer implements reusable, composable UI elements that handle presentation logic, user interactions, and data fetching. Components should be framework-aware but router-agnostic, receiving all routing data as props from controllers/screens.

## Structure

**Framework Implementation**: See [ui-component-layer-react.md](./ui-component-layer/react.md) for React implementation.

### Simple Presentational Component

**Conceptual Structure:**
```typescript
// Abstract concept - not framework-specific
export const ProjectParseDataStatus = (props: { status: Status }) => {
  const { status } = props

  switch (status) {
    case Status.PARSED:
      return <Text color="success">{statusToReadable(Status.PARSED)}</Text>
    case Status.ERROR:
      return <Text color="error">{statusToReadable(Status.ERROR)}</Text>
    case Status.PENDING:
      return (
        <Container>
          <Text color="primary">{statusToReadable(Status.PENDING)}</Text>
          <Spinner size="small" />
        </Container>
      )
    default:
      logger.error(`Unknown status ${status}`)
      return <Text color="error">Unknown</Text>
  }
}
```

### Smart Component with Data Fetching

**Conceptual Structure:**
```typescript
// Abstract concept - not framework-specific
export const ProjectParseDataList = (props: {
  projectId: string
  uniqueId?: string
  ownerId: string
}) => {
  const { projectId, uniqueId, ownerId } = props

  // Fetch data using data fetching library
  const { data, isLoading, isError } = useFetchData({
    fetchFn: async () => {
      return repository.query({
        variables: { ownerId, projectId, filter: { uniqueId } }
      })
    },
    cacheKey: ['parseDatas', ownerId, projectId, uniqueId],
  })

  const parseDatas = data?.items ?? []

  // Mutation for actions
  const { mutate, isPending } = useMutation({
    mutationFn: async (params: { commit: string; projectId: string }) => {
      return repository.create(params)
    },
    onError: (err) => showError(err),
    onSuccess: () => showSuccess('Parse started'),
  })

  const handleParseData = () => {
    if (!uniqueId) {
      showError('Missing unique id')
      return
    }
    mutate({ commit: uniqueId, projectId })
  }

  // Loading and error states
  if (isLoading) return <SkeletonTable columns={3} />
  if (isError) return <ErrorTable columns={3} />

  // Render data
  return (
    <Table>
      <TableHead>
        <Row>
          <Cell>Unique ID</Cell>
          <Cell>Status</Cell>
          <Cell>Action</Cell>
        </Row>
      </TableHead>
      <TableBody>
        {parseDatas.length === 0 ? (
          <NoDataRow columns={3}>
            <Button onClick={handleParseData} disabled={isPending}>
              Parse Data
            </Button>
          </NoDataRow>
        ) : (
          parseDatas.map((item) => (
            <Row key={item.id}>
              <Cell>{item.uniqueId}</Cell>
              <Cell><ProjectParseDataStatus status={item.status} /></Cell>
              <Cell><Button disabled={isPending}>PUML</Button></Cell>
            </Row>
          ))
        )}
      </TableBody>
    </Table>
  )
}
```

### Form Input Component with Ref

**Conceptual Structure:**
```typescript
// Abstract concept - not framework-specific
export interface CommitSelectInputRef {
  getSelectedValue: () => string
}

export const CommitSelectInput = forwardRef<CommitSelectInputRef, {
  projectId: string
  onChange?: (commit?: string) => void
}>((props, ref) => {
  const { projectId, onChange } = props

  // Fetch data
  const { data: commits, isLoading, isError, error, refetch } = useFetchData({
    fetchFn: async () => repository.getCommits({ projectId }),
    cacheKey: ['commits', projectId],
    staleTime: 7200000, // 2 hours
  })

  const [selectedCommit, setSelectedCommit] = useState('')

  const getCommitHash = (value: string): string => {
    const [commitHash] = value.split('|')
    return commitHash
  }

  const handleChange = (value: string) => {
    setSelectedCommit(value)
    onChange?.(getCommitHash(value))
  }

  // Expose methods via ref
  useImperativeHandle(ref, () => ({
    getSelectedValue: () => getCommitHash(selectedCommit),
  }))

  // Loading and error states
  if (isLoading) return <Skeleton height={56} />
  if (isError) return <Alert severity="error">{error.message}</Alert>

  // Render select input
  return (
    <Container>
      <Select
        label="Commit"
        value={selectedCommit}
        onChange={handleChange}
        options={commits?.map((commit, ix) => ({
          key: ix,
          value: `${commit.hash}|${commit.name}`,
          label: `${commit.type}: ${commit.name}`,
        }))}
      />
      <IconButton onClick={refetch} tooltip="Refresh">
        <RefreshIcon />
      </IconButton>
    </Container>
  )
})
```

## Key Characteristics

- **Reusable**: Can be used in multiple screens/contexts
- **Props-driven**: All external data comes through props (no router dependencies)
- **Data fetching**: Can use data fetching libraries (React Query, SWR, Apollo, etc.)
- **Local state**: Manages UI state (form inputs, modals, tabs, etc.)
- **Event handlers**: Handles user interactions and calls callbacks
- **Loading states**: Shows skeletons, spinners while loading
- **Error handling**: Displays error messages gracefully
- **Composable**: Can contain other UI components
- **Styled**: Uses component libraries (Material-UI, Ant Design, Chakra, etc.)

## Component Categories

1. **Presentational Components**: Pure components that only render based on props (no data fetching)
2. **Smart Components**: Components that fetch data and manage state
3. **Form Components**: Components that handle form inputs and validation
4. **Layout Components**: Components that structure other components

## Architectural Rules

### ✅ DO

- Accept all data as props (never use routing hooks)
- Fetch data using data fetching libraries
- Manage local UI state with state management hooks
- Use TypeScript interfaces for props
- Handle loading and error states
- Use component libraries for consistent styling
- Compose smaller components into larger ones
- Use ref forwarding when exposing methods
- Use callback props for user interactions
- Keep components focused on single responsibility
- Use custom hooks for reusable logic
- Log errors using logger utilities

### ❌ DON'T

- Use routing hooks (keep components router-agnostic)
- Access URL parameters or query strings directly
- Include routing logic
- Hardcode API endpoints (use repository layer)
- Access DAL or entities directly
- Use console.log (use logger instead)
- Make components too generic (prefer specific, clear naming)
- Create god components (split into smaller pieces)
- Put business logic in components (use services/use-cases)

## Component Categories

### 1. Presentational Components
Pure components that only render based on props (no data fetching).

```typescript
export const UserAvatar = (props: { name: string; imageUrl?: string }): React.ReactElement => {
  // Pure rendering logic
}
```

### 2. Smart Components
Components that fetch data and manage state.

```typescript
export const ProjectList = (props: { ownerId: string }): React.ReactElement => {
  const { data, isLoading } = useQuery(...)
  // Data fetching + rendering
}
```

### 3. Form Components
Components that handle form inputs and validation.

```typescript
export const ProjectCreateForm = (props: {
  onSubmit: (data: ProjectData) => void
}): React.ReactElement => {
  // Form state + validation + submission
}
```

### 4. Layout Components
Components that structure other components.

```typescript
export const DashboardLayout = (props: {
  children: React.ReactNode
}): React.ReactElement => {
  // Layout structure
}
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

### Subscription/Real-time Updates

```typescript
export const LiveDataComponent = (props: { projectId: string }): React.ReactElement => {
  const { projectId } = props
  const { data, refetch } = useQuery(...)

  useEffect(() => {
    const subscription = gqlRepo()
      .watchQuery({ query: WatchDocument, variables: { projectId } })
      .subscribe({
        next: () => refetch(),
        error: (err) => logger().error(err),
      })

    return () => subscription.unsubscribe()
  }, [projectId])

  return <div>{/* Render data */}</div>
}
```

## Relationship with Other Layers

- **Screen** → **UI Component**
  - Screen extracts routing data
  - Passes clean props to component
  - Component remains router-agnostic

- **UI Component** → **Repository**
  - Component fetches data via repositories
  - Uses React Query for caching/state
  - Never accesses DAL/entities directly

- **UI Component** → **Service/Use Case**
  - Component calls services for business logic
  - Keeps presentation logic separate from business logic

This separation ensures components are testable, reusable, and maintainable across different routing implementations and application contexts.
