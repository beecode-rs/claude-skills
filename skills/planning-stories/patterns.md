# Common Breakdown Patterns

Quick reference for how to break down common story types.

---

## Adding a New Field

**Story:** Add a new data field to an existing entity.

### Task Order

1. **Database** - Add column with migration
2. **Repository** - Update CRUD operations
3. **API** - Add/update endpoints
4. **Frontend** - Add UI components

### Example Breakdown

| Task | Layer | Key Changes |
|------|-------|-------------|
| Add column | database | Migration, default value, index if needed |
| Update repository | backend | Type definition, CRUD methods |
| Update API | api | Request/response types, validation |
| Add form field | frontend | Input component, validation |
| Display field | frontend | Display component, formatting |

### Verification Checklist

- [ ] Migration runs and rolls back
- [ ] Repository tests pass
- [ ] API returns new field
- [ ] Form saves new field
- [ ] Display shows new field

---

## Updating an Existing Field

**Story:** Change an existing field (rename, type change, constraints).

### Task Order (Breaking Change Strategy)

1. **Add parallel** - New field alongside old
2. **Update backend** - Write to both, read from new with fallback
3. **Update frontend** - Use new field
4. **Remove old** - Drop old field after migration complete

### Key Principle

**Never break the app during rollout.** Always maintain backward compatibility until frontend is fully migrated.

### Example: Field Rename

```
Task 1: Add `username` column (keep `userName`)
Task 2: Backend writes to both, reads from `username` with fallback
Task 3: Frontend uses `username`
Task 4: Drop `userName` column
```

### Verification Checklist

- [ ] App works at each step
- [ ] No downtime during deployment
- [ ] Old clients still work (if applicable)
- [ ] Final cleanup removes all old references

---

## Adding a New Entity

**Story:** Create a completely new data type (e.g., comments, tags, notifications).

### Task Order

1. **Database** - Create table with foreign keys
2. **Repository** - Full CRUD operations
3. **API** - REST endpoints
4. **Frontend List** - Display list view
5. **Frontend Detail** - Display/edit individual items

### Example Breakdown

| Task | Layer | Key Changes |
|------|-------|-------------|
| Create table | database | Table, foreign keys, indexes |
| Create repository | backend | Type, CRUD methods, joins |
| Create API endpoints | api | GET, POST, PATCH, DELETE |
| Add list view | frontend | List component, pagination |
| Add detail view | frontend | Detail component, edit form |

### Verification Checklist

- [ ] Table created with correct relationships
- [ ] Repository handles all CRUD operations
- [ ] API endpoints work with authentication
- [ ] List view displays all items
- [ ] Detail view allows create/edit/delete

---

## Adding a New Relationship

**Story:** Connect two existing entities (e.g., tasks to projects, users to teams).

### Task Order

1. **Database** - Add foreign key or junction table
2. **Repository** - Join queries, relationship methods
3. **API** - Include related data in responses
4. **Frontend** - Display relationship, add selectors

### Example: Many-to-Many Relationship

```
Task 1: Create junction table (task_tags)
Task 2: Add relationship methods to repositories
Task 3: API returns related entities, add link/unlink endpoints
Task 4: Frontend shows tags on task, allows adding/removing
```

### Verification Checklist

- [ ] Foreign key constraints work
- [ ] Join queries return correct data
- [ ] API includes related entities
- [ ] Frontend can manage relationships

---

## Bug Fix

**Story:** Fix incorrect behavior in existing code.

### Task Order

1. **Reproduce** - Create test that demonstrates the bug
2. **Fix** - Implement the fix
3. **Verify** - Ensure test passes and no regressions

### Example Breakdown

| Task | Description |
|------|-------------|
| Add failing test | Test that reproduces the bug |
| Implement fix | Change the code to fix behavior |
| Run all tests | Ensure no regressions |

### Verification Checklist

- [ ] Bug is reproducible with test
- [ ] Fix resolves the bug
- [ ] All existing tests still pass
- [ ] Edge cases handled

---

## Refactoring

**Story:** Improve code without changing behavior.

### Task Order

1. **Add tests** - Ensure existing behavior is captured
2. **Refactor** - Make changes incrementally
3. **Verify** - Tests still pass at each step

### Key Principle

**Refactor in small steps.** Each step should leave the code in a working state with all tests passing.

### Example: Extract Service from Controller

```
Task 1: Add integration tests for current behavior
Task 2: Create new service class
Task 3: Move logic to service (one method at a time)
Task 4: Update controller to use service
Task 5: Remove duplicated code
```

### Verification Checklist

- [ ] Tests capture existing behavior
- [ ] Each refactor step keeps tests green
- [ ] No behavior changes
- [ ] Code is cleaner/more maintainable

---

## Performance Optimization

**Story:** Improve performance of slow operation.

### Task Order

1. **Measure** - Add timing/metrics to identify bottleneck
2. **Optimize** - Make targeted improvements
3. **Verify** - Confirm improvement with measurements

### Example Breakdown

| Task | Description |
|------|-------------|
| Add profiling | Measure where time is spent |
| Add index | Database optimization |
| Add caching | Cache frequently accessed data |
| Optimize query | Reduce N+1 queries |
| Verify improvement | Compare before/after metrics |

### Verification Checklist

- [ ] Baseline metrics captured
- [ ] Bottleneck identified
- [ ] Optimization applied
- [ ] Improvement measured
- [ ] No functionality broken

---

## Quick Decision Matrix

| Story Type | First Task | Key Risk |
|------------|------------|----------|
| New field | Database migration | Missing default value |
| Update field | Add parallel field | Breaking change |
| New entity | Create table | Missing relationships |
| New relationship | Add foreign key | Circular dependency |
| Bug fix | Reproduce with test | Can't reproduce |
| Refactor | Add tests | Behavior change |
| Performance | Measure first | Optimizing wrong thing |
