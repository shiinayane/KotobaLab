# Phase 2: Core App Experience

Status: Completed
Last updated: 2026-06-28

## Goal

Make the app feel like a real dictionary MVP instead of a demo: the core loop
`Search → Word Detail → Save → Saved List → reopen Word Detail` should be
understandable without explanation, feel responsive, and keep saved state
consistent. No backend, no AI, no broad redesign.

## Scope

- Search: explicit state model + empty / loading / error UX.
- Word Detail: information hierarchy.
- Saved: list refresh consistency after save/unsave.
- Previews: make them build from a clean checkout.
- Unfinished surfaces: remove or hide placeholder tabs/pages.
- Acknowledgements: in-app CC BY-SA 4.0 attribution surface.

## Non-goals

Deferred to **Phase 3 (Architecture and Tests)**:

- Making repository APIs `async` or introducing a database actor.
- Marking `WordDetailStore` / `SavedStore` as `@MainActor` (only `SearchStore` is today).
- iOS `xcodebuild` CI on GitHub Actions.
- Aligning `verify_database.py`'s search-plan check with the two-column `LIKE` SQL.
- FTS / search ranking.

Deferred as a separate **product decision** (Phase 3 or later):

- Expanding `meanings` from the current 1:1 collapse to true one-to-many
  ([Decision D-2](#d-2-multi-meaning-data-shape)).

Out of scope for the whole product right now: backend, AI, cloud sync, full
study system.

## Completed Work

### Task 1 — Explicit Search state + empty/loading/error UX ✅

`SearchStore` was rewritten from a flat `query` + `results` bag to an explicit
state machine, matching the shape `WordDetailStore` and `SavedStore` already use:

```swift
enum SearchViewState {
    case idle
    case loading
    case empty(query: String)
    case loaded([WordSummary])
    case error(String)
}
```

- Errors are no longer swallowed (`catch { results = [] }` is gone); `idle`,
  `empty`, and `error` render as distinct states via `ContentUnavailableView`,
  matching `SavedView`.
- The 300 ms debounce was hardened: cancel-first, whitespace-trimmed empty
  check, and the searched query is passed into the search call (no time-of-use
  read of mutable `query`). A generation guard is retained — currently redundant
  under synchronous main-actor execution, kept as forward-compat for the Phase 3
  async repository.
- Commits: `c98be28`, `1e63d9e`, `9fc06a1`.

Concurrency caveat carried to Phase 3: the repository call is synchronous on the
`@MainActor` store, so `.loading` rarely renders. Modelled now so the async
migration is a drop-in.

### Task 2 — Word Detail information hierarchy ✅ (resolved by design)

Resolved as a design decision rather than a code change:

- **term + reading are always shown, even when identical**, for visual
  consistency across word cards. The earlier "duplicate display" was
  reclassified as intentional, not a bug. Grounding in real data: `reading` is
  never null/empty in the shipped database, and `term == reading` in ~24% of
  entries (kana-only words) — so the only real duplicate case is the intended
  one.
- `displayName` was renamed to `displayReading` (`3e21fe4`) to reflect its real
  role (the kana subtitle, which also doubles as the Saved search key).
- No layout change required. Multi-meaning layout is gated on D-2.

### Task 3 — Saved list refresh consistency ✅ (resolved by design)

Verified empirically rather than changed: in `NavigationStack`, popping back to
the Saved list **does** re-fire `.onAppear`, so `store.load()` re-queries
SwiftData and a word unsaved in the detail disappears immediately on return. The
earlier "stale list" concern was based on old `NavigationView` behavior and does
not occur here. Correctness holds with no code change.

Residual non-correctness nit (intentionally not addressed): every return runs a
full `.loading` reload, causing a brief spinner flicker.

### Task 4 — Previews build from a clean checkout ✅

`WordMocks.swift` and `SavedMocks.swift` are now tracked, so `PreviewData`'s
references (`WordSummary.list`, `WordDetail.list`, `SavedWordRecordData.list`)
resolve on a fresh clone.

### Task 5 — Hide unfinished surfaces ✅ (with carryover)

- **D-1 resolved**: keep **Home / Saved / Search**; hide **Analysis** and
  **Study** (commented out in `RootView`, `c43da55`, labelled "temporarily"
  pending real implementation).
- The five-tab bar is reduced to three reachable tabs.

Carryover (see Known Risks) — surfaces that still read as unfinished but were
judged non-blocking for the MVP shell:

- `HomeView` remains the landing tab with empty "Recent Search" / "Recent Saved"
  stubs.
- Settings → Profile is a dead-end `NavigationLink { EmptyView() }`.
- `Features/TestView/` is gitignored but still on disk; Xcode target membership
  is unverified.

### Task 6 — In-app acknowledgements (CC BY-SA 4.0) ✅

`Settings → License` (`LicenseView`) is a self-contained attribution surface
(`69849d0`):

- JMdict / EDRDG acknowledgment using the Group's-licence wording, a Jitendex
  source link, a CC BY-SA 4.0 license link, an explicit modification statement,
  and a share-alike notice — no longer deferring attribution to `README.md`.
- App source-code MIT license on a pushed sub-page (`MITLicenseView`).
- Sheet dismissal is consistent across sub-pages via `AppRouter.dismissSheet()`.

Minor carryover: `MITLicenseView`'s body still contains a now-redundant
"See README.md for attribution details" line.

## Key Decisions

- **D-1 (which surfaces ship)**: keep Home / Saved / Search, hide Analysis /
  Study. Home is kept as the landing tab despite placeholder content (recorded
  as carryover, not treated as a blocker).
- **Task 2 and Task 3 were resolved as "by design / already-correct"** after
  grounding the assumptions in real data (term/reading distribution) and actual
  SwiftUI lifecycle behavior, not by editing code.
- **Search generation guard kept** for Phase 3 async forward-compat though
  redundant today.
- **D-2 (multi-meaning data shape)**: deferred past Phase 2 — a data/pipeline
  change, not experience polish (see below).

### D-2: Multi-meaning data shape

`transform.to_meaning_records` collapses all glosses into a single `meanings`
row, so the schema's one-to-many capability is unused. Expanding it touches the
builder, the DB artifact, the benchmark records, and Word Detail layout.
Deferred past Phase 2; revisit when Word Detail genuinely needs multiple senses.

## Verification

Confirmed by code / git inspection:

- `SearchViewState` present and `SearchView` switches on it; no
  `catch { results = [] }` remains.
- `WordMocks.swift` / `SavedMocks.swift` tracked (`git ls-files`).
- `RootView` exposes only Home / Saved / Search; Analysis / Study commented out.
- `Settings → License` reachable and self-contained.

Final gate to run before tagging the phase (recommended, not yet executed here):

- `xcodebuild test` (canonical command in `CLAUDE.md`).
- Core-loop walkthrough on device/simulator: empty search, zero-hit search,
  forced error, open detail, save, return, reopen, unsave from a Saved-tab
  detail, return.
- Open `Settings → License` (and the MIT sub-page) and confirm the `X` dismisses
  the sheet — i.e., the `AppRouter` environment propagates into the sheet.

Completion criteria (roadmap):

- ✅ Core flow understandable without explanation.
- ✅ Search feels responsive (debounced). Main-thread query cost is a Phase 3 item.
- ✅ Saved state stays consistent.
- ⚠️ "Main pages no longer feel like placeholders" — **partially met**: the
  Home landing tab still shows empty stubs (carryover).

## Known Risks / Carryover

- **Home landing tab is still placeholder stubs** — the largest remaining
  "feels like a demo" surface. Recommend hiding Home (land on Search) or giving
  it minimal real content in a short follow-up.
- **Settings → Profile dead-ends** to `EmptyView()`.
- **TestView** is gitignored but on disk — confirm it is out of the app build
  target, otherwise a fresh clone can hit dangling `project.pbxproj` references.
- **`MITLicenseView` still references `README.md`** (redundant now that
  `LicenseView` is self-contained).
- **`.loading` is cosmetic until Phase 3** (synchronous repository on the main
  actor).
- **Saved reload flicker** on every return to the list.
- **Commented-out Analysis / Study tabs** are dead code pending real
  implementation.

## Next Phase

`Phase 3: Architecture and Tests` (see
[`docs/roadmap/product_roadmap.md`](../roadmap/product_roadmap.md)): async
repository decision, `@MainActor` on all stores, iOS `xcodebuild` CI, and the
`verify_database.py` search-plan alignment.
