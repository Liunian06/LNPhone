# 后台主动回复重构 TODO

## 目标

将当前“常驻前台服务 + 每分钟 `Timer.periodic` 轮询”的后台主动回复实现，重构为：

- 不依赖 FCM / 厂商 Push
- 支持多个角色同时开启后台主动回复
- 支持 Android 15 / Android 16
- 允许使用无障碍权限作为增强保活能力
- 具备完整的权限检测、权限引导、返回复检能力
- 一旦某个角色的后台 API 调用报错或返回空结果，立即停用该角色的后台主动回复并清空该角色的全部定时任务

## 当前实现存在的问题

- 当前逻辑是全局开关 + 遍历所有会话 + 每分钟轮询，不是角色级独立调度。
- 当前逻辑依赖长期前台服务，容易在 Android 15/16 的前台服务限制、厂商省电策略下失效。
- 当前没有成体系的权限状态机，只有零散的权限申请。
- 当前没有“权限缺失 -> 引导用户 -> 返回设置页后复检”的完整闭环。
- 当前没有“角色级 API 失败熔断”机制。
- 当前虽然存在忽略电池优化的申请代码，但没有接入正式启用流程。
- 当前通知逻辑过度依赖高优先级和 `fullScreenIntent`，不适合作为聊天消息主路径。

## 总体设计原则

- 后台任务粒度从“全局扫描”改为“会话 / 角色级任务”。
- 系统调度采用“数据库内多任务 + 系统层单最近闹钟”的组合，而不是为每个角色长期跑一个 Timer。
- Flutter 侧负责配置、状态展示、权限编排、任务管理。
- Android 原生侧负责精确闹钟、广播恢复、短时前台服务、无障碍看门狗。
- 无障碍服务只作为“增强保活/恢复”手段，不作为主定时器，不做自动点击系统 UI。
- API 失败熔断只针对“已经成功触发保活并真正发起 API 调用”的场景。
- 权限检查必须从低到高依次确认，缺失时给出可操作引导，用户返回后必须自动复检。

## 关键设计决策

### 1. 调度模型

- 任务主键使用 `sessionId`，UI 上展示为“角色后台主动回复”。
- 每个 `sessionId` 最多保留一个有效待执行任务。
- 数据库允许保留多条历史记录，但活跃任务只能有一条，避免重复调度。
- Android 系统层只保留“最近一次到期时间”的精确闹钟。
- 精确闹钟触发后，原生层启动“短时前台服务”执行一次 due task 扫描。
- 扫描时处理所有 `nextTriggerAt <= now` 的角色任务，而不是只处理单个角色。
- 执行完成后重新计算全局最近触发时间，设置下一次系统闹钟。

### 2. 多角色适配

- 每个角色独立保存：
  - 是否启用后台主动回复
  - 触发间隔
  - 下次触发时间
  - 最后尝试时间
  - 最后成功时间
  - 最后失败原因
  - 当前状态
- 全局仅保留一个总开关作为“主控开关”。
- 只有“全局开关 = 开”且“角色开关 = 开”且“权限链满足”时，该角色任务才参与调度。

### 3. API 失败熔断

- 只在以下条件同时满足时触发熔断：
  - 后台任务成功被调起
  - 进入了该角色的 API 调用流程
  - API 明确返回错误、超时、空字符串、空消息、解析后无有效消息
- 熔断后立即执行：
  - 关闭该 `sessionId` 的后台主动回复开关
  - 删除该 `sessionId` 的全部待执行任务
  - 取消该 `sessionId` 关联的系统 PendingIntent / requestCode
  - 写入日志和失败原因
  - 在设置页 / 角色页显示“已因 API 失败自动停用”
- 不触发熔断的场景：
  - 通知权限未授权
  - 精确闹钟权限未授权
  - 忽略电池优化未授权
  - 无障碍未开启
  - 进程被系统杀掉
  - BOOT_COMPLETED 后任务尚未恢复
  - 短时前台服务尚未成功拉起

### 4. 权限检查顺序

按从低到高的顺序进行：

