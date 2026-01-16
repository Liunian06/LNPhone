# API 预设持久化功能测试指南

## 已实现的功能

API 预设的持久化存储已经完全实现，包括：

1. **预设列表持久化** - 所有创建的 API 预设都会自动保存
2. **活跃预设持久化** - 当前选中使用的 API 预设会被记住
3. **数据验证** - 启动时自动验证保存的预设是否仍然有效

## 测试步骤

### 1. 创建并设置 API 预设

1. 打开应用，进入"设置" -> "API 设置"
2. 点击右上角"+"按钮创建新预设
3. 填写预设信息：
   - 预设名称：例如 "我的 OpenAI"
   - 提供商：选择 OpenAI 或 Gemini
   - Base URL：填写 API 地址（可选，留空使用默认值）
   - API Key：填写你的 API 密钥
   - 模型：输入或拉取模型列表选择
4. 点击"保存"

### 2. 设置为当前使用

1. 在 API 预设列表中，点击刚创建的预设
2. 选择"设为当前使用"
3. 确认预设图标变为绿色勾选标记 ✓

### 3. 验证持久化

1. **完全关闭应用**（不是后台运行，而是从任务管理器中关闭）
2. **重新启动应用**
3. 进入"设置" -> "API 设置"
4. **验证点**：
   - ✓ 之前创建的预设仍然存在
   - ✓ 之前选中的预设仍然显示绿色勾选标记
   - ✓ 可以正常发送消息并获得 AI 回复

### 4. 测试多个预设

1. 创建第二个 API 预设（例如使用不同的模型）
2. 切换到第二个预设（设为当前使用）
3. 关闭并重启应用
4. **验证点**：
   - ✓ 两个预设都存在
   - ✓ 当前使用的是第二个预设（显示绿色勾选）

### 5. 测试预设删除后的处理

1. 删除当前正在使用的预设
2. 关闭并重启应用
3. **验证点**：
   - ✓ 被删除的预设不再显示
   - ✓ 没有任何预设被自动选中（需要重新选择）
   - ✓ 尝试发送消息时会提示"请先在设置中配置并选择 API 预设"

## 技术实现细节

### 存储位置
- 使用 `SharedPreferences` 存储
- 键名：
  - `api_presets`: 预设列表（JSON 数组）
  - `active_preset_id`: 当前活跃预设的 ID

### 存储时机
- 添加预设时自动保存
- 更新预设时自动保存
- 删除预设时自动保存
- 设置当前预设时自动保存

### 加载时机
- App 启动时，`ApiSettingsProvider` 初始化时自动加载
- 添加了 `isInitialized` 标志确保数据加载完成后才使用

### 数据验证
- 启动时验证 `active_preset_id` 对应的预设是否仍然存在
- 如果预设已被删除，自动清除无效的 `active_preset_id`

## 故障排除

### 问题：重启后预设丢失
**可能原因**：
- SharedPreferences 初始化失败
- 应用没有存储权限

**解决方案**：
1. 检查应用权限设置
2. 尝试重新安装应用
3. 检查系统存储空间是否充足

### 问题：选中的预设不记住
**可能原因**：
- 没有正确调用"设为当前使用"
- 预设被删除后未重新选择

**解决方案**：
1. 确保点击预设后选择"设为当前使用"
2. 检查预设是否显示绿色勾选标记
3. 如果预设被删除，需要重新选择一个预设

### 问题：发送消息时提示"请先配置 API 预设"
**可能原因**：
- 没有设置当前使用的预设
- API 设置还在加载中

**解决方案**：
1. 进入 API 设置，选择一个预设并"设为当前使用"
2. 如果刚启动应用，等待几秒让数据加载完成
3. 确保至少创建了一个预设

## 代码改进说明

### 改进 1: 添加初始化状态跟踪
```dart
bool _isInitialized = false;
bool get isInitialized => _isInitialized;
```

### 改进 2: 增强错误处理
```dart
Future<void> _loadPresets() async {
  try {
    // 加载逻辑
    _isInitialized = true;
    notifyListeners();
  } catch (e) {
    debugPrint('Error loading API presets: $e');
    _isInitialized = true;
    notifyListeners();
  }
}
```

### 改进 3: 验证预设有效性
```dart
// 验证 activePresetId 是否仍然有效
if (_activePresetId != null) {
  final presetExists = _presets.any((p) => p.id == _activePresetId);
  if (!presetExists) {
    _activePresetId = null;
    await prefs.remove('active_preset_id');
  }
}
```

### 改进 4: 使用前检查初始化状态
```dart
if (!apiProvider.isInitialized) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('正在加载 API 设置，请稍后重试'))
  );
  return;
}
```

## 结论

API 预设持久化功能已经完整实现并经过增强，能够：
- ✓ 自动保存所有预设配置
- ✓ 记住当前选中的预设
- ✓ 应用重启后自动恢复
- ✓ 处理异常情况（如预设被删除）
- ✓ 提供清晰的用户反馈

用户无需手动保存，所有操作都会自动持久化到设备存储中。