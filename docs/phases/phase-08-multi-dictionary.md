# Phase 8: Multi-Dictionary Foundation

Status: Planned
Last updated: 2026-07-21

## Goal

Support multiple independently versioned, licensed, and selectable offline
dictionary packs while preserving search performance, saved identity, and clear
source attribution.

Architecture direction is documented in
[Multi-Dictionary Strategy](../dictionary/multi_dictionary_strategy.md).

## Scope

### Task 1 — Pack Contract

Define a manifest and common query contract containing dictionary identifier,
schema/content version, languages, source/license metadata, checksums, size, and
compatibility range.

### Task 2 — Source-Aware Identity

Represent an entry reference as at least dictionary identifier + stable source
entry key. Migrate the v1 dictionary and saved/history records to this composite
identity without relying on SQLite row IDs.

### Task 3 — Local Pack Registry

Track installed/enabled packs, versions, paths, activation state, and validation
results. Keep reference data in read-only SQLite packs and user choices/state in
the user-data layer.

### Task 4 — Aggregate Repository

- Search enabled packs with deterministic source ordering and per-pack limits.
- Preserve source identity in every summary/detail result.
- Keep failure in one optional pack from corrupting other packs.
- Benchmark aggregate latency, memory, and cancellation behavior.

### Task 5 — Source-Aware UX

- Let users enable/disable installed dictionaries.
- Label result/detail sources clearly.
- Group overlapping source entries rather than pretending they are one semantic
  record.
- Keep per-pack attribution and license pages reachable.

### Task 6 — Pack Lifecycle

Implement validated install/update/disable/remove/rollback behavior. A network
catalog is optional; local bundled/test packs are enough to prove the model.

## Non-goals

- Automatic semantic merging or conflict resolution between providers.
- User-generated dictionaries.
- A commercial marketplace.
- Mandatory backend delivery.
- Choosing the final second production source; that belongs to Phase 9.

## Verification Gate

- At least two fixture packs can be installed, enabled, searched, updated, and
  removed independently.
- Saved/history references remain stable through individual pack updates.
- Result and detail UI never lose source attribution.
- One corrupt/disabled pack does not prevent another valid pack from working.
- Aggregate search meets documented latency and memory budgets.
- All pack licenses and manifests pass automated validation.

## Next Phase

[Phase 9: Dictionary Catalog Expansion](phase-09-catalog-expansion.md) selects
and ships an additional real dictionary source using this foundation.
