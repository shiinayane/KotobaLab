# Current Work

Status: Documentation realignment ready for review

## Current Objective

Review and land the rebuilt documentation control plane so that a contributor
without conversation history can identify the product direction, current
decisions, next action, and completion evidence.

Do not expand the dictionary schema or Phase 4 implementation until the formal
documentation reflects the current product and dictionary strategy.

Active execution plan:
[Phase 4: Dictionary Source Contract](../phases/phase-04-dictionary-source-contract.md).

## Context

The previous documentation captured the Phase 0–3 foundation and an initial
path toward v1, but it mixed durable constraints, long-term direction, current
status, and detailed future tasks. Recent analysis also established that the
dictionary ecosystem, user-provided sources, and private synchronization need
clear product boundaries before the runtime model is redesigned.

## Decisions in Force

- `AGENTS.md` contains only stable, minimum agent constraints.
- Formal documentation is the project memory and is written in English.
- The Roadmap records long-term capability direction, not status or tasks.
- This file is the only owner of the current objective and next action.
- Phase records are execution hypotheses; current and planned phases may change
  when evidence or a better implementation approach appears.
- Completed Phase 0–3 records remain frozen historical evidence.
- KotobaLab does not aim to author or maintain commercial-grade dictionary
  content.
- v1 must provide at least one legally redistributable offline dictionary.
- General user dictionary import is not an initial v1 release requirement, but
  v1 architecture must not block it.
- Yomitan is the first external source/import format to evaluate.
- SQLite is a rebuildable runtime representation, not an exchange format.
- Dictionary content and user-owned state remain separate.
- Same-account private synchronization may be added later.
- Public or cross-user distribution of unknown commercial dictionaries is out
  of scope.

## Next Action

Review the documentation-only diff, with particular attention to:

1. Whether the Product Contract states the intended v1 and ecosystem boundary.
2. Whether the Roadmap is durable enough to avoid task-level churn.
3. Whether Dictionary Strategy separates source, canonical, runtime, and user
   data clearly.
4. Whether Phase 4 is a sufficiently bounded source-contract phase.
5. Whether deleted future phase plans contained any still-needed commitment.

After approval, commit and open a pull request only with explicit authorization.
After delivery, begin Phase 4 with a proposal for its first source-corpus slice.

## Expected Scope

This work may modify `AGENTS.md`, files under `docs/`, and documentation links
in repository README files.

It does not modify production source code, tests, fixtures, database assets, CI
workflows, Xcode project settings, or GitHub settings.

## Acceptance

- All formal documents are in English.
- `AGENTS.md` contains no current phase or priority.
- The Roadmap contains no current status, task list, or fixed implementation
  choice.
- This file identifies one concrete next action.
- Product, roadmap, workflow, architecture, dictionary, and phase documents do
  not duplicate ownership.
- Recent dictionary ecosystem decisions are recorded formally.
- Completed Phase 0–3 records remain historically accurate.
- Internal Markdown links resolve.
- Relevant Markdown checks and `git diff --check` pass.
- The user reviews the final diff before any commit or pull request.

## Open Decisions

- Whether Phase 4 evidence should promote user-facing Yomitan import into the v1
  contract.
- Which additional legally usable Yomitan source should serve as a
  compatibility probe.
- Whether later execution should continue sequential phase numbering after
  Phase 4; no future phase is created until needed.

## Verification Baseline

Before this documentation change, the repository had completed Phase 0–3,
established iOS and Dictionary Builder CI, and built a Jitendex Yomitan source
into SQLite. The current builder still flattens glosses, discards extracted
forms, omits source metadata, and relies on rebuild-dependent SQLite row IDs for
saved references.

Implementation work must re-check the actual repository rather than treating
this handoff as runtime proof.

## Non-goals

- Changing the dictionary schema
- Implementing a Yomitan importer
- Implementing multi-dictionary runtime behavior
- Implementing CloudKit
- Modifying product UI
- Configuring GitHub branch protection
- Claiming Phase 4 implementation is complete
