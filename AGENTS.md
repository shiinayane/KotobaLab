# AGENTS.md

Rules for every agent task in KotobaLab. This file holds only what cannot be
inferred from the code. Each fact in the repository has exactly one owner
document; link to it instead of restating it.

## Reading

Always read [`docs/current_work.md`](docs/current_work.md) first. Then read only
what the task touches:

| Task touches | Read |
| --- | --- |
| Swift code, layering, concurrency, tests | [`docs/architecture.md`](docs/architecture.md) |
| Dictionary data, builder, schema, assets | [`docs/dictionary.md`](docs/dictionary.md) |
| Product scope, priorities, licensing | [`docs/product.md`](docs/product.md) |

`docs/archive/` holds frozen phase records. Read them only to trace the history
of a decision. `docs/_local/` is gitignored scratch and never a contract.

Documentation records intent; source code and verification record the
implementation. When they conflict, report the evidence and propose a
correction instead of silently choosing one.

## Workflow

```text
Inspect -> Propose -> Approve -> Implement -> Verify -> Report
```

- Inspect the relevant code, tests, docs, and existing worktree changes.
- Propose the goal, scope, affected layers, data/persistence/concurrency impact,
  risks, non-goals, and verification plan. Low-risk work may use a short
  proposal.
- Implement only after explicit approval and only within the approved scope.
  Direct compile fixes, related tests, fixtures, and formatting stay in scope.
- Pause for renewed approval if scope expands materially, product behavior or a
  persistence contract changes, a dependency or layer is added, user changes
  would be overwritten, or verification disproves the design.
- Report what changed and why, the key call chain, verification evidence, and
  unverified boundaries.

Review requests are not implementation requests. Preserve unrelated worktree
changes. Do not refactor outside the approved task or hide architecture changes
inside a bug fix. Do not add layers, protocols, or generics for unconfirmed
future needs.

When isolation is needed, use the isolated workspace the host tool provides.
Create a manual Git worktree only when the user asks for one.

## Permissions

Implementation, documentation, staging, commit, push, pull request, merge, and
release are separate permissions. Never infer one from another. Agents never
merge.

## Verification

| Change | Minimum evidence |
| --- | --- |
| Docs or configuration | Targeted check and `git diff --check` |
| Swift source | `swift format lint -r -s -p KotobaLab/ KotobaLabTests/` and relevant tests |
| Feature or composition | iOS build and tests |
| Builder | `cd Tools/DictionaryBuilder && python3 -m pytest` |
| SQL, schema, or index | Builder tests, verifier, query plan, and benchmark |
| Dictionary asset or migration | Reproducible rebuild, integrity checks, old/new fixtures |
| UI behavior | State tests and runtime inspection |

iOS tests:

```bash
xcodebuild test -project KotobaLab.xcodeproj -scheme KotobaLab \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest'
```

Use a host-provided Apple validation skill when one is available. Builds do not
prove runtime behavior, mocks do not prove migration, and local results on a
newer Xcode do not prove CI, which pins its own Xcode version. Report
unavailable verification explicitly; never describe it as passing.

## Documentation

- Update `docs/current_work.md` when the objective, next action, or an open
  decision changes.
- Update the owner document when a decision or contract changes. Do not copy
  counts, measurements, or rules into a second document.
- Record measurements only in `docs/dictionary.md`, with artifact and date.
- Do not edit `docs/archive/` except to fix links or factual errors.
- Replace obsolete text instead of appending.

## Git

Commits use `<type>(optional scope): <imperative summary>` with types `feat`,
`fix`, `refactor`, `test`, `docs`, `build`, `ci`, or `chore`. One commit is one
semantic change; add a body only for rationale or verification limits.

Branches use ASCII kebab-case `<type>/<short-description>`, plus any prefix the
host tool requires.

A pull request with passing remote CI is required before `main` for schema,
runtime format, stable identity, persisted migration, database replacement,
privacy or entitlements, dependencies, build, signing, CI, the dictionary
release pipeline, and broad cross-layer refactors. Other changes may skip a pull
request after user review. PR descriptions contain Why, What, Verification, and
Known limits.

## Language

Code, comments, tests, formal docs, commits, branches, pull requests, and review
text use English. User-facing localization follows its target language.
Preserve the original language of third-party licenses, dictionary metadata,
quoted errors, and citations. Communicate with the user in the language they
use.
