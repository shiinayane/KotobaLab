# Current Work

Last updated: 2026-10-29

## Status

No phase is active. Phases 0–4 are complete and archived in
[`archive/`](archive/). Phase 4 proved feasibility only; no spike code is in
production.

## Current Objective

Select and propose one small production slice for explicit approval.
Documentation now has one owner per fact: `AGENTS.md`, [product](product.md),
[architecture](architecture.md), [dictionary](dictionary.md), and this file.

## Next Action

Propose one of the remaining candidates from the 2026-10-05 repository review.
The search wildcard and save-toggle fixes are done.

- **Silent saved-state read failure.** When loading a detail, a failure to read
  the saved state is treated as "not saved" without telling the user.
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
