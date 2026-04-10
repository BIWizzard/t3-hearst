# Hearst Television — Data Modernization Phase 2

**Client:** Hearst Television Inc. (HTV-IQ)
**Engagement:** 02 - 2026 Data Modernization Phase 2 (SOW2, building on a completed MVP)
**Delivery Partner:** Trace3
**My Role:** Data Engineering (virtual)
**SOW Kickoff:** April 13–15, 2026 — Charlotte, NC

## Overview

This repository is my personal working space for tracking and contributing to Hearst Television's **Phase 2 Data Modernization** engagement. Phase 2 builds on a just-completed MVP (Phase 0 / SOW v7.0) that delivered a production-grade Microsoft Fabric environment and an AI-powered Pacing dashboard for sales forecasting.

Phase 2 is a **build, not a migration**: the goal is to complete the full data platform modernization, retire the legacy **Decentrix** vendor before the **January 1, 2027** sunset deadline, and expand conversational AI agent capabilities across Sales, Finance, and Ad Ops.

The engagement is structured as **DTaaS (Data Transformation as a Service)** — a monthly envelope of data engineering, data architecture, data analyst, and PM capacity that the Client directs at a rolling list of prioritized initiatives.

## Background — MVP (Phase 0 / SOW v7.0)

Before Phase 2, Trace3 delivered an MVP sales-forecasting capability:

- **Timeline:** January 8 – April 9, 2026
- **Budget:** $198,524 (T&M)
- **Sources integrated:** WideOrbit, AdBook, Informatica MDM, Dynamics (single query)
- **Delivered:** MVP Pacing dashboard, initial Fabric environment, medallion foundation
- **Client Sponsor:** Preman Narayanan (VP, Ad Operations)

The SOW2 kickoff (April 13–15) doubles as **MVP wrap-up and knowledge transfer** for the incoming Phase 2 team. Full SOW details: [`docs/sow/sow-v7-20251118.md`](docs/sow/sow-v7-20251118.md).

## Phase 2 Scope (SOW v2.0)

### Business Objectives
- **Retire Decentrix** by January 1, 2027 (hard vendor sunset)
- **Expand AI Agents** across Sales, Finance, and Ad Ops domains
- Deliver **self-service analytics** and unified **Power BI** dashboards to business stakeholders

### Technical Objectives
- Complete migration of Decentrix and WideOrbit ETL pipelines into **Microsoft Fabric Lakehouse**
- Establish **DEV / TEST / PROD** environments with **CI/CD**
- Expand the existing **Fabric AI Agent framework** into additional business domains

### In-Scope Technology
- **Microsoft Fabric** — Lakehouse, Pipelines, OneLake
- **Power BI** — dashboards, governance, RLS + AD groups
- **Data sources** — WideOrbit, AdBook, Decentrix (migration source)
- **AI** — Azure OpenAI / Fabric AI Agent framework
- **Governance** — Purview (or Client-preferred tooling)

### Phases & Timeline

| Phase | Duration | Purpose |
|-------|----------|---------|
| Plan | 1 week | Kickoff, governance, team/sprint cadence |
| Discovery | 1 week | Assess Decentrix, WideOrbit ETL, PBI assets, MVP Fabric env |
| Design | 1 week | Future-state Lakehouse, CI/CD, PBI governance, AI Agent domain model |
| **Execute** | **30 weeks** | **DTaaS capacity directed at roadmap initiatives** |
| Closure | 1 week | UAT, documentation, knowledge transfer, hypercare |

**Estimated Start:** April 15, 2026
**Estimated End:** December 31, 2026
**Total Estimated Fee:** $772,320 (T&M)

Full SOW details: [`docs/sow/sow-v2-20260406.md`](docs/sow/sow-v2-20260406.md).

### DTaaS Monthly Envelope (Execute Phase)

- **160 hours/month** — Data Engineering / Data Analyst
- **20 hours/month** — Data Architect
- **Project Management** — as needed
- **Senior PM** — dedicated role on the team

This capacity is pointed at Client-prioritized initiatives; it is **not** a fixed-scope waterfall.

### Execute Phase Initiative Menu

From the SOW, these are the named initiatives the Execute capacity can be directed toward:

- WideOrbit ETL migration to Fabric
- Historical data migration and validation
- Decentrix decommission
- Fabric Lakehouse optimization
- DEV/TEST/PROD environment setup
- Fabric pipeline productionization
- MVP Power BI dashboards moved to PROD
- Unified Power BI views
- Sales AI Agent MVP
- Conversational Q&A Agent build

