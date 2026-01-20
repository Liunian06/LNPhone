import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/providers/contact_provider.dart';

class EditRoleScreen extends StatefulWidget {
  final String roleId;

  const EditRoleScreen({super.key, required this.roleId});

  @override
  State<EditRoleScreen> createState() => _EditRoleScreenState();
}

class _EditRoleScreenState extends State<EditRoleScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  String? _avatarPath;

  @override
  void initState() {
    super.initState();
    final provider = context.read<ContactProvider>();
    final role = provider.roles.firstWhere((r) => r.id == widget.roleId);
    _nameController = TextEditingController(text: role.name);
    _descriptionController = TextEditingController(text: role.description);
    _avatarPath = role.avatarPath;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _avatarPath = pickedFile.path;
      });
    }
  }

  void _showDeleteConfirmation() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBgColor = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dialogBgColor,
        title: Text('删除角色', style: TextStyle(color: textColor)),
        content: Text('确定要删除这个角色吗？',
            style: TextStyle(color: textColor.withOpacity(0.7))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消',
                style:
                    TextStyle(color: isDark ? Colors.grey[400] : Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              context.read<ContactProvider>().deleteRole(widget.roleId);
              Navigator.pop(context); // 关闭对话框
              Navigator.pop(context); // 返回列表
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBgColor =
        isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF5F5F5);
    final cardBgColor = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final hintColor = isDark ? Colors.grey[400] : Colors.grey;
    final inputBgColor =
        isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF7F8FA);
    final avatarPlaceholderBgColor =
        isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF0F0F0);

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      appBar: AppBar(
        backgroundColor: cardBgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '编辑角色',
          style: TextStyle(
            color: textColor,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 24),
            onPressed: _showDeleteConfirmation,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 头像卡片
            Container(
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              child: Column(
                children: [
                  Text(
                    '头像',
                    style: TextStyle(
                      fontSize: 16,
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: avatarPlaceholderBgColor,
                            image: _avatarPath != null
                                ? DecorationImage(
                                    image: FileImage(File(_avatarPath!)),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withOpacity(isDark ? 0.2 : 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: _avatarPath == null
                              ? Center(
                                  child: Text(
                                    'A',
                                    style: TextStyle(
                                      fontSize: 40,
                                      color: isDark
                                          ? Colors.grey[600]
                                          : const Color(0xFFB0B0B0),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: cardBgColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withOpacity(isDark ? 0.3 : 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              size: 16,
                              color: isDark ? Colors.grey[400] : Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // 姓名卡片
            Container(
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '姓名',
                    style: TextStyle(
                      fontSize: 16,
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: inputBgColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF48484A)
                            : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: '输入姓名',
                        hintStyle: TextStyle(color: hintColor),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                        filled: false,
                        isDense: true,
                      ),
                      style: TextStyle(fontSize: 16, color: textColor),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入角色姓名';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // 人设卡片
            Container(
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '人设',
                    style: TextStyle(
                      fontSize: 16,
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: inputBgColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF48484A)
                            : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        hintText: '输入人物设定',
                        hintStyle: TextStyle(color: hintColor),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                        filled: false,
                        isDense: true,
                      ),
                      style: TextStyle(fontSize: 16, color: textColor),
                      maxLines: 5,
                      minLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入角色人设';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // 保存按钮
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    try {
                      await context.read<ContactProvider>().updateRole(
                            widget.roleId,
                            _nameController.text,
                            _avatarPath,
                            _descriptionController.text,
                          );
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('保存失败: $e')),
                        );
                      }
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF07C160),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  '保存',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
