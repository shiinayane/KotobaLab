# Dictionary Database Strategy

Status: Active
Last updated: 2026-05-14

## Summary

KotobaLab should keep dictionary content and user data in separate storage layers:

```text
Dictionary content -> SQLite
User data          -> SwiftData
```

This split is still the right direction.

SQLite is better for structured, read-heavy dictionary content and search indexes. SwiftData is better for user-generated app state such as saved words, notes, and future review progress.

## Why Not One Big Table

A dictionary app naturally has one-to-many data:

- one word can have multiple meanings
- one meaning can later have multiple examples
- one word can have tags, frequency, and user state

Putting everything into one large table works for a demo, but it becomes hard to query, hard to update, and hard to extend.

The product database should stay structured and should expose app-facing records, not raw source payloads.

## Storage Boundaries

### SQLite Owns

- Dictionary words.
- Readings.
- Meanings.
- Part-of-speech metadata.
- Future search index data.
- Future example sentence content, if bundled.

### SwiftData Owns

- Saved words.
- Future user notes.
- Future review progress.
- Future app-local learning state.

## App Database Layers

The dictionary database should eventually be treated as three logical layers.

### Search Layer

Optimized for the result list.

It should provide:

- word id
- term
- reading
- preview part of speech
- preview meaning
- ranking or priority

Search should not need full detail data.

### Detail Layer

Optimized for the word detail page.

It should provide:

- word id
- term
- reading
- meanings
- part-of-speech data
- future tags
- future examples

### Source and Debug Layer

Raw source entries and import diagnostics should not be shipped inside the app database.

They should stay in:

- source datasets
- local debug outputs
- builder logs
- local-only files

## Recommended Next Steps

1. Keep the current lean schema.
2. Keep search and detail query benchmarks documented when query SQL or schema changes.
3. Consider a dedicated search table if prefix search becomes slow.
4. Consider FTS only if real requirements need it.
5. Keep raw source data out of the app bundle.
6. Decide how the production database is generated and distributed.

## Do Not Do Yet

Avoid these until the current pipeline is stable:

- Backend dictionary sync.
- AI search.
- Complex semantic search.
- Full text search without query benchmarks.
- Mixing user data into the dictionary database.
