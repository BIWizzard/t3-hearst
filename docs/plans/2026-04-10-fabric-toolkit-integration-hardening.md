# Fabric Toolkit Integration Hardening

**Date:** 2026-04-10
**Phase:** fabric-toolkit-hardening (Pre-Kickoff Workstream 3)
**Owner:** Ken
**Status:** Approved, ready to execute

## Context

The 2026-04-10 fabric toolkit verification session confirmed the symlink-based wiring works structurally and that `FabricDataEngineer` produces quality output when spawned directly. But the session surfaced three concrete interop gaps between the fabric toolkit and Claude Flow / Ruflo / project execution infrastructure:

1. **Skill visibility is main-thread only.** Spawned subagents (via the Agent tool) do not inherit the parent session's skill roster. The fabric agents' `delegates_to:` frontmatter is advisory metadata, not a Claude Code loader directive. Skills must be accessed via file Read from within subagents.
2. **Generic Claude Flow agents (`coder`, `reviewer`, `tester`) don't know the fabric toolkit exists.** Without an explicit signal in project `CLAUDE.md`, they'll reinvent Fabric patterns instead of leveraging Microsoft's first-party knowledge.
3. **MANIFEST.md reads as human documentation, not as an agent routing index.** Missing an explicit "how to use this file" preamble that tells an agent exactly what to do with it.

This plan addresses all three gaps via small, well-scoped doc edits plus a validation spawn. It explicitly defers the bigger infrastructure changes (extending `/om-plan` and `/om-exec` vocabulary, adding a fabric review checklist, seeding intelligence patterns) until we're doing real Fabric work and the need is concrete.

## Goals

- Make the fabric toolkit discoverable and usable by every spawned agent, not just fabric agents
- Standardize the "Read MANIFEST.md → Read SKILL.md" workaround as the canonical invocation pattern
- Polish MANIFEST.md for agent self-service
- Validate the workaround via a comparison spawn test before committing to it as the pattern
- Leave a clean trail on the brief and discovery log so the work is visible to future sessions

## Scope

### In scope
- Edits to `CLAUDE.md`, `docs/fabric-toolkit/MANIFEST.md`, `docs/fabric-toolkit/README.md`
- Verification spawn of `FabricDataEngineer` with the new invocation pattern
- Brief update (mark hardening workstream complete)
- Discovery log entry capturing validation outcome

