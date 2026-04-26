# Architecture Overview

Date: 2026-04-27

## Summary

KotobaLab 当前采用轻量分层架构，可以理解为：

```text
MVVM + UseCase + Repository
```

它不是完整 Clean Architecture，也不需要现在变成完整 Clean Architecture。当前最重要的是保持依赖方向清楚、Feature 可测试、数据层可替换。

## Layer Map

当前主要目录：

```text
KotobaLab
├── App
├── Domain
│   ├── Entity
│   ├── Repository
│   └── UseCase
├── Data
│   ├── Database
│   ├── Persistence
│   ├── Preview
│   └── Repository
├── Features
├── Navigation
├── Resources
└── Shared
```

## Dependency Direction

目标依赖方向：

```text
App / Scene
  -> Feature View
  -> Store
  -> UseCase
  -> Repository Protocol
  -> Repository Implementation
  -> SQLite / SwiftData
```

View 不应该直接依赖 SQLite、SwiftData 或 concrete repository。

Domain 不应该依赖 SwiftUI、SwiftData、GRDB 或 app framework implementation details。

## Feature Structure

当前核心 Feature：

- `Features/Search`
- `Features/Saved`
- `Features/WordDetail`

每个核心 Feature 大致分为：

- `Scene`: 组装 dependencies，创建 Store。
- `Store`: 持有 UI state，调用 UseCase / Repository。
- `View`: 只负责渲染和用户交互。

例子：

```text
SearchScene
-> SearchStore
-> SearchWordsUseCase
-> DictionaryRepositoryProtocol
-> SQLiteDictionaryRepository
```

## MVVM Mapping

当前项目里没有使用 `ViewModel` 命名，而是使用 `Store`。

对应关系：

| MVVM 概念 | 当前实现 |
| --- | --- |
| View | `SearchView`, `SavedView`, `WordDetailView` |
| ViewModel | `SearchStore`, `SavedStore`, `WordDetailStore` |
| Model | `WordSummary`, `WordDetail`, `Meaning` |
| Service / Repository | `DictionaryRepositoryProtocol`, `UserDataRepositoryProtocol` |
| Data source | SQLite, SwiftData |

因此当前架构可以称为：

```text
MVVM with UseCase and Repository boundaries
```

## Domain Layer

Domain 当前包含：

- Entity
- Repository Protocol
- UseCase

### Entity

`Domain/Entity/DictionaryModels.swift` 定义 app 内部使用的词典模型：

- `WordSummary`
- `WordDetail`
- `Meaning`
- `SavedWordSummary`

这些模型应该保持技术无关，不暴露 SQLite row、SwiftData model 或网络 DTO。

### Repository Protocol

`DictionaryRepositoryProtocol` 负责词典内容：

- search words
- fetch word detail
- fetch summaries by ids

`UserDataRepositoryProtocol` 负责用户数据：

- check saved state
- save word
- unsave word
- fetch saved word ids

Protocol 应该只暴露领域模型或领域 ID，不暴露底层技术细节。

### UseCase

当前已有：

- `SearchWordsUseCase`
- `LoadSavedWordsUseCase`

UseCase 的职责是表达业务动作，而不是管理 UI state。

好的边界：

```swift
func execute() throws -> [WordSummary]
```

不推荐：

```swift
func execute() {
    state = .loading
    ...
}
```

UI state 属于 Store。

## Data Layer

Data 当前包含：

- `DatabaseManager`
- `SQLiteDictionaryRepository`
- `SwiftDataUserDataRepository`
- mock / preview repository
- SwiftData persistence model

### SQLite

SQLite 负责词典主库。适合：

- 大量只读词典内容。
- 可控 schema。
- 搜索索引。
- 批量导入。

当前需要补强：

- 可重复生成 pipeline。
- 数据库体积控制。
- `meanings.word_id` 查询索引。
- Search summary / Detail data 分层。

### SwiftData

SwiftData 负责用户数据。适合：

- 收藏。
- 未来 notes。
- 学习进度。
- 本地用户状态。

`SavedWordRecord` 属于 Data/Persistence，不应该进入 Domain。

## App and Dependency Injection

`KotobaLabApp` 负责创建基础 dependencies：

```text
DatabaseManager
-> SQLiteDictionaryRepository
-> AppDependencies
-> RootView
```

`AppDependencies` 当前包含：

- `dictionaryRepository`
- `userDataRepositoryFactory`

`userDataRepositoryFactory` 通过 SwiftData `ModelContext` 创建 user data repository。这是合理的，因为 `ModelContext` 来自 View environment，只能在 Scene / View 组装阶段拿到。

## Navigation

当前已有：

- `AppRouter`
- `AppRoute`
- `AppSheet`

实际 Word Detail 导航目前主要通过 View closure 构造 destination，而不是完全通过 `AppRouter.path`。

短期可以接受。等导航复杂后再统一路由模型，避免现在过早抽象。

## State Management

当前 Store 使用 Observation：

- `@Observable`
- `@Bindable`
- `@State`

核心 View state 使用 enum 表达，例如：

- `SavedViewState`
- `WordDetailViewState`

这是好的方向。后续 Search 也应该补明确状态，而不是只有 `query` 和 `results`。

建议 Search 后续状态：

```swift
enum SearchViewState {
    case idle
    case loading
    case loaded([WordSummary])
    case empty
    case error(String)
}
```

## Current Weak Points

### Synchronous I/O

Repository API 目前是同步 `throws`。随着数据库变大，Store 直接调用同步 repository 会有 UI 卡顿风险。

中期建议：

- 将 dictionary repository 改成 async。
- 或用 dedicated database actor 包住 SQLite 查询。
- Store 只在 MainActor 更新 state。

### Testing Gap

当前没有 test target。

优先补：

- UseCase tests。
- query normalizer tests。
- repository tests with small fixture DB。
- dictionary pipeline tests。

UI test 可以后置。

### Target Hygiene

Xcode file-system synchronized group 会让目录下本地实验文件进入 target。需要保证：

- 正式代码在 `KotobaLab/`。
- 本地实验代码不要放在 app target 同步目录。
- 或显式提交并说明用途。

## Near-term Architecture Tasks

1. 给 Search / Saved / Detail 的 Store 补测试。
2. 设计 async repository 或 database actor 边界。
3. 把 Search state 改成 enum。
4. 增加 `ToggleSavedWordUseCase`。
5. 增加 `LoadWordDetailUseCase`，组合详情和收藏状态。
6. 清理 target 内未跟踪实验文件。
7. 固定 GRDB 版本。

## Rule of Thumb

新增功能时按这个问题判断放哪：

- UI 展示和交互：放 `Features/*/*View.swift`
- UI 状态和用户动作编排：放 `Features/*/*Store.swift`
- 业务动作：放 `Domain/UseCase`
- 技术无关模型：放 `Domain/Entity`
- 数据访问协议：放 `Domain/Repository`
- SQLite / SwiftData 实现：放 `Data/Repository`
- App 级组装：放 `App` 或 `*Scene`

不要为了“更像架构”而加层。只有当一个层能降低重复、隔离变化或提高测试性时，再引入它。
