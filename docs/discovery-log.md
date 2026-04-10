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
