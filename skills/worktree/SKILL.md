---
name: worktree
description: Spawn a git worktree for a branch with full dev environment setup (backend + frontend deps)
user-invocable: true
argument-hint: "<branch-name>"
---

# Worktree Setup

Run the worktree setup script with the provided branch name:

```
~/.claude/scripts/worktree-setup.sh $ARGUMENTS
```

This will:
1. Create a git worktree at a sibling directory (e.g., `../optinode_backend--<branch>`)
2. Use an existing branch or create a new one from `origin/develop`
3. Copy `.env` from the main worktree
4. Install Python dependencies (`uv sync`)
5. Install frontend dependencies (`npm ci`)

Report the result to the user. If successful, remind them they can open the worktree in VSCode with the path printed by the script.