1. 通知权限 `POST_NOTIFICATIONS`
2. 精确闹钟权限 / 特殊访问
3. 忽略电池优化
4. 无障碍服务状态

说明：

- `FOREGROUND_SERVICE` 类权限是 Manifest 级，不属于用户交互授权项，但要纳入诊断结果中显示“已声明/未声明”。
- 无障碍权限不是基础必需项，而是增强模式的最后一级。
- 没有无障碍权限时，基础模式仍可工作，但设置页需明确标记“增强保活未启用”。

## 预期模块拆分

### Flutter 侧新增 / 改造

- `lib/core/services/background_reply_scheduler_service.dart`
- `lib/core/services/background_reply_task_service.dart`
- `lib/core/services/background_permission_service.dart`
- `lib/core/services/background_reply_fuse_service.dart`
- `lib/core/providers/prompt_settings_provider.dart`
- `lib/core/providers/chat_provider.dart`
- `lib/screens/prompt_settings_screen.dart`
- 如有必要新增角色级后台配置页面或在会话设置页补充入口

### Android 原生侧新增 / 改造

- `android/app/src/main/kotlin/.../BackgroundReplyAlarmReceiver.kt`
- `android/app/src/main/kotlin/.../BackgroundReplyBootReceiver.kt`
- `android/app/src/main/kotlin/.../BackgroundReplyForegroundService.kt`
- `android/app/src/main/kotlin/.../BackgroundReplyAccessibilityService.kt`
- `android/app/src/main/kotlin/.../BackgroundPermissionHelper.kt`
- `android/app/src/main/res/xml/background_reply_accessibility_service.xml`
- `android/app/src/main/AndroidManifest.xml`

### 数据库新增 / 改造

- `lib/core/database/tables.dart`
- `lib/core/database/database.dart`
- `lib/core/database/database.g.dart`

## 数据结构 TODO

- [ ] 为 `chat_sessions` 增加角色级后台主动回复字段
  - `background_reply_enabled`
  - `background_reply_interval_minutes`
  - `background_reply_status`
  - `background_reply_last_error`
  - `background_reply_disabled_by_failure`
- [ ] 新增后台任务表 `background_reply_tasks`
  - `id`
  - `session_id`
  - `role_id`
  - `enabled`
  - `status`
  - `next_trigger_at`
  - `last_attempt_at`
  - `last_success_at`
  - `last_error`
  - `trigger_source`
  - `created_at`
  - `updated_at`
- [ ] 对 `session_id` 建唯一活跃任务约束，避免重复入队
- [ ] 新增查询接口
  - 获取全部活跃任务
  - 获取最近到期任务
  - 获取所有 due task
  - 删除某个 `sessionId` 的全部任务
  - 更新任务状态
- [ ] 增加数据库迁移
- [ ] 为任务状态定义明确枚举
  - `pending`
  - `running`
  - `paused_permission_missing`
  - `paused_globally`
  - `disabled_by_failure`
  - `completed_waiting_reschedule`

## 调度重构 TODO

- [ ] 移除后台 `Timer.periodic` 作为主调度源
- [ ] 引入“最近一次系统闹钟 + 数据库多角色任务队列”模型
- [ ] 新增 Flutter 调度服务
  - 根据用户活跃时间、角色开关、角色间隔计算 `nextTriggerAt`
  - 为每个角色创建或更新唯一任务
  - 在全局主开关关闭时清空所有任务
- [ ] 新增 Android `AlarmReceiver`
  - 收到精确闹钟后启动短时前台服务
- [ ] 新增 Android 短时前台服务
  - 扫描全部 due task
  - 逐个角色执行后台主动回复
  - 完成后停止服务
- [ ] 每次任务变更后重新计算“最近一次全局闹钟”
- [ ] 引入 requestCode 生成规则
  - 与 `sessionId` 稳定映射
  - 保证可取消、可覆盖
- [ ] 处理并发执行保护
  - 同一 `sessionId` 不允许重入执行
  - 全局扫描时将任务先标为 `running`

## 多角色后台主动回复 TODO

