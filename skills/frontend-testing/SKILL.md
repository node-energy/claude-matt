---
name: frontend-testing
description: Testing best practices for the frontend including vitest, storybook stories, and user-centric testing approach
---

# Testing Guidelines

## Test Commands

From the `frontend/` directory:

```bash
npx vitest run --project=storybook --reporter=tree app/components/Path/To/Component.stories.tsx
npx vitest run --project=storybook --reporter=tree app/components/Path/To/Component.stories.tsx -t "^Exact Story Name$"
npm run test:storybook  # All storybook tests
npm run test:unit       # Unit tests only
```

Or from project root:

```bash
just frontend-test
```

## Best Practices

- Always verify changes with tests when available
- Use factory-based test data for consistent, reliable tests
- Write tests that resemble how users interact with your code
- Check existing test patterns in similar components before writing new tests
