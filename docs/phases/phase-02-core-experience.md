# Phase 2: Core App Experience

Status: In Progress
Last updated: 2026-05-31

## Goal

Make the app feel like a real dictionary MVP instead of a demo: the core loop
`Search → Word Detail → Save → Saved List → reopen Word Detail` should be
understandable without explanation, feel responsive, and keep saved state
consistent. No backend, no AI, no broad redesign.

## Scope

Work is limited to the iOS app's core-loop surfaces and the in-app attribution
required before any release:

- Search: explicit state model + empty / loading / error UX.
- Word Detail: information hierarchy.
- Saved: list refresh consistency after save/unsave.
- Previews: make them build from a clean checkout.
- Unfinished surfaces: remove or hide placeholder tabs/pages.
- Acknowledgements: in-app CC BY-SA 4.0 attribution surface.

## Non-goals

Deferred to **Phase 3 (Architecture and Tests)** — do not pull these in:

- Making repository APIs `async` or introducing a database actor.
- Marking `WordDetailStore` / `SavedStore` as `@MainActor` (only `SearchStore` is today).
- iOS `xcodebuild` CI on GitHub Actions.
- Aligning `verify_database.py`'s search-plan check with the two-column `LIKE` SQL.
- FTS / search ranking.

Deferred as a separate **product decision** (Phase 2 or later):

