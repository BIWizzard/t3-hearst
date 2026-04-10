# WideOrbit Medallion Straw-Man — Hearst TV Phase 2

**Status:** Pre-kickoff straw-man (not an approved architecture)
**Date:** 2026-04-10
**Author:** `FabricDataEngineer` agent, prompted in the 2026-04-10 fabric toolkit verification session
**Purpose:** A coherent opinionated sketch to take into the Apr 13–15 kickoff and pressure-test with the client. Intended to provoke discussion, not prescribe.
**Context used:** SOW v2 (Phase 2, DTaaS, 160+20 hrs/mo), WideOrbit as primary upstream, Jan 1 2027 Decentrix sunset, Dilip Jayavelu (BI) as Phase 2 sponsor, CI/CD + DEV/TEST/PROD + PBI governance as priority areas.

---

## 1. Bronze / Silver / Gold layout for WideOrbit

WideOrbit is a broadcast traffic system: **orders → spots → logs → as-run → invoices**, with heavy historical revisioning (a spot can move, preempt, make-good, or re-rate weeks after air). That shape should drive every layer decision. Treat it less like a CRM and more like a slowly-mutating ledger with a strong episodic (air-date) grain.

### Bronze — `lh_bronze_wideorbit`
- **Responsibility:** Land raw WideOrbit exports verbatim. No typing, no joins, no dedup. Immutable, append-only.
- **Granularity:** One Delta table per WideOrbit export feed (`orders_raw`, `spots_raw`, `log_raw`, `asrun_raw`, `invoices_raw`, `traffic_inventory_raw`, plus dim exports: `stations_raw`, `advertisers_raw`, `agencies_raw`, `dayparts_raw`).
- **Partitioning:** `ingest_date` (the date we received the export), NOT air date. Bronze is about arrival, not semantics.
- **Required columns on every table:** `_source_file`, `_ingest_ts_utc`, `_batch_id`, `_row_hash`, `_wo_export_run_id` (if WideOrbit provides one).
- **Delta settings:** V-Order ON, `delta.autoOptimize.optimizeWrite = true`, `delta.autoOptimize.autoCompact = true`. Retention 30 days (VACUUM) — Bronze is cheap insurance, not long-term archive. Raw files parked in a Files section of the lakehouse for 90 days for replayability.
- **Naming:** `bronze_<source>_<entity>_raw`, e.g. `bronze_wideorbit_spots_raw`.

### Silver — `lh_silver_wideorbit`
- **Responsibility:** Conformed, typed, deduped, revision-aware. This is where WideOrbit's historical-revision behavior gets tamed.
- **Granularity:** Entity-grain Delta tables with **SCD Type 2** for anything that revises (spots, orders, rates). `spot_current` (Type 1, latest truth) plus `spot_history` (Type 2, full revision trail) is the pattern I'd push for — BI needs the first, audit/finance reconciliation needs the second.
- **Keys:** Stable business keys from WideOrbit (`wo_spot_id`, `wo_order_id`) + surrogate hash keys for join stability.
- **Partitioning:** `air_date` for spot/log/asrun tables — this is the natural query grain for every downstream report. Orders partition on `order_start_date`.
- **Quality gates before promotion from Bronze:** row counts vs. control totals from the export manifest, null checks on keys, FK existence between spots → orders → advertisers, air-date sanity bounds. Failed batches quarantine to `silver_quarantine_<entity>`, they do NOT block the next batch.
- **Delta settings:** V-Order ON, Z-ORDER on `(station_id, air_date)` for spot/log tables. Liquid clustering is the better bet here if your Fabric runtime supports it at kickoff — check runtime version before committing.

### Gold — `lh_gold_broadcast` (and possibly a second `lh_gold_finance`)
- **Responsibility:** Analytics-ready star schemas and pre-aggregated operational marts. This is the Direct Lake surface for Power BI.
- **Shape:** Classic Kimball. Fact tables: `fact_spot_asrun` (grain: one row per aired spot), `fact_order_line` (grain: one row per order line), `fact_revenue_daily` (grain: station × day × advertiser × daypart). Conformed dimensions: `dim_station`, `dim_advertiser`, `dim_agency`, `dim_daypart`, `dim_date`, `dim_program`.
- **Why two Gold lakehouses may be worth it:** Dilip's BI lens and Preman's Ad Ops lens have different refresh cadences and different RLS surfaces. Splitting `gold_broadcast` (operational, higher refresh) from `gold_finance` (period-locked, slower, tighter RLS) saves you governance headaches later. Not a hill to die on pre-kickoff, but raise it.
- **Delta settings:** V-Order ON (non-negotiable for Direct Lake fallback avoidance), OPTIMIZE nightly, statistics refreshed post-load.

### Naming convention (proposed)
`<layer>_<source>_<entity>[_<variant>]` — e.g. `silver_wideorbit_spot_current`, `gold_broadcast_fact_spot_asrun`. Lowercase, snake_case, no spaces, no dates in table names.

---

## 2. Workspace layout

**Recommendation: four workspaces per environment, three environments.**

