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

---

## 2026-04-10 — Pre-Kickoff: Fabric Toolkit Verification
**Phase context:** First functional test of the wired fabric toolkit after the 2026-04-10 setup session. Goal was to verify `.claude/` symlinks enumerate correctly and that spawning `FabricDataEngineer` as a subagent produces usable output.
**Session log:** `sessions/2026-04-10-fabric-toolkit-verification.md` (pending wrap)

### Discoveries

#### Structural wiring passes; FabricDataEngineer loads and produces quality output
- All 7 symlinks (2 agents + 5 skills) resolve to real targets under `docs/fabric-toolkit/upstream/`. Claude Code enumerates them at session start in the agents roster and skills list. Spawning `FabricDataEngineer` via the Agent tool works end-to-end — the agent generated a substantive WideOrbit medallion straw-man (saved to `docs/plans/2026-04-10-wideorbit-medallion-strawman.md`) with a defensible 4-workspace × 3-env topology, opinionated ingestion-shape call (Pipelines Copy + Spark notebooks, no Dataflows Gen2), and 5 sharp kickoff questions.
- **Downstream:** The toolkit is usable today for direct agent invocations and ad-hoc design work. Promotes the fabric agents from "set up but untested" to "proven for single-shot design tasks."

#### **Subagents do not inherit the parent session's skill roster — skills are main-thread only**
- When `FabricDataEngineer` was spawned via the Agent tool, the agent itself flagged that it could not see the `e2e-medallion-architecture` or `spark-authoring-cli` skills in its context, despite the agent's own manifest `delegates_to:` listing them. Root cause: Claude Code skills are registered at the main session level via system-reminders and the `Skill` tool. Subagents spawned via Task tool get a fresh isolated context that does not carry the parent session's skill registrations forward. The symlinks resolve and the skill files exist on disk — but the subagent has no registered Skill tool entries for them and no system-reminder listing them as invocable.
- The agent's `delegates_to:` frontmatter in upstream fabric agent files is **advisory metadata**, not a Claude Code loader directive. Claude Code does not walk the manifest and pre-register the listed skills into the subagent context. Upstream almost certainly designed this for GitHub Copilot CLI's delegation model, which likely handles the manifest differently.
- **Impact on plan execution:** This is the single most important wrinkle for how `/om-exec` should use fabric agents. If a wave spawns `FabricDataEngineer` to build a Bronze→Silver notebook, the agent will fall back to its own embedded knowledge and will not benefit from the detailed skill content unless that content is surfaced another way.
- **Workarounds (pick one per task, none require framework changes):**
  1. **Inline the skill content in the spawn prompt.** Main thread reads `docs/fabric-toolkit/upstream/skills/<name>/SKILL.md` (plus any needed resources) and passes the relevant excerpts into the Agent prompt as context. Best when the task maps cleanly to one skill.
  2. **Have the subagent Read the SKILL.md path directly.** Subagents retain file tool access; instruct the agent in its spawn prompt to `Read docs/fabric-toolkit/upstream/skills/e2e-medallion-architecture/SKILL.md` as step 1 before designing. Cheapest option, works for any skill, costs one Read call per skill.
  3. **Do the skill-heavy work on the main thread.** Invoke the skill via the Skill tool on the main thread, then delegate only the specialized judgement calls to the fabric subagent. Best when the skill content is large and the subagent only needs narrow input.
- **Downstream:** All fabric-invocation patterns in this repo — `/om-exec` waves, quality gates, review escalations — need to adopt one of the workarounds by default. Strong preference: add a standard instruction block to fabric-agent spawn prompts that tells the agent "before you design, Read `docs/fabric-toolkit/upstream/skills/<relevant-skill>/SKILL.md` — it exists on disk but is not auto-loaded into your context." This is a one-line repeatable pattern and preserves the subtree-sync purity (no upstream edits).

