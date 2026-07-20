# KotobaLab Documentation

Status: Active
Last updated: 2026-07-21

This directory contains the durable product and engineering contracts for
KotobaLab. The current roadmap is organized around completing a formal
single-dictionary v1 before multi-dictionary expansion.

## Start Here

1. [Product Requirements and v1 Baseline](product/mvp_prd.md)
2. [v1 Gap Analysis](product/v1_gap_analysis.md)
3. [Product Roadmap](roadmap/product_roadmap.md)
4. [Current Phase — Dictionary Fidelity and Stable Identity](phases/phase-04-dictionary-fidelity.md)

## Documentation Map

### Product

- [Product Requirements and v1 Baseline](product/mvp_prd.md): release scope,
  user needs, required capabilities, non-goals, and v1 gate.
- [v1 Gap Analysis](product/v1_gap_analysis.md): repository-grounded comparison
  between the current MVP and a formal dictionary app.

### Architecture

- [Architecture Overview](architecture/overview.md): dependency direction,
  layer ownership, concurrency, persistence, and placement rules.
- [Testing Strategy](architecture/testing_strategy.md): builder through UI and
  upgrade/release test boundaries.

### Dictionary

- [Database Overview](dictionary/database_intro.md): current schema, artifact,
  query paths, measurements, and limitations.
- [Database Strategy](dictionary/database_strategy.md): target identity,
  fidelity, versioning, activation, and performance principles.
- [Dictionary Pipeline](dictionary/dictionary_pipeline.md): source-to-release
  build and verification contract.
- [Multi-Dictionary Strategy](dictionary/multi_dictionary_strategy.md):
  post-v1 pack model, identity, aggregate search, lifecycle, and source gate.

### Planning and Execution

- [Product Roadmap](roadmap/product_roadmap.md): phase order from completed MVP
  foundations through v1 and dictionary expansion.
- [Phase Records](phases/README.md): historical records and executable phase
  plans. Phase 4 is current.

## Directory Roles

- `product/`: what the product must do and what counts as release-ready.
- `architecture/`: long-lived code and testing boundaries.
- `dictionary/`: data model, build, asset lifecycle, and provider strategy.
- `roadmap/`: product ordering and phase gates.
- `phases/`: completed evidence and current/future execution plans.
- `_local/`: ignored notes, drafts, and local-only analysis.

## Documentation Rules

- Formal documentation is written in English.
- Chinese working notes belong under `_local/`.
- Active docs describe current facts or clearly labeled target direction.
- Historical phase records keep the decisions true at the time; later gaps are
  linked rather than retroactively rewritten into earlier scope.
- Measurements identify the artifact/date they describe.
- Schema, SQL, identity, or builder changes update dictionary docs and phase
  verification records in the same change.
- Roadmap plans are not proof of implementation; only verification can close a
  phase.
