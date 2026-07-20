# Phase 6: Daily-Use Product Completion

Status: Planned
Last updated: 2026-07-21

## Goal

Remove every remaining demo surface and make the app coherent for repeated
offline dictionary use.

## Scope

### Task 1 — Finalize Information Architecture

Choose one supported structure:

- keep Home and implement recent lookups/recent saved content with useful empty
  states, or
- remove Home and make Search the primary launch surface.

Do not keep an empty default tab. Remove commented Analysis/Study code until a
real phase owns those products.

### Task 2 — Complete Saved Management

- Remove the silent 50-record limit or replace it with visible pagination.
- Keep saved ordering explicit and testable.
- Add a clear list-level remove action and undo where appropriate.
- Preserve saved search across term, reading, and definitions without mixing
  dictionary query logic into the View.
- Ensure updates and missing dictionary entries produce explainable behavior.

### Task 3 — Complete Settings

- Remove the Profile dead end unless a real profile feature exists.
- Show app version/build and dictionary source/content/schema versions.
- Explain offline storage and user-data behavior.
- Keep complete source and dependency attribution reachable.
- Add only settings backed by working behavior.

### Task 4 — Product State and Recovery UX

- Add retry actions to recoverable Search/Detail/Saved errors.
- Avoid replacing loaded content with unnecessary spinner flicker.
- Provide meaningful first-use, empty-saved, no-result, and missing-entry states.
- Ensure errors are user-facing messages, not raw persistence implementation
  descriptions.

### Task 5 — Accessibility and Strings

- Verify Dynamic Type without truncating essential headword/definition content.
- Add VoiceOver labels/hints for bookmark, close, source, and navigation actions.
- Verify contrast, dark mode, reduce-motion behavior, and iPad layouts.
- Move user-facing strings into a string catalog and decide supported v1 UI
  languages.

### Task 6 — Product Identity

- Add production app icons for standard/dark/tinted appearances.
- Confirm display name, accent color, launch experience, screenshots, and app
  version surfaces.
- Remove scratch/placeholder resources from the shipped target.

## Non-goals

- App Store submission itself.
- Cloud sync or account/profile implementation.
- Multi-dictionary install UI.
- Full study/analysis tabs.

## Verification Gate

- No visible placeholder, dead-end navigation, empty default surface, or
  commented-out shipped feature remains.
- More than 50 saved entries remain reachable and manageable.
- Accessibility checklist passes on representative small/large devices and iPad.
- All user-facing strings come from the chosen localization system.
- App icon and visible version/source information are present.
- Manual core-loop walkthrough and Store tests pass without stale state or
  unexplained loading flicker.

## Next Phase

[Phase 7: v1 Release Readiness](phase-07-release-readiness.md) validates install,
upgrade, failure recovery, distribution, legal, and App Store requirements.
