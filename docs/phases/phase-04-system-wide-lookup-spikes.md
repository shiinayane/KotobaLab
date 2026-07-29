# Phase 4: System-wide Lookup and Dictionary Fidelity Spikes

Status: Completed
Last updated: 2026-07-30

## Outcome

Bounded, disposable spikes established that KotobaLab can:

- begin an explicit lookup from Japanese encountered outside the app
- import Yomitan term banks at runtime and continue a large import in the
  background
- display structurally different Yomitan dictionaries through one ordered
  generic renderer
- add provider-specific semantic projection without making it the universal
  data model

This phase proved feasibility and clarified product direction. It did not
select a production architecture, approve an implementation, or promote any
spike code into the application.

## Why These Spikes

The earlier source-contract plan assumed that production schema and identity
design were the next highest-risk questions. Product review instead identified
two earlier uncertainties:

1. whether a native iOS app could provide a useful system-wide lookup path
2. whether materially different Yomitan dictionaries could retain useful
   fidelity without a custom parser for every provider

Isolated worktrees answered those questions before production commitments were
made.

## System Entry Evidence

Tests used signed-device execution where extension and cross-application
behavior mattered.

| Path | Evidence | Conclusion |
| --- | --- | --- |
| Selected-text Share Sheet | A selected Japanese string reached the lookup spike on a signed iPhone. The observed navigation path was three levels deep. | Technically viable, but too indirect to be the primary hypothesis. Retain as a possible secondary path. |
| Explicit clipboard Shortcut | An explicitly invoked Shortcut passed clipboard text into lookup with a substantially shorter interaction path. | Retain as the primary selectable-text hypothesis. It remains an explicit action, not continuous clipboard observation. |
| Screenshot OCR | Screenshot input passed through Apple text recognition, candidate selection, and dictionary-backed lookup on a signed iPhone. The spike limited the candidate list to eight. | End-to-end feasibility passed. Candidate ranking and final interaction design remain production work. |
| Save from snippet | The spike contained a candidate path toward saved state. | Writing from the entry surface and observing the result in the main app's SwiftData store was not verified on a signed device. |

The product conclusion is broader than any one extension: KotobaLab should
support explicit system-wide lookup while keeping the specific production entry
surfaces open for later selection.

## Runtime Import and Background Evidence

A disposable runtime importer decoded and inserted Yomitan term banks without
requiring the existing build-time pipeline. A separate signed-device spike ran
a 60-second synthetic import through `BGContinuedProcessingTask`:

- all 120 synthetic banks completed
- progress remained visible through the system background presentation
- an actor-isolation crash in the launch handler was found and corrected
- the focused test suite passed 28 tests after the correction

This established background-execution feasibility, not production durability.
The input was generated rather than a redistributable production dictionary,
and the spike did not verify termination or reboot recovery.

## Dictionary Fidelity Evidence

### Source Observations

The Yomitan v3 format provided a common container but did not provide common
provider semantics.

- The local Jitendex snapshot contained 214 term banks and 427,064 rows with
  structured definitions. Its supported sample produced no malformed records
  or unknown definition node types during the focused scan.
- A local commercial-source snapshot contained 48,523 rows. It was inspected
  only for structure; no source content or fixture was committed.
- A synthetic fixture matching the second source's structural shape was used
  for repeatable tests without copying commercial dictionary content.

### Provider-specific Semantic Projection

The Jitendex-focused projection demonstrated that source conventions can
support useful semantic grouping. A real entry for `掛ける` retained:

- 2 part-of-speech groups
- 25 ordered senses
- 2 forms
- 15 cross-references

This is evidence for an optional provider adapter, not a shared ontology for all
Yomitan dictionaries.

### Generic Ordered Rendering

One generic structured-content renderer displayed both Jitendex-shaped content
and the synthetic second-source shape. The supported projection covered:

- text and inline formatting
- ruby
- ordered and unordered lists
- tables
- links
- disclosures
- a visible fallback for unknown valid nodes

Source order and visible content were preserved. Maintainer visual inspection
accepted the result after a ruby-baseline correction. After that correction:

- Swift formatting passed
- `git diff --check` passed
- 7 of 7 focused generic-renderer tests passed
- an unsigned iOS Simulator build passed

The broader generic-plus-Jitendex focused suite had passed 13 of 13 tests before
the isolated ruby-only correction; it was not rerun afterward.

## Decisions Preserved

- Explicit system-wide lookup is part of the intended everyday product loop.
- Candidate entry mechanisms remain product hypotheses until a production slice
  is separately proposed and approved.
- Generic ordered structural projection is the default fallback for supported
  Yomitan structured content.
- Provider-specific semantic adapters are optional and must justify their
  maintenance cost through known product value.
- Transport compatibility must not be presented as semantic equivalence.
- Unknown valid structures remain observable instead of being silently
  flattened or discarded.
- Spike implementations remain disposable. None is approved for merge into the
  production codebase.

## Deferred Production Work

This phase did not resolve:

- the production system-entry surface or lifecycle
- cross-process save behavior and SwiftData ownership
- OCR candidate ranking, correction, privacy messaging, or accessibility
- the production canonical model or SQLite schema
- stable dictionary identity and saved-reference migration
- import staging, activation, rollback, cleanup, retry, or recovery
- termination and reboot behavior for background import
- performance and storage behavior with production user-supplied dictionaries
- which providers, if any, receive semantic adapters
- general reliability, release readiness, or market demand

## Verification Boundary

Results are specific to the isolated spike artifacts, local source snapshots,
synthetic fixtures, and devices used during the investigation. Commercial
dictionary content remains local and uncommitted.

The passing tests, builds, and manual checks demonstrate the bounded behaviors
described above. They do not establish production readiness or replace
validation against the future production implementation.

## Handoff

Future implementation begins only after a separate proposal selects one small
production slice, explains its architecture and data impact, identifies
non-goals and risks, and receives explicit approval.

No later phase number or implementation order is assigned by this record.
