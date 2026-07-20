# Dictionary Pipeline

Status: Active
Last updated: 2026-07-21

## Current Flow

```text
Jitendex Yomitan source
-> load
-> parse semantic content
-> transform into WordRecord / MeaningRecord
-> export SQLite
-> verify + benchmark
-> GitHub Release asset
-> KotobaLab/Resources staging copy
-> Application Support runtime copy
```

Implementation: `Tools/DictionaryBuilder/`.

## Current Source

The local source snapshot reports:

- title: Jitendex.org [2026-03-05]
- revision: `2026.03.05.0`
- source language: Japanese
- target language: English
- license: CC BY-SA 4.0, with included upstream attribution described by the
  source metadata

Source JSON is local-only and not committed.

## Current Builder Modules

| File | Responsibility |
| --- | --- |
| `main.py` | CLI and file iteration |
| `pipeline/load.py` | term-bank discovery and JSON loading |
| `pipeline/parse.py` | traversal of Jitendex structured semantic content |
| `pipeline/transform.py` | conversion into current app database records |
| `pipeline/export_sqlite.py` | schema creation and inserts |
| `schema/dictionary_schema.sql` | production schema/indexes |
| `debug/verify_database.py` | hard structural/query-plan checks |
| `debug/benchmark_search.py` | production-shaped search plans/latency |
| `tests/` | self-contained pytest fixtures and behavior tests |

## Build Outputs

| Path | Role |
| --- | --- |
| `Tools/DictionaryBuilder/output/dictionary.sqlite` | canonical default builder output and release input |
| `KotobaLab/Resources/dictionary.sqlite` | gitignored app-bundle staging copy used by local builds/CI |
| `KotobaLabTests/Fixtures/test_dictionary.sqlite` | committed small repository-test fixture |

## Commands

Build directly into app resources:

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

Verify and benchmark the same artifact queried by the app:

```bash
python3 Tools/DictionaryBuilder/debug/verify_database.py \
  --db KotobaLab/Resources/dictionary.sqlite

python3 Tools/DictionaryBuilder/debug/benchmark_search.py \
  --db KotobaLab/Resources/dictionary.sqlite
```

Publish a maintained artifact:

```bash
Tools/scripts/release_dictionary.sh dict-vYYYY.MM.DD
```

The release script builds, verifies, computes SHA-256, and creates a GitHub
Release without overwriting an existing tag.

## Current Delivery Contract

`dictionary.sqlite` is ignored by git. Developers and iOS CI download it from a
GitHub Release and place it under `KotobaLab/Resources/`. On first launch,
`DatabaseManager` copies the bundle resource to Application Support.

This is adequate for development onboarding, but not yet a complete app-update
contract: an existing Application Support file is never replaced, schema/source
metadata is absent, and startup failure terminates the app. Phases 4 and 7 own
versioned activation, migration, rollback, and recovery.

## Current Fidelity Limitation

The current builder must not be described as a lossless JMdict/Jitendex import:

- `parse.py` extracts glosses/forms from presentation-oriented content.
- `transform.py` concatenates all glosses into one definition.
- extracted forms are not exported.
- one `meanings` row is emitted for every inserted `words` row.
- source revision/license metadata is not embedded in the database.

Phase 4 replaces this contract using representative real-source fixtures before
search/detail UI expands.

## Verification Policy

Every schema, parser, transform, projection, ranking, or index change must:

1. update/add builder fixtures
2. regenerate the repository fixture where required
3. run pytest
4. build a fresh production database
5. run hard database verification
6. run production-shaped benchmarks
7. update current schema/count/plan documentation
8. run iOS repository/use-case tests

Historical measurements may remain in phase records, but active docs must label
the artifact/date they describe.

## Licensing Boundary

Application source code is MIT licensed. Dictionary artifacts retain their own
provider/upstream licenses and attribution obligations. A future dictionary
pack must ship its own source/license metadata; adding a provider never inherits
the app source-code license.
