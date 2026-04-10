# t3-hearst — Captures

Quick captures and notes. Use `/om-cap` to append.

### 2026-04-10 12:35

SOWs (v7 MVP + v2 Phase 2) and enriched README are foundational context for this engagement — ensure they're embedded in Neon and Claude Flow memory so future sessions load them as primary context.

---

### 2026-04-10 13:25

fabric-toolkit pattern — built a reusable, portable pattern for vendoring microsoft/skills-for-fabric into a Claude Code project via git subtree + curation overlay + .claude/ symlinks. Key artifacts to index: docs/fabric-toolkit/PATTERN.md (the teachable, portable explanation + replication guide — designed to be copied into other repos), docs/fabric-toolkit/README.md (project-specific usage of the toolkit in t3-hearst), docs/fabric-toolkit/MANIFEST.md (curation layer — active vs dormant upstream assets with promote-when triggers), docs/fabric-toolkit/UPSTREAM.md (pinned commit SHA + sync log), scripts/fabric-toolkit-sync.sh (git subtree pull wrapper with active-set change reporting), scripts/fabric-toolkit-wire.sh (idempotent .claude/ symlink creator). The pattern solves the problem of bringing Microsoft's first-party Fabric agent/skill knowledge into a project without global install pollution, without breaking the common/ cross-references by cherry-picking, and with a clean update path. Portable to any Fabric-adjacent repo — PATTERN.md section 6 has the step-by-step replication guide.

---
