# Phase 0: Current MVP Baseline

Date: 2026-04-27

## Goal

Phase 0 的目标是确认 KotobaLab 已经完成一个可运行的最小 MVP：

```text
Search -> Word Detail -> Save / Unsave -> Saved List -> Word Detail
```

这一阶段的重点不是功能完整，而是跑通基础产品闭环、数据访问链路和 SwiftUI 状态驱动 UI。

## Current Status

当前项目已经具备以下基础能力：

- 可以从本地 SQLite 词典数据库搜索词条。
- 可以进入词条详情页查看基础释义。
- 可以收藏和取消收藏词条。
- 可以在 Saved 页查看已收藏词条。
- Search / Saved / WordDetail 已经有对应 Store。
- Domain 层已有基础 Entity、Repository Protocol 和 UseCase。
- Data 层已有 SQLite dictionary repository 和 SwiftData user data repository。
- Scene 层负责组装依赖并把 View 与 Store 连接起来。

## Completed Scope

### Product

- 基础 Tab 结构已经存在。
- Search 页、Saved 页、Word Detail 页已经构成核心路径。
- README 中已有当前 MVP 功能说明和截图。

### Data

- 词典内容使用 SQLite。
- 用户收藏状态使用 SwiftData。
- `DatabaseManager` 负责从 app bundle 准备 `dictionary_app.sqlite`。
- `SQLiteDictionaryRepository` 提供搜索、详情、批量 summary 查询。
- `SwiftDataUserDataRepository` 提供收藏状态读写。

### Architecture

当前架构接近：

```text
SwiftUI View
-> Store
-> UseCase
-> Repository Protocol
-> Repository Implementation
-> SQLite / SwiftData
```

这可以视为 MVVM + UseCase + Repository 的轻量架构。

### Documentation

已经整理出正式文档目录：

- `docs/product/`
- `docs/dictionary/`
- `docs/architecture/`
- `docs/roadmap/`
- `docs/phases/`

本地笔记已迁移到 `docs/_local/`，并由 `.gitignore` 排除。

## Key Decisions

### SQLite for Dictionary Content

词典内容是大量只读或读多写少数据，且搜索性能很重要。因此当前选择 SQLite 作为词典主库是合理的。

### SwiftData for User Data

收藏、未来的 notes、学习进度等用户数据更贴近 SwiftUI 状态和 Apple 生态，因此当前选择 SwiftData 作为用户数据层是合理的。

### Store as ViewModel

项目没有使用传统命名的 `ViewModel`，而是使用 `SearchStore`、`SavedStore`、`WordDetailStore`。这些 Store 实际承担 ViewModel 职责：

- 持有 View state。
- 调用 UseCase 或 Repository。
- 将业务结果转换为 UI 可消费状态。

## Verification

已在本地执行过一次 iOS generic build：

```bash
xcodebuild \
  -project KotobaLab.xcodeproj \
  -scheme KotobaLab \
  -destination 'generic/platform=iOS' \
  -derivedDataPath /tmp/KotobaLabDerived \
  build
```

结果：

```text
BUILD SUCCEEDED
```

注意：项目当前没有 test target，所以还没有自动化行为回归验证。

## Known Risks

### Dictionary DB Delivery

`KotobaLab/Resources/dictionary_app.sqlite` 是运行必需资源，但 sqlite 文件目前被 `.gitignore` 忽略。新环境 clone 后无法保证 app 可运行。

需要在 Phase 1 明确：

- 提交 sample DB。
- 通过脚本生成 DB。
- 或通过 release artifact / remote asset 分发 DB。

### Database Size and Query Plan

当前本地词典数据库约 1.3GB。`words` 和 `meanings` 都是 42 万级记录。

当前缺少 `meanings.word_id` 索引，Search 列表预览和 Word Detail 查询会扫 `meanings` 全表。

Phase 1 需要优先处理：

- 数据库体积审计。
- raw JSON 是否进入 app bundle。
- `meanings(word_id, sequence)` 索引。
- search summary / detail schema 拆分。

### Main Thread I/O

Repository Protocol 当前是同步 `throws` API，SearchStore 又是 `@MainActor`。数据库 I/O 可能压在 UI 调用链上。

Phase 2 / Phase 3 需要考虑：

- async repository。
- database actor。
- 明确 loading / error / cancellation 状态。

### Target Hygiene

当前 Xcode 使用 file-system synchronized group，未跟踪的 `KotobaLab/Features/TestView` 曾被构建日志显示参与主 target 编译。

需要清理：

- 实验代码放到 target 外。
- 或正式提交并标明用途。
- 或配置 target 排除规则。

### Dependency Pinning

GRDB 当前依赖 master branch。后续应该改成版本范围或 exact version，避免不可预期升级。

## Non-goals for Phase 0

这些内容不属于当前阶段：

- 完整后端。
- AI 功能。
- 账号系统。
- 云同步。
- 完整学习系统。
- 大规模 UI polish。

## Next Phase

下一阶段进入：

```text
Phase 1: Database Pipeline and Size Reduction
```

建议优先任务：

1. 用 `dbstat` 审计 SQLite 体积。
2. 计算 raw JSON 字段占比。
3. 增加 `meanings(word_id, sequence)` 索引。
4. 设计 search summary / detail 分层 schema。
5. 更新 `scripts/build_dictionary_db.py`。
6. 生成瘦身版 `dictionary_app.sqlite`。
7. 回归验证 Search / Detail / Saved。
