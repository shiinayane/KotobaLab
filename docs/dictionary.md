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

Search uses `term LIKE 'prefix%' ESCAPE '\' OR reading LIKE 'prefix%' ESCAPE '\'`.
The repository escapes `\`, `%`, and `_` in user input so they match literally;
the verifier and benchmark use the same escaping. SQLite uses the two indexes
only when `PRAGMA case_sensitive_like = ON`, which `DatabaseManager` sets.

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

Asset `dictionary.sqlite` built from the snapshot above (54,394,880 bytes).
Counts verified and search measured locally on 2026-10-17, after adding
`ESCAPE`. Rows use the benchmark limit of 50, not the app limit of 20.

| Property | Value |
| --- | ---: |
| SQLite size | 51.88 MB |
| Words | 293,471 |
| Meaning rows | 293,471 |
| Term equals reading | 70,640 |

| Query | Rows | Average | Plan |
| --- | ---: | ---: | --- |
| `日` | 50 | ~0.070 ms | `MULTI-INDEX OR` |
| `食` | 50 | ~0.069 ms | `MULTI-INDEX OR` |
| `見る` | 21 | ~0.038 ms | `MULTI-INDEX OR` |
| `あ` | 50 | ~0.071 ms | `MULTI-INDEX OR` |
| `zzzznotfound` | 0 | ~0.013 ms | `MULTI-INDEX OR` |
| `%` | 0 | ~0.013 ms | `MULTI-INDEX OR` |

### Native-rendering spike, 2026-10-29

The spike rendered Jitendex `2026.03.05.0` and the user-supplied
小学館例解学習国語 第十二版 (`rgko12;2025-08-18`) with one engine and no
per-dictionary parser.

All 30 samples, 10 from Jitendex and 20 from 小学館, were compared with a
WebKit reference on the iOS 26 Simulator in light mode, and four of them in dark
mode. Most were visually near-identical. The remaining differences match the known gaps under
Rendering.

Full-dictionary style resolution on macOS. A note is layout-affecting unless it
only changes typographic detail such as `word-break` or font family.

| Dictionary | Entries | Unsupported selectors | Layout-affecting notes | Row span or SVG |
| --- | ---: | ---: | ---: | ---: |
| Jitendex | 427,064 | 0 | 0.00% | 0.34% |
| 小学館 | 48,523 | 5, appendix only | 19.45% | 0.04% |

For 小学館, 16.06% of entries are flex labels that render correctly as inline
labels. Vertical writing affects 3.14% and grid placement 0.89%.

Release build on iPhone 16 Pro Max, style and render-model construction:

| Sample | Elements | Time |
| --- | ---: | ---: |
| 掛ける (Jitendex) | 542 | 12.9 ms |
| 犯す (小学館) | 289 | 12.5 ms |
| 小倉百人一首 appendix (小学館) | 15,290 | 111.3 ms |

### Structured-content compression, 2026-10-30

Storage for each entry's Yomitan structured content, which the native renderer
needs and the current asset does not keep. Every entry is compressed on its own
so lookup can decode one entry. Interned binary replaces tags, keys, and
repeated values with indexes into a per-dictionary table. The zstd trained
dictionary is 112 KB, trained on 20,000 random entries; the zlib preset
dictionary is its last 32 KB. Sizes include these dictionaries.

| Encoding | 小学館 | Jitendex, estimate |
| --- | ---: | ---: |
| JSON | 221.3 MB | 457 MB |
| JSON, zlib per entry | 35.6 MB | 171 MB |
| JSON, zlib with preset dictionary | 11.6 MB | 50 MB |
| Interned binary, zlib with preset dictionary | 9.0 MB | 44 MB |
| Interned binary, zstd with trained dictionary | 7.5 MB | 43 MB |

小学館 was measured in full with zstd level 19. Jitendex is ten times a
one-in-ten sample of 42,707 entries with zstd level 12; its per-entry zlib
estimate matches a full-dictionary run. zlib used level 9. Decoding one entry
with zlib and a preset dictionary took 3–4 µs in Python.

Not measured: decoding in Swift on a device, building a preset dictionary
without the zstd trainer, and the plain text that search still needs.

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

## Rendering

Decision, 2026-10-29: dictionary entries render natively by default.

- A CSS subset engine applies each dictionary's own `styles.css` with browser
  semantics: nesting, cascade and specificity, `:has()`, `:not()`,
  `::before`/`::after`, `var()`, `calc()`, and `color-mix()`. Theme variables
  map to system colors, so light and dark mode follow the platform.
- TextKit 2 lays out text, ruby, and selection. SwiftUI lays out boxes, lists,
  tables, images, and disclosures. Decorated inline labels are drawn as
  attachments.
- CSS the engine cannot honor degrades to readable structure and is reported.
  Content is never dropped silently.
- WebKit is not the display path. It may serve as an optional per-dictionary
  view of the original styling, and as an import-time tool, for example to
  rasterize SVG images.
- Known gaps: vertical writing mode, grid placement, row spans, SVG images,
  gradients (approximated by their first color), ruby inside decorated labels,
  and hanging indents.

The evidence is the native-rendering spike under Measurements. Its code is
reference material only and is not part of production.

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
