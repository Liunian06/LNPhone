
# 数据导出格式说明 (JSON)

本文档详细说明了 LNPhone 应用的数据导出格式。导出的 JSON 文件包含了用户的聊天记录、联系人、朋友圈、记忆、钱包、表情包及设置等所有关键数据。

## 1. 根结构

导出的 JSON 文件包含以下顶级字段：

```json
{
  "_metadata": { ... },
  "contacts": { ... },
  "chats": { ... },
  "moments": { ... },
  "memories": { ... },
  "wallet": { ... },
  "emojis": { ... },
  "presets": { ... },
  "settings": { ... }
}
```

## 2. 元数据 (_metadata)

包含导出的基本信息，用于版本控制和校验。

| 字段 | 类型 | 说明 |
|------|------|------|
| exportVersion | String | 导出格式版本号 |
| exportTimestamp | String | 导出时间 (ISO 8601) |
| exportTimestampMs | Number | 导出时间戳 (毫秒) |
| schemaVersion | Number | 数据库架构版本 |
| platform | String | 导出平台 |
| includeImageData | Boolean | 是否包含图片二进制数据 |

**示例：**
```json
{
  "_metadata": {
    "exportVersion": "2.0.0",
    "exportTimestamp": "2026-02-03T10:30:00.000Z",
    "exportTimestampMs": 1769938200000,
    "schemaVersion": 15,
    "platform": "android",
    "includeImageData": true
  }
}
```

## 3. 联系人 (contacts)

包含两个列表：`roles` (联系人角色) 和 `meList` (用户人设)。

### 3.1 角色 (roles)

| 字段 | 类型 | 说明 |
|------|------|------|
| id | String | 唯一ID |
| name | String | 角色名称 |
| avatarPath | String | 头像本地路径 |
| avatarData | String | 头像二进制数据 (Base64 编码) |
| description | String | 角色描述/设定 |
| appearance | String | 外貌描述 |
| referenceImages | List\<String\> | 参考图路径列表 |
| referenceImagesData | List\<String\> | 参考图二进制数据 (Base64 列表) |
| subscribedGroupIds | List\<String\> | 订阅的表情包分组ID |
| subscribedEmojiIds | List\<String\> | 订阅的个体表情ID |

**示例：**
```json
{
  "contacts": {
    "roles": [
      {
        "id": "role_abc123",
        "name": "小雪",
        "avatarPath": "/data/user/0/com.example.lnphone2/files/avatars/role_abc123.jpg",
        "avatarData": "/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAA...",
        "description": "一个活泼开朗的女孩，喜欢音乐和绘画。性格温和但有时候会有点小任性。",
        "appearance": "长发及腰，棕色眼睛，身高165cm，喜欢穿连衣裙",
        "referenceImages": [
          "/data/user/0/com.example.lnphone2/files/refs/ref1.jpg"
        ],
        "referenceImagesData": [
          "/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAA..."
        ],
        "subscribedGroupIds": ["group_001", "group_002"],
        "subscribedEmojiIds": ["emoji_a1", "emoji_a2"]
      }
    ],
    "meList": [
      {
        "id": "me_default",
        "name": "我",
        "avatarPath": "/data/user/0/com.example.lnphone2/files/avatars/me_default.jpg",
        "avatarData": "/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAA...",
        "info": "一个普通的上班族，喜欢在闲暇时间看书和玩游戏。",
        "appearance": "短发，戴眼镜，身高175cm",
        "referenceImages": [],
        "referenceImagesData": null
      }
    ]
  }
}
```

### 3.2 用户人设 (meList)

| 字段 | 类型 | 说明 |
|------|------|------|
| id | String | 唯一ID |
| name | String | 用户名称 |
| avatarPath | String | 头像本地路径 |
| avatarData | String | 头像二进制数据 (Base64 编码) |
| info | String | 用户信息/设定 |
| appearance | String | 外貌描述 |
| referenceImages | List\<String\> | 参考图路径列表 |
| referenceImagesData | List\<String\> | 参考图二进制数据 (Base64 列表) |

## 4. 聊天数据 (chats)

包含 `sessions` (会话列表)、`worldInfos` (世界书) 和 `textPresets` (文本预设)。

### 4.1 会话 (sessions)