### Out of scope (deferred with rationale)
- **Extending `/om-plan` and `/om-exec` vocabulary** to natively recognize `FabricDataEngineer`/`FabricAdmin` and a `fabric-skill:` tag. Requires framework-level edits to those skill files. Defer until we have two or more tagged fabric plans and the repetition cost justifies the abstraction.
- **MANIFEST.md Path column (Polish #2 from spot check).** Skill name → path is reliably inferrable. Not load-bearing.
- **`docs/fabric-toolkit/REVIEW-CHECKLIST.md`** for fabric-specific review semantics (V-Order, RLS, Direct Lake, SCD2 correctness). Defer until we're reviewing real notebook code, at which point the real failure modes will shape the checklist.
- **Seeding intelligence router patterns** with fabric signals via `pattern-store`. Let them accumulate organically from real task routing.
- **Kebab ↔ PascalCase name alias map** as a standalone artifact. Fold the explanation into the CLAUDE.md Fabric Toolkit section as a single note; don't build a dedicated structure for it.

## Tasks

### Task 1: Add Fabric Toolkit section to `CLAUDE.md`

- **Wave:** 1
- **Agent:** coder
- **Complexity:** low
- **Model:** haiku
- **Depends on:** none
- **Parallel:** yes
- **Quality gate:** tests + spec-review + code-review
- **Files:** CLAUDE.md

**Deliverable:** New section in project `CLAUDE.md` (appended at the end, after the "Support" section) covering:
- What the fabric toolkit is and where it lives (`docs/fabric-toolkit/upstream/`)
- The MANIFEST-first + SKILL.md-read invocation pattern
- Why skills aren't auto-loaded in subagents (one-line explanation; point at discovery-log for depth)
- PascalCase (`FabricDataEngineer`, `FabricAdmin`) vs kebab-case filename note — use the frontmatter name when invoking
- Fresh-clone bootstrap note: run `scripts/fabric-toolkit-wire.sh` to recreate `.claude/` symlinks

**Acceptance:** Section is under 40 lines, a fresh `coder` agent reading only CLAUDE.md can correctly decide whether a task needs fabric toolkit content and how to access it.

### Task 2: Add "For agents" preamble to `docs/fabric-toolkit/MANIFEST.md`

- **Wave:** 1
- **Agent:** coder
- **Complexity:** low
- **Model:** haiku
- **Depends on:** none
- **Parallel:** yes
- **Quality gate:** tests + spec-review + code-review
- **Files:** docs/fabric-toolkit/MANIFEST.md

**Deliverable:** 4-6 line blockquote at the top of MANIFEST.md telling agents to: (1) scan Agents and Skills tables for active rows matching task, (2) Read the corresponding `SKILL.md` from `docs/fabric-toolkit/upstream/skills/<name>/SKILL.md`, (3) skip dormant rows unless their promote-when trigger is met, (4) skip MCP / upstream-docs / compatibility sections entirely.

**Acceptance:** Preamble is visible before the first heading, reads as an instruction to an agent, doesn't duplicate content already in the tables below.

### Task 3: Add "Invocation Patterns" section to `docs/fabric-toolkit/README.md`

- **Wave:** 1
- **Agent:** coder
- **Complexity:** low
- **Model:** haiku
- **Depends on:** none
- **Parallel:** yes
- **Quality gate:** tests + spec-review + code-review
- **Files:** docs/fabric-toolkit/README.md

**Deliverable:** New section in README.md documenting the MANIFEST-first workflow for both humans and agents. Explains:
- Why skills aren't auto-loaded into subagents (the discovery from verification session)
- The three workarounds (inline in spawn prompt, subagent Read SKILL.md, main-thread skill invocation)
- Which one to default to (subagent Read SKILL.md) and why
- One concrete example of a fabric-agent spawn prompt with the MANIFEST-first instruction

**Acceptance:** A fresh reader of README.md can spawn `FabricDataEngineer` correctly on their first try.

### Task 4: Verification spawn of `FabricDataEngineer` with MANIFEST-first instruction

- **Wave:** 2
- **Agent:** researcher
- **Complexity:** medium
- **Model:** sonnet
- **Depends on:** Task 1, Task 2, Task 3
- **Parallel:** no
- **Quality gate:** tests + spec-review
- **Files:** (evaluation task — spawns FabricDataEngineer and reads SKILL.md files, no direct writes)

**Method:**
- Pose a narrower design question than the WideOrbit straw-man — specifically: "Design the Bronze → Silver merge pattern for WideOrbit `spots` with SCD Type 2, including the quality gates" — so the `e2e-medallion-architecture` and `spark-authoring-cli` skills are directly load-bearing.
- Spawn with explicit instruction: "Before designing, Read `docs/fabric-toolkit/MANIFEST.md` to see what's available, then Read the relevant `SKILL.md` file(s) for this task."
- Compare output to the WideOrbit straw-man (the blind-spawn baseline from earlier this session, `docs/plans/2026-04-10-wideorbit-medallion-strawman.md`).

**Evaluation criteria:**
- Does the agent actually Read the files it's told to? (Check tool use.)
- Does the output contain skill-specific concepts that weren't in the agent's embedded knowledge?
- Is the output meaningfully more detailed or better-grounded than the blind baseline?

**Acceptance:**
- If validated: document workaround as canonical in discovery-log; update the T1–T3 docs if the verification surfaces refinements.
- If not validated: root-cause why (agent ignored the instruction? Skill file format too dense? Task didn't need the skill?) and decide next action — possibly switch to "inline the skill content in the spawn prompt" as the default pattern instead.

### Task 5: Update `docs/brief.md` phase tracker

- **Wave:** 3
- **Agent:** coder
- **Complexity:** low
- **Model:** haiku
- **Depends on:** Task 4
- **Parallel:** yes
- **Quality gate:** tests + spec-review + code-review
- **Files:** docs/brief.md

**Deliverable:** Mark this workstream (Pre-Kickoff Workstream 3, `fabric-toolkit-hardening`) **Complete** in the Pre-Kickoff Workstreams table.

**Acceptance:** Brief reflects the completed hardening workstream with a date stamp.

### Task 6: Append outcomes to `docs/discovery-log.md`

- **Wave:** 3
- **Agent:** coder
- **Complexity:** low
- **Model:** haiku
- **Depends on:** Task 4
- **Parallel:** yes
- **Quality gate:** tests + spec-review + code-review
- **Files:** docs/discovery-log.md

**Deliverable:** New entry under the 2026-04-10 Fabric Toolkit Verification section (or a new sibling entry) covering:
- Validation result from Task 4 (worked / partially worked / didn't work + why)
- Any new discoveries surfaced during the edits in Tasks 1–3
- Any gaps now revealed that should become open questions for future sessions

**Acceptance:** Discovery-log entry is self-contained enough that a future session can understand the integration pattern without re-reading the plan.

## Quality Gates

- **Pre-Wave 2 gate:** After Tasks 1–3 land, do a fast read-through of the three edits to confirm they're internally consistent and don't contradict each other. (The SKILL.md-read workaround should be described the same way in all three places, or each should reference the canonical location.)
- **Post-Wave 2 gate:** Task 4 result determines whether Wave 3 writes "workaround validated" or "workaround needs revision." Do not skip to Tasks 5/6 without this determination.
- **Final gate:** Brief phase marked complete only after all 6 tasks + both gates pass.

## Risk / Watch items

- **Task 4 may produce an ambiguous result.** The agent might Read the files but produce output no better than the baseline — in which case the workaround "works mechanically but doesn't help." That's a legitimate outcome; it would mean the fabric skills' real value is main-thread invocation and subagents should only be used when they don't need the skill content. Document either way.
- **CLAUDE.md edits are load-bearing.** A future session picks up from this file as authoritative context. If the fabric section is wrong or inconsistent, it will mislead every spawned agent. Review before committing.
- **MANIFEST.md and README.md are project-specific overlay files**, not upstream. Safe to edit. No sync conflicts.

## Execution notes

Given the small size of all edits (no task exceeds ~40 lines of doc content), this plan does not need to run through `/om-exec`'s full wave-spawning machinery. Inline execution from the main thread is faster and more reliable. The wave structure here is for traceability and sequencing, not parallelism.

Tasks 1–3 can be batched as a single multi-edit operation. Task 4 is one Agent tool call. Tasks 5–6 are a single edit each. Total expected: 5 tool calls for execution, 1 for final verification read.
