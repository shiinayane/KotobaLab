# 数据库简述

对 KotobaLab 这种词典 / 学习类 App 来说，数据库（database）的“常规做法”，其实核心就几件事：
    1.    先想清楚数据怎么分层
    2.    表（table）怎么设计
    3.    查询（query）怎么服务页面
    4.    哪些字段冗余（denormalization），哪些拆表
    5.    本地数据库和远程数据源怎么配合

我尽量用你现在这个项目能直接代入的方式讲。

⸻

## 一、先说结论：真实项目一般不会“一个大 Word 表走天下”

新手最容易想到的是：
    •    一个 Word
    •    里面塞 term、reading、meaning、examples、notes、favorite……
    •    然后全部一起存

这在 demo（演示）阶段可以，但正式一点的做法通常是：
    •    核心词条信息一张表
    •    义项（meaning / sense）一张表
    •    例句（example）一张表
    •    收藏关系（favorite）一张表
    •    用户笔记（note）一张表
    •    必要时再加标签（tag）、复习记录（review record）等

也就是说，常规数据库设计更接近：

words
meanings
examples
favorites
notes

而不是一个超级大表。

⸻

## 二、为什么不能什么都塞进一张表

因为词典类数据天然是 一对多（one-to-many） 的。

比如一个词：
    •    可能有多个义项（meanings）
    •    每个义项可能有多个例句（examples）
    •    每个用户可能还有自己的笔记（notes）
    •    还可能有多个标签（tags）

举个例子：

“かける” 这种词，如果你全塞在一行里，会变成非常怪的结构：

term=かける
reading=かける
meaning1=to hang
meaning2=to call
meaning3=to spend
example1=...
example2=...
example3=...

问题是：
    •    不好扩展
    •    不好查
    •    不好更新
    •    不好排序
    •    不好维护

所以数据库设计里，一般会把“重复出现的数据”拆出来。

这就是很典型的 规范化（normalization） 思路。

⸻

## 三、KotobaLab 这类 App 的常见分层

你可以把数据库设计理解成三层。

### 1. 原始数据层（raw data layer）

这是“词典本体”。

例如：
    •    词条
    •    读音
    •    义项
    •    例句
    •    词性
    •    频率

这部分更偏“字典内容”。

⸻

### 2. 用户行为层（user data layer）

这是“用户自己的东西”。

例如：
    •    收藏（favorites）
    •    笔记（notes）
    •    学习状态（learning status）
    •    复习记录（review history）

这部分和词典本体分开存，几乎是常规做法。

因为：
    •    词典数据是相对静态的
    •    用户数据是动态变化的

⸻

### 3. 页面查询层（view/query layer）

数据库里存的是表结构，页面真正要的是：
    •    收藏列表
    •    搜索结果列表
    •    详情页完整数据
    •    复习卡片数据

所以真实项目里通常会有：
    •    数据库存储模型（storage model）
    •    页面展示模型（view model / dto）

也就是说：

数据库怎么存 和 UI 怎么用 往往不是同一套结构。

⸻

## 四、最常见的表设计长什么样

下面我用一个比较“正规但不夸张”的版本来举例。

⸻

### 1. words 表

这是词条主表（main table）。

words
- id
- term
- reading
- normalized_term
- normalized_reading
- short_meaning
- frequency_rank
- created_at
- updated_at

这些字段的作用：
    •    id：唯一标识（identifier）
    •    term：单词本体，比如 食べる
    •    reading：读音，比如 たべる
    •    normalized_term：用于搜索的标准化字段（normalized field）
    •    normalized_reading：同理
    •    short_meaning：列表页展示的简短释义
    •    frequency_rank：词频等级
    •    created_at / updated_at：时间戳（timestamp）

为什么要有 short_meaning

因为列表页经常只需要一句话摘要。

如果每次都去 meanings 表里现拼第一义项，虽然也能做，但很多项目会直接存一个短释义，提升查询效率和开发简单度。

这是一种适度的 反规范化（denormalization）。

⸻

### 2. meanings 表

一个词通常有多个义项，所以拆表。

meanings
- id
- word_id
- sense_index
- part_of_speech
- definition
- explanation

字段说明：
    •    word_id：外键（foreign key），指向 words.id
    •    sense_index：义项顺序
    •    part_of_speech：词性（part of speech）
    •    definition：释义
    •    explanation：补充说明，可选

这张表表达的是：

一个 word 对应多个 meaning。

⸻

### 3. examples 表

例句通常也单独存。

examples
- id
- meaning_id
- example_text
- translation
- source
- example_index

