#!/usr/bin/env bash
set -euo pipefail

# Usage: worktree-remove.sh <branch-name>
# Removes the git worktree for the given branch and optionally deletes the branch.

if [[ $# -lt 1 ]]; then
    echo "Usage: worktree-remove.sh <branch-name>"
    exit 1
fi

BRANCH="$1"

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

# Offer to delete the local branch
if git show-ref --verify --quiet "refs/heads/$BRANCH"; then
    read -rp "Delete local branch '$BRANCH'? [y/N] " answer
    if [[ "${answer,,}" == "y" ]]; then
        git branch -d "$BRANCH" 2>/dev/null || {
            echo "Branch has unmerged changes."
            read -rp "Force delete? [y/N] " force_answer
            if [[ "${force_answer,,}" == "y" ]]; then
                git branch -D "$BRANCH"
                echo "Branch '$BRANCH' force deleted."
            else
                echo "Branch kept."
            fi
        }
    else
        echo "Branch '$BRANCH' kept."
    fi
fi

echo "Done."
