# Phase 0: Current MVP Baseline

Status: Historical
Last updated: 2026-05-20

## Goal

Phase 0 confirms that KotobaLab has a working MVP loop:

```text
Search -> Word Detail -> Save / Unsave -> Saved List -> Word Detail
```

The goal is not feature completeness. The goal is to prove the core product loop, data access path, and SwiftUI state-driven UI.

## Current Status

The current app can:

- Search dictionary entries from a local SQLite database.
- Open a word detail page.
- Save and unsave words.
- Show saved words.
- Reopen word detail from the saved list.

The architecture now includes:

- Domain entities.
- Repository protocols.
- Use cases for search, saved-word loading, detail loading, and saved-state toggling.
- SQLite repository for dictionary data.
- SwiftData repository for user data.
- Mock repositories for previews and tests.

## Completed Work

### Product

- Basic app shell and tab structure.
- Search page.
- Word detail page.
- Saved page.
- Minimal settings, study, analysis, and home placeholders.

### Dictionary

- A new `Tools/DictionaryBuilder` pipeline exists.
- The app dictionary database has been reduced from roughly 1.3GB to roughly 52MB.
- Raw import payloads are no longer kept in the app dictionary database.
- The schema now stores structured words and meanings.
- `meanings.word_id` is indexed.

### Architecture

- The project uses a lightweight MVVM + UseCase + Repository structure.
- `WordDetailStore` now delegates loading and saved-state toggling to use cases.
- Domain models are more focused on app-facing data.
- Data repositories are separated from domain protocols.

### Testing

The project now has a `KotobaLabTests` target.

Current test coverage includes:

- `SearchWordsUseCaseTests`
- `LoadSavedWordsUseCaseTests`
- `ToggleSavedWordUseCaseTests`
- `LoadWordDetailUseCaseTests`

## Verification

The following command was run:

```bash
xcodebuild test \
  -project KotobaLab.xcodeproj \
  -scheme KotobaLab \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -derivedDataPath /tmp/KotobaLabReviewDerived
```

Result:

```text
TEST SUCCEEDED
```

Ten use case tests passed.

## Key Decisions

### SQLite for Dictionary Data

Dictionary content stays in SQLite because it is structured, read-heavy, and search-oriented.

### SwiftData for User Data

User-generated data such as saved words stays in SwiftData because it is app-local state and integrates well with SwiftUI.

### Store as ViewModel

The project uses `Store` names instead of `ViewModel` names. These stores perform the ViewModel role.

## Known Risks

### Dictionary Delivery

`dictionary.sqlite` is still ignored by the generic `*.sqlite` rule. The project needs a clear delivery strategy:

- Generate it locally from `Tools/DictionaryBuilder`.
- Download it from a release artifact.
- Or explicitly track a small fixture database and distribute the full database separately.

### Search Performance

The `meanings` lookup is improved, but the current prefix search still scans `words`.

This is acceptable for the current 52MB database, but it should be measured before the dictionary grows.

### Synchronous Data Access

Repository APIs are still synchronous. If search or detail queries become more expensive, stores can still block main-actor work.

### Dependency Pinning

GRDB has since been pinned to `upToNextMajorVersion` from `7.0.0`; see [Phase 1](phase-01-pipeline-stabilization.md).

### Tooling Hygiene

Python cache files and local generated outputs should stay ignored and should not be committed.

## Non-goals

The following are not part of Phase 0:

- Backend service.
- AI features.
- Account system.
- Cloud sync.
- Full study system.
- Full UI polish.

## Next Phase

Phase 1 (Dictionary Pipeline Stabilization) has since been completed. See [`phase-01-pipeline-stabilization.md`](phase-01-pipeline-stabilization.md) for the execution record.