#### Fabric agents use PascalCase role names in Claude Code's agent roster
- The `FabricDataEngineer` and `FabricAdmin` agents are listed with the original upstream casing even though the `.claude/agents/` symlinks are kebab-case (`fabric-data-engineer.md`, `fabric-admin.md`). Claude Code reads the `name:` field from the YAML frontmatter, not the filename. This is a cosmetic mismatch, not a bug.
- **Downstream:** When spawning via the `subagent_type` parameter of the Agent tool, use `FabricDataEngineer` / `FabricAdmin` (the frontmatter `name`), not the filename. Also: if a future wave-executor or router keys off kebab-case conventions, it may need a casing-normalization shim or a name-alias map.

### Assumptions Validated

- **[Fabric toolkit pattern]** Symlink-based wiring from `.claude/` into `docs/fabric-toolkit/upstream/` works end-to-end for Claude Code's agent discovery — confirmed by successful FabricDataEngineer spawn and quality of generated straw-man. The previous session asserted this structurally; this session proved it functionally.

### Assumptions Invalidated

- **[Implicit assumption]** "Fabric skills will auto-load inside spawned fabric agents because the agent manifests list them under `delegates_to:`" — **invalidated**. Skills are a main-thread concept. Requires an explicit workaround pattern documented above.

### Open Questions

8. Does Claude Code have a supported way to pre-register a skill into a subagent's context at spawn time, or is inlining / Read-based loading the only option? Worth a quick check of Claude Code docs before adopting the workaround as permanent.
9. Should `/om-exec` and `/om-plan` be extended to (a) recognize fabric-tagged tasks and route them to `FabricDataEngineer` / `FabricAdmin`, and (b) inject the relevant skill content automatically via the workaround pattern? If yes, the tagging convention in `docs/plans/*.md` needs a `fabric-skill:` field.
10. Should the project `CLAUDE.md` be updated to tell spawned Claude Flow agents (`coder`, `reviewer`, `tester`) that the fabric toolkit exists on disk under `docs/fabric-toolkit/upstream/` and can be consulted by direct file read for any Fabric-adjacent work? Without this, generic agents will reinvent Fabric patterns instead of leveraging Microsoft's first-party knowledge. **Resolved 2026-04-10 in integration hardening phase — yes, section added to CLAUDE.md.**

---

## 2026-04-10 — Pre-Kickoff: Fabric Toolkit Integration Hardening
**Phase context:** Follow-on to the 2026-04-10 verification session. Addressed the three concrete interop gaps discovered during verification: (1) skill visibility is main-thread only, (2) generic Claude Flow agents unaware of the fabric toolkit, (3) MANIFEST.md lacked an agent-facing routing preamble.
**Plan:** `plans/2026-04-10-fabric-toolkit-integration-hardening.md`

### Discoveries

#### The MANIFEST-first + SKILL.md-read workaround is validated — dramatically improves spawned agent output
- **Method:** Spawned `FabricDataEngineer` twice with comparable scope design tasks. Baseline (earlier session): blind spawn, no skill access, wide WideOrbit medallion design. Test spawn (this session): narrower Bronze→Silver SCD2 merge design with explicit instructions to Read `docs/fabric-toolkit/MANIFEST.md` then the relevant `SKILL.md` file(s) before designing.
- **Test spawn verified file reads explicitly.** The agent reported in its output header: `MANIFEST.md`, `e2e-medallion-architecture/SKILL.md`, `spark-authoring-cli/SKILL.md`, `spark-authoring-cli/resources/data-engineering-patterns.md`. Usage stats show 5 tool uses — consistent with 4 file reads + 1 response generation.
- **Output quality delta is not subtle.** Test spawn produced: full PySpark MERGE pseudocode (not in baseline), concrete business-key derivation using `sha1`/`xxhash64`/`sha2` (not in baseline), two-pass SCD2 expire-then-insert logic with explicit reasoning for why single-MERGE doesn't work atomically (not in baseline), watermark strategy via a Delta control table (not in baseline), within-batch deduplication via window function (not in baseline), 5 pre-merge + 3 post-merge quality gates with severity tiers (baseline only named a handful), refined quarantine design (single table with gate-level tagging, with explicit reasoning why that's better than per-entity), and 7 specific WideOrbit-behavior open questions for kickoff (baseline had 5 generic ones).
- **The test spawn explicitly referenced skill content to justify design choices**, e.g. "the `e2e-medallion-architecture` skill explicitly calls out schema enforcement, partition-aware overwrite, and post-write OPTIMIZE as Silver-layer non-negotiables" and "`data-engineering-patterns.md` is opinionated that MERGE is the right tool for SCD2." The test spawn also refined two straw-man decisions (quarantine structure, liquid clustering vs Z-ORDER) with reasoning drawn from the skill content — meaning the skill actually changed the design, it didn't just decorate it.
- **Downstream:** The workaround is now the canonical invocation pattern for fabric agents in this repo and is documented in three places: `CLAUDE.md` (as the general directive for all spawned agents), `docs/fabric-toolkit/MANIFEST.md` (as the "For agents" preamble), and `docs/fabric-toolkit/README.md` (with full reasoning, three workaround options, and an example spawn prompt). Default to option 1 (subagent reads SKILL.md directly); use option 2 (inline skill content) when avoiding the read round-trip matters; use option 3 (main-thread skill invocation) when the skill is large and the subagent only needs narrow input.

