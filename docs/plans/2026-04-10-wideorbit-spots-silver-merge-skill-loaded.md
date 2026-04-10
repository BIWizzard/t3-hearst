# WideOrbit `spots` — Bronze → Silver Merge Pattern (Skill-Loaded)

**Status:** Pre-kickoff design artifact (not an approved architecture)
**Date:** 2026-04-10
**Author:** `FabricDataEngineer` agent, spawned with the MANIFEST-first + SKILL.md-read invocation pattern
**Companion doc:** [`2026-04-10-wideorbit-medallion-strawman.md`](./2026-04-10-wideorbit-medallion-strawman.md) — the broader pre-kickoff straw-man this refines in one specific area
**Provenance:** [`docs/discovery-log.md`](../discovery-log.md) — see "2026-04-10 — Pre-Kickoff: Fabric Toolkit Integration Hardening" for the verification test that produced this document

---

## Why this document exists (and how to read it alongside the straw-man)

This is the output of a **verification test** of the fabric toolkit invocation pattern. In the same session we produced two designs from the same `FabricDataEngineer` agent under different conditions:

1. **The straw-man** — broad WideOrbit medallion sketch covering Bronze/Silver/Gold layout, workspace topology, ingestion shape, and kickoff questions. Produced by spawning the agent **without** any skill content — the agent worked from its own embedded knowledge because skills aren't auto-loaded into spawned subagents in Claude Code.

2. **This document** — a narrower, skill-shaped drill-down on one specific design question (Bronze → Silver SCD2 merge for WideOrbit spots). Produced by spawning the same agent **with** explicit instructions to first Read `docs/fabric-toolkit/MANIFEST.md` and then Read the relevant `SKILL.md` files before designing.

The two docs are **not competing** — they cover different scopes. The straw-man remains the authoritative pre-kickoff document for breadth (workspace layout, ingestion topology, the 4x3 workspace recommendation, the no-Dataflows-Gen2 call, the kickoff question set). This document is the authoritative reference for **depth** in the one area where a skill-loaded spawn had something specific to add: the SCD2 merge mechanics.

**What to look at if you're reading them side-by-side:**

- **Same agent, same engagement context, same session.** The only variable that changed was whether the agent was told to Read the toolkit files before designing.
- **Both have their opinionated moments.** The straw-man took opinionated positions on workspace split and ingestion shape. This document took opinionated positions on key derivation, quarantine structure, and clustering strategy — but with explicit references back to the skill content that shaped each call.
- **This document refines the straw-man in exactly two places**, with reasoning traceable to specific skill references: (a) single-table quarantine with gate-level tagging instead of per-entity quarantine tables, and (b) liquid clustering as the primary recommendation over Z-ORDER where the Fabric runtime supports it. Both refinements are driven by the revision-heavy nature of WideOrbit's fact grain, which the skill content specifically addresses.
- **Concreteness gap.** The straw-man discusses SCD2 at the level of "we'll use spot_current (Type 1) + spot_history (Type 2)." This document goes to full PySpark MERGE pseudocode, business-key derivation by hash function, within-batch dedup via window functions, two-pass expire-then-insert SCD2 logic with explicit reasoning for why single-MERGE doesn't work atomically, and tiered quality gates with critical-halt vs warning-quarantine severity. That's the skill content showing up in the output.

