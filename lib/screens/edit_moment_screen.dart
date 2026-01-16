import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/models/moments_model.dart';
import '../core/models/contact_model.dart';
import '../core/providers/moments_provider.dart';
import '../core/providers/contact_provider.dart';

/// 编辑/发布朋友圈界面
class EditMomentScreen extends StatefulWidget {
  const EditMomentScreen({super.key});

  @override
  State<EditMomentScreen> createState() => _EditMomentScreenState();
}

class _EditMomentScreenState extends State<EditMomentScreen> {
  final TextEditingController _contentController = TextEditingController();
  final List<String> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  final int _maxImages = 9;

  // 位置、提醒、可见性设置
  String? _location;
  List<ContactRole> _mentionedRoles = [];
  List<ContactRole> _visibleToRoles = [];
  List<ContactRole>? _lastGroupRoles;

  @override
  void initState() {
    super.initState();
    _loadLastGroup();
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  /// 加载上次分组设置
  Future<void> _loadLastGroup() async {
    final prefs = await SharedPreferences.getInstance();
    final lastGroupIds = prefs.getStringList('last_moment_visible_group');

    if (lastGroupIds != null && lastGroupIds.isNotEmpty && mounted) {
      final contactProvider = context.read<ContactProvider>();
      setState(() {
        _lastGroupRoles = lastGroupIds
            .map(
              (id) =>
                  contactProvider.roles.where((r) => r.id == id).firstOrNull,
            )
            .whereType<ContactRole>()
            .toList();
      });
    }
  }

  /// 保存当前分组设置
  Future<void> _saveLastGroup() async {
    if (_visibleToRoles.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        'last_moment_visible_group',
        _visibleToRoles.map((r) => r.id).toList(),
      );
    }
  }

  /// 应用上次分组
  void _applyLastGroup() {
    if (_lastGroupRoles != null && _lastGroupRoles!.isNotEmpty) {
      setState(() {
        _visibleToRoles = List.from(_lastGroupRoles!);
      });
    }
  }

