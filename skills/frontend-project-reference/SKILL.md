---
name: frontend-project-reference
description: Frontend project conventions, development commands, directory rules, git workflows, and environment setup for the opti.node React frontend
---

# Project Reference

## Code Conventions

- Components organized by feature in `app/components/` with co-located stories and tests
- Use Mantine components and design system
- API calls through centralized `api.ts` with automatic camelCase/snake_case conversion
- Forms use react-hook-form with validation
- TanStack Query for server state
- Multi-brand entry points (index.html, alva.html, roedl.html, wavelr.html) driven by `Site` enum

## Development Commands

From **`frontend/` directory** (your working directory):

```bash
npm run storybook       # Storybook server
npm run test:storybook  # All storybook tests
npm run test:unit       # Unit tests only
npx vitest run --project=storybook --reporter=tree app/components/Path/To/Component.stories.tsx
npx vitest run --project=storybook --reporter=tree app/components/Path/To/Component.stories.tsx -t "^Exact Story Name$"
```

Some commands must run from the **project root** (parent of `frontend/`):

```bash
just frontend-server         # React dev server (port 3000)
just frontend-test           # Frontend tests
just frontend-build-ts-types # Generate TS types from OpenAPI (requires api_schema/)
```

## Directory Rules

| Directory | Commands |
|---|---|
| `frontend/` (here) | `npm`, `npx vitest`, storybook |
| Project root (parent) | `just` commands |

**Common mistakes:** Running `npm`/`npx` from project root (use `just frontend-*` instead), running `just` from `frontend/` (won't be found).

## Git Workflows

**Always compare branches against `develop`** (staging), not `main`:

```bash
git diff develop...HEAD
git log develop..HEAD
```

## Environment Setup

- **Environment**: `direnv` for automatic env variable loading
- **Configuration**: `.env` files for local development
