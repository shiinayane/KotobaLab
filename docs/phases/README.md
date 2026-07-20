# Phase Records

Status: Active
Last updated: 2026-07-21

This directory connects the strategic
[Product Roadmap](../roadmap/product_roadmap.md) to executable work and verified
completion records.

## Status Meaning

- **Historical**: baseline snapshot retained for context.
- **Completed**: scope and verification are recorded; later work does not reopen
  the phase unless a material claim is proven false.
- **Current**: the active execution plan.
- **Planned**: ordered future scope with an acceptance gate, not implemented
  work.

## Phase Index

| Phase | Status | Record |
| --- | --- | --- |
| 0 — MVP Baseline | Historical | [phase-00-current-mvp.md](phase-00-current-mvp.md) |
| 1 — Pipeline Stabilization | Completed | [phase-01-pipeline-stabilization.md](phase-01-pipeline-stabilization.md) |
| 2 — Core Experience | Completed | [phase-02-core-experience.md](phase-02-core-experience.md) |
| 3 — Architecture and CI | Completed | [phase-03-architecture-tests.md](phase-03-architecture-tests.md) |
| **4 — Dictionary Fidelity and Stable Identity** | **Current** | [phase-04-dictionary-fidelity.md](phase-04-dictionary-fidelity.md) |
| 5 — Search and Lookup Quality | Planned | [phase-05-search-lookup.md](phase-05-search-lookup.md) |
| 6 — Daily-Use Product Completion | Planned | [phase-06-product-completion.md](phase-06-product-completion.md) |
| 7 — v1 Release Readiness | Planned | [phase-07-release-readiness.md](phase-07-release-readiness.md) |
| 8 — Multi-Dictionary Foundation | Planned | [phase-08-multi-dictionary.md](phase-08-multi-dictionary.md) |
| 9 — Dictionary Catalog Expansion | Planned | [phase-09-catalog-expansion.md](phase-09-catalog-expansion.md) |

## Phase Record Contract

Each current/planned phase should define:

- Goal and why the phase exists now.
- Scope grouped into reviewable tasks.
- Non-goals that prevent scope drift.
- Verification/exit gate.
- Known risks and dependencies.
- Next phase handoff.

A completed phase should additionally record:

- Work actually completed.
- Decisions and rejected alternatives that matter later.
- Commands, tests, measurements, or manual acceptance evidence.
- Explicit carryover rather than silently declaring partial work complete.

Temporary investigation notes belong in `docs/_local/`, not in phase records.