| 字段 | 类型 | 说明 |
|------|------|------|
| id | String | 会话ID |
| roleId | String | 关联的角色ID |
| meId | String | 关联的用户人设ID |
| lastUpdated | Number | 最后更新时间戳 (毫秒) |
| enableExtendedChat | Boolean | 是否启用扩展聊天 (动作/心理描写) |
| enableTextToImage | Boolean | 是否启用文生图 |
| enableEmoji | Boolean | 是否启用表情包 |
| enableIndependentSendButton | Boolean | 是否启用独立发送/续写按钮 |
| currentState | String | 当前状态描述 |
| isPinned | Boolean | 是否置顶 |
| worldInfoIds | List\<String\> | 关联的世界书 ID 列表 |
| textPresetIds | List\<String\> | 关联的预设 ID 列表 |
| backgroundImage | String | 背景图本地路径 |
| backgroundImageData | String | 背景图二进制数据 (Base64 编码) |
| messages | List\<Message\> | 消息列表 |
| _messageCount | Number | 消息总数 (统计字段) |

**注意**：`apiPresetId` 和 `imageApiPresetId` 字段不再导出，因为它们关联到包含敏感信息的 API 设置。

**示例：**
```json
{
  "chats": {
    "sessions": [
      {
        "id": "session_xyz789",
        "roleId": "role_abc123",
        "meId": "me_default",
        "lastUpdated": 1769938200000,
        "enableExtendedChat": true,
        "enableTextToImage": false,
        "enableEmoji": true,
        "enableIndependentSendButton": false,
        "currentState": "正在咖啡厅里看书",
        "isPinned": true,
        "worldInfoIds": ["world_001"],
        "textPresetIds": ["preset_chat_01"],
        "backgroundImage": "/data/user/0/com.example.lnphone2/files/bg/cafe.jpg",
        "backgroundImageData": "/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAA...",
        "messages": [
          {
            "id": "msg_001",
            "isMe": true,
            "sender": "我",
            "type": 0,
            "typeName": "words",
            "content": "你好呀！",
            "messageData": null,
            "timestamp": 1769938100000,
            "timestampFormatted": "2026-02-03T10:28:20.000Z",
            "metadata": null,
            "isRead": true
          },
          {
            "id": "msg_002",
            "isMe": false,
            "sender": "小雪",
            "type": 0,
            "typeName": "words",
            "content": "嗨！今天天气真好呢~",
            "messageData": null,
            "timestamp": 1769938150000,
            "timestampFormatted": "2026-02-03T10:29:10.000Z",
            "metadata": null,
            "isRead": true
          },
          {
            "id": "msg_003",
            "isMe": false,
            "sender": "小雪",
            "type": 5,
            "typeName": "image",
            "content": "/data/user/0/com.example.lnphone2/files/images/img_003.jpg",
            "messageData": "/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAA...",
            "timestamp": 1769938160000,
            "timestampFormatted": "2026-02-03T10:29:20.000Z",
            "metadata": {
              "width": 512,
              "height": 768,
              "prompt": "a sunny day in the park"
            },
            "isRead": true
          }
        ],
        "_messageCount": 3
      }
    ],
    "worldInfos": [...],
    "textPresets": [...]
  }
}
```

### 4.2 消息 (messages)

| 字段 | 类型 | 说明 |
|------|------|------|
| id | String | 消息ID |
| isMe | Boolean | 是否为用户发送 (true=用户, false=角色) |
| sender | String | 发送者名称 |
| type | Number | 消息类型枚举值 |
| typeName | String | 消息类型名称 |
| content | String | 消息内容 (文本或图片路径) |
| messageData | String | 消息二进制数据 (Base64 编码，如图片) |
| timestamp | Number | 时间戳 (毫秒) |
| timestampFormatted | String | 格式化时间 (ISO 8601) |
| metadata | Object | 额外元数据 (引用、生图参数等) |
| isRead | Boolean | 是否已读 |

#### 消息类型 (MessageType)

| 枚举值 | 名称 | 说明 |
|--------|------|------|
| 0 | words | 文字消息 |
| 1 | action | 动作描述 |
| 2 | thought | 内心想法 |
| 3 | state | 当前状态 |
| 4 | emoji | 表情包 |
| 5 | image | 图片 |
| 6 | location | 位置分享 |
| 7 | redpacket | 红包 |
| 8 | transfer | 转账 |
| 9 | acceptRedpacket | 接受红包 |
| 10 | rejectRedpacket | 拒绝红包 |
| 11 | acceptTransfer | 接受转账 |
| 12 | rejectTransfer | 拒绝转账 |
| 13 | product | 商品推荐 |
| 14 | link | 链接分享 |
| 15 | note | 备忘提醒 |
| 16 | anniversary | 纪念日卡片 |
| 17 | memory | 记忆 |
| 18 | diary | 日记 |
| 19 | moment | 朋友圈 |
| 20 | momentComment | 朋友圈评论 |
| 21 | momentLike | 朋友圈点赞 |
| 22 | scene | 场景描述 |
| 23 | narration | 旁白 |
| 24 | options | 互动选项 |

