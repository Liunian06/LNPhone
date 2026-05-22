# LnPhone开发的Agent指南

本文档为在LnPhone代码库上工作的AI agents提供技术上下文和指南。

## 项目背景

LnPhone是一个专注于沉浸式角色扮演体验的复杂AI陪伴应用。代码库主要使用Dart/Flutter，强调提示词工程和多模态交互。

## 关键系统

### 1. LLM服务 (`lib/core/services/llm_service.dart`)

**用途**：处理所有LLM API集成和响应解析。

**关键方法**：
- `sendMessage()`：发送消息到LLM的主入口
- `_buildMessages()`：使用简化ID构建消息上下文
- `_parseResponse()`：将JSON/XML响应解析为消息对象
- `_retryApiCall()`：3次重试机制

**重要细节**：
- 支持多个提供商：OpenAI、Gemini、火山引擎、Minimax、Grok类接口
- 使用简化消息ID（0001、0002...）以便AI更好理解
- 处理多模态内容（文本+图片）
- AI请求时自动触发图片生成
- Token使用追踪用于成本分析

**修改时注意**：
- 始终保持与现有API预设的向后兼容性
- 使用多个LLM提供商测试
- 确保错误处理保留用户上下文
- 谨慎更新提示词构建逻辑（影响AI行为）

### 2. 数据库层 (`lib/core/database/`)

**技术**：Drift（类型安全的SQLite ORM）

**关键表**：
- `messages`：25+种消息类型，带JSON内容字段
- `contacts`：AI角色和用户人设
- `moments`：朋友圈动态
- `memories`：带分类的持久化角色记忆
- `api_presets`：LLM和文生图配置
- `emojis`：带含义的表情包池

**重要模式**：
- 使用Drift的类型安全查询（不用原始SQL）
- 消息内容存储为JSON以保持灵活性
- 外键强制引用完整性
- 在频繁查询的字段上建立索引

**修改时注意**：
- 结构变更后运行`dart run build_runner build`
- 为现有用户编写迁移逻辑
- 使用现有数据库文件测试
- 考虑新查询的性能影响

### 3. 提示词工程系统

**架构**：多层提示词组合

**层次**（按顺序）：
1. 现实提示词（日期/时间）
2. 角色扮演提示词（角色行为）
3. 世界书（上下文）
4. 风格预设（输出格式）
5. 角色信息（角色描述）
6. 用户信息（用户人设）
7. 角色记忆（持久化上下文）
8. 可用表情（表情包池）
9. 图片生成风格（视觉风格）
10. 角色外观（用于图片生成）

**关键角色扮演机制**：
- **碎片化表达**：强制短小、自然的消息
- **情感强度匹配**：防止情感"冷却"
- **反模板生成**：避免重复模式
- **零重复协议**：强制多样性
- **关系动态**：追踪亲密度和互动模式

**修改时注意**：
- 用真实对话广泛测试
- 小的提示词变化可能大幅影响行为
- 在控制和创造力之间平衡
- 考虑token成本（提示词可能1000+ tokens）

### 4. 后台服务 (`lib/core/services/background_service.dart`)

**用途**：使AI能够在应用后台时主动发送消息。

**关键特性**：
- 前台服务保持应用存活
- 根据用户设置调度主动回复
- 带角色头像的通知显示
- 失败API调用的重试逻辑

**平台考虑**：
- Android：需要前台服务权限
- iOS：后台执行受限
- Windows/macOS：不同的后台处理

**修改时注意**：
- 测试电池影响
- 确保通知不打扰
- 优雅处理网络故障
- 考虑用户隐私（后台活动）

### 5. 状态管理（Providers）

**模式**：使用Provider包进行响应式状态管理

**关键Providers**：
- `ChatProvider`：聊天会话和消息
- `ContactProvider`：AI角色和用户人设
- `MomentsProvider`：朋友圈状态
- `MemoryProvider`：角色记忆
- `EmojiProvider`：表情包池管理
- `ApiSettingsProvider`：LLM配置

**重要模式**：
- 状态变更后使用`notifyListeners()`
- 避免在providers中进行重计算
- 将业务逻辑委托给services
- 保持providers专注于状态，而非逻辑

**修改时注意**：
- 最小化不必要的重建
- 使用大数据集测试（100+条消息）
- 确保正确释放资源
- 考虑内存使用

## 常见修改场景

### 添加新消息类型

1. **更新枚举** 在`lib/core/database/tables.dart`中：
   ```dart
   enum MessageType {
     // ... 现有类型
     newType,
   }
   ```

2. **更新解析** 在`llm_service.dart`中：
   ```dart
   case 'new_type':
     return MessageType.newType;
   ```

3. **添加UI渲染** 在聊天widgets中：
   ```dart
   case MessageType.newType:
     return NewTypeMessageWidget(message: message);
   ```

4. **更新提示词** 如果AI需要知道这个类型：
   ```
   可用消息类型：
   - new_type: 何时使用此类型的描述
   ```

5. **运行build_runner**：`dart run build_runner build`

### 添加新LLM提供商

1. **添加枚举** 在`lib/core/models/api_preset.dart`中：
   ```dart
   enum ApiProvider {
     // ... 现有提供商
     newProvider,
   }
   ```

2. **实现API调用** 在`llm_service.dart`中：
   ```dart
   case ApiProvider.newProvider:
     return await _callNewProviderApi(messages, preset);
   ```

3. **添加配置UI** 在`chat_model_settings_screen.dart`中

4. **全面测试** 使用各种消息类型和上下文

### 修改角色扮演行为

**位置**：`assets/prompts/`中的提示词模板或`PromptSettingsProvider`

