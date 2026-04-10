# fabric-toolkit — Asset Manifest

> **For agents:** Use this file as your Fabric-work routing index.
> 1. Scan the **Agents** and **Skills** tables below for `active` rows matching your task.
> 2. Read the corresponding `SKILL.md` at `docs/fabric-toolkit/upstream/skills/<name>/SKILL.md`. Skills deep-link into `../../common/` reference docs; follow those links as needed.
> 3. Skip `dormant` rows unless the row's "Promote when" trigger is met — those assets exist on disk but are not wired into Claude Code.
> 4. Skip the **MCP**, **Upstream docs**, and **Compatibility files** sections entirely — they are not agent-invocable from this project.

Full index of upstream `microsoft/skills-for-fabric` assets, marked **active** (wired into `.claude/`) or **dormant** (available at `upstream/` but not loaded by Claude Code).

**Rule:** Only active assets count toward Claude Code's loaded context. Promoting a dormant asset takes a single symlink addition in `scripts/fabric-toolkit-wire.sh` plus a status flip here. See `README.md` for the full promotion flow.

## Agents (upstream: `upstream/agents/`)

| File | Status | Purpose | Promote when |
|------|--------|---------|--------------|
| `FabricDataEngineer.agent.md` | **active** | Orchestrates medallion + ETL/ELT across Spark, SQL, Pipelines. Primary entry point for Lakehouse and transformation work. | — |
| `FabricAdmin.agent.md` | **active** | Workspace provisioning, capacity, governance, security, RLS + AD groups, observability. Aligns to SOW2 CI/CD + DEV/TEST/PROD + PBI governance scope. | — |
| `FabricAppDev.agent.md` | dormant | Python/ODBC/XMLA consumers of Fabric data (pyodbc, sqlalchemy, azure-identity). | A deliverable requires a custom Python data-access layer or embedded app consuming Fabric — e.g. a sidecar service for Sales AI Agent (D6) or a custom reporting tool. |

## Skills (upstream: `upstream/skills/`)

Each skill directory contains a `SKILL.md` plus optional `references/` or `resources/` subdirs. Skills deep-link into `upstream/common/` — do not relocate them outside the `upstream/` tree.

| Skill | Status | Purpose | Promote when |
|-------|--------|---------|--------------|
| `e2e-medallion-architecture` | **active** | Bronze/Silver/Gold end-to-end: workspace-per-layer, V-Order, OPTIMIZE WRITE, Direct Lake hand-off to PBI. Dense, ~22 KB. | — |
| `spark-authoring-cli` | **active** | Notebook API workflow, data-engineering patterns (MERGE, schema mgmt), Spark session tuning profiles, 4 reference docs covering patterns / workflow / orchestration / notebook-api. Critical path for D1a/D1b. | — |
| `sqldw-authoring-cli` | **active** | T-SQL DDL/DML/ETL, COPY INTO, transactions, stored procs, time travel. Silver/Gold warehouse path; option for Decentrix ETL migration if we go warehouse-native. | — |
| `sqldw-consumption-cli` | **active** | Read-only T-SQL against lakehouse SQL endpoints and warehouse. Schema discovery, row counts, script generation. Pairs with authoring for dev/test loops. | — |
| `powerbi-authoring-cli` | **active** | Semantic model creation, TMDL authoring, Direct Lake, dataset refresh, deployment pipelines, permissions. 39 KB + 3 reference docs (properties / TMDL / advanced features). Covers PBI modernization + unified views initiatives. | — |
| `spark-consumption-cli` | dormant | Livy sessions, DataFrames, Delta time-travel, JSON / unstructured analysis. Interactive analytical workflow. | First time we need interactive ad-hoc Spark analysis during Discovery or Execute — or when validating pipeline outputs without running full authoring cycle. |
| `powerbi-consumption-cli` | dormant | DAX queries + semantic model metadata discovery. Requires `PowerBIQuery` MCP server. | Promotion blocked on (1) client approval of the MS-hosted PowerBIQuery MCP endpoint and (2) client-issued credentials. Reassess after kickoff. |
| `eventhouse-authoring-cli` | dormant | KQL table authoring, ingestion, materialized views, retention policies (Real-Time Intelligence). | A deliverable introduces streaming / event-driven data — not currently in SOW2 scope. |
| `eventhouse-consumption-cli` | dormant | KQL queries, time-series analytics, ingestion health monitoring. | Paired with `eventhouse-authoring-cli` — same trigger. |
| `check-updates` | dormant | Upstream marketplace version check utility. | Not needed — replaced by `scripts/fabric-toolkit-sync.sh`. |

