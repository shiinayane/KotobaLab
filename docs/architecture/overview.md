# Architecture Overview

Status: Active
Last updated: 2026-05-14

## Summary

KotobaLab currently uses a lightweight layered architecture:

```text
SwiftUI View
-> Store
-> UseCase
-> Repository Protocol
-> Repository Implementation
-> SQLite / SwiftData
```

This is best described as MVVM with UseCase and Repository boundaries. It is not a full Clean Architecture implementation, and it does not need to become one yet. The current priority is to keep dependency direction clear, keep features testable, and keep the data layer replaceable.

## Directory Map

```text
KotobaLab
├── App
├── Domain
│   ├── Entity
│   ├── Repository
│   └── UseCase
├── Data
│   ├── Database
│   ├── Persistence
│   ├── Preview
│   └── Repository
├── Features
├── Navigation
├── Resources
└── Shared
```

## Layer Responsibilities

### App

The `App` layer creates root dependencies and assembles the app shell.

Current examples:

- `KotobaLabApp`
- `AppDependencies`
- `TabContainer`

### Domain

The `Domain` layer owns technology-neutral app concepts.

It contains:

- Entities such as `WordSummary`, `WordDetail`, and `Meaning`.
- Repository protocols such as `DictionaryRepositoryProtocol` and `UserDataRepositoryProtocol`.
- Use cases such as `SearchWordsUseCase`, `LoadSavedWordsUseCase`, `LoadWordDetailUseCase`, and `ToggleSavedWordUseCase`.

Domain should not depend on SwiftUI, SwiftData, GRDB, SQLite rows, or app framework details.

### Data

The `Data` layer owns concrete persistence and repository implementations.

Current data sources:

- SQLite via GRDB for dictionary content.
- SwiftData for user-generated data such as saved words.
- Mock repositories for previews and tests.

### Features

Each feature should keep UI rendering, UI state, and dependency assembly separate.

Current pattern:

```text
FeatureScene
-> FeatureStore
-> FeatureView
```

The scene assembles dependencies, the store owns UI state, and the view renders state.

## MVVM Mapping

The project uses `Store` instead of `ViewModel`, but the role is the same.

| MVVM concept | Current implementation |
| --- | --- |
| View | `SearchView`, `SavedView`, `WordDetailView` |
| ViewModel | `SearchStore`, `SavedStore`, `WordDetailStore` |
| Model | `WordSummary`, `WordDetail`, `Meaning` |
| Service boundary | Repository protocols |
| Data source | SQLite, SwiftData |

## Dependency Direction

The intended dependency flow is:

```text
App / Scene
  -> Feature View
  -> Store
  -> UseCase
  -> Repository Protocol
  -> Repository Implementation
  -> SQLite / SwiftData
```

Views should not directly depend on SQLite, SwiftData, GRDB, or concrete repositories.

## Current Strengths

- The core app is no longer view-driven only.
- Use cases now cover search, saved-word loading, word-detail loading, and saved-state toggling.
- Mock repositories make use case tests straightforward.
- The dictionary database has moved toward a reproducible build pipeline.
- The documentation structure now separates product, dictionary, architecture, roadmap, and phase records.

## Current Weak Points

### Synchronous Repository APIs

Repository protocols are still synchronous. Because stores run on the main actor, database work can still block UI work if queries become expensive.

Future direction:

- Make dictionary repository APIs async.
- Or isolate SQLite access behind a dedicated database actor.
- Keep state mutation on the main actor.

### Search Query Plan

The schema has four indexes: `idx_words_term`, `idx_words_reading`, `idx_words_sequence`, and `idx_meanings_word_id`. Prefix search depends on `PRAGMA case_sensitive_like = ON`; without it SQLite scans `words`, and with it SQLite uses a `MULTI-INDEX OR` plan over `idx_words_term` and `idx_words_reading` because the repository's `WHERE w.term LIKE ? OR w.reading LIKE ?` covers both columns.

Current benchmark record:

- before PRAGMA: `見る` ~16.8 ms, `zzzznotfound` ~16.2 ms, plan `SCAN words`
- after PRAGMA: `見る` ~0.034 ms, `zzzznotfound` ~0.012 ms, plan `MULTI-INDEX OR` using `idx_words_term` + `idx_words_reading`

Future direction:

- Keep benchmark records current.
- Consider a dedicated search table.
- Consider FTS only after measuring actual search needs.

### Dependency Pinning

GRDB is pinned to `upToNextMajorVersion` from `7.0.0` in `KotobaLab.xcodeproj/project.pbxproj`.

### Target Hygiene

The project now has target exceptions for `Features/TestView`, which is an improvement. The long-term goal is still to keep local experiments out of the app target entirely.

## Near-term Architecture Tasks

1. Add explicit search state instead of only `query` and `results`.
2. Design async repository or database actor boundaries.
3. Mark `WordDetailStore` and `SavedStore` as `@MainActor` to match `SearchStore`.

## Placement Rules

Use these rules when adding new code:

- UI rendering: `Features/<Feature>/<Feature>View.swift`
- UI state and user action orchestration: `Features/<Feature>/<Feature>Store.swift`
- Feature assembly: `Features/<Feature>/<Feature>Scene.swift`
- Business operation: `Domain/UseCase`
- Technology-neutral model: `Domain/Entity`
- Data access contract: `Domain/Repository`
- SQLite or SwiftData implementation: `Data/Repository`
- App-level composition: `App`

Do not add a new layer unless it reduces duplication, isolates real change, or improves testability.
