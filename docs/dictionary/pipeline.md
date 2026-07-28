# Dictionary Pipeline

Status: Active
Last updated: 2026-07-28

## Current Flow

```text
Jitendex Yomitan source
-> load term banks
-> parse supported semantic content
-> transform into runtime records
-> export SQLite
-> verify and benchmark
-> publish GitHub Release asset
-> stage in KotobaLab/Resources
-> copy to Application Support at first launch
```

Implementation lives in `Tools/DictionaryBuilder/`.

## Current Source Snapshot

The local source metadata reports:

- title: Jitendex.org [2026-03-05]
- revision: `2026.03.05.0`
- source language: Japanese
- target language: English
- license: CC BY-SA 4.0 with upstream attribution

Source JSON is local-only and not committed.

## Builder Modules

| Path | Responsibility |
| --- | --- |
| `main.py` | CLI and term-bank iteration |
| `pipeline/load.py` | source discovery and JSON loading |
| `pipeline/parse.py` | current Jitendex content traversal |
| `pipeline/transform.py` | conversion into runtime records |
| `pipeline/export_sqlite.py` | schema creation and inserts |
| `schema/dictionary_schema.sql` | production schema and indexes |
| `debug/verify_database.py` | hard database and query-plan checks |
| `debug/benchmark_search.py` | production-shaped search measurements |
| `tests/` | self-contained pytest fixtures and behavior tests |

## Outputs

| Path | Role |
| --- | --- |
| `Tools/DictionaryBuilder/output/dictionary.sqlite` | default build and release input |
| `KotobaLab/Resources/dictionary.sqlite` | gitignored app-bundle staging asset |
| `KotobaLabTests/Fixtures/test_dictionary.sqlite` | committed repository-test fixture |

## Commands

Build into app resources:

```bash
python3 Tools/DictionaryBuilder/main.py \
  --source dataset/source/jitendex-yomitan \
  --schema Tools/DictionaryBuilder/schema/dictionary_schema.sql \
  --output KotobaLab/Resources/dictionary.sqlite
```

Run builder tests:

```bash
cd Tools/DictionaryBuilder
python3 -m pytest
```

Verify and benchmark the same asset used by the app:

```bash
python3 Tools/DictionaryBuilder/debug/verify_database.py \
  --db KotobaLab/Resources/dictionary.sqlite

python3 Tools/DictionaryBuilder/debug/benchmark_search.py \
  --db KotobaLab/Resources/dictionary.sqlite
```

Publish a maintained asset:

```bash
Tools/scripts/release_dictionary.sh dict-vYYYY.MM.DD
```

The release script builds, verifies, computes SHA-256, and creates a GitHub
Release without overwriting an existing tag.

## Current Delivery Contract

`dictionary.sqlite` is ignored by git. Developers and iOS CI download it from a
GitHub Release and place it under `KotobaLab/Resources/`. On first launch,
`DatabaseManager` copies the bundled asset to Application Support.

This does not yet define app-update replacement: an existing runtime copy is
not replaced, asset metadata is absent, and initialization failure is not
recoverable. These are known product gaps, not features of the durable
[Dictionary Strategy](strategy.md).

## Current Fidelity Boundary

The current builder is not a lossless JMdict or Jitendex importer:

- `parse.py` traverses presentation-oriented content and extracts a limited set
  of fields
- `transform.py` concatenates glosses into one definition
- extracted alternative forms are not exported
- one `meanings` row is emitted per `words` row
- source revision and license metadata are not embedded in SQLite

The current [Phase 4](../phases/phase-04-dictionary-source-contract.md) defines
the supported source contract before production schema migration.

## Change Verification

When a change affects parsing, transformation, schema, indexes, projections, or
runtime queries:

1. add or update representative builder fixtures
2. regenerate the repository fixture if its contract changed
3. run the builder tests
4. build a fresh production asset
5. run hard database verification
6. run production-shaped benchmarks
7. record artifact-specific schema, count, plan, and latency changes
8. run affected iOS repository and use-case tests

Dictionary artifacts retain their provider and upstream licenses independently
of the MIT-licensed application source.
