# Phase 7: v1 Release Readiness

Status: Planned
Last updated: 2026-07-21

## Goal

Turn the completed single-dictionary product into a release candidate that is
safe to install, update, test, and distribute.

## Scope

### Task 1 — Startup and Asset Recovery

- Replace dependency-initialization `fatalError` with a launch state that can
  explain missing, corrupt, incompatible, and migration-failed databases.
- Validate checksum/integrity and required metadata before activation.
- Offer an in-scope recovery path such as retry, restore bundled asset, or clear
  local dictionary copy without deleting unrelated user data.

### Task 2 — Install and Upgrade Matrix

Test at least:

- clean install with the production asset
- app update with unchanged dictionary schema
- dictionary content update with stable saved references
- supported schema migration
- rejected future/incompatible schema
- corrupt/incomplete replacement and rollback
- SwiftData user-model migration

### Task 3 — Automated Product Tests

- Add Store tests for all critical state machines.
- Add a small UI test target for launch → search → detail → save → Saved →
  reopen/unsave plus Settings → attribution.
- Keep tests deterministic with fixtures while retaining a production-asset CI
  smoke gate where valuable.

### Task 4 — Release Quality

- Set latency, launch, memory, database-size, and app-size budgets.
- Test supported iPhone/iPad layouts and the oldest selected OS.
- Decide the deployment target based on product reach and maintenance cost,
  rather than leaving the project-template value unexamined.
- Run accessibility audit and beta feedback pass.

### Task 5 — Privacy, Legal, and Store Metadata

- Declare actual data collection behavior and add required privacy metadata.
- Re-verify every dictionary/dependency attribution and redistribution term.
- Prepare App Store description, screenshots, support/privacy URLs, category,
  age rating, and review notes.
- Keep source-code MIT licensing distinct from dictionary-pack licenses.

### Task 6 — Versioning and Release Procedure

- Define app semantic/release versioning and build-number policy.
- Define dictionary schema/content version compatibility and rollback policy.
- Create a repeatable release checklist from clean checkout through archive,
  TestFlight, acceptance, tag, and release notes.

## Non-goals

- A second dictionary provider.
- Backend account/sync service.
- AI features.
- Study-system expansion.

## v1 Exit Gate

- Every criterion in
  [Product Requirements and v1 Baseline](../product/mvp_prd.md#v1-release-gate)
  is satisfied.
- Clean-install and upgrade matrices pass with no user-data loss.
- CI is green for builder, lint, unit/repository/Store, and critical UI flow.
- No known P0/P1 defect remains; accepted lower-severity issues are documented.
- Attribution, privacy, icon, screenshots, and store metadata are complete.
- A TestFlight build passes the core-loop acceptance walkthrough.

## Next Phase

After v1, [Phase 8: Multi-Dictionary Foundation](phase-08-multi-dictionary.md)
generalizes the single asset into source-aware offline dictionary packs.
