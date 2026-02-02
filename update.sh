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
git fetch $REMOTE_NAME --tags --quiet || { echo "❌ Network error: Could not fetch from upstream."; exit 1; }

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
if git merge "$TARGET_TAG" --no-edit; then
    echo "✅ Merge successful."
else
    echo "⚠️  Merge conflicts detected."
    echo "🔧 Preserving Coolify configurations (docker-compose.yml, Dockerfile)..."
    
    CONFLICTS=$(git diff --name-only --diff-filter=U)
    
    # Priority protection for Coolify config
    for FILE in docker-compose.yml Dockerfile; do
        if echo "$CONFLICTS" | grep -q "$FILE"; then
            echo "   - Keeping local $FILE"
            git checkout HEAD -- "$FILE"
            git add "$FILE"
        fi
    done

    # Check remaining
    REMAINING=$(git diff --name-only --diff-filter=U)
    if [ -n "$REMAINING" ]; then
        echo "❌ Automated resolution failed for: $REMAINING"
        echo "Please resolve manually."
        exit 1
    else
        git commit --no-edit
        echo "✅ Conflicts resolved."
    fi
fi

# 5. Push to Deploy
echo "🔄 Pushing to origin (triggers Coolify deploy)..."
git push origin HEAD

echo "-------------------"
echo "🎉 Update Complete!"
