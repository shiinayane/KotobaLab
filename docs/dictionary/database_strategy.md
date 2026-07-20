# Dictionary Database Strategy

Status: Active
Last updated: 2026-07-21

## Core Decision

Keep reference dictionary content and user-owned state separate:

```text
Versioned read-only SQLite dictionary data
                 +
SwiftData saved/history/preferences
```

This remains correct for both the single-dictionary v1 and future multiple
dictionary packs.

## Product Data Principles

### Preserve Meaning Before Optimizing Size

The app database should normalize the source into app-useful records, but it
must not irreversibly concatenate distinct senses or discard searchable forms.
Compactness is a measured constraint, not permission to lose core dictionary
meaning.

### Separate Durable Identity from Row Identity

SQLite integer primary keys may remain useful for joins and indexes. They are
not stable across rebuilds and must not be stored as the only reference in user
data.

A durable entry reference needs:

- a stable dictionary identifier
- a stable source entry key

For the single-source Phase 4 migration, the dictionary identifier may be
constant, but the data model should not erase it from the conceptual contract.

### Version Every Asset Contract

Each production database or pack needs machine-readable:

- schema version
- content/source revision
- dictionary identifier
- language metadata
- build identity
- source/license attribution metadata

The app must validate compatibility before activating an asset.

### Keep Search and Detail Projections Separate

Search should read a lean, indexed projection. Detail should load structured
forms/senses/glosses/tags. Avoid making every search row decode the complete
entry graph.

### Preserve Provider Boundaries

When multiple dictionaries arrive, equivalent-looking headwords from different
providers remain distinct sourced entries. The first implementation should
group/display sources, not synthesize an authoritative merged definition.

## Target Logical Model

Exact table names belong to Phase 4 design, but the logical relationships are:

```text
Dictionary metadata
  └─ Entry (stable source key)
      ├─ Forms / readings
      └─ Ordered senses
          ├─ Glosses
          └─ supported tags / restrictions
```

The model should support the current Jitendex source faithfully enough for v1
without pretending to be a universal dictionary ontology.

## Asset Lifecycle

The current “copy only if missing” behavior is insufficient. The target
activation flow is:

```text
discover candidate asset
-> verify checksum/file integrity
-> read metadata and compatibility
-> open and verify schema/content invariants
-> migrate stable user references if required
-> atomically activate
-> retain or restore prior valid asset on failure
```

Dictionary replacement must not delete SwiftData user state.

## Performance Policy

- Maintain indexes for every production lookup path.
- Verify complete production query plans, including projections and ordering.
- Record database size, row counts, search/detail/batch latency, and temporary
  B-tree use after relevant changes.
- Add FTS only for a defined requirement that prefix/form indexes cannot meet.
- Reject ranking changes that are correct in theory but unusable in measured
  broad-prefix queries.

## Multi-Dictionary Direction

After v1, prefer one independently versioned SQLite pack per provider over one
ever-growing monolithic database. This improves install/remove/update isolation
and licensing clarity. The app layer aggregates enabled packs through a common
repository contract.

The trade-offs and migration path are detailed in
[Multi-Dictionary Strategy](multi_dictionary_strategy.md).

## Explicit Non-decisions

- No final table layout is mandated before representative source fixtures are
  audited in Phase 4.
- No FTS engine is selected.
- No second dictionary provider is selected.
- No remote manifest/backend is required for v1.
- No cross-provider semantic merge algorithm is planned.
