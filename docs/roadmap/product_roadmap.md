# KotobaLab Product Roadmap

## 一句话方向

KotobaLab 后续应该先把“词典产品本体”做扎实，再把后端作为分发、同步、AI 的支撑层，最后把 AI 做成学习体验增强，而不是一开始就让 AI 接管核心词典。

当前状态已经具备一个不错的 MVP 基础：

- Search / Detail / Saved 的核心闭环已经跑通。
- Repository / UseCase / Store 的分层开始成型。
- SQLite 词典数据和 SwiftData 用户数据的分工方向合理。
- 数据导入 pipeline 已经有雏形。

下一阶段的分水岭不是继续堆功能，而是把 MVP 快速拼出来的部分逐步替换成长期可维护的产品基础。

## 总体优先级

建议后续按这个顺序推进：

1. 数据库瘦身与数据管线稳定
2. App 核心体验打磨
3. 架构边界和测试补强
4. 后端最小化接入
5. AI 功能实验
6. AI 产品化
7. 作品化与展示

不要先上后端，也不要先上 AI。当前最大的技术债不是“没有后端”，而是词典数据还处在 MVP 临时产物阶段。

1GB 数据库不是单纯因为平台规则不能发布。Apple App Store Connect 文档中，iOS / iPadOS 的最大未压缩 app size 是 4GB。但 1GB 词典库会带来下载、安装、更新、测试和用户体验负担。更重要的是，如果数据库中包含大量 raw content，说明 app bundle 中混入了运行时不一定需要的数据。

参考：

