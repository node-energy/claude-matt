---
name: draft-pr
description: Create a draft pull request against develop with proper template. MUST be used whenever the user asks to create a PR, open a PR, draft a PR, or make a pull request.
argument-hint: "[TICKET-KEY | Jira URL | GitHub PR URL] [opti.node URL]"
---

Create a draft pull request against the `develop` branch following the team's PR template and conventions.

## Input

`$ARGUMENTS` may contain any combination of:
- A ticket key like `D2-1234` or `WUP-5678`
- A ticket key with description like `D2-1234: do something`
- A Jira URL like `https://node-energy.atlassian.net/browse/D2-1234`
- A GitHub PR URL like `https://github.com/node-energy/optinode_backend/pull/123`
- An opti.node URL for the "How to test it" section like `http://localhost:3000/some/path`

Parse all of these from `$ARGUMENTS`. A Jira URL implies the ticket key (extract it from the URL path). Multiple items may be provided separated by spaces.

## Step 1: Gather information

Run these in parallel to understand what will go into the PR:

```bash
git rev-parse --abbrev-ref HEAD
```
```bash
git log develop..HEAD --oneline
```
```bash
git diff develop...HEAD --stat
```
```bash
git diff develop...HEAD
```
```bash
git rev-parse --abbrev-ref @{upstream} 2>/dev/null || echo "no upstream"
```

If there are no commits ahead of `develop`, warn the user and stop. If there are uncommitted changes, warn the user but continue.

## Step 2: Parse arguments and extract ticket info

From `$ARGUMENTS`, extract:
- **Ticket key**: e.g., `D2-1234`, `WUP-5678`, `CoCo-9171`. If not provided explicitly, try to extract from the branch name (branches follow pattern `TICKET-KEY-description`, e.g., `D2-1234-fix-something`).
- **Jira URL**: if a `node-energy.atlassian.net` URL was provided, keep it. If only a ticket key is available, construct: `https://node-energy.atlassian.net/browse/TICKET-KEY`
- **GitHub PR URL**: if a `github.com/.../pull/N` URL was provided, extract the PR number.
- **opti.node URL**: any `localhost:3000` URL provided.

## Step 3: Find relevant Storybook stories

If the diff includes frontend changes (files under `frontend/app/`), find related Storybook stories:

1. Identify the changed component directories from the diff.
2. Look for `.stories.tsx` files in those directories or their parent directories.
3. Read the `title` field from each story file's `meta` object (e.g., `title: "Generic/DecimalLabel"`).
4. Convert the Storybook title to a URL path: lowercase everything, replace `/` with `-`, remove spaces. The first exported story name (often `Default`) becomes the story suffix. Example: title `"Generic/DecimalLabel"` with story `Default` becomes `http://localhost:6006/?path=/story/generic-decimallabel--default`.

If there are no frontend changes, skip this step.

## Step 4: Draft the PR title

Format: `TICKET-KEY: Short imperative description`

- Use the ticket key from Step 2.
- If `$ARGUMENTS` included a description after the ticket key (e.g., `D2-1234: do something`), use that as the description.
- Otherwise, write a concise imperative description summarizing the changes.
- If no ticket key was found at all, just write a descriptive title without a prefix.

## Step 5: Draft the PR body

Use this exact template structure. Replace all placeholder/italic instructional text with real content.

```
### Goals: why merge this PR?

{goal_text}

### Solution details

{solution_details}

### How to test it

{test_instructions}

### Anything in particular you want feedback on?



### Checklist

- [{ac_check}] All acceptance criteria of the ticket have been fulfilled
- [{test_check}] All code changes are covered by automated tests
- [ ] All slow tests have run successfully locally: `pytest -m "slow"`
- [ ] You have checked the desired behavior in the user interface (on a test cluster or your local machine)
- [{util_check}] [Used utility functions were moved, documented and tested](https://node-energy.atlassian.net/wiki/spaces/DEV/pages/1101824068/ADR+5+Util+Functionality)
```

### Goal text logic (pick ONE, in priority order):
1. If a Jira URL was provided or constructed: `closes [TICKET-KEY](jira_url)`
2. If a GitHub PR URL was provided: `follow up to #NUMBER`
3. Otherwise: analyze the changes and write an appropriate reason (e.g., "improves code quality", "fixes bug (describe bug)", "adds tests")

### Solution details:
- Write 2-4 concise sentences summarizing what was changed and why.
- Mention where the reviewer should start reviewing (which file/module is the main change).
- Explain what and why, not how. Do not repeat acceptance criteria.

### How to test it:
- If an opti.node URL was provided or is easily derivable: `- In opti.node: {url}`
- If Storybook stories were found: `- [In Storybook]({storybook_url})` for each relevant story
- If NONE of the above apply, leave this section commented out (as it is in the original template).

### Feedback section:
Leave blank (empty line after the heading). The developer will fill this in personally.

### Checklist logic:
- **Acceptance criteria**: Mark `[x]` only if a ticket was provided AND the changes clearly address the described work. Otherwise `[ ]`.
- **Automated tests**: Mark `[x]` only if new or modified test files exist in the diff. Otherwise `[ ]`.
- **Slow tests**: ALWAYS leave `[ ]`. Never check this automatically.
- **UI behavior**: ALWAYS leave `[ ]`. Never check this automatically.
- **Utility functions (ADR 5)**: Mark `[x]` if new utility functions were properly moved, documented, and tested, but not if no new utility functions were introduced. Mark `[ ]` if new utils exist and you cannot verify proper handling.

## Step 6: Present draft for review

Show the user the complete draft:
1. The proposed PR title
2. The full PR body (formatted as it will appear on GitHub)
3. The target branch (`develop`)

Then ask: "Does this look good? You can edit the title, body, or fill in the feedback section. Say **go** to create the PR, or tell me what to change."

Wait for the user's confirmation before proceeding. Apply any requested changes.

## Step 7: Create the PR

Once the user confirms:

1. Push the branch if it has no upstream:
   ```bash
   git push -u origin HEAD
   ```

2. Create the draft PR using `gh pr create`. Use a HEREDOC for the body to preserve formatting:
   ```bash
   gh pr create --draft --base develop --title "TITLE" --body "$(cat <<'EOF'
   BODY
   EOF
   )"
   ```

3. Report the PR URL back to the user.

## Important rules

- NEVER force-push, rebase, or modify any code files. This skill only creates PRs.
- NEVER skip git hooks or bypass signing.
- If `gh` is not authenticated, tell the user to run `gh auth login` first.
