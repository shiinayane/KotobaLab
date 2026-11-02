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

M1 replaces this pipeline with the Swift importer in `Packages/KotobaKit`,
which the app does not use yet.

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

The Swift import below measures decoding in Swift and a preset dictionary built
without the zstd trainer.

### Swift import, 2026-11-01

`kotoba-pack` release build of `KotobaKit` pack format 1 on an Apple-silicon
Mac. Jitendex `2026.10.03.0` came from its upstream download URL as a
38,831,822-byte zip. 小学館 `rgko12;2025-08-18` was zipped locally, 79,489,317
bytes. Glossaries are JSON with sorted keys, each compressed as raw deflate at
level 6 with a 32 KB preset dictionary built during import. Megabytes are 10⁶
bytes.

| Property | Jitendex | 小学館 |
| --- | ---: | ---: |
| Entries | 436,555 | 48,523 |
| Rows that need a nonzero ordinal | 0 | 432 |
| Glossary JSON | 466.3 MB | 221.3 MB |
| Glossary compressed | 51.8 MB | 12.9 MB |
| Media | 5.0 MB, 250 files | 69.4 MB, 3,604 files |
| Pack file | 115.0 MB | 90.6 MB |
| Import time | 30.3 s | 10.7 s |
| Peak memory | 249 MB | 409 MB |
| Decode and parse one random entry | 27 µs | 54 µs |
| Import time, iPhone 16 Pro Max | 29.5 s | not measured |
| Peak memory footprint, iPhone 16 Pro Max | 202 MB | not measured |
| Decode and parse one random entry, iPhone 16 Pro Max | 34 µs | not measured |

Pack sizes include the indexes added on 2026-11-01 for search; the other rows
were measured before them, when the packs were 104.8 MB and 90.0 MB and the
indexes took 0.1 s less to build. The iPhone ran the same importer in a Release
build of a throwaway host app, once, at nominal thermal state, and wrote the
same sizes as the Mac. The upstream
download took 12.7 s on that run's network. 小学館 is user-supplied and was not
copied to the device.

The iPhone import is far inside the M1 gate of about three minutes, so pack
format 1 keeps JSON glossaries, raw deflate at level 6, and a 32 KB preset
dictionary built during import.

Compression takes 58% of the Jitendex import because every entry reloads the
preset dictionary. Trade-offs on Jitendex:

| Level | Preset dictionary | Glossary compressed | Import time |
| ---: | ---: | ---: | ---: |
| 9 | 32 KB | 49.8 MB | 36.2 s |
| 6 | 32 KB | 51.8 MB | 30.3 s |
| 6 | 16 KB | 54.7 MB | 23.0 s |
| 6 | 8 KB | 58.2 MB | 20.0 s |
| 6 | none | 172.9 MB | 19.3 s |

The preset dictionary is a greedy cover of 256-byte segments from 512 entries
sampled across up to eight term banks, scored by how many samples share each 8-byte
substring. In a Python comparison on held-out entries, with raw deflate at
level 6, it compressed 小学館 17.0 times and Jitendex 9.0 times. The last 32 KB
of a zstd-trained dictionary reached 17.9 and 9.0, and concatenated whole
entries reached 10.3 and 8.3.

In the Jitendex pack, the entries table is 79.0 MB and the term, reading, and
sequence indexes are 12.0 MB, 13.5 MB, and 5.2 MB. The 小学館 pack is mostly
media, 72.2 MB.

Jitendex `2026.10.03.0` has 10,059 rows that equal another row of the same
sequence under Unicode canonical equivalence but not by code point, such as
`御雜煮` written with U+FA48 or U+716E. Swift `String` equality treats them as
the same, so identity compares code points.

### Pack search, 2026-11-01

`kotoba-pack search` on the packs above, limit 20, same Mac. Each prefix ran
once from a fresh process and then 100 times; the average is warm. Every plan
searches both covering indexes and reads the table only for the 20 results.

| Prefix | Jitendex matches | First | Average |
| --- | ---: | ---: | ---: |
| `し` | 15,485 | 22.9 ms | 21.6 ms |
| `あ` | 7,387 | 10.8 ms | 10.5 ms |
| `た` | 6,034 | 8.6 ms | 8.3 ms |
| `食` | 577 | 1.1 ms | 0.8 ms |
| `日本` | 403 | 0.9 ms | 0.6 ms |
| `たべ` | 67 | 0.4 ms | 0.3 ms |
| `見る` | 29 | 0.3 ms | 0.2 ms |

小学館 averaged 3.2 ms for `し` and 1.5 ms for `あ`. Single-kana prefixes cost
the most because every match is ranked and grouped. Before the covering
indexes, ranking `あ` read 2,744 table pages; with them it reads 63 index pages.
Times are warm; a cold first query on a device is measured when the app adopts
packs.

Known limits: a single-kanji prefix ranks long compounds before common words,
because Jitendex scores encode priority, not frequency (`食べる` is not in the
top 20 for `食`). Hiragana and katakana do not match each other, and 19,614
Jitendex readings mix both. A redirect row is the result when only it matches,
such as `見る将` for `見る`; display should show its group's main entry.

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
- Saved words, history, notes, and preferences live outside dictionary
  assets. Replacing an asset must never silently delete personal data.

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

SQLite row IDs are internal. App-facing and persisted identity is
`dictionaryID + entryKey`:

