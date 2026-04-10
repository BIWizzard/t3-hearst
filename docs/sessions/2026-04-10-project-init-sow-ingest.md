# Pre-Kickoff: Project Init + SOW Ingestion — 2026-04-10

**Repo:** t3-hearst
**Branch:** `main`
**Phase:** Pre-Kickoff Setup (SOW kickoff scheduled Apr 13–15, 2026)
**Task(s):** Initialize Open Mind tracking, convert SOWs to markdown, enrich README, embed foundational context into all memory layers

## Session Summary

First working session on the t3-hearst repo following Ken's introductory call for the Hearst Television Data Modernization Phase 2 engagement. Started from a near-empty repo (README + two SOW source documents + a one-off extraction script) and ended with a fully-initialized Open Mind project, foundational context embedded across three memory layers, and a clean git history.

Work was entirely administrative / setup — no code, no architecture decisions. The goal was to set Ken up for success ahead of the Apr 13–15 kickoff in Charlotte, NC by transforming the raw SOW contracts into a structured knowledge base that future Claude sessions (and Ken's own reference use) can query semantically.

Two SOWs were converted from their native formats (PDF via pypdf, docx via pandoc) into clean, readable markdown with "Notes for Ken" sections distilling the operationally-important details. The README was rewritten from scratch to reflect the rich context the SOWs revealed — most notably that the original README conflated the in-flight MVP (SOW v7.0) with the upcoming Phase 2 (SOW v2.0), and that several named entities were wrong or ambiguous.

## What Was Built/Changed

**New documentation:**
- `docs/brief.md` — project brief with phase tracker, assumptions registry (9 items, most confirmed against SOW sections), design rebase queue
- `docs/sow/sow-v7-20251118.md` — MVP SOW (converted from PDF, signed Nov 19 2025, $198,524, Jan 8–Apr 9 2026)
- `docs/sow/sow-v2-20260406.md` — Phase 2 SOW (converted from docx, unsigned, $772,320, DTaaS model, Apr 15–Dec 31 2026)
- `docs/captures.md`, `docs/discovery-log.md`, `docs/open-mind.yaml` — Open Mind scaffolding
- `docs/sessions/`, `docs/plans/` — session and plan directories

**Repo restructure:**
- Moved SOW source documents to `docs/sow/source/` (PDF + docx)
- Moved kickoff agenda to `docs/meetings/source/`
- Deleted `extract_docx.py` (one-off probe script superseded by pandoc)
- Added `.gitignore` covering `.claude/`, `.claude-flow/`, `.swarm/`, `ruvector.db`, `agentdb.rvf*`, `.mcp.json`, `CLAUDE.md`

**README rewrite** — fully replaced with SOW-informed content: MVP vs Phase 2 separation, DTaaS model explanation, corrected stakeholders, D1–D11 roadmap separated from SOW phase structure, repo layout diagram, working notes.

**Memory layers populated:**
- **Neon:** 6 tracked files embedded, 9 chunks total (README 1, brief 1, open-mind.yaml 1, captures 1, sow-v7 1, sow-v2 5)
- **Claude Flow:** 6 entries in `t3-hearst` namespace — `project/overview`, `sow/v7-mvp`, `sow/v2-phase2`, `project/stakeholders`, `project/roadmap-d1-d11`, `project/open-questions`
- **Claude Flow pretrain:** 6 files analyzed, 2 patterns extracted during `/om-init`

## Key Decisions

| Decision | Rationale |
|----------|-----------|
| Gitignore all ruflo boilerplate (`.claude/`, `CLAUDE.md`, `.mcp.json`) | 259 generated files would bury real project diffs in noise; all regeneratable via `npx @claude-flow/cli@latest init` |
| Archive SOW + agenda source docs under `docs/sow/source/` and `docs/meetings/source/` instead of deleting | Root stays clean, originals preserved as the source of truth; markdown versions are what get tracked/embedded |
| Create separate markdown files per SOW rather than a single combined doc | Each SOW has distinct sponsorship, dates, budget, and phase — mixing them loses clarity; cross-reference via `docs/sow/` index structure |
| Rewrite README from scratch rather than edit in place | Original conflated MVP with Phase 2 and had several errors ("Wide Open" → WideOrbit, wrong sponsor, "migration" vs "build") — structural rewrite was cleaner than line-by-line edits |
| Track the markdown SOWs (not the source PDFs/docx) in `open-mind.yaml` | Binary source docs don't embed well; markdown is searchable and the canonical project reference |
| Store SOW facts as separate Claude Flow memory keys (`sow/v7-mvp`, `sow/v2-phase2`) rather than one combined key | Semantic search targets specific questions better when facts are decomposed by concern |

## Discoveries

- **Discovery:** "Wide Open" in the original README was actually **WideOrbit** — confirmed in SOW v7.0 §2.1.1.
  - **Impact:** Resolves assumption A1. All references updated across README, brief, and SOW docs.

- **Discovery:** The MVP (SOW v7.0) and Phase 2 (SOW v2.0) are under **different sponsors and services managers**. MVP was sponsored by Preman Narayanan (VP, Ad Ops) with Leslie Huffman as SSM. Phase 2 is sponsored by Dilip Jayavelu (Sr Dir BI) with Josh Ruyle as SSM.
  - **Impact:** Different accountability chains. Phase 2 reports to the BI org, not Ad Ops — may affect prioritization and stakeholder alignment for D1–D11 deliverables. Worth understanding why the handoff happened.

- **Discovery:** SOW v2 is structured as **DTaaS** (Data Transformation as a Service) under an internal label **"DA TWINS"**. 30 of 34 weeks are Execute phase — nearly the entire engagement is **elastic capacity** pointed at a rolling initiative menu, not fixed-scope deliverables.
  - **Impact:** Ken's work will be demand-driven, not plan-driven. D1–D11 roadmap items are suggestions that Execute capacity targets, not contractual commitments. "TWINS" acronym origin is unknown and flagged for kickoff clarification.

- **Discovery:** MVP dashboard scope was **capped at 3 legacy dashboard pages** of medium-to-high complexity (SOW v7.0 §2.2.3 Phase 4).
  - **Impact:** Phase 2 PBI modernization can't assume extensive MVP dashboard inventory to carry forward — Discovery phase dashboard audit will likely surface a smaller baseline than the team might assume.

- **Discovery:** SOW v2 End Date is **December 31, 2026**, but the business-driver Decentrix sunset is **January 1, 2027**. These are tight adjacents with no buffer.
  - **Impact:** Unclear whether hypercare/closure must complete before sunset or can run in parallel with the vendor shutdown. Flagged for kickoff.

- **Discovery:** SOW v2 T&E is billed at **$2,500/week/resource with no stated ceiling** in the fee table — unlike MVP which capped T&E at $10,000 total.
  - **Impact:** Phase 2 T&E could substantially exceed expectations over 34 weeks if onsite presence is frequent. Worth tracking.

## Assumptions Validated/Invalidated

- **[A1]** "Wide Open" is actually WideOrbit: **VALIDATED** — SOW v7.0 §2.1.1
- **[A2]** Microsoft Fabric (Lakehouse) is the target: **VALIDATED** — SOW v2.0 §2.1, §2.2
- **[A3]** Medallion architecture is the agreed pattern: **UNCHANGED** — not explicit in SOW language; confirm at Design phase
- **[A4]** Decentrix decommission is inside SOW2 Execute: **VALIDATED** — SOW v2.0 Execute initiative menu
- **[A5]** DEV/TEST/PROD + CI/CD is in scope: **VALIDATED** — SOW v2.0 §2.1, §2.2
- **[A6]** AI uses Azure OpenAI + Fabric AI Agent framework: **VALIDATED** — SOW v2.0 §2.2
- **[A7]** Decentrix Jan 1 2027 sunset is an external business driver (not a contractual SOW date): **OPEN** — confirmed SOW end is Dec 31 2026; sequencing TBD
- **[A8]** Client owns LLM provisioning/licensing: **VALIDATED** — SOW v2.0 Assumptions §2.7
- **[A9]** "TWINS" acronym meaning: **OPEN** — flagged for kickoff

## Problems & Solutions

| Problem | Resolution |
|---------|------------|
| PDF read via `Read` tool failed — `pdftoppm` / poppler not installed | Installed `pypdf` into Open Mind venv and extracted via Python — fast and avoids a system-level dependency |
| Pandoc docx conversion produced cluttered output (`{.smallcaps}`, pipe-table artifacts, image refs) | Used pandoc for initial extraction, then rewrote the markdown from scratch into a cleaner structure — salvaged all facts, discarded formatting noise |
| ruflo `init` generated 259 files of boilerplate (98 agents + 30 skills + CLAUDE.md) that would dominate git diffs | Gitignored the lot — fully regeneratable from `npx @claude-flow/cli@latest init` |
| CLAUDE.md generated by ruflo init contained no project-specific content | Gitignored with the rest of the boilerplate |
| Claude Flow memory wrote `agentdb.rvf` + `.lock` files to repo root as untracked runtime state | Added to `.gitignore` alongside `ruvector.db` |

## Open Questions

1. What does "TWINS" (DA TWINS) stand for in the DTaaS delivery model? — Clarify at kickoff.
2. Must the Dec 31 2026 SOW closure complete before the Jan 1 2027 Decentrix sunset, or can they run in parallel? — Clarify at kickoff.
3. Why did sponsorship shift from Preman Narayanan (Ad Ops) to Dilip Jayavelu (BI) between MVP and Phase 2? Any org-political implications?
4. What is the actual state of the MVP Fabric environment as handed off from SOW v7 delivery? — KT deliverable during Apr 13–15 kickoff.
5. What Power BI assets actually exist from the MVP (capped at 3 pages)? — Informs Discovery phase dashboard audit.
6. Is "medallion architecture" the agreed internal pattern or just Ken's working assumption? — Confirm at Design phase.
7. How is the D1–D11 roadmap prioritized against the Execute phase monthly capacity envelope (160 DE/DA + 20 Architect)?

## Tracked Files Changed

- `README.md` — full rewrite with SOW-informed context
- `docs/brief.md` — new (phase tracker, assumptions registry, rebase queue)
- `docs/captures.md` — new + timestamped foundational capture entry
- `docs/discovery-log.md` — new (stub)
- `docs/open-mind.yaml` — added SOW markdowns to tracked_files, removed CLAUDE.md
- `docs/sow/sow-v7-20251118.md` — new (MVP SOW converted from PDF)
- `docs/sow/sow-v2-20260406.md` — new (Phase 2 SOW converted from docx)

## Next Steps

1. Prepare for Apr 13–15 kickoff in Charlotte — virtual attendance. Review this repo's `docs/brief.md` and both SOW markdowns as pre-read.
2. During kickoff: resolve Open Questions 1, 2, 3, 4 above.
3. During/after kickoff: set up `docs/plans/` entries for D1a and D1b (the Q2 2026 deliverables).
4. After MVP KT: create a `docs/discoveries/mvp-fabric-env.md` or equivalent capturing actual MVP Fabric state.
5. Build personal tracking for D1–D11 deliverables that maps them to DTaaS monthly capacity.

## Continuation Prompt

> Continue the t3-hearst project — Hearst Television Data Modernization Phase 2 engagement.
>
> **Last session recap:** Completed Open Mind project initialization, converted both SOWs (v7.0 MVP and v2.0 Phase 2) to markdown with clean structure, rewrote the README with SOW-informed context, and embedded foundational facts across Neon and Claude Flow memory layers. All work committed to `main` in commits `cbbc330` and `dbb1f64`.
>
> **Priority:** Prepare for the Apr 13–15 2026 SOW kickoff in Charlotte, NC (virtual attendance). Review `docs/brief.md` and both SOW markdowns as the pre-read; draft a list of clarifying questions pulled from the 7 open questions in the session log.
>
> **Key context:**
> - This is a **build, not a migration**. Decentrix decommission is in the Execute phase.
> - **DTaaS model** — 160 hrs/month DE/DA + 20 hrs/month Architect, Client-directed against a rolling initiative menu. Not fixed-scope.
> - **Hard deadline:** Jan 1 2027 Decentrix sunset (external business driver, not a contractual SOW date — SOW v2 ends Dec 31 2026).
> - **Sponsors differ:** MVP = Preman Narayanan (Ad Ops), Phase 2 = Dilip Jayavelu (BI). Different accountability.
> - **"TWINS"** internal label is unexplained — clarify at kickoff.
> - **WideOrbit** (not "Wide Open") is the primary data source from the MVP.
>
> **Brief:** Read `docs/brief.md` for full project context, phase tracker, and assumptions registry.
