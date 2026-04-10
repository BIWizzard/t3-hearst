# t3-hearst — Discovery Log

Discoveries with cross-phase implications. Append-only.

---

## 2026-04-10 — Pre-Kickoff: Project Init + SOW Ingestion
**Phase context:** Pre-kickoff setup before Apr 13–15 SOW kickoff in Charlotte, NC
**Session log:** `sessions/2026-04-10-project-init-sow-ingest.md`

### Discoveries

#### MVP and Phase 2 have different sponsors and services managers
- MVP (SOW v7.0) sponsored by **Preman Narayanan** (VP, Ad Operations) with **Leslie Huffman** as Services Solutions Manager.
- Phase 2 (SOW v2.0) sponsored by **Dilip Jayavelu** (Senior Director, Business Intelligence) with **Josh Ruyle** as SSM.
- **Downstream:** Phase 2 reports into the BI org, not Ad Ops. May affect prioritization, escalation paths, and stakeholder alignment across all D1–D11 deliverables. The reason for the sponsorship shift is unknown and should be clarified during kickoff as it may signal org-political context worth understanding.

#### SOW v2 is a DTaaS (Data Transformation as a Service) engagement, not fixed-scope
- 30 of 34 weeks are the Execute phase — nearly the entire engagement is **elastic capacity** (160 hrs/mo DE+DA, 20 hrs/mo Architect) directed at a rolling initiative menu.
- Internal label "**DA TWINS**" appears on the role cards; acronym meaning is unknown.
- **Downstream:** Affects how Ken should plan and track work across all future phases. D1–D11 roadmap items are Client-directed priorities, not contractual commitments. Discovery, Design, and Execute phases need to be approached as demand-driven rather than waterfall. Planning artifacts in `docs/plans/` should reflect capacity allocation against the monthly envelope, not fixed deliverable deadlines.

#### MVP dashboard work was capped at 3 legacy pages
- SOW v7.0 §2.2.3 Phase 4 explicitly limited new dashboard development to "recreation of functionality of up to three (3) legacy dashboard pages of medium to high complexity."
- **Downstream:** Phase 2 Discovery phase PBI audit should not assume a substantial MVP dashboard inventory to carry forward. "MVP Power BI dashboards moved to PROD" in the SOW v2 Execute menu refers to at most 3 dashboards. Any unified PBI view work will be net-new construction.

#### Decentrix sunset deadline and SOW end date are tight adjacents
- SOW v2 End Date: **December 31, 2026**
- Decentrix vendor sunset (external business driver): **January 1, 2027**
- **Downstream:** Zero buffer between SOW closure and vendor shutdown. Unclear whether hypercare/closure must complete before sunset or if the two can run concurrently. Affects Q4 2026 scheduling and risk management. Must be resolved at kickoff.

#### SOW v2 T&E is uncapped at resource level
- T&E billed at up to $2,500/week/resource with no stated total ceiling in the fee table. Contrast with MVP which capped T&E at $10,000 total.
- **Downstream:** Over 34 weeks with potential multi-resource onsite presence, T&E could substantially exceed budget expectations. Worth monitoring across Execute phase and flagging in status reporting.

### Assumptions Validated

- **[A1]** "Wide Open" is WideOrbit — SOW v7.0 §2.1.1
- **[A2]** Microsoft Fabric (Lakehouse) is the target platform — SOW v2.0 §2.1, §2.2
- **[A4]** Decentrix decommission is inside the SOW2 Execute phase — SOW v2.0 initiative menu
- **[A5]** DEV/TEST/PROD + CI/CD is in scope — SOW v2.0 §2.1, §2.2
- **[A6]** AI expansion uses Azure OpenAI + Fabric AI Agent framework — SOW v2.0 §2.2
- **[A8]** Client owns LLM provisioning/licensing — SOW v2.0 Assumptions §2.7

### Assumptions Invalidated

- None this session.

### Open Questions

