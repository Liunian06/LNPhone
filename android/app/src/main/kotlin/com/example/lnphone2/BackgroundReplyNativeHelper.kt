package com.example.lnphone2

import android.Manifest
import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.PowerManager
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import id.flutter.flutter_background_service.BackgroundService

object BackgroundReplyNativeHelper {
    const val CHANNEL = "com.example.lnphone2/background_reply"

    private const val PREFS_NAME = "background_reply_prefs"
    private const val KEY_NEXT_WAKEUP_AT = "next_wakeup_at"
    private const val WAKEUP_REQUEST_CODE = 426_001

    fun getPermissionStatus(context: Context): Map<String, Any> {
        return mapOf(
            "notificationsGranted" to notificationsGranted(context),
            "exactAlarmGranted" to exactAlarmGranted(context),
            "batteryOptimizationIgnored" to batteryOptimizationIgnored(context),
            "exactAlarmSupported" to true,
            "batteryOptimizationSupported" to (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M),
        )
    }

    fun notificationsGranted(context: Context): Boolean {
        val notificationsEnabled = NotificationManagerCompat.from(context).areNotificationsEnabled()
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            notificationsEnabled && ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.POST_NOTIFICATIONS,
            ) == PackageManager.PERMISSION_GRANTED
        } else {
            notificationsEnabled
        }
    }

    fun exactAlarmGranted(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
            return true
        }
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        return alarmManager.canScheduleExactAlarms()
    }

    fun batteryOptimizationIgnored(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            return true
        }
        val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        return powerManager.isIgnoringBatteryOptimizations(context.packageName)
    }

    fun scheduleNextWakeup(context: Context, timestampMs: Long) {
        if (timestampMs <= 0L) {
            cancelNextWakeup(context)
            return
        }

        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pendingIntent = buildWakeupPendingIntent(context)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
            !alarmManager.canScheduleExactAlarms()
        ) {
            alarmManager.setAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                timestampMs,
                pendingIntent,
            )
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarmManager.setExactAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                timestampMs,
                pendingIntent,
            )
        } else {
            alarmManager.setExact(
                AlarmManager.RTC_WAKEUP,
                timestampMs,
                pendingIntent,
            )
        }

        persistNextWakeup(context, timestampMs)
    }

    fun cancelNextWakeup(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.cancel(buildWakeupPendingIntent(context))
        persistNextWakeup(context, 0L)
    }

    fun getPersistedNextWakeup(context: Context): Long {
        return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .getLong(KEY_NEXT_WAKEUP_AT, 0L)
    }

    fun restoreWakeupFromPersistence(context: Context) {
        val nextWakeupAt = getPersistedNextWakeup(context)
        if (nextWakeupAt <= 0L) {
            return
        }

        if (nextWakeupAt <= System.currentTimeMillis()) {
            cancelNextWakeup(context)
            startFlutterBackgroundService(context)
            return
        }

        scheduleNextWakeup(context, nextWakeupAt)
    }

    fun startFlutterBackgroundService(context: Context) {
        val intent = Intent(context, BackgroundService::class.java)
        try {
            ContextCompat.startForegroundService(context, intent)
        } catch (_: Exception) {
            context.startService(intent)
        }
    }

    private fun persistNextWakeup(context: Context, timestampMs: Long) {
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putLong(KEY_NEXT_WAKEUP_AT, timestampMs)
            .apply()
    }

    private fun buildWakeupPendingIntent(context: Context): PendingIntent {
        val intent = Intent(context, BackgroundReplyAlarmReceiver::class.java).apply {
            action = "com.example.lnphone2.ACTION_BACKGROUND_REPLY_WAKEUP"
        }

        val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        return PendingIntent.getBroadcast(
            context,
            WAKEUP_REQUEST_CODE,
            intent,
            flags,
        )
    }
}