- [ ] 将当前“全局后台主动回复开关”调整为“全局开关 + 角色级开关”
- [ ] 设置页保留全局主控开关
- [ ] 在会话级别增加角色开关和角色间隔设置
- [ ] 允许多个角色同时处于启用态
- [ ] 同一时刻多个角色到期时，按以下顺序处理
  - 先按 `nextTriggerAt` 升序
  - 再按 `lastAttemptAt` 升序
  - 最后按 `sessionId` 固定排序
- [ ] 限制单轮扫描的最大执行角色数，避免一次性打爆 API
- [ ] 单轮扫描结束后，未执行的 due task 顺延到下一轮最近时间点

## 权限编排 TODO

### 权限诊断服务

- [ ] 新增统一权限诊断服务 `background_permission_service`
- [ ] 输出统一状态模型
  - `supported`
  - `declared`
  - `granted`
  - `missing`
  - `requires_manual_action`
  - `last_checked_at`
- [ ] 汇总以下状态
  - 通知权限状态
  - 精确闹钟权限状态
  - 忽略电池优化状态
  - 无障碍增强模式状态
  - Manifest 声明状态

### 权限检查顺序

- [ ] 按以下顺序依次检测并提示
  - 第 1 步：通知权限
  - 第 2 步：精确闹钟
  - 第 3 步：忽略电池优化
  - 第 4 步：无障碍增强权限
- [ ] 当前一步未完成时，不允许直接跳到更高一级的启用确认
- [ ] 所有权限检查结果写入数据库 / 内存状态，供设置页直接展示

### 用户引导与返回复检

- [ ] 设置页新增“后台主动回复权限检查”卡片
- [ ] 每个权限项展示
  - 当前状态
  - 为什么需要
  - 如何开启
  - 跳转按钮
- [ ] 跳转系统设置后，在 `AppLifecycleState.resumed` 自动复检
- [ ] 返回后如果仍未满足，则继续显示明确缺失项
- [ ] 全部满足后，自动刷新调度状态
- [ ] 如果权限链中断，暂停全部后台任务，但不直接删除任务

## 无障碍增强模式 TODO

- [ ] 在 Manifest 中声明无障碍服务
- [ ] 增加无障碍服务配置 XML
- [ ] 明确服务只监听必要事件
  - `TYPE_WINDOW_STATE_CHANGED`
  - `TYPE_WINDOWS_CHANGED`
  - `TYPE_VIEW_CLICKED`
  - `TYPE_NOTIFICATION_STATE_CHANGED`
- [ ] 无障碍服务只做以下事情
  - 检查全局最近闹钟是否丢失
  - 检查是否存在过期未执行任务
  - 必要时补设闹钟或补拉起短时执行服务
- [ ] 无障碍服务禁止做以下事情
  - 自动点击系统设置
  - 自动操作三方应用界面
  - 伪造用户操作维持常驻
- [ ] 设置页增加“增强保活模式”说明
  - 未开启时说明基础模式可用但稳定性较低
  - 开启后说明用途、风险和限制

## API 执行与失败熔断 TODO

- [ ] 为后台执行链路单独封装 `runBackgroundReplyForSession(sessionId)`
- [ ] 背景执行前记录
  - `task running`
  - `attemptAt`
  - `triggerSource`
- [ ] 背景执行成功标准
  - API 调用成功
  - 返回内容非空
  - 解析后至少有一条有效展示消息
- [ ] 背景执行失败判定
  - HTTP 错误
  - SDK 抛错
  - 超时
  - 原始响应为空
  - 解析后无有效消息
- [ ] 失败后立即触发角色熔断
  - 关闭该角色后台主动回复
  - 删除该角色所有任务
  - 记录错误到 `chat_sessions.background_reply_last_error`
  - 状态写成 `disabled_by_failure`
- [ ] 成功后重新计算该角色下一次触发时间
- [ ] 失败熔断后向 UI 发出可读提示
  - “角色 XXX 的后台主动回复已因 API 失败自动关闭”

## 通知与前台服务 TODO

