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

## Differentiation

KotobaLab differentiates by combining four strengths:

- **Abundant imported dictionaries:** users bring as many Yomitan dictionaries
  as they own.
- **Native rendering:** every entry renders natively, which enables linked
  entries and other cross-entry interactions.
- **System-wide lookup:** from any screen, a screenshot becomes recognized text
  whose words can be tapped and looked up, or the whole passage translated.
- **A native iOS app:** platform text, accessibility, and appearance
  throughout.

## Principles

- **Local first.** Lookup and saved words work without an account or network.
  Only downloading a dictionary needs a connection.
- **Explicit invocation.** System-wide lookup starts with a deliberate user
  action. KotobaLab never watches other apps or captures content silently.
- **Source aware.** Every entry keeps its dictionary identity and attribution.
  Look-alike entries from different providers are never merged silently.
- **One import path.** The app bundles no dictionary. Recommended and
  user-supplied dictionaries all go through the same Swift importer, and
  supported content is never destructively flattened.
- **Replaceable content.** Dictionary assets evolve independently of the app;
  user references survive compatible rebuilds or migrate explicitly.
- **Explicit scope.** Placeholder tabs, dead-end navigation, and speculative
  abstractions are not progress.

## System-wide Entry

Phase 4 spikes on a signed iPhone showed that explicit system-wide lookup is
feasible. v1 ships all three entry paths:

- An explicitly invoked clipboard Shortcut for selectable text.
- The selected-text Share Sheet.
- Screenshot OCR. iOS lets no app read another app's screen, so a Shortcut
  bound by the user to the Action Button or Back Tap takes the screenshot and
  hands it to KotobaLab. The app guides this one-time setup.

Recognized text is split into words that can each be tapped and looked up, and
the whole passage can be sent to on-device system translation. Candidate
ranking, segmentation accuracy, and saving from an entry surface into the main
app's SwiftData store are not yet verified.

## v1 Contract

v1 is a focused Japanese-English dictionary trusted for ordinary offline lookup.
It must provide:

- the complete core loop with no placeholder destinations
- a Home screen with recent lookups and a daily entry
- an in-app list of recommended openly licensed dictionaries, starting with
  Jitendex, downloaded from their upstream on request; first launch guides the
  user to download one
- private user import of Yomitan dictionaries from Files or a URL: imported
  entries render natively with their source and attribution, updatable
  dictionaries can be checked for updates through their `indexUrl`, and the
  user can remove a dictionary again
- source-aware, stable entry identity
- ordered, structured detail for the supported source subset
- predictable, measured offline search over headwords and readings
- deinflection, so inflected forms such as 食べた find their dictionary form
- the clipboard Shortcut, Share Sheet, and screenshot OCR entry paths, with
  tappable word segmentation and on-device translation of whole passages
- saved entries that survive supported dictionary updates
- visible source, version, attribution, and license information
- recoverable behavior for missing, corrupt, or incompatible assets
- accessibility and release validation suitable for an iOS app
- an English base interface localized into Japanese, Simplified Chinese, and
  Traditional Chinese

v1 is free. Romaji, fuzzy matching, definition search, and a larger study
system are added only after their behavior and value are specified.

v1 non-goals: mandatory accounts or backend, a public dictionary marketplace,
cloud sync, AI-generated definitions, social features, full spaced repetition,
and automatic merging across providers. Machine translation of a passage is
labeled as such and never appears as a dictionary result.

## Release Gate

v1 ships when:

- parsing, runtime projection, and visible detail preserve the declared
  dictionary contract
- dictionary updates preserve identity or migrate user references safely
- a failed import leaves the previous state intact, unsupported content in an
  imported dictionary is reported instead of dropped silently, and removing or
  replacing an imported dictionary never deletes saved entries silently
- search is fixture-backed, deterministic, and measured
- clean install and supported updates preserve the core loop
- no placeholder, fatal startup path, missing attribution, or known destructive
  flattening remains
- importer and app checks pass in CI, using small self-made Yomitan fixtures
- accessibility, privacy, license, metadata, and distribution checks are done

## Dictionary Ecosystem Boundary

Yomitan import from Files, a URL, or the recommended list is part of v1.
Recommended dictionaries are downloaded from their own upstream, so KotobaLab
does not redistribute them; their attribution comes from each dictionary's
`index.json`. Downloads accept only HTTPS, check size before downloading, and
validate the archive before importing. User-imported dictionaries may later
sync privately between one user's devices.

KotobaLab will not recommend a dictionary without confirmed permission, scrape
commercial dictionary sites, run a public exchange for unknown commercial data,
or treat AI output as licensed dictionary content.

## Roadmap

Each milestone starts with a proposal and explicit approval.

| Milestone | Scope |
| --- | --- |
| M0 Cleanup | Remove demo views, load every saved word, replace the fatal launch path with a recoverable state |
| M1 Data foundation | Structured-content storage, stable entry identity, dictionary registry, a Swift Yomitan importer core, downloading and importing Jitendex, measured download size and on-device import time; retire the Python builder, the released SQLite asset, and its CI download |
| M2 Native detail | Production native renderer for imported dictionaries, linked entries, the rendering gaps v1 needs |
| M3 Import | Import from Files and URLs, the recommended list, update checks, removal, multi-dictionary lookup with source sections, deinflection |
| M4 System-wide lookup | Clipboard Shortcut, Share Sheet, screenshot OCR, word segmentation, on-device translation |
| M5 Release | Home, localization, accessibility, privacy manifest and policy, icon, App Store metadata, TestFlight |

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

Later opportunities, not commitments: notes, tags, light study
workflows, spaced repetition, more definition languages and monolingual
sources, optional private cloud sync, and bounded AI assistance that never
replaces dictionary sources.

Use small disposable spikes for high-risk questions. A successful spike does
not authorize production code.
