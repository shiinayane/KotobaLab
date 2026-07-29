# Phase 3: Architecture and CI

Status: Completed
Last updated: 2026-07-21

## Goal

Make the MVP architecture safe for asynchronous data access and automatically
verifiable before product/data expansion begins.

## Scope

- Move dictionary repository operations off main-actor execution.
- Make UI actor isolation explicit.
- Keep Domain framework-neutral under Swift 6 concurrency.
- Align GRDB records and SQL with the app-facing model.
- Verify the production search query shape.
- Add iOS lint/test CI.
- Strengthen repository persistence tests.

## Non-goals

- Rich dictionary senses, forms, and tags.
- Search ranking, normalization, FTS, or deinflection.
- Home/Settings product completion.
- Multi-dictionary support.
- Backend or AI features.

## Completed Work

### Async Dictionary Boundary

`DictionaryRepositoryProtocol` now exposes `async throws` operations for search,
detail, and batch-summary resolution. `SQLiteDictionaryRepository` executes
them through GRDB `DatabaseQueue.read`; `await` propagates through use cases and
Stores.

The app no longer relies on synchronous dictionary I/O from a main-actor Store.

### Explicit Actor Isolation

- Project default actor isolation is `nonisolated`.
- `SearchStore`, `SavedStore`, and `WordDetailStore` are explicitly
  `@MainActor @Observable`.
- Domain value types remain framework-neutral and dictionary entities are
  `Sendable` where they cross the repository boundary.

### Search Cancellation Safety

`SearchStore` retains cancel-first debounce plus a generation counter. Every
query change, including clearing the query, invalidates older in-flight work so
late results cannot replace `.idle` or a newer result.

### GRDB Record and Query Cleanup

- `WordRecord` and `MeaningRecord` live in `Data/Database/Record`.
- Detail loading uses the GRDB `hasMany` association and ordered meanings.
- Summary queries use a shared typed `SQL` projection because selecting the
  first ordered meaning remains clearer as a correlated SQL subquery than as a
  forced all-DSL expression.
- Batch summary loading preserves requested ID order and repeated IDs while
  avoiding duplicate database lookup values.

### Production Query Verification

`verify_database.py` and `benchmark_search.py` match the app's actual
two-column prefix search:

```sql
WHERE w.term LIKE ? OR w.reading LIKE ?
```

The verifier requires both `idx_words_term` and `idx_words_reading` and rejects
a scan. On the 2026-07-21 local artifact, representative searches remain roughly
0.014–0.072 ms and use `MULTI-INDEX OR`.

An attempted outer sort was rejected after benchmark evidence showed a broad
prefix regression to roughly 214 ms. Ranking remains a Phase 5 product task,
not an accidental SQL cleanup.

### CI and Tests

- `.github/workflows/ios-tests.yml` runs Apple `swift format lint` and the iOS
  Swift Testing suite with `xcodebuild`.
- CI downloads the release `dictionary.sqlite` required by app startup.
- `.github/workflows/builder-tests.yml` continues to run the Python suite.
- `SwiftDataUserDataRepositoryTests` cover save, duplicate-save prevention,
  unsave behavior, and reverse-chronological ordering.

## Key Decisions

- Chose async repository APIs rather than a custom database actor. GRDB's queue
  owns database serialization; Domain/UseCase APIs express suspension without
  importing GRDB.
- Chose explicit Store `@MainActor` annotations rather than project-wide default
  MainActor isolation.
- Kept a hybrid GRDB Query Interface + typed SQL approach where it preserves the
  real query shape and benchmark behavior.
- Kept search generation guards after async migration because suspension points
  make stale completion a real correctness risk.

## Verification

- `xcodebuild -list` parses the project and resolves GRDB 7.10.0.
- iOS and builder workflows exist and target their corresponding source paths.
- `verify_database.py` passes against the 51.88 MB artifact.
- Search benchmark records use both term and reading indexes.
- `Domain/` has no SwiftUI, SwiftData, GRDB, or SQLite imports.

## Carryover

- Store state transitions and critical UI flows still need direct automated
  coverage before release.
- Repository fixtures need richer cases for ranking, forms, detail metadata,
  duplicate/missing batch IDs, and stable identity.
- CI's latest-release artifact dependency needs a pinned/manifested update
  contract before v1.
- Product/data limitations are now tracked by the
  [v1 Gap Analysis](../product/v1_gap_analysis.md), not by extending this phase.

## Next Phase

The originally planned dictionary source-contract work was later superseded by
[Phase 4: System-wide Lookup and Dictionary Fidelity Spikes](phase-04-system-wide-lookup-spikes.md).
