# Phase 4: Dictionary Source Contract

Status: Current
Last updated: 2026-07-28

## Outcome

Define and verify the supported dictionary source model, stable identity
contract, and runtime projection requirements before migrating the production
database or app.

This phase succeeds when representative source records can be decoded into a
typed, source-aware representation without silent destructive flattening, and
when the next runtime migration can be designed from evidence rather than
assumptions.

## Why Now

The current builder extracts only a limited subset of Jitendex's
presentation-oriented Yomitan data. It concatenates glosses, drops extracted
alternative forms, omits source metadata, and relies on rebuild-dependent row
IDs.

Changing the production schema, repositories, saved records, or UI before
defining the supported source boundary would couple the app to another
under-specified model.

## Plan Mutability

This phase is a working hypothesis. Its slices may be revised, reordered, or
replaced when real source data, Yomitan documentation, performance evidence, or
a better implementation path changes the problem.

## Slice 1: Representative Source Corpus

Build a small, repository-safe corpus covering:

- multiple senses, glosses, forms, readings, and part-of-speech changes
- kana-only entries and entries where term equals reading
- restrictions, supported tags, and missing optional fields
- structured Jitendex content currently traversed by the builder
- the official Yomitan test dictionary
- one additional legally usable compatibility source or fixture

The compatibility source evaluates format assumptions; it does not become an
approved bundled dictionary.

Acceptance:

- every fixture has provenance and a repository-compatible license
- each fixture states the behavior or ambiguity it protects
- the corpus includes real structures that the current simplified tests miss

## Slice 2: Typed Yomitan Source Decoder

Decode the relevant Yomitan v3 term-bank and metadata fields into
source-specific types.

- keep positional JSON access inside the decoding boundary
- preserve ordering and optionality
- distinguish valid unsupported content from malformed input
- report unsupported source features explicitly
- avoid coupling decoding to SQLite records or Domain UI entities

Acceptance:

- supported source shapes decode without scattered raw array indexing
- malformed records produce actionable errors
- unsupported valid content is observable and testable
- fixtures cover each supported and intentionally unsupported shape

## Slice 3: Canonical Source Representation

Define the smallest representation that preserves the product-required meaning:

- dictionary identity and source entry key candidates
- forms and readings
- ordered senses and glosses
- part of speech, supported tags, and restrictions at the correct scope
- source attribution and revision
- an explicit provider-specific extension seam where a shared field would lose
  meaning

Do not design a universal ontology or force every provider into Jitendex's
presentation model.

Acceptance:

- distinct senses and searchable forms remain distinguishable
- source ordering survives conversion
- unsupported data is measured rather than silently discarded
- Jitendex-specific details do not leak across the whole builder

## Slice 4: Stable Identity Decision

Evaluate source identifiers against representative data and rebuild behavior.
Define the durable identity contract as:

```text
dictionaryID + stableSourceEntryKey
```

Acceptance:

- key construction is documented and deterministic
- rebuilding the same source in a different input order preserves logical IDs
- collisions, missing keys, and changed source records have explicit policies
- runtime row IDs are clearly limited to internal joins and indexes

## Slice 5: Runtime Contract Proposal

Use the verified source model to propose, but not yet migrate to, a runtime
contract.

The proposal must cover:

- lean search projection versus structured detail projection
- source and compatibility metadata
- stable identity lookup
- expected asset-size growth
- production search, detail, and batch query shapes
- migration and rollback questions that the implementation phase must answer

Acceptance:

- the proposal is exercised with representative converted fixtures
- size and query behavior are measured, not assumed
- fidelity compromises and unsupported fields are explicit
- no production app behavior or saved-data schema changes are required to close
  this phase

## Phase Acceptance

- The supported Yomitan/Jitendex source subset is documented and fixture-backed.
- Source decoding and canonical conversion preserve declared ordering and
  structure.
- Unsupported or malformed content cannot disappear silently.
- Stable source-aware identity is deterministic on representative data.
- A measured runtime contract proposal is ready for separate implementation
  review.
- Builder tests for the source contract pass.

## Non-goals

- Final production SQLite schema.
- Production dictionary rebuild or release.
- App repository, Domain model, or Word Detail migration.
- SwiftData saved-reference migration.
- Asset replacement, rollback, or startup recovery implementation.
- Search ranking, FTS, fuzzy search, deinflection, or UI redesign.
- General user dictionary import UI.
- Multi-dictionary runtime aggregation.
- CloudKit or public dictionary distribution.

## Risks and Open Decisions

- Jitendex structured content is presentation-oriented and may require a
  narrowly scoped interpreter rather than a generic tree flattening algorithm.
- Yomitan compatibility is a family of source shapes, not proof that every
  dictionary can map losslessly to one model.
- A richer source model may exceed acceptable runtime size unless the runtime
  projection stays separate.
- Identity behavior for upstream splits, merges, and deleted entries requires
  explicit policy.

## Handoff

After acceptance, update [Current Work](../development/current_work.md) with the
smallest implementation phase justified by the evidence. Do not pre-assign a
phase number or migration design here.
