# Product Roadmap

Status: Active
Last updated: 2026-05-21

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

Status: **Completed**. Execution record: [`docs/phases/phase-01-pipeline-stabilization.md`](../phases/phase-01-pipeline-stabilization.md).

Goal:

Make the dictionary database reproducible, lean, and measurable.

Tasks (all closed):

- ✅ Keep the DictionaryBuilder CLI command documented.
- ✅ Keep raw source data out of the app database.
- ✅ Add database size checks (`verify_database.py` enforces a 100 MB hard limit).
- ✅ Keep query plan checks for important queries (`verify_database.py` + benchmark records).
- ✅ Add a small fixture database for tests (`KotobaLabTests/Fixtures/test_dictionary.sqlite`).
- ✅ Decide how the production database is delivered (GitHub Release artifact; `Tools/scripts/release_dictionary.sh` for builder maintainer).

Completion criteria (all met):

- ✅ A clean checkout can obtain `dictionary.sqlite` from the latest GitHub Release.
- ✅ Search, detail, and saved flows still pass tests.
- ✅ The database size is understood and intentional (52 MB / 293,471 words / 4 indexes).
- ✅ Query plans for critical paths are documented (benchmark tables in `docs/dictionary/`).

## Phase 2: Core App Experience

Status: **Completed**. Execution record: [`docs/phases/phase-02-core-experience.md`](../phases/phase-02-core-experience.md).

Goal:

Make the app feel like a real dictionary MVP instead of a demo.

Tasks:

- ✅ Improve Search empty, loading, and error states (explicit `SearchViewState`).
- ✅ Word Detail information hierarchy — resolved by design (term + reading shown intentionally).
- ✅ Saved list refresh behavior — already consistent via `onAppear` re-fire on pop.
- ✅ Add explicit Search state.
- ✅ Keep previews working (preview mocks now tracked).
- ✅ Remove or hide unfinished product surfaces (Analysis / Study hidden).

Completion criteria:

- ✅ The core flow is understandable without explanation.
- ✅ Search feels responsive.
- ✅ Saved state stays consistent.
- ⚠️ Main pages no longer feel like placeholders — partially met; the Home landing
  tab still shows empty stubs (carryover, see execution record).

## Phase 3: Architecture and Tests

Status: **Planned**. Execution record: [`docs/phases/phase-03-architecture-tests.md`](../phases/phase-03-architecture-tests.md).

Goal:

Make the current lightweight architecture durable.

Tasks:

- Decide whether repository APIs should become async (or move behind a database actor).
- Mark `WordDetailStore` and `SavedStore` `@MainActor` (only `SearchStore` is today).
- Add iOS xcodebuild CI to GitHub Actions.
- Align `verify_database.py` search-plan check with the app's actual two-column SQL.
- Keep Domain free of SwiftUI, SwiftData, GRDB, and SQLite row types — currently clean; preserve.
- Keep local experiments out of the app target — already satisfied (`TestView` gitignored + target-excluded).

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

With Phase 2 (Core App Experience) closed, the immediate next priorities sit in Phase 3 (Architecture and Tests):

1. Decide whether repository APIs should become `async`, or move behind a database actor.
2. Mark `WordDetailStore` and `SavedStore` as `@MainActor` (only `SearchStore` is today).
3. Add iOS `xcodebuild` CI to GitHub Actions.
4. Align `verify_database.py`'s search-plan check with the app's actual two-column `LIKE` SQL.

Phase 2 carryover to fold in opportunistically: hide or fill the Home landing tab,
resolve the Settings → Profile dead-end, and confirm `TestView` is out of the app
build target.

## What Not To Do Next

Do not prioritize:

- backend first
- AI chat first
- complex cloud sync
- advanced study system
- broad UI redesign

The strongest path is to finish the local-first dictionary foundation first.