**测试方法**：
1. 创建特定场景的测试对话
2. 评估AI响应的期望行为
3. 迭代提示词措辞
4. 测试边缘情况（情感极端、长对话）

**常见调整**：
- 情感强度：调整强度匹配规则
- 消息长度：修改碎片化指南
- 创造力：在结构和自由之间平衡
- 一致性：加强记忆集成

### 使用记忆系统

**记忆类别**：
- `fact`：关于用户/世界的客观信息
- `preference`：用户喜好/厌恶
- `event`：过去的事件和经历
- `relationship`：关系动态和历史

**最佳实践**：
- 在重要对话时刻创建记忆
- 更新现有记忆而非创建重复
- 定期清理不相关记忆
- 将相关记忆注入LLM上下文（不是所有记忆）

**记忆选择逻辑**：
- 时效性：最近的记忆更相关
- 类别：匹配记忆类别到对话上下文
- 关键词：按关键词搜索记忆
- 重要性：给重要记忆更高权重

## 性能考虑

### 数据库查询
- 在频繁查询的字段上使用索引
- 限制查询结果（分页）
- 避免N+1查询（使用join）
- 缓存频繁访问的数据

### LLM API调用
- 最小化上下文长度（token成本）
- 适当时缓存响应
- 实现请求防抖
- 优雅处理速率限制

### UI渲染
- 懒加载消息历史
- 虚拟化长列表
- 优化图片加载
- 最小化重建

### 内存使用
- 正确释放providers
- 定期清理图片缓存
- 限制内存中的消息数量
- 适当使用弱引用

## 安全考虑

### API密钥
- 存储在安全存储中（绝不在代码中）
- 使用前验证
- 优雅处理过期
- 支持密钥轮换

### 用户数据
- 静态加密敏感数据
- LLM调用前清理用户输入
- 尊重用户隐私设置
- 实现数据导出/删除

### LLM交互
- 解析前验证LLM响应
- 显示前清理输出
- 处理恶意提示词（注入攻击）
- API调用速率限制

## 测试策略

### 单元测试
- Services：模拟API调用，测试业务逻辑
- Providers：测试状态变更和通知
- Models：测试序列化/反序列化
- Utils：测试辅助函数

### 集成测试
- Database：测试CRUD操作和迁移
- LLM：使用模拟响应测试（避免真实API调用）
- Background service：测试调度和通知

### 手动测试
- 角色扮演对话：测试AI行为
- 多模态消息：测试所有消息类型
- 后台回复：测试主动消息
- 边缘情况：长对话、网络故障

## 调试技巧

### LLM问题
- 检查`_buildMessages()`中的提示词构建
- 验证API响应格式
- 使用不同提供商测试
- 查看token使用和上下文长度

### 数据库问题
- 检查生成代码是否最新（`build_runner`）
- 验证外键约束
- 查看迁移逻辑
- 使用现有数据库文件测试

### UI问题
- 检查provider通知
- 验证widget重建
- 查看状态管理流程
- 使用不同屏幕尺寸测试

### 后台服务问题
- 检查平台权限
- 验证通知设置
- 查看调度逻辑
- 测试电池优化设置

## 要遵循的代码模式

### 错误处理
```dart
try {
  // 操作
} catch (e, stackTrace) {
  debugPrint('错误: $e');
  debugPrint('堆栈跟踪: $stackTrace');
  // 优雅降级
  return fallbackValue;
}
```

### Provider更新
```dart
void updateState() {
  _internalState = newValue;
  notifyListeners(); // 状态变更后始终通知
}
```

### 数据库查询
```dart
// 使用Drift的类型安全查询
final messages = await (select(messagesTable)
  ..where((t) => t.contactId.equals(contactId))
  ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
  ..limit(10))
  .get();
```

### 带重试的API调用
```dart
Future<T> _retryApiCall<T>(Future<T> Function() apiCall) async {
  for (int i = 0; i < 3; i++) {
    try {
      return await apiCall();
    } catch (e) {
      if (i == 2) rethrow;
      await Future.delayed(Duration(seconds: 2 * (i + 1)));
    }
  }
  throw Exception('不可达');
}
```

## 重要陷阱

1. **消息ID简化**：LLM看到的是简化ID（0001、0002），不是真实数据库ID。始终正确映射它们。

2. **提示词Token成本**：完整提示词可能1000+ tokens。添加提示词层时监控成本。

3. **后台服务限制**：iOS有严格的后台执行限制。Android电池优化可能杀死服务。

4. **Drift代码生成**：结构变更后始终运行`build_runner`。生成的代码必须提交。

5. **Provider释放**：必须正确释放Providers以避免内存泄漏。

6. **图片生成成本**：文生图API很贵。实现用户限制和缓存。

7. **记忆增长**：长对话创建许多记忆。实现清理逻辑。

8. **多模态上下文**：图片消耗许多tokens。限制上下文中的图片数量。

9. **平台差异**：Flutter代码运行在5+个平台上。仔细测试平台特定功能。

10. **中文语言**：UI和提示词都是中文。保持语言一致性。

## 资源

- **Drift文档**：https://drift.simonbinder.eu/
- **Provider文档**：https://pub.dev/packages/provider
- **Flutter文档**：https://flutter.dev/docs
- **OpenAI API**：https://platform.openai.com/docs
- **Gemini API**：https://ai.google.dev/docs

## 遇到疑问时

1. 阅读现有代码模式
2. 查看`docs/`目录中的文档
3. 用真实对话测试
4. 考虑用户体验影响
5. 优先考虑沉浸感和拟人化
6. 对提示词变更请求澄清
