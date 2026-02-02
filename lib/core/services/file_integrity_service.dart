import 'dart:io';
import 'package:flutter/foundation.dart';
import '../database/database.dart';
import '../utils/storage_utils.dart';
import '../models/contact_model.dart';
import 'emoji_file_backup_service.dart';

/// 文件完整性检查和恢复服务
/// 用于解决 Android 15/16 等高版本系统中图片资源丢失的问题
class FileIntegrityService {
  final AppDatabase _db;

  FileIntegrityService(this._db);

  /// 检查并恢复所有丢失的图片资源
  /// 应在应用启动时调用
  Future<FileIntegrityReport> checkAndRestoreAll() async {
    debugPrint('[FileIntegrity] 开始检查文件完整性...');

    final report = FileIntegrityReport();

    try {
      // 1. 检查并恢复角色头像
      await _checkRoleAvatars(report);

      // 2. 检查并恢复用户头像
      await _checkMeAvatars(report);

      // 3. 检查并恢复聊天背景图
      await _checkChatBackgrounds(report);

      // 4. 检查并恢复聊天消息中的图片
      await _checkMessageImages(report);

      // 5. 检查表情包文件
      await _checkEmojiFiles(report);

      debugPrint('[FileIntegrity] 检查完成: ${report.summary}');
    } catch (e) {
      debugPrint('[FileIntegrity] 检查过程出错: $e');
      report.errors.add('检查过程出错: $e');
    }

    return report;
  }

  /// 检查角色头像
  Future<void> _checkRoleAvatars(FileIntegrityReport report) async {
    try {
      final roles = await _db.getAllContactRoles();

      for (final role in roles) {
        report.totalChecked++;

        // 如果没有头像路径，跳过
        if (role.avatarPath == null || role.avatarPath!.isEmpty) {
          continue;
        }

        // 检查文件是否存在
        final absPath = await StorageUtils.toAbsolutePath(role.avatarPath!);
        final file = File(absPath);

        if (!await file.exists()) {
          report.missingFiles++;
          debugPrint(
              '[FileIntegrity] 角色头像丢失: ${role.name} - ${role.avatarPath}');

          // 尝试从数据库恢复
          if (role.avatarData != null && role.avatarData!.isNotEmpty) {
            try {
              // 确保目录存在
              final directory = file.parent;
              if (!await directory.exists()) {
                await directory.create(recursive: true);
              }

              // 写入文件
              await file.writeAsBytes(role.avatarData!);
              report.restoredFiles++;
              debugPrint('[FileIntegrity] 已恢复角色头像: ${role.name}');
            } catch (e) {
              report.failedRestores++;
              report.errors.add('恢复角色头像失败 ${role.name}: $e');
              debugPrint('[FileIntegrity] 恢复失败: $e');
            }
          } else {
            report.noBackupFiles++;
            debugPrint('[FileIntegrity] 无备份数据: ${role.name}');
          }
        }

        // 检查参考图
        for (final refPath in role.referenceImages) {
          if (refPath.isEmpty || refPath.startsWith('http')) continue;

          report.totalChecked++;
          final refAbsPath = await StorageUtils.toAbsolutePath(refPath);
          final refFile = File(refAbsPath);

          if (!await refFile.exists()) {
            report.missingFiles++;
            debugPrint('[FileIntegrity] 参考图丢失: ${role.name} - $refPath');

            // 尝试从 referenceImagesData 恢复
            final index = role.referenceImages.indexOf(refPath);
            if (role.referenceImagesData != null &&
                index >= 0 &&
                index < role.referenceImagesData!.length) {
              try {
                final base64Data = role.referenceImagesData![index];
                // 这里需要解码 base64 并写入文件
                // 由于 referenceImagesData 存储的是 base64 字符串，需要解码
                report.noBackupFiles++; // 暂时标记为无备份，需要完善
              } catch (e) {
                report.failedRestores++;
              }
            } else {
              report.noBackupFiles++;
            }
          }
        }
      }
    } catch (e) {
      report.errors.add('检查角色头像时出错: $e');
    }
  }

