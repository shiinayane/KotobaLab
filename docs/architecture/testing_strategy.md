# Testing Strategy

Status: Active
Last updated: 2026-07-21

## Purpose

KotobaLab has two independently changing products inside one repository:

1. the generated dictionary asset
2. the iOS app that queries the asset and persists user state

Tests must catch contract mismatches between them, not only local function bugs.

## Test Pyramid

### Builder Unit Tests

Location: `Tools/DictionaryBuilder/tests/`

Own:

- source parsing for representative real entry shapes
- transformation into canonical forms/senses/glosses/tags
- deterministic stable identity
- SQLite export constraints and indexes
- metadata/manifest generation
- explicit handling of malformed/unsupported source content

These tests should be self-contained and not require the full dataset.

### Database Verification and Benchmarks

Location: `Tools/DictionaryBuilder/debug/`

Own:

- required tables, indexes, metadata, foreign keys, and integrity checks
- content invariants and expected aggregate counts/ranges
- production-shaped query plans
- representative search/detail/batch latency
- database size budget

Verification is a hard release gate. Benchmarks are evidence, not flaky
microsecond assertions; regressions require review and an updated record.

### Repository Tests

Location: `KotobaLabTests/RepositoryTests/`

Own:

- GRDB record-to-Domain mapping
- search normalization/ranking/result-window contract
- ordered structured detail
- stable/composite identity resolution
- requested order, duplicates, and missing IDs in batch lookup
- SwiftData uniqueness, ordering, migration, and missing-entry behavior
- asset compatibility and replacement using old/new fixture databases

Use small fixture databases generated from the same schema contract as
production.

### UseCase Tests

Location: `KotobaLabTests/UseCaseTests/`

Own business coordination independent of frameworks:

- empty-query behavior
- dictionary + saved-state composition
- toggle behavior
- recent-history behavior
- missing dictionary entry policy
- composite source identity propagation

Use mocks at repository boundaries.

### Store Tests

Planned under `KotobaLabTests/StoreTests/`.

Own UI state machines:

- idle/loading/empty/loaded/error/retry transitions
- debounce and cancellation
- stale async completion rejection
- refresh without unnecessary content loss
- pagination/load-more state if introduced
- optimistic or failed save actions

Tests run on `@MainActor` and use controllable async mocks; avoid real sleeps.

### UI Tests

Planned as a small dedicated UI test target.

Own only critical integration journeys:

- launch → search → ordered result → detail
- save → Saved → reopen → unsave
- first-use/empty/error recovery
- Settings → dictionary/source/license information
- accessibility identifiers for critical controls

Do not duplicate every Store assertion through slow UI tests.

## Upgrade and Release Matrix

Before v1, automated or repeatable integration tests must cover:

- clean install
- app update with same schema/new content
- compatible dictionary schema migration
- stable saved/history references across dictionary replacement
- corrupt/incomplete new asset rollback
- incompatible future asset rejection
- SwiftData schema migration

## CI Gates

### Pull Requests

- Apple `swift format lint`
- iOS unit/repository/Store tests
- builder pytest suite when builder/schema code changes
- link/Markdown checks when formal docs change

### Dictionary Release

- full builder tests
- production build
- database verification/integrity
- benchmark comparison
- checksum and metadata validation
- fixture compatibility tests against the iOS repository

### App Release

- all pull-request gates
- critical UI tests
- clean/upgrade install matrix
- production dictionary smoke test
- accessibility and license/privacy checklist

## Fixture Policy

- Keep fixtures small, deterministic, licensed for repository use, and generated
  by scripts where possible.
- Include hard cases, not just happy-path words: same term/reading, multiple
  forms, multiple senses/POS, duplicate-looking entries, missing optional tags,
  broad-prefix ranking, and cross-dictionary overlap.
- Version fixtures with schema changes and retain at least one previous-version
  fixture for migration tests.

## Current Coverage Gaps

- No Store tests.
- No UI test target.
- Current dictionary fixture does not exercise rich senses/forms/tags or stable
  identity.
- No database replacement/rollback or SwiftData migration matrix.
- No formal documentation link checker.

Phases 4–7 close these gaps in the order required by the product model.
