# Story Breakdown Examples

Detailed examples for different story types.

---

## Example 1: Adding a New Field

### Input Story

```
Add a priority field to tasks that can be high, medium, or low.
Users should be able to set priority when creating/editing tasks.
Tasks should display their priority visually.
```

### Output: STORY.task-priority.md

```markdown
# Story: Task Priority System

## Overview

Add priority levels (high/medium/low) to tasks so users can prioritize their work.

## Dependencies

- Tasks table exists
- Task edit form exists
- Task list view exists

---

## Tasks

### Task 1: Add priority column to database

**Layer:** database

**Description:**
Add a priority column to the tasks table with default value 'medium'.

**Changes:**
- Add `priority` column: ENUM('high', 'medium', 'low') DEFAULT 'medium'
- Create migration file
- Run migration

**Verification:**
- [ ] Migration file created in /migrations/
- [ ] Migration runs without errors
- [ ] Column exists in tasks table with correct type
- [ ] Default value is 'medium'
- [ ] Rollback migration works
- [ ] Typecheck passes
- [ ] All tests pass

---

### Task 2: Add priority to repository layer

**Layer:** backend

**Description:**
Update TaskRepository to handle priority field in create, update, and queries.

**Changes:**
- Update TaskRepository.create to accept priority
- Update TaskRepository.update to accept priority
- Add TaskRepository.findByPriority method
- Update Task type definition

**Verification:**
- [ ] Unit test: create with priority works
- [ ] Unit test: update priority works
- [ ] Unit test: findByPriority returns correct tasks
- [ ] Typecheck passes
- [ ] All tests pass
- [ ] App runs without errors

---

### Task 3: Add priority endpoints to API

**Layer:** api

**Description:**
Add API endpoints for priority operations.

**Changes:**
- PATCH /tasks/:id/priority - update task priority
- GET /tasks?priority=high - filter by priority

**Verification:**
- [ ] API test: PATCH updates priority
- [ ] API test: GET filters by priority
- [ ] Returns 400 for invalid priority value
- [ ] Typecheck passes
- [ ] All tests pass

---

### Task 4: Add priority UI to task form

**Layer:** frontend

**Description:**
Add priority selector to task create and edit forms.

**Changes:**
- Add PrioritySelect component
- Integrate into TaskCreateForm
- Integrate into TaskEditForm

**Verification:**
- [ ] Priority dropdown shows 3 options
- [ ] Default selection is 'medium'
- [ ] Selection is saved on form submit
- [ ] Component test passes
- [ ] Typecheck passes
- [ ] App runs without errors

---

### Task 5: Display priority on task cards

**Layer:** frontend

**Description:**
Show priority indicator on task cards in the list view.

**Changes:**
- Add PriorityBadge component
- Integrate into TaskCard component
- Add colors: red (high), yellow (medium), gray (low)

**Verification:**
- [ ] Badge displays on task cards
- [ ] Colors are correct for each priority
- [ ] Badge is visible without hover
- [ ] Component test passes
- [ ] Typecheck passes
- [ ] App runs without errors

---

## Completion Criteria

The story is complete when:

- [ ] All 5 tasks are verified complete
- [ ] User can set priority when creating a task
- [ ] User can change priority when editing a task
- [ ] Tasks display priority visually
- [ ] User can filter tasks by priority
- [ ] Typecheck passes
- [ ] All tests pass

## Rollback Plan

1. Revert frontend changes (Tasks 4-5)
2. Revert API changes (Task 3)
3. Revert repository changes (Task 2)
4. Run migration rollback (Task 1)

---

## Notes

- Priority field is optional - existing tasks will default to 'medium'
- No notifications for priority changes in this story
- Future: could add priority-based sorting
```

---

## Example 2: Breaking Change (Field Rename)

### Input Story

```
Rename the `userName` field to `username` throughout the app.
```

### Output: STORY.rename-username.md

```markdown
# Story: Rename userName to username

## Overview

Rename the `userName` field to `username` for consistency with API conventions.

## Dependencies

- Users table with `userName` column
- All API endpoints using `userName`
- Frontend displaying `userName`

---

## Tasks

### Task 1: Add parallel username field

**Layer:** database

**Description:**
Add new `username` column while keeping `userName` for backward compatibility.

**Changes:**
- Add `username` column with same type as `userName`
- Create migration to copy data from `userName` to `username`
- Update write operations to populate both fields

**Verification:**
- [ ] Migration runs successfully
- [ ] Both columns exist with same data
- [ ] New writes populate both columns
- [ ] Rollback works
- [ ] Typecheck passes
- [ ] All tests pass

---

### Task 2: Update backend to use username

**Layer:** backend

**Description:**
Update all backend code to read from `username` with `userName` fallback.

**Changes:**
- Update UserRepository to prefer `username`
- Add fallback logic for `userName`
- Update type definitions

**Verification:**
- [ ] Unit tests pass with new field
- [ ] Fallback to old field works
- [ ] Typecheck passes
- [ ] All tests pass

---

### Task 3: Update frontend to use username

**Layer:** frontend

**Description:**
Update all frontend code to use `username` from API.

**Changes:**
- Update API client types
- Update all components using userName
- Update forms and displays

**Verification:**
- [ ] All components render correctly
- [ ] Forms submit with correct field
- [ ] E2E tests pass
- [ ] Typecheck passes
- [ ] App runs without errors

---

### Task 4: Remove old userName field

**Layer:** cleanup

**Description:**
Remove the deprecated `userName` column after frontend is fully migrated.

**Changes:**
- Create migration to drop `userName` column
- Remove all references to `userName`
- Clean up fallback logic

**Verification:**
- [ ] Migration runs successfully
- [ ] No references to `userName` remain
- [ ] All tests pass
- [ ] App runs without errors
- [ ] E2E tests pass

---

## Completion Criteria

- [ ] All 4 tasks complete
- [ ] Field is consistently named `username` everywhere
- [ ] No breaking changes during rollout
- [ ] All tests pass

## Rollback Plan

1. Restore `userName` column from backup
2. Revert Task 4 migration
3. Revert frontend changes
4. Revert backend changes

---

## Notes

- This is a breaking change - must use parallel field strategy
- Deploy in order: Task 1 → Task 2 → Task 3 → Task 4
- Wait 1 day between Task 3 and Task 4 to catch any missed references
```

