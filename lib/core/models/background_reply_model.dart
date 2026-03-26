enum BackgroundReplyTaskStatus {
  pending,
  running,
  pausedPermissionMissing,
  pausedGlobally,
  disabledByFailure,
}

enum BackgroundReplySessionStatus {
  idle,
  scheduled,
  running,
  pausedPermissionMissing,
  pausedGlobally,
  disabledByFailure,
}

BackgroundReplyTaskStatus backgroundReplyTaskStatusFromName(String raw) {
  switch (raw) {
    case 'running':
      return BackgroundReplyTaskStatus.running;
    case 'paused_permission_missing':
      return BackgroundReplyTaskStatus.pausedPermissionMissing;
    case 'paused_globally':
      return BackgroundReplyTaskStatus.pausedGlobally;
    case 'disabled_by_failure':
      return BackgroundReplyTaskStatus.disabledByFailure;
    case 'pending':
    default:
      return BackgroundReplyTaskStatus.pending;
  }
}

String backgroundReplyTaskStatusName(BackgroundReplyTaskStatus status) {
  switch (status) {
    case BackgroundReplyTaskStatus.running:
      return 'running';
    case BackgroundReplyTaskStatus.pausedPermissionMissing:
      return 'paused_permission_missing';
    case BackgroundReplyTaskStatus.pausedGlobally:
      return 'paused_globally';
    case BackgroundReplyTaskStatus.disabledByFailure:
      return 'disabled_by_failure';
    case BackgroundReplyTaskStatus.pending:
      return 'pending';
  }
}

BackgroundReplySessionStatus backgroundReplySessionStatusFromName(String raw) {
  switch (raw) {
    case 'scheduled':
      return BackgroundReplySessionStatus.scheduled;
    case 'running':
      return BackgroundReplySessionStatus.running;
    case 'paused_permission_missing':
      return BackgroundReplySessionStatus.pausedPermissionMissing;
    case 'paused_globally':
      return BackgroundReplySessionStatus.pausedGlobally;
    case 'disabled_by_failure':
      return BackgroundReplySessionStatus.disabledByFailure;
    case 'idle':
    default:
      return BackgroundReplySessionStatus.idle;
  }
}

String backgroundReplySessionStatusName(
  BackgroundReplySessionStatus status,
) {
  switch (status) {
    case BackgroundReplySessionStatus.scheduled:
      return 'scheduled';
    case BackgroundReplySessionStatus.running:
      return 'running';
    case BackgroundReplySessionStatus.pausedPermissionMissing:
      return 'paused_permission_missing';
    case BackgroundReplySessionStatus.pausedGlobally:
      return 'paused_globally';
    case BackgroundReplySessionStatus.disabledByFailure:
      return 'disabled_by_failure';
    case BackgroundReplySessionStatus.idle:
      return 'idle';
  }
}

class BackgroundReplyTaskModel {
  final String id;
  final String sessionId;
  final String roleId;
  final bool enabled;
  final BackgroundReplyTaskStatus status;
  final int nextTriggerAt;
  final int? lastAttemptAt;
  final int? lastSuccessAt;
  final String? lastError;
  final String? triggerSource;
  final int createdAt;
  final int updatedAt;

  const BackgroundReplyTaskModel({
    required this.id,
    required this.sessionId,
    required this.roleId,
    required this.enabled,
    required this.status,
    required this.nextTriggerAt,
    required this.lastAttemptAt,
    required this.lastSuccessAt,
    required this.lastError,
    required this.triggerSource,
    required this.createdAt,
    required this.updatedAt,
  });
}

class BackgroundPermissionSnapshot {
  final bool notificationsGranted;
  final bool exactAlarmGranted;
  final bool batteryOptimizationIgnored;
  final bool exactAlarmSupported;
  final bool batteryOptimizationSupported;

  const BackgroundPermissionSnapshot({
    required this.notificationsGranted,
    required this.exactAlarmGranted,
    required this.batteryOptimizationIgnored,
    required this.exactAlarmSupported,
    required this.batteryOptimizationSupported,
  });

  bool get hasBaseRequirements =>
      notificationsGranted &&
      exactAlarmGranted &&
      (!batteryOptimizationSupported || batteryOptimizationIgnored);
}
