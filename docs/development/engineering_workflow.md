# Engineering Workflow

This document defines stable implementation, verification, review, and Git
rules. Current state and temporary results do not belong here.

## Language

Repository-controlled engineering content uses English. User-facing localization
follows its target language. Preserve original third-party licenses, metadata,
quoted errors, and citations.

## Development Flow

```text
Inspect -> Propose -> Approve -> Implement -> Verify -> Review
```

### Inspect

Read the relevant source, tests, [Current Work](current_work.md), active phase,
contracts, and existing worktree changes. Old plans and code are evidence, not
automatic constraints against better evidence.

### Propose

Before implementation, identify:

- problem and current behavior
- files and architecture layers in scope
- user-visible and data-flow changes
- persistence, concurrency, licensing, dependency, and release impact
- verification, non-goals, risks, and meaningful alternatives

Low-risk work may use a short proposal.

### Approve

Explicit approval is required before implementation. Documentation, commit,
push, pull request, merge, and release remain separate permissions.

### Implement

Keep each change within the approved scope and small enough for complete review.
Direct compilation fixes, relevant tests and fixtures, and local formatting
remain in scope.

Pause and propose again if scope expands materially, behavior or a persistence
contract changes unexpectedly, a dependency or architecture layer is added,
user changes would be overwritten, or verification disproves the design.

### Verify

Run the highest relevant evidence:

| Change | Minimum evidence |
| --- | --- |
| Docs or configuration | Targeted validation and `git diff --check` |
| Swift source | Format/lint and relevant tests |
| Feature or composition | Relevant iOS tests and build |
| Builder | Builder tests |
| SQL, schema, or index | Tests, verifier, query plan, and benchmark |
| Dictionary asset | Reproducible rebuild and integrity checks |
| Migration or replacement | Old/new fixtures, failures, and rollback |
| UI behavior | State tests and targeted runtime inspection |
| CloudKit or iCloud | Account, quota, error, and multi-device behavior |

Builds do not prove runtime behavior. Mocks do not prove migration. Screenshots
do not prove lifecycle. Local checks do not prove remote CI. Newest-toolchain
results do not prove the minimum supported environment. Report unavailable
verification explicitly.

### Review

The handoff states what changed and why, behavior before and after, the key
ownership and call chain, important data/concurrency decisions, verification,
unverified boundaries, and recommended review focus.

## Documentation Ownership

Update only the owner affected by evidence:

- next action: Current Work
- phase plan or progress: active phase
- implemented architecture: architecture docs
- dictionary contract: dictionary docs
- product contract: product docs
- long-term direction: Roadmap

Do not mechanically modify every document after every change.

## Commit Convention

Use:

```text
<type>(optional scope): <imperative English summary>
```

Types: `feat`, `fix`, `refactor`, `test`, `docs`, `build`, `ci`, `chore`.

Examples:

```text
feat(dict): preserve ordered senses
fix(search): discard stale results
test(db): cover stable identity rebuild
docs(roadmap): clarify product direction
```

Use a concise summary without a period. One commit expresses one semantic
change. Add a body only for rationale, compatibility, or verification limits.

## Branch Convention

Use ASCII kebab-case: `<type>/<short-description>` and honor any required prefix,
for example `codex/dictionary-metadata`.

## Pull Request Policy

A pull request and relevant remote CI are required before `main` for:

- dictionary schema, runtime format, stable identity, or persisted migration
- database replacement or rollback
- CloudKit, iCloud, privacy, or entitlements
- dependencies, build, signing, or CI
- dictionary release pipeline
- broad cross-layer refactoring
- phase or milestone closeout

Low-risk changes may skip a pull request after user review. The user may require
one for any change.

PR titles follow the commit convention. Descriptions contain only Why, What,
Verification, and Known limits. Agents never merge automatically.

## Delivery Authority

Without explicit authorization, do not stage, commit, push, create or update a
pull request, merge, rewrite history, or release. Permission for one action does
not imply another.

GitHub and other network-dependent delivery commands may require an approved
elevated network environment. If such a command fails inside the sandbox, retry
it with the required authorization before diagnosing credentials or remote
availability.

## Maintenance Limit

Keep this file within 150 physical lines. Replace obsolete rules instead of
appending; move current state, plans, contracts, and commands to their owners.
