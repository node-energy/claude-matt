---
name: dead-code-cleanup
description: Find and clean up dead code remaining after file deletions in the frontend codebase — searches for broken imports, unused references, and orphaned CSS classes
argument-hint: context about deletions
---

Find and clean up dead code remaining after file deletions in the frontend codebase. Context: $ARGUMENTS

## Process

### Step 1: Identify Deleted Files
Run `git status` to find deleted files in `frontend/`. Look for entries marked as deleted (D) or staged deletions.

### Step 2: Extract Identifiers
From each deleted file path, extract:
- **Component names**: `DeletedComponent` from `DeletedComponent.tsx`
- **Directory names**: `DeletedFeature` from `components/DeletedFeature/`
- **Utility names**: `deletedUtil` from `utils/deletedUtil.ts`
- **CSS class prefixes**: `.DeletedComponent` from `DeletedComponent.scss`

### Step 3: Search for References

**Import patterns** (search `*.ts`, `*.tsx`, `*.js`, `*.jsx`):
- `from ['"].*DeletedComponent['"]`
- `import.*DeletedComponent`

**Usage patterns**:
- `DeletedComponent` (JSX or function calls)
- `\.deletedFunction\s*\(`

**CSS patterns** (search `*.css`, `*.scss`):
- `\.DeletedComponent`
- `className.*DeletedComponent`

**File search** for related files:
- `**/*DeletedName*` (co-located stories, tests, type files)

### Step 4: Categorize and Fix

**Safe to auto-fix** — remove immediately:
- Unused imports from deleted files
- Unused variables that referenced deleted code

**Needs manual review** — flag for the user:
- Component references in JSX (what replaces them?)
- Function calls to deleted utilities
- Configuration references (package.json, tsconfig.json, vite.config.ts, .storybook/ configs)

## Detection Scope

Search for dead references in:
- **TS/JS files**: imports, component refs, function calls, type usage
- **Config files**: package.json, tsconfig.json, vite.config.ts, eslint.config.mjs, .storybook/
- **Style files**: @import statements, class name references
- **Other**: .md documentation links, test files

## Search Patterns Reference

| What to find | Pattern |
|---|---|
| Import statements | `from ['"].*DeletedName.*['"]` |
| Named imports | `import.*\{.*DeletedName.*\}` |
| JSX/function usage | `DeletedName\s*[<({]` |
| CSS classes | `\.DeletedClass\b` |

## Actions

1. Auto-fix all unused imports (safe removals)
2. Report component references and function calls that need manual decisions
3. Clean up object properties and array entries referencing deleted code
4. After cleanup, run `npx tsc --noEmit` and `npx eslint .` from `frontend/` to verify