为什么挂在 meaning_id 上，而不是 word_id

因为很多时候例句是对应某个具体义项，不是笼统对应整个词。

当然，如果你前期不想那么细，也可以先挂在 word_id 上，这样更简单。

常规做法里，两种都能见到：
    •    简化版：examples.word_id
    •    更细版：examples.meaning_id

⸻

### 4. favorites 表

收藏最好单独一张表，不要直接在 words 表里塞 is_favorite。

favorites
- id
- word_id
- created_at

如果是单用户本地 App，这样已经够了。

如果以后考虑多用户（multi-user），就会变成：

favorites
- id
- user_id
- word_id
- created_at

为什么不直接在 words 表里加 is_favorite

因为“是否收藏”本质上是用户行为（user behavior），不是词条本体属性。

这点很重要。

⸻

### 5. notes 表

用户笔记也建议单独存。

notes
- id
- word_id
- content
- created_at
- updated_at

以后如果你想支持：
    •    多条笔记
    •    不同笔记类型
    •    高亮片段
    •    用户标签

单独拆表会舒服很多。

⸻

## 五、页面不是直接对应表，而是对应“查询结果”

这是数据库设计里一个很重要的习惯。

很多初学者会想：

收藏页是不是就等于 favorites 表？

其实不是。

因为页面要展示的往往是拼装后的结果（assembled result）。

⸻

### 1. 收藏页要的不是 favorites 表本身

收藏页通常要显示：
    •    term
    •    reading
    •    short meaning
    •    favorite time

所以它实际查的是：
    •    favorites
    •    join words

得到一个列表项（list item）。

比如页面模型：

struct FavoriteWordItem: Identifiable, Hashable {
    let id: UUID
    let term: String
    let reading: String
    let shortMeaning: String
    let favoritedAt: Date
}

这个模型不一定在数据库里原样存在，它是查询拼出来的。

⸻

### 2. 详情页要的是聚合结果（aggregate result）

详情页需要：
    •    基本词条信息
    •    多个义项
    •    每个义项的例句
    •    收藏状态
    •    用户笔记

所以详情页常常是：
    •    查 words
    •    查 meanings
    •    查 examples
    •    查 favorites
    •    查 notes

然后在 repository（仓库层）里组装成：

struct WordDetail {
    let id: UUID
    let term: String
    let reading: String
    let meanings: [Meaning]
    let examples: [Example]
    let isFavorite: Bool
    let note: String?
}

这才是常规思路。

⸻

## 六、数据库设计里最常见的几个原则

⸻

### 原则 1：本体数据和用户数据分开

也就是：
    •    words / meanings / examples 是内容层
    •    favorites / notes / reviews 是用户层

这是非常常规的做法。

否则以后你会很难区分：
    •    “这个词天生是什么”
    •    “这个用户对它做了什么”

⸻

### 原则 2：列表页查轻，详情页查重

也就是说：
    •    列表页（list page）只查必要字段
    •    详情页（detail page）再查完整数据

这个你前面已经直觉上意识到了，非常对。

不要让列表页背着完整详情跑。

⸻

### 原则 3：关系型数据（relational data）就老老实实拆表

只要出现：
    •    一个词多个义项
    •    一个义项多个例句
    •    一个词多个标签

这基本就是典型关系型数据库（relational database）的处理场景。

⸻

### 原则 4：为查询服务，而不是只为“理论优雅”服务

纯规范化有时会把表拆得很细，但实际项目里还会适度冗余。

比如：
    •    words.short_meaning
    •    words.search_text
    •    words.sort_key

这些字段可能都带一点“为了查询方便”的性质。

这并不奇怪，反而很常见。

⸻

### 原则 5：永远用稳定的主键（primary key）

不要用：
    •    term 当主键
    •    reading 当主键

因为：
    •    同形异义词（homograph）很多
    •    同一 term 可能有不同词性和词义
    •    将来数据来源一变就麻烦

所以一般都用：
    •    UUID
    •    或自增整数（auto increment integer）

对 SwiftUI 来说，UUID 很自然。

⸻

## 七、本地 App 常见技术路线

你这个项目大概率会先做本地数据，所以常规路线一般是下面几种。

⸻

### 方案 A：先 JSON，后 SQLite / SwiftData

这是很多独立开发（indie dev）项目的常见路线。

早期
    •    用 JSON 文件存词典数据
    •    启动时加载
    •    收藏和笔记先简单存本地

中期
    •    改成 SQLite / SwiftData
    •    支持搜索、分页（pagination）、排序
    •    收藏和笔记进入正式数据库

