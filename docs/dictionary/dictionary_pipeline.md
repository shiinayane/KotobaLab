# Dictionary Pipeline

Status: Active
Last updated: 2026-05-21

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

This is the current local development path and is consistent with the release artifact delivery strategy below.

## Current Schema Summary

The app database currently stores:

- `words`
- `meanings`

Raw source JSON is intentionally not stored in the app database.

This keeps the app database much smaller and closer to a product database.

## Delivery Strategy

The app resource database `dictionary.sqlite` is intentionally ignored by git (`*.sqlite` rule).

The production delivery path is **GitHub Release artifact**:

- The full prebuilt `dictionary.sqlite` is published as an asset of a tagged GitHub Release at
  `https://github.com/shiinayane/KotobaLab/releases/latest`.
- Ordinary developers and CI obtain the database by downloading this artifact. They do **not** need to install the Python pipeline or the source dataset.
- Only the builder maintainer needs the source dataset (`dataset/source/jitendex-yomitan`) and runs `Tools/DictionaryBuilder/main.py` to regenerate and publish a new release.

### Onboarding flow

```text
1. git clone git@github.com:shiinayane/KotobaLab.git
2. Download dictionary.sqlite from the latest GitHub Release
3. Place it at KotobaLab/Resources/dictionary.sqlite
4. Open KotobaLab.xcodeproj and build
```

### Re-generating the database (builder maintainer only)

For a one-shot build + verify + publish, use the helper script:

```bash
Tools/scripts/release_dictionary.sh dict-v2026.05.21
```

The script builds the database with `main.py`, runs `verify_database.py`,
computes a SHA-256, and creates a tagged GitHub Release with both the
`dictionary.sqlite` artifact and the checksum attached. It refuses to
overwrite an existing release tag.

Manual equivalent, if you want to drive the steps individually:

```text
1. Obtain the jitendex-yomitan source dataset (see jitendex upstream).
2. Place it under dataset/source/jitendex-yomitan.
3. Run the build command above to produce a fresh dictionary.sqlite.
4. Verify it (see "Database verification").
5. Tag a new GitHub Release and upload the artifact.
```

### License attribution

The shipped `dictionary.sqlite` is a derivative work of [JMdict](https://www.edrdg.org/jmdict/j_jmdict.html) via [jitendex-yomitan](https://github.com/stephenmk/jitendex), distributed under **CC BY-SA 4.0**. The KotobaLab app must surface this attribution in its in-app acknowledgements before any App Store release.

## Database verification

`Tools/DictionaryBuilder/debug/verify_database.py` provides a single command that fails hard on any structural regression in the generated database:

```bash
python3 Tools/DictionaryBuilder/debug/verify_database.py \
  --db KotobaLab/Resources/dictionary.sqlite
```

It checks:

- file existence and that the path is a regular file
- file size against `--max-size-mb` (default **100 MB** hard limit)
- presence of required tables (`words`, `meanings`)
- presence of required indexes (`idx_words_term`, `idx_words_reading`, `idx_meanings_word_id`)
- that the search query plan uses `idx_words_term` (not `SCAN words`)
- that the meaning detail query plan uses `idx_meanings_word_id` (not `SCAN meanings`)

Any failure raises `RuntimeError` and aborts the script with a non-zero exit, so this can be wired into release-time verification.

## Current Risks

### Build Command

`Tools/DictionaryBuilder/main.py` supports CLI arguments for source, schema, and output paths. The release pipeline is driven by `Tools/scripts/release_dictionary.sh`, which composes build + verify + upload into a single command (see "Re-generating the database" above).

### Search Index

The schema declares four indexes: `idx_words_term`, `idx_words_reading`, `idx_words_sequence`, and `idx_meanings_word_id`.

Prefix search has a measured dependency on SQLite `LIKE` behavior. Without `PRAGMA case_sensitive_like = ON`, SQLite falls back to `SCAN words`. With the PRAGMA enabled, the repository's `WHERE w.term LIKE ? OR w.reading LIKE ?` resolves to a `MULTI-INDEX OR` plan using `idx_words_term` + `idx_words_reading`.

Benchmark record:

| Setting | Query | Average time | Query plan |
| --- | --- | ---: | --- |
| Before `PRAGMA case_sensitive_like = ON` | `見る` | ~16.8 ms | `SCAN words` |
| Before `PRAGMA case_sensitive_like = ON` | `zzzznotfound` | ~16.2 ms | `SCAN words` |
| After `PRAGMA case_sensitive_like = ON` | `見る` | ~0.034 ms | `MULTI-INDEX OR` (`idx_words_term` + `idx_words_reading`) |
| After `PRAGMA case_sensitive_like = ON` | `zzzznotfound` | ~0.012 ms | `MULTI-INDEX OR` (`idx_words_term` + `idx_words_reading`) |

The app enables this PRAGMA in `DatabaseManager`.

## Next Steps

1. Keep benchmark records current when schema or search SQL changes.
2. Align `verify_database.py` search-plan check with the app's actual `WHERE term LIKE ? OR reading LIKE ?` SQL shape.
