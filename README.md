<h1 align="center">KotobaLab</h1>

<p align="center">
  A local-first Japanese dictionary and study app for iOS, built in SwiftUI.
</p>

<p align="center">
  <a href="https://github.com/shiinayane/KotobaLab/actions/workflows/builder-tests.yml">
    <img alt="Builder tests" src="https://github.com/shiinayane/KotobaLab/actions/workflows/builder-tests.yml/badge.svg">
  </a>
  <img alt="iOS 26+" src="https://img.shields.io/badge/iOS-26%2B-007AFF?logo=apple&logoColor=white">
  <img alt="Swift 6" src="https://img.shields.io/badge/Swift-6.0-F05138?logo=swift&logoColor=white">
  <img alt="Status: WIP" src="https://img.shields.io/badge/status-WIP-yellow">
</p>

> [!NOTE]
> KotobaLab is a personal project in active development. The current focus is **Phase 2 — Core App Experience**. See the [Roadmap](#roadmap) below.

The dictionary ships as a bundled, indexed SQLite asset — **293,471 entries in 52 MB** — for sub-millisecond offline prefix search. User data (saved words, future review state) lives in a separate SwiftData store. Backend and AI features are deliberately deferred to later phases.

## Screenshots

> Minimal MVP UI. Polish lives in Phase 2.

| Search | Word Detail |
|---|---|
| ![Search](imgs/search.png) | ![Word Detail](imgs/word_detail.png) |

| Saved | Saved Search |
|---|---|
| ![Saved](imgs/saved.png) | ![Saved Search](imgs/saved_search.png) |

## Highlights

- **Offline-first dictionary.** 293,471 entries derived from JMdict via jitendex-yomitan; prefix search resolves to a verified `MULTI-INDEX OR` plan over `idx_words_term` + `idx_words_reading` and benchmarks at ~0.03 ms after `PRAGMA case_sensitive_like = ON`.
- **Strict layered architecture.** `View → Store → UseCase → Repository protocol → Repository impl → SQLite / SwiftData`. `Domain/` has zero SwiftUI / SwiftData / GRDB imports; every PR is reviewed against this rule.
- **Two-engine persistence.** GRDB-backed SQLite for read-heavy reference content; SwiftData (`@Model SavedWordRecord` with `@Attribute(.unique)`) for user state. The two are never mixed in the same store.
- **Reproducible build pipeline.** Python 3.14 builder (`parse → transform → export_sqlite`) with a self-contained pytest suite running on every push and PR, hard-fail database verification (`verify_database.py`), and one-command release automation (`release_dictionary.sh`) publishing tagged assets to GitHub Releases.

## Tech Stack

| Layer | Technology |
|---|---|
| UI | SwiftUI · `@Observable` stores · iOS 26+ |
| Dictionary storage | SQLite via [GRDB 7](https://github.com/groue/GRDB.swift) (`upToNextMajorVersion` from `7.0.0`) |
| User-data storage | SwiftData |
| Language | Swift 6.0 |
| Concurrency | Swift Concurrency (`Task`, `Task.sleep`) |
| Tests | Swift Testing (`@Test` / `#expect`) + pytest (Python pipeline) |
| Build pipeline | Python 3.14 |
| CI | GitHub Actions ([`builder-tests.yml`](.github/workflows/builder-tests.yml)) |
| Release | Tagged GitHub Release artifact (build + verify + SHA-256 + `gh release create`) |

## Getting Started

The dictionary database (`dictionary.sqlite`, ~52 MB) is **not** committed to git. It is published as a GitHub Release artifact.

```bash
# 1. Clone (HTTPS — works without SSH keys; substitute git@github.com:... if you have SSH set up)
git clone https://github.com/shiinayane/KotobaLab.git
cd KotobaLab

# 2. Download the dictionary from the latest release
curl -L -o KotobaLab/Resources/dictionary.sqlite \
  https://github.com/shiinayane/KotobaLab/releases/latest/download/dictionary.sqlite

# 3. (Optional) Verify the checksum
curl -L -o KotobaLab/Resources/dictionary.sqlite.sha256 \
  https://github.com/shiinayane/KotobaLab/releases/latest/download/dictionary.sqlite.sha256
( cd KotobaLab/Resources && shasum -a 256 -c dictionary.sqlite.sha256 )

# 4. Open in Xcode and build
open KotobaLab.xcodeproj
```

> [!IMPORTANT]
> Builder maintainers who need to regenerate the dictionary from source data do **not** follow this flow — see [For Maintainers](#for-maintainers).

## Architecture

```text
App / Scene
  └─ Feature View         (SwiftUI, pure render)
      └─ Store            (@Observable, ideally @MainActor)
          └─ UseCase      (business operation)
              └─ Repository protocol   ──┐  Domain (framework-free)
                  └─ Repository impl   ──┤
                      ├─ SQLite / GRDB ──┤  Data (concrete persistence)
                      └─ SwiftData     ──┘
```

Hard rules — surfaced in every review:

- `Domain/` cannot import SwiftUI, SwiftData, GRDB, or SQLite row types.
- Views cannot directly hold a Repository or database reference.
- Each feature uses the `Scene + Store + View` triad.
- Dictionary content (SQLite) and user data (SwiftData) never mix.

Detail: [`docs/architecture/overview.md`](docs/architecture/overview.md).

## Repository Layout

```text
KotobaLab/
├── App/                 KotobaLabApp, AppDependencies, TabContainer
├── Domain/              Entities, Repository protocols, UseCases (framework-free)
├── Data/                GRDB / SwiftData implementations + Mocks
├── Features/            Search, WordDetail, Saved, ... (Scene + Store + View triads)
├── Navigation/          AppRouter, AppRoute, AppSheet
├── Shared/              Shared SwiftUI components
└── Resources/           dictionary.sqlite (gitignored, see Getting Started)

KotobaLabTests/          Swift Testing — UseCase + Repository tests + fixture DB
Tools/DictionaryBuilder/ Python pipeline (parse / transform / export_sqlite + pytest)
Tools/scripts/           release_dictionary.sh
docs/                    English project docs (product / architecture / dictionary / roadmap / phases)
.github/workflows/       builder-tests.yml — pytest on every relevant push / PR
```

## For Maintainers

<details>
<summary><b>Run the iOS test suite</b></summary>

```bash
xcodebuild test \
  -project KotobaLab.xcodeproj \
  -scheme KotobaLab \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -derivedDataPath /tmp/KotobaLabReviewDerived
```

</details>

<details>
<summary><b>Re-generate dictionary.sqlite locally</b></summary>

```bash
python3 Tools/DictionaryBuilder/main.py \
  --source dataset/source/jitendex-yomitan \
  --schema Tools/DictionaryBuilder/schema/dictionary_schema.sql \
  --output KotobaLab/Resources/dictionary.sqlite

python3 Tools/DictionaryBuilder/debug/verify_database.py \
  --db KotobaLab/Resources/dictionary.sqlite
```

</details>

<details>
<summary><b>Run the builder pytest suite</b></summary>

```bash
cd Tools/DictionaryBuilder && python3 -m pytest
```

Self-contained — no source dataset or main database required.

</details>

<details>
<summary><b>Publish a new dictionary release</b></summary>

```bash
Tools/scripts/release_dictionary.sh dict-vYYYY.MM.DD
```

Wraps build + verify + SHA-256 + `gh release create` into one command. The artifact is published at <https://github.com/shiinayane/KotobaLab/releases>. See [`docs/dictionary/dictionary_pipeline.md`](docs/dictionary/dictionary_pipeline.md) for the full delivery contract.

</details>

## Roadmap

| Phase | Status | Focus |
|---|---|---|
| 0 — MVP Baseline | Complete | Search / Detail / Save / Saved loop, layered architecture, initial tests |
| 1 — Dictionary Pipeline Stabilization | Complete | Reproducible build, fixture testing, GitHub Release delivery, CI |
| **2 — Core App Experience** | **Current** | Empty / loading / error states, `enum`-modelled state, info hierarchy |
| 3 — Architecture and Tests | Planned | Async repository or database actor; full `@MainActor` isolation; iOS CI |
| 4 — Minimal Backend | Planned | Dictionary asset manifest, AI API proxy |
| 5 — AI Experiments | Planned | Word explanations, example sentences, nuance comparison |
| 6 — AI Productization | Planned | Caching, prompt versioning, rate limiting, cost controls |

Full roadmap: [`docs/roadmap/product_roadmap.md`](docs/roadmap/product_roadmap.md). Phase execution records: [`docs/phases/`](docs/phases).

## Documentation

| Topic | Document |
|---|---|
| Product scope and MVP boundary | [`docs/product/mvp_prd.md`](docs/product/mvp_prd.md) |
| Architecture and placement rules | [`docs/architecture/overview.md`](docs/architecture/overview.md) |
| Dictionary database design | [`docs/dictionary/database_intro.md`](docs/dictionary/database_intro.md) · [`database_strategy.md`](docs/dictionary/database_strategy.md) |
| Build pipeline and delivery | [`docs/dictionary/dictionary_pipeline.md`](docs/dictionary/dictionary_pipeline.md) |
| Roadmap | [`docs/roadmap/product_roadmap.md`](docs/roadmap/product_roadmap.md) |
| Phase 0 — MVP baseline | [`docs/phases/phase-00-current-mvp.md`](docs/phases/phase-00-current-mvp.md) |
| Phase 1 — Pipeline stabilization | [`docs/phases/phase-01-pipeline-stabilization.md`](docs/phases/phase-01-pipeline-stabilization.md) |

## Attribution

KotobaLab ships derivative dictionary data from:

- [JMdict](https://www.edrdg.org/jmdict/j_jmdict.html) — the Japanese–Multilingual Dictionary maintained by the [Electronic Dictionary Research and Development Group](https://www.edrdg.org/).
- [jitendex-yomitan](https://github.com/stephenmk/jitendex) — Stephen Kraus' JMdict-derived Yomitan dictionary.

The shipped `dictionary.sqlite` is licensed under **CC BY-SA 4.0**, inheriting from upstream. Before any App Store release, this attribution must surface in an in-app Acknowledgements view.

## License

The application source-code license is **to be decided** before public release. Until then, the repository is published as a personal portfolio project — no usage rights are granted beyond reading the source.

The shipped dictionary asset is independently licensed under CC BY-SA 4.0; see [Attribution](#attribution).
