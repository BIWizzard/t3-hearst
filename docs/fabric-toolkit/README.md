# fabric-toolkit

A vendored copy of [`microsoft/skills-for-fabric`](https://github.com/microsoft/skills-for-fabric) plus a curation layer that controls which assets are wired into this project's Claude Code environment.

This toolkit exists because Phase 2 is heavy on Microsoft Fabric work (Lakehouse, Pipelines, OneLake, Power BI, Fabric AI Agent framework) and Microsoft ships a first-party set of AI agent definitions, skills, and common reference docs that cover nearly all of that surface area.

## Layout

```
docs/fabric-toolkit/
├── README.md           ← this file
├── MANIFEST.md         ← full asset index (active vs dormant, promote triggers)
├── UPSTREAM.md         ← pinned commit SHA, sync log
├── UPSTREAM-LICENSE    ← MIT notice from microsoft/skills-for-fabric
└── upstream/           ← git subtree of the full upstream repo (squashed)
    ├── agents/         ← 3 persona agents (Claude Code compatible YAML + markdown)
    ├── skills/         ← 10 skills with progressive-disclosure references
    ├── common/         ← 9 shared reference docs linked from every skill
    ├── mcp-setup/      ← templates for registering Fabric MCP servers
    ├── compatibility/  ← per-tool rule files (ignored for our use)
    ├── docs/           ← upstream authoring/testing guides
    └── ... (full mirror, see upstream README for details)
```

## How the active set is wired

Claude Code loads agents and skills from `.claude/agents/` and `.claude/skills/`. That directory is gitignored in this repo (ruflo boilerplate pattern — see root `.gitignore`), so nothing in the toolkit lives there directly. Instead, the **active set** is wired in via symlinks that point back into `docs/fabric-toolkit/upstream/`:

```
.claude/agents/fabric-data-engineer.md → ../../docs/fabric-toolkit/upstream/agents/FabricDataEngineer.agent.md
.claude/agents/fabric-admin.md         → ../../docs/fabric-toolkit/upstream/agents/FabricAdmin.agent.md
.claude/skills/e2e-medallion-architecture → ../../docs/fabric-toolkit/upstream/skills/e2e-medallion-architecture
.claude/skills/spark-authoring-cli        → ../../docs/fabric-toolkit/upstream/skills/spark-authoring-cli
.claude/skills/sqldw-authoring-cli        → ../../docs/fabric-toolkit/upstream/skills/sqldw-authoring-cli
.claude/skills/sqldw-consumption-cli      → ../../docs/fabric-toolkit/upstream/skills/sqldw-consumption-cli
.claude/skills/powerbi-authoring-cli      → ../../docs/fabric-toolkit/upstream/skills/powerbi-authoring-cli
```

Because every skill deep-links into `common/` via relative paths (`../../common/COMMON-CORE.md`), the symlinks preserve the upstream layout and those links resolve correctly.

After a fresh clone, run:

```bash
scripts/fabric-toolkit-wire.sh
```

This recreates the active-set symlinks. Idempotent — safe to rerun.

## Promoting a dormant asset

To activate something currently marked dormant in `MANIFEST.md`:

1. Find the asset in `MANIFEST.md`, confirm the "promote when" trigger is met.
2. Add a symlink line to `scripts/fabric-toolkit-wire.sh`.
3. Rerun `scripts/fabric-toolkit-wire.sh`.
4. Update `MANIFEST.md` to flip the status from dormant → active.
5. Commit the MANIFEST + wire-script changes.

Do not modify files under `upstream/` directly. Those are owned by the upstream repo and will be overwritten on the next sync.

## Updating from upstream

```bash
scripts/fabric-toolkit-sync.sh
```

The script runs `git subtree pull --prefix=docs/fabric-toolkit/upstream microsoft-fabric main --squash`, reports which active-set files changed so you can review diffs deliberately, and updates `UPSTREAM.md` with the new commit SHA and date.

Prerequisites — the `microsoft-fabric` remote needs to exist. If it doesn't (fresh clone):

```bash
git remote add -f microsoft-fabric https://github.com/microsoft/skills-for-fabric.git
```

## License

Upstream content is MIT-licensed by Microsoft Corporation. See `UPSTREAM-LICENSE`. Redistribution inside this repo is permitted; the notice file satisfies the attribution requirement.

## Customizing agent behavior

The upstream agent files have `delegates_to` arrays that reference skills by name. If we want an agent to behave differently in this project (e.g., only delegate to the skills we've actually activated), **do not edit the file in `upstream/`**. Instead, copy the agent markdown into `.claude/agents/` as a project-local override, modify it there, and note the divergence in `MANIFEST.md` so we remember during sync.

Today, all active agents use the upstream files as-is via symlink. No overrides.