```
ws-hearst-ingest-<env>     → Pipelines, Dataflows, Bronze lakehouse
ws-hearst-engineering-<env>→ Notebooks, Silver lakehouse, job definitions
ws-hearst-analytics-<env>  → Gold lakehouse(s), SQL endpoints
ws-hearst-bi-<env>         → Semantic models, Direct Lake reports, apps
```

Three environments: `dev`, `test`, `prod`. **Twelve workspaces total.** Yes, that sounds like a lot. It isn't — it's the minimum that gives you clean deployment pipelines, clean RLS boundaries, and a credible answer when Dilip asks "who can touch production semantic models?"

**Why split engineering from analytics from BI:**
- Deployment pipelines in Fabric operate per-workspace. Splitting BI off means a semantic model hotfix doesn't drag notebook changes with it.
- RLS and AD group permissions land cleanly on the BI workspace without leaking into the lakehouses.
- Gold lakehouse lives in `analytics`, the semantic model in `bi` points at it via Direct Lake. This is the supported pattern and it keeps the "who owns what" story clean for the Jan 1 2027 cutover conversation.

**Shortcut strategy:** Silver → Gold via OneLake shortcuts, not data copies. Bronze → Silver is a real transform so that's a Spark write, not a shortcut.

---

## 3. Ingestion shape

**Recommendation: Pipelines Copy for landing, notebook Spark for everything downstream. No Dataflows Gen2.**

Reasoning:
- **WideOrbit exports, not streams.** That's a scheduled-file-drop pattern. Pipelines Copy Activity is purpose-built for this: parameterized source, landing-zone-to-Bronze, built-in retry, and it plays nicely with Fabric deployment pipelines across dev/test/prod.
- **Bronze → Silver is where the revision logic lives** — SCD2 merges, quarantine routing, quality gates. That is Spark notebook territory, full stop. Dataflows Gen2 will get you 60% of the way and then fight you on the last 40% (merge semantics, testability, source control, cost at scale).
- **Silver → Gold is also Spark notebooks,** orchestrated by a master pipeline. Star-schema builds with window functions and aggregations are not a dataflow use case.
- **Dataflows Gen2 becomes a trap** the moment you need git-backed CI/CD, unit tests, or parameterized dev/test/prod promotion. The client explicitly called out CI/CD as a priority. That alone disqualifies Dataflows for the transform layers.
- **Cost lens:** Fabric Spark with NEE (Native Execution Engine) on a right-sized pool beats Dataflows Gen2 on sustained transform workloads. For bursty daily WideOrbit batches, a small autoscaling pool is the sweet spot.

**Orchestration:** One master Pipeline per environment triggers: (1) Copy exports to Bronze, (2) notebook: Bronze→Silver with quality gates, (3) notebook: Silver→Gold, (4) semantic model refresh via REST API activity. Watermark table in Silver drives incremental windows.

---

## 4. Five questions for kickoff (Apr 13–15)

1. **What does WideOrbit actually hand us?** CSV? XML? SFTP drop? API pull? Event Grid? The ingestion design collapses or expands dramatically on this answer. I've assumed scheduled file exports — confirm or kill.
2. **How far back do historical revisions propagate?** If a spot can re-rate 90 days after air, our Silver SCD2 window and Gold re-aggregation strategy both have to accommodate that. What's the longest revision horizon finance has seen?
3. **Is Decentrix parity the Jan 1 2027 acceptance bar, or is Phase 2 allowed to drop/rework legacy reports?** This determines whether Gold mirrors Decentrix semantics or gets to be a clean-sheet Kimball model. Huge scope implication.
4. **Who owns the semantic model — Dilip's team or ours?** This decides whether the `bi` workspace is ours to deploy into or a handoff target, and it reshapes the RLS/AD-group design.
5. **What's the refresh SLA the business actually needs?** Daily at 6am is a different architecture than hourly is a different architecture than near-real-time. Preman's Ad Ops dashboards historically wanted intraday — does Dilip's BI lens change that?

---

## 5. Toolkit reference material to reconcile before committing

Load-bearing for this sketch:

- **`e2e-medallion-architecture` skill** — specifically any reference patterns for SCD2 in Silver, quarantine/gate patterns between layers, and the workspace split recommendations. Want to confirm the four-workspace-per-env recommendation matches the toolkit's reference topology before committing it to the kickoff deck.
- **`spark-authoring-cli` skill** — notebook scaffolding for Bronze→Silver merge patterns, V-Order and Liquid Clustering guidance for the current Fabric runtime, and any project-standard utility libraries (logging, watermark helpers, quality-gate framework) to build on instead of reinventing.
- **Delta/V-Order defaults doc** if the toolkit has one — asserting V-Order ON everywhere, but the toolkit may have a more nuanced position for Bronze specifically.
- **Deployment pipeline reference** — Fabric deployment pipelines have sharp edges around lakehouse item binding across environments. If the toolkit has a proven pattern for parameterizing lakehouse IDs dev→test→prod, that's the single highest-leverage thing to adopt verbatim rather than re-derive.

**Before kickoff, actually open those skills and reconcile this straw-man against them** — this reconciliation pass was not done in the original generation session because of the subagent skill-visibility gap (see `discovery-log.md` 2026-04-10 fabric toolkit verification entry).
