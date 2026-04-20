---
name: frontend-coding-standards
description: Frontend coding standards for the optinode repo — TypeScript (`Array<T>`), ESLint (JSX prop sorting), Prettier, Mantine style props, naming, and validation commands. Use whenever writing, editing, or reviewing any `.ts`/`.tsx` file in `frontend/`, before considering a file done, or when fixing lint/type errors.
---

# Coding Standards

## TypeScript

- Prefer explicit types over `any`
- Use `Array<T>` syntax instead of `T[]`. This is a team convention (not ESLint-enforced) that people forget easily — please apply it consistently:

```typescript
// Correct
Array<string>
Array<User>

// Incorrect
string[]
User[]
```

## ESLint

- Follow the ESLint rules in `eslint.config.mjs`. Don't disable rules or silence warnings — those configs exist for a reason, and suppressing them tends to hide real bugs. Fix violations rather than suppress them.
- Sort JSX props and destructured prop parameters alphabetically (callbacks last, case-insensitive). The `react/jsx-sort-props` rule auto-fixes JSX usage sites via `eslint --fix`; destructured parameters in the component signature are not auto-sorted, so apply this manually there:

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

- Formatting is handled automatically by the `format-frontend.sh` hook (`eslint --fix` + `prettier --write` on PostToolUse). No need to run these manually.

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

Common props, grouped:

- Sizing: `w`, `h`, `miw`, `mih`, `maw`, `mah`
- Margin: `m`, `mt`, `mb`, `ml`, `mr`, `mx`, `my`
- Padding: `p`, `pt`, `pb`, `pl`, `pr`, `px`, `py`
- Typography: `fz`, `fw`, `lh`, `ta`
- Color: `bg`, `c`

## Utility Functions

- Add a JSDoc docstring to exported utility functions — they're imported across the codebase and the docstring is what shows up in IDE hovers for callers
- Create an accompanying test file (e.g. `myUtil.test.ts`) for utility functions
- Test data factories (`createTest*` functions in test directories) are **not** considered utility functions and do not require their own test files

## Character Handling

- Test syntax validity when working with non-ASCII characters

## Validation Commands

ESLint and Prettier run automatically via the `format-frontend.sh` PostToolUse hook. Type checking is not hooked, so run it yourself from `frontend/`:

```bash
npx tsc --noEmit  # type changes have cascading effects across the codebase
```
