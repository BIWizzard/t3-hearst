# The fabric-toolkit pattern — explanation, rationale, and replication guide

This document explains **what this pattern does, why it's designed the way it is, and how to replicate it in a fresh repository**. It is intentionally portable — nothing in it is specific to the t3-hearst project. If you need this toolkit in another repository (client-side, team-shared, or personal workspace), follow this guide and you'll reproduce the same structure, behavior, and safety properties.

## 1. The problem

When you work on a Microsoft Fabric project with Claude Code (or any AI coding tool that supports agents/skills), you want the model to know Fabric deeply:

- **Where things live** — the Fabric REST API topology, token audiences, workload endpoints, item definition formats.
- **How to do things** — Bronze/Silver/Gold medallion patterns, T-SQL ETL against warehouses, semantic model authoring via TMDL, Delta optimization tuning, notebook deployment via API.
- **Which commands to run** — `az rest` recipes, `sqlcmd`, Livy session lifecycle, OneLake uploads via curl.

You can write this yourself, or you can use the body of knowledge Microsoft publishes at **[microsoft/skills-for-fabric](https://github.com/microsoft/skills-for-fabric)**. That repo contains 3 persona agents, 10 skills, and 9 shared common reference docs — all first-party, MIT-licensed, and Claude Code-compatible.

The question is: **how do you bring that into your project without making a mess?**

## 2. Why the obvious approaches don't quite work

### "Just run their install.sh"
Upstream provides `install.sh` that copies skills to `~/.copilot/skills/fabric/` and drops compatibility files (`CLAUDE.md`, `.cursorrules`, etc.) into your project root. Problems:

- **It's a global install.** Every project on your machine inherits the same Fabric toolset. Fine if you only do Fabric work, messy if you don't.
- **No version pinning.** You get whatever was latest when you ran it. No record of "our project is using the 2026-03-15 version of these skills."
- **It pollutes your project root.** `CLAUDE.md`, `AGENTS.md`, `.cursorrules`, `.windsurfrules` all land in your repo root. Some of those collide with files you may already have (in this project, `CLAUDE.md` is our gitignored ruflo config — the upstream file would clobber it).

### "Cherry-pick the files I need"
Copy just the skills and agents you want, adapt them to your project, commit the copies. Problems:

- **Skills deep-link into `common/` via relative paths** (`../../common/COMMON-CORE.md`). If you copy a skill without the common/, the progressive disclosure breaks. If you rewrite the paths, you're modifying upstream content, which means every sync becomes a merge conflict.
- **Skills cross-reference each other.** `spark-authoring-cli` assumes `sqldw-authoring-cli` exists. `e2e-medallion-architecture` assumes both exist. Trimming breaks cross-links the authors put there intentionally.
- **Agents have `delegates_to` arrays listing skill names.** If you pick 4 skills but the agent delegates to 9, you have a dead list. Editing it means modifying upstream content → sync conflicts.
- **No update path.** Every time upstream changes, you're doing manual diffs against copies that no longer match.

### "Add it as a git submodule"
Better than cherry-picking, but:

- **Submodules are notoriously annoying.** Fresh clones don't get submodule content unless you remember `--recursive`. CI often misconfigures them. New team members trip over them.
- **You can't modify anything inside.** That's usually good, but it means overrides (if you ever need them) have to live somewhere else with path rewrites.

### "Vendor the whole thing by just copying it"
Copy all files once, commit them, ignore upstream. Problems:

- **No provenance.** Six months later nobody knows what commit this was from.
- **Manual updates are painful.** You'd need to re-download, diff, merge by hand every time.

## 3. The pattern this toolkit uses

Three ideas, layered:

### Idea 1: Vendor the full upstream repo as a git subtree
Everything from `microsoft/skills-for-fabric` lives under `docs/fabric-toolkit/upstream/`, pulled in via `git subtree add --squash`. That means:

- **Files are plain tracked files** — visible to `git log`, `git blame`, and anyone browsing the repo.
- **Provenance is in the commit history** — the subtree-add commit records the upstream SHA.
- **Updates are one command** — `git subtree pull --prefix=docs/fabric-toolkit/upstream <remote> main --squash` merges upstream's current state, with normal git conflict resolution if you've made local changes.
- **Fresh clones just work** — no `--recursive`, no submodule init, nothing special.
- **Squash keeps history clean** — upstream's entire commit history doesn't bleed into yours; each pull is one squash commit on your side.

### Idea 2: Overlay files that live beside the subtree, not inside it
Inside `docs/fabric-toolkit/`, alongside `upstream/`, we add four files that we own:

- **`README.md`** — how to use the toolkit in this project (project-specific usage doc).
- **`MANIFEST.md`** — an index of every upstream asset, marked active or dormant, with "promote when" triggers. This is the **curation layer**. It doesn't modify upstream; it describes which bits we've turned on.
- **`UPSTREAM.md`** — the sync log. Records pinned commit SHA, sync dates, and which active-set files changed between pulls.
- **`UPSTREAM-LICENSE`** — a copy of upstream's MIT license, satisfying the attribution requirement for the files we vendor.
- **`PATTERN.md`** (this file) — the portable, teachable explanation.

None of these files live inside `upstream/`, so syncs never touch them.

### Idea 3: Wire the active set into `.claude/` via symlinks
Claude Code loads agents from `.claude/agents/*.md` and skills from `.claude/skills/<name>/SKILL.md`. The toolkit doesn't live there — it lives under `docs/fabric-toolkit/upstream/`. We bridge the two with symlinks:

```
.claude/agents/fabric-data-engineer.md → ../../docs/fabric-toolkit/upstream/agents/FabricDataEngineer.agent.md
.claude/skills/spark-authoring-cli     → ../../docs/fabric-toolkit/upstream/skills/spark-authoring-cli
[...and so on for the active set]
```

`.claude/` is gitignored, so the symlinks aren't tracked — they're ephemeral. We rebuild them from a single script (`scripts/fabric-toolkit-wire.sh`) that reads the active set and creates all the links in one shot. Idempotent — run it on fresh clones, run it after editing the active set, run it whenever.

**Why symlinks and not copies?**
1. **No duplication.** The source of truth for an agent or skill is the upstream file. Copying it would create two versions that can drift.
2. **Relative paths still resolve.** When a skill references `../../common/COMMON-CORE.md`, the path is relative to the symlink's target (the real file under `upstream/skills/<name>/`), not the link. So `../../common/` walks back through `upstream/skills/` to `upstream/common/`. No path rewriting, no breakage.
3. **Rename at the symlink level.** Upstream uses `FabricDataEngineer.agent.md`; Claude Code expects `<name>.md`. The symlink's filename is `fabric-data-engineer.md` but it points at the upstream file unchanged. We get the rename without editing anything.
4. **Trivial to promote/demote.** Activating a dormant skill is one line in the wire script. Demoting is one line removed. No file moves.

## 4. The safety properties this gives you

| Property | Mechanism |
|----------|-----------|
| **Pinned, reproducible version** | Subtree squash commit records exact upstream SHA |
| **Clean update path** | `git subtree pull` — merges, conflicts handled normally |
| **No local edits to upstream** | Overrides (if ever needed) go in `.claude/agents/<name>.md` as real files, not symlinks; documented in MANIFEST |
| **Curation visible at a glance** | MANIFEST.md is a single table showing what's active vs dormant, and why |
| **License compliance** | `UPSTREAM-LICENSE` sits next to the vendored content |
| **No global side effects** | Everything is project-scoped; your other projects are untouched |
| **Fresh clones work** | Run `scripts/fabric-toolkit-wire.sh` once, done |
| **Teachable** | This document — the pattern is explicit, portable, and the reasoning is recorded |

## 5. Expected use cases

### Primary — individual workspace for a Fabric project
You're working on a Microsoft Fabric engagement (lakehouse modernization, ETL migration, PBI dashboarding, etc.) and you want Claude Code to be a Fabric-knowledgeable collaborator. The toolkit gives you:

- An orchestrator agent (`fabric-data-engineer`) that knows medallion, delegates work to the right skill, and understands the Fabric topology.
- Skills you can invoke directly for specific tasks: "build a Bronze ingestion notebook", "author a TMDL semantic model with Direct Lake", "write a T-SQL merge against the warehouse".
- A shared `common/` knowledge base on auth, REST APIs, and CLI patterns that skills implicitly load when relevant.

### Secondary — shared team or client repo
If you end up working inside a team repo (your company's) or a client repo, the same pattern works. Follow the replication guide below. Two notes:

- **MANIFEST.md becomes more important.** When other people are reading your work, the curation layer tells them what's loaded and why.
- **The PATTERN.md file becomes a teaching artifact.** Point colleagues at it so they understand the choices before trying to "fix" what looks unusual.
- **Consider whether `.claude/` should be tracked.** If the team is standardizing on Claude Code and wants everyone to see the same agents/skills, you may want to track `.claude/` (removing it from `.gitignore`) or track the symlink layout some other way. In that case the wire script can be removed in favor of committed symlinks — works on macOS and Linux, gotcha on Windows.

### Tertiary — personal reference library
Even if you're not actively using Claude Code, the vendored content under `upstream/common/` and `upstream/skills/*/SKILL.md` is an excellent Fabric reference. You can grep it, read it, and link to it in your own notes.

## 6. Replication guide — from scratch, in any repository

These steps reproduce the entire pattern in a fresh repo. No prerequisites beyond `git` and a shell.

### Step 1: Vendor upstream as a git subtree

```bash
cd <your-project>

# Add the upstream as a named remote (this makes subsequent pulls easier)
git remote add -f microsoft-fabric https://github.com/microsoft/skills-for-fabric.git

# Vendor the full upstream repo under docs/fabric-toolkit/upstream
git subtree add --prefix=docs/fabric-toolkit/upstream microsoft-fabric main --squash
```

After this, `docs/fabric-toolkit/upstream/` contains the full upstream layout (agents/, skills/, common/, etc.).

### Step 2: Copy the license notice

```bash
cp docs/fabric-toolkit/upstream/LICENSE docs/fabric-toolkit/UPSTREAM-LICENSE
```

### Step 3: Write your overlay files

Create four files under `docs/fabric-toolkit/`:

- **`README.md`** — project-specific usage instructions. Describe how your project uses the toolkit, what's active, how to update, how to add overrides.
- **`MANIFEST.md`** — a table listing every upstream asset (agents, skills, common docs, mcp assets) marked `active` or `dormant`, with a "promote when" column describing the trigger to move something from dormant → active.
- **`UPSTREAM.md`** — a sync log. Start with the commit SHA you just pinned (`git rev-parse microsoft-fabric/main`), today's date, and "initial vendoring" as the note.
- **`PATTERN.md`** — this document. Copy it verbatim as a teaching artifact.

You can use the files in this repo as templates — they're designed to be adapted.

### Step 4: Write the wire script

Create `scripts/fabric-toolkit-wire.sh` that creates the symlinks for your active set. The script in this repo (`scripts/fabric-toolkit-wire.sh`) is a good starting point — edit the `link_agent` and `link_skill` calls to match your active set.

Make it executable:
```bash
chmod +x scripts/fabric-toolkit-wire.sh
```

### Step 5: Write the sync script

Create `scripts/fabric-toolkit-sync.sh` to handle future updates. The version in this repo wraps `git subtree pull`, reports active-set diffs, and prompts you to update `UPSTREAM.md`. Copy it, edit the `ACTIVE_PATHS` array to match your active set.

```bash
chmod +x scripts/fabric-toolkit-sync.sh
```

### Step 6: Decide on `.claude/` tracking policy

**Option A — Gitignore `.claude/`** (what this project does):
Fresh clones won't have the symlinks. Anyone who clones must run `scripts/fabric-toolkit-wire.sh` once. Simpler, no cross-platform worries, but requires the manual step.

**Option B — Track `.claude/` symlinks**:
Commit the symlinks. Works on macOS/Linux out of the box. Windows support for symlinks in git is possible but has gotchas (need `core.symlinks=true`, admin rights, etc.). Consider this if your team is macOS/Linux only.

**Option C — Track `.claude/` as real files** (copies, not symlinks):
The wire script can be a "copy" script instead. Cleanest for cross-platform, but you lose the "single source of truth" property — the `.claude/` copy will drift from the vendored copy unless you remember to re-run on every sync.

For most cases, Option A is the simplest and most robust. It's what we use here.

### Step 7: Run the wire script and verify

```bash
scripts/fabric-toolkit-wire.sh
ls -la .claude/agents/ .claude/skills/
```

You should see your symlinks. Open one and confirm it resolves — e.g. `head .claude/skills/spark-authoring-cli/SKILL.md`.

### Step 8: Commit

```bash
git add docs/fabric-toolkit/ scripts/fabric-toolkit-*.sh
git commit -m "Add fabric-toolkit: vendored microsoft/skills-for-fabric + curation layer"
```

Do not force `.claude/` into the commit — it's ignored per your gitignore policy.

### Step 9: Document for teammates

Point teammates at `docs/fabric-toolkit/PATTERN.md` (this file) and `docs/fabric-toolkit/README.md` (the project-specific doc). Together they explain what's going on and how to add/remove assets.

## 7. Maintenance operations

### Promoting a dormant asset
1. Open `docs/fabric-toolkit/MANIFEST.md`, confirm the "promote when" trigger is met.
2. Add a line to `scripts/fabric-toolkit-wire.sh` (and to the `ACTIVE_PATHS` array in `scripts/fabric-toolkit-sync.sh` if you want change reporting on it).
3. Run `scripts/fabric-toolkit-wire.sh`.
4. Flip the status in MANIFEST.md from `dormant` to `active`.
5. Commit.

### Demoting an active asset
1. Remove the line from both scripts.
2. Delete the now-orphaned symlink under `.claude/`.
3. Flip MANIFEST.md status to `dormant`.
4. Commit.

### Updating from upstream
```bash
scripts/fabric-toolkit-sync.sh
```
Review any active-set file changes the script reports. If everything looks fine, append a row to UPSTREAM.md and commit.

### Customizing an agent or skill for your project
Don't edit `upstream/` — it will be clobbered on the next sync. Instead:
1. Copy the file out of `upstream/` into `.claude/agents/<name>.md` (or `.claude/skills/<name>/`) as a real file (not a symlink).
2. Remove the matching symlink so Claude Code loads your copy.
3. Make your edits.
4. Document the override in MANIFEST.md ("active (override)") so future-you remembers.
5. On sync, `fabric-toolkit-sync.sh` will still report upstream changes to the original — but since you have a real file in `.claude/`, nothing is auto-applied. Reconcile manually.

## 8. What this pattern is and isn't

**What it is:**
- A way to bring Microsoft's first-party Fabric knowledge into a Claude Code project cleanly.
- A reproducible, portable, teachable structure.
- A curation layer (MANIFEST) that controls what's loaded without modifying vendor content.

**What it isn't:**
- An install script for every Claude Code project. It's specific to projects that need Fabric skills.
- A fork. We don't modify upstream — we vendor it and layer on top.
- A replacement for understanding the upstream content. Read the docs, read the skills, know what's in there. The toolkit just makes it available; it doesn't make it automatic.

## 9. Why you'd use this in another repo

If you end up doing Fabric work in a different repository — client-side, company team repo, or another personal workspace — this pattern ports directly:

1. **It's 100% declarative.** The whole thing is files + scripts. No runtime dependencies, no config servers, no install state.
2. **The overlay files are reusable with light edits.** README, MANIFEST, PATTERN, and the two scripts can be copied forward. Adjust the active set in MANIFEST + wire script to match the new project's needs.
3. **Git subtree is vanilla git.** Works in every git host, every CI system, every IDE.
4. **No side effects.** Nothing installs globally, nothing depends on environment variables, nothing phones home.

If you're teaching a teammate, a contractor, or a client engineer how this works, point them at this document first. The replication guide in section 6 gets them from zero to working in about 10 minutes.
