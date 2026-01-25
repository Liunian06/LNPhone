import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// 画中画 (Picture-in-Picture) 服务
/// 用于处理 Android 小窗模式的进入和状态监听
class PipService {
  static const MethodChannel _channel =
      MethodChannel('com.example.lnphone2/pip');

  // 单例模式
  static final PipService _instance = PipService._internal();
  factory PipService() => _instance;
  PipService._internal() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  // PiP 状态变化监听器
  final List<Function(bool)> _listeners = [];

  /// 添加 PiP 状态监听器
  void addListener(Function(bool) listener) {
    _listeners.add(listener);
  }

  /// 移除 PiP 状态监听器
  void removeListener(Function(bool) listener) {
    _listeners.remove(listener);
  }

  /// 处理原生端的方法调用
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (call.method == 'pipStateChanged') {
      final bool isInPipMode = call.arguments as bool;
      for (final listener in _listeners) {
        listener(isInPipMode);
      }
    }
  }

  /// 尝试进入画中画模式
  /// 返回是否成功触发（不代表一定进入成功，取决于系统支持）
  Future<bool> enterPipMode() async {
    try {
      await _channel.invokeMethod('enterPip');
      return true;
    } on PlatformException catch (e) {
      debugPrint('Failed to enter PiP mode: ${e.message}');
      return false;
    }
  }
}
