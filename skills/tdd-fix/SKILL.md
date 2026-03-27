---
name: tdd-fix
description: Fix a bug using TDD — write a failing test first, then iterate on the fix until all tests pass
user_invocable: true
argument-hint: bug description
---

Fix a bug using test-driven development: $ARGUMENTS

## Step 1: Understand the bug

- Read the relevant code to understand the expected vs actual behavior
- Find existing tests for the affected module to understand test patterns and conventions

## Step 2: Write a failing test

- Write a test that reproduces the exact bug described above
- Place it alongside existing tests for the module, following the same patterns
- Run the test to confirm it **fails** for the right reason

## Step 3: Fix the bug

- Implement the minimal fix needed
- Run the failing test again to confirm it now **passes**
- If it still fails, iterate on the fix until it passes

## Step 4: Verify no regressions

- Run the full related test suite to ensure nothing else broke
- If any tests fail, fix regressions before continuing

Only present the solution once all tests are green.
