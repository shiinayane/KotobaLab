# 数据库选型

对 KotobaLab 这种本地词典 / 学习类 App，我会把数据库选型拆成两层看：

SwiftData 更像 Apple 生态里“面向 App 状态和对象关系”的持久化框架（persistence framework）；你用 @Model 定义模型，SwiftData 负责存储、查询、关系遍历、索引（index）和可选的 CloudKit 同步。官方也强调它是用声明式（declarative）模型代码来做持久化和高效抓取（fetching）的。 ￼

SQLite 则更像底层数据库引擎（database engine）：轻量、嵌入式（embedded）、事务性（transactional），适合做本地文件数据库。SQLite 官方明确把它定位为应用内嵌数据库，并提供 ACID 事务保证；同时它自带全文检索（full-text search）扩展，尤其是 FTS5，专门面向高效文本搜索。 ￼

对你这个项目，最重要的不是“谁更高级”，而是谁负责哪一层。

⸻

## 一、先给结论

如果 KotobaLab 第一阶段重点是把 App 跑起来，尤其是：
    •    收藏
    •    历史记录
    •    用户笔记
    •    学习状态
    •    简单本地同步

那 SwiftData 很适合做用户侧数据（user data）。它和 SwiftUI 结合紧，开发体验好，模型定义也自然。 ￼

如果 你要处理“大量词典内容 + 复杂搜索”，尤其是：
    •    kanji / reading 联合搜索
    •    前缀搜索（prefix search）
    •    全文检索（full-text search）
    •    大量只读词典数据（read-only dictionary data）
    •    自己控制表结构、索引、查询性能

那 SQLite 更适合做词典主库（dictionary store），因为它就是为结构化本地数据和搜索这类场景准备的，而且 FTS5 是它的强项。 ￼

所以对 KotobaLab，我最推荐的不是二选一，而是：

词典内容用 SQLite，用户数据用 SwiftData。

这是我基于你的项目形态做的工程判断，不是 Apple 官方一句话直接这么写，但和两者的官方定位非常一致。 ￼

⸻

## 二、SwiftData 适合管什么

### 1. 用户自己产生的数据（user-generated data）

比如：
    •    Favorites
    •    Notes
    •    Review progress
    •    Search history
    •    App preferences

这类数据通常有几个特点：
    •    量不算特别大
    •    和 SwiftUI 页面关系很近
    •    经常增删改查（CRUD）
    •    对“对象关系”比“复杂 SQL”更敏感

SwiftData 的优势就在这里：模型类（model class）、关系（relationship）、抓取（fetch）、索引（index）和持久化都已经集成在 Apple 这套模型里了。 ￼

### 2. 跨设备同步的个人数据

如果以后你希望用户的：
    •    收藏
    •    笔记
    •    学习进度

在自己的 iPhone / iPad / Mac 间同步，SwiftData 可以通过 CloudKit 提供自动 iCloud 同步。Apple 官方文档明确写了 SwiftData 用 CloudKit 做跨设备同步，并且 ModelConfiguration.CloudKitDatabase 支持托管式 CloudKit 同步。 ￼

### 3. 和 SwiftUI 强绑定的“App 状态型数据”

比如：
    •    某词是否已收藏
    •    最近一次复习时间
    •    某词条的用户标签
    •    某学习卡片的掌握程度

这种数据如果都用裸 SQLite 去写，你会更自由，但开发心智负担也更大。SwiftData 在这里会更顺手。这个判断更多是工程经验上的推断，但它和 Apple 把 SwiftData定位为 App 内模型持久化方案是吻合的。 ￼

⸻

## 三、SwiftData 不太适合单独扛什么

### 1. 大词典主库（large dictionary corpus）

KotobaLab 以后如果想认真做，词典本体很可能是：
    •    大量词条
    •    多义项（senses）
    •    例句（examples）
    •    搭配（collocations）
    •    词频（frequency）
    •    索引字段（normalized fields）

这种数据更像“内容数据库（content database）”，而不是简单的 App 状态持久化。SwiftData 虽然能存，但当你开始追求查询可控性（query control）、导入策略（import pipeline）、**精细索引（fine-grained indexing）**时，SQLite 会更合适。SwiftData 当然也支持索引，但官方暴露出来的主要是普通索引，不是 SQLite FTS5 这种全文检索能力。 ￼

### 2. 复杂搜索（advanced search）

你这个项目的核心之一就是搜索。SQLite 官方文档明确提供 FTS5 作为全文检索扩展，而 FTS 的设计目标就是高效搜索大文本集合。对于词典、例句库、释义搜索，这类能力很关键。 ￼

如果你只是：
    •    term 精确匹配
    •    reading 精确匹配
    •    少量数据前缀过滤

SwiftData 还能应付。
但如果你要做：
    •    kanji / kana 混合查找
    •    definition 文本检索
    •    例句全文搜索
    •    排名（ranking）
    •    prefix tokenization（前缀分词式匹配）

那 SQLite 的 FTS 路线明显更自然。 ￼

⸻

## 四、SQLite 适合管什么

### 1. 词典本体（dictionary corpus）

这是最适合 SQLite 的部分：
    •    words
    •    meanings
    •    examples
    •    collocations
    •    search_index

这些数据通常是：
    •    结构化
    •    体量较大
    •    多表关联
    •    读多写少
    •    很依赖查询性能

