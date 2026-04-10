# t3-hearst — Project Brief

## Overview

Hearst Television **Data Modernization Phase 2** (SOW2), delivered by Trace3 under a **DTaaS** (Data Transformation as a Service) model. Builds on a completed MVP (SOW v7.0, Jan 8 – Apr 9, 2026) that delivered an initial Microsoft Fabric environment and an AI-powered Pacing dashboard for sales forecasting. Phase 2 completes the platform modernization, retires legacy Decentrix, and expands the Fabric AI Agent framework across Sales, Finance, and Ad Ops.

This is a **build, not a migration**.

- **Timeline:** April 15 – December 31, 2026 (~34 weeks)
- **Hard external deadline:** January 1, 2027 — Decentrix vendor sunset
- **Budget:** $772,320 estimated (T&M)
- **My role:** Data engineering (virtual)
- **Client sponsor:** Dilip Jayavelu, Senior Director of Business Intelligence (HTV-IQ)
- **Trace3 Services Solutions Manager:** Josh Ruyle
- **Account Manager:** Gemma Francis

Full SOW references: [`docs/sow/sow-v2-20260406.md`](sow/sow-v2-20260406.md) (Phase 2, current), [`docs/sow/sow-v7-20251118.md`](sow/sow-v7-20251118.md) (MVP, context).

## Phase Tracker

### SOW Structure (from SOW v2.0)

| Phase | Status | Dates | Notes |
|-------|--------|-------|-------|
| Plan | Not started | Apr 15 – ~Apr 22, 2026 | 1 week. Kickoff in Charlotte Apr 13–15. |
| Discovery | Not started | ~Apr 22 – Apr 29, 2026 | 1 week. Current-state assessment of Decentrix, WideOrbit ETL, PBI assets, MVP Fabric env. |
| Design | Not started | ~Apr 29 – May 6, 2026 | 1 week. Future-state Lakehouse, CI/CD, PBI governance, AI Agent domain model. |
| Execute | Not started | ~May 6 – Dec 24, 2026 | 30 weeks. DTaaS capacity against roadmap initiatives. |
| Closure | Not started | ~Dec 24 – Dec 31, 2026 | 1 week. UAT, docs, KT, hypercare. |

### HTV-IQ Roadmap Deliverables (what Execute capacity targets)

| Quarter | Deliverable | Description |
|---------|-------------|-------------|
| Q2 2026 | D1a | Alpha → Beta launch (10 → 500 → 1000 users) + historical data |
| Q2 2026 | D1b | Data load freq daily → every 30 minutes |
| Q3 2026 | D2 | Inventory & Inbound |
| Q3 2026 | D3 | Billing (Terri) and Compensation |
| Q3 2026 | D4 | Outbound |
| Q3 2026 | D5 | GCS Integration |
| Q3 2026 | D6 | Sales AI Agents |
| Q3 2026 | D7 | Ad Ops Agent |
| Q3 2026 | D8a | Finance Forecasting (yearly, monthly, weekly) |
| Q3 2026 | D8b | Forecasting accessible via Power BI + Data Agent |
| Q4 2026 | D9 | Anomaly detection + make-good optimization |
| Q4 2026 | D10 | Revenue signals + inventory management ML models |
| Q4 2026 | D11 | Churn / opportunity scoring / prioritization models |
| Jan 1, 2027 | **Decentrix sunset** | **Hard external deadline — vendor fully retired** |

## Assumptions Registry

| ID | Assumption | Status | Source / Validated |
|----|-----------|--------|-------------------|
| A1 | "Wide Open" is actually **WideOrbit** | **Confirmed** | SOW v7.0 §2.1.1 |
| A2 | Microsoft Fabric (Lakehouse) is the target platform | **Confirmed** | SOW v2.0 §2.1, §2.2 |
| A3 | Medallion architecture is the agreed pattern | Assumed | Stated in README intent; not explicit in SOW language — confirm at Design |
| A4 | Decentrix decommission happens during SOW2 Execute | **Confirmed** | SOW v2.0 Execute initiative menu |
| A5 | DEV/TEST/PROD + CI/CD is in scope | **Confirmed** | SOW v2.0 §2.1, §2.2 |
| A6 | AI expansion uses Azure OpenAI + Fabric AI Agent framework | **Confirmed** | SOW v2.0 §2.2 |
| A7 | Sunset deadline (Jan 1, 2027) is an external business driver — not a contractual SOW date | **Open** | SOW End Date is Dec 31, 2026; confirm sequencing at kickoff |
| A8 | Client (HTV-IQ) owns LLM provisioning/licensing | **Confirmed** | SOW v2.0 Assumptions |
| A9 | "TWINS" = internal DTaaS role label (meaning TBD) | **Open** | Flag for kickoff clarification |

## Design Rebase Queue

- [ ] Clarify sunset-vs-closure sequencing (A7) — must hypercare complete before Jan 1, 2027?
- [ ] Get current-state of MVP Fabric environment (hand-off deliverable from SOW v7.0)
- [ ] Inventory MVP Power BI assets — MVP capped new dashboards at 3 legacy pages; confirm what exists
- [ ] Clarify "TWINS" / DTaaS operating model and sprint cadence
- [ ] Design medallion architecture (bronze/silver/gold boundaries) — confirm this is the agreed pattern during Design Phase
- [ ] Define AI Agent domain model expansion scope (Sales / Finance / Ad Ops)
- [ ] Map D1–D11 roadmap initiatives to Execute phase capacity allocation
- [ ] Individual tracking artifacts for D1–D11 deliverables

## Stakeholders

### HTV-IQ (Client)
- **SOW2 Sponsor:** Dilip Jayavelu — Senior Director of Business Intelligence
- **MVP Sponsor:** Preman Narayanan — VP, Ad Operations and Info Services
- **Required at kickoff:** Dilip, Hetal, Kushali, Diya, Mark O
- **Optional:** Boyd, Marc Mekler, Billie, John Branco
- **SMEs from:** Sales, Finance, Ad Ops (per SOW assumptions)

### Trace3
- **Account Manager:** Gemma Francis
- **Services Solution Manager (SOW2):** Josh Ruyle
- **Services Solution Manager (MVP):** Leslie Huffman
- **DTaaS team roles:** Data Architect, Data Engineer(s), Data Analyst, Senior PM
- **In-person at kickoff:** Gemma, Jillian, Jaime Tirado, Jean Francois
- **Virtual:** Josh Docken, Jim Haley, Bryce Rippentrop, Ken Graham (me)
- **Optional:** Kevin Rogers

## Location
- Client office: 3540 Toringdon Way, Charlotte, NC 28277
