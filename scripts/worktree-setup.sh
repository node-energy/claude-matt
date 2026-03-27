#!/usr/bin/env bash
set -euo pipefail

# Usage: worktree-setup.sh <branch-name>
# Creates a git worktree for the given branch with full dev environment setup.

if [[ $# -lt 1 ]]; then
    echo "Usage: worktree-setup.sh <branch-name>"
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

if [[ -d "$TARGET_DIR" ]]; then
    echo "Error: Directory already exists: $TARGET_DIR"
    echo "If this is a stale worktree, remove it with: git worktree remove '$TARGET_DIR'"
    exit 1
fi

echo "Fetching latest from origin..."
git fetch origin

# Determine if branch exists locally, on origin, or needs to be created
if git show-ref --verify --quiet "refs/heads/$BRANCH"; then
    echo "Using existing local branch: $BRANCH"
    git worktree add "$TARGET_DIR" "$BRANCH"
elif git show-ref --verify --quiet "refs/remotes/origin/$BRANCH"; then
    echo "Using existing remote branch: origin/$BRANCH"
    git worktree add "$TARGET_DIR" "$BRANCH"
else
    echo "Creating new branch '$BRANCH' from origin/develop..."
    git worktree add -b "$BRANCH" "$TARGET_DIR" origin/develop
fi

# Copy .env if it exists in the main worktree
if [[ -f "$MAIN_WORKTREE/.env" ]]; then
    cp "$MAIN_WORKTREE/.env" "$TARGET_DIR/.env"
    echo "Copied .env from main worktree"
else
    echo "Warning: No .env found in $MAIN_WORKTREE — skipping"
fi

# Install backend dependencies
echo "Installing backend dependencies (uv sync)..."
(cd "$TARGET_DIR" && uv sync)

# Install frontend dependencies
echo "Installing frontend dependencies (npm ci)..."
(cd "$TARGET_DIR/frontend" && npm ci)

echo ""
echo "Worktree ready at: $TARGET_DIR"
echo "Branch: $BRANCH"
echo ""
echo "Open it in VSCode with: code '$TARGET_DIR'"
