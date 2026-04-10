# Skill Locker Pattern

A portable, reusable framework for making dense domain knowledge available to spawned AI agents on demand, via progressive disclosure. This doc is intentionally instance-agnostic — it describes the pattern itself, not any specific implementation of it. Drop it into any project that needs the pattern, no editing required.

## What this is

A skill locker is an on-disk, curated knowledge store designed to be consumed by AI agents — especially spawned subagents that don't inherit the parent session's skill registrations. The locker makes domain knowledge discoverable via a routing index, fetchable on demand via file reads, and cheap to skip when a task doesn't need it.

The pattern works for any content class that is too dense to inline in a system prompt and too stable to generate on demand — platform knowledge (cloud services, data platforms, frameworks), domain knowledge (industry regulations, vertical-specific workflows), codebase knowledge (internal libraries, deploy runbooks, on-call procedures), team knowledge (delivery patterns, conventions), or project-local knowledge (historical decisions, assumptions).

The pattern was first formalized after a controlled proof-of-concept validated that an agent given access to a properly curated skill locker produced materially better output than the same agent working from its embedded knowledge alone. That POC used a vendored third-party knowledge base as the content store; the pattern itself has no third-party dependency.

## The problem

Spawning subagents (via Claude Code's Agent tool, or any similar mechanism) creates an isolated context. That context does not inherit whatever "skills" or "tools" the main session had registered. It also has a finite token budget. If you try to cram all the knowledge a spawned agent might need into its initial prompt, you burn context on material that may not be relevant to the task.

The obvious answer — "register skills globally" — fails in practice because:

- Platforms like Claude Code register skills at the main session level; subagents don't automatically inherit them.
- Global skills create name-collision and discovery problems across projects.
- Content you don't control (vendored upstream, client-confidential, team-proprietary) can't always live in global skills.
- Progressive disclosure (overview → specific → detailed reference) is better served by on-demand file reads than by pre-loaded registration of entire skill trees.

What you want instead: **dense knowledge stored on disk, indexed for fast agent routing, and fetched on demand by the agent itself via file reads.** That is a skill locker.

## The pattern (five parts)

1. **Content store.** Files on disk, organized for progressive disclosure. Top level is a directory of skills — self-contained knowledge units. Each skill has a `SKILL.md` overview plus optional `resources/` for deeper reference. Skills may cross-link via relative paths into a shared `common/` directory for reference material they all depend on.

2. **Curation index.** A single `MANIFEST.md` file at the locker root that acts as the routing catalog. It lists every skill with: name, status (active / dormant), a one-line purpose, and — for dormant items — a "promote when" trigger describing the signal to watch for before activating. The MANIFEST is the file agents read first; everything else is reached through it.

3. **Invocation protocol.** A convention for how agents use the locker. The canonical protocol is: (a) Read `MANIFEST.md` first, (b) based on the task, Read the specific `SKILL.md` files that apply, (c) if a skill references deeper resources, Read those as needed. The agent picks what applies — the calling thread does not pre-compute the selection. This preserves judgment at the agent level, which is exactly where the task context lives.

4. **Entry-point signal.** A small section in the project's `CLAUDE.md` (or equivalent agent instructions file) that tells every spawned agent: the locker exists, where it lives, what task types it applies to, and the invocation protocol. Without this, generic spawned agents don't know the locker is there and will reinvent content that already exists in it.

5. **(Optional) Specialized agents inside the locker.** Domain-specific agent personas that live alongside the skills and reference them via their own internal delegation maps. These agents can be invoked directly (as the `subagent_type` when spawning) when a task clearly matches their specialty. They follow the same invocation protocol for accessing skills — the "inside the locker" part is just about where the agent definition lives, not about skill auto-loading.

All five parts are required for the locker to do its job. Remove any one and the locker degrades:

- No content store → nothing to route to.
- No curation index → agents can't efficiently select what applies.
- No invocation protocol → agents don't know to read files.
- No entry-point signal → only agents that already know about the locker will use it.
- No specialized agents (optional) → you lose persona-level orchestration, but the locker still works for generic agents.

## Worked example (compact, generic)

Imagine a project that uses a lot of AWS. Instead of cramming AWS conventions and patterns into `CLAUDE.md` directly:

```
docs/aws-locker/
├── README.md            ← human-facing setup, links, promotion guide
├── MANIFEST.md          ← agent-facing routing index
├── skills/
│   ├── iam-policies/
│   │   ├── SKILL.md
│   │   └── resources/   ← specific IAM patterns, examples
│   ├── s3-lifecycle/
│   │   └── SKILL.md
│   └── lambda-patterns/
│       └── SKILL.md
└── common/              ← shared reference docs linked from multiple skills
    └── auth-tokens.md
```

An abbreviated `MANIFEST.md`:

```markdown
# AWS Locker — Asset Manifest

> **For agents:** Scan the Skills table below for active rows matching
> your task. Read the corresponding SKILL.md at
> docs/aws-locker/skills/<name>/SKILL.md. Skills may reference
> common/ docs via relative paths; follow as needed. Skip dormant
> rows unless their "Promote when" trigger is met.

## Skills

| Skill | Status | Purpose | Promote when |
|-------|--------|---------|--------------|
| `iam-policies` | active | IAM policy authoring, least-privilege patterns, common role designs | — |
| `s3-lifecycle` | active | Lifecycle rules, storage-class transitions, object versioning | — |
| `lambda-patterns` | dormant | Cold-start mitigation, layer management, async invocation | First Lambda-heavy task |
```

The corresponding `CLAUDE.md` entry-point snippet:

```markdown
## AWS Locker

For any task involving AWS services (IAM, S3, Lambda, networking, etc.):

1. Read `docs/aws-locker/MANIFEST.md` — the routing index.
2. Based on the task, Read the relevant SKILL.md file(s) at
   `docs/aws-locker/skills/<name>/SKILL.md`. Skills may reference
   `common/` docs via relative paths; follow as needed.
3. Skills are NOT auto-loaded into spawned subagents — these file
   reads are how you access them.

If a task has no AWS surface, skip this entirely.
```

That is a complete, working locker. Scale the same shape up to any domain.

## Separation principles (three axes)

When deciding what belongs in one locker versus separate lockers, apply these three tests.

**1. Separate by provenance and update cadence.** Vendored upstream content (third-party SDKs, open-source patterns, vendor-authored knowledge bases) updates on the upstream's cadence. Your own curation updates on yours. Mixing them in one store means an upstream sync can clobber your edits. Rule: **one locker per upstream source, with "yourself" treated as an upstream source.**

**2. Separate by scope.** Global patterns (general coding conventions), domain patterns (platform knowledge, industry knowledge), project-local patterns (this project's specific decisions). An agent spawned for a narrow task shouldn't have to wade through irrelevant scopes. Rule: **separate semantically by scope, so the router can filter quickly.**

**3. Separate by trust and licensing.** Publicly-licensed vendored content has one trust boundary. Client-confidential content has another. Internal team IP has a third. Mixing creates real leakage risk during sync, sharing, or publishing. Rule: **locker boundaries must align with git boundaries and sharing boundaries.**

## When NOT to build a locker

Lockers have maintenance cost — MANIFEST upkeep, curation, sync discipline, invocation-pattern education. They earn their keep only when:

- Content is dense enough that inlining wastes context
- Content is stable enough that curation stays fresh
- Multiple agents or spawns benefit from the same content
- Progressive disclosure actually pays off

They are **not** worth it when:

- Content is small → put it in `CLAUDE.md`
- Content is highly dynamic → generate on demand
- Only one task type ever uses it → inline it in that task's spawn prompt
- You already have a different discovery mechanism that works (for example, a well-indexed codebase the agent can search)

Resist locker sprawl. Two to four lockers per project is plenty. If you find yourself building a fifth, ask whether two of the existing ones should merge.

## Risks to watch

- **Index rot.** `MANIFEST.md` files get stale if not maintained. Every locker needs a review cadence and a "last curated" date somewhere visible. A MANIFEST that still lists skills that were quietly removed six months ago is actively worse than no locker at all.

- **Workaround fragility.** The "subagent reads the skill file" part of the invocation protocol exists because — as of the time this pattern was formalized — Claude Code and similar platforms do not auto-register session-level skills into spawned subagents. If that behavior changes, the file-read workaround becomes unnecessary, but the locker pattern still holds value: curation, filtering, progressive disclosure, and trust-boundary separation remain useful regardless of how skills are registered.

- **Trust-boundary leakage.** The moment you think "let me put confidential content in the same locker as vendored public content to save space" — stop. Different trust zones, different lockers, possibly different git scopes. Enforcing this at locker boundaries is far easier than enforcing it at file-by-file review time.

- **Over-generalization.** The pattern is useful when instantiated for a concrete domain with real content. It is not useful as a theoretical framework with no implementations. Build the first locker from a real need before formalizing anything. The pattern doc (this file) exists because the pattern was validated against a working instance, not as a greenfield abstraction.

- **Locker discoverability.** A locker that exists but isn't surfaced in `CLAUDE.md` is invisible to spawned agents. The entry-point signal (part 4 of the pattern) is load-bearing — skip it and the rest of the work is wasted.

## Open question: global hosting vs per-project hosting

*This section is explicitly open. It is a design question worth exploring in a dedicated session, not an answered problem.*

Should a skill locker live globally — in its own dedicated repo or a shared directory — with each project referencing it by URL, filesystem path, or package manager dependency? Or should each project carry its own copy of every locker it uses?

**Per-project hosting arguments:**

- Self-contained projects are easier to onboard, share, and fork.
- Version drift between locker and project is impossible — they are the same checkout.
- No external dependencies at runtime; everything an agent needs is in the repo.
- Simpler trust story — one git history, one set of permissions, one sharing boundary.
- No network or platform dependencies during session start.

**Global (single-source-of-truth) hosting arguments:**

- A domain pattern that improves in one project improves for all consumers at once.
- Curation effort is not duplicated across N projects.
- Update cadence stays consistent across consumers.
- Fits the mental model of "this is a durable knowledge asset, not a project artifact."
- Makes multi-project "skill store" patterns possible — many projects pulling from one authoritative source.
- Reduces cognitive load for contributors who work across multiple projects.

**Hybrid possibilities worth exploring:**

- Global store, per-project lightweight pointer (a small local `MANIFEST.md` stub + symlink or git submodule into the global content).
- Global store, per-project sync script that pulls a pinned version of the locker into the project tree (the git-subtree pattern — self-contained at runtime, syncable on demand).
- Global store, CLI-level indirection — a small tool that fetches skills by name from a shared cache and materializes them into `docs/<locker>/` on first use.
- Global store, per-project cherry-pick — each project curates its own subset of globally-maintained skills, with the MANIFEST acting as the subset declaration.

The tradeoff is roughly **self-containment vs. curation leverage**. For a single project with one or two lockers, per-project copies are obviously simpler and the global argument is weak. As the locker count grows — or the number of projects consuming the same locker grows — the global argument gets stronger, and the risk of drift between per-project copies becomes a real curation tax.

This is worth thinking through before the locker count grows beyond two or three instances. Until then, per-project copies are fine and the answer is "do not decide yet."

## Using this document

This file is intentionally portable — no project-specific references, no assumptions about what lives alongside it. If you want to adopt the pattern in a new project, you only need this doc to explain what you are doing and why. To actually instantiate a locker, you still need to build the five parts for your specific content — this doc describes the pattern, not any particular instance of it.

If your project already has an instance of the pattern in place (say, a working domain locker), this doc is the conceptual companion that explains *why* the shape looks the way it does — useful for onboarding new contributors or for making the case to replicate the pattern in adjacent projects.

## Provenance

This pattern was first recognized and validated during a 2026-04-10 session that integrated a vendored third-party knowledge base into a Claude Code project. Validation consisted of a controlled comparison spawn test: the same agent was prompted with the same-scope design task twice — once with no skill access ("blind baseline"), and once with explicit MANIFEST-first + SKILL.md-read instructions. The skill-loaded output was materially more detailed, more concrete, and contained design refinements explicitly traceable to specific skill references. The blind baseline was coherent but much shallower. The delta was large enough that the pattern graduated from "probably useful" to "demonstrably load-bearing" in a single comparison test.

The pattern has no dependency on the specific content of that first instance. The shape — content store, curation index, invocation protocol, entry-point signal, optional specialized agents — is what transfers.
