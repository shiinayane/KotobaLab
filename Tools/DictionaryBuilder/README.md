# Dictionary Builder

Python toolchain that builds the KotobaLab SQLite dictionary from Yomitan source files, verifies it, and publishes it as a GitHub Release artifact.

## Layout

```
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
└── tests/                  # pytest, 16 cases (self-contained)
```

## Build

```bash
python3 Tools/DictionaryBuilder/main.py \
  --source dataset/source/jitendex-yomitan \
  --schema Tools/DictionaryBuilder/schema/dictionary_schema.sql \
  --output KotobaLab/Resources/dictionary.sqlite
```

`--source` defaults to `dataset/source/jitendex-yomitan` and `--output` defaults to `Tools/DictionaryBuilder/output/dictionary.sqlite`. Override either to direct the build at a different location.

## Test

The pipeline has a pytest suite covering `parse`, `transform`, and `export_sqlite`:

```bash
cd Tools/DictionaryBuilder && python3 -m pytest
```

The suite is self-contained — no source dataset or main database required. It also runs in CI on every push and pull request that touches the builder ([`.github/workflows/builder-tests.yml`](../../.github/workflows/builder-tests.yml)).

## Verify

`debug/verify_database.py` hard-fails on any structural regression in a built database (file size over the limit, missing tables / indexes, search or detail queries falling back to a table scan):

```bash
python3 Tools/DictionaryBuilder/debug/verify_database.py \
  --db KotobaLab/Resources/dictionary.sqlite
```

Default size limit is 100 MB; override with `--max-size-mb`.

## Release

For the builder maintainer, `Tools/scripts/release_dictionary.sh` composes build + verify + SHA-256 + `gh release create` into one command:

```bash
Tools/scripts/release_dictionary.sh dict-vYYYY.MM.DD
```

It refuses to overwrite an existing tag and writes the `.sha256` file in standard `<hash>  <filename>` format so consumers can verify with `shasum -a 256 -c`. Releases are published at <https://github.com/shiinayane/KotobaLab/releases>.

## Benchmark

Search query shape (from `KotobaLab/Data/Repository/Dictionary/SQLiteDictionaryRepository.swift`):

```sql
WHERE w.term LIKE ? OR w.reading LIKE ?
```

SQLite requires `PRAGMA case_sensitive_like = ON` for `LIKE 'prefix%'` to engage `idx_words_term` and `idx_words_reading`. Without it, `EXPLAIN QUERY PLAN` falls back to `SCAN words`. The app enables this PRAGMA in `DatabaseManager`.

Reproduce the benchmark with:

```bash
python3 Tools/DictionaryBuilder/debug/benchmark_search.py \
  --db Tools/DictionaryBuilder/output/dictionary.sqlite
```

Recorded results (293,471 rows):

| Setting | Query | Average time | Query plan |
| --- | --- | ---: | --- |
| Before `PRAGMA case_sensitive_like = ON` | `見る` | ~16.8 ms | `SCAN words` |
| Before `PRAGMA case_sensitive_like = ON` | `zzzznotfound` | ~16.2 ms | `SCAN words` |
| After `PRAGMA case_sensitive_like = ON` | `見る` | ~0.034 ms | `MULTI-INDEX OR` (`idx_words_term` + `idx_words_reading`) |
| After `PRAGMA case_sensitive_like = ON` | `zzzznotfound` | ~0.012 ms | `MULTI-INDEX OR` (`idx_words_term` + `idx_words_reading`) |
