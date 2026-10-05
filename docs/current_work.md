# Current Work

Last updated: 2026-10-05

## Status

No phase is active. Phases 0–4 are complete and archived in
[`archive/`](archive/). Phase 4 proved feasibility only; no spike code is in
production.

## Current Objective

Consolidate the documentation into one owner per fact: `AGENTS.md`,
[product](product.md), [architecture](architecture.md),
[dictionary](dictionary.md), and this file. The restructure was drafted on
2026-10-05 as a documentation-only change for user review.

## Next Action

After the documentation change is reviewed, propose one small production slice
for explicit approval. Candidates found in the 2026-10-05 repository review:

- **Search wildcard escaping.** User input reaches `LIKE` unescaped, so `%` or
  `_` match arbitrary entries and a leading wildcard forces a full table scan.
- **swift-format configuration.** Local Xcode 27 rejects the committed
  `.swift-format`; the uncommitted replacement adds trailing-comma rules that
  flag five existing violations. Confirm CI's Xcode 26.4 accepts it first.
- **Save-toggle failure.** A failed toggle replaces the loaded detail with an
  error screen.
- **Unused code.** `AppRouter` path navigation, `AppRoute`, and the bundled
  `Resources/MockData` JSON are unused.

## Open Decisions

- Which system entry path becomes the first production slice, and whether
  screenshot OCR is in it.
- Whether user-facing Yomitan import belongs in v1, which
  [product](product.md) currently lists as a non-goal.
- How far native rendering of imported dictionaries should go. A local study
  suggests a CSS-subset projection covers most entries of heavily styled
  dictionaries, but it is unverified beyond one sample.
- Which providers justify a semantic adapter beyond generic rendering.
- Production import, identity, activation, recovery, and saved-reference
  contracts.
