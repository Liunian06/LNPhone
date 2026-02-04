# LNPhone 开发者文档

欢迎阅读 LNPhone 开发者文档。本文档集旨在帮助开发者快速理解项目架构、核心功能和实现细节。

---

## 📚 文档目录

### 核心架构

| 文档 | 说明 |
|------|------|
| [架构总览](./架构总览.md) | 项目整体架构、技术栈、模块关系 |
| [数据模型](./数据模型.md) | 所有数据模型详解（Chat、Contact、Emoji 等） |
| [数据库设计](./数据库设计.md) | Drift 数据库架构、表定义、迁移策略 |
| [状态管理](./状态管理.md) | Provider 架构、数据流、最佳实践 |

### 核心功能

| 文档 | 说明 |
|------|------|
| [LLM 集成](./LLM集成.md) | 多供应商 LLM 支持、上下文构建、API 调用 |
| [消息解析](./消息解析.md) | AI 响应解析器、JSON/XML 格式支持 |
| [表情包系统](./表情包系统.md) | 统一表情池、订阅模型、文件管理 |
| [后台服务](./后台服务.md) | 主动回复机制、通知服务、Android 适配 |

### API 规范

| 文档 | 说明 |
|------|------|
| [生图 API 规范](./image_generation_api_spec.md) | Volcengine、Gemini、OpenAI、Groklike API 规范 |
| [JSON 导出格式](./关于用户数据JSON格式导出的开发者文档.md) | 数据导出/导入 JSON 格式规范 |

---

## 🚀 快速开始

### 了解项目架构

1. 首先阅读 [架构总览](./架构总览.md) 了解整体设计
2. 然后阅读 [数据模型](./数据模型.md) 了解核心数据结构
3. 最后阅读 [状态管理](./状态管理.md) 了解数据流

### 理解核心功能

- **聊天功能**: [LLM 集成](./LLM集成.md) → [消息解析](./消息解析.md)
- **表情系统**: [表情包系统](./表情包系统.md)
- **后台服务**: [后台服务](./后台服务.md)
- **生图功能**: [生图 API 规范](./image_generation_api_spec.md)

---

## 📁 项目结构

```
lib/
├── main.dart                    # 应用入口
├── core/
│   ├── database/               # Drift 数据库
│   ├── models/                 # 数据模型
│   ├── providers/              # 状态管理
│   └── services/               # 业务服务
├── screens/                    # 页面
└── widgets/                    # 组件

docs/                           # 开发者文档（本目录）
assets/
├── prompts/                    # 提示词模板
└── ...
```

---

## 🔑 核心概念

### 三层架构

```
UI (Screens/Widgets)
        ↕
State (Providers)
        ↕
Data (Database/Services)
```

### 关键设计决策

| 决策 | 选择 | 原因 |
|------|------|------|
| 状态管理 | Provider | 官方推荐、简单、够用 |
| 数据库 | Drift (SQLite) | 类型安全、迁移支持 |
| LLM 响应格式 | JSON 优先 | 节省 Token、解析准确 |
| 表情存储 | 文件 + 路径引用 | 避免数据库膨胀 |
| 后台服务 | Foreground Service | 稳定、不被杀死 |

### 重要注意事项

1. **外键约束已禁用** - 避免 `insertOrReplace` 触发级联删除
2. **GIF 使用字节复制** - 保护透明通道
3. **消息 ID 使用简化格式** - 方便 AI 正确引用
4. **后台服务使用独立数据库连接** - Isolate 间不共享

---

## 🛠️ 开发指南

### 添加新的消息类型

1. 在 [`MessageType`](../lib/core/models/chat_model.dart) 枚举中添加新类型
2. 在 [`ResponseParser`](../lib/core/services/xml_parser.dart) 中添加处理逻辑
3. 在 UI 中添加对应的消息气泡组件

### 添加新的 LLM 供应商

1. 在 [`ApiProvider`](../lib/core/models/api_preset.dart) 枚举中添加
2. 在 [`LlmService`](../lib/core/services/llm_service.dart) 中添加调用方法
3. 在设置界面添加配置选项

### 添加新的数据库表

1. 在 [`tables.dart`](../lib/core/database/tables.dart) 中定义表
2. 在 [`database.dart`](../lib/core/database/database.dart) 中注册
3. 增加 `schemaVersion` 并添加迁移逻辑
4. 运行 `flutter pub run build_runner build` 生成代码

---

## 📖 相关资源

- [Flutter 官方文档](https://flutter.dev/docs)
- [Provider 包文档](https://pub.dev/packages/provider)
- [Drift 数据库文档](https://drift.simonbinder.eu/)
- [OpenAI API 文档](https://platform.openai.com/docs)
- [Gemini API 文档](https://ai.google.dev/docs)

---

*文档版本: 1.0.0 | 最后更新: 2026-02-03*