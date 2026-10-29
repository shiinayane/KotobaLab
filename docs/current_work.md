# Current Work

Last updated: 2026-10-29

## Status

No phase is active. Phases 0–4 are complete and archived in
[`archive/`](archive/). No spike code is in production.

The 2026-10-29 native-rendering spike passed, and native rendering is the
default; see [Rendering](dictionary.md#rendering). Its code is reference
material on the local, unpushed branch `spike/native-rendering` in
`.claude/worktrees/spike-native-rendering`, and must not be merged.

## Current Objective

Select and propose one small production slice for explicit approval.
Documentation now has one owner per fact: `AGENTS.md`, [product](product.md),
[architecture](architecture.md), [dictionary](dictionary.md), and this file.

## Next Action

All candidates from the 2026-10-05 repository review are done. Choose the next
slice from the open decisions below and propose it for approval.

## Open Decisions

- Which system entry path becomes the first production slice, and whether
  screenshot OCR is in it.
- Whether user-facing Yomitan import belongs in v1, which
  [product](product.md) currently lists as a non-goal.
- Which rendering gaps to close first: vertical writing, grid placement, row
  spans, SVG, or ruby inside labels.
- What import precomputes, such as compiled styles, rasterized SVG, or render
  data stored in SQLite.
- Which providers justify a semantic adapter beyond generic rendering.
- Production import, identity, activation, recovery, and saved-reference
  contracts.
