import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../core/providers/contact_provider.dart';
import '../../core/models/contact_model.dart'; // 需要导入模型以便类型检查
import 'add_role_screen.dart';
import 'edit_role_screen.dart';

class RolesTab extends StatelessWidget {
  const RolesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ContactProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFEDEDED), // 微信背景灰
      appBar: AppBar(
        backgroundColor: const Color(0xFFEDEDED),
        elevation: 0,
        automaticallyImplyLeading: false, // 移除返回按钮
        title: const Text(
          '通讯录',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.black),
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
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '暂无联系人',
                    style: TextStyle(color: Colors.grey[400], fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '点击右上角 + 号添加',
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // 您可以在这里添加 "新的朋友"、"群聊"、"标签"、"公众号" 等固定头部项
                Expanded(
                  child: ListView.builder(
                    itemCount: provider.roles.length,
                    itemBuilder: (context, index) {
                      final role = provider.roles[index];
                      // 检查是否是最后一个元素来决定是否显示分割线
                      // 在微信中，通常列表项本身有分割线，或者容器有下边框
                      // 我们这里使用 Container 的 decoration
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
      color: Colors.white,
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
                  borderRadius: BorderRadius.circular(4), // 微信风格圆角方形
                  color: const Color(0xFFF0F0F0),
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
                          style: const TextStyle(
                            fontSize: 20,
                            color: Color(0xFFB0B0B0),
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
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFEDEDED), width: 0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role.name,
                      style: const TextStyle(
                        fontSize: 17,
                        color: Colors.black,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // 如果有描述，也可以稍微显示一点，或者不显示，微信通讯录列表通常只显示名字
                    // if (role.description.isNotEmpty)
                    //   Padding(
                    //     padding: const EdgeInsets.only(top: 2.0),
                    //     child: Text(
                    //       role.description,
                    //       style: const TextStyle(
                    //         fontSize: 13,
                    //         color: Colors.grey,
                    //       ),
                    //       maxLines: 1,
                    //       overflow: TextOverflow.ellipsis,
                    //     ),
                    //   ),
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
