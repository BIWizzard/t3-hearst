# Pre-Kickoff: Fabric Toolkit Setup — 2026-04-10

**Repo:** t3-hearst
**Branch:** `main`
**Phase:** Pre-Kickoff Setup (SOW kickoff scheduled Apr 13–15, 2026)
**Task(s):** Investigate `microsoft/skills-for-fabric` repo; vendor it into this project with a curation overlay and wire the active set into `.claude/`; produce a portable, teachable explanation of the pattern for reuse in other repos.

## Session Summary

Second working session on t3-hearst, focused on tooling preparation for the Fabric-heavy data engineering work coming in Phase 2. Started from a clean repo with only the prior session's SOW ingest committed, and ended with a fully vendored copy of Microsoft's first-party Fabric skills repo, a curation layer governing which assets are active vs dormant, project-local symlinks wiring the active set into Claude Code, reproducible sync and wire scripts, and a portable PATTERN.md document explaining the entire approach for replication in other repos.

The core investigation was delegated to three parallel Explore subagents that independently mapped the upstream `agents/`, `skills/`, and `mcp-setup/ + common/ + docs/ + root` trees. Their reports surfaced several structural facts that changed the integration plan mid-session — most notably that skills deep-link into a shared `common/` directory via relative paths, which made the cherry-pick approach brittle and tipped the decision toward vendoring the full repo via `git subtree` instead of selective file copies.

Work was entirely tooling and scaffolding — no Fabric code written, no architecture decisions for the actual engagement. The goal was to give future sessions (and potentially other repos) a well-curated, updatable, teachable body of Fabric knowledge that Claude Code can load as native agents and skills.

## What Was Built/Changed

**Vendored upstream (via `git subtree`, squashed):**
- `docs/fabric-toolkit/upstream/` — full mirror of `microsoft/skills-for-fabric` at commit `339c328dc507a0ff2235e79a70d7c175eb6cc281` (upstream `main` as of 2026-03-26). Includes 3 agents, 10 skills, 9 common reference docs, mcp-setup templates, compatibility files, and upstream docs. 482 KB total.

**Curation overlay (`docs/fabric-toolkit/`):**
- `README.md` — project-specific usage instructions: layout, how the active set is wired, how to promote dormant assets, how to sync, how to customize.
- `MANIFEST.md` — asset index covering all 3 agents, 10 skills, 9 common docs, and mcp-setup items. Each entry marked `active` / `dormant` with a "promote when" trigger column so future-me knows the signal to watch for. Active set: 2 agents + 5 skills.
- `PATTERN.md` — portable, teachable document explaining the whole pattern: the problem, why the obvious approaches don't work, the three-layer design (subtree + overlay + symlinks), safety properties, expected use cases, 9-step replication guide for fresh repos, maintenance operations, and a "what this is / isn't" scoping section. Intentionally has zero t3-hearst-specific references so it can be copied verbatim into another repo.
- `UPSTREAM.md` — pinned commit SHA, integration method (git subtree squashed), sync log (initial entry only so far).
- `UPSTREAM-LICENSE` — MIT license copy from upstream, satisfying the attribution requirement for all vendored content.

**Scripts (tracked, under `scripts/`):**
- `fabric-toolkit-sync.sh` — wraps `git subtree pull --squash`, captures before/after SHAs, reports which active-set files changed between pulls, prompts for UPSTREAM.md update. Reads the active-set path list from an inline array that must stay in sync with the wire script.
- `fabric-toolkit-wire.sh` — idempotent. Creates symlinks under `.claude/agents/` and `.claude/skills/` pointing back into `docs/fabric-toolkit/upstream/`. Agent symlinks rename from upstream's `Fabric<Persona>.agent.md` to kebab-case `<name>.md` as Claude Code expects. Skill symlinks preserve upstream directory names.

