# Product Roadmap

Status: Active
Last updated: 2026-05-20

## Positioning

KotobaLab should be positioned as:

```text
An offline-first Japanese dictionary and study app,
enhanced by AI explanations and personalized learning tools.
```

The dictionary should remain the product foundation. Backend and AI features should support the dictionary experience, not replace it.

## Strategic Order

Recommended order:

1. Stabilize the dictionary pipeline.
2. Polish the core app experience.
3. Strengthen architecture and tests.
4. Add minimal backend support only where local-first is not enough.
5. Experiment with AI features.
6. Productize AI only after cost, cache, and quality controls exist.

Do not start with backend or AI. The current core value is the dictionary and saved-word learning loop.

## Relationship to Phase Records

This document is the plan. `docs/phases/` is the execution record.

Create a new phase document only when a phase is started or completed. Do not treat planned roadmap sections as proof that the work has already been done.

## Phase 1: Dictionary Pipeline Stabilization

Goal:

Make the dictionary database reproducible, lean, and measurable.

Tasks:

- Keep the DictionaryBuilder CLI command documented.
- Keep raw source data out of the app database.
- Add database size checks.
- Keep query plan checks for important queries.
- Add a small fixture database for tests.
- Decide how the production database is delivered.

Completion criteria:

- A clean checkout can produce or obtain `dictionary.sqlite`.
- Search, detail, and saved flows still work.
- The database size is understood and intentional.
- Query plans for critical paths are documented.

## Phase 2: Core App Experience

Goal:

Make the app feel like a real dictionary MVP instead of a demo.

Tasks:

- Improve Search empty, loading, and error states.
- Improve Word Detail information hierarchy.
- Improve Saved list refresh behavior.
- Add explicit Search state.
- Keep previews working.
- Remove or hide unfinished product surfaces.

Completion criteria:

- The core flow is understandable without explanation.
- Search feels responsive.
- Saved state stays consistent.
- Main pages no longer feel like placeholders.

## Phase 3: Architecture and Tests

Goal:

Make the current lightweight architecture durable.

Tasks:

- Decide whether repository APIs should become async.
- Mark all stores `@MainActor` (only `SearchStore` is today).
- Add iOS xcodebuild CI to GitHub Actions.
- Align `verify_database.py` search-plan check with the app's actual two-column SQL.
- Keep Domain free of SwiftUI, SwiftData, GRDB, and SQLite row types.
- Keep local experiments out of the app target.

Phase 3 inherits these from Phase 1 as completed prerequisites:

- ✅ Repository tests with a fixture SQLite database.
- ✅ DictionaryBuilder pipeline tests (16 pytest cases + GitHub Actions CI).
- ✅ GRDB pinned to `7.0.0+`.

Completion criteria:

- New feature code has an obvious home.
- Core domain behavior is tested.
- Data layer changes can be validated without manually running the app.

## Phase 4: Minimal Backend

Goal:

Add backend support only for work that does not belong on device.

Potential backend responsibilities:

- dictionary asset manifest
- dictionary asset download metadata
- AI API proxy
- basic logging and rate limiting

Avoid early:

- full account system
- complex sync
- social features
- admin dashboard

Example manifest endpoint:

```text
GET /dictionary/manifest
```

Example response:

```json
{
  "latestDictionaryVersion": "2026.05.01",
  "assets": [
    {
      "name": "dictionary.sqlite",
      "url": "https://example.com/dictionary.sqlite",
      "sha256": "...",
      "size": 54525952
    }
  ]
}
```

## Phase 5: AI Experiments

Goal:

Validate whether AI improves the learning experience.

Good first experiments:

- AI word explanation.
- AI example sentence generation.
- Nuance comparison.
- Saved-word quiz generation.

Rules:

- Dictionary data is the source of truth.
- AI output should be clearly marked.
- AI should receive grounded word data from the dictionary.
- AI output should be structured for UI rendering.

Example structured output:

```json
{
  "simpleExplanation": "...",
  "nuance": "...",
  "examples": [
    {
      "ja": "...",
      "en": "...",
      "level": "N4"
    }
  ],
  "commonMistakes": ["..."]
}
```

## Phase 6: AI Productization

Goal:

Make AI sustainable instead of a demo feature.

Tasks:

- cache AI results
- version prompts
- add rate limiting
- control cost
- add failure fallback
- collect quality feedback
- avoid hallucinated dictionary facts

Suggested cache key:

```text
word_id + prompt_version + user_level + language
```

## Current Priorities

With Phase 1 (Dictionary Pipeline Stabilization) closed, the immediate next priorities sit in Phase 2 (Core App Experience):

1. Improve Search and Word Detail UX (empty / loading / error states, info hierarchy).
2. Model search state explicitly with an `enum`, replacing the current flat `query` + `results`.
3. Improve Saved list refresh behavior.
4. Keep search benchmark records current as schema or SQL evolves.

## What Not To Do Next

Do not prioritize:

- backend first
- AI chat first
- complex cloud sync
- advanced study system
- broad UI redesign

The strongest path is to finish the local-first dictionary foundation first.
