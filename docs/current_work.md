# Current Work

Last updated: 2026-11-01

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

M1 Data foundation is approved as five pull requests, each reviewed on its own:

1. The `KotobaKit` package, a minimal Yomitan importer, and import
   measurements. In review.
2. The frozen pack format, identity rules, and read API.
3. The import service, App Group, dictionary registry, and saved-entry model.
4. The app switch to downloaded packs, starting with Jitendex on first launch.
5. Retiring the Python builder, the released SQLite asset, and its CI download.

## Open Decisions

- Which rendering gaps to close first: vertical writing, grid placement, row
  spans, SVG, or ruby inside labels.
- What import precomputes, such as compiled styles, rasterized SVG, or render
  data stored in SQLite.
- Which providers justify a semantic adapter beyond generic rendering.
- Import activation and recovery contracts. Identity is decided; see
  [Identity](dictionary.md#identity).
- How import guards storage once the Python verifier's fixed 100 MB limit is
  retired: for example a size estimate and free-space check instead of a fixed
  cap.
- Whether KotobaLab mirrors recommended dictionaries in its own GitHub Release
  as a fallback when an upstream download fails or changes format. Jitendex's
  CC BY-SA 4.0 license allows it with attribution.
