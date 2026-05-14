# Dictionary Pipeline

Status: Active
Last updated: 2026-05-14

KotobaLab uses a local dictionary database generated from source dictionary data.

## Current Flow

```text
Yomitan source data
-> Tools/DictionaryBuilder
-> SQLite dictionary.sqlite
-> App bundle resource
-> DatabaseManager
-> SQLiteDictionaryRepository
-> UseCase
-> Store
-> SwiftUI View
```

## Current Tooling

The current builder lives under:

```text
Tools/DictionaryBuilder
```

Important files:

- `main.py`: current build entry point.
- `schema/dictionary_schema.sql`: SQLite schema.
- `pipeline/load.py`: source file loading.
- `pipeline/parse.py`: semantic parsing from source entries.
- `pipeline/transform.py`: conversion into app database records.
- `pipeline/export_sqlite.py`: SQLite export logic.
- `debug/inspect_entry.py`: entry inspection helper.
- `debug/benchmark_search.py`: search query plan and latency benchmark helper.

## Current Output

The current generated database is:

```text
Tools/DictionaryBuilder/output/dictionary.sqlite
```

The app currently expects:

```text
KotobaLab/Resources/dictionary.sqlite
```

## Current Local Setup

From the repository root, generate the app resource database with:

```bash
python3 Tools/DictionaryBuilder/main.py \
  --source dataset/source/jitendex-yomitan \
  --schema Tools/DictionaryBuilder/schema/dictionary_schema.sql \
  --output KotobaLab/Resources/dictionary.sqlite
```

Verify the app resource exists:

```bash
ls -lh KotobaLab/Resources/dictionary.sqlite
```

This is the current local development path. The production delivery strategy is still undecided.

## Current Schema Summary

The app database currently stores:

- `words`
- `meanings`

Raw source JSON is intentionally not stored in the app database.

This keeps the app database much smaller and closer to a product database.

## Current Risks

### Build Command

`Tools/DictionaryBuilder/main.py` supports CLI arguments for source, schema, and output paths. This is good enough for local generation, but the project still needs a CI/release story for how the generated database is provided to new environments.

### Delivery Strategy

The app resource database is ignored by git because `*.sqlite` is ignored.

The project needs a clear answer for how contributors and CI obtain `dictionary.sqlite`.

Possible options:

- Generate it locally.
- Download it from a release artifact.
- Track a very small fixture database for tests and keep the full database external.

### Search Index

`meanings.word_id` is now indexed.

Prefix search has a measured dependency on SQLite `LIKE` behavior. Without `PRAGMA case_sensitive_like = ON`, SQLite scans `words`. With the PRAGMA enabled, the same prefix search can use `idx_words_term`.

Benchmark record:

| Setting | Query | Average time | Query plan |
| --- | --- | ---: | --- |
| Before `PRAGMA case_sensitive_like = ON` | `見る` | ~16.8 ms | `SCAN words` |
| Before `PRAGMA case_sensitive_like = ON` | `zzzznotfound` | ~16.2 ms | `SCAN words` |
| After `PRAGMA case_sensitive_like = ON` | `見る` | ~0.034 ms | `SEARCH words USING INDEX idx_words_term` |
| After `PRAGMA case_sensitive_like = ON` | `zzzznotfound` | ~0.012 ms | `SEARCH words USING INDEX idx_words_term` |

The app enables this PRAGMA in `DatabaseManager`.

## Next Steps

1. Decide the production delivery path for `dictionary.sqlite`.
2. Add a small fixture database for repository tests.
3. Add pipeline tests for parsing and export.
4. Keep benchmark records current when schema or search SQL changes.
