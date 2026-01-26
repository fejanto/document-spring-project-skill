#!/usr/bin/env bash
# Auto-update hook for document-spring-project plugin
# Runs when Claude Code loads the plugin

set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
UPDATE_CHECK_FILE="$PLUGIN_DIR/.last-update-check"
UPDATE_INTERVAL=86400  # 24 hours in seconds

# Function to check if update is needed
should_check_update() {
    if [ ! -f "$UPDATE_CHECK_FILE" ]; then
        return 0  # First run, should check
    fi

    local last_check=$(cat "$UPDATE_CHECK_FILE")
    local now=$(date +%s)
    local elapsed=$((now - last_check))

    if [ $elapsed -gt $UPDATE_INTERVAL ]; then
        return 0  # More than 24h since last check
    fi

    return 1  # Recently checked
}

# Function to check for updates (if git repo)
check_git_updates() {
    if [ ! -d "$PLUGIN_DIR/.git" ]; then
        return 0  # Not a git repo, skip
    fi

    cd "$PLUGIN_DIR"

    # Fetch latest without pulling
    git fetch origin master --quiet 2>/dev/null || return 0

    # Check if behind
    local local_commit=$(git rev-parse HEAD)
    local remote_commit=$(git rev-parse origin/master)

    if [ "$local_commit" != "$remote_commit" ]; then
        # Clear old cache to prepare for update
        local cache_dir="$HOME/.claude/plugins/cache/fejanto-skills/document-spring-project"
        if [ -d "$cache_dir" ]; then
            rm -rf "$cache_dir" 2>/dev/null || true
        fi

        echo "📦 Update available for document-spring-project plugin"
        echo "   Current: ${local_commit:0:8}"
        echo "   Latest:  ${remote_commit:0:8}"
        echo ""
        echo "   Run: /docs-update"
        echo "   Or:  cd $PLUGIN_DIR && git pull origin master"
        echo ""
        echo "   (Old cache cleared automatically)"
        echo ""
        return 1
    fi

    return 0
}

# Main execution
main() {
    # Check if should verify updates
    if ! should_check_update; then
        exit 0  # Skip check
    fi

    # Record check time
    date +%s > "$UPDATE_CHECK_FILE"

    # Check for updates
    check_git_updates

    exit 0
}

# Only run if not sourced
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
