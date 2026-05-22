# PRD：Conclusion 会话上下文压缩记忆与「总结库」

## 1. 背景

LnPhone 当前聊天上下文主要由三部分组成：

1. 系统提示词与角色扮演提示词
2. 角色长期记忆 `role_memories`
3. 最近 N 条聊天消息

其中最近 N 条聊天消息负责提供精确上下文，角色长期记忆负责保存稳定事实、偏好、关系、承诺等长期信息。

当前问题是：当聊天消息滑出上下文窗口后，AI 可能丢失当前会话里的连续剧情和临时状态。例如：

- 用户刚刚生气，但相关消息已经不在最近上下文里
- 当前正在进行一个未完成约定
- 角色刚刚答应稍后做某事
- 红包、转账、朋友圈互动等功能事件发生后，后续回复需要延续状态
- 当前关系氛围、角色情绪、对话主题被上下文窗口截断

这些信息不一定适合写入长期记忆，但又需要在当前会话中持续可见。因此需要增加一层会话级上下文压缩记忆：`conclusion`。

同时，为了让用户能够修正 AI 对会话状态的误判，需要提供一个独立的管理入口「总结库」，用于按对话查看、编辑、删除这些结论。

## 2. 目标

引入 `conclusion` 机制，让 AI 每轮回复时同步输出一条会话摘要，用于压缩当前会话状态，并在后续生成回复时注入最新一条摘要。

目标包括：

1. 降低上下文窗口滑动导致的短期失忆
2. 保留当前会话的剧情连续性
3. 区分会话摘要和角色长期记忆
4. 不大幅改动现有上下文构建结构
5. 控制 token 成本，每次只注入当前 chatId 最新一条有效 conclusion
6. 支持后续扩展「总结库」查看、编辑、删除、清空摘要
7. 让 conclusion 可被用户修正，避免错误摘要持续污染后续上下文
8. 支持历史会话无感兼容
9. 对单条 conclusion 做长度控制，避免模型误判导致摘要失控

## 3. 非目标

本功能第一版不处理：

1. 不替代现有 `memory` 长期记忆机制
2. 不把 conclusion 自动写入角色长期记忆
3. 不做语义检索或 RAG
4. 不做多条 conclusion 的自动合并
5. 不做历史 conclusion 的自动批量回填
6. 不在普通聊天气泡里展示 conclusion
7. 不要求缺失 conclusion 时重试整轮 AI 回复
8. 不在聊天页内提供结论编辑 UI，编辑入口放在独立的「总结库」中

## 4. 核心概念

### 4.1 Memory 长期记忆

已有机制，AI 可输出：

```json
{"type":"memory","content":"用户喜欢少糖去冰的奶茶","category":"preference"}
```

特点：

- 角色级
- 长期保存
- 跨会话可用
- 适合保存稳定事实、偏好、承诺、关系变化、重要事件
- 注入到 `[Role Memories]`

### 4.2 Conclusion 会话摘要

新增机制，AI 可输出：

```json
{
  "type": "conclusion",
  "content": "用户因为角色忘记约定有些不满；角色已经道歉并承诺晚上补偿。当前氛围正在缓和，角色状态是心虚和讨好。"
}
```

特点：

- 会话级
- 每轮仅保留最终有效的一条
- 不直接进入长期记忆
- 不在聊天 UI 显示
- 只注入当前会话最新一条未删除记录
- 用于总结当前剧情、关系氛围、未完成事项和角色状态
- 支持在「总结库」中查看、编辑、删除

### 4.3 总结库

「总结库」是一个独立的 App / 入口，用于管理结论历史。

特点：

- 按 `chatId` 独立隔离
- 用户可查看每一轮结论
- 用户可编辑任意一条结论
- 用户可软删除任意一条结论
- 删除后下一轮注入自动跳过该条，寻找当前 `chatId` 下最近的未删除结论
- 编辑不改变结论的时间顺序，排序仍以创建时间为准

## 5. 用户故事

### 5.1 防止剧情断裂

作为用户，我希望即使前面的聊天记录滑出上下文窗口，AI 仍然记得当前对话正在发生什么，这样角色不会突然忘记刚刚的剧情。

### 5.2 保留临时状态

作为用户，我希望 AI 能记住当前临时情绪和关系氛围，例如刚吵完架、正在哄人、正在暧昧、正在约定某件事，而不是只记住长期偏好。

