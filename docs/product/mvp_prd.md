# MVP Product Requirements

Status: Active
Last updated: 2026-05-10

## Product

KotobaLab is a native Apple app for Japanese vocabulary lookup and lightweight study.

The first product version should focus on one core loop:

```text
Search -> Word Detail -> Save -> Saved List -> Reopen Detail
```

## MVP Goal

The MVP should prove that the app can:

- search a local dictionary
- show useful word details
- save words locally
- browse saved words
- keep the app responsive and understandable

The MVP is not a full language learning platform.

## Target Users

Primary users:

- the developer
- intermediate Japanese learners
- users who need quick dictionary lookup

The product tone should be closer to a focused dictionary and study tool than to a course app or entertainment app.

## In Scope

### Search

Users can search dictionary entries.

The search result list should show:

- term
- reading
- preview meaning
- part of speech when available

The search page should handle:

- empty query
- no results
- loading state
- errors

### Word Detail

Users can open a word detail page.

The detail page should show:

- term
- reading
- meanings
- part-of-speech data
- saved state

### Saved Words

Users can save and unsave words.

Users can browse saved words and reopen detail pages.

### Local Persistence

Dictionary content is local SQLite data.

User data is local SwiftData data.

## Out of Scope for MVP

The following are intentionally out of scope:

- account system
- cloud sync
- backend service
- AI explanations
- AI examples
- social features
- full study scheduling
- advanced semantic search
- full UI polish

## MVP Acceptance Criteria

The MVP is acceptable when:

- Search returns correct local dictionary results.
- Word detail opens reliably.
- Save and unsave work consistently.
- Saved list reflects saved state.
- The app can be built from a clean checkout plus documented local data setup.
- Core use cases have unit tests.
- The dictionary generation path is documented.

## Current Status

Current implementation status:

- Search, detail, and saved flows exist.
- Use cases exist for the core app loop.
- Unit tests cover the current use cases.
- The dictionary database has been reduced significantly.
- Documentation has been reorganized.

Main remaining MVP gaps:

- document and stabilize dictionary database delivery
- improve or benchmark search query performance
- pin GRDB dependency
- move repository APIs toward async boundaries if needed
- improve core page UX and empty states
