# Product Requirements and v1 Baseline

Status: Active
Last updated: 2026-07-21

## Product Positioning

KotobaLab is a native, offline-first Japanese dictionary for iOS. Its first
release should be dependable for everyday lookup before it grows into a broader
study product.

The product order is deliberate:

```text
Dictionary correctness
-> Lookup quality
-> Daily-use product completeness
-> Release reliability
-> Multiple dictionaries
-> Optional study and intelligent features
```

AI, accounts, and a backend are not part of the dictionary foundation.

## Current Baseline

The repository already proves the core loop:

```text
Search -> Word Detail -> Save -> Saved List -> Reopen Detail
```

It also has a reproducible SQLite build pipeline, async GRDB access, SwiftData
user persistence, explicit Store state, unit/repository tests, and iOS/builder
CI. This is a strong engineering MVP, but it is not yet a release-ready
dictionary product. The concrete gaps are recorded in
[v1 Gap Analysis](v1_gap_analysis.md).

## v1 Product Goal

v1 is a focused Japanese-English dictionary that can be trusted for ordinary
offline lookup. A single dictionary source is acceptable for v1 only if its
content is represented faithfully, search behavior is predictable, saved data
survives dictionary updates, and every visible product surface is complete.

Multiple dictionary sources are an explicit post-v1 goal. They must be added
through a source-aware data model rather than by appending unrelated columns or
merging entries heuristically.

## Target Users

Primary users are Japanese learners who need to:

- look up a Japanese headword or reading quickly
- distinguish likely matches from less relevant entries
- inspect structured senses and usage information
- save an entry and find it again later
- use the dictionary without a network connection

The initial interface and definition language may remain English. Additional
definition languages belong to the multi-dictionary expansion phases.

## Required v1 Capabilities

### Dictionary Content

- Preserve stable source identity across database rebuilds.
- Preserve headwords, readings, alternative forms, ordered senses, glosses,
  part-of-speech data, and the source metadata needed for attribution.
- Expose a schema/content version and validate required invariants during build.
- Do not silently flatten distinct senses into one display string.

### Search

- Search Japanese headwords and readings offline.
- Normalize supported Japanese input consistently.
- Rank exact matches before prefix and alternative-form matches.
- Produce deterministic ordering for equal-ranked results.
- Define result limits or pagination without silently hiding relevant matches.
- Provide empty, loading, no-result, error, and retry behavior.

Romaji, fuzzy search, deinflection, and full-text definition search are optional
for v1. They should be added only with explicit behavior specifications and
benchmarks.

### Word Detail

- Show term and reading with an intentional hierarchy.
- Show ordered senses rather than a single flattened definition.
- Show part of speech and supported usage/restriction tags in the scope where
  they apply.
- Identify the dictionary source and expose its attribution.
- Support basic actions expected from a dictionary: save, copy, and share.

### Saved and Recent Activity

- Save and unsave entries reliably.
- Keep saved references correct after a dictionary asset update.
- Show all saved entries, or provide explicit pagination; no undocumented
  fixed-size truncation.
- Support search and a clear removal action.
- Record recent lookups if Home remains a product surface.

### App Shell and Settings

- Every visible tab and navigation destination has real content.
- Search is the primary entry point unless Home provides useful recent content.
- Settings contains only working destinations.
- Dictionary version, source, licenses, app version, and local-data behavior are
  visible to the user.
- Database initialization and upgrade failures render a recoverable UI instead
  of terminating with `fatalError`.

### Quality and Release

- Support Dynamic Type, VoiceOver labels, dark appearance, and common compact
  and regular layouts.
- Centralize user-facing strings and decide the initial localization set.
- Include a real app icon and complete release metadata.
- Keep dictionary/user-data boundaries intact: SQLite for read-only reference
  packs, SwiftData for user-owned state.
- Pass builder, repository, use-case, Store, and critical-flow UI tests in CI.
- Verify startup, search, detail, save, database upgrade, and attribution on a
  clean install and an upgrade install.

## v1 Non-goals

- Account system or mandatory backend.
- Cloud sync.
- AI-generated definitions or examples.
- Social features.
- Full spaced-repetition study system.
- Semantic merging across dictionary providers.
- A downloadable dictionary marketplace.

## v1 Release Gate

v1 is ready only when all of the following are true:

- Dictionary rebuilds preserve entry identity or migrate user references safely.
- Search correctness and ranking have fixture-backed specifications.
- Structured entry detail is presented without known destructive flattening.
- The core loop works after both clean install and dictionary update.
- No placeholder tab, dead-end navigation, missing app icon, or fatal startup
  path remains.
- Accessibility, privacy, license, and App Store checklist items are complete.
- CI covers the production app build and the dictionary builder.
- A beta walkthrough finds no release-blocking failure in the core loop.

The execution path from the current baseline to this gate is defined in the
[Product Roadmap](../roadmap/product_roadmap.md).
