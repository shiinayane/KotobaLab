# Dictionary

Dictionary data principles, the current pipeline, and measurements. This is the
only document that records dictionary counts and benchmarks.

## Current State

KotobaLab ships one Jitendex-derived Japanese-English SQLite asset. GRDB reads a
compact `words` + `meanings` schema; SwiftData stores saved word IDs separately.

Source snapshot: Jitendex.org `2026.03.05.0`, Japanese to English, CC BY-SA 4.0
with upstream JMdict (EDRDG) and Tatoeba attribution. Source JSON is local-only
under `dataset/source/` and never committed.

The current builder is an MVP projection, not a faithful importer:

- `parse.py` walks Jitendex presentation markup for a few fields.
- `transform.py` joins all glosses into one meaning row per word.
- Extracted alternative forms are not exported.
- Source revision and license metadata are not stored in SQLite.
- Autoincrement row IDs are exposed as durable saved references.

## Pipeline

```text
Jitendex Yomitan source -> load -> parse -> transform -> export SQLite
-> verify and benchmark -> GitHub Release asset -> KotobaLab/Resources
-> copied to Application Support on first launch
```

| Path | Responsibility |
| --- | --- |
| `Tools/DictionaryBuilder/main.py` | CLI and term-bank iteration |
| `pipeline/load.py` | Source discovery and JSON loading |
| `pipeline/parse.py` | Jitendex content traversal |
| `pipeline/transform.py` | Conversion into runtime records |
| `pipeline/export_sqlite.py` | Schema creation and inserts |
| `schema/dictionary_schema.sql` | Production schema and indexes |
| `debug/verify_database.py` | Hard checks: size, tables, indexes, query plans |
| `debug/benchmark_search.py` | Production-shaped search timing |
| `debug/create_test_fixture_db.py` | Generates `KotobaLabTests/Fixtures/test_dictionary.sqlite` |
| `tests/` | Self-contained pytest suite |

`dictionary.sqlite` is gitignored. Developers and iOS CI download it from the
latest GitHub Release into `KotobaLab/Resources/`. Releases replace git-lfs,
which would exhaust the free quota, and local generation, which would block
onboarding.

Search uses `term LIKE 'prefix%' OR reading LIKE 'prefix%'`. SQLite uses the two
indexes only when `PRAGMA case_sensitive_like = ON`, which `DatabaseManager`
sets.

## Commands

```bash
# Build into app resources
python3 Tools/DictionaryBuilder/main.py \
  --source dataset/source/jitendex-yomitan \
  --schema Tools/DictionaryBuilder/schema/dictionary_schema.sql \
  --output KotobaLab/Resources/dictionary.sqlite

# Verify and benchmark the same asset the app uses
python3 Tools/DictionaryBuilder/debug/verify_database.py --db KotobaLab/Resources/dictionary.sqlite
python3 Tools/DictionaryBuilder/debug/benchmark_search.py --db KotobaLab/Resources/dictionary.sqlite

# Publish: build, verify, SHA-256, gh release create; refuses existing tags
Tools/scripts/release_dictionary.sh dict-vYYYY.MM.DD
```

For any change to parsing, transformation, schema, indexes, projections, or
queries: update fixtures, run builder tests, rebuild the asset, run the
verifier and benchmark, record new measurements below, and run the affected iOS
repository and UseCase tests.

## Measurements

Artifact built 2026-07-21 from the snapshot above, measured locally:

| Property | Value |
| --- | ---: |
| SQLite size | 51.88 MB |
| Words | 293,471 |
| Meaning rows | 293,471 |
| Term equals reading | 70,640 |

| Query | Rows | Average | Plan |
| --- | ---: | ---: | --- |
| `日` | 50 | ~0.072 ms | `MULTI-INDEX OR` |
| `食` | 50 | ~0.067 ms | `MULTI-INDEX OR` |
| `見る` | 21 | ~0.036 ms | `MULTI-INDEX OR` |
| `あ` | 50 | ~0.070 ms | `MULTI-INDEX OR` |
| `zzzznotfound` | 0 | ~0.014 ms | `MULTI-INDEX OR` |

## Data Boundaries

```text
External source (e.g. Yomitan)
-> canonical source representation
-> versioned runtime pack (SQLite)
+ separate user-owned state (SwiftData)
```

- An importer decodes a provider format. Source-specific fields stay source
  concerns.
- The canonical layer keeps the smallest shared structure the app needs, with
  explicit provider-specific payload where necessary. It is not a universal
  dictionary ontology.
- SQLite is the rebuildable runtime projection, not an exchange format. Search
  projections stay lean; detail projections may carry structured forms, senses,
  tags, and restrictions.
- Saved words, history, notes, preferences, and pack registry state live
  outside dictionary assets. Replacing an asset must never silently delete
  personal data.

## Fidelity Contract

For every supported source shape:

- preserve entry, form, reading, sense, and gloss order where meaningful
- keep distinct senses distinguishable
- keep supported tags and restrictions at their correct scope
- retain enough source information for attribution and unsupported data
- report unsupported content explicitly instead of silently flattening it

Yomitan is the first external format. Its compatibility is a transport and
structural container, not shared semantics: dictionaries in the same format
encode meaning in different tags and structured-content shapes.

- The default path is a generic ordered structural projection that keeps text,
  inline formatting, ruby, lists, tables, links, and disclosures in source order,
  and renders unknown valid nodes through a visible fallback.
- A provider-specific semantic adapter is optional. It must justify its
  maintenance cost with better search, grouping, cross-references, or detail.

Phase 4 spikes showed both paths are feasible: one generic renderer displayed
Jitendex and a second, structurally different source, and a Jitendex adapter
recovered grouped senses and cross-references. See
[the Phase 4 record](archive/phase-04-system-wide-lookup-spikes.md). No spike
code is in production.

## Identity

SQLite row IDs are internal. App-facing and persisted identity is conceptually
`dictionaryID + stableSourceEntryKey`. A rebuild of the same source must
preserve logical identity or ship an explicit migration map. Equivalent-looking
entries from different providers stay distinct.

## Assets and Multiple Dictionaries

Every production asset should carry a stable dictionary ID, provider and
display information, languages, schema version, content revision and build
identity, a checksum, and license and attribution metadata.

Target activation: discover, verify integrity, check metadata and
compatibility, verify invariants, migrate user references if needed, activate
atomically, and keep or restore the previous asset on failure.

Prefer one independently versioned read-only pack per provider. Aggregate lookup
keeps source labels and a deterministic order, never compares provider-specific
frequency scales, and shows separate source sections instead of merging
definitions.

## Licensing

Application code is MIT. Every dictionary asset keeps its own provider and
upstream obligations. A bundled source must pass a redistribution,
attribution, commercial-use, maintenance, quality, size, and update-cadence
review. User-imported commercial dictionaries may be synced privately between
one user's devices but never redistributed.