  /// 选择图片
  Future<void> _pickImages() async {
    if (_selectedImages.length >= _maxImages) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('最多只能选择$_maxImages张图片')));
      return;
    }

    final List<XFile> images = await _picker.pickMultiImage();

    if (images.isNotEmpty) {
      final remainingSlots = _maxImages - _selectedImages.length;

      setState(() {
        final imagesToAdd = images
            .take(remainingSlots)
            .map((e) => e.path)
            .toList();
        _selectedImages.addAll(imagesToAdd);
      });

      if (images.length > remainingSlots) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已达到最大图片数量($_maxImages张)，部分图片未添加')),
        );
      }
    }
  }

  /// 拍照
  Future<void> _takePhoto() async {
    if (_selectedImages.length >= _maxImages) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('最多只能选择$_maxImages张图片')));
      return;
    }

    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);

    if (photo != null) {
      setState(() {
        _selectedImages.add(photo.path);
      });
    }
  }

  /// 删除图片
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  /// 发布朋友圈
  void _publishMoment() async {
    final content = _contentController.text.trim();

    // 内容和图片都为空时不允许发布
    if (content.isEmpty && _selectedImages.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入内容或选择图片')));
      return;
    }

    final momentsProvider = context.read<MomentsProvider>();

    // 创建媒体列表
    final mediaItems = _selectedImages
        .map((path) => MediaItem(url: path, type: MediaType.image))
        .toList();

    // 保存当前可见性设置为上次分组
    await _saveLastGroup();

    // 发布朋友圈
    await momentsProvider.publishPost(
      content: content.isEmpty ? null : content,
      mediaItems: mediaItems,
      location: _location,
    );

    // 返回上一页
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('发布成功')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDEDED),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEDEDED),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '发表',
          style: TextStyle(
            color: Colors.black,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _publishMoment,
            child: const Text(
              '发表',
              style: TextStyle(
                color: Color(0xFF07C160),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 文本输入区域
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _contentController,
                  maxLines: null,
                  minLines: 5,
                  decoration: const InputDecoration(
                    hintText: '这一刻的想法...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 17),
                  ),
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 17,
                    height: 1.4,
                  ),
                ),
              ),

              // 图片网格（几乎没有间距）
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: _buildImageGrid(),
              ),

              const SizedBox(height: 8),

              // 分隔线
              const Divider(height: 1, thickness: 0.5),

              // 所在位置
              _buildLocationOption(),

              const Divider(height: 1, thickness: 0.5),

              // 提醒谁看
              _buildMentionOption(),

              const Divider(height: 1, thickness: 0.5),

              // 谁可以看
              _buildVisibilityOption(),

              // 上次分组（如果有的话）
              if (_lastGroupRoles != null && _lastGroupRoles!.isNotEmpty) ...[
                const Divider(height: 1, thickness: 0.5),
                _buildLastGroupOption(),
              ],

              const SizedBox(height: 100), // 留出空间避免被键盘遮挡
            ],
          ),
        ),
      ),
    );
  }

  /// 构建图片网格
  Widget _buildImageGrid() {
    final totalItems = _selectedImages.length < _maxImages
        ? _selectedImages.length + 1
        : _selectedImages.length;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: totalItems,
      itemBuilder: (context, index) {
        if (index == _selectedImages.length &&
            _selectedImages.length < _maxImages) {
          return _buildAddImageButton();
        }
        return _buildImageItem(index);
      },
    );
  }

  /// 构建图片项
  Widget _buildImageItem(int index) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.file(File(_selectedImages[index]), fit: BoxFit.cover),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  /// 构建添加图片按钮
  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFE5E5E5)),
        ),
        child: const Icon(Icons.add, size: 40, color: Colors.grey),
      ),
    );
  }

  /// 构建位置选项
  Widget _buildLocationOption() {
    return ListTile(
      leading: const Icon(Icons.location_on_outlined),
      title: Text(
        _location ?? '所在位置',
        style: TextStyle(
          color: _location == null ? Colors.black : const Color(0xFF576B95),
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
      onTap: _showLocationInput,
    );
  }

  /// 构建提醒谁看选项
  Widget _buildMentionOption() {
    return ListTile(
      leading: const Icon(Icons.alternate_email),
      title: Text(
        _mentionedRoles.isEmpty
            ? '提醒谁看'
            : _mentionedRoles.map((r) => r.name).join('、'),
        style: TextStyle(
          color: _mentionedRoles.isEmpty
              ? Colors.black
              : const Color(0xFF576B95),
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
      onTap: _showMentionSelector,
    );
  }

  /// 构建可见性选项
  Widget _buildVisibilityOption() {
    String displayText;
    if (_visibleToRoles.isEmpty) {
      displayText = '公开';
    } else {
      displayText = _visibleToRoles.map((r) => r.name).join('、');
    }

    return ListTile(
      leading: const Icon(Icons.person_outline),
      title: const Text('谁可以看', style: TextStyle(color: Colors.black)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            displayText,
            style: const TextStyle(color: Colors.grey, fontSize: 15),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ],
      ),
      onTap: _showVisibilitySelector,
    );
  }

  /// 构建上次分组选项
  Widget _buildLastGroupOption() {
    final groupNames = _lastGroupRoles!.map((r) => r.name).join('、');

    return InkWell(
      onTap: _applyLastGroup,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          '上次分组: $groupNames',
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
      ),
    );
  }

  /// 显示位置输入
  void _showLocationInput() {
    final controller = TextEditingController(text: _location);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('输入位置'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: '请输入位置信息'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _location = controller.text.trim().isEmpty
                      ? null
                      : controller.text.trim();
                });
                Navigator.pop(context);
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  /// 显示提醒谁看选择器
  void _showMentionSelector() {
    final contactProvider = context.read<ContactProvider>();
    final tempSelected = List<ContactRole>.from(_mentionedRoles);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('提醒谁看'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: contactProvider.roles.length,
                  itemBuilder: (context, index) {
                    final role = contactProvider.roles[index];
                    final isSelected = tempSelected.any((r) => r.id == role.id);

                    return CheckboxListTile(
                      title: Text(role.name),
                      value: isSelected,
                      onChanged: (value) {
                        setDialogState(() {
                          if (value == true) {
                            tempSelected.add(role);
                          } else {
                            tempSelected.removeWhere((r) => r.id == role.id);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _mentionedRoles = tempSelected;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('确定'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// 显示可见性选择器
  void _showVisibilitySelector() {
    final contactProvider = context.read<ContactProvider>();
    final tempSelected = List<ContactRole>.from(_visibleToRoles);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('谁可以看'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: const Text('公开'),
                      trailing: tempSelected.isEmpty
                          ? const Icon(Icons.check, color: Color(0xFF07C160))
                          : null,
                      onTap: () {
                        setDialogState(() {
                          tempSelected.clear();
                        });
                      },
                    ),
                    const Divider(),
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        '或选择特定角色可见：',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: contactProvider.roles.length,
                        itemBuilder: (context, index) {
                          final role = contactProvider.roles[index];
                          final isSelected = tempSelected.any(
                            (r) => r.id == role.id,
                          );

                          return CheckboxListTile(
                            title: Text(role.name),
                            value: isSelected,
                            onChanged: (value) {
                              setDialogState(() {
                                if (value == true) {
                                  tempSelected.add(role);
                                } else {
                                  tempSelected.removeWhere(
                                    (r) => r.id == role.id,
                                  );
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _visibleToRoles = tempSelected;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('确定'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// 显示图片来源选择对话框
  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('从相册选择'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImages();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('拍照'),
                  onTap: () {
                    Navigator.pop(context);
                    _takePhoto();
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text(
                    '取消',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
