# Dictionary Database Overview

Status: Active
Last updated: 2026-07-21

This document describes the database the app uses today. The target model and
multi-dictionary direction are documented separately in
[Database Strategy](database_strategy.md) and
[Multi-Dictionary Strategy](multi_dictionary_strategy.md).

## Current Artifact

Local verification on 2026-07-21:

| Property | Current value |
| --- | ---: |
| File | `KotobaLab/Resources/dictionary.sqlite` |
| Size | 51.88 MB |
| Words | 293,471 |
| Meanings | 293,471 |
| Words without a meaning | 0 |
| Words where term equals reading | 70,640 |
| Distinct POS strings | 40 |

The one-to-one word/meaning count is an implementation limitation, not a source
truth: the builder currently joins all extracted glosses into one definition
row.

The local source metadata identifies Jitendex revision `2026.03.05.0`, Japanese
source language, and English target language. The built SQLite file does not yet
store that metadata.

## Current Schema

```text
words
  id INTEGER PRIMARY KEY AUTOINCREMENT
  term TEXT NOT NULL
  reading TEXT
  sequence INTEGER

meanings
  id INTEGER PRIMARY KEY AUTOINCREMENT
  word_id INTEGER NOT NULL -> words.id
  sequence INTEGER NOT NULL
  part_of_speech TEXT
  definition_text TEXT NOT NULL
```

Indexes:

- `idx_words_term`
- `idx_words_reading`
- `idx_words_sequence`
- `idx_meanings_word_id`

## Current Query Paths

### Search Summary

`SQLiteDictionaryRepository.searchWords` searches term and reading prefixes,
limits to 20 through the UseCase, and projects the first ordered meaning:

```sql
WHERE w.term LIKE ? OR w.reading LIKE ?
```

There is no explicit production `ORDER BY`, ranking policy, normalization beyond
trimmed input, alternative-form search, or pagination.

### Word Detail

GRDB loads `WordRecord` plus ordered associated `MeaningRecord` rows. Although
the app model supports an array, the current production artifact has one meaning
row per word because of builder flattening.

### Saved Summaries

SwiftData returns saved SQLite IDs; the dictionary repository resolves summaries
with `WHERE w.id IN (...)` and restores requested order in memory.

## Current Query Plan Snapshot

`DatabaseManager` enables `PRAGMA case_sensitive_like = ON`, allowing SQLite to
use both prefix indexes.

On the 2026-07-21 artifact:

- Search: `MULTI-INDEX OR` over `idx_words_term` and `idx_words_reading`.
- Preview/detail meaning lookup: `idx_meanings_word_id`.
- Representative search averages: about 0.014–0.072 ms on the local benchmark
  environment.

These numbers describe one artifact and machine. Re-run the production-shaped
benchmark whenever schema, projection, ranking, indexes, or SQLite configuration
changes.

## Known Limitations

- Autoincrement `words.id` is incorrectly used as durable user-data identity.
- Distinct senses/glosses are flattened.
- Extracted alternative forms are discarded.
- Source tags/restrictions/examples/furigana metadata are mostly absent.
- Database schema/content/source/license versions are absent.
- There is no asset upgrade/rollback contract after first copy to Application
  Support.
- Schema and repositories assume exactly one dictionary source.

These are Phase 4 blockers, not optional long-term refinements. See
[Phase 4](../phases/phase-04-dictionary-fidelity.md).