## 5. 朋友圈 (moments)

包含 `posts` (动态列表) 和 `currentUser` (当前用户设置)。

### 5.1 动态 (posts)

| 字段 | 类型 | 说明 |
|------|------|------|
| id | String | 动态ID |
| user | Object | 发布者信息 |
| content | String | 文本内容 |
| mediaItems | List\<Object\> | 媒体文件列表 |
| mediaData | List\<String\> | 媒体文件二进制数据 (Base64 列表) |
| likes | List\<Object\> | 点赞列表 |
| comments | List\<Object\> | 评论列表 |
| location | String | 位置信息 |
| createdAt | String | 发布时间 (ISO 8601) |
| createdAtMs | Number | 发布时间戳 (毫秒) |
| _likeCount | Number | 有效点赞数 (统计字段) |
| _commentCount | Number | 评论数 (统计字段) |

**示例：**
```json
{
  "moments": {
    "posts": [
      {
        "id": "post_001",
        "user": {
          "id": "role_abc123",
          "name": "小雪",
          "avatarUrl": "/data/user/0/com.example.lnphone2/files/avatars/role_abc123.jpg",
          "avatarData": "/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAA...",
          "coverImageUrl": null,
          "coverImageData": null,
          "signature": "每天都要开心哦~"
        },
        "content": "今天的晚霞好美啊！🌅",
        "mediaItems": [
          {
            "url": "/data/user/0/com.example.lnphone2/files/moments/sunset.jpg",
            "type": "image",
            "thumbnailUrl": null
          }
        ],
        "mediaData": [
          "/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAA..."
        ],
        "likes": [
          {
            "user": {
              "id": "me_default",
              "name": "我",
              "avatarUrl": "/data/user/0/com.example.lnphone2/files/avatars/me_default.jpg",
              "avatarData": "/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAA...",
              "coverImageUrl": null,
              "coverImageData": null,
              "signature": null
            },
            "createdAt": "2026-02-03T11:00:00.000Z",
            "isCancelled": false
          }
        ],
        "comments": [
          {
            "id": "comment_001",
            "user": {
              "id": "me_default",
              "name": "我",
              "avatarUrl": "/data/user/0/com.example.lnphone2/files/avatars/me_default.jpg",
              "avatarData": "/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAA...",
              "coverImageUrl": null,
              "coverImageData": null,
              "signature": null
            },
            "content": "真的好美！",
            "createdAt": "2026-02-03T11:05:00.000Z",
            "replyTo": null
          }
        ],
        "location": "东京塔",
        "createdAt": "2026-02-03T10:50:00.000Z",
        "createdAtMs": 1769939400000,
        "_likeCount": 1,
        "_commentCount": 1
      }
    ],
    "currentUser": {
      "name": "我",
      "avatarUrl": "/data/user/0/com.example.lnphone2/files/avatars/me_default.jpg",
      "avatarData": "/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAA...",
      "coverImageUrl": "/data/user/0/com.example.lnphone2/files/moments/cover.jpg",
      "coverImageData": "/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAA...",
      "signature": "热爱生活"
    },
    "_postCount": 1
  }
}
```

### 5.2 用户设置 (currentUser)

| 字段 | 类型 | 说明 |
|------|------|------|
| name | String | 用户名称 |
| avatarUrl | String | 头像路径 |
| avatarData | String | 头像二进制数据 (Base64 编码) |
| coverImageUrl | String | 封面图路径 |
| coverImageData | String | 封面图二进制数据 (Base64 编码) |
| signature | String | 个人签名 |

### 5.3 朋友圈用户 (MomentsUser)

| 字段 | 类型 | 说明 |
|------|------|------|
| id | String | 用户ID |
| name | String | 用户名称 |
| avatarUrl | String | 头像路径 |
| avatarData | String | 头像二进制数据 (Base64 编码) |
| coverImageUrl | String | 封面图路径 |
| coverImageData | String | 封面图二进制数据 (Base64 编码) |
| signature | String | 个人签名 |

