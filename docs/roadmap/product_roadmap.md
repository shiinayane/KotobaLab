# Product Roadmap

Status: Active
Last updated: 2026-07-28

## Purpose

This roadmap records durable product direction. It intentionally does not
record current status, task order, phase numbers, implementation choices, or
delivery dates.

For current status and the next reviewable action, read
[Current Work](../development/current_work.md). For execution plans and
historical completion evidence, read [Phase Records](../phases/README.md).

## North Star

KotobaLab should become a dependable, local-first Japanese dictionary before it
becomes a broad study platform or an AI product.

## Direction 1: Trustworthy Dictionary Foundation

Dictionary data should remain faithful, source-aware, reproducible, and legally
usable.

- Preserve the supported structure of source entries.
- Separate stable source identity from runtime database row identity.
- Version and validate dictionary assets.
- Keep attribution and license boundaries visible.
- Measure correctness, size, and lookup performance together.

## Direction 2: Complete Daily Dictionary Experience

The core lookup loop should feel complete and reliable in ordinary use.

- Make search predictable and useful.
- Present structured detail without hiding source meaning.
- Preserve saved entries across supported content updates.
- Remove placeholders and dead ends from visible product surfaces.
- Support accessibility, recovery, and release-quality operation.

## Direction 3: Extensible Dictionary Ecosystem

KotobaLab should be able to use more than one dictionary source without
pretending that all sources share one ontology or license.

- Treat each source as an independently identified dictionary.
- Keep source attribution and provider boundaries intact.
- Allow independently versioned, validated runtime assets.
- Do not block a future user-import path, including Yomitan-compatible sources.
- Evaluate each bundled source on legal permission, quality, maintenance cost,
  size, and product value.

## Direction 4: Personal Data Continuity

User-owned state should outlive replaceable dictionary assets and remain
portable.

- Keep personal state separate from dictionary content.
- Use stable, source-aware references for saved words and history.
- Make backup, export, import, and private same-account sync possible without
  turning synchronization into dictionary distribution.
- Never silently retarget a personal reference to a different provider.

## Later Opportunities

After the dictionary product is dependable, useful extensions may include:

- recent activity, notes, tags, and lightweight study workflows
- spaced repetition
- additional definition languages and monolingual sources
- optional private cloud synchronization
- carefully bounded AI assistance that never replaces dictionary sources

These are opportunities, not commitments or phase assignments.

## Long-Term Guardrails

- Offline lookup remains a first-class capability.
- Dictionary and user-owned data remain separate.
- Provider identity and attribution are never erased for convenience.
- Commercial or unclear-license dictionary data is not redistributed.
- Product breadth does not come before correctness and daily usability.
- A roadmap direction may be revisited when evidence changes; implementation
  plans must not be treated as permanent doctrine.
