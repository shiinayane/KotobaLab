# Architecture Overview

Status: Active
Last updated: 2026-07-28

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

This is not a full Clean Architecture implementation. Add a layer only when it
isolates a real source of change, removes duplication, or materially improves
testability.

## Directory Map

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
│   ├── Preview         preview fixtures and helpers
│   └── Repository      concrete and mock repositories
├── Features            Scene + Store + View feature units
├── Navigation          app routing and sheets
├── Resources           staged dictionary asset
└── Shared              reusable UI components
```

## Layer Responsibilities

### App and Scene

- Construct long-lived dependencies.
- Bind concrete repositories to Domain protocols.
- Create feature Stores and inject UseCases.
- Own application launch and dependency readiness.

Current root composition is `KotobaLabApp -> RootView -> FeatureScene`.

### View

- Render Store state and forward user actions.
- Own only view-local presentation state.
- Never query GRDB or SwiftData or construct repositories directly.

### Store

- Acts as the feature ViewModel.
- Is explicitly `@MainActor @Observable` when state is observed by UI.
- Models meaningful loading, empty, loaded, error, retry, and cancellation
  transitions.
- Delegates business operations to UseCases.

### Domain

- Defines app-facing entities, repository contracts, and UseCases.
- Must not import SwiftUI, SwiftData, GRDB, or SQLite row types.
- Keeps values crossing async dictionary boundaries `Sendable` where required.

### Data

- Owns GRDB records and queries, SQLite setup, SwiftData models, migrations, and
  concrete repository implementations.
- Converts storage-specific records into Domain entities.
- Keeps dictionary content and user-owned data in separate storage engines.

## Concurrency

The Xcode target uses `SWIFT_DEFAULT_ACTOR_ISOLATION = nonisolated`.

- UI Stores are explicitly `@MainActor`.
- `DictionaryRepositoryProtocol` methods are `async throws`.
- `SQLiteDictionaryRepository` is `Sendable` and reads through GRDB
  `DatabaseQueue.read`.
- UseCases propagate suspension without importing GRDB.
- SwiftData repositories remain `@MainActor` while they own a main
  `ModelContext`.

Do not add a custom database actor unless a measured requirement is not served
by GRDB's queue and the current repository boundary.

## Persistence Boundaries

Read-heavy dictionary reference content belongs in versioned, read-only SQLite
assets. Saved entries, history, preferences, notes, and future import registry
state belong in SwiftData.

User data must reference dictionary entries through stable, source-aware
identity rather than transient SQLite row IDs. Dictionary records and SwiftData
models do not import or join each other's storage technologies; UseCases
coordinate Domain values.

The durable data direction is defined in
[Dictionary Strategy](../dictionary/strategy.md).

## GRDB Query Policy

- Use GRDB Query Interface for ordinary typed relationships and filtering.
- Use typed `SQLRequest` or `SQL` fragments when a projection or ranking query
  is clearer as SQL.
- Interpolate values through GRDB; never construct SQL from user strings.
- Benchmark the complete production query when SQL, indexes, projection,
  ranking, or result limits change.

## Feature Placement

| Concern | Location |
| --- | --- |
| UI rendering | `Features/<Feature>/<Feature>View.swift` |
| UI state and actions | `Features/<Feature>/<Feature>Store.swift` |
| Dependency assembly | `Features/<Feature>/<Feature>Scene.swift` |
| Business operation | `Domain/UseCase/` |
| Technology-neutral model | `Domain/Entity/` |
| Data-access contract | `Domain/Repository/` |
| Concrete persistence | `Data/` |
| App launch and composition | `App/` |

Not every static screen needs a Store. Add a Scene or Store when a feature has
dependencies, asynchronous state, business actions, or meaningful testable
behavior.

## Test Ownership

- Builder tests own source decoding, transformation, export invariants, and
  deterministic fixtures.
- Database verification owns schema, indexes, integrity, production query
  plans, and asset budgets.
- Repository tests own concrete record mapping and persistence behavior.
- UseCase tests own framework-independent business coordination.
- Store tests own UI state machines, cancellation, and stale-result handling.
- UI tests should cover only critical integrated user journeys.

Detailed verification requirements are selected through
[Engineering Workflow](../development/engineering_workflow.md).

## Known Risks

- Saved user state still references transient autoincrement word IDs.
- Launch composition still uses fatal failure instead of recoverable readiness.
- Runtime dictionary copying has no versioned replacement or rollback contract.
- Current dictionary entities are too flat for source-faithful detail.
- Store and critical-flow UI behavior lack direct automated coverage.

These are current implementation facts. Their order and resolution belong in
[Current Work](../development/current_work.md) and phase records.