## HTV-IQ Quarterly Deliverables Roadmap

Separate from the SOW phase structure, the HTV-IQ program tracks quarterly deliverables **D1–D11** that the Execute phase capacity will be directed at:

### Q2 2026
- **D1a** — Alpha → Beta launch (user base 10 → 500 → 1000) + historical data
- **D1b** — Data load frequency increase (daily → every 30 minutes)

### Q3 2026
- **D2** — Inventory & Inbound
- **D3** — Billing (Terri) and Compensation
- **D4** — Outbound
- **D5** — GCS Integration
- **D6** — Sales AI Agents
- **D7** — Ad Ops Agent
- **D8a** — Finance Forecasting (yearly, monthly, weekly)
- **D8b** — Forecasting accessible via Power BI & Data Agent

### Q4 2026
- **D9** — Anomaly detection & make-good optimization
- **D10** — Revenue signals & inventory management ML models
- **D11** — Churn, opportunity scoring & prioritization models

### Hard Deadline
- **January 1, 2027** — Decentrix sunset (no more vendor costs)

## Stakeholders

### HTV-IQ (Client)
- **Client Sponsor (SOW2):** Dilip Jayavelu — Senior Director, Business Intelligence
- **Prior MVP Sponsor (SOW v7):** Preman Narayanan — VP, Ad Operations and Info Services
- **Required for kickoff:** Dilip, Hetal, Kushali, Diya, Mark O
- **Optional:** Boyd, Marc Mekler, Billie, John Branco

### Trace3
- **Account Manager:** Gemma Francis
- **Services Solution Manager (SOW2):** Josh Ruyle
- **Prior Services Solution Manager (MVP):** Leslie Huffman
- **In-person at Charlotte kickoff:** Gemma, Jillian, Jaime Tirado, Jean Francois
- **Virtual:** Josh Docken, Jim Haley, Bryce Rippentrop, Ken Graham
- **Optional:** Kevin Rogers

## Key Locations
- **Client office:** 3540 Toringdon Way, Charlotte, NC 28277
- **Trace3 HQ:** 7505 Irvine Center Drive, Suite 100, Irvine, CA 92618

## Repository Layout

```
docs/
├── brief.md                   Phase tracker, assumptions, design rebase queue
├── captures.md                Quick notes (via /om-cap)
├── discovery-log.md           Cross-phase discoveries (append-only)
├── open-mind.yaml             Open Mind project config
├── plans/                     Design and implementation plans
├── sessions/                  Per-session logs
├── meetings/
│   └── source/                Original meeting materials (agendas, decks)
└── sow/
    ├── sow-v7-20251118.md     MVP SOW (signed, in flight)
    ├── sow-v2-20260406.md     Phase 2 SOW (kickoff Apr 13–15)
    └── source/                Original SOW documents (PDF, docx)
```

## Working Notes

- **"Wide Open"** in early notes was actually **WideOrbit** — confirmed in SOW v7.
- MVP limited new dashboard work to **3 legacy dashboard pages** of medium-to-high complexity. Keep that ceiling in mind when assessing what PBI assets Phase 2 carries forward.
- "TWINS" is the internal label on the DTaaS roles (e.g., "DA TWINS Data Engineer"). Acronym origin TBD — flag at kickoff.
- SOW2 T&E is billed at up to **$2,500/week/resource** with no stated total cap in the fee table — watch this during Execute.
- Decentrix Jan 1, 2027 sunset is the **external business driver**, but SOW2's hard End Date is Dec 31, 2026. Confirm at kickoff whether the hypercare/closure period must complete before the sunset or can run in parallel.

## Open Questions / TODOs
- [ ] Attend SOW kickoff (Apr 13–15, Charlotte, NC) — virtual participation
- [ ] Complete MVP knowledge transfer sessions
- [ ] Clarify "TWINS" acronym and DTaaS operating model
- [ ] Confirm sunset-vs-closure sequencing for Decentrix
- [ ] Get first look at MVP Fabric environment and pipelines
- [ ] Review existing Power BI asset inventory (dashboard audit is a Discovery Phase deliverable)
- [ ] Document detailed requirements and data flows as Discovery progresses
- [ ] Set up personal tracking for D1–D11 deliverables inside the DTaaS cadence
