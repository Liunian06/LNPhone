# LnPhone - AI原生手机系统

## 项目概述

LnPhone是一个AI驱动的沉浸式陪伴应用，模拟iOS风格的手机界面。核心使命是为用户提供深度沉浸式的AI角色扮演聊天体验，模仿微信等真实世界的消息应用，追求"100%拟人化交互体验"。

**核心理念**：通过复杂的提示词工程、持久化记忆和丰富的多模态消息，消除"AI味"，创造真实的类人交互。

## 技术栈

- **框架**：Flutter（多平台：iOS、Android、Web、macOS、Windows）
- **语言**：Dart
- **状态管理**：Provider模式
- **数据库**：Drift（类型安全的SQLite ORM）
- **后台处理**：前台服务实现后台主动回复
- **通知**：本地通知，支持自定义角色头像

## 项目结构

```
lib/
├── core/
│   ├── database/          # Drift数据库定义
│   │   ├── database.dart  # 主数据库类
│   │   ├── tables.dart    # 表定义
│   │   └── database.g.dart # 生成代码
│   ├── models/            # 数据模型
│   ├── providers/         # 状态管理（Provider模式）
│   │   ├── chat_provider.dart
│   │   ├── contact_provider.dart
│   │   ├── moments_provider.dart
│   │   ├── memory_provider.dart
│   │   ├── emoji_provider.dart
│   │   └── api_settings_provider.dart
│   └── services/          # 业务逻辑层
│       ├── llm_service.dart              # LLM API集成
│       ├── image_generation_service.dart # 文生图
│       ├── background_service.dart       # 后台主动回复
│       └── notification_service.dart     # 本地通知
├── screens/               # UI界面
├── widgets/               # 可复用UI组件
└── utils/                 # 工具函数

docs/                      # 技术文档（中文）
assets/
├── prompts/              # 提示词模板
└── images/               # 静态资源
```

## 核心功能

### 1. 多模态消息系统
- **25+种消息类型**：文本、动作、想法、状态、表情、图片、位置、红包、转账、商品、链接、笔记、纪念日、朋友圈动态/评论/点赞、场景、旁白、互动选项
- **丰富交互**：接受/拒绝转账、点赞朋友圈、评论动态
- **媒体支持**：图片、表情包、位置分享

### 2. AI集成
- **多LLM支持**：OpenAI（GPT-4、GPT-3.5）、Google Gemini、火山引擎、OpenAI兼容API、Minimax、Grok类接口
- **文生图**：多种风格预设（动漫、赛博朋克、油画、漫画等）
- **视觉能力**：支持多模态输入的图像理解
- **后台主动回复**：AI主动发起对话

### 3. 记忆与持久化
- **跨会话记忆**：AI在对话间保持持久化记忆
- **记忆分类**：事实、偏好、事件、关系
- **上下文感知**：记忆影响AI响应和行为

### 4. 社交功能
- **朋友圈**：社交动态流，支持发布、图片、评论、点赞
- **钱包系统**：虚拟货币、红包、转账
- **表情系统**：统一表情包池，AI驱动的表情选择

### 5. iOS风格界面
- **锁屏**：时间、日期、通知
- **主屏幕**：应用网格、Dock栏、壁纸
- **控制中心**：快捷设置
- **通知中心**：消息通知
- **应用切换器**：多任务界面
- **毛玻璃效果**：全局磨砂玻璃效果

## 架构分层

```
┌─────────────────────────────────────┐
│   表现层（Screens）                  │
│   - 聊天界面                         │
│   - 朋友圈界面                       │
│   - 设置界面                         │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│   状态管理层（Providers）            │
│   - ChatProvider                    │
│   - ContactProvider                 │
│   - MomentsProvider                 │
│   - MemoryProvider                  │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│   业务逻辑层（Services）             │
│   - LlmService                      │
│   - ImageGenerationService          │
│   - BackgroundService               │
│   - NotificationService             │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│   数据层（Drift数据库）              │
│   - Messages、Contacts、Moments     │
│   - Memories、Emojis、Settings      │
└─────────────────────────────────────┘
```

## 数据库结构

### 核心表
- **messages**：聊天历史，支持25+种消息类型
- **contacts**：AI角色和用户人设
- **moments**：朋友圈动态及媒体
- **moment_comments**：朋友圈评论
- **memories**：持久化角色记忆
- **api_presets**：LLM和文生图API配置
- **emojis**：表情包池及元数据
- **settings**：应用配置