### 5.3 不污染长期记忆

作为用户，我不希望每一轮临时对话都进入长期记忆列表，否则长期记忆会变得混乱、重复、难以管理。

### 5.4 修正错误摘要

作为用户，我希望能在「总结库」里查看每一轮结论，并对错误的结论进行编辑或删除，这样 AI 总结偏差时不会持续影响后续对话。

## 6. 输出格式设计

AI 回复仍然使用纯 JSON Array。

普通回复示例：

```json
[
  {"type":"thought","content":"糟了，他是真的有点不高兴"},
  {"type":"word","content":"我没有忘"},
  {"type":"word","content":"刚刚是真的被事情绊住了"},
  {"type":"word","content":"晚上我陪你看完"},
  {"type":"state","content":"心虚"},
  {
    "type":"conclusion",
    "content":"用户提醒角色今天约好一起看电影，并表现出不满。角色解释自己不是忘记，而是被事情耽误，并承诺晚上继续陪用户看完。当前氛围略委屈但可挽回，角色状态是心虚和安抚。"
  }
]
```

带多条 conclusion 的示例：

```json
[
  {"type":"word","content":"我先解释一下"},
  {
    "type":"conclusion",
    "content":"当前会话发生了轻微争执，关系氛围偏紧张。"
  },
  {"type":"word","content":"我不是故意的"},
  {
    "type":"conclusion",
    "content":"用户对角色临时失约表达不满，角色正在解释并尝试安抚，当前氛围仍紧张但可修复。"
  }
]
```

说明：AI 允许输出多个 `type=conclusion`，但后端只保存最后一条非空 conclusion 作为本轮正式摘要；前面的 conclusion 视为草稿或修正过程，不进入数据库。

沉默回复示例：

```json
[
  {"type":"system","content":"empty"},
  {
    "type":"conclusion",
    "content":"当前会话没有新的有效进展，维持上一轮对话状态。"
  }
]
```

说明：如果本轮没有输出 conclusion，本轮聊天仍正常完成，并沿用数据库中已有的最新有效 conclusion。

## 7. Conclusion 内容规范

每条 conclusion 应尽量包含以下信息：

1. 当前事件：这一轮对话发生了什么
2. 当前主题：双方正在讨论或推进什么
3. 关系状态：用户和角色之间当前氛围
4. 用户状态：用户显露出的情绪、需求、态度
5. 角色状态：角色当前情绪、态度、意图
6. 未完成事项：后续需要继续履行或回应的事情
7. 功能事件：红包、转账、朋友圈、图片、位置等组件产生的状态变化

不应包含：

1. 对最近消息的逐字复述
2. 大量无关闲聊细节
3. 未经用户确认的永久事实
4. 幻觉出来的人设、设定、关系
5. 应该进入长期记忆的稳定偏好替代项
6. 对用户不可见系统逻辑的描述

长度限制：

- 提示词中建议 conclusion 控制在 2000 字以内，避免模型对字数上限误判
- 业务层允许最多 5000 字
- 超过 5000 字时后端做兜底处理，优先截断并记录日志，避免异常长摘要污染后续上下文

原则上应保持信息密度高、可延续剧情，不为了凑长度重复表达。

## 8. 上下文注入设计

当前代码实际传给模型的是一个 `messages` 数组，结构如下：

```text
messages[0] = system
messages[1..N] = 最近 contextLength 条上下文消息
```

其中 `messages[0].content` 由 `LlmService._buildSystemPrompt` 构建，当前完整结构为：

```text
1. Reality Prompt
   - 当 enableRealityPrompt 开启且 realityPrompt 非空时注入
   - 注入当前 UTC+8 日期和时间

2. Roleplay Prompt
   - 角色扮演核心提示词

3. [World Info]
   - 当前聊天绑定的世界书内容

4. [Style Presets]
   - 当前聊天绑定的聊天类文本预设

5. [Character Info]
   - 角色名称、角色描述

6. [User Info]
   - 用户名称、用户信息

7. [Role Memories]
   - 角色长期记忆

8. [Conversation Conclusion]
   - 新增：当前 chatId 最新一条未删除 conclusion
   - 插入位置固定在 [Role Memories] 之后、[Available Emojis] 之前

9. [Available Emojis]
   - 当前可用表情包列表

10. [Image Generation Style]
    - 图片生成风格提示词

11. [Character Appearance]
    - 角色外观描述

12. [User Appearance]
    - 用户外观描述
```

