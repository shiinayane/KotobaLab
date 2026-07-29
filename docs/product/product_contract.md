# Product Contract

Status: Active
Last updated: 2026-07-30

## Product Definition

KotobaLab is a native, local-first Japanese dictionary and light study app for
iOS. It should first become dependable for everyday lookup, then grow through
additional dictionary sources and user-owned learning features.

The target everyday loop is:

```text
Encounter Japanese anywhere
-> invoke KotobaLab explicitly
-> inspect a dictionary-backed result in context
-> save the relevant entry or context
-> reopen it later
```

In-app search remains a first-class path through the same dictionary experience.
System-wide entry is a product direction, not a claim that its production
surface has already been selected or implemented.

## Target Users

The first release serves Japanese learners who need to:

- look up a Japanese headword or reading quickly
- distinguish likely matches from less relevant entries
- inspect structured senses and usage information
- save an entry and find it again later
- use the dictionary without a network connection
- begin a lookup from Japanese encountered outside KotobaLab through an
  explicitly invoked path

The initial definition language may remain English.

## Product Principles

### Local First

Lookup and saved-word access must work without an account or network connection.
Dictionary content is read-only reference data; saved words and other personal
state are user-owned data.

### Explicit Invocation

System-wide lookup begins with an intentional user action. Selected text,
clipboard text, and screenshot OCR may provide entry paths, but KotobaLab does
not continuously inspect other apps or silently capture user content.

### Source Aware

Every displayed entry retains its dictionary identity and attribution.
Equivalent-looking entries from different providers are not silently merged.

### Faithful Before Broad

One legally redistributable bundled dictionary is enough for v1, but its
supported content must not be destructively flattened. Breadth does not justify
losing ordered senses, searchable forms, or source identity.

### Replaceable Content

Dictionary assets may evolve independently of the app. Durable user references
must survive compatible rebuilds or have an explicit migration policy.

### Explicit Scope

New product surfaces must be complete enough to use. Placeholder tabs, dead-end
navigation, and speculative abstractions are not product progress.

## v1 Contract

v1 is a focused Japanese-English dictionary that can be trusted for ordinary
offline lookup.

It must provide:

- the complete core loop without placeholder destinations
- at least one bundled dictionary whose license permits redistribution
- source-aware, stable entry identity
- ordered, structured dictionary detail for the supported source subset
- predictable offline search over supported headwords and readings
- saved entries that remain valid across supported dictionary updates
- visible dictionary source, version, attribution, and license information
- recoverable behavior for missing, corrupt, or incompatible dictionary assets
- accessibility and release validation appropriate for an iOS application

Romaji, fuzzy matching, deinflection, definition search, and a larger study
system are useful only after their behavior and value are specified.

## Dictionary Ecosystem Boundary

A general Yomitan import interface is not a v1 release requirement. However,
the source model, stable identity, and runtime asset contract must not make
future user import unnecessarily difficult.

User-imported dictionaries may later be synchronized privately between devices
owned by the same account. Private synchronization does not authorize public
distribution, catalog listing, sharing, or cross-user transfer.

KotobaLab will not:

- bundle or redistribute a dictionary without confirmed permission
- scrape commercial dictionary websites
- provide a public exchange for unknown commercial dictionary data
- treat AI output as licensed dictionary content or as the source of truth

## v1 Non-goals

- Mandatory accounts or backend service.
- Public dictionary marketplace.
- General user dictionary import UI.
- Cloud synchronization.
- AI-generated dictionary definitions.
- Social features.
- Full spaced-repetition system.
- Automatic semantic merging across providers.

## Release Gate

v1 is ready when:

- source parsing, runtime projection, and visible detail preserve the declared
  supported dictionary contract
- dictionary rebuilds preserve identity or migrate user references safely
- search behavior is fixture-backed, deterministic, and measured
- clean-install and supported update flows preserve the core loop
- no placeholder, fatal startup path, missing attribution, or known destructive
  content flattening remains
- critical builder and app checks pass in CI
- accessibility, privacy, license, metadata, and distribution checks are
  complete

Execution details belong in [Current Work](../development/current_work.md) and
the current [Phase Record](../phases/README.md), not in this contract.