**Files the agent Read to produce this document** (declared verbatim in the agent's response header):

```
Files Read:
- docs/fabric-toolkit/MANIFEST.md
- docs/fabric-toolkit/upstream/skills/e2e-medallion-architecture/SKILL.md
- docs/fabric-toolkit/upstream/skills/spark-authoring-cli/SKILL.md
- docs/fabric-toolkit/upstream/skills/spark-authoring-cli/resources/data-engineering-patterns.md
```

Note: the agent chose to Read **two skills plus one resource doc**, not one. That multi-skill selection was the agent's own judgment call based on the task shape — the main thread did not pre-compute which skills to load. This is exactly the invocation pattern the framework is designed around: MANIFEST.md gives the agent the menu, and the agent picks what it needs.

**What this document is NOT:**

- NOT an approved architecture. Nothing here has been pressure-tested with the client. Multiple design choices depend on unconfirmed WideOrbit behavior (see §6 — Open Questions).
- NOT a replacement for the straw-man's breadth. It only covers the `spots` fact grain, Bronze → Silver, SCD2 merge specifics. It does not address workspace layout, ingestion shape, Gold design, other fact grains, or anything else the straw-man covers.
- NOT a final design for this merge pattern. When the Design phase formally starts (post-kickoff), this should be re-run against client-confirmed WideOrbit specifics and promoted to a proper approved design doc.

---

# Bronze to Silver Merge Pattern — WideOrbit `spots` (SCD2)

Good news up front: after reading the skill content, the straw-man's shape is broadly correct, but I'm tightening three things — the surrogate-key derivation, the quarantine mechanism (deletion-vector-aware, not a separate physical table per failed batch), and the reprocessing idempotency contract. The `e2e-medallion-architecture` skill explicitly calls out schema enforcement, partition-aware overwrite, and post-write OPTIMIZE as Silver-layer non-negotiables, and `data-engineering-patterns.md` is opinionated that MERGE is the right tool for SCD2 and that validation must happen at ingestion boundaries, not downstream. Both points shape the design below.

## 1. Silver Table Design

Two physical tables in `lh_silver_wideorbit`, both Delta, V-Order ON, deletion vectors ON:

**`silver_wideorbit_spot_current`** — Type 1, one row per logical spot (latest known state). This is what 95% of Gold queries and Power BI semantic models should hit.

Columns: `spot_sk BIGINT`, `spot_bk STRING` (business key, see §2), `station_id`, `market_id`, `advertiser_id`, `agency_id`, `order_id`, `air_date DATE`, `air_time_local`, `air_datetime_utc`, `length_seconds`, `rate_card_amount`, `net_amount`, `spot_type` (commercial / PSA / promo / make-good / preempt), `status`, `is_preempted`, `is_makegood`, `makegood_parent_spot_bk`, `log_reconciled`, plus audit columns `_effective_from_utc`, `_last_seen_batch_id`, `_last_seen_ingest_ts_utc`, `_source_row_hash`, `_wo_export_run_id`.

- **Partitioning**: `air_date` (monthly bucketing via a generated `air_month` column is tempting, but daily partition + liquid clustering is cleaner — see below).
- **Clustering**: Liquid clustering on `(station_id, air_date, advertiser_id)`. Reasoning: the straw-man proposed Z-ORDER, but liquid clustering is the current Fabric-native recommendation and handles the WideOrbit revision pattern better — revisions scatter writes across historical partitions, and Z-ORDER's whole-partition rewrite cost punishes that. If liquid clustering isn't yet enabled in the target Fabric region, fall back to Z-ORDER on `(station_id, air_date)` and OPTIMIZE weekly.

**`silver_wideorbit_spot_history`** — Type 2, one row per version of a spot.

Same business columns plus SCD2 metadata: `spot_version_sk BIGINT`, `spot_bk`, `_valid_from_utc`, `_valid_to_utc`, `_is_current BOOLEAN`, `_change_type` (INSERT / UPDATE / LOGICAL_DELETE), `_changed_columns ARRAY<STRING>` (diff of what moved), `_source_row_hash`, `_batch_id`, `_wo_export_run_id`.

- **Partitioning**: `air_date` — same as current, so lineage queries against a given air date stay partition-pruned.
- **Clustering**: Liquid clustering on `(spot_bk, _valid_from_utc)` so "show me the full revision chain for this spot" is a single cluster seek.

Why two tables, not a view over history: consuming semantic models in Direct Lake mode can't efficiently filter `_is_current = true` across tens of millions of rows, and the skill is explicit that Gold/Silver hand-off to Power BI should hit physically materialized, read-optimized tables.

## 2. Business Key and Surrogate Key Strategy

WideOrbit's native spot identifier is typically a compound of `(station_id, spot_id)` where `spot_id` is a station-local integer. That's stable across most revisions but **not** across the preempt/make-good lifecycle, where WideOrbit sometimes reuses or reassigns IDs. So:

- **`spot_bk` (business key)**: `sha1(station_id || '|' || wo_spot_id || '|' || originating_order_line_id)`. Including the order line disambiguates make-goods that reuse a parent spot's ID. This is the **identity** column — same `spot_bk` means "same logical spot across revisions."
- **`spot_sk` (surrogate key)**: monotonically-assigned `BIGINT` in `spot_current` via `xxhash64(spot_bk)` (deterministic, safe to regenerate). History gets its own `spot_version_sk = xxhash64(spot_bk || '|' || _valid_from_utc)`.
- **`_source_row_hash`**: `sha2(concat_ws('|', <all tracked business columns>), 256)` — this is the **change-detection** hash. Same `spot_bk` + different `_source_row_hash` means "revised attributes, expire old version, insert new."

This needs client confirmation (see §6) — it's the single biggest modeling risk.

## 3. Merge Logic

Watermarking: track `_wo_export_run_id` and `max(_ingest_ts_utc)` processed per batch in a Delta control table `silver_ops.merge_watermarks`. Each Silver run pulls Bronze rows where `_ingest_ts_utc > last_watermark` **OR** `ingest_date` is in a reprocessing list (see §5). Never filter on `air_date` for the watermark — WideOrbit's historical revisions would be silently dropped.

```python
# --- 1. Read Bronze slice (watermarked, but re-reads ingest_date if on reprocess list) ---
bronze_slice = (spark.read.table("lh_bronze_wideorbit.bronze_wideorbit_spots_raw")
    .filter(f"_ingest_ts_utc > '{last_watermark}' OR ingest_date IN ({reprocess_dates})"))

# --- 2. Type + conform + derive keys + compute row hash ---
staged = (bronze_slice
    .transform(apply_schema_enforcement)        # reject schema drift -> quarantine
    .transform(conform_types)                    # dates, decimals, enums
    .withColumn("spot_bk", sha1_bk_expr())
    .withColumn("_source_row_hash", row_hash_expr())
    .transform(run_pre_merge_gates))             # §4

# --- 3. Dedup within-batch: WideOrbit can re-send same spot multiple times in one export ---
from pyspark.sql.window import Window
from pyspark.sql.functions import row_number, col
w = Window.partitionBy("spot_bk").orderBy(col("_wo_export_run_id").desc(), col("_ingest_ts_utc").desc())
staged_dedup = staged.withColumn("_rn", row_number().over(w)).filter("_rn = 1").drop("_rn")

# --- 4a. MERGE into spot_current (Type 1 upsert-latest) ---
from delta.tables import DeltaTable
current = DeltaTable.forName(spark, "lh_silver_wideorbit.silver_wideorbit_spot_current")
(current.alias("t")
  .merge(staged_dedup.alias("s"), "t.spot_bk = s.spot_bk")
  .whenMatchedUpdate(
      condition = "t._source_row_hash <> s._source_row_hash",
      set = { /* all business cols + _last_seen_batch_id, _last_seen_ingest_ts_utc, _source_row_hash */ })
  .whenMatchedUpdate(  # unchanged row — just touch last_seen for freshness tracking
      condition = "t._source_row_hash = s._source_row_hash",
      set = {"_last_seen_batch_id": "s._batch_id", "_last_seen_ingest_ts_utc": "s._ingest_ts_utc"})
  .whenNotMatchedInsertAll()
  .execute())

# --- 4b. MERGE into spot_history (Type 2 expire + insert) ---
# Only rows that actually changed or are new relative to history's current version
history = DeltaTable.forName(spark, "lh_silver_wideorbit.silver_wideorbit_spot_history")
changes = staged_dedup.alias("s").join(
    history.toDF().filter("_is_current = true").alias("h"),
    "spot_bk", "left"
).filter("h.spot_bk IS NULL OR h._source_row_hash <> s._source_row_hash")

# Two-pass: expire then insert (single MERGE can't do both legs of SCD2 atomically without the row-duplication trick)
(history.alias("t")
  .merge(changes.alias("s"), "t.spot_bk = s.spot_bk AND t._is_current = true")
  .whenMatchedUpdate(set = {
      "_is_current": "false",
      "_valid_to_utc": "s._ingest_ts_utc"})
  .execute())

# Insert new version rows
changes.withColumn("_valid_from_utc", col("_ingest_ts_utc")) \
       .withColumn("_valid_to_utc", lit(None).cast("timestamp")) \
       .withColumn("_is_current", lit(True)) \
       .write.format("delta").mode("append") \
       .saveAsTable("lh_silver_wideorbit.silver_wideorbit_spot_history")

# --- 5. Post-merge gates + advance watermark + OPTIMIZE (§4) ---
```

Spark session config: Silver balanced profile per the skill — V-Order ON, `optimizeWrite.enabled=true`, adaptive execution ON, `snapshot.driverMode.enabled=true`.

## 4. Quality Gates

**Pre-merge (on `staged` before any write):**
1. **Schema enforcement** — Bronze columns must conform to Silver expected types. Rows failing type coercion are isolated.
2. **Null business keys** — `station_id`, `wo_spot_id`, `order_line_id`, `air_date` all NOT NULL. Failed rows isolated.
3. **Air-date sanity bounds** — `air_date BETWEEN current_date - 3 years AND current_date + 1 year`. Outside bounds isolated.
4. **FK existence checks** — `station_id IN silver_stations`, `advertiser_id IN silver_advertisers`. Orphans isolated (warning, not fail — see policy below).
5. **Control-total check** — Bronze row count for `_batch_id` must match `_wo_export_run_id` manifest row count (if manifest present). Mismatch >0.5% **fails the whole batch**.

**Post-merge:**
6. **Row-count reconciliation** — `spot_current` distinct `spot_bk` count should equal the running population +/- net new inserts from this batch. Compute delta, assert within tolerance.
7. **Lineage verification** — every `spot_current` row touched must have a corresponding `_last_seen_batch_id = current_batch_id` or a matching `spot_history` insert.
8. **History chain integrity** — for every `spot_bk` touched, assert exactly one `_is_current = true` row in history.

**Failure routing (refinement of the straw-man):** Instead of a separate `silver_quarantine_<entity>` table per entity, use a single `lh_silver_wideorbit.silver_quarantine_spots` Delta table with columns `(_quarantine_ts_utc, _batch_id, _gate_name, _gate_severity, _failure_reason, _raw_row STRUCT<...>, _retry_count, _resolution_status)`. One table, many failure types, clean operational view. Critical gates (schema, null keys, control-total) **halt the merge and fail the batch** — nothing from that `_batch_id` lands in Silver, the whole batch goes to quarantine, and the pipeline emits a high-severity alert. Warning gates (FK orphans, air-date bounds) **quarantine the offending rows only** and let the rest of the batch merge, with a medium-severity alert summarizing counts.

Reprocessing from quarantine is a manual SQL workflow initially — flip `_resolution_status` to `reprocess` and the next Silver run picks up those rows via a union with the watermarked Bronze slice.

## 5. Reprocessing Strategy

The merge is **idempotent by construction** because:
- The within-batch dedup (§3 step 3) keeps only the latest row per `spot_bk` per run.
- `spot_current` MERGE is a pure upsert keyed on `spot_bk` — reprocessing the same Bronze `ingest_date` produces the same end state.
- `spot_history` only inserts when `_source_row_hash` differs from the current version. Rerunning with identical Bronze data produces **zero** new history rows — the chain stays clean.

For WideOrbit re-emitting historical periods: the pipeline accepts a `reprocess_ingest_dates` parameter (via Fabric Variable Library). When set, those dates are re-scanned from Bronze **in addition to** the watermarked slice. Because hash-based change detection is the gate for history inserts, re-emitted unchanged rows cost nothing; re-emitted changed rows land as proper new SCD2 versions with `_valid_from_utc = _ingest_ts_utc` of the re-emitted batch. This means revision timestamps in `spot_history` track **when we learned of the change**, not when the change occurred in WideOrbit's system — an important distinction to flag to the client.

After every successful merge, run `OPTIMIZE lh_silver_wideorbit.silver_wideorbit_spot_current WHERE air_date >= current_date - 30` and same for history, scoped to touched partitions only. Full OPTIMIZE weekly.

## 6. Open Questions for Client Kickoff (Apr 13–15)

1. **Business key stability.** Does WideOrbit's `spot_id` stay stable across preempts, make-goods, and re-rates, or does it get reassigned? Is there a native `wo_spot_guid` or equivalent we should use instead of the synthesized hash?
2. **Export manifest.** Does each WideOrbit export run include a row-count manifest / control totals file we can use for the pre-merge control-total gate? If not, we lose our strongest integrity check and need a compensating post-hoc reconciliation against invoices.
3. **Revision timestamps.** Does WideOrbit include a `last_modified_utc` on each row in the export? If yes, we can distinguish "when WO recorded the change" vs "when we ingested it" in `spot_history`. If no, our Type 2 chain is valid-from-ingest only — need to set expectations with analytics consumers.
4. **Make-good linkage.** How is a make-good linked to its preempted parent in the export? A column, a convention, a separate file? This determines whether `makegood_parent_spot_bk` is a reliable join key.
5. **Historical revision window.** How far back can WideOrbit re-emit? 90 days? Full year? This sets the `reprocess_ingest_dates` strategy and whether we need a periodic full-refresh safety net.
6. **Late-arriving dimensions.** If a spot references a `station_id` or `advertiser_id` not yet in the Silver dimension, do we quarantine, or do we land it and let a second-pass job resolve? Default to the latter for facts, but needs confirmation.
7. **Deletes.** Does WideOrbit ever hard-delete a spot, or is everything tombstoned with a status change? The design assumes logical deletes only — a hard-delete would force an extra anti-join pass.

The design holds up against the skill's "schema enforcement, validation at boundaries, MERGE for SCD, partition-aware writes, post-write OPTIMIZE" guidance without contradiction. The one place I diverged from the straw-man is quarantine structure (single table with gate-level tagging, not one-per-entity) and clustering strategy (liquid over Z-ORDER where available) — both driven by the revision-heavy nature of this specific fact grain.