也就是说，conclusion 的精确插入点是原结构第 7 层 `[Role Memories]` 和原结构第 8 层 `[Available Emojis]` 中间。

`messages[1..N]` 由 `LlmService._buildMessagesWithSimpleIds` 构建，来源为：

```text
chat.messages + 朋友圈虚拟消息
```

构建流程：

1. `ChatProvider` 先读取当前聊天消息 `chat.messages`
2. 再把朋友圈动态、评论、点赞转换成虚拟 `ChatMessage`
3. 合并后按 `timestamp` 升序排序
4. `LlmService` 只截取最后 `contextLength` 条
5. 每条消息分配简化 ID：`0001`、`0002`、`0003`...
6. 每条历史消息以 JSON 字符串形式传入模型

历史消息 JSON 示例：

```json
{"id":"0001","type":"word","content":"今晚还看电影吗","timestamp":"2026-05-22 21:30:00"}
```

部分消息会带额外字段：

- `ref`：引用消息的简化 ID
- `root_id`：朋友圈评论/点赞所属动态的简化 ID
- `reply_to`：朋友圈评论回复目标的简化 ID
- `message`：红包/转账留言
- `name`、`price`：商品信息
- `title`、`url`：链接或笔记信息
- `images`：图片或朋友圈图片的多模态内容

最终注入顺序为：

```text
system message:
  Reality Prompt
  Roleplay Prompt
  [World Info]
  [Style Presets]
  [Character Info]
  [User Info]
  [Role Memories]
  [Conversation Conclusion]
  [Available Emojis]
  [Image Generation Style]
  [Character Appearance]
  [User Appearance]

recent history messages:
  最近 contextLength 条聊天消息 / 朋友圈虚拟消息
```

注入格式建议：

```text
[Conversation Conclusion]
The following is the latest compressed summary of this chat session. Use it to maintain continuity for messages outside the current context window. If it conflicts with recent chat messages, prioritize recent chat messages.
- 用户提醒角色今天约好一起看电影，并表现出不满。角色解释自己不是忘记，而是被事情耽误，并承诺晚上继续陪用户看完。当前氛围略委屈但可挽回，角色状态是心虚和安抚。
```

优先级：

```text
最近聊天消息 > 最新未删除的 Conversation Conclusion > Role Memories > 默认人设
```

说明：如果当前 chatId 下最新一条 conclusion 已被删除，则自动向前查找下一条未删除记录；若没有任何有效 conclusion，则不注入该区块。

## 9. 保存与更新策略

第一版采用：

```text
每轮允许 AI 输出多个 conclusion，但只保存最后一条非空 conclusion。
```

具体规则：

1. AI 每轮回复可以输出零个或多个 `type=conclusion` 的 JSON 对象
2. 解析器识别所有 conclusion，并筛掉空字符串或仅空白字符
3. `ChatProvider` 取最后一条有效 conclusion 作为本轮正式摘要
4. 该结论交给 `ConclusionProvider` 保存到 `conversation_conclusions`
5. 每轮只新增一条记录，不覆盖历史记录
6. `sourceMessageId` 表示本轮 AI 回复批次 ID；如果当前没有稳定批次 ID，可以为空
7. 下一轮构建上下文时，只读取当前 `chatId` 下最新一条未删除的 conclusion
8. 如果本轮没有输出 conclusion，不报错、不重试，继续使用上一条有效 conclusion

优点：

- 实现简单
- 可追溯每轮摘要变化
- 不破坏现有记忆机制
- token 成本可控
- 后续可以扩展为摘要历史 UI 或周期性合并
- 支持用户在「总结库」中修正单条摘要，不影响整条链路

缺点：

- 数据量会随聊天轮次增长
- 若 AI 总结错误，最新摘要会影响下一轮
- 需要后续提供清理、编辑或重新生成能力

## 10. 兼容设计

由于 `conversation_conclusions` 是新增数据库表，历史已有聊天消息都没有对应的 conclusion。第一版必须保证老数据可以无感继续使用。

### 10.1 历史会话无 conclusion

当当前 `chatId` 查询不到任何有效 conclusion 时：

1. 不注入 `[Conversation Conclusion]` 区块
2. 仍按原有方式注入角色长期记忆和最近 N 条聊天消息
3. 不阻塞聊天生成
4. 不提示用户需要迁移
5. 等下一轮 AI 回复成功输出 conclusion 后，再开始保存并注入最新 conclusion

