# Current Work

Status: Phase 4 spike findings ready for review

## Current Objective

Publish the durable conclusions from the completed Phase 4 feasibility spikes
without promoting disposable spike code or beginning production implementation.

Active phase record:
[Phase 4: System-wide Lookup and Dictionary Fidelity Spikes](../phases/phase-04-system-wide-lookup-spikes.md).

## Decisions in Force

- Formal documentation is the project memory and is written in English.
- This file is the only owner of the current objective and next action.
- Completed Phase 0–3 records remain frozen historical evidence.
- Phase 4 proved selected product and technical paths feasible; it did not
  approve a production architecture or implementation.
- Explicit system-wide lookup is part of the intended everyday product loop.
- Selected text, clipboard text, and screenshot OCR are candidate entry
  mechanisms, not committed production surfaces.
- Yomitan is the first external dictionary format to support.
- Generic ordered structural rendering is the fallback for arbitrary supported
  Yomitan content.
- Provider-specific semantic projection is optional and justified only where it
  adds known product value.
- SQLite remains a rebuildable runtime representation, not an exchange format.
- Dictionary content and user-owned state remain separate.
- No Phase 4 spike branch or implementation artifact is approved for merge into
  production.

## Next Action

Review the pushed documentation-only branch and decide whether these findings
should be merged. Production implementation remains deferred until a separate
proposal identifies one small, reviewable slice and receives explicit
approval.

## Expected Scope

This work may modify only formal documentation under `docs/`.

It does not modify production source code, tests, fixtures, database assets, CI
workflows, Xcode project settings, or GitHub settings. It does not promote,
merge, or publish the disposable spike implementations.

## Acceptance

- Product, roadmap, dictionary, and phase documents record the durable Phase 4
  conclusions without claiming production readiness.
- The completed phase record separates verified evidence from deferred work.
- No commercial dictionary content or local source data is committed.
- Completed Phase 0–3 records remain historically accurate.
- Internal Markdown links resolve.
- Relevant Markdown checks and `git diff --check` pass.
- The branch is committed and pushed without creating a pull request.

## Open Decisions

- Which system entry mechanism should become the first production slice.
- Whether screenshot OCR belongs in the first production scope.
- Which providers justify a semantic adapter beyond generic structural
  rendering.
- The production import, identity, activation, recovery, and saved-reference
  contracts.
- Whether user-facing Yomitan import belongs in v1.

## Verification Baseline

Before this documentation change, the repository had completed Phase 0–3,
established iOS and Dictionary Builder CI, and built a Jitendex-derived
Yomitan source into SQLite.

Phase 4 used isolated, disposable worktrees to test system entry, runtime
import, background import, and structured-definition fidelity. The evidence is
preserved in the completed phase record. None of those artifacts is part of the
production baseline.

Implementation work must re-check the actual repository rather than treating
the spike results as runtime proof.

## Non-goals

- Changing the dictionary schema
- Implementing a production Yomitan importer
- Implementing system-wide lookup
- Implementing multi-dictionary runtime behavior
- Migrating saved references
- Adding CloudKit or public dictionary distribution
- Modifying product UI
- Creating a pull request or merging this documentation branch
