# Phase Records

Status: Active
Last updated: 2026-07-28

Phase records connect durable product direction to reviewable execution. They
are plans and evidence, not permanent doctrine.

## Status Meaning

- **Historical**: an initial snapshot retained for context.
- **Completed**: verified work preserved as history. Later expectations do not
  retroactively expand its scope.
- **Current**: the present working hypothesis. It may be revised, split,
  reordered, or replaced when evidence supports a better path.

Future phases are created only when they are close enough to plan responsibly.
The absence of a numbered future phase is intentional.

## Phase Index

| Phase | Status | Record |
| --- | --- | --- |
| 0 — MVP Baseline | Historical | [phase-00-current-mvp.md](phase-00-current-mvp.md) |
| 1 — Pipeline Stabilization | Completed | [phase-01-pipeline-stabilization.md](phase-01-pipeline-stabilization.md) |
| 2 — Core Experience | Completed | [phase-02-core-experience.md](phase-02-core-experience.md) |
| 3 — Architecture and CI | Completed | [phase-03-architecture-tests.md](phase-03-architecture-tests.md) |
| 4 — Dictionary Source Contract | Current | [phase-04-dictionary-source-contract.md](phase-04-dictionary-source-contract.md) |

Current status and the immediate next action are owned by
[Current Work](../development/current_work.md).

## Current Phase Contract

A current phase should define:

- the outcome and why it matters now
- reviewable slices, each with explicit acceptance criteria
- non-goals that prevent accidental scope expansion
- evidence and verification required before completion
- known risks, unresolved decisions, and carryover
- enough mutability to incorporate better evidence or implementation choices

## Completed Phase Contract

A completed record should preserve:

- work actually completed
- decisions and rejected alternatives that still matter
- tests, commands, measurements, or manual acceptance evidence
- explicit carryover rather than claims that unfinished work was complete

Only factual corrections and link maintenance should change a completed record.
Temporary investigation notes belong in `docs/_local/`.