1. What does "TWINS" / "DA TWINS" stand for in the DTaaS delivery model?
2. Must SOW closure (Dec 31 2026) complete before Decentrix sunset (Jan 1 2027), or can they run in parallel?
3. Why did sponsorship shift from Ad Ops (Preman) to BI (Dilip) between MVP and Phase 2?
4. Is "medallion architecture" the agreed internal pattern or just a working assumption? (Confirm at Design phase.)

---

## 2026-04-10 — Pre-Kickoff: Fabric Toolkit Setup
**Phase context:** Pre-kickoff tooling prep — vendored `microsoft/skills-for-fabric` and wired an active set of Fabric agents and skills into Claude Code for the Phase 2 engagement.
**Session log:** `sessions/2026-04-10-fabric-toolkit-setup.md`

### Discoveries

#### Microsoft ships a first-party, MIT-licensed Fabric skills library usable by Claude Code
- `microsoft/skills-for-fabric` contains 3 persona agents (FabricDataEngineer, FabricAdmin, FabricAppDev), 10 skills covering Spark/Warehouse/Eventhouse/PowerBI authoring + consumption, 9 shared `common/` reference docs, and MCP setup templates. All Claude-Code compatible YAML frontmatter + markdown.
- License is MIT (Microsoft Corporation, 2026). Attribution requirement met by shipping `UPSTREAM-LICENSE` alongside the vendored content.
- **Downstream:** This is a durable, Microsoft-maintained knowledge base for Fabric work that we can pull from across the entire engagement. Any Fabric-adjacent task (medallion design, notebook authoring, TMDL semantic modeling, T-SQL ETL, governance) now has a first-party reference as context-dense as anything we'd write ourselves. All future Fabric work should consider whether one of the active skills applies before reinventing.

#### Upstream skills deep-link into a shared `common/` directory via relative paths
- Skills reference `../../common/COMMON-CORE.md` and similar paths. This is an upstream architectural choice (top-down flow: Agents → Skills → Common) documented in `docs/architecture-overview.md` inside the upstream repo.
- **Downstream:** Any cherry-pick or per-skill reorganization that breaks this relative layout will silently degrade the skills' progressive disclosure. The fabric-toolkit vendoring pattern preserves the layout; any project-local override must either inherit the same layout or rewrite paths.

#### Upstream `install.sh` is designed for global install and clobbers project-local `CLAUDE.md` / `AGENTS.md` / `.cursorrules` / `.windsurfrules`
- Confirmed by reading `install.sh`. Copies skills to `~/.copilot/skills/fabric/` and drops compatibility files into the project root. Existing files may be overwritten depending on the install flag combination.
- **Downstream:** **Never run `install.sh` against this repo** or any project repo that has its own `CLAUDE.md`. The toolkit's vendor-then-symlink pattern is the safe integration method. If we ever port this to a client repo that has its own CLAUDE.md conventions, same rule applies.

#### Only 1 of 10 upstream skills requires an MCP server
- `powerbi-consumption-cli` depends on the `PowerBIQuery` MCP at `api.fabric.microsoft.com/v1/mcp/powerbi` for DAX query execution. The other 9 skills use `az rest` / `sqlcmd` / `curl` / Livy API patterns and require no MCP.
- **Downstream:** Delaying client MCP approval does not block any of our active skills. Only gates promotion of `powerbi-consumption-cli`. If the client permanently denies the Microsoft-hosted MCP endpoint, we lose DAX-via-MCP but keep all authoring capabilities.

### Assumptions Validated

- None against the brief's assumptions registry — this session was tooling work, not engagement claims.

### Assumptions Invalidated

- None.

### Open Questions

5. Does Microsoft update `microsoft/skills-for-fabric` frequently enough to warrant monthly sync cadence, or is quarterly enough? First real sync will set the baseline.
6. At kickoff, confirm client approval of the Microsoft-hosted `PowerBIQuery` MCP server and establish the credential provisioning path. (New items 8 and 9 on the kickoff agenda alongside the prior 7.)
7. If Fabric tooling patterns catch on internally at Trace3, is there value in publishing `PATTERN.md` + scripts as a reusable internal snippet so other engineers don't re-derive the approach?
