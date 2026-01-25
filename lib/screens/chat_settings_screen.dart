import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../core/providers/chat_provider.dart';
import '../core/database/database.dart';
import '../core/models/world_info_model.dart';
import '../core/models/text_preset_model.dart';
import '../core/models/api_preset.dart';

class ChatSettingsScreen extends StatefulWidget {
  final String chatId;

  const ChatSettingsScreen({super.key, required this.chatId});

  @override
  State<ChatSettingsScreen> createState() => _ChatSettingsScreenState();
}

class _ChatSettingsScreenState extends State<ChatSettingsScreen> {
  List<WorldInfo> _allWorldInfos = [];
  List<TextPreset> _allTextPresets = [];
  List<ApiPreset> _allApiPresets = [];
  bool _isLoadingData = true;
  final AppDatabase _db = AppDatabase();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoadingData = true);
    try {
      // 并行加载数据,提高效率
      final results = await Future.wait([
        _db.getAllWorldInfos(),
        _db.getAllTextPresets(),
        _db.getAllApiPresetsFromDb(), // 使用正确的数据库方法
      ]);

      if (mounted) {
        setState(() {
          _allWorldInfos = results[0] as List<WorldInfo>;
          _allTextPresets = results[1] as List<TextPreset>;
          _allApiPresets = results[2] as List<ApiPreset>;
          _isLoadingData = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading chat settings data: $e');
      if (mounted) {
        setState(() => _isLoadingData = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF111111) : const Color(0xFFEDEDED);
    final textColor = isDark ? Colors.white : Colors.black;
    final subtitleColor = isDark ? Colors.white70 : Colors.black87;
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '聊天设置',
          style: TextStyle(
            color: textColor,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          final chat = chatProvider.getChat(widget.chatId);

          if (chat == null) {
            return Center(
                child: Text('聊天不存在', style: TextStyle(color: textColor)));
          }

          if (_isLoadingData) {
            return Center(child: CupertinoActivityIndicator(color: textColor));
          }

          return ListView(
            children: [
              const SizedBox(height: 10),
              // 扩展聊天设置
              _buildSettingItem(
                isDark: isDark,
                child: SwitchListTile(
                  title: Text(
                    '启用扩展聊天',
                    style: TextStyle(
                        fontSize: 16,
                        color: textColor,
                        fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '开启后将显示角色的动作和想法',
                    style: TextStyle(fontSize: 13, color: subtitleColor),
                  ),
                  value: chat.enableExtendedChat,
                  activeColor: const Color(0xFF07C160),
                  onChanged: (value) async {
                    await chatProvider.updateChatSettings(
                      widget.chatId,
                      enableExtendedChat: value,
                    );
                  },
                ),
              ),
              _buildSettingItem(
                isDark: isDark,
                child: SwitchListTile(
                  title: Text(
                    '启用文生图',
                    style: TextStyle(
                        fontSize: 16,
                        color: textColor,
                        fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '开启后角色可以发送图片（需要配置生图模型）',
                    style: TextStyle(fontSize: 13, color: subtitleColor),
                  ),
                  value: chat.enableTextToImage,
                  activeColor: const Color(0xFF07C160),
                  onChanged: (value) async {
                    await chatProvider.updateChatSettings(
                      widget.chatId,
                      enableTextToImage: value,
                    );
                  },
                ),
              ),
              _buildSettingItem(
                isDark: isDark,
                child: SwitchListTile(
                  title: Text(
                    '启用独立发送/续写按钮',
                    style: TextStyle(
                        fontSize: 16,
                        color: textColor,
                        fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '开启后将在输入框右侧显示独立的发送/续写按钮',
                    style: TextStyle(fontSize: 13, color: subtitleColor),
                  ),
                  value: chat.enableIndependentSendButton,
                  activeColor: const Color(0xFF07C160),
                  onChanged: (value) async {
                    await chatProvider.updateChatSettings(
                      widget.chatId,
                      enableIndependentSendButton: value,
                    );
                  },
                ),
              ),

              _buildSectionTitle('API 设置', isDark),
              _buildSettingItem(
                isDark: isDark,
                child: ListTile(
                  title: Text(
                    '独立 API 预设',
                    style: TextStyle(
                        fontSize: 16,
                        color: textColor,
                        fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    chat.apiPresetId == null
                        ? '使用全局默认'
                        : _getApiPresetName(chat.apiPresetId!),
                    style: TextStyle(fontSize: 13, color: subtitleColor),
                  ),
                  trailing:
                      Icon(Icons.arrow_forward_ios, size: 16, color: textColor),
                  onTap: () => _showApiPresetSelector(
                      context, chatProvider, chat.apiPresetId, isDark),
                ),
              ),

              _buildSectionTitle('世界书 (World Info)', isDark),
              _buildSettingItem(
                isDark: isDark,
                child: ListTile(
                  title: Text(
                    '选择世界书',
                    style: TextStyle(
                        fontSize: 16,
                        color: textColor,
                        fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    chat.worldInfoIds.isEmpty
                        ? '未选择'
                        : '已选择 ${chat.worldInfoIds.length} 个',
                    style: TextStyle(fontSize: 13, color: subtitleColor),
                  ),
                  trailing:
                      Icon(Icons.arrow_forward_ios, size: 16, color: textColor),
                  onTap: () => _showWorldInfoSelector(
                      context, chatProvider, chat.worldInfoIds, isDark),
                ),
              ),

              _buildSectionTitle('预设 (Presets)', isDark),
              _buildSettingItem(
                isDark: isDark,
                child: ListTile(
                  title: Text(
                    '选择预设',
                    style: TextStyle(
                        fontSize: 16,
                        color: textColor,
                        fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    chat.textPresetIds.isEmpty
                        ? '未选择'
                        : '已选择 ${chat.textPresetIds.length} 个',
                    style: TextStyle(fontSize: 13, color: subtitleColor),
                  ),
                  trailing:
                      Icon(Icons.arrow_forward_ios, size: 16, color: textColor),
                  onTap: () => _showTextPresetSelector(
                      context, chatProvider, chat.textPresetIds, isDark),
                ),
              ),

              _buildSectionTitle('外观设置', isDark),
              _buildSettingItem(
                isDark: isDark,
                child: ListTile(
                  title: Text(
                    '聊天背景图',
                    style: TextStyle(
                        fontSize: 16,
                        color: textColor,
                        fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    chat.backgroundImage != null ? '已设置' : '未设置',
                    style: TextStyle(fontSize: 13, color: subtitleColor),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (chat.backgroundImage != null)
                        Container(
                          width: 40,
                          height: 40,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            image: DecorationImage(
                              image: FileImage(File(chat.backgroundImage!)),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      Icon(Icons.arrow_forward_ios, size: 16, color: textColor),
                    ],
                  ),
                  onTap: () => _showBackgroundImageOptions(
                      context, chatProvider, chat.backgroundImage, isDark),
                ),
              ),

              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSettingItem({required Widget child, required bool isDark}) {
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    return Container(
      color: cardColor,
      child: child,
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    final textColor = isDark ? Colors.white70 : Colors.black87;
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8, top: 20),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          color: textColor,
        ),
      ),
    );
  }

  String _getApiPresetName(String id) {
    try {
      final preset = _allApiPresets.firstWhere((p) => p.id == id);
      return preset.name;
    } catch (e) {
      return '未知预设';
    }
  }

  void _showApiPresetSelector(
    BuildContext context,
    ChatProvider provider,
    String? currentId,
    bool isDark,
  ) {
    final bgColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtitleColor = isDark ? Colors.white70 : Colors.black87;

    showModalBottomSheet(
      context: context,
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (context) {
        return Container(
          height: 400,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '选择 API 预设',
                style: TextStyle(fontSize: 18, color: textColor),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    ListTile(
                      title: Text('使用全局默认', style: TextStyle(color: textColor)),
                      trailing: currentId == null
                          ? const Icon(Icons.check, color: Color(0xFF07C160))
                          : null,
                      onTap: () {
                        provider.updateChatConfig(widget.chatId,
                            apiPresetId: null);
                        Navigator.pop(context);
                      },
                    ),
                    Divider(color: isDark ? Colors.white24 : Colors.black12),
                    ..._allApiPresets.map((preset) {
                      final isSelected = currentId == preset.id;
                      return ListTile(
                        title: Text(preset.name,
                            style: TextStyle(color: textColor)),
                        subtitle: Text(
                            '${preset.provider.name} - ${preset.model}',
                            style: TextStyle(color: subtitleColor)),
                        trailing: isSelected
                            ? const Icon(Icons.check, color: Color(0xFF07C160))
                            : null,
                        onTap: () {
                          provider.updateChatConfig(widget.chatId,
                              apiPresetId: preset.id);
                          Navigator.pop(context);
                        },
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showWorldInfoSelector(
    BuildContext context,
    ChatProvider provider,
    List<String> currentIds,
    bool isDark,
  ) {
    final selectedIds = List<String>.from(currentIds);
    final bgColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtitleColor = isDark ? Colors.white70 : Colors.black87;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '选择世界书',
                        style: TextStyle(fontSize: 18, color: textColor),
                      ),
                      TextButton(
                        onPressed: () {
                          provider.updateChatConfig(widget.chatId,
                              worldInfoIds: selectedIds);
                          Navigator.pop(context);
                        },
                        child: const Text('完成', style: TextStyle(fontSize: 16)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _allWorldInfos.isEmpty
                        ? Center(
                            child: Text('暂无世界书',
                                style: TextStyle(color: textColor)))
                        : ListView.builder(
                            itemCount: _allWorldInfos.length,
                            itemBuilder: (context, index) {
                              final info = _allWorldInfos[index];
                              final isSelected = selectedIds.contains(info.id);
                              return CheckboxListTile(
                                title: Text(info.name,
                                    style: TextStyle(color: textColor)),
                                subtitle: Text(
                                  info.content,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: subtitleColor),
                                ),
                                value: isSelected,
                                activeColor: const Color(0xFF07C160),
                                checkColor: Colors.white,
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      selectedIds.add(info.id);
                                    } else {
                                      selectedIds.remove(info.id);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showTextPresetSelector(
    BuildContext context,
    ChatProvider provider,
    List<String> currentIds,
    bool isDark,
  ) {
    final selectedIds = List<String>.from(currentIds);
    final bgColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtitleColor = isDark ? Colors.white70 : Colors.black87;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '选择预设',
                        style: TextStyle(fontSize: 18, color: textColor),
                      ),
                      TextButton(
                        onPressed: () {
                          provider.updateChatConfig(widget.chatId,
                              textPresetIds: selectedIds);
                          Navigator.pop(context);
                        },
                        child: const Text('完成', style: TextStyle(fontSize: 16)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _allTextPresets.isEmpty
                        ? Center(
                            child: Text('暂无预设',
                                style: TextStyle(color: textColor)))
                        : ListView.builder(
                            itemCount: _allTextPresets.length,
                            itemBuilder: (context, index) {
                              final preset = _allTextPresets[index];
                              final isSelected =
                                  selectedIds.contains(preset.id);
                              return CheckboxListTile(
                                title: Text(preset.name,
                                    style: TextStyle(color: textColor)),
                                subtitle: Text(
                                  preset.content,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: subtitleColor),
                                ),
                                value: isSelected,
                                activeColor: const Color(0xFF07C160),
                                checkColor: Colors.white,
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      selectedIds.add(preset.id);
                                    } else {
                                      selectedIds.remove(preset.id);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// 显示背景图设置选项
  void _showBackgroundImageOptions(
    BuildContext context,
    ChatProvider provider,
    String? currentImage,
    bool isDark,
  ) {
    final bgColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    showModalBottomSheet(
      context: context,
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '聊天背景图',
                style: TextStyle(fontSize: 18, color: textColor),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.photo_library, color: textColor),
                title: Text('从相册选择', style: TextStyle(color: textColor)),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickBackgroundImage(provider);
                },
              ),
              if (currentImage != null) ...[
                Divider(color: isDark ? Colors.white24 : Colors.black12),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title:
                      const Text('移除背景图', style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    Navigator.pop(context);
                    await provider.updateChatBackgroundImage(
                        widget.chatId, null);
                  },
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  /// 从相册选择背景图
  Future<void> _pickBackgroundImage(ChatProvider provider) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      // 将图片复制到应用文档目录，确保持久化
      final appDocDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ext = path.extension(pickedFile.path);
      final newFileName = 'chat_bg_${widget.chatId}_$timestamp$ext';
      final newPath = path.join(appDocDir.path, newFileName);

      // 复制文件
      final sourceFile = File(pickedFile.path);
      await sourceFile.copy(newPath);

      // 更新数据库
      await provider.updateChatBackgroundImage(widget.chatId, newPath);
    } catch (e) {
      debugPrint('Error picking background image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择图片失败: $e')),
        );
      }
    }
  }
}
