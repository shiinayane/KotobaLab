# Dictionary Strategy

Status: Active
Last updated: 2026-07-30

## Purpose

This document defines durable dictionary-data decisions and clearly separates
the current implementation from the intended architecture. Exact schemas,
migration steps, and task order belong in phase records.

## Current Runtime

KotobaLab currently ships one Jitendex-derived Japanese-English SQLite asset.
GRDB reads a compact `words` and `meanings` schema; SwiftData stores saved word
IDs separately.

Verified snapshot from 2026-07-21:

| Property | Value |
| --- | ---: |
| SQLite size | 51.88 MB |
| Words | 293,471 |
| Meaning rows | 293,471 |
| Term equals reading | 70,640 |

The one-to-one word/meaning count is an implementation limitation, not a source
truth. The current builder concatenates glosses, drops extracted alternative
forms, omits source metadata, and exposes autoincrement row IDs as durable saved
references.

Current prefix search uses indexed `term` and `reading` paths with
`PRAGMA case_sensitive_like = ON`. Historical measurements and query-plan
evidence belong in phase records or verification output.

## Durable Data Boundaries

```text
External dictionary source
        ↓
Canonical source representation
        ↓
Versioned runtime dictionary pack
        +
Separate user-owned state
```

### External Source

An importer decodes a provider format such as Yomitan. Source-specific fields
remain source concerns and should not leak as positional JSON access throughout
the builder.

### Canonical Source Representation

The canonical layer preserves the supported meaning of source entries before
runtime optimization. It should contain the smallest shared structure the app
actually needs while allowing explicit provider-specific payload where
necessary.

It is not a universal dictionary ontology.

### Runtime Pack

The runtime asset is a measured projection optimized for app queries. SQLite is
the current and preferred local runtime format; supporting Yomitan import does
not require querying raw Yomitan JSON in the app.

Search projections should stay lean. Detail projections may load structured
forms, readings, senses, glosses, tags, and restrictions.

### User-Owned State

Saved words, history, preferences, notes, and future pack registry state belong
outside read-only dictionary assets. Replacing or removing an asset must not
delete personal data silently.

## Fidelity Contract

For every supported source shape:

- preserve entry, form, reading, sense, and gloss ordering where meaningful
- keep distinct senses distinguishable
- preserve supported restrictions and tags at their correct scope
- retain enough source information to explain attribution and unsupported data
- fail or report unsupported content explicitly instead of silently flattening
  it

Compactness is a measured constraint, not permission to lose meaning.

Yomitan compatibility describes a transport and structural container, not a
shared semantic ontology. Dictionaries using the same format may encode
provider-specific meaning in different tag sets and structured-content shapes.

The default fidelity path is an ordered structural projection that:

- preserves supported text, inline content, ruby, lists, tables, links, and
  disclosure structure
- keeps source order and nesting visible
- renders unknown valid nodes through an explicit fallback instead of silently
  dropping their content

A selected provider may add a semantic projection when its stable conventions
support materially better search, grouping, cross-references, or detail
presentation. Such an adapter sits above generic decoding; it does not redefine
Yomitan or require one parser per dictionary.

## Identity Contract

SQLite row IDs may be used internally for joins and indexes. App-facing and
persisted identity is conceptually:

```text
DictionaryEntryID {
  dictionaryID
  stableSourceEntryKey
}
```

The concrete Swift and storage representation remains an implementation
decision. Rebuilding the same source must preserve logical identity or provide
an explicit migration map.

Equivalent-looking entries from different providers remain distinct.

## Asset Metadata and Lifecycle

Every production asset should provide machine-readable:

- stable dictionary identifier and display/provider information
- source and target languages
- schema and compatibility version
- content/source revision and build identity
- checksum or equivalent integrity evidence
- license and attribution metadata

Target activation flow:

```text
discover candidate
-> verify integrity
-> read metadata and compatibility
-> verify schema and content invariants
-> migrate user references if required
-> activate atomically
-> retain or restore the previous valid asset on failure
```

## Multiple Dictionaries

Prefer one independently versioned read-only pack per provider over a single
ever-growing database. Separate packs improve update isolation, removal,
rollback, size choice, and license clarity.

Aggregate lookup must keep source labels and use an explicit deterministic
policy. Provider-specific frequency values must not be compared as though they
share one scale. Initial detail presentation should preserve separate source
sections rather than synthesize definitions.

The app should not require one repository protocol per provider unless their
app-facing operations genuinely differ.

## Import and Synchronization Boundary

A future Yomitan import path should decode a supported source contract and
compile it into the runtime format. Unsupported features must be reported to
the user.

Privately synchronizing user-imported assets between devices on the same account
may be supported later. Public catalogs, sharing, or cross-user distribution of
unknown commercial data are separate capabilities and are not implied.

## Licensing Boundary

Application source code is MIT licensed. Every dictionary asset retains its own
provider and upstream obligations. A candidate bundled source must pass an
explicit redistribution, attribution, commercial-use, maintenance, quality,
size, and update-cadence review.

## Performance and Verification

For changes to source decoding, schema, projections, ranking, indexes, or SQLite
configuration:

- add representative fixtures and invariants
- rebuild the affected fixture and production asset
- verify schema, metadata, integrity, and production query plans
- benchmark complete production-shaped search, detail, and batch paths
- run affected builder and iOS tests
- record artifact-specific measurements without turning them into timeless
  architectural claims

Add FTS only for a defined lookup requirement that measured indexed projections
cannot satisfy.

## Explicit Non-decisions

- No final canonical or SQLite table layout is mandated here.
- No universal support for every Yomitan feature is promised.
- No second bundled provider has been selected.
- No remote catalog or mandatory backend is required.
- No cross-provider semantic merge algorithm is planned.
