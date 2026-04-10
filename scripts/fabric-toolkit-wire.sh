#!/usr/bin/env bash
# fabric-toolkit-wire.sh — create symlinks under .claude/ that expose the active-set
# of fabric-toolkit agents and skills to Claude Code.
#
# .claude/ is gitignored in this repo, so the symlinks live outside version control.
# Run this after a fresh clone, or whenever the active set in docs/fabric-toolkit/MANIFEST.md changes.
#
# Idempotent — existing symlinks are replaced, not duplicated.

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

CLAUDE_AGENTS=".claude/agents"
CLAUDE_SKILLS=".claude/skills"
TOOLKIT="docs/fabric-toolkit/upstream"

mkdir -p "$CLAUDE_AGENTS" "$CLAUDE_SKILLS"

# Agent symlinks: upstream uses Fabric<Persona>.agent.md, we rename to kebab-case <name>.md
# which is the filename convention Claude Code expects in .claude/agents/.
link_agent() {
  local upstream_rel="$1"    # e.g. agents/FabricDataEngineer.agent.md
  local link_name="$2"       # e.g. fabric-data-engineer.md
  local link_path="$CLAUDE_AGENTS/$link_name"
  local target="../../$TOOLKIT/$upstream_rel"

  if [ -L "$link_path" ] || [ -e "$link_path" ]; then
    rm -f "$link_path"
  fi
  ln -s "$target" "$link_path"
  echo "    agent  $link_name -> $upstream_rel"
}

# Skill symlinks: upstream skills are directories; preserve the upstream directory name
# since it matches the trigger-phrase conventions in each SKILL.md.
link_skill() {
  local skill_name="$1"
  local link_path="$CLAUDE_SKILLS/$skill_name"
  local target="../../$TOOLKIT/skills/$skill_name"

  if [ -L "$link_path" ] || [ -e "$link_path" ]; then
    rm -f "$link_path"
  fi
  ln -s "$target" "$link_path"
  echo "    skill  $skill_name"
}

echo "==> wiring fabric-toolkit active set into .claude/"

# --- agents ---
link_agent "agents/FabricDataEngineer.agent.md" "fabric-data-engineer.md"
link_agent "agents/FabricAdmin.agent.md"        "fabric-admin.md"

# --- skills ---
link_skill "e2e-medallion-architecture"
link_skill "spark-authoring-cli"
link_skill "sqldw-authoring-cli"
link_skill "sqldw-consumption-cli"
link_skill "powerbi-authoring-cli"

echo ""
echo "==> done. Claude Code will pick up the new agents/skills on next session start."
echo "    To view active set:      cat docs/fabric-toolkit/MANIFEST.md"
echo "    To sync from upstream:   scripts/fabric-toolkit-sync.sh"
