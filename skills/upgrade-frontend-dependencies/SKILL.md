---
name: upgrade-frontend-dependencies
description: Automate monthly frontend dependency upgrades — bumps minor/patch versions, evaluates major upgrades via changelogs, runs checks, and creates a draft PR
user-invocable: true
---

Automate the monthly frontend dependency upgrade process. This skill upgrades minor/patch versions, evaluates major upgrades by reviewing changelogs, runs verification checks, and creates a draft PR with full details for manual testing.

All `npm` commands MUST be run from `frontend/`, never from the project root.

## Step 1: Audit dependencies

Run these in parallel:

```bash
cd frontend && npm outdated --json 2>/dev/null || echo "{}"
```

Read `frontend/package.json` to identify:

- **Pinned packages**: exact versions with no `^` or `~` prefix (e.g., `"10.2.19"`, `"8.5.8"`, `"7.10.1"`)
- **URL-based packages**: versions that are URLs (e.g., `xlsx` pointing to a CDN) — always skip these
- **Documented pins**: check the `dependenciesComments` field in package.json for documented reasons why a package is pinned

Categorize every outdated package into one of:
1. **Minor/patch upgrade** — same major version, newer minor or patch available
2. **Major upgrade** — newer major version available
3. **Pinned/skipped** — exact version, URL-based, or documented pin reason

**Important**: A package can appear in BOTH the minor/patch and major lists. If a package has a minor/patch update within the current major AND a new major version available, apply the minor/patch bump in Step 2 and evaluate the major upgrade in Step 3. For example, `@mantine/core: ^8.3.17` with wanted `8.3.18` and latest `9.0.1` should get the `8.3.18` bump first, then be evaluated for the `9.x` major upgrade.

### Package grouping

Group related packages by family prefix. All packages in a group MUST be upgraded together to avoid version mismatches. If any package in a group cannot be upgraded, skip the entire group.

Known groups:
- `@mantine/*` and `mantine-react-table-open` (third-party but tightly coupled to Mantine)
- `@tiptap/*`
- `@storybook/*`, `storybook`, and `eslint-plugin-storybook`
- `@tanstack/*`
- `@testing-library/*`
- `@typescript-eslint/*`
- `eslint-*` (eslint plugins and configs, but NOT `eslint` itself and NOT `eslint-plugin-storybook` which belongs to the storybook group)
- `@sentry/*`
- `@xyflow/*`
- `i18next` and `react-i18next` (always upgrade together)
- `vitest` and `@vitest/*` (always upgrade together)
- `react` and `react-dom` (always upgrade together)
- `@types/react` and `@types/react-dom` (always upgrade together)

Packages not in a known group are upgraded individually.

### Present audit results

Before proceeding, present the categorized list to the user in this format:

```
## Dependency Audit Results

### Minor/Patch Upgrades (will be applied)
- package-name: ^1.2.3 → ^1.3.0
- @mantine/* (group): ^8.3.17 → ^8.5.2

### Major Upgrades (will be evaluated)
- some-package: ^2.1.0 → ^3.0.0

### Pinned/Skipped
- openapi-typescript: 7.10.1 (pinned — enum flag broken, see dependenciesComments)
- xlsx: URL-based, skipped
```

Wait for the user to confirm before proceeding. The user may ask to skip or include specific packages.

## Step 2: Apply minor and patch upgrades

1. For each non-pinned package (or package group) with a minor/patch update:
   - Edit `frontend/package.json` to update the version number
   - Preserve the existing prefix (`^` or `~`)
   - For grouped packages, update all packages in the group to their respective latest minor/patch versions
2. Run `npm install` from `frontend/` to update the lock file
3. Report what was upgraded

## Step 3: Evaluate and apply major upgrades

For each package (or package group) with a major version bump:

### 3a: Research breaking changes

For each package, research breaking changes using the GitHub API (avoids WebFetch permission prompts):

1. Get the GitHub repo: `npm view <pkg> repository.url` → extract `{owner}/{repo}` by stripping the `git+https://github.com/` prefix and `.git` suffix
2. Fetch recent releases: `gh api repos/{owner}/{repo}/releases --jq '.[0:5] | .[] | "TAG: " + .tag_name + "\nBODY: " + .body + "\n---"'`
3. If the releases are empty or unhelpful, try: `gh api repos/{owner}/{repo}/contents/CHANGELOG.md --jq '.content' | base64 -d | head -200`

Focus on breaking changes between the current major version and the latest major version.

### 3b: Decide whether to upgrade

Apply this decision matrix:

| Scenario | Action |
|----------|--------|
| No relevant breaking changes for how we use the package | Upgrade. Note in PR that no breaking changes affect us. |
| Small breaking changes (< 5 files, mechanical fixes like renames) | Upgrade. Apply the necessary code changes. Note what changed and why. |
| Large breaking changes (5+ files, or non-trivial logic changes) | Skip. Record the package, reason, and changelog URL for the PR description. Flag as "recommended for separate PR". |

