# Agent Skills

A collection of agent skills for Claude Code that encode team conventions, automate migrations, and standardize testing across a Django + React stack.

## Reference & Standards

These skills provide project conventions and coding standards so Claude follows team practices without being told each time.

- **backend-project-reference** — Django, DRF, Celery, and infrastructure conventions: app organization, logging, API schemas, settings, task processing, feature flags, and development commands.
- **frontend-project-reference** — Frontend conventions, development commands, directory rules, git workflows, and environment setup for the React frontend.
- **frontend-coding-standards** — TypeScript, ESLint, Prettier, and general code quality: `Array<T>` syntax, JSX prop sorting, Mantine props, naming conventions, and validation commands.

## Testing

These skills standardize how tests are written and ensure a user-centric, TDD-oriented approach.

- **backend-testing** — Backend testing conventions for pytest-django: test commands, factory-based test data, and best practices.
- **frontend-testing** — Frontend testing best practices including vitest, Storybook stories, and user-centric testing approach.
- **frontend-storybook-testing** — Storybook canvas usage patterns, query priority guidelines, and interaction test organization.
- **e2e-test** — Write a Playwright E2E test (Python) for a given workflow, including research, planning, page objects, fixtures, and verification steps.
- **tdd-fix** — Fix a bug using TDD: write a failing test first, then iterate on the fix until all tests pass.

## Refactoring & Migration

These skills automate complex, multi-step migrations between legacy and modern patterns.

- **wizard-refactor** — Migrate a ComponentEditWizard to the VariantObjectWizard pattern, including architecture migration, field type mappings, and constants file creation.
- **dynamic-form-refactor** — Migrate a form from OptionsForm/DynamicForm to react-hook-form + FormFieldController, with field metadata extraction from Django serializers and a TDD story approach.
- **dead-code-cleanup** — Find and clean up dead code remaining after file deletions: broken imports, unused references, and orphaned CSS classes.

## Tooling & Workflow

These skills handle common development workflow tasks.

- **worktree** — Spawn a git worktree for a branch with full dev environment setup (backend + frontend deps).
- **draft-pr** — Create a draft pull request against develop with the team's PR template, Jira linking, Storybook story discovery, and checklist automation.
