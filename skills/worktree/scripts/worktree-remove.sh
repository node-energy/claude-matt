#!/usr/bin/env bash
set -euo pipefail

# Usage: worktree-remove.sh <branch-name> [--delete-branch]
# Removes the git worktree for the given branch.
# Pass --delete-branch to also delete the local branch after removal.

if [[ $# -lt 1 ]]; then
    echo "Usage: worktree-remove.sh <branch-name> [--delete-branch]"
    exit 1
fi

BRANCH="$1"
DELETE_BRANCH=false
if [[ "${2:-}" == "--delete-branch" ]]; then
    DELETE_BRANCH=true
fi

# Find the main worktree root (the original clone, not a worktree)
MAIN_WORKTREE="$(git worktree list --porcelain | head -1 | sed 's/^worktree //')"
REPO_NAME="$(basename "$MAIN_WORKTREE")"
PARENT_DIR="$(dirname "$MAIN_WORKTREE")"

# Sanitize branch name for directory (replace slashes with dashes)
DIR_SUFFIX="$(echo "$BRANCH" | tr '/' '-')"
TARGET_DIR="${PARENT_DIR}/${REPO_NAME}--${DIR_SUFFIX}"

if [[ ! -d "$TARGET_DIR" ]]; then
    echo "Error: Worktree directory not found: $TARGET_DIR"
    echo ""
    echo "Active worktrees:"
    git worktree list
    exit 1
fi

echo "Removing worktree at: $TARGET_DIR"
git worktree remove "$TARGET_DIR"
git worktree prune

# Nudge VS Code's git extension to refresh by touching a watched file
MAIN_GIT_DIR="$(git -C "$MAIN_WORKTREE" rev-parse --git-dir)"
touch "$MAIN_GIT_DIR/config"

echo "Worktree removed."

if [[ "$DELETE_BRANCH" == true ]] && git show-ref --verify --quiet "refs/heads/$BRANCH"; then
    git branch -d "$BRANCH" 2>/dev/null || {
        echo "Warning: Branch '$BRANCH' has unmerged changes. Use 'git branch -D $BRANCH' to force delete."
    }
    echo "Branch '$BRANCH' deleted."
fi

echo "Done."
