# Product Roadmap

Status: Active
Last updated: 2026-07-21

## North Star

KotobaLab should become a dependable, offline-first Japanese dictionary before
it becomes a study platform or an AI product.

The current implementation proves the lookup/save loop and its architecture.
The remaining path to a formal app is dictionary fidelity, search quality,
complete daily-use UX, update safety, and release hardening. A second dictionary
source comes after that baseline, through an explicit multi-dictionary model.

## How to Read This Roadmap

- This file defines product order, phase boundaries, and exit gates.
- [`docs/phases/`](../phases/README.md) contains executable plans and historical
  completion records.
- Completed historical phases are not retroactively expanded to include later
  expectations.
- A phase closes only when its acceptance gate is met or an exception is
  recorded explicitly.

## Phase Summary

| Phase | Status | Outcome |
| --- | --- | --- |
| 0 — MVP Baseline | Complete | Working Search → Detail → Save → Saved loop |
| 1 — Pipeline Stabilization | Complete | Reproducible, verified, releasable dictionary artifact |
| 2 — Core Experience | Complete | Explicit UI state and a coherent core flow |
| 3 — Architecture and CI | Complete | Async GRDB boundary, explicit actor isolation, iOS CI, real query-plan verification |
| **4 — Dictionary Fidelity and Stable Identity** | **Current** | Lossless-enough entry model, stable saved references, versioned asset contract |
| 5 — Search and Lookup Quality | Planned | Predictable ranked search and useful structured detail |
| 6 — Daily-Use Product Completion | Planned | No placeholders; complete Home/Search/Saved/Settings behavior |
| 7 — v1 Release Readiness | Planned | Safe startup/update, test matrix, accessibility, legal and App Store gate |
| 8 — Multi-Dictionary Foundation | Planned | Installable source-aware dictionary packs and cross-pack lookup |
| 9 — Dictionary Catalog Expansion | Planned | At least one additional licensed dictionary/language source ships well |

## Completed Foundation

### Phase 0 — MVP Baseline

Established the local lookup/save loop, layered feature structure, SQLite and
SwiftData split, and initial use-case tests.

Record: [`phase-00-current-mvp.md`](../phases/phase-00-current-mvp.md)

### Phase 1 — Dictionary Pipeline Stabilization

Established the Python builder, compact schema, fixture tests, database
verification, GitHub Release artifact, checksum, and builder CI.

Record: [`phase-01-pipeline-stabilization.md`](../phases/phase-01-pipeline-stabilization.md)

### Phase 2 — Core App Experience

Established explicit Search state, loading/empty/error rendering, intentional
term/reading display, saved-list refresh behavior, preview fixtures, hidden
unfinished tabs, and in-app attribution.

Record: [`phase-02-core-experience.md`](../phases/phase-02-core-experience.md)

### Phase 3 — Architecture and CI

Established async dictionary repository APIs backed by GRDB reads, explicit
`@MainActor` Stores, nonisolated default actor settings, typed GRDB records,
production-shaped query verification/benchmarks, iOS lint/test CI, and expanded
SwiftData repository tests.

Record: [`phase-03-architecture-tests.md`](../phases/phase-03-architecture-tests.md)

## Path to a Formal Single-Dictionary v1

### Phase 4 — Dictionary Fidelity and Stable Identity

Goal: make the data trustworthy across source parsing, display, rebuilds, and
app updates.

Primary outcomes:

- preserve ordered senses/glosses, forms, readings, POS, and supported tags
- define a stable source entry key and migrate saved references away from raw
  autoincrement IDs
- add schema/content/source/license metadata
- define asset compatibility, replacement, and rollback behavior
- strengthen builder fixtures and invariants before changing UI

Why first: every search/detail/product improvement depends on this data contract.

Plan: [`phase-04-dictionary-fidelity.md`](../phases/phase-04-dictionary-fidelity.md)

### Phase 5 — Search and Lookup Quality

Goal: make lookup behavior predictable and useful with the richer model.

Primary outcomes:

- documented normalization and matching rules
- exact-first, deterministic ranking across term, reading, and alternative forms
- a measured result-limit/pagination strategy
- structured sense/detail rendering with source attribution
- copy/share and retry behavior
- search and detail contract tests plus refreshed benchmarks