### 5.4 媒体项 (MediaItem)

| 字段 | 类型 | 说明 |
|------|------|------|
| url | String | 媒体文件路径 |
| type | String | 类型 ("image" 或 "video") |
| thumbnailUrl | String | 视频缩略图路径 (可选) |

### 5.5 点赞 (MomentLike)

| 字段 | 类型 | 说明 |
|------|------|------|
| user | MomentsUser | 点赞用户信息 |
| createdAt | String | 点赞时间 (ISO 8601) |
| isCancelled | Boolean | 是否已取消点赞 |

### 5.6 评论 (MomentsComment)

| 字段 | 类型 | 说明 |
|------|------|------|
| id | String | 评论ID |
| user | MomentsUser | 评论用户信息 |
| content | String | 评论内容 |
| createdAt | String | 评论时间 (ISO 8601) |
| replyTo | MomentsUser | 回复给谁 (可选) |

## 6. 记忆 (memories)

包含角色的长期记忆。

| 字段 | 类型 | 说明 |
|------|------|------|
| id | String | 记忆ID |
| roleId | String | 关联角色ID |
| content | String | 记忆内容 |
| createdAt | Number | 创建时间戳 (毫秒) |
| createdAtFormatted | String | 创建时间 (ISO 8601) |
| updatedAt | Number | 更新时间戳 (毫秒) |
| updatedAtFormatted | String | 更新时间 (ISO 8601) |
| sourceSessionId | String | 来源会话ID (可选) |
| category | Number | 分类枚举值 |
| categoryName | String | 分类名称 |
| categoryDisplayName | String | 分类显示名称 |

**示例：**
```json
{
  "memories": {
    "items": [
      {
        "id": "mem_001",
        "roleId": "role_abc123",
        "content": "用户喜欢喝咖啡，尤其是拿铁",
        "createdAt": 1769852400000,
        "createdAtFormatted": "2026-02-02T10:30:00.000Z",
        "updatedAt": 1769852400000,
        "updatedAtFormatted": "2026-02-02T10:30:00.000Z",
        "sourceSessionId": "session_xyz789",
        "category": 0,
        "categoryName": "general",
        "categoryDisplayName": "一般记忆"
      },
      {
        "id": "mem_002",
        "roleId": "role_abc123",
        "content": "用户的生日是3月15日",
        "createdAt": 1769766000000,
        "createdAtFormatted": "2026-02-01T10:30:00.000Z",
        "updatedAt": 1769766000000,
        "updatedAtFormatted": "2026-02-01T10:30:00.000Z",
        "sourceSessionId": null,
        "category": 1,
        "categoryName": "important",
        "categoryDisplayName": "重要记忆"
      }
    ],
    "_totalCount": 2
  }
}
```

#### 记忆分类 (MemoryCategory)

| 枚举值 | 名称 | 显示名称 |
|--------|------|----------|
| 0 | general | 一般记忆 |
| 1 | important | 重要记忆 |

## 7. 钱包 (wallet)

包含 `balance` (当前余额) 和 `transactions` (交易记录)。

| 字段 | 类型 | 说明 |
|------|------|------|
| balance | Number | 当前余额 |
| transactions | List\<Object\> | 交易记录列表 |
| _transactionCount | Number | 交易总数 (统计字段) |

**示例：**
```json
{
  "wallet": {
    "balance": 1888.88,
    "transactions": [
      {
        "id": "tx_001",
        "type": 0,
        "typeName": "transfer",
        "typeDisplayName": "转账",
        "direction": 0,
        "directionName": "income",
        "amount": 100.00,
        "amountDisplayText": "+100.00",
        "description": "收到转账",
        "relatedContactName": "小雪",
        "relatedSessionId": "session_xyz789",
        "relatedMessageId": "msg_100",
        "timestamp": 1769938200000,
        "timestampFormatted": "2026-02-03T10:30:00.000Z"
      },
      {
        "id": "tx_002",
        "type": 1,
        "typeName": "redpacket",
        "typeDisplayName": "红包",
        "direction": 1,
        "directionName": "expense",
        "amount": 8.88,
        "amountDisplayText": "-8.88",
        "description": "发红包",
        "relatedContactName": "小雪",
        "relatedSessionId": "session_xyz789",
        "relatedMessageId": "msg_101",
        "timestamp": 1769938300000,
        "timestampFormatted": "2026-02-03T10:31:40.000Z"
      }
    ],
    "_transactionCount": 2
  }
}
```