The goal is to keep this PR low-risk and easy to review. Major upgrades requiring significant code changes are better handled in dedicated PRs where the diff is focused and rollback is straightforward.

**Important**: If a package in a group can't be upgraded, skip the entire group.

### 3c: Apply decided upgrades

1. Edit `frontend/package.json` for packages decided to upgrade
2. Apply any necessary code changes for breaking changes
3. Run `npm install` from `frontend/`

## Step 4: Verify

Run these sequentially from `frontend/`:

1. **ESLint**: `npm run eslint`
   - If there are lint errors caused by the upgrades, fix them
2. **TypeScript**: `npm run typescript`
   - If there are type errors caused by the upgrades, fix them
3. **Tests**: `npm run test:ci`
   - All tests must pass

If errors from a specific upgrade cannot be reasonably fixed:
- Revert that upgrade (or its entire group if grouped)
- Move it to the "not upgraded" list
- Re-run `npm install` and re-verify

## Step 5: Commit and push

1. Create a new branch from `develop`:
   ```bash
   git checkout -b chore/upgrade-frontend-deps-YYYY-MM develop
   ```
   Use the current year and month (e.g., `chore/upgrade-frontend-deps-2026-04`).

2. Stage all changed files:
   - `frontend/package.json`
   - `frontend/package-lock.json`
   - Any source files changed for major upgrade compatibility

3. Commit:
   ```bash
   git commit -m "chore: upgrade frontend dependencies (Month YYYY)"
   ```

4. Push:
   ```bash
   git push -u origin HEAD
   ```

## Step 6: Create draft PR

Invoke `/draft-pr` to create a draft pull request. The PR description MUST include these additional sections beyond the standard template:

### Upgraded (major) section

List every major version upgrade that was applied:

```markdown
### Major version upgrades

| Package | Old | New | Notes |
|---------|-----|-----|-------|
| @mantine/* | ^8.3.17 | ^9.0.0 | Renamed `foo` prop to `bar` in Button |
| some-lib | ^2.1.0 | ^3.0.0 | No breaking changes relevant to our usage |
```

### Not upgraded section

List every package that was NOT upgraded, with reasons and links:

```markdown
### Not upgraded

| Package | Current | Latest | Reason | Separate PR? | Changelog |
|---------|---------|--------|--------|:---:|-----------|
| big-lib | ^2.1.0 | ^4.0.0 | Major rewrite of core API, requires significant refactor | Yes | [Releases](https://github.com/org/big-lib/releases) |
| openapi-typescript | 7.10.1 | 7.12.0 | Pinned (enum flag broken) | No | [Issue](https://github.com/openapi-ts/openapi-typescript/issues/1872) |
| xlsx | 0.20.3 | 0.20.5 | URL-based dependency, manually managed | No | — |
```

### Manual testing note

Add at the end of the PR body:

```markdown
> **Note:** This PR requires manual testing before merging. Please verify that the application works correctly in the browser, especially features related to upgraded packages.
```

## Recommended permissions

For a low-friction experience, add these to your `settings.json` `permissions.allow` array:

```json
"Bash(npm install:*)",
"Bash(npm run:*)",
"Bash(npm view:*)",
"Bash(npm info:*)",
"Bash(gh api:*)",
"Bash(gh pr:*)",
"Bash(git log:*)",
"Bash(git fetch:*)",
"Bash(git checkout:*)",
"Bash(git add:*)",
"Bash(git commit:*)",
"Bash(git push:*)"
```

Without these, you'll be prompted for each command during execution.

## Important rules

- NEVER upgrade pinned packages (exact versions or URL-based) without explicit user approval
- NEVER skip `npm install` — the lock file must always be updated
- NEVER force-push, rebase, or amend commits
- NEVER skip git hooks
- If `npm install` fails due to peer dependency conflicts, report the conflict and ask the user how to proceed
- Always run all three verification steps (eslint, typescript, tests) before committing
- Always present the audit results and wait for user confirmation before making changes
- **Minor/patch versions can contain breaking changes too.** If a minor/patch upgrade introduces new lint errors, type errors, or test failures that affect many files and aren't straightforward to fix, pin that package at its current exact version instead. Add a comment to `dependenciesComments` explaining why, and list it in the "Not upgraded" section of the PR. ESLint plugins are especially prone to this — stricter rule enforcement in a patch release is effectively a breaking change.
- When verifying eslint, compare the error count against a clean run on the base branch (with proper `npm install` after switching) to distinguish pre-existing errors from upgrade-introduced ones. Do NOT rely on `git stash` alone — `node_modules` may still contain upgraded packages.