Plan: [`phase-05-search-lookup.md`](../phases/phase-05-search-lookup.md)

### Phase 6 — Daily-Use Product Completion

Goal: remove the remaining demo surfaces and make the app pleasant for repeated
daily use.

Primary outcomes:

- choose and complete the primary information architecture: useful Home with
  recent activity, or remove Home and launch into Search
- remove the Profile dead end and all commented/placeholder product surfaces
- remove the unexplained 50-item Saved cap; add explicit saved management
- surface dictionary/app versions, source, licenses, and local-data behavior
- centralize user-facing strings and complete accessibility passes
- add a real app icon and polished empty/error/retry states

Plan: [`phase-06-product-completion.md`](../phases/phase-06-product-completion.md)

### Phase 7 — v1 Release Readiness

Goal: prove the single-dictionary app survives real installation, update, and
distribution conditions.

Primary outcomes:

- recoverable startup and incompatible/corrupt asset handling
- clean-install and upgrade-install matrix for dictionary and SwiftData versions
- Store and critical-flow UI tests in CI
- performance, memory, accessibility, privacy, license, and device checks
- deployment-target decision, versioning policy, release checklist, and beta run

Exit gate: all criteria in
[Product Requirements and v1 Baseline](../product/mvp_prd.md#v1-release-gate)
are met. This is the first App Store-ready milestone.

Plan: [`phase-07-release-readiness.md`](../phases/phase-07-release-readiness.md)

## Post-v1 Dictionary Expansion

### Phase 8 — Multi-Dictionary Foundation

Goal: support multiple independently versioned dictionary packs without
breaking lookup, saved state, attribution, or offline behavior.

Primary outcomes:

- common pack manifest and schema compatibility contract
- source-aware composite entry identity
- enabled-pack registry and deterministic aggregate search
- source-grouped detail presentation and per-pack attribution
- install/update/disable/remove lifecycle with integrity checks
- migration from the bundled v1 dictionary into the pack model

No semantic merging of equivalent entries is required in this phase.

Plan: [`phase-08-multi-dictionary.md`](../phases/phase-08-multi-dictionary.md)

### Phase 9 — Dictionary Catalog Expansion

Goal: ship at least one additional high-quality, legally redistributable source
and make source selection valuable rather than cosmetic.

Candidate directions include Japanese-Chinese definitions, a Japanese
monolingual dictionary, or a complementary Japanese-English source. The exact
source is not selected by this roadmap; licensing, redistribution, update
availability, structured-data quality, size, and maintenance cost must be
evaluated first.

Primary outcomes:

- documented source evaluation and license decision
- source-specific importer with fixtures and quality report
- cross-pack search/detail UX validated with real overlapping entries
- size, latency, and update-cost budgets remain within product limits

Plan: [`phase-09-catalog-expansion.md`](../phases/phase-09-catalog-expansion.md)

## Later Opportunities — Not Yet Numbered

These are intentionally outside the committed phase sequence:

- spaced-repetition study and review scheduling
- user notes, tags, and export/import
- optional cloud sync
- backend-hosted dictionary catalog or delta updates
- AI explanations, example generation, or nuance comparison

They should receive a numbered phase only after v1 and multi-dictionary results
show a concrete product need. AI output must never replace licensed dictionary
content as the source of truth.

## Current Priorities

Phase 4 starts with decisions that are expensive to change later:

1. Define the canonical entry/sense/form model from representative Jitendex
   source records.
2. Define stable entry identity and the migration path for existing saved IDs.
3. Add database metadata and compatibility rules.
4. Expand builder fixtures and verification around the new contract.
5. Rebuild, benchmark, and only then update app repository/domain models.

## Guardrails

- Do not add backend or AI work before the v1 release gate.
- Do not polish the current flattened detail model instead of fixing fidelity.
- Do not add FTS, fuzzy search, or deinflection without behavior requirements,
  representative fixtures, and production-query benchmarks.
- Do not use SQLite autoincrement IDs as durable user-data identity.
- Do not combine different providers into one apparent definition without
  preserving source boundaries and licenses.
- Do not select a second dictionary source until redistribution and update terms
  are verified.