- The dictionary ID is `indexUrl` when `index.json` has one, otherwise the
  title. Titles of updatable dictionaries carry a date, such as
  `Jitendex.org [2026-10-03]`.
- The entry key is `(sequence, term, reading, ordinal)`. `sequence` is 0 unless
  `index.json` declares `sequenced`. An empty reading takes the term. `ordinal`
  numbers rows that share the other three fields, in source order.
- Terms and readings compare by code point, never by Swift `String` equality,
  which merges CJK compatibility ideographs with their unified forms.
- A saved entry stores a snapshot: the key plus a SHA-256 fingerprint of the
  glossary. Among rows with the same sequence, term, and reading, resolving it
  prefers the row with the same fingerprint, and the same ordinal among several
  such rows. The fingerprint catches reordered homographs, which `ordinal`
  alone cannot. Without a fingerprint match, the ordinal decides only when one
  row has that identity, since homographs that were both reordered and edited
  cannot be told apart.
- Otherwise the entry has changed and is never silently replaced. Candidates
  are the rows with its identity, then rows with the same absolute sequence,
  then rows with the same term and reading. Measured on 2026-11-01 between Jitendex `2026.03.05.0`
  and `2026.10.03.0`: 1,396 keys disappeared, 1,319 of them (94%) kept their
  sequence, and 57 changed the sign of their sequence, 56 of them becoming
  redirects.
- In memory, an entry is addressed by a reference that carries the pack's
  import ID. A reference from an earlier import is rejected, because row IDs
  change on every import.

A rebuild of the same source must preserve logical identity or ship an explicit
migration map. Equivalent-looking entries from different providers stay
distinct.

## Pack Format

Each imported dictionary is one SQLite file, `KotobaKit` pack format 1. Opening
a pack checks its format version and metadata.

| Table | Contents |
| --- | --- |
| `meta` | Format version, import ID, importer version, import time, source SHA-256, `index.json`, `styles.css`, preset dictionary |
| `entries` | Term, reading, sequence, ordinal, tags, rules, score, compressed glossary |
| `tags` | Tag bank rows; the first definition of a name wins |
| `media` | Images and other files the glossaries reference, by archive path |
| `source_banks` | Raw-deflated banks the format does not read yet, such as kanji and frequency banks |

Changes follow three rules, so most changes need no source archive:

- Data columns are frozen. Changing one bumps the format version and requires
  re-importing the source.
- Indexes and derived columns are upgraded in place: on a copy, which then
  replaces the pack. A future kana-folded reading column belongs here.
- New meta keys and new tables are additive and need no version bump. The first
  in-place upgrade adds a meta key recording which upgrades a pack has; a pack
  without that key has none.

A `DictionaryPack` opened before its file was replaced or deleted never reads
the new file, but depending on the system it fails with an I/O error or keeps
reading the deleted one, so holders reopen afterwards. Reads of one pack run one at a time.

Glossaries are JSON with sorted keys, each raw-deflated on its own with the
pack's preset dictionary, so lookup decodes one entry at a time. The preset
dictionary is text both sides treat as if it came just before each entry, so
markup the entries share becomes short back-references. Jitendex `食べる` is
3,185 bytes of JSON, 808 bytes deflated alone, and 362 bytes with the preset
dictionary. The dictionary is built during import; see
[Swift import](#swift-import-2026-11-01).

Search matches a prefix of the term or reading with `GLOB`, which is
case-sensitive and so uses the indexes without `PRAGMA case_sensitive_like`.
Results rank by the length of the matched term or reading, then score, then
source order. In a `sequenced` dictionary, rows with the same absolute sequence
form one result, represented by the best-matching row: Jitendex lists each
spelling, and each redirect with a negative sequence, as its own row. The
`(term, score, sequence)` and `(reading, score, sequence)` indexes cover the
ranking, and `(sequence)` serves groups and saved-entry candidates.

## Assets and Multiple Dictionaries

Every production asset should carry a stable dictionary ID, provider and
display information, languages, schema version, content revision and build
identity, a checksum, and license and attribution metadata.

`DictionaryLibrary` in `KotobaKit` keeps the installed packs, one file per
dictionary in one directory. The directory is the registry: each pack carries
its dictionary ID, title, revision, and import time, so no separate list can
disagree with the files.

- Import writes a temporary file, moves it to a new pack file once complete,
  and only then deletes the pack of the same dictionary it replaces. No pack is
  replaced in place.
- A failed, cancelled, or out-of-space import leaves the installed packs as
  they were. There is no fixed size cap; running out of space is reported as
  its own error.
- Opening the library deletes leftover temporary files and, when an
  interrupted replacement left two packs of one dictionary, keeps the newer.
  Packs that cannot be opened are listed with their error and deleted only by
  the user.
- Source archives are not kept. A change to a pack's data columns means
  downloading recommended dictionaries again and choosing user files again.

Prefer one independently versioned read-only pack per provider. Aggregate lookup
keeps source labels and a deterministic order, never compares provider-specific
frequency scales, and shows separate source sections instead of merging
definitions.

## Licensing

Application code is MIT, so code and data from GPL projects such as Yomitan,
including its deinflection rules, are never copied into the app. Every
dictionary keeps its own provider and upstream obligations. A recommended
source must pass a license, attribution, commercial-use, maintenance, quality,
size, and update-cadence review. User-imported commercial dictionaries may be synced privately between
one user's devices but never redistributed.
