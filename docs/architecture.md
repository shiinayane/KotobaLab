# Architecture

The architecture that is true in the current code, plus the rules that keep it
that way.

## Layers

```text
App / Scene -> SwiftUI View -> @MainActor Store -> UseCase
-> Repository protocol -> Repository implementation -> GRDB SQLite / SwiftData
```

Dependencies point one way. This is lightweight MVVM with explicit UseCase and
Repository boundaries, not full Clean Architecture. A Store plays the ViewModel
role.

Hard rules:

- `Domain/` must not import SwiftUI, SwiftData, GRDB, or SQLite record types.
- Views must not hold repositories or database references.
- Business logic lives in UseCases, not Views.
- Dictionary content stays in SQLite; user-owned data stays in SwiftData.
  Neither storage layer imports or joins the other; UseCases coordinate them.
- Add an abstraction only when it removes real duplication, isolates a known
  change, or materially improves testability.

## Placement

| Concern | Location |
| --- | --- |
| Launch and dependency composition | `App/` |
| Technology-neutral models | `Domain/Entity/` |
| Data-access contracts | `Domain/Repository/` |
| Business operations | `Domain/UseCase/` |
| GRDB records, SQLite setup, SwiftData models, repositories | `Data/` |
| Feature UI | `Features/<Feature>/` |
| Sheet presentation (`AppRouter`) | `Navigation/` |
| Shared components | `Shared/` |

A feature with dependencies, asynchronous state, or testable behavior uses
`Scene + Store + View`: the Scene assembles UseCases, the Store owns state, and
the View renders. Static screens such as Settings and License may be a View
alone.

## Concurrency

- The app target uses `SWIFT_DEFAULT_ACTOR_ISOLATION = nonisolated` with
  approachable concurrency enabled.
- UI Stores are explicitly `@MainActor @Observable`. The project does not use
  default MainActor isolation.
- `DictionaryRepositoryProtocol` is `async throws`. `SQLiteDictionaryRepository`
  is `Sendable` and reads through GRDB `DatabaseQueue.read`. GRDB owns
  serialization, so there is no custom database actor; add one only for a
  measured need.
- `SwiftDataUserDataRepository` is `@MainActor` because it owns the main
  `ModelContext`.
- Values crossing the dictionary boundary are `Sendable`.
- `SearchStore` keeps cancel-first debounce plus a generation counter so a late
  result cannot replace a newer state.

## GRDB Query Policy

- Use the Query Interface for ordinary typed relationships and filters.
- Use typed `SQLRequest` or `SQL` when a projection or ranking is clearer as SQL,
  such as the first-meaning preview subquery.
- Interpolate values through GRDB; never build SQL from user strings.
- Benchmark the complete production query after any SQL, index, projection,
  ranking, or limit change. An outer sort was once rejected because it regressed
  broad prefix searches to about 214 ms.

## Tests

| Layer | Owns |
| --- | --- |
| Builder pytest | Source decoding, transformation, export invariants |
| Database verifier | Schema, indexes, integrity, production query plans, size |
| Repository tests | Record mapping and persistence, against the fixture database |
| UseCase tests | Framework-independent coordination, with mock repositories |
| Store tests | State machines, cancellation, stale results (only `WordDetailStore` so far) |
| UI tests | Only critical integrated journeys (none yet) |

CI runs `swift format lint` and the iOS tests on Xcode 26.4, and the builder
tests on Python 3.14.

## Known Gaps

- Saved words persist transient SQLite row IDs, not stable source identity.
- Saved-word loading silently stops at 50 records.
- Launch failure ends in `fatalError` instead of a recoverable state.
- The bundled database is copied to Application Support once and never
  replaced on app update.
- Domain entities are too flat for structured dictionary detail.
- Home and Settings → Profile are still placeholders.
- Only `WordDetailStore` has Store tests; other Stores and critical UI flows
  have none.