---

## Example 3: New Entity

### Input Story

```
Add a comments feature. Users should be able to comment on tasks.
Comments should show the author and timestamp.
```

### Output: STORY.task-comments.md

```markdown
# Story: Task Comments

## Overview

Allow users to add comments to tasks for discussion and updates.

## Dependencies

- Tasks table exists
- Users table exists
- Task detail view exists

---

## Tasks

### Task 1: Create comments table

**Layer:** database

**Description:**
Create a new comments table with foreign keys to tasks and users.

**Changes:**
- Create `comments` table with columns:
  - id (primary key)
  - task_id (foreign key to tasks)
  - user_id (foreign key to users)
  - content (text)
  - created_at (timestamp)
  - updated_at (timestamp)
- Add indexes on task_id and user_id

**Verification:**
- [ ] Migration runs successfully
- [ ] Table created with correct schema
- [ ] Foreign key constraints work
- [ ] Indexes exist
- [ ] Rollback works
- [ ] Typecheck passes
- [ ] All tests pass

---

### Task 2: Add comment repository

**Layer:** backend

**Description:**
Create CommentRepository with CRUD operations.

**Changes:**
- Create CommentRepository class
- Implement create, findByTaskId, update, delete methods
- Create Comment type definition
- Add user join for author info

**Verification:**
- [ ] Unit test: create comment works
- [ ] Unit test: findByTaskId returns comments with author
- [ ] Unit test: update comment works
- [ ] Unit test: delete comment works
- [ ] Typecheck passes
- [ ] All tests pass

---

### Task 3: Add comment API endpoints

**Layer:** api

**Description:**
Create REST endpoints for comment operations.

**Changes:**
- GET /tasks/:taskId/comments - list comments
- POST /tasks/:taskId/comments - create comment
- PATCH /comments/:id - update comment (author only)
- DELETE /comments/:id - delete comment (author only)

**Verification:**
- [ ] API test: GET returns comments with authors
- [ ] API test: POST creates comment
- [ ] API test: PATCH updates own comment
- [ ] API test: DELETE removes own comment
- [ ] Returns 403 for unauthorized updates/deletes
- [ ] Typecheck passes
- [ ] All tests pass

---

### Task 4: Add comment list to task detail

**Layer:** frontend

**Description:**
Display comments on the task detail page.

**Changes:**
- Create CommentList component
- Create CommentItem component showing author and timestamp
- Fetch and display comments on task detail page
- Add loading and empty states

**Verification:**
- [ ] Comments display on task detail
- [ ] Author name shows correctly
- [ ] Timestamp formatted correctly
- [ ] Loading state shows while fetching
- [ ] Empty state shows when no comments
- [ ] Component tests pass
- [ ] Typecheck passes
- [ ] App runs without errors

---

### Task 5: Add comment form

**Layer:** frontend

**Description:**
Allow users to create new comments.

**Changes:**
- Create CommentForm component
- Add textarea and submit button
- Handle submit and optimistic updates
- Show new comment immediately after submit

**Verification:**
- [ ] Form renders on task detail
- [ ] Submit creates comment via API
- [ ] New comment appears immediately
- [ ] Form clears after submit
- [ ] Error handling works
- [ ] Component tests pass
- [ ] Typecheck passes
- [ ] App runs without errors

---

## Completion Criteria

- [ ] All 5 tasks complete
- [ ] Users can view comments on tasks
- [ ] Users can add comments
- [ ] Comments show author and timestamp
- [ ] Users can edit their own comments
- [ ] Users can delete their own comments
- [ ] All tests pass

## Rollback Plan

1. Remove CommentForm component
2. Remove CommentList from task detail
3. Remove comment API endpoints
4. Remove CommentRepository
5. Drop comments table

---

## Notes

- Comments are not threaded in this story (future enhancement)
- No markdown support initially (future enhancement)
- No @mentions (future enhancement)
```
