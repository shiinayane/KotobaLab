# Phase 9: Dictionary Catalog Expansion

Status: Planned
Last updated: 2026-07-21

## Goal

Ship at least one additional production-quality dictionary source that adds
meaningful coverage beyond the current Japanese-English Jitendex pack.

## Candidate Value Directions

- Japanese-Chinese definitions for Chinese-speaking learners.
- Japanese monolingual definitions for advanced learners.
- A complementary Japanese-English source with different examples, usage notes,
  or coverage.

This phase does not preselect a source. Availability is not enough: the app must
have the right to modify and redistribute an offline pack and must be able to
maintain updates reproducibly.

## Scope

### Task 1 — Source Evaluation

For each serious candidate, verify:

- license and offline redistribution rights
- attribution/share-alike requirements
- source and target languages
- structured-data fidelity and stable identifiers
- update cadence and reproducible acquisition
- coverage, duplication, examples, tags, and known quality limitations
- raw and built size plus expected search cost

Record a decision matrix and rejection reasons.

### Task 2 — Provider Adapter

Implement a source-specific importer that maps into the common pack contract
without erasing provider-specific meaning. Add real-source fixtures, validation,
quality counts, and deterministic output.

### Task 3 — Cross-Pack Product Behavior

Validate searches where sources agree, disagree, duplicate headwords, or expose
different languages. Keep source sections understandable and user-configurable.

### Task 4 — Delivery and Maintenance

Publish a versioned pack with checksum, manifest, attribution, update procedure,
and CI/release checks. Document who maintains source updates and how a broken
release is rolled back.

## Non-goals

- Shipping many low-quality dictionaries to increase a catalog count.
- Hiding source disagreements by merging definition text.
- Scraping sources without redistribution permission.
- Requiring accounts or cloud sync.

## Verification Gate

- Source license and redistribution decision is documented and reflected in-app.
- Importer output is reproducible and fixture-tested.
- New pack materially improves an identified user lookup need.
- Search/detail behavior remains clear for overlapping entries.
- App/pack size, latency, update, and maintenance budgets are accepted.
- Pack can be independently updated or rolled back without damaging existing
  user references.

## After Phase 9

Use actual v1 and multi-dictionary usage to decide whether the next investment
is study/review, user notes/export, cloud sync, additional dictionary languages,
or carefully grounded AI assistance. Do not pre-number those phases before the
evidence exists.