**Active set wired into `.claude/`:**
- `fabric-data-engineer` (agent) — primary orchestrator for medallion / ETL / ELT
- `fabric-admin` (agent) — workspace provisioning, governance, RLS/AD groups, CI/CD-adjacent
- `e2e-medallion-architecture` (skill) — Bronze/Silver/Gold end-to-end, 22 KB, covers V-Order / OPTIMIZE WRITE / Direct Lake
- `spark-authoring-cli` (skill + 4 reference docs) — notebook API workflow, data engineering patterns, Spark session tuning profiles
- `sqldw-authoring-cli` (skill) — T-SQL ETL / DDL / DML / COPY INTO / time travel
- `sqldw-consumption-cli` (skill) — read-only T-SQL against lakehouse SQL endpoints
- `powerbi-authoring-cli` (skill + 3 reference docs) — TMDL, semantic models, Direct Lake, deployment pipelines

**Dormant (tracked in upstream/, pullable via MANIFEST.md triggers):**
- `FabricAppDev.agent.md`
- `spark-consumption-cli`, `powerbi-consumption-cli`, `eventhouse-authoring-cli`, `eventhouse-consumption-cli`, `check-updates`
- `.mcp.json` PowerBIQuery server — **blocked pending client approval of the Microsoft-hosted MCP endpoint and credentials**; reassess after kickoff
- `mcp-setup/` Fabric MCP registration templates

**Project config updates:**
- `docs/open-mind.yaml` — added the four overlay markdown files (README, MANIFEST, PATTERN, UPSTREAM) to `tracked_files` so Neon indexes them for semantic retrieval. Intentionally did not add `upstream/*` to avoid polluting Neon with vendor content.
- `docs/captures.md` — one capture entry at 13:25 indexing the toolkit artifacts.

## Key Decisions

| Decision | Rationale |
|----------|-----------|
| Vendor the full upstream repo via `git subtree --squash` rather than cherry-pick selected files | Skills deep-link into `common/` via relative paths like `../../common/COMMON-CORE.md`; cherry-picking would require either pulling the full `common/` anyway (saving little) or rewriting the paths (breaking sync). Skills also cross-reference each other. Full vendor keeps upstream pristine, makes syncs `git subtree pull`, and only adds ~482 KB. |
| Store vendored content under `docs/fabric-toolkit/upstream/` and the overlay files beside it (not inside) | Overlay files (README, MANIFEST, PATTERN, UPSTREAM, LICENSE) never need to move during a sync because they live outside the subtree prefix. Syncs only touch `upstream/`. |
| Wire the active set via symlinks from `.claude/` back into `docs/fabric-toolkit/upstream/` (rather than file copies) | Single source of truth: upstream files never get duplicated. Relative paths in skills (`../../common/...`) resolve correctly because the symlink target is the real file inside `upstream/skills/<name>/`, so `../../common/` walks back through `upstream/skills/` to `upstream/common/`. Verified working with live `ls` + `head` through a symlink. |
| Keep `.claude/` gitignored; rebuild symlinks via `scripts/fabric-toolkit-wire.sh` on fresh clones | `.claude/` already holds ruflo boilerplate (98+ files) that we've intentionally gitignored. Keeping symlinks out of tracking matches that pattern. Wire script is idempotent so re-running is safe. |
| Rename agent filenames at the symlink level (`FabricDataEngineer.agent.md` → `fabric-data-engineer.md`) rather than editing upstream files | Upstream uses PascalCase `.agent.md` suffix; Claude Code expects kebab-case `.md`. Renaming at symlink level means upstream files stay pristine and updates never produce merge conflicts. |
| Hold the `PowerBIQuery` MCP server dormant until kickoff | Requires client approval of a Microsoft-hosted MCP endpoint and client-issued credentials, neither of which exist yet. No urgency to promote before we actually have access to client Fabric. |
| Mark `FabricAdmin.agent.md` active (not just `FabricDataEngineer`) | User prioritized CI/CD + DEV/TEST/PROD + PBI governance work in the scope confirmation, which is exactly where this agent's capacity planning, workspace organization, and RLS/AD content lives. Easy to demote later if it feels too platform-team-ish once the DTaaS role boundaries are clearer. |
| Write a separate `PATTERN.md` (portable) alongside `README.md` (project-specific) rather than collapsing into one doc | User explicitly flagged that this pattern may need to travel to other repos (client, team, personal). Separating the reusable teaching artifact from the project-specific usage doc means the teaching artifact can be copied verbatim without stripping t3-hearst context. |
| Track the overlay markdown in `open-mind.yaml` but exclude `upstream/*` | Overlay files are ours, semantically valuable, and change rarely — good candidates for Neon embedding. Upstream would be thousands of chunks of vendor content that pollutes semantic search results. The MANIFEST is the curation index that lets us find things without needing everything in Neon. |

