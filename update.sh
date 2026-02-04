#!/bin/bash

# 🦞 OpenClaw Auto-Updater for Coolify
# ------------------------------------
# Usage: ./update.sh [channel]
# Channels: stable (default), beta, dev

set -e

CHANNEL="${1:-stable}"
REMOTE_NAME="upstream"
UPSTREAM_URL="https://github.com/openclaw/openclaw.git"

echo "🦞 OpenClaw Updater"
echo "-------------------"
echo "📡 Channel: $CHANNEL"

# 1. Setup Remote
if [ ! -d ".git" ]; then
    echo "❌ Error: Not a git repository."
    exit 1
fi

if ! git remote | grep -q "^${REMOTE_NAME}$"; then
    echo "🔹 Configuring upstream remote..."
    git remote add $REMOTE_NAME $UPSTREAM_URL
fi

# 2. Fetch Latest
echo "🔹 Fetching tags from $UPSTREAM_URL..."
git fetch $REMOTE_NAME --tags --force --quiet || { echo "❌ Network error: Could not fetch from upstream."; exit 1; }

# 3. Determine Version
TARGET_TAG=""

if [ "$CHANNEL" == "dev" ]; then
    # Dev = Latest commit on main
    echo "🔹 targeted: latest main (dev)"
    TARGET_TAG="$REMOTE_NAME/main"
    git fetch $REMOTE_NAME main --quiet
elif [ "$CHANNEL" == "beta" ]; then
    # Beta = Latest tag containing 'beta'
    TARGET_TAG=$(git tag -l "v*" | grep "beta" | sort -V | tail -n 1)
else
    # Stable = Latest tag NOT containing prerelease keywords (supports -patch versions like v2026.1.1-1)
    TARGET_TAG=$(git tag -l "v*" | grep -v -E "(beta|alpha|dev|rc|test)" | sort -V | tail -n 1)
fi

if [ -z "$TARGET_TAG" ]; then
    echo "❌ Error: Could not find a suitable version for channel '$CHANNEL'."
    exit 1
fi

CURRENT_VERSION=$(git describe --tags --abbrev=0 2>/dev/null || git rev-parse --short HEAD)
echo "ℹ️  Current: $CURRENT_VERSION"
echo "ℹ️  Target:  $TARGET_TAG"

if [ "$CURRENT_VERSION" == "$TARGET_TAG" ]; then
    echo "✅ You are already up to date."
    # Optional: Allow force update? For now, exit.
    exit 0
fi

# 4. Confirm & Install
echo
read -p "❓ Update to $TARGET_TAG? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Update cancelled."
    exit 1
fi

echo "🚀 Starting update..."

# Stash local changes
if [[ -n $(git status -s) ]]; then
    echo "📦 Stashing local changes..."
    git stash push -m "Auto-update stash $(date)"
fi

# Merge
echo "🔹 Merging..."
# Attempt merge without committing so we can fix files
git merge "$TARGET_TAG" --no-edit --allow-unrelated-histories --no-commit -X theirs || true

echo "🔧 Preserving local configurations..."
# Force restore our critical files from the pre-merge state (HEAD)
for FILE in docker-compose.yaml Dockerfile README.md update.sh; do
    if git checkout HEAD -- "$FILE" 2>/dev/null; then
        echo "   - Restored local $FILE"
        git add "$FILE"
    fi
done

# Check if we have remaining conflicts
REMAINING=$(git diff --name-only --diff-filter=U)
if [ -n "$REMAINING" ]; then
    echo "⚠️  Some conflicts require manual resolution: $REMAINING"
    exit 1
else
    git commit -m "chore: auto-update to $TARGET_TAG" --no-edit || echo "ℹ️ Nothing new to commit."
    echo "✅ Update prepared locally."
fi

# 5. Done
echo "-------------------"
echo "🎉 Local update files prepared!"
echo "Check your files and run 'git push public-fork HEAD' when ready."