也就是说，历史会话会从功能上线后的第一轮有效 AI 回复开始自然生成 conclusion。

### 10.2 不做历史批量回填

第一版不对历史消息批量生成 conclusion。

原因：

1. 避免升级后产生大量模型调用成本
2. 避免批量摘要引入错误上下文
3. 避免阻塞数据库迁移和应用启动
4. 保持实现简单，降低对老数据的风险

后续如有需要，可在「总结库」中提供“根据最近消息生成当前会话摘要”的手动能力。

### 10.3 数据库迁移兼容

新增表时只执行建表迁移，不修改历史 `messages`、`chats`、`role_memories` 数据。

迁移要求：

1. 老用户升级后数据库可正常打开
2. 没有 conclusion 的聊天仍能正常发送和接收消息
3. 查询最新 conclusion 时返回 `null` 是正常状态
4. `LlmService` 仅在 conclusion 非空时注入对应区块
5. 删除聊天、清空聊天时，如果没有 conclusion 也不应报错

### 10.4 Prompt 兼容

修改提示词后，模型应尽量输出 conclusion，但解析和业务逻辑不能强依赖它。

兼容规则：

1. 有 conclusion：保存并供下一轮注入
2. 无 conclusion：本轮正常完成，下一轮沿用旧 conclusion 或不注入
3. conclusion 格式无法解析：不影响已解析的普通消息
4. 历史模型输出或旧格式输出仍按原有逻辑处理

### 10.5 与长期记忆兼容

Conclusion 不进入 `role_memories`，也不影响现有 `memory` 类型消息处理。

同一轮 AI 回复中：

```json
[
  {"type":"memory","content":"用户喜欢少糖去冰的奶茶","category":"preference"},
  {"type":"conclusion","content":"用户和角色正在讨论买奶茶，角色已经记下用户偏好，当前氛围轻松。"}
]
```

处理结果：

1. `memory` 写入角色长期记忆
2. `conclusion` 写入会话摘要表
3. 两者互不覆盖、互不替代

## 11. 数据模型设计

建议新增 Drift 表：`conversation_conclusions`。

字段：

```text
id                 String    主键
chatId             String    所属聊天会话 ID
roleId             String    所属角色 ID
content            String    摘要内容
createdAt          int       创建时间
updatedAt          int       更新时间
deletedAt          int?      软删除时间，删除后不再参与上下文注入
sourceMessageId    String?   本轮 AI 回复批次 ID，第一版可为空
startMessageId     String?   摘要覆盖范围开始消息 ID，第一版可为空
endMessageId       String?   摘要覆盖范围结束消息 ID，第一版可为空
tokenEstimate      int?      token 估算，第一版可为空
```

第一版必须字段：

```text
id
chatId
roleId
content
createdAt
updatedAt
```

推荐保留字段：

- `deletedAt`：支持「总结库」中的删除操作
- `sourceMessageId`：用于追踪本轮 AI 回复批次

排序与查询约定：

- 列表顺序按 `createdAt desc`
- 编辑只更新 `content` 和 `updatedAt`
- 删除只写入 `deletedAt`
- 注入时只查找 `deletedAt == null` 的最新一条

## 12. ConclusionProvider 设计

新增 `ConclusionProvider`，职责：

1. 加载指定聊天的结论列表
2. 获取当前聊天最新的有效结论
3. 新增结论
4. 编辑结论
5. 删除指定结论（软删除）
6. 清空指定聊天的结论
7. 后续支持恢复删除和历史查看

核心接口建议：

```dart
Future<List<ConversationConclusion>> getConclusionsByChatId(String chatId);

Future<ConversationConclusion?> getLatestActiveConclusion(String chatId);

Future<void> addConclusion({
  required String chatId,
  required String roleId,
  required String content,
  String? sourceMessageId,
  String? startMessageId,
  String? endMessageId,
});

Future<void> updateConclusion({
  required String id,
  required String content,
});

Future<void> deleteConclusion(String id);

Future<void> deleteConclusionsByChatId(String chatId);
```

第一版注入路径只需要 `getLatestActiveConclusion(chatId)`，而「总结库」App 需要 `getConclusionsByChatId(chatId)` 支持列表展示。

## 13. 解析逻辑设计