## Discoveries

- **Discovery:** Skills in `microsoft/skills-for-fabric` use markdown relative paths to deep-link into a shared `common/` directory (e.g., `../../common/COMMON-CORE.md#authentication`). This is a structural assumption of the upstream repo.
  - **Impact:** Any integration approach that separates skills from common/ breaks the progressive-disclosure chain that makes the skills valuable. This forced the shift from cherry-pick to full-vendor. **Downstream:** if we ever customize an active skill with a project-local override, the override must either live inside a directory with the same `../../common/` relative resolution OR have its common/ references rewritten to absolute-from-symlink paths.

- **Discovery:** Upstream agents declare `delegates_to` arrays listing skills by name (not by path). If a listed skill is missing, the agent still loads and functions; it just can't route work to the missing skill.
  - **Impact:** Dormant skills in the MANIFEST don't need the agent's `delegates_to` trimmed — the agent degrades gracefully. Means we can keep upstream agents pristine even though our active set is smaller than the full delegate list. **Downstream:** promoting a dormant skill becomes purely a wire-script change, with no agent edits.

- **Discovery:** The `PowerBIQuery` MCP server in upstream `.mcp.json` is a Microsoft-hosted HTTP endpoint (`api.fabric.microsoft.com/v1/mcp/powerbi`) with OAuth public client flow. Only `powerbi-consumption-cli` depends on it; the other 9 skills use `az rest` / `sqlcmd` / `curl` patterns and need no MCP at all.
  - **Impact:** Delaying MCP approval doesn't block any of our active skills. Only blocks promotion of `powerbi-consumption-cli`. **Downstream:** if client blocks the Microsoft MCP endpoint entirely, we lose DAX query execution via MCP but all authoring capabilities remain via CLI.

- **Discovery:** Symlinks from `.claude/skills/<name>` to `docs/fabric-toolkit/upstream/skills/<name>` correctly resolve the `../../common/` relative links inside the skills because relative path resolution happens from the *real file* location, not the symlink location.
  - **Impact:** Validates the whole symlink-based wiring approach. No path rewriting needed anywhere. **Downstream:** this property also means the wire script never needs to be updated if upstream reorganizes file layout, as long as the skill directory name stays the same and `common/` stays a sibling of `skills/` in upstream.

- **Discovery:** Upstream is MIT-licensed (Microsoft Corporation, 2026). The license has a single attribution requirement — include the copyright + permission notice in copies or substantial portions.
  - **Impact:** Full vendor is unambiguously permitted. Single `UPSTREAM-LICENSE` file satisfies the notice requirement for everything under `upstream/`. No client-side compliance concerns. **Downstream:** if we port the toolkit to a client repo, we carry `UPSTREAM-LICENSE` along as part of the pattern.

- **Discovery:** Upstream's own install flow (`install.sh` / `install.ps1`) copies skills to `~/.copilot/skills/fabric/` (global) and drops compatibility files into the project root (`CLAUDE.md`, `AGENTS.md`, `.cursorrules`, `.windsurfrules`). The upstream root `CLAUDE.md` would collide with any project that already has one.
  - **Impact:** Confirms that running upstream `install.sh` against this repo would have been actively harmful — it would have clobbered our gitignored ruflo `CLAUDE.md`. The vendor-then-wire approach sidesteps this entirely. **Downstream:** never run upstream `install.sh` against any project repo; it's designed for greenfield or globally-shared installs.

- **Discovery:** The Claude Flow daemon started cleanly at session start but was dead by session wrap time (PID file existed but process was gone). Unknown cause.
  - **Impact:** CF memory operations (session save, consolidation, hook feedback, pattern store) will fail during this wrap. Neon + file-based docs are the safety net — all durable session artifacts still get written. **Downstream:** if this keeps happening, investigate whether something in the subtree-add flow or the git subtree merge killed the daemon; for now, treat it as a known soft failure mode.

## Assumptions Validated/Invalidated

