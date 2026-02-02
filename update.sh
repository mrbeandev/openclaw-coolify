#!/bin/bash

# OpenClaw/Moltbot Auto-Updater for Coolify
# -----------------------------------------
# This script safely updates your repository to the latest stable release
# while preserving your Coolify-specific configurations.

set -e

# 1. Setup Remote
REMOTE_NAME="upstream"
UPSTREAM_URL="https://github.com/openclaw/openclaw.git" # Official OpenClaw Repo

echo "🦞 OpenClaw Updater"
echo "-------------------"

# Check if we are inside a valid git repo
if [ ! -d ".git" ]; then
    echo "❌ Error: Not a git repository. Please run this from the root of your installation."
    exit 1
fi

# Ensure upstream is configured
if ! git remote | grep -q "^${REMOTE_NAME}$"; then
    echo "🔹 Configuring upstream remote ($UPSTREAM_URL)..."
    git remote add $REMOTE_NAME $UPSTREAM_URL
else
    echo "🔹 Upstream remote is configured."
fi

# 2. Fetch Latest Info
echo "🔹 Fetching latest tags..."
git fetch $REMOTE_NAME --tags --quiet

# Find latest stable tag (filters out -beta, -alpha, etc)
LATEST_TAG=$(git tag -l "v*" | grep -v "-" | sort -V | tail -n 1)

if [ -z "$LATEST_TAG" ]; then
    echo "❌ Error: Could not find any stable tags."
    exit 1
fi

CURRENT_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "unknown")

echo "ℹ️  Current Version: $CURRENT_TAG"
echo "ℹ️  Latest Version:  $LATEST_TAG"

if [ "$CURRENT_TAG" == "$LATEST_TAG" ]; then
    echo "✅ You are already on the latest version."
    exit 0
fi

# 3. Perform Update
read -p "❓ Update to $LATEST_TAG? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Update cancelled."
    exit 1
fi

echo "🚀 Starting update..."

# Stash any uncommitted local changes to be safe
if [[ -n $(git status -s) ]]; then
    echo "📦 Stashing local changes..."
    git stash push -m "Auto-update stash $(date)"
fi

# Try to merge
echo "🔹 Merging $LATEST_TAG..."
if git merge "$LATEST_TAG" --no-edit; then
    echo "✅ Merge successful."
else
    echo "⚠️  Merge conflicts detected."
    echo "🔧 Attempting to preserve your Coolify configurations..."
    
    # Conflict Resolution Strategy:
    # We PRIORITIZE our local Coolify config files (docker-compose, Dockerfile)
    # forcing them to keep 'OUR' version (the one currently working on Coolify).
    
    CONFLICTS=$(git diff --name-only --diff-filter=U)
    
    if echo "$CONFLICTS" | grep -q "docker-compose.yml"; then
        echo "   - Keeping local docker-compose.yml"
        git checkout HEAD -- docker-compose.yml
        git add docker-compose.yml
    fi
    
    if echo "$CONFLICTS" | grep -q "Dockerfile"; then
        echo "   - Keeping local Dockerfile"
        git checkout HEAD -- Dockerfile
        git add Dockerfile
    fi

    # Check if there are still unresolved conflicts
    REMAINING_CONFLICTS=$(git diff --name-only --diff-filter=U)
    if [ -n "$REMAINING_CONFLICTS" ]; then
        echo "❌ Automated resolution failed for these files:"
        echo "$REMAINING_CONFLICTS"
        echo "Please manually resolve the conflicts, commit, and push."
        exit 1
    else
        git commit --no-edit
        echo "✅ Conflicts resolved (Coolify configs protected)."
    fi
fi

# 4. Push to Origin
echo "🔄 Pushing updated code to your repository..."
git push origin HEAD

echo "-------------------"
echo "🎉 Update Complete!"
echo "👉 Coolify should now detect the new commit and redeploy your bot."