新增消息类型：

```dart
enum MessageType {
  ...
  conclusion,
}
```

JSON 解析新增：

```dart
case 'conclusion':
  type = MessageType.conclusion;
  break;
```

XML 兼容不是第一版重点，但可选支持：

```xml
<conclusion>当前会话摘要</conclusion>
```

聊天过滤逻辑：

1. `conclusion` 不进入聊天 UI
2. `conclusion` 不进入普通消息列表显示
3. `conclusion` 不作为最新聊天气泡摘要
4. `conclusion` 不进入长期记忆列表
5. `conclusion` 被单独提取并保存到 `conversation_conclusions`
6. `总结库` 读取的是该独立表，而不是普通消息表

## 14. ChatProvider 流程

生成回复流程新增步骤：

1. 调用 LLM 生成回复
2. `ResponseParser` 解析 JSON Array
3. 从解析结果中提取所有 `MessageType.conclusion`
4. 从结论列表里取最后一条有效 conclusion
5. 从可展示消息中排除 conclusion
6. 正常保存和展示其他消息
7. 调用 `ConclusionProvider.addConclusion()` 保存本轮最终 conclusion

伪流程：

```dart
final conclusionMessages = aiMessages
    .where((msg) => msg.type == MessageType.conclusion)
    .where((msg) => msg.content.trim().isNotEmpty)
    .toList();

final finalConclusion = conclusionMessages.isEmpty
    ? null
    : conclusionMessages.last;

for (final conclusion in conclusionMessages) {
  // 这里不展示，只用于筛选和调试
}

if (finalConclusion != null) {
  await conclusionProvider.addConclusion(
    chatId: chatId,
    roleId: role.id,
    content: finalConclusion.content,
    sourceMessageId: aiBatchId,
  );
}
```

说明：

- 同一轮输出多个 conclusion 时，只保留最后一条
- 结论不进入普通聊天消息列表
- 结论保存后，下一轮由 `ConclusionProvider` 提供最新有效记录

## 15. LlmService 流程

`LlmService.generateResponse` 新增参数：

```dart
String? conversationConclusion
```

`_buildSystemPrompt` 在 `[Role Memories]` 后、聊天消息前插入：

```dart
if (conversationConclusion != null && conversationConclusion.isNotEmpty) {
  buffer.writeln('\n[Conversation Conclusion]');
  buffer.writeln(
    'The following is the latest compressed summary of this chat session. Use it to maintain continuity for messages outside the current context window. If it conflicts with recent chat messages, prioritize recent chat messages.'
  );
  buffer.writeln('- $conversationConclusion');
}
```

注入规则：

1. 只注入当前 chatId 最新一条未删除 conclusion
2. 如果该条 conclusion 已被软删除，则向前查找上一条未删除记录
3. 如果没有任何有效 conclusion，则不注入该区块

## 16. Prompt 修改建议

在 `roleplay_prompt.txt` 输出格式中增加：

```json
{"type":"conclusion", "content":"当前会话状态摘要"}
```

新增规则：

```text
每次回复应额外输出一条 conclusion 类型消息，用于总结当前会话状态。
如果本轮需要修正前面的摘要，可以输出多个 conclusion，但最终一条会被保存为本轮正式摘要。

conclusion 要求：
1. 使用客观第三方摘要口吻，不要写成角色对用户说的话
2. 包含当前事件、关系状态、角色状态、用户状态、未完成事项
3. 不逐字复述聊天内容
4. 不写入未经确认的永久事实
5. 不替代 memory；稳定偏好、承诺、重要关系变化仍应使用 memory
6. 建议控制在 2000 字以内，避免模型对字数误判
```

## 17. UI 设计

第一版新增独立 App / 入口「总结库」，不在聊天页内展示 conclusion。

### 17.1 入口

- 主屏或应用列表新增「总结库」图标
- 进入后可选择角色或聊天会话

### 17.2 列表页

- 按 `chatId` 展示会话
- 进入某个会话后，按时间倒序展示每一轮 conclusion
- 显示摘要内容预览、创建时间、编辑状态、删除状态

### 17.3 详情页

- 查看某条 conclusion 的完整内容
- 查看所属 chatId、roleId、创建时间、更新时间、来源批次 ID
- 允许进入编辑模式

### 17.4 编辑能力

- 支持修改单条 conclusion 内容
- 编辑不改变该条 conclusion 的排序位置
- 编辑只更新 `content` 与 `updatedAt`

