# 聊天设置功能说明

## 功能概述

实现了针对单个聊天的扩展聊天设置功能，允许用户控制是否显示AI回复中的动作（action）和想法（thought）内容。

## 主要功能

### 1. 聊天设置界面
- 位置：聊天详情页面右上角三个点按钮 → 聊天设置
- 设置项：
  - **启用扩展聊天**（滑块开关）
    - 默认：开启
    - 开启时：显示AI的对话、动作和想法
    - 关闭时：仅显示AI的对话内容，不显示动作和想法

### 2. State状态显示
- 位置：聊天界面顶部标题下方
- 功能：显示AI当前的状态信息（如"美滋滋"）
- 特性：
  - state消息不保存到聊天记录
  - 仅用于实时显示当前状态
  - 类似微信个性签名的展示效果

### 3. 消息过滤机制
- 扩展聊天**开启**时：
  - 显示所有消息类型（words、action、thought等）
  - state消息仅显示在标题下方，不在聊天记录中
  
- 扩展聊天**关闭**时：
  - 仅显示words（对话）类型消息
  - 过滤掉action（动作）和thought（想法）
  - state消息仍显示在标题下方

## 技术实现

### 1. 数据模型扩展
- `ChatSession`模型新增`enableExtendedChat`字段
- 默认值为`true`
- 支持序列化和反序列化

### 2. 状态管理
- `ChatProvider`新增`updateChatSettings`方法
- 支持更新单个聊天的扩展设置
- 自动持久化到SharedPreferences

### 3. UI组件
- 新增`ChatSettingsScreen`聊天设置页面
- `ChatDetailScreen`集成状态显示和消息过滤

### 4. 消息处理流程
```
AI回复 → 提取state消息 → 更新状态显示
       ↓
       过滤消息（根据enableExtendedChat设置）
       ↓
       保存到聊天记录（排除state消息）
       ↓
       显示在界面上
```

## 使用场景

1. **沉浸式对话模式**
   - 关闭扩展聊天，获得纯对话体验
   - 适合快速交流场景

2. **完整体验模式**
   - 开启扩展聊天，体验角色的动作和心理活动
   - 适合深度角色扮演场景

3. **状态感知**
   - 通过state标签了解角色当前状态
   - 类似社交软件的个性签名功能

## 文件修改清单

### 新增文件
- `lib/screens/chat_settings_screen.dart` - 聊天设置页面

### 修改文件
- `lib/core/models/chat_model.dart` - 添加enableExtendedChat字段
- `lib/core/providers/chat_provider.dart` - 添加updateChatSettings方法
- `lib/screens/chat_detail_screen.dart` - 集成设置按钮、状态显示和消息过滤

## 注意事项

1. **向后兼容**：旧版本的聊天数据会自动设置`enableExtendedChat`为`true`
2. **状态不持久化**：state消息仅用于显示，不保存到聊天历史
3. **独立设置**：每个聊天的扩展设置相互独立，互不影响