- [Maximum build file sizes - Apple Developer](https://developer.apple.com/help/app-store-connect/reference/maximum-build-file-sizes/)
- [Uploading and versioning Apple hosted background assets - Apple Developer Documentation](https://developer.apple.com/documentation/AppStoreConnectAPI/managing-apple-hosted-background-assets)

## Phase 1：数据瘦身与 Pipeline 重建

这是下一阶段的第一优先级。

当前数据库大是符合 MVP 预期的，因为目标是先跑通。但如果 KotobaLab 要作为长期主作品，数据层必须从“能查到”进化成“结构清楚、体积可控、可重复生成、可更新”。

### 阶段目标

- 当前 MVP 数据库：约 1GB
- Phase 1 目标：小于 300MB
- 理想目标：100MB 到 200MB 以内

具体数字要看 Jitendex / Yomitan 数据结构，但方向很明确：App 运行需要什么，就保留什么；原始导入数据不应该原样进入 app bundle。

### 先做数据库审计

不要盲目删字段。先回答这些问题：

1. 哪些表最大？
2. 哪些字段最大？
3. raw JSON 占多少？
4. FTS index 占多少？
5. index 是否过多？
6. summary 和 detail 是否重复存储？
7. 是否有导入中间数据残留？

可以先用 SQLite 的 `dbstat` 做体积分析：

```sql
SELECT
  name,
  SUM(pgsize) AS size_bytes
FROM dbstat
GROUP BY name
ORDER BY size_bytes DESC;
```

再看整体大小：

```sql
PRAGMA page_count;
PRAGMA page_size;
```

整体大小可以按 `page_count * page_size` 计算。这一步会告诉我们到底是谁吃掉了 1GB。

### 数据库结构拆三层

未来的词典数据库不要直接保存一份完整 raw content，而是拆成三层：

1. Search layer
2. Detail layer
3. Source / debug layer

#### Search layer

Search layer 用于搜索列表页，应该极小、极快。

建议字段：

- `word_id`
- `term`
- `reading`
- `preview_meaning`
- `priority`

Search 页只需要这些，不需要完整释义、例句、tag、source raw JSON。

#### Detail layer

Detail layer 用于详情页，保存结构化详情。

建议字段或结构：

- `word_id`
- `term`
- `reading`
- `senses`
- `glosses`
- `part_of_speech`
- `tags`
- `source`

这里可以用结构化表，也可以存 compact JSON，但不要存原始完整导入对象。

#### Source / debug layer

这类数据不要进 app bundle。

例如：

- raw Yomitan entry
- raw import payload
- debug import info
- pipeline intermediate data

它们应该留在 `data/`、`scripts` 输出目录或本地调试资产中，而不是进入 `KotobaLab/Resources/dictionary_app.sqlite`。

### FTS 重新评估

如果后续使用 SQLite FTS5，要注意 FTS index 本身也会占体积。可以考虑 external content table，减少内容重复存储：

```sql
CREATE VIRTUAL TABLE word_search_fts
USING fts5(
  term,
  reading,
  meaning,
  content='word_search',
  content_rowid='id'
);
```

但不要现在盲改。先审计大小，再判断 FTS 是否是主要问题。

### 当前必须修复的性能点

当前 `meanings.word_id` 没有索引，搜索预览子查询和详情页 meanings 查询都会扫 `meanings` 全表。下一次生成数据库时至少应该补：

```sql
CREATE INDEX idx_meanings_word_id_sequence
ON meanings(word_id, sequence);
```

如果 Search 列表长期需要 `preview_meaning`，更推荐把它放进 Search layer，避免每次列表查询都对子表做 correlated subquery。

### Phase 1 交付物

建议最终产出：

- `scripts/build_dictionary_db.py`
- `docs/dictionary/database_strategy.md`
- `docs/dictionary/dictionary_pipeline.md`
- `KotobaLab/Resources/dictionary_app.sqlite`

并且明确一个可重复生成命令：

```bash
python scripts/build_dictionary_db.py \
  --source data/source/jitendex-yomitan \
  --output KotobaLab/Resources/dictionary_app.sqlite
```

完成标准：

- 删除 sqlite 后可以从 source 重新生成。
- 数据库体积明显下降。
- Search / Detail / Saved 查询结果不退化。
- 查询计划不再出现关键路径全表扫描。

## Phase 2：App 核心体验打磨

数据库瘦身后，不要急着上 AI。先把词典本体体验做扎实。

KotobaLab 的核心价值应该先是一个好用、稳定、反应快、视觉舒服的日语词典和学习工具。AI 是增强，不是地基。

### Search

搜索体验要先做到稳定：

- 输入不卡。
- 搜索结果快。
- 空状态清楚。
- 错误状态清楚。
- 结果排序合理。

当前已经有 `SearchWordsUseCase`，方向是对的。后续可以补：

- `SearchQueryNormalizer`
- `WordSummaryMatcher`
- 搜索 state：idle / loading / loaded / empty / error

但不要过度抽象。

### Saved

下一步 Saved 的重点：

- 收藏 / 取消收藏稳定。
- Saved 列表刷新正确。
- Detail 页与 Saved 页状态一致。
- 本地过滤体验流畅。

如果 Detail 和 Saved 都会执行收藏切换，可以引入：

- `ToggleSavedWordUseCase`

### Word Detail

详情页是产品质感的关键页面。

优先打磨：

- 释义层级
- 读音展示
- 词性 / tag
- 例句
- 收藏按钮状态
- 空 / 加载 / 错误状态

可以考虑新增：

- `LoadWordDetailUseCase`

它通常组合：

- `dictionaryRepository.fetchWordDetail`
- `userDataRepository.isWordSaved`

### Phase 2 质量标准

- Search 首次响应小于 300ms。
- Search 输入不中断 UI。
- 数据库打开稳定。
- Saved 状态一致。
- 核心页面无明显 placeholder 感。
- Preview 可用。
- Mock 可用。

## Phase 3：架构补强

当前方向接近：

```text
Feature -> Store -> UseCase -> RepositoryProtocol -> RepositoryImplementation
```

后续要补齐边界，而不是继续堆层。

推荐中期结构：

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
│   └── Repository
├── Features
├── Navigation
├── Resources
└── Shared
```

### Domain 不要知道 SwiftData

`SavedWordRecord` 是 SwiftData 的 `@Model`，应该留在：

```text
Data/Persistence/SavedWordRecord.swift
```

而不是进入 Domain。

### UseCase 不要碰 UI state

UseCase 只做：

```text
输入 -> 业务动作 -> 输出
```

例如：

```swift
func execute() throws -> [WordSummary]
```

Store 才负责：

- `state = .loading`
- `state = .loaded(words)`
- `state = .error(...)`

### Repository Protocol 不暴露技术细节

Protocol 不应该返回：

- `SavedWordRecord`
- `ModelContext`
- `SQLite.Row`

而应该返回：

- `WordSummary`
- `WordDetail`
- `SavedWordID`

### 补最小测试

不要一开始写很多 UI test。先写最有价值的测试：

- `SearchWordsUseCaseTests`
- `LoadSavedWordsUseCaseTests`
- `ToggleSavedWordUseCaseTests`
- `SearchQueryNormalizerTests`
- `DictionaryPipelineTests`

这些测试比早期 UI 自动化更能保护核心工程质量。

## Phase 4：后端最小化接入

后端不要太早上。判断标准应该是：

只有当一个能力本地做不合适时，才上后端。

### 适合放后端的能力

#### 词典资源分发

如果数据库最终仍然较大，或者希望后续更新词典而不用每次重新发 App，可以用后端、CDN 或 Apple-hosted Background Assets 分发词典资产。

可选结构：

```text
App bundle:
  - 小型基础词库
  - UI
  - 本地用户数据

Remote assets:
  - 完整词典 DB
  - 扩展词库
  - AI 辅助数据
```

#### 用户数据同步

先保持本地 SwiftData。等产品成熟后再考虑：

- saved words 同步
- 学习进度同步
- 用户 notes 同步

不要第一时间做完整账号系统。

#### AI API 代理

如果 AI 使用云端模型，最好走：

```text
iOS App -> Backend -> AI Provider
```

不要让 iOS App 直接持有 provider API key。后端还可以处理：

- 成本控制
- rate limit
- 缓存
- prompt versioning
- 质量记录

### 后端 MVP API

第一版后端只需要：

```text
GET  /dictionary/manifest
GET  /dictionary/assets/{version}
POST /ai/explain-word
POST /ai/generate-examples
```

Manifest 示例：

```json
{
  "latestDictionaryVersion": "2026.04.01",
  "assets": [
    {
      "name": "dictionary-core.sqlite",
      "url": "https://example.com/dictionary-core.sqlite",
      "sha256": "...",
      "size": 123456789
    }
  ]
}
```

### 后端技术栈

先不要纠结技术栈，先确定边界。

合理选择：

- FastAPI / Python
- Node.js / TypeScript
- Vapor / Swift
- Supabase / Firebase

后端不是词典主体，而是资源分发、AI 代理和可选同步。

## Phase 5：AI 功能实验

AI 不应该一上来变成聊天机器人。对 KotobaLab 来说，AI 最有价值的方向是围绕具体词条做学习辅助。

### 第一批 AI 功能

建议顺序：

1. AI 解释词条
2. 例句生成
3. 词义辨析
4. 学习卡片生成
5. 语义搜索

#### AI 解释词条

用户打开一个词，AI 给出：

- 简单解释
- 使用场景
- 相近词区别
- 常见搭配
- 学习提示

#### 例句生成

按用户水平生成例句：

- N5
- N4
- N3
- 日常会话
- 商务语境

AI 生成例句必须有检查和降级策略，不能完全无约束生成。

#### 词义辨析

适合 AI 的例子：

- `勉強する` vs `学ぶ`
- `見る` vs `観る`
- `あげる` vs `くれる` vs `もらう`

#### 学习卡片生成

从 saved words 生成：

- quiz
- cloze deletion
- flashcard
- review plan

这会让 Saved 功能更有产品价值。

#### 语义搜索

语义搜索可以放后面。它适合支持普通关键词搜索做不到的问题：

- “表达感谢的词”
- “商务场合道歉”
- “表示不确定的副词”

### AI 核心原则

AI 不能替代词典数据库。

正确关系应该是：

```text
Dictionary DB = ground truth
AI = explanation / tutor / assistant
```

具体原则：

- 词条是否存在由数据库决定。
- 基础释义来自数据库。
- AI 只基于已知词条做解释和扩展。
- UI 上区分“词典内容”和“AI 生成内容”。

### AI 输出结构化

不要让 AI 直接返回一大段不可控文本。应该要求结构化返回：

```json
{
  "simpleExplanation": "...",
  "nuance": "...",
  "examples": [
    {
      "ja": "...",
      "en": "...",
      "level": "N4"
    }
  ],
  "commonMistakes": ["..."]
}
```

OpenAI Structured Outputs 可以让模型输出符合定义的 JSON Schema，这比单纯要求“返回 JSON”更适合稳定渲染 UI。

参考：

- [Structured model outputs - OpenAI API](https://platform.openai.com/docs/guides/structured-outputs/supported-schemas)

## Phase 6：AI 产品化

AI 实验跑通后，不要马上堆功能。要开始做产品化判断。

需要回答：

1. AI 是免费功能还是高级功能？
2. AI 结果是否缓存？
3. AI 是否根据用户水平调整？
4. 如何避免幻觉？

### 成本和额度

AI 有真实成本。需要设计：

- 免费每日次数
- 登录后增加次数
- 付费订阅
- 本地缓存

### 缓存

建议强缓存：

```text
word_id + prompt_version + user_level -> ai_explanation
```

同一个词不应该每次都重新请求。

### 个性化

用户可以设置：

- JLPT N5 / N4 / N3
- 中文解释 / 英文解释
- 简洁 / 详细

### 避免幻觉

策略：

- 只把当前词条的真实数据传给模型。
- 要求模型不得创造词典中不存在的义项。
- 输出结构化 JSON。
- 显示 AI generated 标识。
- 允许用户反馈。
- 请求失败时回退到纯词典体验。

## Phase 7：作品化与展示

如果 KotobaLab 是个人主作品，就不只是做出来，还要让别人看得懂工程能力。

README 应展示：

- 项目目标
- 核心功能
- 架构图
- 数据 pipeline
- 数据库优化前后对比
- SwiftUI / Observation / UseCase 设计
- 后端设计
- AI 设计
- 截图或 GIF

docs 建议最终包含：

- `docs/architecture.md`
- `docs/dictionary/database_strategy.md`
- `docs/dictionary/dictionary_pipeline.md`
- `docs/backend_plan.md`
- `docs/ai_feature_design.md`
- `docs/product_roadmap.md`

数据库优化前后可以成为很强的作品亮点：

```text
Before:
  SQLite DB: ~1GB
  Raw content included
  MVP pipeline

After:
  SQLite DB: xxx MB
  Raw content removed
  Reproducible pipeline
  Search / Detail schema separated
  FTS optimized if needed
```

## 当前 Review 发现对应的优先级

| Review 发现 | 对应阶段 | 处理建议 |
| --- | --- | --- |
| 词典数据库没有可复现交付路径 | Phase 1 | 建立可重复生成命令、文档和校验 |
| 搜索和详情查询会扫 meanings 全表 | Phase 1 | 增加 `meanings(word_id, sequence)` 索引，重构 preview 查询 |
| 同步 Repository 把数据库 I/O 压在 UI 调用链上 | Phase 2 / Phase 3 | 引入 async repository 或 database actor |
| 被 git 忽略的 TestView 实际参与主 target 编译 | Phase 3 | 清理 target 边界，移除未提交实验代码 |
| 依赖锁定到 GRDB master 分支 | Phase 3 | 改成 version-based package requirement |

## 最关键的战略建议

不要现在就全力做后端和 AI。

否则很容易变成：

- App 本体还不稳。
- 数据库还很大。
- 体验还像 MVP。
- 但开始堆 AI。

这会让项目失焦。

更稳的路线是：

```text
数据瘦身
-> 核心体验
-> 架构稳定
-> 后端资产分发
-> AI 解释 / 例句
-> AI 学习系统
```

## 推荐定位

不要把 KotobaLab 定位成：

```text
AI 日语聊天工具
```

更稳的定位是：

```text
Offline-first Japanese dictionary and study app,
enhanced by AI explanations and personalized learning tools.
```

中文理解：

```text
离线优先的日语词典 + 学习系统，AI 用来增强解释、例句、辨析和复习。
```

这个定位更稳，因为它有坚实的本体：

- 本地词典数据
- 收藏
- 搜索
- 详情
- 学习记录

AI 是加分项，不是全部。

## 下一步建议

最具体的下一步是进入 Phase 1：数据库体积审计 + pipeline 重构。

直接做这五件事：

1. 用 `dbstat` 找出 SQLite 最大表和索引。
2. 判断 raw content 占比。
3. 设计新的 summary / detail schema。
4. 修改 `scripts/build_dictionary_db.py`。
5. 生成瘦身版 `dictionary_app.sqlite`。

然后回到 App 里验证：

- Search 正常。
- Detail 正常。
- Saved 正常。
- 性能正常。

如果这一阶段做好，KotobaLab 会从“功能 MVP”真正进入“可长期发展的产品工程”。
