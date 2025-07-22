# How to Create Validation Files for /screen-tasks Command

The `/screen-tasks` command validates Jira tasks based on project-specific rules defined in validation files. This guide explains how to create and configure these validation files.

## File Location and Naming

Validation files must be placed in the `settings/` directory at the root of your project with the following naming convention:

```
settings/{PROJECT_HANDLE}_validation.json
```

For example:
- For project "GP": `settings/GP_validation.json`
- For project "MYAPP": `settings/MYAPP_validation.json`

## File Structure

The validation file is a JSON object where:
- **Keys** are Jira status names (exact match required)
- **Values** are arrays of validation rule names to apply

### Example Structure

```json
{
  "In Progress": ["comment_count_at_least_one", "description_not_empty"],
  "Design": ["original_estimate_not_empty"],
  "Verification": ["worklog_not_empty"]
}
```

## Available Validation Rules

### 1. `comment_count_at_least_one`
- **Purpose**: Ensures the task has at least one comment
- **Check**: `jira view {TASK_ID} --template=json | jq '.fields.comment.comments | length' > 0`
- **Pass**: Task has 1 or more comments
- **Fail**: Task has no comments

### 2. `description_not_empty`
- **Purpose**: Ensures the task has a description
- **Check**: `jira view {TASK_ID} --template=json | jq '.fields.description'`
- **Pass**: Description field is not null and not empty
- **Fail**: Description is null or empty string

### 3. `original_estimate_not_empty`
- **Purpose**: Ensures the task has an original time estimate
- **Check**: `jira view {TASK_ID} --template=json | jq '.fields.timetracking.originalEstimate'`
- **Pass**: Original estimate is set (e.g., "4h", "2d")
- **Fail**: No original estimate set

### 4. `worklog_not_empty`
- **Purpose**: Ensures work has been logged on the task
- **Check**: `jira worklog list {TASK_ID}`
- **Pass**: At least one worklog entry exists
- **Fail**: No worklog entries found

## How It Works

When you run `/screen-tasks GP`, the command:

1. Looks for `settings/GP_validation.json`
2. For each status in the file (e.g., "In Progress"), it finds tasks that:
   - Were previously in that status
   - Are no longer in that status or "Done"
3. Applies the specified validation rules to each task
4. Displays results in a color-coded table

## Complete Example

Let's say you want to ensure:
- Tasks in "In Progress" must have comments and descriptions
- Tasks in "Design" must have time estimates
- Tasks in "Verification" must have work logged

Create `settings/GP_validation.json`:

```json
{
  "In Progress": ["comment_count_at_least_one", "description_not_empty"],
  "Design": ["original_estimate_not_empty"],
  "Verification": ["worklog_not_empty"]
}
```

Running `/screen-tasks GP` will produce output like:

```
Status: In Progress
┌──────────┬────────────────────────────┬───────────────────────┐
│ Task ID  │ comment_count_at_least_one │ description_not_empty │
├──────────┼────────────────────────────┼───────────────────────┤
│ GP-3     │ ✗ No comments              │ ✗ Empty               │
│ GP-5     │ ✓ 2 comments               │ ✓ Has description     │
└──────────┴────────────────────────────┴───────────────────────┘

Status: Design
┌──────────┬─────────────────────────────┐
│ Task ID  │ original_estimate_not_empty │
├──────────┼─────────────────────────────┤
│ GP-19    │ ✓ 4h                        │
│ GP-20    │ ✗ Not set                   │
└──────────┴─────────────────────────────┘

Summary: 4 tasks validated | ✓ 3 passed | ✗ 3 failed
```

## Tips

1. **Status Names**: Must match exactly as they appear in Jira (case-sensitive)
2. **Multiple Projects**: Create separate validation files for each project
3. **Command Visibility**: The `/screen-tasks` command only appears when at least one validation file exists
4. **Custom Workflows**: Adapt validation rules to match your team's workflow requirements

## Troubleshooting

- **"Please create validation rules for this project"**: No validation file found for the specified project handle
- **No output**: No tasks have transitioned out of the specified statuses
- **Command not available**: No validation files exist in the `settings/` directory