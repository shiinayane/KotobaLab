# KotobaLab Documentation

Status: Active
Last updated: 2026-05-10

This directory contains project documents that should remain useful across development sessions.

## Directory Layout

- `product/`: product scope, MVP requirements, and user-facing feature boundaries.
- `dictionary/`: dictionary database design, build pipeline, and data delivery notes.
- `architecture/`: app architecture, module boundaries, dependency flow, and testing strategy.
- `roadmap/`: long-term product and technical roadmap.
- `phases/`: milestone records, phase summaries, and acceptance notes.
- `_local/`: local-only notes and scratch documents ignored by git.

## Language Policy

Formal documentation in this directory should be written in English.

Chinese notes, drafts, and historical versions should be kept under `docs/_local/`.

## Current Entry Points

- [MVP PRD](product/mvp_prd.md)
- [Dictionary database overview](dictionary/database_intro.md)
- [Dictionary strategy](dictionary/database_strategy.md)
- [Dictionary pipeline](dictionary/dictionary_pipeline.md)
- [Architecture overview](architecture/overview.md)
- [Product roadmap](roadmap/product_roadmap.md)
- [Phase 0: Current MVP Baseline](phases/phase-00-current-mvp.md)
- [Phase 1: Dictionary Pipeline Stabilization](phases/phase-01-pipeline-stabilization.md)

## Document Roles

- `product/` defines product scope and acceptance criteria.
- `architecture/` defines current code boundaries and placement rules.
- `dictionary/` defines database schema, pipeline, and delivery decisions.
- `roadmap/` defines planned direction.
- `phases/` records completed or in-progress milestones.
