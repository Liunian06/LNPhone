import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../core/providers/contact_provider.dart';
import '../../core/models/contact_model.dart';
import '../../core/theme/app_theme.dart';
import 'add_role_screen.dart';
import 'edit_role_screen.dart';

class RolesTab extends StatelessWidget {
  const RolesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ContactProvider>();

    return Scaffold(
      backgroundColor: context.chatBackground,
      appBar: AppBar(
        backgroundColor: context.chatBackground,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          '通讯录',
          style: TextStyle(
            color: context.primaryTextColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: context.primaryTextColor),
            onPressed: () {},
          ),
          IconButton(
            icon:
                Icon(Icons.add_circle_outline, color: context.primaryTextColor),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddRoleScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: provider.roles.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.person_2,
                    size: 64,
                    color: context.secondaryTextColor.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '暂无联系人',
                    style: TextStyle(
                        color: context.secondaryTextColor, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '点击右上角 + 号添加',
                    style: TextStyle(
                        color: context.secondaryTextColor.withOpacity(0.7),
                        fontSize: 13),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: provider.roles.length,
                    itemBuilder: (context, index) {
                      final role = provider.roles[index];
                      return _buildContactItem(context, role);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildContactItem(BuildContext context, ContactRole role) {
    return Material(
      color: context.surfaceColor,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditRoleScreen(roleId: role.id),
            ),
          );
        },
        child: Row(
          children: [
            // 头像区域
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 10.0,
              ),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: context.isDarkMode
                      ? Colors.grey[700]
                      : const Color(0xFFF0F0F0),
                  image: role.avatarPath != null
                      ? DecorationImage(
                          image: FileImage(File(role.avatarPath!)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: role.avatarPath == null
                    ? Center(
                        child: Text(
                          role.name.isNotEmpty ? role.name[0] : 'U',
                          style: TextStyle(
                            fontSize: 20,
                            color: context.secondaryTextColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
            // 内容区域
            Expanded(
              child: Container(
                padding: const EdgeInsets.only(right: 16, top: 16, bottom: 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: context.dividerColor, width: 0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role.name,
                      style: TextStyle(
                        fontSize: 17,
                        color: context.primaryTextColor,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
