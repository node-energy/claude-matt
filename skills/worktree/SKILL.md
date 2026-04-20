---
name: worktree
description: Spawn a git worktree for a branch with full dev environment setup (backend + frontend deps)
user-invocable: true
argument-hint: "<branch-name> or remove <branch-name>"
---

# Worktree Management

Manage git worktrees with full dev environment setup. Supports two operations: **setup** (default) and **remove**.

## Setup a worktree

Parse the arguments to extract:
- **branch name** (required)
- **base branch** (optional — defaults to `origin/develop`)

Example arguments and how to interpret them:
- `feature/my-thing` → branch=`feature/my-thing`, base=default
- `feature/my-thing from origin/main` → branch=`feature/my-thing`, base=`origin/main`
- `feature/my-thing based on main` → branch=`feature/my-thing`, base=`origin/main` (add `origin/` if missing)

Run the setup script from the `scripts/` subdirectory next to this SKILL.md:

```
<this-skill-directory>/scripts/worktree-setup.sh <branch-name> [base-branch]
```

The script will:
1. Create a git worktree at a sibling directory (e.g., `../optinode_backend--<branch>`)
2. Use an existing branch or create a new one from the base branch
3. Copy `.env` from the main worktree
4. Install Python dependencies (`uv sync`)
5. Install frontend dependencies (`npm ci`)

## Remove a worktree

If the arguments start with "remove" or "clean up", this is a removal request.

Example arguments:
- `remove feature/my-thing`
- `clean up feature/my-thing`

Run the removal script:

```
<this-skill-directory>/scripts/worktree-remove.sh <branch-name> [--delete-branch]
```

Ask the user whether they also want to delete the local branch before running. Pass `--delete-branch` if they say yes.

If the user isn't sure which worktrees exist, run `git worktree list` first to show them.
