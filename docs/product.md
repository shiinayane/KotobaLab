# Product

What KotobaLab is, what v1 must deliver, and where it is heading. Current status
belongs in [Current Work](current_work.md), not here.

## Definition

KotobaLab is a native, local-first Japanese dictionary and light study app for
iOS. It should become dependable for everyday lookup before it becomes a broad
study platform or an AI product.

Target loop:

```text
Encounter Japanese anywhere -> invoke KotobaLab explicitly
-> inspect a dictionary-backed result in context
-> save the entry or context -> reopen it later
```

In-app search remains a first-class path into the same experience.

The first release serves Japanese learners who need to look up a headword or
reading quickly, tell likely matches from weak ones, read structured senses,
save and revisit entries, work offline, and start a lookup from text outside
the app. The definition language may stay English at first.

## Principles

- **Local first.** Lookup and saved words work without an account or network.
- **Explicit invocation.** System-wide lookup starts with a deliberate user
  action. KotobaLab never watches other apps or captures content silently.
- **Source aware.** Every entry keeps its dictionary identity and attribution.
  Look-alike entries from different providers are never merged silently.
- **Faithful before broad.** One redistributable bundled dictionary is enough
  for v1, but its supported content must not be destructively flattened.
- **Replaceable content.** Dictionary assets evolve independently of the app;
  user references survive compatible rebuilds or migrate explicitly.
- **Explicit scope.** Placeholder tabs, dead-end navigation, and speculative
  abstractions are not progress.

## System-wide Entry

Phase 4 spikes on a signed iPhone showed that explicit system-wide lookup is
feasible. The candidate entry paths are still hypotheses:

- An explicitly invoked clipboard Shortcut is the primary hypothesis for
  selectable text because its path is shortest.
- The selected-text Share Sheet works but is three levels deep, so it is at most
  a secondary path.
- Screenshot OCR worked end to end; candidate ranking and interaction design
  remain open.

Saving from an entry surface into the main app's SwiftData store was not
verified.

## v1 Contract

v1 is a focused Japanese-English dictionary trusted for ordinary offline lookup.
It must provide:

- the complete core loop with no placeholder destinations
- at least one bundled dictionary whose license permits redistribution
- source-aware, stable entry identity
- ordered, structured detail for the supported source subset
- predictable, measured offline search over headwords and readings
- saved entries that survive supported dictionary updates
- visible source, version, attribution, and license information
- recoverable behavior for missing, corrupt, or incompatible assets
- accessibility and release validation suitable for an iOS app

Romaji, fuzzy matching, deinflection, definition search, and a larger study
system are added only after their behavior and value are specified.

v1 non-goals: mandatory accounts or backend, a public dictionary marketplace, a
general user dictionary import UI, cloud sync, AI-generated definitions, social
features, full spaced repetition, and automatic merging across providers.

## Release Gate

v1 ships when:

- parsing, runtime projection, and visible detail preserve the declared
  dictionary contract
- rebuilds preserve identity or migrate user references safely
- search is fixture-backed, deterministic, and measured
- clean install and supported updates preserve the core loop
- no placeholder, fatal startup path, missing attribution, or known destructive
  flattening remains
- builder and app checks pass in CI
- accessibility, privacy, license, metadata, and distribution checks are done

## Dictionary Ecosystem Boundary

A general Yomitan import interface is not a v1 requirement, but the source
model, identity, and asset contract must not make later user import hard.
User-imported dictionaries may later sync privately between one user's devices.

KotobaLab will not bundle a dictionary without confirmed permission, scrape
commercial dictionary sites, run a public exchange for unknown commercial data,
or treat AI output as licensed dictionary content.

## Long-term Directions

1. **Trustworthy dictionary foundation:** faithful, versioned, source-aware,
   legally usable data, measured for correctness, size, and speed.
2. **Complete daily experience:** predictable search, explicit system-wide
   entry, structured detail, durable saved entries, accessibility, recovery.
3. **Extensible ecosystem:** independently identified and versioned sources,
   each evaluated on license, quality, maintenance, size, and value.
4. **Personal data continuity:** user state outlives dictionary assets and can
   be backed up, exported, and synced privately, never retargeted to another
   provider silently.

Later opportunities, not commitments: recent activity, notes, tags, light study
workflows, spaced repetition, more definition languages and monolingual
sources, optional private cloud sync, and bounded AI assistance that never
replaces dictionary sources.

Use small disposable spikes for high-risk questions. A successful spike does
not authorize production code.
