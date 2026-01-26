#!/usr/bin/env bash
# Manual update script for document-spring-project plugin
# Usage: /docs-update

set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "🔄 Updating document-spring-project plugin..."
echo ""

# Check if git repo
if [ ! -d "$PLUGIN_DIR/.git" ]; then
    echo "❌ Not a git repository. Cannot auto-update."
    echo ""
    echo "To update manually:"
    echo "1. Uninstall: /plugin uninstall document-spring-project"
    echo "2. Reinstall: /plugin install document-spring-project@fejanto-skills"
    exit 1
fi

cd "$PLUGIN_DIR"

# Get current version
CURRENT_VERSION=$(git describe --tags --abbrev=0 2>/dev/null || echo "unknown")
CURRENT_COMMIT=$(git rev-parse --short HEAD)

echo "Current version: $CURRENT_VERSION ($CURRENT_COMMIT)"
echo ""

# Fetch latest
echo "Checking for updates..."
git fetch origin master --quiet

# Check if behind
LOCAL_COMMIT=$(git rev-parse HEAD)
REMOTE_COMMIT=$(git rev-parse origin/master)

if [ "$LOCAL_COMMIT" = "$REMOTE_COMMIT" ]; then
    echo "✅ Already up to date!"
    exit 0
fi

# Show what will be updated
echo ""
echo "📦 Update available:"
echo ""
git log --oneline --decorate "$LOCAL_COMMIT..$REMOTE_COMMIT" | head -5
echo ""

# Ask for confirmation
read -p "Update to latest version? (y/n) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Update cancelled."
    exit 0
fi

# Stash any local changes
if ! git diff-index --quiet HEAD --; then
    echo "⚠️  Stashing local changes..."
    git stash push -m "Auto-stash before plugin update"
    STASHED=true
else
    STASHED=false
fi

# Pull latest
echo "Pulling latest changes..."
if git pull origin master --quiet; then
    NEW_VERSION=$(git describe --tags --abbrev=0 2>/dev/null || echo "unknown")
    NEW_COMMIT=$(git rev-parse --short HEAD)

    echo ""
    echo "✅ Update successful!"
    echo ""
    echo "Updated: $CURRENT_VERSION ($CURRENT_COMMIT) → $NEW_VERSION ($NEW_COMMIT)"
    echo ""

    # Restore stashed changes
    if [ "$STASHED" = true ]; then
        echo "Restoring stashed changes..."
        git stash pop --quiet || true
    fi

    echo "Changes will take effect on next Claude Code restart or plugin reload."
    echo ""
    echo "To reload now: /plugin reload document-spring-project"
else
    echo "❌ Update failed. Please check git status and try manually."

    if [ "$STASHED" = true ]; then
        echo ""
        echo "Your changes were stashed. Restore with: git stash pop"
    fi

    exit 1
fi