## Common reference docs (upstream: `upstream/common/`)

These are the shared knowledge base that skills link into via relative paths. They are **always loaded implicitly** when an active skill links to them — no separate activation needed. Listed here for discoverability.

| File | Covers |
|------|--------|
| `COMMON-CORE.md` | Fabric REST API patterns, auth, token audiences, item discovery, workload topology, rate limiting, LRO polling, gotchas |
| `COMMON-CLI.md` | `az rest` recipes, token acquisition by workload, OneLake via curl, SQL via sqlcmd, pagination |
| `ITEM-DEFINITIONS-CORE.md` | Definition envelope formats — TMDL, PBIR, `.ipynb` (notebook JSON with Fabric execution_count/outputs rules) |
| `SPARK-AUTHORING-CORE.md` | Notebook deployment, lakehouse creation, job execution, CI/CD patterns for Spark |
| `SPARK-CONSUMPTION-CORE.md` | Livy session lifecycle, DataFrame patterns, Delta Lake read paths |
| `SQLDW-AUTHORING-CORE.md` | T-SQL object authoring on Warehouses and SQL Endpoints |
| `SQLDW-CONSUMPTION-CORE.md` | Read-only T-SQL patterns, schema discovery, performance monitoring |
| `EVENTHOUSE-AUTHORING-CORE.md` | KQL table authoring (dormant domain) |
| `EVENTHOUSE-CONSUMPTION-CORE.md` | KQL query patterns (dormant domain) |

## MCP (upstream: `upstream/mcp-setup/` and `upstream/.mcp.json`)

| Asset | Status | Purpose | Promote when |
|-------|--------|---------|--------------|
| `upstream/.mcp.json` → `PowerBIQuery` server | dormant | Microsoft-hosted HTTP MCP at `api.fabric.microsoft.com/v1/mcp/powerbi` with OAuth public client flow. Enables DAX query execution against semantic models. | **Blocked pending client approval.** Also blocked until we have client-issued credentials with access to their Fabric workspaces. Reassess after kickoff. |
| `upstream/mcp-setup/register-fabric-mcp.sh` / `.ps1` | dormant | Scripts for registering additional Fabric MCP servers (fabric / fabric-warehouse / fabric-lakehouse templates) with Copilot CLI or Claude Desktop. | If Microsoft publishes additional Fabric MCP servers we want to use, or if we want to use the generic Fabric MCP templates for custom endpoints. |
| `upstream/mcp-setup/mcp-config-template.json` | dormant | Template JSON with bearer-token + env var substitution. | Same as above. |

## Upstream docs (upstream: `upstream/docs/`)

Read-only reference. Useful for understanding how Microsoft structures agents/skills/common so that any assets we author ourselves can follow the same patterns. Not wired into Claude Code.

- `architecture-overview.md` — Agents → Skills → Common hierarchy, top-down flow principle
- `skill-authoring-guide.md` — How to create new skills
- `common-folder-guide.md` — What belongs in common/ and why
- `quality-requirements.md` — Token limits, trigger similarity rules
- `testing-guide.md`, `plugins-guide.md`, `mcp-servers-guide.md`

## Compatibility files (upstream: `upstream/compatibility/`, `upstream/install.sh`, etc.)

Ignored. These exist for users running the upstream install script in other AI-tool environments (Cursor, Windsurf, Codex). We use the symlink-into-`.claude/` pattern instead, so `install.sh` / `.cursorrules` / `.windsurfrules` / `AGENTS.md` / `package.json` / `install.ps1` are not relevant to us.

## Summary count

- **Active:** 2 agents + 5 skills = 7 assets wired into `.claude/`.
- **Dormant (tracked, pullable on demand):** 1 agent + 5 skills + 3 MCP assets = 9 assets.
- **Reference only (not loaded, read by humans when useful):** all of `upstream/docs/` + `upstream/common/*` (latter is implicitly loaded through skill links).