优点：
    •    前期开发快
    •    适合先把 UI 和数据模型跑通

缺点：
    •    后面迁移会有一点工作量

⸻

### 方案 B：直接 SQLite

这其实很常规，也很适合词典类 App。

因为词典数据天然适合：
    •    结构化存储（structured storage）
    •    本地查询
    •    索引（index）
    •    模糊搜索（fuzzy search）或前缀搜索（prefix search）

SQLite 是移动端（mobile）非常经典的本地数据库方案。

⸻

### 方案 C：SwiftData / Core Data 做用户数据，词典本体单独处理

这也是常见路线。

比如：
    •    大词典内容从打包资源（bundled resource）或 SQLite 读
    •    用户收藏、笔记、学习进度用 SwiftData（or Core Data）

这种“内容数据”和“用户数据”分开的方案很常见。

特别是当词典本体是大量只读（read-only）数据时。

⸻

## 八、对 KotobaLab，我更推荐哪种常规做法

如果按你现在这个阶段，我会建议：

第一阶段：先把结构想对，不急着上最重方案

你可以先按这个心智模型设计：

词典内容
    •    words
    •    meanings
    •    examples

用户数据
    •    favorites
    •    notes

页面模型
    •    WordListItem
    •    WordDetail

就算你现在底层还没完全换成正式数据库，这个分层也值得先定下来。

⸻

第二阶段：数据访问统一走 repository

比如：

protocol WordRepositoryProtocol {
    func searchWords(query: String) async throws -> [WordListItem]
    func fetchFavoriteWords() async throws -> [WordListItem]
    func fetchWordDetail(id: UUID) async throws -> WordDetail
    func toggleFavorite(wordID: UUID) async throws
    func saveNote(wordID: UUID, content: String) async throws
}

这样以后你底层想从：
    •    mock data
    •    JSON
    •    SQLite
    •    SwiftData
    •    API

之间切换时，上层页面不至于崩掉。

这是很常规的工程做法。

⸻

## 九、常见错误也顺便说一下

⸻

### 错误 1：UI 直接操作数据库

比如 View 里直接写查询、拼接表、更新收藏。

这会让：
    •    View 变臃肿
    •    不好测试（test）
    •    不好复用

更常规的做法是：

View -> ViewModel -> Repository -> Database

⸻

### 错误 2：一个 Word 模型兼任一切

比如：
    •    搜索页用它
    •    收藏页用它
    •    详情页用它
    •    编辑页也用它

早期方便，后面很容易失控。

更常规的是按用途拆模型。

⸻

### 错误 3：把用户状态塞进词典本体

比如直接在 words 里放：
    •    isFavorite
    •    userNote
    •    lastReviewedAt

从概念上就不太干净。

最好拆开。

⸻

### 错误 4：过早追求“完美数据库”

一上来就设计十几张表、层层嵌套，也容易把自己拖死。

常规而务实的路线通常是：
    •    先抓住核心关系
    •    够用即可
    •    随功能增长再扩展

⸻

## 十、你现在最适合的一版“常规做法”

如果我替你先定一个 KotobaLab 的基础版数据库思路，我会这样：

### 表结构（storage tables）

words
- id
- term
- reading
- short_meaning
- frequency_rank

meanings
- id
- word_id
- sense_index
- part_of_speech
- definition

examples
- id
- meaning_id
- example_text
- translation
- example_index

favorites
- id
- word_id
- created_at

notes
- id
- word_id
- content
- updated_at

### 页面模型（view models / DTOs）

WordListItem
- id
- term
- reading
- shortMeaning
- isFavorite

WordDetail
- id
- term
- reading
- meanings
- examples
- isFavorite
- note

### 查询方式（queries）
    •    搜索页：查 words
    •    收藏页：查 favorites + words
    •    详情页：查 words + meanings + examples + favorites + notes

这已经是非常像真实项目的“常规做法”了。

⸻

## 十一、一句话总结

数据库（database）的常规做法，不是“把所有信息塞一个对象里”，而是：

按关系拆表（normalize），按页面组装查询结果（query result），把词典本体数据和用户行为数据分开。

对 KotobaLab 来说，最自然的做法就是：
    •    words / meanings / examples 管内容
    •    favorites / notes 管用户状态
    •    列表页查轻量数据
    •    详情页查完整数据
    •    中间统一走 repository（仓库层）

如果你愿意，下一步我可以直接帮你画出 KotobaLab 第一版 ER 图（Entity Relationship Diagram，实体关系图），然后顺手给你对应的 Swift struct 也一起定下来。