No new assumptions were validated or invalidated against the brief's assumptions registry this session. All 9 registry assumptions are unchanged from the prior wrap. The session added structural knowledge about tooling, not claims about the Fabric engagement itself.

## Problems & Solutions

| Problem | Resolution |
|---------|------------|
| Initial plan was to cherry-pick 5 skills into `docs/fabric-toolkit/{skills,common,agents}/` with copied files. After the Explore agents returned, it became clear that skills deep-link into `common/` via relative paths, meaning we'd need `common/` anyway, and that trimming agent `delegates_to` lists would break sync updates. | Pivoted to git subtree vendor of the full repo. User was presented with a reconsidered recommendation and approved. Resulting structure is simpler, has cleaner updates, and avoids the brittleness of path-sensitive cherry-picks. |
| Upstream filenames use PascalCase + `.agent.md` suffix (`FabricDataEngineer.agent.md`), but Claude Code expects lowercase `.md` in `.claude/agents/`. | Renamed at the symlink level: symlinks are named `fabric-data-engineer.md` but point at the upstream file unchanged. No upstream edits, no sync conflicts. |
| Claude Flow daemon was running at session start but dead by wrap time. CF memory operations will fail during wrap. | Warned, continued. Neon embedding + file-based session log + discovery log + git commit are independent of CF and all still functional. The daemon can be restarted at next session start. |
| User asked (after I already sketched a cherry-pick plan) whether full-clone might actually be better given all the baked-in dependencies. | Reconsidered honestly, acknowledged the earlier plan had a hidden cost, and re-presented a full-vendor plan with explicit reasoning for the reversal. The willingness to ask the question mid-plan caught a real structural issue before we committed to the worse approach. |

## Open Questions

1. Why did the Claude Flow daemon die mid-session? Reproducible, or a one-off? If reproducible, does it correlate with `git subtree` operations or some other trigger? Worth watching across the next few sessions.
2. Does Microsoft update `microsoft/skills-for-fabric` frequently enough that a monthly sync cadence makes sense, or is quarterly fine? First real sync will tell us how much churn to expect.
3. At kickoff, ask whether the client permits the Microsoft-hosted `PowerBIQuery` MCP server (`api.fabric.microsoft.com/v1/mcp/powerbi`). If yes, also ask about credential provisioning path. This gates promotion of `powerbi-consumption-cli`.
4. If the Fabric work pattern takes hold on the Trace3 side, does it make sense to publish PATTERN.md + the scripts as an internal reusable snippet somewhere, so other engineers can pick up the same approach without re-deriving it?
5. Verify in the next Claude Code session that the wired agents and skills are actually loaded — the symlinks look correct structurally but the definitive test is a session where Claude Code enumerates them.

## Retrieval Quality

| Context Need | Method | Max Similarity | Fallback Reason |
|---|---|---|---|
| project_status | semantic | 0.540 | — |
| last_session | recent | — | — |
| discoveries | semantic | 0.402 | — |
| practices | sql | — | — |
| related_context | semantic | 0.439 | — |

**Fallback rate:** 0/5 — zero file fallbacks this session.
**Query tuning:** None. The `/om-go` briefing used the default thresholds and returned usable results for all five needs.
**Corpus changes:** Added 4 overlay markdown files to `open-mind.yaml` tracked_files for Neon embedding during this wrap.

## Tracked Files Changed

Tracked files that changed during this session (between wraps):

- `docs/open-mind.yaml` — added 4 fabric-toolkit overlay files to `tracked_files`
- `docs/captures.md` — one capture entry at 13:25 indexing the toolkit artifacts
- `docs/fabric-toolkit/README.md` — **new**
- `docs/fabric-toolkit/MANIFEST.md` — **new**
- `docs/fabric-toolkit/PATTERN.md` — **new**
- `docs/fabric-toolkit/UPSTREAM.md` — **new**
- `docs/fabric-toolkit/UPSTREAM-LICENSE` — **new**
- `docs/sessions/2026-04-10-fabric-toolkit-setup.md` — this session log, **new**
- `docs/discovery-log.md` — appended this session's cross-phase discoveries (below in Step 5)

Untracked (gitignored, existed) additions: symlinks under `.claude/agents/` and `.claude/skills/` for the active set.

