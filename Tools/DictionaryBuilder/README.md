# Dictionary Builder

Python toolchain that builds the KotobaLab SQLite dictionary from Yomitan source
files, verifies it, and publishes it as a GitHub Release artifact.

The current builder is stable as an MVP pipeline, but its data model is
intentionally being replaced in Phase 4: it flattens extracted glosses into one
meaning row, does not export extracted alternative forms, and does not embed
source/schema metadata or stable user-facing identity. See the
[Phase 4 plan](../../docs/phases/phase-04-dictionary-fidelity.md).

## Layout

```text
Tools/DictionaryBuilder/
├── main.py                 # build entry point
├── schema/
│   └── dictionary_schema.sql
├── pipeline/
│   ├── load.py             # iterate term banks
│   ├── parse.py            # extract term / reading / pos / glosses
│   ├── transform.py        # → WordRecord + MeaningRecord
│   └── export_sqlite.py    # write to SQLite (one transaction)
├── debug/
│   ├── verify_database.py     # tables / indexes / size / query plans
│   ├── benchmark_search.py    # search latency + query plan
│   ├── create_test_fixture_db.py
│   ├── find_entry.py
│   └── inspect_entry.py
└── tests/                  # pytest, 20 cases (self-contained)
```

## Build

```bash
python3 Tools/DictionaryBuilder/main.py \
  --source dataset/source/jitendex-yomitan \
  --schema Tools/DictionaryBuilder/schema/dictionary_schema.sql \
  --output KotobaLab/Resources/dictionary.sqlite
```

`--source` defaults to `dataset/source/jitendex-yomitan` and `--output`
defaults to `Tools/DictionaryBuilder/output/dictionary.sqlite`. Override either
to direct the build at a different location.

## Test

The pipeline has a pytest suite covering `parse`, `transform`, and `export_sqlite`:

```bash
cd Tools/DictionaryBuilder && python3 -m pytest
```

The suite is self-contained — no source dataset or main database required. It
also runs in CI on every push and pull request that touches the builder
([`.github/workflows/builder-tests.yml`](../../.github/workflows/builder-tests.yml)).

## Verify

`debug/verify_database.py` hard-fails on structural regressions in the current
contract: file size over the limit, missing tables/indexes, or production-shaped
search/detail queries falling back to a table scan.

```bash
python3 Tools/DictionaryBuilder/debug/verify_database.py \
  --db KotobaLab/Resources/dictionary.sqlite
```

Default size limit is 100 MB; override with `--max-size-mb`.

## Release

For the builder maintainer, `Tools/scripts/release_dictionary.sh` composes build,
verification, SHA-256, and `gh release create` into one command:

```bash
Tools/scripts/release_dictionary.sh dict-vYYYY.MM.DD
```

It refuses to overwrite an existing tag and writes the `.sha256` file in
standard `<hash>  <filename>` format so consumers can verify with
`shasum -a 256 -c`. Releases are published at
<https://github.com/shiinayane/KotobaLab/releases>.

## Benchmark

Search query shape (from `KotobaLab/Data/Repository/Dictionary/SQLiteDictionaryRepository.swift`):

```sql
WHERE w.term LIKE ? OR w.reading LIKE ?
```

SQLite requires `PRAGMA case_sensitive_like = ON` for `LIKE 'prefix%'` to
engage `idx_words_term` and `idx_words_reading`. Without it,
`EXPLAIN QUERY PLAN` falls back to `SCAN words`. The app enables this PRAGMA in
`DatabaseManager`.

Reproduce the benchmark with:

```bash
python3 Tools/DictionaryBuilder/debug/benchmark_search.py \
  --db Tools/DictionaryBuilder/output/dictionary.sqlite
```

Recorded results are artifact- and machine-specific. The 2026-07-21 local
51.88 MB artifact (293,471 words) produced:

| Query | Rows | Average time | Query plan |
| --- | ---: | ---: | --- |
| `日` | 50 | ~0.072 ms | `MULTI-INDEX OR` |
| `食` | 50 | ~0.067 ms | `MULTI-INDEX OR` |
| `見る` | 21 | ~0.036 ms | `MULTI-INDEX OR` |
| `あ` | 50 | ~0.070 ms | `MULTI-INDEX OR` |
| `zzzznotfound` | 0 | ~0.014 ms | `MULTI-INDEX OR` |

Re-run this benchmark and update the active dictionary docs whenever schema,
indexes, projection, ranking, or result ordering changes.
