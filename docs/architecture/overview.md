# Architecture Overview

Status: Active
Last updated: 2026-07-21

## Summary

KotobaLab uses lightweight MVVM with explicit UseCase and Repository boundaries:

```text
App / Scene
-> SwiftUI View
-> @MainActor Store
-> UseCase
-> Repository Protocol
-> Repository Implementation
-> GRDB SQLite / SwiftData
```

This is intentionally not a full Clean Architecture implementation. New layers
are justified only when they isolate a real source of change, remove duplication,
or materially improve testability.

## Current Directory Map

```text
KotobaLab
├── App                 dependency composition and app shell
├── Domain
│   ├── Entity          technology-neutral product models
│   ├── Repository      data-access contracts
│   └── UseCase         business operations
├── Data
│   ├── Database        GRDB manager and database records
│   ├── Persistence     SwiftData models
│   ├── Preview         preview fixtures/helpers
│   └── Repository      concrete and mock repositories
├── Features            Scene + Store + View feature units
├── Navigation          app routing/sheets
├── Resources           bundled/staged dictionary asset
└── Shared              reusable UI components
```

## Layer Responsibilities

### App and Scene

- Construct long-lived dependencies.
- Bind concrete repositories to Domain protocols.
- Create feature Stores and inject UseCases.
- Own launch state and database compatibility/recovery in future Phase 4/7 work.

Current root composition is `KotobaLabApp -> RootView -> FeatureScene`.

### View

- Render Store state.
- Forward user actions.
- Own view-local presentation state only.
- Never query GRDB/SwiftData or construct repositories directly.

### Store

- Acts as the feature ViewModel.
- Is explicitly `@MainActor @Observable` when it owns UI-observed state.
- Models meaningful state transitions, cancellation, retry, and user action
  orchestration.
- Delegates business operations to UseCases.

Current Stores: `SearchStore`, `SavedStore`, and `WordDetailStore`.

### Domain

- Defines app-facing entities and repository contracts.
- Contains UseCases for search, detail, saved loading, and saved toggling.
- Must not import SwiftUI, SwiftData, GRDB, or SQLite row types.
- Value models crossing async dictionary boundaries should remain `Sendable`.

### Data

- Owns GRDB records, SQL/query-interface code, SQLite setup, SwiftData models,
  migrations, and concrete repository implementations.
- Converts concrete records into Domain entities.
- Keeps dictionary content and user-owned data in separate storage engines.

## Concurrency Model

The Xcode target uses `SWIFT_DEFAULT_ACTOR_ISOLATION = nonisolated`.

- UI Stores are explicitly `@MainActor`.
- `DictionaryRepositoryProtocol` methods are `async throws`.
- `SQLiteDictionaryRepository` is `Sendable` and performs reads through GRDB
  `DatabaseQueue.read`, which owns SQLite serialization.
- UseCases propagate suspension to Stores without importing GRDB.
- SwiftData repositories remain `@MainActor` because they own a main
  `ModelContext` and currently expose synchronous operations.

Do not add a custom database actor unless a measured requirement is not served
by GRDB's queue and current repository boundary.

## Persistence Boundaries

### Dictionary Data

Read-heavy reference content belongs in versioned, read-only SQLite assets.
Today there is one Jitendex-derived database. Phase 8 may generalize this to one
SQLite pack per dictionary provider while preserving a common repository model.

### User Data

Saved entries, recent lookup history, future notes, and user pack preferences
belong in SwiftData. User data must reference dictionary entries by stable,
source-aware identity rather than transient SQLite row IDs.

Dictionary records and SwiftData models must not be joined by importing one
storage technology into the other. UseCases coordinate their Domain values.

## GRDB Query Policy

Use the simplest representation that keeps the production query understandable
and testable:

- GRDB Query Interface for table relationships and ordinary typed filtering.
- Typed `SQLRequest`/`SQL` fragments when a projection or ranking query is
  clearer and more stable as SQL.
- Parameter interpolation through GRDB, never string-built user values.
- Benchmark the complete production query whenever SQL, indexes, projection,
  ranking, or result limits change.

The current summary projection intentionally uses a correlated first-meaning
subquery. The current detail query uses the `WordRecord.meanings` association.

## Feature Placement Rules

| Concern | Location |
| --- | --- |
| UI rendering | `Features/<Feature>/<Feature>View.swift` |
| UI state and actions | `Features/<Feature>/<Feature>Store.swift` |
| Dependency assembly | `Features/<Feature>/<Feature>Scene.swift` |
| Business operation | `Domain/UseCase/` |
| Technology-neutral model | `Domain/Entity/` |
| Data-access contract | `Domain/Repository/` |
| GRDB/SwiftData record and implementation | `Data/` |
| App launch/composition | `App/` |

Not every static screen needs a Store. Add a Scene/Store when the feature has
dependencies, asynchronous state, business actions, or meaningful testable
behavior.

## Current Strengths

- Dependency direction is clear and Domain remains framework-neutral.
- Dictionary I/O is async and UI state is main-actor isolated.
- Mocks and a fixture SQLite database support UseCase/repository tests.
- Dictionary and user persistence are separated.
- Builder and iOS CI protect the current foundation.

## Current Architecture Risks

- Saved user state references transient autoincrement word IDs.
- Launch composition fails with `fatalError` rather than a recoverable launch
  state.
- Dictionary asset copying has no schema/content-version upgrade contract.
- Domain entry models are too flat for source-faithful senses/forms and for
  future multiple providers.
- Store and UI state machines lack direct automated coverage.
- `AnyView` destination factories erase type information; acceptable in the
  small current shell, but re-evaluate if navigation grows rather than building
  a speculative router now.

These risks are owned by Phases 4–8 in the
[Product Roadmap](../roadmap/product_roadmap.md).
