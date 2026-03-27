---
name: frontend-coding-standards
description: Coding standards for TypeScript, ESLint, Prettier, and general code quality — Array<T> syntax, JSX prop sorting, Mantine props, naming conventions, validation commands
---

# Coding Standards

## TypeScript

- Prefer explicit types over `any`
- **Always use `Array<T>` syntax** instead of `T[]`:

```typescript
// Correct
Array<string>
Array<User>

// Incorrect
string[]
User[]
```

## ESLint

- **Always follow all ESLint rules** defined in `eslint.config.mjs` — no disabling rules or ignoring warnings
- Fix violations immediately rather than suppressing them
- **Sort JSX props alphabetically** (callbacks last, case-insensitive):

```typescript
// Correct
<Component
  data={data}
  disabled={false}
  title="Example"
  onClick={handler}
/>

// Incorrect
<Component
  onClick={handler}
  data={data}
  title="Example"
  disabled={false}
/>
```

## Code Formatting

- **Always format code with Prettier** using the project's configuration

## Function Naming

**Prefer descriptive function names over superfluous comments.** Use comments only for complex business logic or when the "why" isn't clear:

```typescript
// Good - descriptive name, no comment needed
function getVisibleTabsBasedOnPersonConditions() { ... }

// Good - comment explains business rule "why"
function calculateTaxRate() {
  // Use reduced rate for solar contractors per § 6 EEG regulation
  return isSolarContractor ? BASE_RATE * 0.8 : BASE_RATE;
}
```

## Mantine Component Props

**Prefer Mantine's built-in style props over the `style` prop:**

```typescript
// Correct
<Stack miw={0} w="80%" mt="md" />

// Incorrect
<Stack style={{ minWidth: 0, width: "80%", marginTop: "var(--mantine-spacing-md)" }} />
```

Common props: `w`, `h`, `miw`, `mih`, `maw`, `mah`, `m`, `mt`, `mb`, `ml`, `mr`, `mx`, `my`, `p`, `pt`, `pb`, `pl`, `pr`, `px`, `py`, `bg`, `c`, `fz`, `fw`, `lh`, `ta`.

## Utility Functions

- **Always add a JSDoc docstring** to exported utility functions explaining what the function does
- **Always create an accompanying test file** (e.g. `myUtil.test.ts`) for utility functions

## Character Handling

- Test syntax validity when working with non-ASCII characters

## Validation Commands

Run from `frontend/` directory:

```bash
npx prettier --check path/to/changed/file.tsx
npx eslint path/to/changed/file.tsx
npx tsc --noEmit  # Always run — type changes have cascading effects
```

When changing shared types or utilities, run `npx tsc --noEmit` and `npx eslint .`.