Not in the `tracked_files` list but committed to the repo this session:

- `docs/fabric-toolkit/upstream/**` — ~100 files from the git subtree vendoring (license, agents, skills, common, docs, mcp-setup, compatibility, upstream README and misc)
- `scripts/fabric-toolkit-sync.sh`
- `scripts/fabric-toolkit-wire.sh`

## Next Steps

1. **Verify in a fresh Claude Code session** that the wired agents and skills load correctly — pick a small Fabric-adjacent question and see whether the agents or skills get invoked.
2. **At kickoff (Apr 13–15), resolve the MCP question** — confirm or deny client approval for `api.fabric.microsoft.com/v1/mcp/powerbi`, and line up credential provisioning path.
3. **Stand up personal tracking for D1a / D1b** — these are Q2 Plan/Discovery deliverables and the first real use of the toolkit will be here. Create `docs/plans/d1a-*.md` and `docs/plans/d1b-*.md` when the Plan phase formally begins.
4. **Do the first upstream sync** after 2-3 weeks to establish the baseline churn rate and confirm the sync script handles a real pull cleanly.
5. **Prepare the Apr 13–15 kickoff** — the prior session's 7 open questions are still the driving agenda items (TWINS acronym, sunset sequencing, sponsorship handoff, MVP Fabric state, PBI inventory, medallion pattern confirmation, D1–D11 capacity mapping). Add MCP approval and credential provisioning as items 8 and 9.

## Continuation Prompt

> Continue the t3-hearst project — Hearst Television Data Modernization Phase 2 engagement.
>
> **Last session recap:** Set up `docs/fabric-toolkit/` — vendored `microsoft/skills-for-fabric` (MIT, pinned to `339c328d`) as a git subtree, added a curation overlay (README, MANIFEST, PATTERN, UPSTREAM, LICENSE), wrote sync + wire scripts, and symlinked an active set of 2 agents + 5 skills into `.claude/`. The `PATTERN.md` is designed to be portable to other repos. Dormant (pullable on demand): `FabricAppDev`, `spark-consumption-cli`, `powerbi-consumption-cli`, both eventhouse skills, `check-updates`, and the `.mcp.json` PowerBIQuery server (blocked on client approval). All committed to `main` in `5d34dd2` (subtree squash), `00a4237` (subtree merge), and `b6f2b7b` (overlay + scripts + yaml).
>
> **Priority:** SOW kickoff is Apr 13–15 in Charlotte (virtual). Use the kickoff to resolve the 7 open questions from the prior wrap **plus** (8) client approval of the Microsoft-hosted `PowerBIQuery` MCP endpoint and (9) credential provisioning path for client Fabric. Between now and kickoff, verify in a fresh session that Claude Code actually loads the wired fabric agents and skills, and review the PATTERN.md one more time to make sure it reads cleanly as a teaching artifact.
>
> **Key context:**
> - Phase 2 is a **build, not a migration**. DTaaS model — 160 hrs/month DE/DA + 20 hrs/month Architect, Client-directed against a rolling initiative menu. Not fixed-scope.
> - Hard deadline: Jan 1 2027 Decentrix sunset (external business driver, not a contractual SOW date — SOW v2 ends Dec 31 2026).
> - Sponsors differ: MVP = Preman Narayanan (Ad Ops), Phase 2 = Dilip Jayavelu (BI).
> - "TWINS" internal label is unexplained — clarify at kickoff.
> - WideOrbit (not "Wide Open") is the primary data source from the MVP.
> - **Fabric toolkit is wired and ready** — invoke `fabric-data-engineer`, `fabric-admin`, or any of the 5 active skills directly once real Fabric work begins. If you need a dormant skill, check `docs/fabric-toolkit/MANIFEST.md` for the promote trigger and edit `scripts/fabric-toolkit-wire.sh`.
> - **Claude Flow daemon** died mid-session this time. Non-blocking, but worth watching. CF memory operations may fail until the daemon is healthy.
>
> **Brief:** Read `docs/brief.md` for full project context, phase tracker, and assumptions registry. Read `docs/fabric-toolkit/README.md` and `docs/fabric-toolkit/MANIFEST.md` for the active toolkit surface.
