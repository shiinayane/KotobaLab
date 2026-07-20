# Multi-Dictionary Strategy

Status: Planned direction
Last updated: 2026-07-21

## Purpose

The current app ships one Japanese-English Jitendex-derived SQLite database.
That is sufficient to prove and release a focused v1, but it should not remain
the final breadth of the product. This document defines how additional sources
can be added after v1 without corrupting identity, attribution, or search.

## Recommended Unit: Dictionary Pack

Use one read-only SQLite file plus a manifest as the deployment unit for each
provider/source edition.

Conceptual pack:

```text
<dictionary-id>/
├── manifest.json (or equivalent embedded metadata)
└── dictionary.sqlite
```

Required manifest concepts:

- stable dictionary identifier
- display name/provider
- source and target languages
- schema version and app compatibility
- content/source version
- checksum and byte size
- license/attribution links and required text
- build identity

Embedding critical metadata in SQLite as well as the external manifest allows
the app to reject a mismatched pair.

## Why Separate Packs

Compared with one monolithic database, separate packs provide:

- independent install, update, rollback, disable, and removal
- clearer license/attribution boundaries
- failures isolated to one source
- no need to rebuild every dictionary when one provider updates
- easier size management for users who do not need every language

Costs:

- aggregate search must coordinate multiple GRDB queues/databases
- global ranking across providers needs an explicit policy
- saved/history identity must include the dictionary source
- pack lifecycle and compatibility become product responsibilities

These costs are acceptable after the single-pack v1 proves the core app.

## Identity

Never use a pack's SQLite row ID outside that pack's repository implementation.

App-facing identity:

```text
DictionaryEntryID {
  dictionaryID
  sourceEntryKey
}
```

The exact Swift type is a Phase 8 implementation decision. The contract must be
Hashable/Sendable and persistable in SwiftData.

Saved words and recent history refer to this composite identity. Updating one
pack may remap internal row IDs but must preserve its source keys or provide a
migration map.

## Repository Shape

Keep provider-specific GRDB records inside each pack implementation. Expose a
common Domain model that always carries source identity and display attribution.

Conceptual flow:

```text
Enabled pack registry
  ├─ JitendexRepository
  ├─ Japanese-ChineseRepository
  └─ MonolingualRepository
          ↓
AggregateDictionaryRepository
          ↓
Search / Detail UseCases
```

Do not create one Swift protocol per source unless implementations actually need
different app-facing operations. Prefer one pack contract plus source-specific
builder adapters.

## Aggregate Search

The first multi-dictionary search should be simple and explainable:

1. normalize the query once at the UseCase/domain boundary
2. search enabled packs concurrently with cancellation
3. apply per-pack result limits and ranking
4. combine using user source order or an explicit deterministic policy
5. keep source labels in every result

Do not globally compare opaque provider frequency numbers as if they shared one
scale. Do not remove duplicate-looking entries unless source identity remains
accessible.

## Detail Presentation

Initial behavior should show separate source sections or separate sourced
entries. This preserves:

- disagreements and nuance
- source-specific tags/examples
- attribution
- user trust

Cross-source headword grouping may be introduced as presentation convenience,
but it must not merge or rewrite licensed definition content.

## Pack Registry and User Data

The registry owns:

- installed path/version/checksum
- enabled state and user order
- last validation/update result

Dictionary content remains in read-only SQLite packs. Registry preferences,
saved entries, and history remain user data. Removing a pack needs an explicit
policy for references: retain dormant saved references for possible reinstall,
or let the user delete them; never silently retarget them to another source.

## Delivery Stages

Phase 8 can prove the architecture with local fixture/bundled packs. A remote
catalog is not required.

If later needed, delivery can evolve to:

```text
signed/static catalog manifest
-> HTTPS asset download
-> checksum and metadata verification
-> staged open/integrity checks
-> atomic activation
```

A custom backend is optional; static release hosting may remain sufficient.

## Source Selection Gate

Before adding a production provider, verify:

- modification and offline redistribution permission
- commercial/App Store compatibility if relevant
- attribution and share-alike implications
- stable identifiers and structured export quality
- reproducible acquisition and update cadence
- content coverage and language value
- built size and search performance
- long-term maintenance ownership

Phase 9 owns this decision. The roadmap names Japanese-Chinese, monolingual, and
complementary Japanese-English only as value directions, not approved sources.

## Explicit Non-goals

- Automatic semantic merging.
- Scraping dictionary websites.
- User-generated untrusted pack execution.
- Mandatory cloud accounts.
- Treating AI output as a dictionary provider.
