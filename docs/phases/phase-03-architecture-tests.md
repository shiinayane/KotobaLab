# Phase 3: Architecture and Tests

Status: Planned
Last updated: 2026-06-28

## Goal

Make the current lightweight architecture durable: new feature code has an
obvious home, core domain behavior is tested, and data-layer changes can be
validated without manually running the app.

## Scope

- Decide repository concurrency: `async` APIs vs a dedicated database actor.
- Mark `WordDetailStore` and `SavedStore` as `@MainActor` (only `SearchStore` is today).
- Add iOS `xcodebuild` CI to GitHub Actions.
- Align `verify_database.py`'s search-plan check with the app's two-column `LIKE` SQL.
- Preserve `Domain` framework purity (currently clean).
- Keep local experiments out of the app target (currently satisfied).

## Non-goals

- Backend, AI, cloud sync — later phases.
- FTS / search ranking.
- Multi-meaning data shape (`meanings` 1:1 → one-to-many) — a product/data
  decision tracked as D-2 in the Phase 2 record, not architecture work.
- Broad UI work. The Phase 2 UI carryover (Home landing placeholder, Settings →
  Profile dead-end, `MITLicenseView` README line) is folded in opportunistically,
  not a Phase 3 objective.

## Current State (verified 2026-06-28)

Several roadmap-listed Phase 3 items are already satisfied. Grounding before
planning:

| Concern | Actual state |
|---|---|
| Store actor isolation | `SearchStore` is `@MainActor @Observable`; `WordDetailStore` and `SavedStore` are `@Observable` **without** `@MainActor`. |
| Repository APIs | `DictionaryRepositoryProtocol` and `UserDataRepositoryProtocol` are both **synchronous `throws`**, called from main-actor stores. |
| Production search SQL | `WHERE w.term LIKE ? OR w.reading LIKE ?` — two-column OR ([SQLiteDictionaryRepository.swift:49](../../KotobaLab/Data/Repository/Dictionary/SQLiteDictionaryRepository.swift#L49)). |
| `verify_database.py` check | `check_search_query_uses_index` asserts on `WHERE term LIKE ?` — **single column**, a different query than production ([verify_database.py:111-131](../../Tools/DictionaryBuilder/debug/verify_database.py#L111)). |
| iOS CI | None. Only `builder-tests.yml` (Python pytest) runs in Actions. |
| `Domain` purity | **Clean** — every file under `Domain/` imports only `Foundation`. |
| Local experiments | `Features/TestView/` is gitignored **and** excluded from the app target via `membershipExceptions` in `project.pbxproj`. Already out of the build. |
| GRDB pin | `upToNextMajorVersion`, `minimumVersion 7.0.0` (unchanged). |

## Work Plan

### Task 1 — Repository concurrency decision (the core of this phase)

Both repositories are synchronous `throws` and are called from main-actor
stores. SQLite queries therefore run on the main thread and block the UI — the
reason Phase 2's `SearchStore.loading` state rarely renders.

Options:

- **A — `async` repository protocols**: methods become `async throws`; queries
  run off the main actor. Ripples through UseCase → Store → View (`await`
  propagation).
- **B — Database actor**: a dedicated actor owns the GRDB connection; stores
  `await` into it. Localizes concurrency at the data layer; smaller blast radius
  on UseCases.
- **C — Keep synchronous** for the MVP and accept main-thread blocking.

This is **coupled with Task 2**: marking the remaining stores `@MainActor`
without resolving this just pins the blocking I/O to the main thread. Decide
Task 1 first (recorded as Decision D-3).

**Acceptance:** a written decision; if A or B is chosen, search/detail/saved no
longer block the main thread, and the Phase 2 `.loading` state becomes
meaningful.

### Task 2 — `@MainActor` on `WordDetailStore` and `SavedStore`

Only `SearchStore` is isolated today. Swift 6 strict concurrency will flag the
other two. Mechanically small, but must compose with Task 1 (do not pin blocking
I/O to the main actor).

**Acceptance:** all three stores `@MainActor`; builds clean under strict
concurrency.

### Task 3 — iOS `xcodebuild` CI

Add a GitHub Actions workflow running the canonical `xcodebuild test` command
(see `CLAUDE.md`) on a macOS runner, alongside the existing Python job.

Open question: the production `dictionary.sqlite` is not in the repo (delivered
as a GitHub Release artifact, decided in Phase 1). The workflow must either
download that artifact or run against the in-repo test fixture
(`KotobaLabTests/Fixtures/test_dictionary.sqlite`) only. Full-artifact CI was
explicitly deferred from Phase 1 to here.

**Acceptance:** PRs and pushes run the iOS test suite in CI.

### Task 4 — `verify_database.py` two-column search-plan alignment

`check_search_query_uses_index` checks `WHERE term LIKE ?` while the app runs
`WHERE term LIKE ? OR reading LIKE ?`. Update the checked SQL to the two-column
OR and assert the plan uses both `idx_words_term` and `idx_words_reading`
(MULTI-INDEX OR) rather than `SCAN words`.

If the documented plan description changes, refresh the query-plan tables in
`docs/dictionary/`.

**Acceptance:** the verification exercises the real production query shape.

### Task 5 — Preserve `Domain` purity (guard; already clean)

`Domain/` is currently framework-free. Keep it that way; optionally add a
lightweight check (script or review rule). No remediation needed today.

**Acceptance:** no `SwiftUI` / `SwiftData` / `GRDB` / `SQLite3` import under `Domain/`.

### Task 6 — Keep experiments out of the app target (already satisfied)

`TestView` is gitignored and excluded via `membershipExceptions`. Optionally
delete the scratch files and drop the now-stale exception entries from
`project.pbxproj` for tidiness.

**Acceptance:** scratch experiments remain unreachable from and uncompiled into
the shipped app.

## Inherited from Phase 1 (completed prerequisites)

- Repository tests against a fixture SQLite database.
- DictionaryBuilder pytest suite + Python CI.
- GRDB pinned to `7.0.0+`.

## Open Decisions

- **D-3: Repository concurrency** — `async` protocols (A) vs database actor (B)
  vs keep-synchronous (C). Drives Tasks 1 and 2. Recommendation pending; lean
  toward B (database actor) to contain the change at the data layer, but confirm
  against how much `await` propagation A would actually cost.
- **CI data source** — download the Release `dictionary.sqlite` vs fixture-only.

## Verification (completion criteria)

- New feature code has an obvious home (placement rules hold).
- Core domain behavior is tested — extend the existing UseCase tests as the
  concurrency model changes.
- Data-layer changes can be validated without manually running the app
  (iOS CI + `verify_database.py`).

## Known Risks

- **Async refactor ripple (Option A)**: `await` propagates through UseCase →
  Store → View; larger diff than it first appears.
- **`@MainActor` before concurrency decision**: doing Task 2 before Task 1 pins
  blocking I/O to the main thread. Sequence Task 1 first.
- **CI artifact dependency**: artifact-download CI couples the build to the
  GitHub Release being present; fixture-only CI tests less of the real database.

## Next Phase

`Phase 4: Minimal Backend` — only for work that does not belong on device
(dictionary asset manifest, download metadata, an eventual AI proxy). See
[`docs/roadmap/product_roadmap.md`](../roadmap/product_roadmap.md).
