# Upstream sync log

Tracks the exact commit this toolkit's `upstream/` subtree is pinned to, and the history of sync operations.

## Current pin

| Field | Value |
|-------|-------|
| Upstream repo | https://github.com/microsoft/skills-for-fabric |
| Upstream branch | `main` |
| Pinned commit SHA | `339c328dc507a0ff2235e79a70d7c175eb6cc281` |
| Pinned date | 2026-04-10 |
| Integration method | `git subtree` (squashed) |
| Subtree prefix | `docs/fabric-toolkit/upstream` |

## Sync log

| Date | From SHA | To SHA | Method | Active-set files changed | Notes |
|------|----------|--------|--------|--------------------------|-------|
| 2026-04-10 | — | `339c328d` | initial `git subtree add` | n/a | Initial vendoring of the full upstream repo alongside project-local overlay (README, MANIFEST, sync + wire scripts). License verified: MIT (Microsoft Corporation, 2026). |

## How to sync

```bash
scripts/fabric-toolkit-sync.sh
```

The script handles the `git subtree pull`, lists which active-set files changed, and prompts before appending a new row here. See `scripts/fabric-toolkit-sync.sh` for details.
