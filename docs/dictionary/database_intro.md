# Dictionary Database Overview

Status: Active
Last updated: 2026-05-14

This document describes the current app-facing dictionary database. Design rationale and future storage rules belong in [Dictionary Database Strategy](database_strategy.md).

## Current Dictionary Schema

The current dictionary database has two main tables:

```text
words
meanings
```

### words

Stores the word identity and basic display fields.

Current fields:

- `id`
- `term`
- `reading`
- `sequence`

### meanings

Stores meanings associated with a word.

Current fields:

- `id`
- `word_id`
- `sequence`
- `part_of_speech`
- `definition_text`

`meanings.word_id` is indexed so detail queries can load meanings efficiently.

## Current App Models

The app does not expose raw database rows to features.

Feature-facing models include:

- `WordSummary`
- `WordDetail`
- `Meaning`
- `WordDetailDisplayData`

This keeps the UI independent from SQLite details.

## Query Types

### Search

Search returns a list of `WordSummary`.

It needs:

- id
- term
- reading
- preview part of speech
- preview meaning

### Detail

Detail returns `WordDetail`.

It needs:

- word identity
- display fields
- all meanings for the selected word

### Saved Words

Saved words are stored as user data in SwiftData.

The app loads saved word ids from SwiftData, then resolves those ids through the dictionary repository.

## Current Limits

The current schema is good enough for the MVP, but search behavior depends on SQLite connection configuration.

Known limits:

- prefix search scans `words` unless `PRAGMA case_sensitive_like = ON` is enabled
- there is no dedicated search ranking yet
- there is no FTS table yet
- there is no fixture database for repository tests yet

Current measured result:

- before `PRAGMA case_sensitive_like = ON`: `見る` ~16.8 ms, `zzzznotfound` ~16.2 ms, plan `SCAN words`
- after `PRAGMA case_sensitive_like = ON`: `見る` ~0.034 ms, `zzzznotfound` ~0.012 ms, plan `SEARCH words USING INDEX idx_words_term`

## Next Step

Before changing search architecture, measure:

- database size
- row counts
- query plans
- search latency
- detail latency

Then choose the simplest search design that meets product needs.
