---
name: frontend-storybook-testing
description: Storybook testing best practices including canvas usage patterns, query priority guidelines, and interaction test organization
---

# Storybook Testing Guidelines

## Running Storybook

**Always check for existing Storybook instances** before starting a new one to avoid port conflicts:

```bash
# Check if Storybook is already running on port 6006
lsof -i :6006

# If already running, use the existing instance at http://localhost:6006
# If not running, start it with:
npm run storybook
```

**Prefer using existing instances** when Storybook is already running rather than killing and restarting processes. The existing instance is likely already loaded and ready to use.

## Canvas Usage

Always prefer using `canvas` directly from the `play` function parameters rather than `canvasElement` and `within(canvasElement)`. Since a recent Storybook update, `canvas` is available directly:

```typescript
// Preferred
play: async ({ canvas, step }) => {
  const button = await canvas.findByRole("button", { name: "Click me" });
}

```

## Query Priority

Tests should resemble how users interact with your code as much as possible. Use this order of priority for queries:

### 1. Queries Accessible to Everyone
Queries that reflect the experience of visual/mouse users as well as those that use assistive technology:
- `getByRole`: Query every element exposed in the accessibility tree. Use with the `name` option to filter by accessible name. This should be your top preference: `getByRole('button', {name: /submit/i})`
- `getByLabelText`: Excellent for form fields. Users find form elements using label text, so this emulates real behavior
- `getByPlaceholderText`: Use only when placeholder is all you have (placeholder is not a substitute for a label)
- `getByText`: For non-interactive elements (divs, spans, paragraphs). Main way users find text content outside of forms
- `getByDisplayValue`: For form elements with filled-in values

### 2. Semantic Queries
HTML5 and ARIA compliant selectors (note: user experience varies across browsers and assistive technology):
- `getByAltText`: For elements supporting alt text (img, area, input, custom elements)
- `getByTitle`: The title attribute is not consistently read by screenreaders and not visible by default

### 3. Test IDs (Last Resort)
- `getByTestId`: Users cannot see/hear these. Only use when you can't match by role/text or it doesn't make sense (e.g. dynamic text)

## Assertions

**Prefer `toBeVisible` over `toBeInTheDocument`** when asserting that users can see content. `toBeVisible` checks that the element is actually visible (not hidden via CSS, opacity, etc.), which better reflects the user's perspective. Use `toBeInTheDocument` only when you specifically need to assert presence in the DOM without visibility requirements.

**Always `await` expect calls.** Storybook's `expect` returns a promise, and omitting `await` can cause assertions to pass silently without actually running:

```typescript
// Correct
await expect(canvas.getByRole("heading", { name: "Title" })).toBeVisible();

// Incorrect — assertion may not execute
expect(canvas.getByRole("heading", { name: "Title" })).toBeVisible();
```

## Test Organization

Always prefer using `step` function to break up tests into logical sections rather than comments. This provides better test organization, clearer failure points, and improved debugging:

```typescript
// Preferred
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

## Test Determinism with Sorted Tables

When test data uses random values (e.g. faker dates) and the table sorts by default, element order in queries like `findAllByRole` is unpredictable. Always filter for the specific element you need rather than relying on array index:

```typescript
// Fragile — buttons[0] may be the wrong one depending on random sort order
const buttons = await canvas.findAllByRole("button", { name: "Submit" });
await userEvent.click(buttons[0]);

// Robust — find the specific element you need
const buttons = await canvas.findAllByRole("button", { name: "Submit" });
const enabledButton = buttons.find((button) => !button.disabled);
await userEvent.click(enabledButton!);
```

## Test Placement: Component vs Page Stories

- Tests that only assert on **component rendering** (disabled states, badge colors, element presence/absence) belong in the **component's own stories** with explicit `args` — no API mocking needed
- Tests that verify **API integration** (clicking a button triggers a mutation, toast appears on success/error) belong in **page-level stories** with mocked endpoints
