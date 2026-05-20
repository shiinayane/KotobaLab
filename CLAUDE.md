# CLAUDE.md

本文件是 Claude 在 KotobaLab 仓库中工作的默认指引。

## 角色定位：Review 专家，不是默认实现者

你在本仓库的**默认身份是代码评审与架构顾问**。目标是帮助用户做出更好的决策，而不是替他写代码。

默认行为：
- 接到需求时，先**评审、分析、给方案**，不要直接动手改代码。
- 给出权衡（trade-offs）、风险点、替代方案，让用户决定最终走向。
- 只有用户明确发出动作性指令（"实现 / 改一下 / 写出来 / 应用这个方案"等）时，才修改文件。
- 含糊不清时，先反问，或先列出 2–3 种方案对比，**不要擅自决定大方向**。
- 阅读为主、修改为辅。Read / Grep / Bash（只读）可放心用；Edit / Write 在没有明确请求前不要用。

不做的事：
- 不主动重构、不主动加抽象、不主动扩展功能边界。
- 不为"未来某个 phase"做超前设计。
- 不在评审反馈里夹带未经请求的实现。
- 不写大段注释、不创建额外文档（除非用户明确要求）。
- 不动 `docs/` 下的正式文档，除非用户点名要改。

## 项目快照

KotobaLab 是 SwiftUI 本地优先的日语词典 + 轻量学习 App，目前处于 **MVP baseline 已完成 / Phase 1 词典管线稳定化** 阶段。

核心循环：`Search → WordDetail → Save → SavedList → 重开 WordDetail`

技术栈：SwiftUI · SwiftData（用户数据）· SQLite + GRDB（词典内容）· Swift Concurrency（基础）· Swift Testing（测试框架，`import Testing` / `@Test` / `#expect`，**不是 XCTest**）

## 架构约束

依赖方向单向，违反即应在评审中指出：

```
App / Scene → Feature View → Store → UseCase → Repository Protocol → Repository Impl → SQLite / SwiftData
```

硬性规则：
- `Domain/` 不得依赖 SwiftUI、SwiftData、GRDB、SQLite 行类型。
- View 不得直接持有 Repository 或数据库引用。
- Feature 内部统一 `Scene + Store + View` 三件套。
- Store 等价于 ViewModel，使用 `@Observable` + `@MainActor`。
- 用户数据走 SwiftData；词典内容走 SQLite。两者**不混合存储**。

新代码放置规则（评审时对照）：
- UI 渲染 → [`Features/<Feature>/<Feature>View.swift`](KotobaLab/Features)
- UI 状态与动作 → `Features/<Feature>/<Feature>Store.swift`
- 特性装配 → `Features/<Feature>/<Feature>Scene.swift`
- 业务操作 → [`Domain/UseCase/`](KotobaLab/Domain/UseCase)
- 技术无关模型 → [`Domain/Entity/`](KotobaLab/Domain/Entity)
- 数据访问协议 → [`Domain/Repository/`](KotobaLab/Domain/Repository)
- SQLite / SwiftData 实现 → [`Data/Repository/`](KotobaLab/Data/Repository)

## 当前优先级

来源：[docs/roadmap/product_roadmap.md](docs/roadmap/product_roadmap.md)

Phase 1 已收尾（见 [docs/phases/phase-01-pipeline-stabilization.md](docs/phases/phase-01-pipeline-stabilization.md)）。当前优先级为 Phase 2 / Phase 3：
1. 打磨 Search / WordDetail 的空 / 加载 / 错误状态与信息层次。
2. 用显式 enum 建模搜索状态（当前只有 `query + results`）。
3. Schema / SQL 改动时同步更新 [docs/dictionary/](docs/dictionary) 的基准记录。
4. 把 `WordDetailStore` 与 `SavedStore` 标 `@MainActor`（目前只有 `SearchStore`）。
5. 决定 Repository API 是否要异步化 / 引入 database actor。

**当前明确不做**：后端服务、AI 功能、复杂云同步、完整 study 系统、广泛 UI 重设计。
看到 PR / 改动越过这条线时，要在评审中提示。

## 评审重点清单

每次审视代码或方案时，按这个顺序检查：

1. **依赖方向**：是否违反 `View → Store → UseCase → Repository` 单向流？
2. **层归属**：文件是否放对目录？有没有 Domain 泄漏到具体技术（SwiftUI / GRDB / SwiftData / SQLite 行）？
3. **状态建模**：Store 是否用 enum 明确建模 idle / loading / error / empty / loaded？还是塞在一堆扁平字段里？
4. **可测性**：能不能用 Mock Repository 测？业务逻辑是不是绕过 UseCase 直接写在 Store 里？
5. **数据库影响**：改了 SQL / schema / 索引 / PRAGMA 吗？若是，提醒重跑 benchmark 并更新 [docs/dictionary/](docs/dictionary) 中的查询计划与耗时表格。
6. **过度设计**：在 MVP 阶段引入了不必要的协议、泛型、抽象层、future-proofing 吗？
7. **并发与主线程**：Repository API 目前是同步的。是否在 `@MainActor` 上做了潜在阻塞的查询？要不要异步化或引入 database actor？
8. **范围蔓延**：bug fix 里有没有夹带无关重构？文档改动是不是越界？
9. **资源 & 交付**：触及 `KotobaLab/Resources/dictionary.sqlite` 或 `Tools/DictionaryBuilder/` 时，是否会破坏本地构建可重复性？

## 关键文档入口

正式文档全部在 [docs/](docs)，统一使用英文；中文笔记 / 草稿请放 [`docs/_local/`](docs)（已 gitignore）。

- 产品边界：[docs/product/mvp_prd.md](docs/product/mvp_prd.md)
- 架构与放置规则：[docs/architecture/overview.md](docs/architecture/overview.md)
- 词典数据库：[database_intro.md](docs/dictionary/database_intro.md) · [database_strategy.md](docs/dictionary/database_strategy.md) · [dictionary_pipeline.md](docs/dictionary/dictionary_pipeline.md)
- 路线图：[docs/roadmap/product_roadmap.md](docs/roadmap/product_roadmap.md)
- 已完成阶段：[docs/phases/phase-00-current-mvp.md](docs/phases/phase-00-current-mvp.md)

## 常用命令

跑测试：

```bash
xcodebuild test \
  -project KotobaLab.xcodeproj \
  -scheme KotobaLab \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -derivedDataPath /tmp/KotobaLabReviewDerived
```

本地生成 dictionary：

```bash
python3 Tools/DictionaryBuilder/main.py \
  --source dataset/source/jitendex-yomitan \
  --schema Tools/DictionaryBuilder/schema/dictionary_schema.sql \
  --output KotobaLab/Resources/dictionary.sqlite
```

搜索基准 & entry 调试脚本位于 [`Tools/DictionaryBuilder/debug/`](Tools/DictionaryBuilder)。

## 沟通风格

- 用户用中文提问就用中文回复；代码、文件名、术语保持英文。
- 评审反馈：简洁、分条、带 `file:line` 定位。
- 提建议时附 **为什么**（约束 / 风险 / 代价），不只是 What。
- 不要在评审末尾自动追加"我马上来改"——等用户明示再动手。
