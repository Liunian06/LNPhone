package com.example.lnphone2

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.RenderMode
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    // 强制使用 TextureView 渲染模式，这比 Manifest 配置更可靠
    // TextureView 能有效解决 Android 低版本小窗模式下的白屏/黑屏问题
    override fun getRenderMode(): RenderMode {
        return RenderMode.texture
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            BackgroundReplyNativeHelper.CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getPermissionStatus" -> {
                    result.success(BackgroundReplyNativeHelper.getPermissionStatus(this))
                }
                "scheduleNextWakeup" -> {
                    val timestampMs = (call.argument<Number>("timestampMs") ?: 0L).toLong()
                    BackgroundReplyNativeHelper.scheduleNextWakeup(this, timestampMs)
                    result.success(null)
                }
                "cancelNextWakeup" -> {
                    BackgroundReplyNativeHelper.cancelNextWakeup(this)
                    result.success(null)
                }
                "getPersistedNextWakeup" -> {
                    result.success(BackgroundReplyNativeHelper.getPersistedNextWakeup(this))
                }
                "openNotificationSettings" -> {
                    openNotificationSettings()
                    result.success(null)
                }
                "openExactAlarmSettings" -> {
                    openExactAlarmSettings()
                    result.success(null)
                }
                "openBatteryOptimizationSettings" -> {
                    openBatteryOptimizationSettings()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun openNotificationSettings() {
        val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
            putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
        }
        startActivity(intent)
    }

    private fun openExactAlarmSettings() {
        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            Intent(
                Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM,
                Uri.parse("package:$packageName"),
            )
        } else {
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.parse("package:$packageName")
            }
        }
        startActivity(intent)
    }

    private fun openBatteryOptimizationSettings() {
        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Intent(
                Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                Uri.parse("package:$packageName"),
            )
        } else {
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.parse("package:$packageName")
            }
        }
        startActivity(intent)
    }
}
