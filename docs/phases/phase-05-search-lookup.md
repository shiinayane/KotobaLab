# Phase 5: Search and Lookup Quality

Status: Planned
Last updated: 2026-07-21

## Goal

Make lookup predictable: common input should find the intended entry quickly,
the result order should be explainable, and detail should expose the structured
content preserved in Phase 4.

## Scope

### Task 1 — Search Behavior Specification

Define supported normalization and matching for:

- surrounding whitespace
- hiragana/katakana handling where appropriate
- exact headword and exact reading
- headword/reading prefix
- alternative forms
- case/width behavior for non-Japanese text present in entries

Explicitly decide whether romaji, deinflection, fuzzy matching, and definition
full-text search are in or out. They are not implied requirements.

### Task 2 — Ranking and Stable Ordering

- Rank exact matches before prefix/alternative-form matches.
- Use source priority/frequency only where its semantics are understood.
- Add deterministic tie breakers.
- Specify deduplication when one entry matches through multiple forms.
- Keep source order accidentalities out of the public contract.

### Task 3 — Result Window Strategy

Replace the undocumented fixed 20-result behavior with one of:

- an explicit capped result set with a clear product reason, or
- incremental loading/pagination.

The choice must preserve latency and simple interaction on broad kana prefixes.

### Task 4 — Structured Word Detail

- Render ordered senses and glosses.
- Show POS/tags/restrictions at their correct scope.
- Keep the intentional term + reading presentation even when equal.
- Show source attribution/edition in a compact form.
- Add copy and share actions.
- Add visible retry for recoverable load failures.

### Task 5 — History Input for Product Navigation

Record recent successful lookups with stable entry identity. This data will
either power a useful Home screen in Phase 6 or support a recent-search section
inside Search if Home is removed.

### Task 6 — Tests and Benchmarks

- Add fixture-backed ranking/normalization tests.
- Add Store tests for debounce, cancellation, stale result rejection, empty,
  error, retry, and pagination/cap behavior.
- Benchmark the complete production projection and ordering, not a simplified
  SQL fragment.
- Update verifier expectations and dictionary docs with every schema/query-plan
  change.

## Non-goals

- Multi-provider aggregate search.
- Automatic semantic merging of duplicate-looking entries.
- AI explanations.
- Broad visual redesign outside Search and Word Detail.

## Verification Gate

- A written search matrix maps representative input to ordered expected results.
- Exact, reading, kana, form, no-result, and broad-prefix cases pass repository
  and Store tests.
- Search order is deterministic across repeated builds.
- Detail renders representative multi-sense entries without destructive
  flattening.
- Search remains responsive on the production database and no query-plan
  regression is accepted without measurement and rationale.
- Recent lookup recording does not block search or corrupt saved data.

## Next Phase

[Phase 6: Daily-Use Product Completion](phase-06-product-completion.md) completes
navigation, saved management, settings, accessibility, and product identity.