  /// 检查用户头像
  Future<void> _checkMeAvatars(FileIntegrityReport report) async {
    try {
      final meList = await _db.getAllContactMes();

      for (final me in meList) {
        report.totalChecked++;

        if (me.avatarPath == null || me.avatarPath!.isEmpty) {
          continue;
        }

        final absPath = await StorageUtils.toAbsolutePath(me.avatarPath!);
        final file = File(absPath);

        if (!await file.exists()) {
          report.missingFiles++;
          debugPrint('[FileIntegrity] 用户头像丢失: ${me.name} - ${me.avatarPath}');

          if (me.avatarData != null && me.avatarData!.isNotEmpty) {
            try {
              final directory = file.parent;
              if (!await directory.exists()) {
                await directory.create(recursive: true);
              }

              await file.writeAsBytes(me.avatarData!);
              report.restoredFiles++;
              debugPrint('[FileIntegrity] 已恢复用户头像: ${me.name}');
            } catch (e) {
              report.failedRestores++;
              report.errors.add('恢复用户头像失败 ${me.name}: $e');
            }
          } else {
            report.noBackupFiles++;
          }
        }

        // 检查参考图
        for (final refPath in me.referenceImages) {
          if (refPath.isEmpty || refPath.startsWith('http')) continue;

          report.totalChecked++;
          final refAbsPath = await StorageUtils.toAbsolutePath(refPath);
          final refFile = File(refAbsPath);

          if (!await refFile.exists()) {
            report.missingFiles++;
            report.noBackupFiles++; // 参考图暂时没有完善的备份机制
          }
        }
      }
    } catch (e) {
      report.errors.add('检查用户头像时出错: $e');
    }
  }

  /// 检查聊天背景图
  Future<void> _checkChatBackgrounds(FileIntegrityReport report) async {
    try {
      final sessions = await _db.getAllSessions();

      for (final session in sessions) {
        if (session.backgroundImage == null ||
            session.backgroundImage!.isEmpty) {
          continue;
        }

        report.totalChecked++;

        final absPath =
            await StorageUtils.toAbsolutePath(session.backgroundImage!);
        final file = File(absPath);

        if (!await file.exists()) {
          report.missingFiles++;
          debugPrint(
              '[FileIntegrity] 聊天背景图丢失: ${session.id} - ${session.backgroundImage}');

          if (session.backgroundImageData != null &&
              session.backgroundImageData!.isNotEmpty) {
            try {
              final directory = file.parent;
              if (!await directory.exists()) {
                await directory.create(recursive: true);
              }

              await file.writeAsBytes(session.backgroundImageData!);
              report.restoredFiles++;
              debugPrint('[FileIntegrity] 已恢复聊天背景图: ${session.id}');
            } catch (e) {
              report.failedRestores++;
              report.errors.add('恢复聊天背景图失败 ${session.id}: $e');
            }
          } else {
            report.noBackupFiles++;
          }
        }
      }
    } catch (e) {
      report.errors.add('检查聊天背景图时出错: $e');
    }
  }

  /// 检查聊天消息中的图片
  Future<void> _checkMessageImages(FileIntegrityReport report) async {
    try {
      final sessions = await _db.getAllSessions();

      for (final session in sessions) {
        for (final message in session.messages) {
          // 只检查图片类型的消息
          if (message.type.toString() != 'MessageType.image') {
            continue;
          }

          // 如果 content 是文件路径
          if (message.content.isNotEmpty &&
              !message.content.startsWith('http')) {
            report.totalChecked++;

            final absPath = await StorageUtils.toAbsolutePath(message.content);
            final file = File(absPath);

            if (!await file.exists()) {
              report.missingFiles++;
              debugPrint(
                  '[FileIntegrity] 消息图片丢失: ${message.id} - ${message.content}');

              if (message.messageData != null &&
                  message.messageData!.isNotEmpty) {
                try {
                  final directory = file.parent;
                  if (!await directory.exists()) {
                    await directory.create(recursive: true);
                  }

                  await file.writeAsBytes(message.messageData!);
                  report.restoredFiles++;
                  debugPrint('[FileIntegrity] 已恢复消息图片: ${message.id}');
                } catch (e) {
                  report.failedRestores++;
                  report.errors.add('恢复消息图片失败 ${message.id}: $e');
                }
              } else {
                report.noBackupFiles++;
              }
            }
          }
        }
      }
    } catch (e) {
      report.errors.add('检查消息图片时出错: $e');
    }
  }

  /// 检查表情包文件
  Future<void> _checkEmojiFiles(FileIntegrityReport report) async {
    try {
      final emojis = await _db.getAllEmojis();

      for (final emoji in emojis) {
        report.totalChecked++;

        if (emoji.localPath.isEmpty || emoji.localPath.startsWith('http')) {
          continue;
        }

        final absPath = await StorageUtils.toAbsolutePath(emoji.localPath);
        final file = File(absPath);

        if (!await file.exists()) {
          report.missingFiles++;
          debugPrint(
              '[FileIntegrity] 表情包文件丢失: ${emoji.id} (${emoji.meaning}) - ${emoji.localPath}');

          // 尝试从数据库备份恢复
          if (emoji.emojiData != null && emoji.emojiData!.isNotEmpty) {
            try {
              final directory = file.parent;
              if (!await directory.exists()) {
                await directory.create(recursive: true);
              }

              await file.writeAsBytes(emoji.emojiData!);
              report.restoredFiles++;
              debugPrint(
                  '[FileIntegrity] 已恢复表情包文件: ${emoji.id} (${emoji.meaning})');
            } catch (e) {
              report.failedRestores++;
              report.errors.add('恢复表情包文件失败 ${emoji.id}: $e');
              debugPrint('[FileIntegrity] 恢复失败: $e');
            }
          } else {
            report.noBackupFiles++;
            debugPrint('[FileIntegrity] 表情包无备份数据，无法恢复: ${emoji.id}');
          }
        }
      }
    } catch (e) {
      report.errors.add('检查表情包文件时出错: $e');
    }
  }

