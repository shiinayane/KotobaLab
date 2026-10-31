# Current Work

Last updated: 2026-10-30

## Status

No phase is active. Phases 0–4 are complete and archived in
[`archive/`](archive/). No spike code is in production.

The 2026-10-29 native-rendering spike passed, and native rendering is the
default; see [Rendering](dictionary.md#rendering). Its code is reference
material on the local, unpushed branch `spike/native-rendering` in
`.claude/worktrees/spike-native-rendering`, and must not be merged.

## Current Objective

Deliver v1 along the [roadmap](product.md#roadmap), one approved milestone at a
time.

## Next Action

M0 Cleanup is implemented and in review. After it merges, propose M1 Data
foundation, starting with the structural changes in
[architecture](architecture.md#planned-changes).

## Open Decisions

- Which rendering gaps to close first: vertical writing, grid placement, row
  spans, SVG, or ruby inside labels.
- What import precomputes, such as compiled styles, rasterized SVG, or render
  data stored in SQLite.
- Which providers justify a semantic adapter beyond generic rendering.
- Production import, identity, activation, recovery, and saved-reference
  contracts.
- How to store structured content compactly; see
  [the compression measurements](dictionary.md#structured-content-compression-2026-10-30).
  zlib with a preset dictionary needs no new dependency; zstd would add one.
- How import guards storage once the Python verifier's fixed 100 MB limit is
  retired: for example a size estimate and free-space check instead of a fixed
  cap.
- Whether KotobaLab mirrors recommended dictionaries in its own GitHub Release
  as a fallback when an upstream download fails or changes format. Jitendex's
  CC BY-SA 4.0 license allows it with attribution.