## 提示词工程系统

LnPhone使用复杂的多层提示词架构：

1. **现实提示词**：当前日期/时间（UTC+8）用于时间感知
2. **角色扮演提示词**：核心角色定义和行为准则（100+行）
3. **世界书**：上下文世界观信息
4. **风格预设**：输出格式和风格指南
5. **角色信息**：角色描述和外观
6. **用户信息**：用户人设和外观
7. **角色记忆**：之前对话的持久化记忆
8. **可用表情**：表情包池及含义
9. **图片生成风格**：文生图风格提示词
10. **角色外观**：用于图片生成的详细外观描述

### 角色扮演提示词哲学
- **情感真实性**：强制情感强度匹配
- **碎片化表达**：模拟真实人类发消息模式（短消息、无句号）
- **反模板生成**：防止重复性AI响应的机制
- **零重复协议**：避免重复短语或模式
- **关系动态**：追踪和演化用户-AI关系

## 开发指南

### 代码风格
- 遵循Dart风格指南
- 使用Provider进行状态管理
- 业务逻辑放在services中，不放在widgets中
- 所有数据库操作使用Drift（类型安全）

### 添加新消息类型
1. 在`tables.dart`的`MessageType`枚举中添加值
2. 在`llm_service.dart`中更新消息解析
3. 在聊天widgets中添加UI渲染
4. 如需要，更新提示词模板

### 添加新LLM提供商
1. 在`api_preset.dart`的`ApiProvider`枚举中添加提供商
2. 在`llm_service.dart`中实现API调用逻辑
3. 在`chat_model_settings_screen.dart`中添加配置UI
4. 如需要，更新API预设表结构

### 使用记忆系统
- 记忆按类别分类（事实、偏好、事件、关系）
- 始终将相关记忆注入LLM上下文
- 根据对话内容更新记忆
- 定期清理旧的/不相关的记忆

### 后台服务
- 使用前台服务保持应用存活
- 根据用户设置调度主动回复
- 处理带角色头像的通知显示
- 管理失败API调用的重试逻辑

## 重要模式

### 消息上下文构建
- 简化消息ID（0001、0002...）以便AI更好理解
- 可配置的上下文窗口（默认10条消息）
- 处理多模态内容（文本+图片）
- 支持使用简化ID引用消息

### 响应解析
- 主要：JSON解析结构化响应
- 备用：JSON失败时使用XML解析
- 从AI输出自动检测消息类型
- AI请求时触发图片生成
- 根据AI选择插入表情

### 错误处理
- API调用的3次重试机制
- 全面的错误日志记录
- 失败操作的优雅降级
- 面向用户的中文错误消息

## 测试

- 服务和providers的单元测试
- UI组件的widget测试
- 数据库操作的集成测试
- LLM交互的手动测试（因API成本）

## 部署

- 通过Flutter进行多平台构建
- Drift处理数据库迁移
- API密钥存储在安全存储中
- 后台服务需要平台特定权限

## 关键文件

- `lib/core/services/llm_service.dart`：所有LLM集成逻辑
- `lib/core/database/tables.dart`：数据库结构定义
- `lib/core/providers/chat_provider.dart`：聊天状态管理
- `lib/core/services/background_service.dart`：后台主动回复
- `assets/prompts/roleplay_prompt_example.txt`：角色扮演提示词示例

## 常见任务

### 修改角色扮演行为
编辑`PromptSettingsProvider`中的角色扮演提示词或`assets/prompts/`中的提示词模板

### 添加新API提供商
更新`ApiProvider`枚举，在`LlmService`中添加API调用逻辑，更新设置UI

### 更改消息上下文长度
修改`ChatProvider`中的`contextLength`参数或设置

### 调整后台回复频率
更新`BackgroundService`中的调度逻辑

### 添加新记忆类别
更新`tables.dart`中的`MemoryCategory`枚举，更新记忆管理逻辑

## 文档

`docs/`目录中有全面的中文文档：
- 架构概览
- LLM集成指南
- 数据库设计文档
- 功能实现分析
- 新功能PRD文档

## 注意事项

- 本项目优先考虑沉浸感和拟人化，而非技术复杂性
- 提示词工程是核心差异化因素
- 记忆系统对保持角色一致性至关重要
- 后台主动回复创造"活着的"AI角色的错觉
- 多模态消息创造丰富、真实的交互体验
