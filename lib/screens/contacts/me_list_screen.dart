import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../core/providers/contact_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/storage_utils.dart';
import 'edit_me_screen.dart';
import 'add_me_screen.dart';

/// 用户人设列表界面
class MeListScreen extends StatelessWidget {
  const MeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.chatBackground,
      appBar: AppBar(
        backgroundColor: context.appBarBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: context.primaryTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '我的人设',
          style: TextStyle(
            color: context.primaryTextColor,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: context.primaryTextColor, size: 26),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddMeScreen()),
              );
            },
            tooltip: '添加人设',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Consumer<ContactProvider>(
        builder: (context, provider, _) {
          if (provider.meList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.person,
                    size: 64,
                    color: context.secondaryTextColor.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '暂无人设',
                    style: TextStyle(
                      color: context.secondaryTextColor,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '点击右上角添加新人设',
                    style: TextStyle(
                      color: context.secondaryTextColor.withOpacity(0.7),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const AddMeScreen()),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('创建人设'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.wechatGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.meList.length,
            itemBuilder: (context, index) {
              final me = provider.meList[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: context.isDarkMode
                            ? Colors.black.withOpacity(0.3)
                            : Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditMeScreen(meId: me.id),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 头像
                            me.avatarPath != null && me.avatarPath!.isNotEmpty
                                ? FutureBuilder<String>(
                                    future: StorageUtils.ensureFileExists(
                                      me.avatarPath!,
                                      backupData: me.avatarData,
                                    ),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return Container(
                                          width: 56,
                                          height: 56,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: context.isDarkMode
                                                ? Colors.grey[700]
                                                : const Color(0xFFF0F0F0),
                                          ),
                                          child: Center(
                                            child: SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(
                                                  context.secondaryTextColor,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }

                                      final avatarPath =
                                          snapshot.data ?? me.avatarPath!;
                                      final file = File(avatarPath);

                                      return Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: context.isDarkMode
                                              ? Colors.grey[700]
                                              : const Color(0xFFF0F0F0),
                                        ),
                                        child: file.existsSync()
                                            ? ClipOval(
                                                child: Image.file(
                                                  file,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error,
                                                      stackTrace) {
                                                    return Center(
                                                      child: Text(
                                                        me.name.isNotEmpty
                                                            ? me.name[0]
                                                            : 'M',
                                                        style: TextStyle(
                                                          fontSize: 24,
                                                          color: context
                                                              .secondaryTextColor,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              )
                                            : Center(
                                                child: Text(
                                                  me.name.isNotEmpty
                                                      ? me.name[0]
                                                      : 'M',
                                                  style: TextStyle(
                                                    fontSize: 24,
                                                    color: context
                                                        .secondaryTextColor,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                      );
                                    },
                                  )
                                : Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: context.isDarkMode
                                          ? Colors.grey[700]
                                          : const Color(0xFFF0F0F0),
                                    ),
                                    child: Center(
                                      child: Text(
                                        me.name.isNotEmpty ? me.name[0] : 'M',
                                        style: TextStyle(
                                          fontSize: 24,
                                          color: context.secondaryTextColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                            const SizedBox(width: 12),
                            // 信息
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    me.name,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: context.primaryTextColor,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    me.info,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: context.secondaryTextColor,
                                      height: 1.4,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            // 箭头
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: context.secondaryTextColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