### 7.1 交易记录 (transactions)

| 字段 | 类型 | 说明 |
|------|------|------|
| id | String | 交易ID |
| type | Number | 交易类型枚举值 |
| typeName | String | 交易类型名称 |
| typeDisplayName | String | 交易类型显示名称 |
| direction | Number | 方向枚举值 (0=收入, 1=支出) |
| directionName | String | 方向名称 (income/expense) |
| amount | Number | 金额 |
| amountDisplayText | String | 金额显示文本 |
| description | String | 描述 |
| relatedContactName | String | 相关联系人名称 |
| relatedSessionId | String | 相关会话ID |
| relatedMessageId | String | 相关消息ID |
| timestamp | Number | 时间戳 (毫秒) |
| timestampFormatted | String | 格式化时间 (ISO 8601) |

## 8. 表情包 (emojis)

包含 `emojis` (表情列表) 和 `groups` (分组列表)。

**示例：**
```json
{
  "emojis": {
    "emojis": [
      {
        "id": "emoji_001",
        "meaning": "开心",
        "rawContent": "笑得很开心，眼睛弯成月牙形",
        "groupId": "group_happy",
        "localPath": "/data/user/0/com.example.lnphone2/files/emojis/happy.gif",
        "backupPath": "/data/user/0/com.example.lnphone2/files/emoji_backup/emoji_001.gif",
        "emojiData": "R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAA...",
        "type": 0,
        "typeName": "global",
        "roleId": null,
        "createdAt": 1769679600000,
        "createdAtFormatted": "2026-02-01T10:30:00.000Z"
      },
      {
        "id": "emoji_002",
        "meaning": "比心",
        "rawContent": "双手比心，表达爱意",
        "groupId": "group_love",
        "localPath": "/data/user/0/com.example.lnphone2/files/emojis/love.png",
        "backupPath": null,
        "emojiData": "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJA...",
        "type": 1,
        "typeName": "role",
        "roleId": "role_abc123",
        "createdAt": 1769766000000,
        "createdAtFormatted": "2026-02-02T10:30:00.000Z"
      }
    ],
    "groups": [
      {
        "id": "group_happy",
        "name": "开心表情",
        "type": 0,
        "typeName": "global",
        "roleId": null,
        "isVisible": true,
        "createdAt": 1769593200000,
        "createdAtFormatted": "2026-01-31T10:30:00.000Z"
      },
      {
        "id": "group_love",
        "name": "小雪专属",
        "type": 1,
        "typeName": "role",
        "roleId": "role_abc123",
        "isVisible": true,
        "createdAt": 1769679600000,
        "createdAtFormatted": "2026-02-01T10:30:00.000Z"
      }
    ],
    "_emojiCount": 2,
    "_groupCount": 2
  }
}
```

### 8.1 表情 (emojis)

| 字段 | 类型 | 说明 |
|------|------|------|
| id | String | 表情ID |
| meaning | String | 含义/关键词 (用于引导大模型) |
| rawContent | String | 详细描述 (用于区分相似表情) |
| groupId | String | 分组ID |
| localPath | String | 本地文件路径 |
| backupPath | String | 备份文件路径 |
| emojiData | String | 表情图片二进制数据 (Base64 编码) |
| type | Number | 类型枚举值 (0=global, 1=role) |
| typeName | String | 类型名称 |
| roleId | String | 角色ID (仅角色表情) |
| createdAt | Number | 创建时间戳 (毫秒) |
| createdAtFormatted | String | 创建时间 (ISO 8601) |

### 8.2 表情包分组 (groups)

| 字段 | 类型 | 说明 |
|------|------|------|
| id | String | 分组ID |
| name | String | 分组名称 |
| type | Number | 类型枚举值 (0=global, 1=role) |
| typeName | String | 类型名称 |
| roleId | String | 角色ID (仅角色分组) |
| isVisible | Boolean | 是否可见 |
| createdAt | Number | 创建时间戳 (毫秒) |
| createdAtFormatted | String | 创建时间 (ISO 8601) |

#### 表情类型 (EmojiType)

| 枚举值 | 名称 | 说明 |
|--------|------|------|
| 0 | global | 全局表情 (所有角色可用) |
| 1 | role | 角色专属表情 |

## 9. 预设 (presets)

包含 `worldInfos` (世界书) 和 `textPresets` (文本预设)。