#### The straw-man baseline has been superseded by the skill-loaded design for Silver merge specifics
- The WideOrbit straw-man in `docs/plans/2026-04-10-wideorbit-medallion-strawman.md` remains a valid high-level pre-kickoff design, but for the specific Bronze→Silver SCD2 merge pattern for `spots`, the skill-loaded test spawn output is the more authoritative reference. Key refinements to carry forward when we're actually building this: liquid clustering over Z-ORDER (where Fabric runtime supports it), single quarantine table with `_gate_name`/`_gate_severity` tagging, two-pass SCD2 (expire then insert) rather than trying to do it in one MERGE, and WideOrbit-specific dedup-within-batch because the source can re-emit the same spot multiple times in one export.
- **Downstream:** When Design phase formally starts (after kickoff), the skill-loaded output from this session should be re-run against updated context (client-confirmed WideOrbit specifics, finalized workspace layout) and promoted into `docs/plans/` as a proper design doc. Until then, it lives in conversational context as a richer reference alongside the straw-man.

#### MANIFEST.md is the correct routing entry point, not individual SKILL.md files
- The initial instinct was to point agents at specific SKILL.md files. The correct pattern is to point agents at MANIFEST.md first and let the agent decide which SKILL.md files to Read based on its task. This preserves judgment at the agent level and handles the common case where multiple skills are load-bearing (e.g. the test spawn Read both `e2e-medallion-architecture` and `spark-authoring-cli` plus one `resources/` file — a decision the main thread couldn't have pre-computed without knowing the exact task shape).
- **Downstream:** Any future toolkit addition or curation update must maintain MANIFEST.md as the single, agent-readable routing index. Polish #1 from the MANIFEST.md spot check (the "For agents" blockquote preamble) is the mechanism that makes MANIFEST's role explicit inside the file itself.

### Assumptions Validated

- **[Workaround pattern]** The MANIFEST-first + SKILL.md-read pattern is canonical — validated via direct comparison test. Default pattern for all future fabric agent spawns in this repo.
- **[MANIFEST as routing index]** The curation overlay's purpose-built role as an agent-facing routing index (not just human documentation) is validated. The preamble makes this explicit.

### Assumptions Invalidated

- None this session. (The previous entry's invalidation of "skills auto-load into subagents" stands and was the driver for this workstream.)

### Open Questions

- No new open questions from this workstream. Questions 8–10 from the previous verification entry are now all addressed (8 tracked to future session, 9 deferred as explicit out-of-scope, 10 resolved by CLAUDE.md edit).

### Work Completed (plan checklist)

- [x] T1 — Fabric Toolkit section added to `CLAUDE.md` (appended after Support section)
- [x] T2 — "For agents" blockquote preamble added to `docs/fabric-toolkit/MANIFEST.md`
- [x] T3 — "Invocation patterns" section added to `docs/fabric-toolkit/README.md` with three workaround options + example spawn prompt
- [x] T4 — Verification spawn completed with explicit file-read confirmation; workaround validated
- [x] T5 — `docs/brief.md` Pre-Kickoff Workstreams table updated, workstream 3 marked Complete
- [x] T6 — This discovery-log entry (you are reading it)

### Meta-discovery: the fabric toolkit is a proof of concept for a general Skill Locker pattern

After validating the MANIFEST-first invocation pattern against the fabric toolkit, it became clear the same five-part structure generalizes well beyond fabric-specific content. The scaffold — content store + curation index + invocation protocol + entry-point signal + optional specialized agents — has no fabric-specific assumptions baked into it. Swap the content store and the curation index, and the same pattern works for any dense, progressively-disclosed knowledge domain: other cloud platforms, industry/domain knowledge, internal codebase knowledge, team delivery patterns, project-local historical context, or anything else that is too dense to inline in a system prompt and too stable to generate on demand.

**Three separation principles** for deciding what belongs in one locker vs separate lockers: (1) separate by provenance and update cadence — one locker per upstream source, treating "yourself" as an upstream source; (2) separate by scope — global vs domain vs project-local; (3) separate by trust and licensing — locker boundaries must align with git boundaries and sharing boundaries.

**Captured as a portable pattern doc** at `docs/SKILL-LOCKER-PATTERN.md` in this repo. The doc is intentionally self-contained and instance-agnostic — no t3-hearst or fabric references — so it can be dropped into any other repo verbatim. It has been surfaced in seven non-sibling freelance projects outside the t3-hearst engagement so the pattern is immediately available there (see list below). The companion fabric-specific teaching doc at `docs/fabric-toolkit/PATTERN.md` remains unchanged and continues to describe the fabric instance in concrete detail; the new SKILL-LOCKER-PATTERN.md is the abstraction layer above it.

**Projects where the pattern doc has been surfaced (2026-04-10):**
- `/Users/kmgdev/dev_projects/t3-hearst/docs/SKILL-LOCKER-PATTERN.md` (home)
- `/Users/kmgdev/KGiQ-LLC/docs/SKILL-LOCKER-PATTERN.md`
- `/Users/kmgdev/dev_projects/portfolio-front-end/docs/SKILL-LOCKER-PATTERN.md`
- `/Users/kmgdev/dev_projects/booking-module/docs/SKILL-LOCKER-PATTERN.md`
- `/Users/kmgdev/dev_projects/open-mind/docs/SKILL-LOCKER-PATTERN.md`
- `/Users/kmgdev/dev_projects/iq-publish/docs/SKILL-LOCKER-PATTERN.md`
- `/Users/kmgdev/dev_projects/artemis-intel/docs/SKILL-LOCKER-PATTERN.md`
- `/Users/kmgdev/dev_projects/upwork/docs/SKILL-LOCKER-PATTERN.md`

**Open exploration parked for another session:** Does the skill locker itself want to live globally — in a dedicated repo, or a shared directory that multiple projects reference — rather than being copied per-project? The tradeoffs are roughly **self-containment vs curation leverage**. Per-project wins on simplicity, onboarding, trust, and offline self-sufficiency. Global wins when the same domain locker is consumed by many projects and curation effort gets duplicated, or when a pattern improvement in one project should propagate automatically. Hybrid possibilities exist: global store with per-project stubs, git-subtree cherry-picks, or CLI-level indirection. Worth exploring dedicated when the locker count grows beyond two or three instances. Until then, per-project copies are fine and the answer is "don't decide yet." This exploration question is captured in the provenance-footer section of every SKILL-LOCKER-PATTERN.md copy, so it travels with the pattern wherever it goes.

**Downstream:** When a new knowledge domain emerges in any of the listed projects that matches the "dense + stable + reused" criteria in the pattern doc, the shape to build is already documented locally. The pattern doesn't need to be re-derived. Over time, if two projects instantiate the same kind of locker (say, both KGiQ-LLC and portfolio-front-end want a "web framework conventions" locker), that is the signal to revisit the global-hosting question.
