# Dictionary Pipeline

Status: Active
Last updated: 2026-05-10

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

The builder does not have CLI arguments yet. From the repository root, run it in the builder directory so the current relative paths resolve correctly:

```bash
(cd Tools/DictionaryBuilder && python3 main.py)
```

After the build finishes, install the generated database into the app resources:

```bash
cp Tools/DictionaryBuilder/output/dictionary.sqlite KotobaLab/Resources/dictionary.sqlite
```

Verify the app resource exists:

```bash
ls -lh KotobaLab/Resources/dictionary.sqlite
```

This is the temporary happy path for local development. It should be replaced by an argument-driven command when DictionaryBuilder is stabilized.

## Current Schema Summary

The app database currently stores:

- `words`
- `meanings`

Raw source JSON is intentionally not stored in the app database.

This keeps the app database much smaller and closer to a product database.

## Current Risks

### Hard-coded Paths

`Tools/DictionaryBuilder/main.py` currently uses hard-coded relative paths.

The builder should support CLI arguments:

```bash
python3 Tools/DictionaryBuilder/main.py \
  --source dataset/source/jitendex-yomitan \
  --schema Tools/DictionaryBuilder/schema/dictionary_schema.sql \
  --output KotobaLab/Resources/dictionary.sqlite
```

### Delivery Strategy

The app resource database is ignored by git because `*.sqlite` is ignored.

The project needs a clear answer for how contributors and CI obtain `dictionary.sqlite`.

Possible options:

- Generate it locally.
- Download it from a release artifact.
- Track a very small fixture database for tests and keep the full database external.

### Search Index

`meanings.word_id` is now indexed, but word search still needs measurement.

The next decision should be based on query timings and query plans, not on guessing.

## Next Steps

1. Add CLI arguments to DictionaryBuilder.
2. Document the official build command.
3. Add a small fixture database for repository tests.
4. Add pipeline tests for parsing and export.
5. Benchmark current search and detail queries.