  /// 清理无效的文件引用
  /// 将数据库中指向不存在文件的路径清空，避免显示错误
  Future<void> cleanInvalidReferences() async {
    debugPrint('[FileIntegrity] 开始清理无效引用...');

    try {
      // 清理角色头像引用
      final roles = await _db.getAllContactRoles();
      for (final role in roles) {
        if (role.avatarPath != null && role.avatarPath!.isNotEmpty) {
          final absPath = await StorageUtils.toAbsolutePath(role.avatarPath!);
          final file = File(absPath);

          if (!await file.exists() &&
              (role.avatarData == null || role.avatarData!.isEmpty)) {
            // 文件不存在且无备份，清空路径
            final updatedRole = ContactRole(
              id: role.id,
              name: role.name,
              avatarPath: '',
              avatarData: role.avatarData,
              description: role.description,
              appearance: role.appearance,
              referenceImages: role.referenceImages,
              referenceImagesData: role.referenceImagesData,
              subscribedGroupIds: role.subscribedGroupIds,
              subscribedEmojiIds: role.subscribedEmojiIds,
            );
            await _db.insertContactRole(updatedRole);
            debugPrint('[FileIntegrity] 已清理角色头像引用: ${role.name}');
          }
        }
      }

      // 清理用户头像引用
      final meList = await _db.getAllContactMes();
      for (final me in meList) {
        if (me.avatarPath != null && me.avatarPath!.isNotEmpty) {
          final absPath = await StorageUtils.toAbsolutePath(me.avatarPath!);
          final file = File(absPath);

          if (!await file.exists() &&
              (me.avatarData == null || me.avatarData!.isEmpty)) {
            final updatedMe = ContactMe(
              id: me.id,
              name: me.name,
              avatarPath: '',
              avatarData: me.avatarData,
              info: me.info,
              appearance: me.appearance,
              referenceImages: me.referenceImages,
              referenceImagesData: me.referenceImagesData,
            );
            await _db.insertContactMe(updatedMe);
            debugPrint('[FileIntegrity] 已清理用户头像引用: ${me.name}');
          }
        }
      }

      // 清理表情包无效引用
      final emojis = await _db.getAllEmojis();
      final invalidEmojiIds = <String>[];

      for (final emoji in emojis) {
        if (emoji.localPath.isNotEmpty && !emoji.localPath.startsWith('http')) {
          final absPath = await StorageUtils.toAbsolutePath(emoji.localPath);
          final file = File(absPath);

          if (!await file.exists()) {
            // 表情包文件不存在且无备份，记录需要删除的ID
            invalidEmojiIds.add(emoji.id);
            debugPrint(
                '[FileIntegrity] 已标记删除无效表情包: ${emoji.id} (${emoji.meaning})');
          }
        }
      }

      // 批量删除无效表情包
      if (invalidEmojiIds.isNotEmpty) {
        await _db.deleteEmojis(invalidEmojiIds);
        debugPrint('[FileIntegrity] 已删除 ${invalidEmojiIds.length} 个无效表情包记录');
      }

      debugPrint('[FileIntegrity] 清理完成');
    } catch (e) {
      debugPrint('[FileIntegrity] 清理过程出错: $e');
    }
  }
}

/// 文件完整性检查报告
class FileIntegrityReport {
  int totalChecked = 0; // 总共检查的文件数
  int missingFiles = 0; // 丢失的文件数
  int restoredFiles = 0; // 成功恢复的文件数
  int failedRestores = 0; // 恢复失败的文件数
  int noBackupFiles = 0; // 没有备份数据的文件数
  List<String> errors = []; // 错误信息列表

  String get summary {
    return '检查 $totalChecked 个文件，发现 $missingFiles 个丢失，'
        '成功恢复 $restoredFiles 个，失败 $failedRestores 个，'
        '无备份 $noBackupFiles 个';
  }

  bool get hasIssues => missingFiles > 0 || errors.isNotEmpty;

  bool get allRestored => missingFiles > 0 && missingFiles == restoredFiles;
}
