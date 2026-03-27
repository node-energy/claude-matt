---
name: backend-project-reference
description: Backend project conventions for Django, DRF, Celery, and infrastructure — app organization, logging, API schemas, settings, task processing, feature flags, and development commands
---

# Backend Project Reference

## Code Conventions

- Django apps follow domain boundaries (customers, invoicing, energy_data, etc.)
- Use `structlog` for structured logging, not standard logging
- Models use `django-timeseries` for time series data (energy measurements)
- API uses DRF with auto-generated OpenAPI schemas in `api_schema/`
- Multi-file settings in `optinode/webserver/config/settings/` — use `config()` helper for env vars
- Task processing via Celery with Redis
- Feature flags using django-waffle

## Development Commands

Use `just` command runner from **project root**:

```bash
just backend-server          # Django with auto-reload
just frontend-server         # React dev server (port 3000)
just backend-tests-fast      # Backend tests
just frontend-test           # Frontend tests
just backend-migrate         # Database migrations
just frontend-build-ts-types # Generate TS types from OpenAPI
just db-copy-backup-to-local # Restore staging data locally
```

## Directory Rules

| Directory | Commands |
|---|---|
| Project root (where `justfile` lives) | `just` commands, backend operations |
| `frontend/` | `npm`, `npx vitest`, storybook |

**Common mistakes:** Running `npm`/`npx` from project root (use `just frontend-*` instead), running `just` from `frontend/` (won't be found).

## Environment Setup

- **Python**: `uv` for dependency management
