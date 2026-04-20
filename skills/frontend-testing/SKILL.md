---
name: frontend-testing
description: Frontend testing conventions for vitest and Storybook interaction tests — test commands, canvas/query patterns, assertions, step organization, determinism, factory-based data, and where tests belong. Use whenever writing, fixing, or reviewing a `.test.ts(x)` or `.stories.tsx` file, debugging a failing frontend test, or deciding between a unit test and a storybook interaction test.
---

# Frontend Testing Guidelines

## Test Commands

From the `frontend/` directory:

```bash
npx vitest run --project=storybook --reporter=tree app/components/Path/To/Component.stories.tsx
npx vitest run --project=storybook --reporter=tree app/components/Path/To/Component.stories.tsx -t "^Exact Story Name$"
npm run test:storybook  # All storybook tests
npm run test:unit       # Unit tests only
```

Or from project root: `just frontend-test`.

## Factory-Based Test Data

Prefer existing test-data factories over hand-rolled object literals. They stay in sync with backend types and keep tests resilient to schema changes. In the optinode_backend repo these live in `frontend/app/utils/test/` (e.g. `createTestSite.ts`, `createTestUser.ts`). Other repos will have an analogous directory — look there first before inventing fixtures inline.

## Canvas Usage

Use `canvas` directly from the `play` function parameters. A recent Storybook update exposes it alongside `canvasElement`, so there's no need for `within(canvasElement)` anymore:

```typescript
play: async ({ canvas, step }) => {
  const button = await canvas.findByRole("button", { name: "Click me" });
}
```

## Query Priority

Tests should resemble how users interact with the UI. Prefer queries that reflect real user perception — this catches accessibility regressions as a side effect and avoids tests that pass while the UI is broken for real users.

### 1. Queries accessible to everyone
- `getByRole` with `name`: top preference — `getByRole('button', { name: /submit/i })`
- `getByLabelText`: form fields; users find inputs by their label
- `getByPlaceholderText`: only when placeholder is all you have (placeholder ≠ label)
- `getByText`: non-interactive elements (divs, spans, paragraphs)
- `getByDisplayValue`: form elements with filled-in values

### 2. Semantic queries
- `getByAltText`: images and elements that support alt text
- `getByTitle`: inconsistently surfaced by screenreaders; use sparingly

### 3. Test IDs (last resort)
- `getByTestId`: invisible to users. Only when role/text genuinely can't identify the element (e.g. purely dynamic content).

## Assertions

**Prefer `toBeVisible` over `toBeInTheDocument`** when you're asserting the user can see something. `toBeInTheDocument` passes for elements hidden via CSS, opacity, or offscreen positioning — which is usually not what you actually want to check.

**Always `await` expect calls.** Storybook's `expect` returns a promise; without `await`, a failing assertion can silently resolve as a passing test:

```typescript
// Correct
await expect(canvas.getByRole("heading", { name: "Title" })).toBeVisible();

// Incorrect — may not execute before the test ends
expect(canvas.getByRole("heading", { name: "Title" })).toBeVisible();
```

## Step Organization

Use the `step` function to break tests into logical sections instead of comments. Steps show up in the Storybook UI as collapsible blocks and give you precise failure locations:

```typescript
play: async ({ canvas, step }) => {
  await step("Check form renders correctly", async () => {
    await expect(canvas.getByRole("heading", { name: "Form Title" })).toBeVisible();
  });

  await step("Fill out form fields", async () => {
    await canvas.getByLabelText("Name").fill("John Doe");
    await canvas.getByLabelText("Email").fill("john@example.com");
  });

  await step("Submit form and verify success", async () => {
    await canvas.getByRole("button", { name: /submit/i }).click();
    await expect(canvas.getByText("Success!")).toBeVisible();
  });
};
```

## Determinism with Sorted/Randomized Data

When factories produce random values (e.g. faker dates) and a table sorts by default, query results come back in unpredictable order. Filter for the specific element — don't index into the array:

```typescript
// Fragile — buttons[0] depends on random sort order
const buttons = await canvas.findAllByRole("button", { name: "Submit" });
await userEvent.click(buttons[0]);

// Robust — identify the one you actually want
const buttons = await canvas.findAllByRole("button", { name: "Submit" });
const enabledButton = buttons.find((button) => !button.disabled);
await userEvent.click(enabledButton!);
```

## Test Placement: Component vs Page Stories

- **Pure rendering** assertions (disabled states, badge colors, element presence/absence) belong in the **component's own stories** with explicit `args`. No API mocking needed.
- **API integration** assertions (click triggers mutation, toast appears on success/error) belong in **page-level stories** with mocked endpoints. Component-level stories shouldn't care about network behavior.