- [ ] 保留后台执行时的短时前台服务通知
- [ ] 将聊天消息通知与前台服务常驻通知彻底分离
- [ ] 不再依赖 `fullScreenIntent` 作为聊天通知主路径
- [ ] 消息通知使用正常高优先级渠道
- [ ] 前台服务只在执行窗口内存在，执行完成立即结束

## 设置页与交互 TODO

- [ ] 在 [prompt_settings_screen.dart](./lib/screens/prompt_settings_screen.dart) 保留全局总开关
- [ ] 在设置页增加权限诊断面板
- [ ] 在角色 / 会话设置中增加
  - 当前角色是否启用后台主动回复
  - 当前角色触发间隔
  - 当前角色任务状态
  - 当前角色最近失败原因
- [ ] 增加“重新启用已熔断角色”的显式入口
  - 手动重新启用时清除失败标记
  - 再次触发权限复检
  - 重新建任务
- [ ] 增加“立即测试当前角色后台触发”的按钮
- [ ] 增加“查看后台任务队列”的调试入口

## 生命周期与恢复 TODO

- [ ] 应用冷启动时恢复全部有效任务
- [ ] 应用从后台返回前台时复检权限和任务状态
- [ ] `BOOT_COMPLETED` 后只恢复任务和闹钟，不直接长期常驻执行
- [ ] 应用升级替换后恢复任务
- [ ] 时间变更、时区变更后重算所有 `nextTriggerAt`

## 日志与排障 TODO

- [ ] 为后台任务增加专门日志分类
  - `Scheduler`
  - `Permission`
  - `Accessibility`
  - `BackgroundReply`
  - `Fuse`
- [ ] 日志至少记录
  - 任务创建
  - 任务取消
  - 闹钟设置
  - 闹钟触发
  - 服务启动/结束
  - 角色执行开始/成功/失败
  - 熔断原因
  - 权限检查结果
- [ ] 设置页增加导出后台调度日志入口

## 测试 TODO

### 单元测试

- [ ] 多角色任务排序测试
- [ ] 单角色重复入队去重测试
- [ ] 最近闹钟重算测试
- [ ] API 失败熔断测试
- [ ] 权限状态聚合测试

### 集成测试

- [ ] 两个角色同时启用，触发时间不同，验证分别按期执行
- [ ] 两个角色同时到期，验证按排序顺序执行
- [ ] 某个角色 API 失败，验证只停该角色，其他角色不受影响
- [ ] 用户关闭通知权限后返回设置页，验证自动复检
- [ ] 用户开启精确闹钟后返回设置页，验证自动复检
- [ ] 用户开启无障碍后返回设置页，验证自动复检
- [ ] 重启后任务恢复测试
- [ ] 时间变更后任务重算测试

### 真机验证

- [ ] Android 15 真机验证
- [ ] Android 16 真机验证
- [ ] 至少一台国产 ROM 真机验证
- [ ] 锁屏 2 小时以上验证
- [ ] 多角色长时间待机验证

## 验收标准

- [ ] 可以同时启用多个角色的后台主动回复
- [ ] 每个角色任务彼此独立，互不覆盖
- [ ] 设置页能按顺序展示权限状态和引导
- [ ] 用户从系统设置返回后会自动复检权限
- [ ] 权限不完整时不会错误进入后台调度
- [ ] 某个角色后台 API 失败后，只停该角色，不影响其他角色
- [ ] 停用角色后，该角色所有任务和 PendingIntent 都被清空
- [ ] Android 15 / 16 下不再依赖常驻 `Timer.periodic`
- [ ] 无障碍增强模式可选开启，并能提升任务恢复能力

## 暂不实现

- 不接入 FCM
- 不接入厂商 Push
- 不实现 Accessibility 自动点击系统 UI
- 不实现长期常驻死循环 foreground service
- 不实现 API 失败自动重试和指数退避

## 需要你确认的点

- [ ] “角色级开关”是否就是按 `ChatSession` 粒度，而不是按 `roleId` 粒度
- [ ] API 失败熔断后，是否需要同时给用户发一条本地系统通知
- [ ] 单轮 due task 最大执行角色数是否需要上限，建议默认 3
- [ ] 无障碍增强模式是否默认关闭，仅在用户手动开启后生效