**注意**：API 预设 (`apiPresets`) 不再导出，因为它们包含敏感的 API Key 信息。用户需要在导入后重新配置 API 设置。

**示例：**
```json
{
  "presets": {
    "worldInfos": [
      {
        "id": "world_001",
        "name": "现代都市设定",
        "content": "故事发生在一个现代化的大都市...",
        "createdAt": 1769593200000,
        "createdAtFormatted": "2026-01-31T10:30:00.000Z",
        "updatedAt": 1769679600000,
        "updatedAtFormatted": "2026-02-01T10:30:00.000Z",
        "_contentLength": 256
      }
    ],
    "textPresets": [
      {
        "id": "preset_chat_01",
        "name": "日常对话",
        "content": "请用轻松自然的语气回复...",
        "type": 0,
        "typeName": "chat",
        "isBuiltIn": false,
        "createdAt": 1769593200000,
        "updatedAt": 1769593200000
      },
      {
        "id": "preset_image_01",
        "name": "动漫风格",
        "content": "anime style, high quality...",
        "type": 1,
        "typeName": "image",
        "isBuiltIn": true,
        "createdAt": 1769593200000,
        "updatedAt": 1769593200000
      }
    ]
  }
}
```

### 9.1 世界书 (worldInfos)

| 字段 | 类型 | 说明 |
|------|------|------|
| id | String | 世界书ID |
| name | String | 名称 |
| content | String | 内容 |
| createdAt | Number | 创建时间戳 (毫秒) |
| createdAtFormatted | String | 创建时间 (ISO 8601) |
| updatedAt | Number | 更新时间戳 (毫秒) |
| updatedAtFormatted | String | 更新时间 (ISO 8601) |
| _contentLength | Number | 内容长度 (统计字段) |

### 9.2 文本预设 (textPresets)

| 字段 | 类型 | 说明 |
|------|------|------|
| id | String | 预设ID |
| name | String | 名称 |
| content | String | 内容 |
| type | Number | 类型枚举值 |
| typeName | String | 类型名称 |
| isBuiltIn | Boolean | 是否为内置预设 |
| createdAt | Number | 创建时间戳 (毫秒) |
| updatedAt | Number | 更新时间戳 (毫秒) |

#### 预设类型 (TextPresetType)

| 枚举值 | 名称 | 说明 |
|--------|------|------|
| 0 | chat | 聊天预设 |
| 1 | image | 生图预设 |

## 10. 设置 (settings)

包含应用的键值对设置。

| 字段 | 类型 | 说明 |
|------|------|------|
| items | Object | 设置键值对 |
| _count | Number | 设置项数量 (统计字段) |

**注意**：包含敏感信息的设置项（如包含 `key`、`secret`、`token`、`api`、`password` 等关键词的设置）不会被导出。

**示例：**
```json
{
  "settings": {
    "items": {
      "theme": "dark",
      "language": "zh-CN",
      "notification_enabled": "true",
      "chat_font_size": "16",
      "moments_auto_refresh": "true"
    },
    "_count": 5
  }
}
```

---

## 开发者注意事项

1. **完整数据迁移**：从 v2.0.0 版本开始，JSON 导出默认包含所有图片资源的 Base64 编码数据，可实现完整的跨设备数据迁移，无需依赖 ZIP 导出功能。

2. **文件大小**：由于包含图片二进制数据，导出文件可能较大。如需仅导出文本数据，可在调用 `exportToJson()` 时设置 `includeImageData: false`。

3. **敏感信息安全**：
   - API Key、Secret、Token 等敏感信息**完全不导出**
   - API 预设配置不导出
   - 用户需要在导入后重新配置 API 设置

4. **数据恢复**：此格式支持完整数据恢复，包括：
   - 所有联系人头像和参考图
   - 聊天中的图片消息
   - 朋友圈媒体文件
   - 表情包图片
   - 聊天背景图

5. **隐私安全**：虽然敏感配置已不导出，但聊天记录、朋友圈内容等可能包含个人隐私信息，请妥善保管导出文件。

6. **版本兼容**：
   - v1.0.0：仅包含文本数据和路径引用
   - v2.0.0：包含图片二进制数据 (Base64)，不包含 API Key

7. **统计字段**：以 `_` 开头的字段（如 `_messageCount`、`_likeCount`）为统计/辅助字段，用于快速查看数据量，导入时可忽略。

8. **Base64 编码**：所有二进制数据（图片、音频等）均使用标准 Base64 编码。解码时请使用对应语言的 Base64 解码函数。