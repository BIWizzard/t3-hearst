#!/usr/bin/env bash
# fabric-toolkit-sync.sh — pull upstream microsoft/skills-for-fabric into docs/fabric-toolkit/upstream
#
# What it does:
#   1. Verifies the `microsoft-fabric` remote exists (adds it if missing).
#   2. Captures the current pinned SHA (before).
#   3. Runs `git subtree pull --prefix=docs/fabric-toolkit/upstream microsoft-fabric main --squash`.
#   4. Captures the new pinned SHA (after).
#   5. Reports which files in the active set (agents/skills wired into .claude/) changed.
#   6. Prompts to append a new entry to UPSTREAM.md.
#
# Safe to rerun. Non-destructive — subtree pull merges cleanly or leaves conflicts for manual resolution.

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

UPSTREAM_REMOTE="microsoft-fabric"
UPSTREAM_URL="https://github.com/microsoft/skills-for-fabric.git"
UPSTREAM_BRANCH="main"
SUBTREE_PREFIX="docs/fabric-toolkit/upstream"
UPSTREAM_LOG="docs/fabric-toolkit/UPSTREAM.md"

# Active-set paths, relative to the subtree prefix. Keep in sync with scripts/fabric-toolkit-wire.sh
ACTIVE_PATHS=(
  "agents/FabricDataEngineer.agent.md"
  "agents/FabricAdmin.agent.md"
  "skills/e2e-medallion-architecture"
  "skills/spark-authoring-cli"
  "skills/sqldw-authoring-cli"
  "skills/sqldw-consumption-cli"
  "skills/powerbi-authoring-cli"
)

echo "==> fabric-toolkit sync"

# 1. Ensure remote exists
if ! git remote get-url "$UPSTREAM_REMOTE" >/dev/null 2>&1; then
  echo "    remote '$UPSTREAM_REMOTE' not found — adding"
  git remote add -f "$UPSTREAM_REMOTE" "$UPSTREAM_URL"
fi

# 2. Capture current pin (SHA of last upstream commit reachable through the subtree squash)
BEFORE_SHA=$(git log --grep="git-subtree-dir: $SUBTREE_PREFIX" --pretty=format:"%s %b" -1 \
  | grep -oE "git-subtree-split: [0-9a-f]+" | awk '{print $2}' | cut -c1-40 || true)
if [ -z "$BEFORE_SHA" ]; then
  BEFORE_SHA="(unknown)"
fi
echo "    current pin: $BEFORE_SHA"

# 3. Fetch latest upstream
git fetch "$UPSTREAM_REMOTE" "$UPSTREAM_BRANCH"
AFTER_SHA=$(git rev-parse "$UPSTREAM_REMOTE/$UPSTREAM_BRANCH")
echo "    upstream HEAD: $AFTER_SHA"

if [ "$BEFORE_SHA" = "$AFTER_SHA" ]; then
  echo "==> already up to date, nothing to pull"
  exit 0
fi

# 4. Diff active set (before pulling) so we can report what's about to change
echo ""
echo "==> changes in active-set files between $BEFORE_SHA and $AFTER_SHA:"
ACTIVE_CHANGED=()
for path in "${ACTIVE_PATHS[@]}"; do
  # Walk the upstream tree at HEAD and compare to current pin
  if [ "$BEFORE_SHA" != "(unknown)" ]; then
    if ! git diff --quiet "$BEFORE_SHA" "$AFTER_SHA" -- "$path" 2>/dev/null; then
      ACTIVE_CHANGED+=("$path")
      echo "    [changed] $path"
    fi
  fi
done
if [ ${#ACTIVE_CHANGED[@]} -eq 0 ]; then
  echo "    (no active-set files changed — sync is low-risk)"
fi

# 5. Run the actual subtree pull
echo ""
echo "==> running git subtree pull (squashed)"
git subtree pull --prefix="$SUBTREE_PREFIX" "$UPSTREAM_REMOTE" "$UPSTREAM_BRANCH" --squash

# 6. Prompt for UPSTREAM.md update
echo ""
echo "==> sync complete. Please update $UPSTREAM_LOG:"
echo "    - Current pin: $AFTER_SHA"
echo "    - Add a sync-log row with today's date, $BEFORE_SHA → $AFTER_SHA, and the changed files listed above."
echo ""
if [ ${#ACTIVE_CHANGED[@]} -gt 0 ]; then
  echo "==> review recommended: ${#ACTIVE_CHANGED[@]} active-set file(s) changed. Open them in .claude/ to verify behavior."
fi
