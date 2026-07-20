# Phase 4: Dictionary Fidelity and Stable Identity

Status: Current
Last updated: 2026-07-21

## Goal

Turn the compact MVP database into a trustworthy product data contract without
yet adding multiple dictionary providers.

The phase succeeds when a representative source entry can be rebuilt, stored,
queried, displayed by Domain models, and referenced by user data without losing
important structure or changing identity unexpectedly.

## Why This Phase Comes First

The current builder extracts `forms` but drops them, joins all glosses into one
definition, and emits exactly one meaning row per word. The current saved model
stores an autoincrement SQLite ID. Search and UI work built on those assumptions
would need to be redone after a fidelity/identity migration.

## Scope

### Task 1 — Source Contract Audit

- Select representative Jitendex entries covering multiple senses, multiple
  spellings/readings, kana-only words, POS changes, restrictions/tags, and
  unusual structured content.
- Record which source fields are required for v1, which are optional, and which
  are deliberately unsupported.
- Add source-shaped fixtures instead of relying only on simplified hand-written
  records.

Acceptance: the supported subset is explicit and every required shape has a
fixture.

### Task 2 — Canonical Entry Model

Define a normalized model for:

- entry identity
- headword forms and readings
- ordered senses
- one or more glosses per sense
- part of speech and supported usage/restriction tags
- source attribution and source revision

Do not model every possible future provider. Add only structure required to
represent the current source faithfully and the identity/source seams required
by Phase 8.

Acceptance: parsing no longer concatenates distinct source senses into an
irreversible string, and alternative forms reach the database.

### Task 3 — Stable Entry Identity

- Audit whether the Jitendex/JMdict sequence is unique at the intended entry
  boundary.
- Choose a stable source key. If one source field is insufficient, define a
  documented deterministic composite.
- Separate durable identity from SQLite row IDs used only for joins/performance.
- Change saved user data to reference a stable key, with an explicit migration
  from existing `wordID` records.

Acceptance: rebuilding the same source in a different insertion order preserves
logical entry identity and saved-word resolution.

### Task 4 — Versioned Database Metadata

Add machine-readable metadata for at least:

- schema version
- content/source revision
- dictionary identifier
- source and target languages
- build timestamp or build identifier
- attribution/license identifier

Define compatibility rules between app version and schema version.

Acceptance: app startup can inspect the asset and distinguish compatible,
upgradeable, and unsupported databases.

### Task 5 — Asset Replacement and Migration Design

- Define how a newly bundled/downloaded database replaces the Application
  Support copy.
- Preserve the old asset until the new asset passes integrity and compatibility
  checks.
- Define saved-reference migration and rollback behavior.
- Avoid implementing a remote catalog; this phase handles a single app-shipped
  asset only.

Acceptance: the upgrade algorithm is covered by tests using old/new fixtures and
cannot leave the app without a usable dictionary after a failed replacement.

### Task 6 — Builder and Verifier Upgrade

- Update parse → transform → export for the new schema.
- Add foreign keys, uniqueness constraints, required indexes, and integrity
  checks based on the canonical model.
- Add counts/invariants that detect dropped senses/forms and missing metadata.
- Regenerate fixture and production assets reproducibly.

Acceptance: builder tests, database verification, and integrity checks fail on
representative data loss or identity instability.

### Task 7 — App Model and Repository Migration

- Add GRDB records in `Data`, tech-neutral entities in `Domain`, and updated
  repository projections.
- Keep search summary queries lean while detail queries load structured data.
- Preserve async/non-main-thread behavior.
- Update tests before changing the final detail layout; visual redesign belongs
  to Phase 5.

Acceptance: repository tests prove stable lookup, structured detail order, and
saved-reference migration.

## Non-goals

- Search ranking or FTS.
- Full Word Detail redesign.
- A second dictionary source.
- Dictionary download/catalog UI.
- Semantic merging across entries or providers.
- Backend or AI features.

## Verification Gate

- Representative real-source fixtures round-trip required content.
- Database rebuild determinism/stable identity is tested.
- Existing saved IDs have a tested migration or a documented development-only
  reset decision before any public release.
- New database passes schema, metadata, foreign-key, index, and content-invariant
  verification.
- Production search/detail benchmarks are refreshed and stay within agreed size
  and latency budgets.
- iOS and builder CI pass.

## Known Risks

- Jitendex's structured Yomitan content is presentation-oriented; brittle HTML-
  like traversal can silently miss nested metadata. Fixture selection must be
  grounded in real source records.
- Stable identity may require a composite more nuanced than `sequence` alone.
- A richer schema can increase the current 52 MB asset substantially; fidelity
  decisions need explicit size budgets, not premature flattening.
- Migrating user references is harder after public release, which is why it is
  required now.

## Next Phase

[Phase 5: Search and Lookup Quality](phase-05-search-lookup.md) consumes the
versioned, structured data model to define ranking and useful detail rendering.
