import '../database/database.dart';
import '../models/background_reply_model.dart';
import '../services/app_log_service.dart';
import '../utils/storage_utils.dart';
import 'background_permission_service.dart';

class BackgroundReplySchedulerService {
  static const String enableBackgroundActiveReplyKey =
      'enable_background_active_reply';
  static const String backgroundActiveReplyIntervalKey =
      'background_active_reply_interval';
  static const String lastActiveTimeKey = 'last_active_time';
  static const int defaultBackgroundReplyIntervalMinutes = 60;

  static final AppDatabase _db = AppDatabase();

  static Future<int?> syncAllTasks({
    BackgroundPermissionSnapshot? permissionSnapshot,
    String triggerSource = 'manual',
  }) async {
    final snapshot = permissionSnapshot ??
        await BackgroundPermissionService.getPersistedSnapshot();
    final globalEnabled =
        await _db.getSettingBool(enableBackgroundActiveReplyKey) ?? true;
    final globalInterval =
        await _db.getSettingInt(backgroundActiveReplyIntervalKey) ??
            defaultBackgroundReplyIntervalMinutes;
    final lastActiveTime = await _db.getSettingInt(lastActiveTimeKey) ?? 0;

    final sessionEntities = await _db.getAllSessionEntities();
    final activeSessionIds = <String>{};

    for (final session in sessionEntities) {
      final config = await _db.getSessionBackgroundReplyConfig(session.id);
      final hasFailureLock = config.disabledByFailure;
      final roleEnabled = config.enableBackgroundReply;
      final isManagedSession = roleEnabled || hasFailureLock;

      if (!isManagedSession) {
        await _db.deleteBackgroundReplyTaskBySessionId(session.id);
        await _db.updateSessionBackgroundReplySettings(
          session.id,
          backgroundReplyStatus: backgroundReplySessionStatusName(
            BackgroundReplySessionStatus.idle,
          ),
        );
        continue;
      }

      activeSessionIds.add(session.id);

      if (hasFailureLock) {
        await _db.deleteBackgroundReplyTaskBySessionId(session.id);
        await _db.updateSessionBackgroundReplySettings(
          session.id,
          backgroundReplyStatus: backgroundReplySessionStatusName(
            BackgroundReplySessionStatus.disabledByFailure,
          ),
        );
        continue;
      }

      if (!globalEnabled) {
        await _db.deleteBackgroundReplyTaskBySessionId(session.id);
        await _db.updateSessionBackgroundReplySettings(
          session.id,
          backgroundReplyStatus: backgroundReplySessionStatusName(
            BackgroundReplySessionStatus.pausedGlobally,
          ),
        );
        continue;
      }

      final lastMessage = await _db.getLastMessage(session.id);
      if (lastMessage == null) {
        await _db.deleteBackgroundReplyTaskBySessionId(session.id);
        await _db.updateSessionBackgroundReplySettings(
          session.id,
          backgroundReplyStatus: backgroundReplySessionStatusName(
            BackgroundReplySessionStatus.idle,
          ),
        );
        continue;
      }

      final intervalMinutes = config.intervalMinutes > 0
          ? config.intervalMinutes
          : globalInterval;
      final nextTriggerAt = _computeNextTriggerAt(
        lastActiveTime: lastActiveTime,
        lastMessageTime: lastMessage.timestamp,
        intervalMinutes: intervalMinutes,
      );

      if (!snapshot.hasBaseRequirements) {
        await _db.upsertBackgroundReplyTask(
          id: 'bg-task-${session.id}',
          sessionId: session.id,
          roleId: session.roleId,
          nextTriggerAt: nextTriggerAt,
          status: BackgroundReplyTaskStatus.pausedPermissionMissing,
          enabled: false,
          triggerSource: triggerSource,
        );
        await _db.updateSessionBackgroundReplySettings(
          session.id,
          backgroundReplyStatus: backgroundReplySessionStatusName(
            BackgroundReplySessionStatus.pausedPermissionMissing,
          ),
        );
        continue;
      }

      await _db.upsertBackgroundReplyTask(
        id: 'bg-task-${session.id}',
        sessionId: session.id,
        roleId: session.roleId,
        nextTriggerAt: nextTriggerAt,
        status: BackgroundReplyTaskStatus.pending,
        enabled: true,
        triggerSource: triggerSource,
      );
      await _db.updateSessionBackgroundReplySettings(
        session.id,
        backgroundReplyStatus: backgroundReplySessionStatusName(
          BackgroundReplySessionStatus.scheduled,
        ),
      );
    }

    final allTasks = await _db.getAllBackgroundReplyTasks();
    final staleSessionIds = allTasks
        .where((task) => !activeSessionIds.contains(task.sessionId))
        .map((task) => task.sessionId)
        .toList();
    await _db.deleteBackgroundReplyTasksBySessionIds(staleSessionIds);

    final nextTask = snapshot.hasBaseRequirements && globalEnabled
        ? await _db.getNextBackgroundReplyTask()
        : null;

    await AppLogService.log(
      '后台任务同步完成',
      category: 'Scheduler',
      data: {
        'globalEnabled': globalEnabled,
        'hasBaseRequirements': snapshot.hasBaseRequirements,
        'activeSessionCount': activeSessionIds.length,
        'nextTriggerAt': nextTask?.nextTriggerAt,
        'triggerSource': triggerSource,
      },
    );

    return nextTask?.nextTriggerAt;
  }

  static Future<int?> syncAllTasksFromStoredPermissions({
    String triggerSource = 'background',
  }) {
    return syncAllTasks(
      permissionSnapshot: null,
      triggerSource: triggerSource,
    );
  }

  static Future<void> disableSessionDueToApiFailure(
    String sessionId, {
    required String reason,
  }) async {
    await _db.updateSessionBackgroundReplySettings(
      sessionId,
      enableBackgroundReply: false,
      backgroundReplyStatus: backgroundReplySessionStatusName(
        BackgroundReplySessionStatus.disabledByFailure,
      ),
      backgroundReplyDisabledByFailure: true,
      backgroundReplyLastError: reason,
    );
    await _db.updateBackgroundReplyTaskError(
      sessionId,
      status: BackgroundReplyTaskStatus.disabledByFailure,
      lastError: reason,
      enabled: false,
    );
    await _db.deleteBackgroundReplyTaskBySessionId(sessionId);

    await AppLogService.log(
      '后台主动回复已因 API 失败自动停用',
      category: 'Fuse',
      level: LogLevel.warning,
      data: {
        'sessionId': sessionId,
        'reason': reason,
      },
    );
  }

  static Future<void> reenableSessionAfterFailure(
    String sessionId, {
    int? intervalMinutes,
  }) async {
    await _db.clearSessionBackgroundReplyFailure(sessionId);
    await _db.updateSessionBackgroundReplySettings(
      sessionId,
      enableBackgroundReply: true,
      backgroundReplyIntervalMinutes: intervalMinutes,
    );
  }

  static int _computeNextTriggerAt({
    required int lastActiveTime,
    required int lastMessageTime,
    required int intervalMinutes,
  }) {
    final baseTime =
        lastActiveTime > lastMessageTime ? lastActiveTime : lastMessageTime;
    return baseTime + intervalMinutes * 60 * 1000;
  }

  static Future<int?> recordForegroundUserActivity({
    required String triggerSource,
  }) async {
    await _db.setSettingInt(
      lastActiveTimeKey,
      StorageUtils.getUniqueTimestamp(),
    );
    return syncAllTasksFromStoredPermissions(triggerSource: triggerSource);
  }
}