SQLite 官方明确把它用于桌面和应用程序的本地文件数据库场景，这和词典内容库非常匹配。 ￼

### 2. 搜索索引（search index）

如果你后面做：
    •    标准化后的 normalized_term
    •    normalized_reading
    •    释义全文索引
    •    例句全文索引

SQLite 非常适合。尤其 FTS5 本来就是为“高效搜索文档集合”设计的。 ￼

### 3. 只读打包数据（bundled read-only data）

词典内容通常不是用户自己编辑的大量数据，而更像你打包进 App 的资源。SQLite 很适合把这类内容作为本地数据库文件使用。SQLite 官方也提到它常被当作应用的磁盘文件格式来使用。 ￼

⸻

## 五、SQLite 不一定最适合单独管什么

如果你把所有东西都放 SQLite，也不是不行，但会有代价：
    •    你要自己写数据访问层（data access layer）
    •    自己处理对象映射（object mapping）
    •    自己管理观察更新（observation / reactivity）
    •    自己处理和 SwiftUI 的联动

对于“收藏、笔记、学习状态”这些很贴近界面的数据，纯 SQLite 会更底层、更可控，但开发成本更高。这是工程判断，不是 SQLite 官方直接给你的建议。SQLite 官方只负责证明它是个很强的数据库，不负责替你做 SwiftUI 集成。 ￼

⸻

## 六、放到 KotobaLab 上，怎么分工最合理

我建议你这样分：

### 方案 A：最推荐

SQLite 管词典内容，SwiftData 管用户数据

也就是：

SQLite
    •    Word
    •    Meaning
    •    Example
    •    Search index

SwiftData
    •    Favorite
    •    Note
    •    ReviewState
    •    SearchHistory

这套分法最符合你项目的实际需求，因为词典主库更偏“内容检索系统（content retrieval system）”，而用户数据更偏“App 内对象状态（app object state）”。SQLite 擅长前者，SwiftData 擅长后者。 ￼

### 方案 B：前期偷跑版

先全 SwiftData

适用于：
    •    你还在搭 UI
    •    词典数据量很小
    •    搜索要求不复杂
    •    先验证产品形态

优点是开发速度快。缺点是等你后面认真做搜索时，大概率还会迁到 SQLite 或至少补一个 SQLite 搜索库。SwiftData 本身支持索引，但官方公开信息里没有把它定位成 FTS 型全文搜索方案。 ￼

### 方案 C：前期就全 SQLite

适用于：
    •    你已经确定要认真做词典
    •    想尽早把 schema（模式）、索引、查询逻辑定稳
    •    不介意前期工程量更大

这条路更“硬核”，但会让你在 SwiftUI 那边写更多桥接代码。对于你当前还在梳理 SwiftUI 架构的阶段，我觉得不一定最省力。这个是项目建议。 ￼

⸻

## 七、如果只从“使用范围”来记，可以这样背

### SwiftData 的使用范围

适合：
    •    小到中等规模本地业务数据
    •    SwiftUI 绑定很紧的数据
    •    用户个人数据
    •    跨自己设备同步的个人数据（CloudKit）
    •    快速开发、原型验证（prototyping） ￼

不那么适合：
    •    大规模全文检索
    •    复杂 SQL / 复杂手工调优
    •    词典主库这种明显搜索驱动的数据层  ￼

### SQLite 的使用范围

适合：
    •    本地结构化大数据
    •    自己控制 schema 和 query
    •    高性能搜索
    •    全文检索（FTS5）
    •    只读打包内容库
    •    复杂过滤 / 排序 / 联表（join）查询  ￼

不那么适合：
    •    想少写样板代码（boilerplate）
    •    想天然吃到 SwiftUI/CloudKit 这套生态红利
    •    想用非常“对象化”的方式直接驱动界面

⸻

## 八、我对 KotobaLab 的实际建议

如果是我来定第一版架构，我会这样：

### 第一阶段
    •    词典数据先放 SQLite
    •    用户数据先放 SwiftData
    •    UI 层统一只依赖 Repository（仓库层）

比如：

protocol DictionaryRepository {
    func searchWords(query: String) async throws -> [WordListItem]
    func fetchWordDetail(id: String) async throws -> WordDetail
}

protocol UserDataRepository {
    func fetchFavorites() async throws -> [FavoriteItem]
    func toggleFavorite(wordID: String) async throws
    func saveNote(wordID: String, content: String) async throws
}

这样你上层 SwiftUI 根本不用关心底层到底是 SwiftData 还是 SQLite。

### 第二阶段

等你要做更强的搜索，再继续加强 SQLite：
    •    加 index（索引）
    •    加 FTS5
    •    加 normalization（标准化字段）
    •    加 search ranking（搜索排序）

### 第三阶段

如果你想让用户的收藏和笔记在 Apple 设备间自动同步，再把 SwiftData 这部分接上 CloudKit。Apple 官方已经给出了这条路。 ￼

⸻

## 九、一句话结论

对 KotobaLab：

SwiftData 更适合“用户状态层”，SQLite 更适合“词典内容层和搜索层”。
如果只选一个做完整项目，我会更偏向 SQLite；
如果讲“开发效率 + Apple 生态体验”，那就把 SwiftData 用在收藏、笔记、学习进度 上。

你这个项目最稳的路线，不是站队，而是 SQLite + SwiftData 混合架构（hybrid architecture）。
