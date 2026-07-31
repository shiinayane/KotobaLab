# AGENTS.md

Minimum constraints for agents working in the KotobaLab repository.

This file contains only rules that apply to every task and cannot be inferred
reliably from the code. Product state, current work, engineering workflow, and
execution plans belong under [`docs/`](docs/README.md).

## Required Reading

Before changing the repository, read:

1. [`docs/README.md`](docs/README.md)
2. [`docs/development/current_work.md`](docs/development/current_work.md)
3. The phase, architecture, or dictionary documents linked by the current work
4. The relevant source code and tests

Documentation records intent and constraints. Source code and verification
results record the implementation. When they conflict, report the evidence and
propose a correction instead of silently choosing one.

## Collaboration

- Inspect and propose before modifying files.
- When isolated development is needed, default to a separate Codex managed
  Worktree conversation. Do not manually run `git worktree add` in the current
  conversation or modify across worktrees by changing `workdir`. Use Local,
  Handoff, a permanent worktree, or a manual Git worktree only when the user
  explicitly requests it.
- State the goal, scope, architecture impact, risks, non-goals, and verification
  plan.
- Implement only after explicit approval and only within the approved scope.
- Pause for renewed approval if implementation would materially expand scope,
  change product behavior, alter a persistence contract, or add a dependency.
- Keep changes small enough for the user to understand and review completely.
- Explain behavior changes, key mechanisms, verification evidence, and
  unverified boundaries after implementation.
- Do not ask the user to copy code mechanically unless they request a snippet.

Implementation, documentation, commit, push, pull request, merge, and release
are separate permissions. Never infer one from another.

## Architecture Boundaries

Dependency direction remains one-way:

```text
App / Scene → Feature View → Store → UseCase → Repository protocol
→ Repository implementation → SQLite / SwiftData
```

- `Domain/` must not import SwiftUI, SwiftData, GRDB, or SQLite record types.
- Views must not hold repositories or database references directly.
- Features use the `Scene + Store + View` structure.
- Observable UI Stores are explicitly `@MainActor @Observable`.
- Dictionary content remains in SQLite; user data remains in SwiftData.
- Business logic must not bypass UseCases and move into Views.
- Do not add layers, protocols, generics, or abstractions for unconfirmed future
  needs.

Add an abstraction only when it removes real duplication, isolates a known
change, or materially improves testability.

## Scope and Evidence

- Preserve unrelated worktree changes.
- Do not refactor outside the approved task.
- Do not turn review requests into implementation.
- Do not hide unrelated architecture changes inside a bug fix.
- Report unavailable verification explicitly; never describe it as passing.
- Mark work complete only when supported by actual evidence.
- Close a phase only when its acceptance gate is satisfied.

## Apple Platform Validation

When a Swift, SwiftUI, Xcode, Simulator, device, signing, UI, or performance
change requires executable Apple-platform evidence, use the available
`apple-dev-loop` skill to select and run the smallest sufficient validation
profile. Do not invoke it for documentation-only work, source-only explanations,
or changes that require no Apple toolchain or runtime evidence.

## Language

Source code, comments, test names, formal documentation, commits, branches, pull
requests, and review text use English. User-facing localization follows its
target language. Preserve the original language of third-party licenses,
dictionary metadata, quoted errors, and citations. Communicate with the user in
the language they use.

Engineering, verification, and Git conventions are defined in
[`docs/development/engineering_workflow.md`](docs/development/engineering_workflow.md).