### 17.5 删除能力

- 支持软删除单条 conclusion
- 删除后该条记录在总结库中可标记为“已删除”或隐藏
- 删除后下一次聊天注入时自动跳过该条，寻找当前 chatId 最近的未删除 conclusion

### 17.6 后续可选能力

- 恢复已删除 conclusion
- 批量清理旧 conclusion
- 根据最近消息重新生成 conclusion
- 查看 conclusion 历史对比

## 18. 错误处理

### 18.1 AI 未输出 conclusion

处理：

- 不报错
- 不重试
- 不影响普通回复
- 下一轮继续使用已有最新有效 conclusion

### 18.2 conclusion 为空

处理：

- 空字符串不保存
- 仅空白字符不保存

### 18.3 conclusion 较长

处理：

- 提示词要求控制在 2000 字以内
- 业务层最多保存 5000 字
- 超过 5000 字时后端兜底截断并记录日志

### 18.4 JSON 格式错误

处理：

- 沿用现有 JSON 解析和重试机制
- 不为 conclusion 单独引入新的失败路径

### 18.5 已删除结论参与注入

处理：

- 注入查询只取 `deletedAt == null` 的最新记录
- 如果最新一条被删除，则自动回退到上一条未删除记录
- 如果没有任何未删除记录，则不注入 conclusion 区块

## 19. 数据清理策略

第一版每轮新增，数据量会随聊天轮次增长。

建议清理策略：

1. 每个 chatId 可设置保留最近 200 条有效 conclusion
2. 删除聊天会话时同步清理该 chatId 下所有 conclusion
3. 用户在「总结库」中删除单条 conclusion 时采用软删除，注入时自动跳过
4. 后续可将旧 conclusion 合并成阶段性摘要

第一版最低要求：删除聊天时应清理对应 conclusion，避免孤儿数据。

## 20. 验收标准

1. AI 输出 `type=conclusion` 后，不会在聊天界面显示
2. conclusion 会保存到 `conversation_conclusions`
3. 每轮只保存最后一条有效 conclusion
4. 「总结库」中可以按 chatId 查看每一轮 conclusion
5. 可以编辑、软删除单条 conclusion
6. 删除后下一轮注入会自动跳过该条，使用当前 chatId 最近的未删除 conclusion
7. conclusion 注入位置在角色记忆之后、聊天消息之前
8. AI 未输出 conclusion 时，普通聊天不受影响
9. conclusion 不出现在长期记忆列表中
10. `memory` 和 `conclusion` 可以在同一轮回复中同时输出
11. 最近聊天消息与 conclusion 冲突时，AI 应优先遵循最近聊天消息
12. 缩小上下文窗口后，AI 仍能通过最新 conclusion 延续当前剧情

## 21. 实施优先级

### P0

1. 新增 `MessageType.conclusion`
2. 新增数据库表 `conversation_conclusions`
3. 新增数据库 CRUD
4. 新增 `ConclusionProvider`
5. `ResponseParser` 支持 JSON `type=conclusion`
6. `ChatProvider` 提取并保存最后一条 conclusion
7. `LlmService` 支持注入最新有效 conclusion
8. 修改 `roleplay_prompt.txt` 输出规范

### P1

1. 新增「总结库」App 基础浏览能力
2. 支持查看、编辑、软删除单条 conclusion
3. 删除聊天时清理 conclusion
4. 兼容历史无 conclusion 的聊天
5. Debug 日志
6. 单元测试或手动测试用例

### P2

1. 历史 conclusion 查看
2. 恢复删除
3. 周期性合并旧 conclusion
4. 基于最近消息重新生成 conclusion

## 22. 总体结论

Conclusion 机制适合作为 LnPhone 的会话级上下文压缩层。

配套的「总结库」App 则提供了可见、可编辑、可删除的管理能力，让结论既能持续服务于上下文，又不会因为 AI 一次误判而长期污染后续对话。

最终上下文分层为：

```text
最近聊天消息：精确上下文
Conclusion：当前会话压缩上下文
Memory：角色级长期记忆
```

第一版采用“每轮仅保存最后一条有效 conclusion、只注入当前 chatId 最新未删除 conclusion”的策略，能在不大幅改动现有架构的前提下，明显改善上下文窗口滑动造成的失忆问题，并避免污染长期记忆系统。