- Expanding `meanings` from the current 1:1 collapse to true one-to-many.
  See [Decision D-2](#d-2-multi-meaning-data-shape).

Out of scope for the whole product right now: backend, AI, cloud sync, full
study system.

## Current State (verified 2026-05-31)

Re-checking the code corrects two stale lines in the roadmap:

| Store | State today |
|---|---|
| `SearchStore` | **Flat** — `var query` + `var results: [WordSummary]`; errors swallowed to `results = []` ([SearchStore.swift:14](../../KotobaLab/Features/Search/SearchStore.swift#L14)). |
| `WordDetailStore` | Already enum-modelled — `WordDetailViewState { idle, loading, loaded, notFound, error }` ([WordDetailStore.swift:54](../../KotobaLab/Features/WordDetail/WordDetailStore.swift#L54)). |
| `SavedStore` | Already enum-modelled — `SavedViewState { idle, loading, loaded, error }` ([SavedStore.swift:53](../../KotobaLab/Features/Saved/SavedStore.swift#L53)). |

So "model search state explicitly with an enum" is now **only** about
`SearchStore`. WordDetail and Saved already have empty/loading/error handled
in their views; their Phase 2 work is hierarchy (WordDetail) and refresh (Saved).

## Work Plan

### Task 1 — Explicit Search state + empty/loading/error UX

The only store still holding a flat `query` + `results` bag. Today
`search()` swallows every error into an empty result list
([SearchStore.swift:24-30](../../KotobaLab/Features/Search/SearchStore.swift#L24)),
so "no query yet", "searched but zero hits", and "search failed" are all
indistinguishable empty lists in the UI.

Proposed state, mirroring the shape WordDetail/Saved already use:

```swift
enum SearchViewState {
    case idle                  // query is empty — show a hint, not an empty list
    case loading               // a search is in flight
    case empty(query: String)  // searched, zero results
    case loaded([WordSummary])
    case error(String)
}
```

`SearchStore` changes:

- Replace `var results` with `var state: SearchViewState = .idle`; keep `query`.
- `search()`: trim `query`; if empty → `.idle`; else `.loading` →
  run `searchWordsUseCase.execute` → `.loaded` / `.empty(query:)` / `.error`.
- Keep the existing 300 ms debounce ([SearchStore.swift:32](../../KotobaLab/Features/Search/SearchStore.swift#L32)).
  When the debounced task is cancelled, do not clobber `state`.

`SearchView` changes ([SearchView.swift:14](../../KotobaLab/Features/Search/SearchView.swift#L14)):
switch on `state`, using `ContentUnavailableView` for `idle` / `empty` / `error`
to match the visual language Saved already uses
([SavedView.swift:61-83](../../KotobaLab/Features/Saved/SavedView.swift#L61)).

Preview helper `SearchStore.previewWithResults()` updates with the new state
([PreviewHelpers.swift:9](../../KotobaLab/Data/Preview/PreviewHelpers.swift#L9)).

**Concurrency caveat (informs Phase 3, do not fix here):** the repository call
is synchronous on the `@MainActor` store, so the `.loading` case will rarely
render — the main thread blocks through the query. We still model `.loading`
now so the Phase 3 async-repository migration is a drop-in, but its visible
value depends on that later change. Note this in the PR description rather than
solving it in Phase 2.

**Acceptance:** typing, clearing, a zero-hit query, and a thrown repository
error each show a visibly distinct state. No `catch { results = [] }`.

### Task 2 — Word Detail information hierarchy

[WordDetailView.swift:53-82](../../KotobaLab/Features/WordDetail/WordDetailView.swift#L53).
Two concrete issues:

- `headerSection` shows `term` (largeTitle) then `displayName`, where
  `displayName = reading ?? term` ([DictionaryModels.swift:17](../../KotobaLab/Domain/Entity/DictionaryModels.swift#L17)).
  When a word has no reading this prints the term twice. Show reading only when
  it differs from term.
- `meaningSection` renders a flat list under one "Meaning" header. Because
  `meanings` is currently 1:1 (see [D-2](#d-2-multi-meaning-data-shape)), there
  is usually a single entry — numbering/grouping has little value until the data
  shape decision lands. Keep this task to clarifying the single-meaning layout
  (POS styling, spacing, label) and defer multi-meaning layout to whenever D-2
  resolves.

**Acceptance:** no duplicated term/reading line; POS and definition are visually
distinguishable; layout reads cleanly with one meaning and does not break with
several.

### Task 3 — Saved list refresh consistency

[SavedView.swift:14-22](../../KotobaLab/Features/Saved/SavedView.swift#L14) reloads
via `.onAppear { store.load() }`. The gap: in SwiftUI, `onAppear` fires when a
view is *pushed*, not when a `NavigationStack` *pops back* to it. So the
Saved-tab → Word Detail → unsave → back path returns to a list that still shows
the just-unsaved word until the tab is left and re-entered.

`ToggleSavedWordUseCase` writes through to SwiftData
([ToggleSavedWordUseCase.swift](../../KotobaLab/Domain/UseCase/ToggleSavedWordUseCase.swift)),
which is the source of truth; the `[WordSummary]` cached in `.loaded` is the
stale copy.

Two options (pick during implementation):

- **Option A (minimal):** reload when the list re-appears reliably — e.g. drive
  the reload from a value that changes on return, or reload on `NavigationStack`
  path changes. Smallest diff, stays inside the current synchronous design.
- **Option B (cleaner):** have the Word Detail save action signal the Saved
  store to invalidate, via a shared lightweight "saved changed" signal owned at
  the Scene/DI level.

Recommend **Option A** for Phase 2 to avoid widening scope; revisit B if A
proves flaky. Either way, avoid introducing a new layer ([CLAUDE.md placement
rules]).

**Acceptance:** unsaving (or saving) inside a detail opened from the Saved tab
is reflected in the list immediately on return, with no tab switch needed.

### Task 4 — Keep previews building from a clean checkout

`PreviewData.swift` (committed) references `WordSummary.list`, `WordDetail.list`,
and `SavedWordRecordData.list` ([PreviewData.swift](../../KotobaLab/Data/Preview/PreviewData.swift)),
but those extensions live in `WordMocks.swift` and `SavedMocks.swift`, which are
**currently untracked** (`git status` shows them under `KotobaLab/Data/Preview/`).
A fresh clone is missing the symbols `PreviewData` depends on.

- Commit `WordMocks.swift` and `SavedMocks.swift`, and confirm they are added to
  the correct Xcode target membership (preview/test, not shipped app code if
  avoidable).
- Verify every `#Preview` across the core-loop views still compiles after the
  Task 1 state change.

**Acceptance:** clean checkout → `xcodebuild` succeeds without locally-untracked
files; all core-loop previews render.

### Task 5 — Remove or hide unfinished surfaces

`RootView` ships five tabs
([RootView.swift:18-46](../../KotobaLab/Features/Root/RootView.swift#L18)), three of
which are placeholders:

- `HomeView` — empty "Recent Search" / "Recent Saved" section stubs.
- `AnalysisView` — literal `"Hello, World!"`.
- `StudyView` — `"Study page"`.
- Settings sheet — `"Setting page"` ([SettingsView.swift](../../KotobaLab/Features/Settings/SettingsView.swift)).
- `Features/TestView/` (`ContentView`, `ShopHomeDemoView`) appears to be scratch
  experimentation, not part of the core loop.

This is a **product decision** — see [D-1](#d-1-which-surfaces-ship-in-the-mvp).
Implementation waits on that decision; the mechanical change (removing tabs from
the `TabView`, deleting/quarantining `TestView`) is small once direction is set.

**Acceptance:** no tab or page opens onto a placeholder; `TestView` scratch code
is not reachable from the shipped app.

### Task 6 — In-app acknowledgements (CC BY-SA 4.0)

Carried over from Phase 1 as a Phase 2 precondition: JMdict / Jitendex is
CC BY-SA 4.0, which requires attribution in the distributed app, not only in
docs ([phase-01 Key Decisions](phase-01-pipeline-stabilization.md)). Add a
minimal acknowledgements surface — most naturally inside the existing Settings
sheet, which is currently a placeholder anyway (folds into Task 5).

**Acceptance:** a user-reachable screen states the dictionary source and its
CC BY-SA 4.0 license with required attribution text.

## Open Decisions

### D-1: Which surfaces ship in the MVP?

Recommendation (advisor view, **needs user sign-off**): keep the core loop only
— **Saved** and **Search** — for the MVP, hide **Analysis** and **Study**
(neither is in MVP scope), and either (a) implement a minimal real **Home**
(recent searches / recent saved, which the stubs already gesture at) or (b) hide
Home too and let Search be the entry tab. Remove `Features/TestView/` from the
app target regardless.

Alternatives: keep Home as the landing tab with real content; or keep all tabs
but gate the unfinished ones behind a clear "coming soon" state. Decision drives
Task 5.

### D-2: Multi-meaning data shape

`transform.to_meaning_records` collapses all glosses into a single `meanings`
row, so the schema's one-to-many capability is unused. Expanding it touches the
builder, the DB artifact, the benchmark records, and Word Detail layout
(Task 2). Recommendation: **defer past Phase 2** — it is a data/pipeline change
dressed as a UI task, and Phase 2 should stay on experience polish. Revisit when
Word Detail genuinely needs to show multiple distinct senses.

## Verification

- `xcodebuild test` (canonical command in `CLAUDE.md`) passes.
- Core-loop previews build from a clean checkout (Task 4).
- Manual core-loop walkthrough: empty search, zero-hit search, forced error,
  open detail, save, return, reopen, unsave from Saved-tab detail, return.
- No new untracked files required to build.
- No SQL / schema / index / PRAGMA changes in this phase → benchmark records in
  `docs/dictionary/` are untouched (if D-2 is ever pulled in, that changes).

## Known Risks

- **`.loading` is cosmetic until Phase 3.** Synchronous repository on the main
  actor means the spinner rarely shows. Modelled now for forward-compat, but its
  payoff is gated on the Phase 3 async decision.
- **Saved refresh (Option A) can be subtle.** SwiftUI lifecycle timing around
  `NavigationStack` pop is easy to get almost-right; verify the unsave-on-return
  path explicitly, not just the tab-switch path.
- **Target membership of preview mocks.** If `WordMocks`/`SavedMocks` land in the
  shipped app target, sample data ships in the binary. Prefer preview/test-only
  membership.
- **Scope creep into Phase 3.** Refresh and search-state work sit next to the
  `@MainActor` / async-repository questions; resist fixing those here.

## Next Phase

`Phase 3: Architecture and Tests` (see
[`docs/roadmap/product_roadmap.md`](../roadmap/product_roadmap.md)). Phase 2
deliberately leaves these for Phase 3: async repository decision, `@MainActor`
on all stores, iOS xcodebuild CI, and the `verify_database.py` search-plan
alignment.
