# LnPhone - AI Native 手机系统

一个高度还原iOS风格的AI Native手机系统，使用Flutter开发，支持多平台。

![Flutter](https://img.shields.io/badge/Flutter-3.10+-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart)
![License](https://img.shields.io/badge/License-MIT-green)

## 📱 功能特性

### 核心界面
- **锁屏界面** - 精确还原iOS锁屏，支持时间显示、通知预览、向上滑动解锁
- **主屏幕** - 应用网格布局、多页滑动、页面指示器
- **Dock栏** - 毛玻璃效果、固定4个应用
- **状态栏** - 灵动岛、时间、信号、WiFi、电池指示器

### 交互功能
- **控制中心** - 从右上角下滑打开，包含WiFi、蓝牙、亮度、音量等控制
- **通知中心** - 从左上角下滑打开，显示通知列表
- **多任务切换器** - 应用卡片预览、向上滑动关闭应用
- **应用编辑模式** - 长按图标进入，支持删除和晃动动画

### 视觉效果
- **动态壁纸** - 6种预设渐变壁纸，包含极光动画效果
- **毛玻璃效果** - Dock栏、控制中心、通知使用iOS风格模糊
- **应用图标** - 高度还原iOS图标样式，渐变、圆角、光泽效果
- **流畅动画** - 页面切换、应用启动、控制交互动画

## 🏗️ 项目结构

```
lib/
├── main.dart                 # 应用入口
├── core/                     # 核心模块
│   ├── constants/
│   │   └── ios_constants.dart    # iOS设计常量
│   ├── models/
│   │   └── app_model.dart        # 应用数据模型
│   ├── data/
│   │   └── default_apps.dart     # 预设应用数据
│   └── providers/
│       └── system_state_provider.dart  # 系统状态管理
├── screens/                  # 页面
│   ├── home_screen.dart      # 主屏幕
│   └── lock_screen.dart      # 锁屏
└── widgets/                  # 组件
    ├── widgets.dart          # 组件导出
    ├── ios_status_bar.dart   # 状态栏
    ├── ios_time_widget.dart  # 时间组件
    ├── ios_app_icon.dart     # 应用图标
    ├── ios_app_grid.dart     # 应用网格
    ├── ios_dock.dart         # Dock栏
    ├── ios_wallpaper.dart    # 壁纸
    ├── ios_control_center.dart    # 控制中心
    ├── ios_notification_center.dart # 通知中心
    ├── ios_home_indicator.dart    # 底部指示器
    └── ios_app_switcher.dart      # 多任务切换
```

## 🚀 快速开始

### 环境要求
- Flutter SDK >= 3.10.4
- Dart SDK >= 3.0.0

### 安装步骤

1. 克隆项目
```bash
git clone <repository-url>
cd lnphone2
```

2. 安装依赖
```bash
flutter pub get
```

3. 运行应用
```bash
# Android
flutter run

# iOS
flutter run -d ios

# Web
flutter run -d chrome

# macOS
flutter run -d macos

# Windows
flutter run -d windows
```

### 构建发布版本
```bash
# Android APK
flutter build apk --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

## 🎨 设计规范

### 尺寸常量
| 元素 | 尺寸 |
|------|------|
| 应用图标 | 60x60 |
| 图标圆角 | 13.5 (22.5%) |
| Dock高度 | 100 |
| 状态栏高度 | 44 |
| 网格列数 | 4 |

### 颜色系统
```dart
// 系统蓝色
Color(0xFF007AFF)

// 系统绿色
Color(0xFF34C759)

// 系统红色
Color(0xFFFF3B30)

// 系统橙色
Color(0xFFFF9500)
```

## 📦 依赖包

| 包名 | 用途 |
|------|------|
| cupertino_icons | iOS风格图标 |
| intl | 国际化支持 |
| provider | 状态管理 |
| flutter_animate | 动画效果 |
| blur | 模糊效果 |

## 🔧 自定义

### 添加新应用
在 `lib/core/data/default_apps.dart` 中添加：

```dart
const AppModel(
  id: 'my_app',
  name: '我的应用',
  type: AppType.thirdParty,
  iconType: IconType.gradient,
  icon: CupertinoIcons.app,
  gradientColors: [Color(0xFF007AFF), Color(0xFF5AC8FA)],
),
```

### 更换壁纸
在 `IOSWallpaper` 组件中切换样式：

```dart
IOSWallpaper(
  style: WallpaperStyle.aurora, // gradient1, gradient2, gradient3, dark, aurora, mesh
  child: ...
)
```

### 自定义控制中心
修改 `lib/widgets/ios_control_center.dart` 添加新的控制项。

## 🗺️ 路线图

- [x] 锁屏界面
- [x] 主屏幕
- [x] 应用图标系统
- [x] Dock栏
- [x] 控制中心
- [x] 通知中心
- [x] 多任务切换器
- [ ] 搜索界面
- [ ] 设置应用
- [ ] 小组件支持
- [ ] 文件夹功能
- [ ] 动态壁纸库
- [ ] AI助手集成

## 📄 许可证

MIT License

## 🤝 贡献

欢迎提交Issue和Pull Request！

---

**LnPhone** - AI Native Phone System  
Made with ❤️ using Flutter
