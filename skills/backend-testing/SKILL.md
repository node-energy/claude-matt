---
name: backend-testing
description: Backend testing conventions for pytest-django — test commands, factory-based test data, and best practices
---

# Backend Testing Guidelines

## Test Commands

```bash
# From project root
just backend-tests-fast
```

## Conventions

- Testing with pytest-django
- Factories in `tests/factories.py` within each app
- Use factory-based test data for consistent, reliable tests

## Best Practices

- Always verify changes with tests when available
- Write tests that resemble how users interact with your code
- Check existing test patterns in similar modules before writing new tests
