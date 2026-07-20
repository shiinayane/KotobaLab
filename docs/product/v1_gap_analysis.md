# v1 Gap Analysis

Status: Active
Last updated: 2026-07-21

## Purpose

This audit compares the repository as implemented on 2026-07-21 with the
requirements of a dependable, basic dictionary app. It is the evidence used to
reorganize the roadmap after Phase 3.

## What Already Works

- Native SwiftUI app with Search, Word Detail, Saved, and Settings surfaces.
- Offline SQLite dictionary with 293,471 words and 293,471 meaning rows.
- Indexed term/reading prefix search with a verified `MULTI-INDEX OR` plan.
- Async dictionary repository using GRDB `DatabaseQueue.read`.
- SwiftData saved-word persistence.
- Explicit `idle/loading/empty/loaded/error` state where appropriate.
- Reproducible Python builder, database verifier, benchmark, fixture database,
  Swift Testing suites, and GitHub Actions workflows.
- In-app JMdict/Jitendex and source-code license pages.

These are foundation strengths and should be preserved rather than rewritten.

## Product and Data Gaps

| Area | Repository evidence | Why it blocks or weakens a formal app | Planned phase |
| --- | --- | --- | --- |
| Sense fidelity | `transform.to_meaning_records` joins every gloss with `"; "` and emits one row; the shipped database has exactly one meaning per word. | Distinct senses and their metadata cannot be represented or rendered correctly. | Phase 4 |
| Alternative forms | `parse.py` extracts `forms`, but `WordRecord`, the SQLite schema, and app models discard them. | Valid spellings cannot be searched or explained. | Phase 4 |
| Stable identity | `words.id` is an autoincrement build artifact; `SavedWordRecord` persists only that integer. | A rebuilt dictionary can make a saved ID refer to a different entry. | Phase 4 |
| Asset metadata | The database has only `words` and `meanings`; no schema, content version, source identifier, language, or license metadata is queryable. | The app cannot validate compatibility or explain exactly which data is installed. | Phase 4 |
| Asset upgrades | `DatabaseManager` copies the bundled database only when the destination does not exist. | App updates do not replace or migrate an already installed dictionary. | Phase 4 / 7 |
| Search semantics | Production search is `term LIKE prefix OR reading LIKE prefix`, fixed at 20 results, with no explicit ranking or `ORDER BY`. | Exact matches are not guaranteed first and equal queries are not a documented stable contract. | Phase 5 |
| Input coverage | Forms are unavailable and no normalization/deinflection policy exists. | Common lookup inputs can miss entries even when the source contains them. | Phase 5 |
| Detail usefulness | `WordDetailView` renders term, reading, POS, and flattened definition only. | It omits structured senses, restrictions/tags, source identity, copy, and share. | Phase 5 |
| Saved completeness | `fetchSavedWordIDs` silently applies `fetchLimit = 50`. | Older saved words become unreachable with no indication. | Phase 6 |
| Home | `HomeView` contains only “Recent Search” and “Recent Saved” labels. | The default tab visibly looks unfinished. | Phase 6 |
| Settings | Profile navigates to `EmptyView()`. | This is a user-visible dead end. | Phase 6 |
| Startup failure | Dependency construction ends in `fatalError`. | A missing, corrupt, or incompatible database terminates the app instead of offering recovery. | Phase 7 |
| App identity | The AppIcon set declares slots but contains no image assets. | The app is not distributable as a finished product. | Phase 6 / 7 |
| Accessibility/localization | User-facing strings are inline and there is no string catalog or UI/accessibility test target. | Release behavior is not verified for assistive technology or localization. | Phase 6 / 7 |
| Multi-dictionary model | Repository IDs, schema, attribution, and saved state all assume one database/source. | A second Japanese-English, Japanese-Chinese, or Japanese monolingual source cannot be added safely. | Phase 8 |

## Engineering Gaps

- Store behavior is not directly tested; async cancellation and error/retry
  transitions rely mostly on code review and manual walkthroughs.
- Repository fixture coverage does not yet specify ranking, alternative forms,
  duplicate requested IDs, missing IDs, or all detail metadata.
- There is no UI test target for the critical lookup/save loop.
- Builder tests verify the current flattening implementation, not source-content
  fidelity against representative real entries.
- The release process covers the dictionary artifact but not an app release
  checklist, upgrade matrix, privacy declaration, or beta acceptance run.

## Roadmap Conclusions

1. Phase 3 is complete enough to close: repository async propagation, explicit
   Store actor isolation, GRDB record/query cleanup, iOS CI, and production-plan
   verification are present.
2. Backend and AI are removed from the numbered near-term roadmap. They do not
   address the deficiencies above.
3. The next work must start at source fidelity and stable identity. UI polish on
   the current lossy model would make later migration more expensive.
4. A formal single-dictionary v1 should ship before multi-dictionary expansion.
   This creates a smaller release gate while still requiring the identity and
   metadata seams that later dictionary packs need.
5. Multi-dictionary support should use source-aware dictionary packs and
   composite identities. It should not attempt automatic semantic merging in
   its first version.

See the [Product Roadmap](../roadmap/product_roadmap.md) for the resulting phase
order and [Multi-Dictionary Strategy](../dictionary/multi_dictionary_strategy.md)
for the post-v1 data direction.
