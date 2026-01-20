import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/models/memory_model.dart';
import '../core/models/contact_model.dart';
import '../core/providers/memory_provider.dart';
import '../core/providers/contact_provider.dart';
import '../core/utils/time_formatter.dart';

/// 记忆库 App 界面
/// 展示所有角色的记忆，支持按角色分组查看
class MemoryAppScreen extends StatefulWidget {
  const MemoryAppScreen({super.key});

  @override
  State<MemoryAppScreen> createState() => _MemoryAppScreenState();
}

class _MemoryAppScreenState extends State<MemoryAppScreen>
    with SingleTickerProviderStateMixin {
  MemoryCategory? _selectedCategory;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F5F7),
      appBar: _buildAppBar(context, isDark),
      body: Column(
        children: [
          _buildTabBar(isDark),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildByRoleView(context, isDark),
                _buildByCategoryView(context, isDark),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFab(context, isDark),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDark) {
    return AppBar(
      backgroundColor: isDark ? const Color(0xFF16213E) : Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: isDark ? Colors.white : Colors.black87,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF667EEA), const Color(0xFF764BA2)]
                    : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.psychology_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            '记忆库',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.search_rounded,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
          onPressed: () => _showSearchDialog(context),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildTabBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16213E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.grey).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF667EEA), const Color(0xFF764BA2)]
                : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(4),
        labelColor: Colors.white,
        unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: '按角色'),
          Tab(text: '按分类'),
        ],
      ),
    );
  }

  Widget _buildByRoleView(BuildContext context, bool isDark) {
    return Consumer2<MemoryProvider, ContactProvider>(
      builder: (context, memoryProvider, contactProvider, _) {
        final roles = contactProvider.roles;

        if (roles.isEmpty) {
          return _buildEmptyState(isDark, '还没有角色', '创建角色后即可在此查看记忆');
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: roles.length,
          itemBuilder: (context, index) {
            final role = roles[index];
            final memories = memoryProvider.getMemoriesForRole(role.id);
            return _buildRoleCard(context, role, memories, isDark);
          },
        );
      },
    );
  }

  Widget _buildRoleCard(
    BuildContext context,
    ContactRole role,
    List<RoleMemory> memories,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16213E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.grey).withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          // 导航到角色记忆详情页面
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RoleMemoryDetailScreen(role: role),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildAvatar(role, isDark),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role.name,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${memories.length} 条记忆',
                      style: TextStyle(
                        color: isDark ? Colors.white60 : Colors.black45,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? Colors.white60 : Colors.black45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(ContactRole role, bool isDark) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF667EEA), const Color(0xFF764BA2)]
              : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: role.avatarPath != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                role.avatarPath!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _buildAvatarPlaceholder(role.name),
              ),
            )
          : _buildAvatarPlaceholder(role.name),
    );
  }

  Widget _buildAvatarPlaceholder(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMemoryItem(
      BuildContext context, RoleMemory memory, bool isDark) {
    return Dismissible(
      key: Key(memory.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) {
        context.read<MemoryProvider>().deleteMemory(memory.id);
      },
      child: InkWell(
        onTap: () => _showEditMemoryDialog(context, memory),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.grey.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                memory.category.icon,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      memory.content,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(memory.category)
                                .withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            memory.category.displayName,
                            style: TextStyle(
                              color: _getCategoryColor(memory.category),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          TimeFormatter.formatRelative(memory.updatedAt),
                          style: TextStyle(
                            color: isDark ? Colors.white38 : Colors.black38,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildByCategoryView(BuildContext context, bool isDark) {
    return Consumer<MemoryProvider>(
      builder: (context, memoryProvider, _) {
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: MemoryCategory.values.length,
          itemBuilder: (context, index) {
            final category = MemoryCategory.values[index];
            return _buildCategoryCard(
                context, category, memoryProvider, isDark);
          },
        );
      },
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    MemoryCategory category,
    MemoryProvider provider,
    bool isDark,
  ) {
    // 获取该分类下的所有记忆
    final allMemories = <RoleMemory>[];
    final contactProvider = context.read<ContactProvider>();
    for (final role in contactProvider.roles) {
      final memories = provider.getMemoriesForRole(role.id);
      allMemories.addAll(memories.where((m) => m.category == category));
    }

    final isExpanded = _selectedCategory == category;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16213E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.grey).withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _selectedCategory = isExpanded ? null : category;
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getCategoryColor(category).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        category.icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.displayName,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${allMemories.length} 条记忆',
                          style: TextStyle(
                            color: isDark ? Colors.white60 : Colors.black45,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: isDark ? Colors.white60 : Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            Divider(
              color: isDark ? Colors.white12 : Colors.grey.shade200,
              height: 1,
            ),
            if (allMemories.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  '暂无此类记忆',
                  style: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(12),
                itemCount: allMemories.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final memory = allMemories[index];
                  final role = contactProvider.roles.firstWhere(
                    (r) => r.id == memory.roleId,
                    orElse: () => ContactRole(
                      id: '',
                      name: '未知角色',
                      description: '',
                    ),
                  );
                  return _buildMemoryItemWithRole(
                    context,
                    memory,
                    role,
                    isDark,
                  );
                },
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildMemoryItemWithRole(
    BuildContext context,
    RoleMemory memory,
    ContactRole role,
    bool isDark,
  ) {
    return Dismissible(
      key: Key(memory.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) {
        context.read<MemoryProvider>().deleteMemory(memory.id);
      },
      child: InkWell(
        onTap: () => _showEditMemoryDialog(context, memory),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.grey.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF667EEA), const Color(0xFF764BA2)]
                            : [
                                const Color(0xFF6366F1),
                                const Color(0xFF8B5CF6)
                              ],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        role.name.isNotEmpty ? role.name[0] : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    role.name,
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    TimeFormatter.formatRelative(memory.updatedAt),
                    style: TextStyle(
                      color: isDark ? Colors.white38 : Colors.black38,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                memory.content,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              Icons.psychology_outlined,
              size: 50,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.black38,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFab(BuildContext context, bool isDark) {
    return FloatingActionButton.extended(
      onPressed: () => _showAddMemoryDialog(context, null),
      backgroundColor:
          isDark ? const Color(0xFF667EEA) : const Color(0xFF6366F1),
      elevation: 8,
      icon: const Icon(Icons.add_rounded, color: Colors.white),
      label: const Text(
        '添加记忆',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }

  Color _getCategoryColor(MemoryCategory category) {
    switch (category) {
      case MemoryCategory.general:
        return Colors.blueGrey;
      case MemoryCategory.important:
        return Colors.amber;
      case MemoryCategory.preference:
        return Colors.pink;
      case MemoryCategory.relationship:
        return Colors.teal;
      case MemoryCategory.promise:
        return Colors.indigo;
      case MemoryCategory.secret:
        return Colors.purple;
      case MemoryCategory.time:
        return Colors.orange;
      case MemoryCategory.location:
        return Colors.green;
      case MemoryCategory.task:
        return Colors.blue;
      case MemoryCategory.item:
        return Colors.deepOrange;
    }
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这条记忆吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showSearchDialog(BuildContext context) {
    showSearch(
      context: context,
      delegate: MemorySearchDelegate(),
    );
  }

  void _showAddMemoryDialog(BuildContext context, String? roleId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MemoryEditSheet(
        roleId: roleId,
        onSave: (content, category, selectedRoleId) {
          if (selectedRoleId != null) {
            context.read<MemoryProvider>().addMemory(
                  roleId: selectedRoleId,
                  content: content,
                  category: category,
                );
          }
        },
      ),
    );
  }

  void _showEditMemoryDialog(BuildContext context, RoleMemory memory) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MemoryEditSheet(
        memory: memory,
        roleId: memory.roleId,
        onSave: (content, category, _) {
          context.read<MemoryProvider>().updateMemory(
                id: memory.id,
                content: content,
                category: category,
              );
        },
      ),
    );
  }
}

/// 记忆编辑/添加底部弹窗
class MemoryEditSheet extends StatefulWidget {
  final RoleMemory? memory;
  final String? roleId;
  final Function(String content, MemoryCategory category, String? roleId)
      onSave;

  const MemoryEditSheet({
    super.key,
    this.memory,
    this.roleId,
    required this.onSave,
  });

  @override
  State<MemoryEditSheet> createState() => _MemoryEditSheetState();
}

class _MemoryEditSheetState extends State<MemoryEditSheet> {
  late TextEditingController _contentController;
  late MemoryCategory _selectedCategory;
  String? _selectedRoleId;

  @override
  void initState() {
    super.initState();
    _contentController =
        TextEditingController(text: widget.memory?.content ?? '');
    _selectedCategory = widget.memory?.category ?? MemoryCategory.general;
    _selectedRoleId = widget.roleId;
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(bottom: bottomPadding),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 拖动指示器
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // 标题
              Text(
                widget.memory != null ? '编辑记忆' : '添加记忆',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              // 选择角色（仅添加时显示）
              if (widget.memory == null && widget.roleId == null) ...[
                Text(
                  '选择角色',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Consumer<ContactProvider>(
                  builder: (context, contactProvider, _) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedRoleId,
                          hint: Text(
                            '请选择角色',
                            style: TextStyle(
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                          isExpanded: true,
                          dropdownColor:
                              isDark ? const Color(0xFF16213E) : Colors.white,
                          items: contactProvider.roles.map((role) {
                            return DropdownMenuItem(
                              value: role.id,
                              child: Text(
                                role.name,
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedRoleId = value;
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
              // 记忆内容
              Text(
                '记忆内容',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _contentController,
                maxLines: 4,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: '输入要记住的内容...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.grey.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // 分类选择
              Text(
                '分类',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: MemoryCategory.values.map((category) {
                  final isSelected = _selectedCategory == category;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _getCategoryColor(category)
                            : (isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.grey.withOpacity(0.1)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            category.icon,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            category.displayName,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? Colors.white70 : Colors.black54),
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              // 保存按钮
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _contentController.text.trim().isEmpty ||
                          (_selectedRoleId == null && widget.memory == null)
                      ? null
                      : () {
                          widget.onSave(
                            _contentController.text.trim(),
                            _selectedCategory,
                            _selectedRoleId ?? widget.roleId,
                          );
                          Navigator.pop(context);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? const Color(0xFF667EEA)
                        : const Color(0xFF6366F1),
                    disabledBackgroundColor:
                        isDark ? Colors.white12 : Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    '保存',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(MemoryCategory category) {
    switch (category) {
      case MemoryCategory.general:
        return Colors.blueGrey;
      case MemoryCategory.important:
        return Colors.amber;
      case MemoryCategory.preference:
        return Colors.pink;
      case MemoryCategory.relationship:
        return Colors.teal;
      case MemoryCategory.promise:
        return Colors.indigo;
      case MemoryCategory.secret:
        return Colors.purple;
      case MemoryCategory.time:
        return Colors.orange;
      case MemoryCategory.location:
        return Colors.green;
      case MemoryCategory.task:
        return Colors.blue;
      case MemoryCategory.item:
        return Colors.deepOrange;
    }
  }
}

/// 角色记忆详情页面
/// 展示单个角色的所有记忆，支持添加、编辑、批量删除、清空功能
class RoleMemoryDetailScreen extends StatefulWidget {
  final ContactRole role;

  const RoleMemoryDetailScreen({super.key, required this.role});

  @override
  State<RoleMemoryDetailScreen> createState() => _RoleMemoryDetailScreenState();
}

class _RoleMemoryDetailScreenState extends State<RoleMemoryDetailScreen> {
  bool _isMultiSelectMode = false;
  final Set<String> _selectedIds = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F5F7),
      appBar: _buildAppBar(context, isDark),
      body: Consumer<MemoryProvider>(
        builder: (context, memoryProvider, _) {
          final memories = memoryProvider.getMemoriesForRole(widget.role.id);

          if (memories.isEmpty) {
            return _buildEmptyState(isDark);
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: memories.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final memory = memories[index];
              return _buildMemoryItem(context, memory, isDark);
            },
          );
        },
      ),
      bottomNavigationBar:
          _isMultiSelectMode ? _buildMultiSelectBar(context, isDark) : null,
      floatingActionButton: _isMultiSelectMode
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showAddMemoryDialog(context),
              backgroundColor:
                  isDark ? const Color(0xFF667EEA) : const Color(0xFF6366F1),
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                '添加记忆',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDark) {
    if (_isMultiSelectMode) {
      return AppBar(
        backgroundColor: isDark ? const Color(0xFF16213E) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () {
            setState(() {
              _isMultiSelectMode = false;
              _selectedIds.clear();
            });
          },
        ),
        title: Text(
          '已选择 ${_selectedIds.length} 条',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 18,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              final memoryProvider = context.read<MemoryProvider>();
              final memories =
                  memoryProvider.getMemoriesForRole(widget.role.id);
              setState(() {
                if (_selectedIds.length == memories.length) {
                  _selectedIds.clear();
                } else {
                  _selectedIds.clear();
                  _selectedIds.addAll(memories.map((m) => m.id));
                }
              });
            },
            child: Text(
              '全选',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
        ],
      );
    }

    return AppBar(
      backgroundColor: isDark ? const Color(0xFF16213E) : Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: isDark ? Colors.white : Colors.black87,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          _buildSmallAvatar(isDark),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.role.name,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert_rounded,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
          onSelected: (value) {
            switch (value) {
              case 'multi_select':
                setState(() {
                  _isMultiSelectMode = true;
                });
                break;
              case 'clear_all':
                _showClearAllDialog(context);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'multi_select',
              child: Row(
                children: [
                  Icon(Icons.check_box_outlined, size: 20),
                  SizedBox(width: 12),
                  Text('批量选择'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'clear_all',
              child: Row(
                children: [
                  Icon(Icons.delete_sweep_rounded, size: 20, color: Colors.red),
                  SizedBox(width: 12),
                  Text('清空记忆', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSmallAvatar(bool isDark) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF667EEA), const Color(0xFF764BA2)]
              : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: widget.role.avatarPath != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                File(widget.role.avatarPath!),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: Text(
                    widget.role.name.isNotEmpty
                        ? widget.role.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            )
          : Center(
              child: Text(
                widget.role.name.isNotEmpty
                    ? widget.role.name[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
    );
  }

  Widget _buildMemoryItem(
      BuildContext context, RoleMemory memory, bool isDark) {
    final isSelected = _selectedIds.contains(memory.id);

    return InkWell(
      onTap: () {
        if (_isMultiSelectMode) {
          setState(() {
            if (isSelected) {
              _selectedIds.remove(memory.id);
            } else {
              _selectedIds.add(memory.id);
            }
          });
        } else {
          _showEditMemoryDialog(context, memory);
        }
      },
      onLongPress: () {
        if (!_isMultiSelectMode) {
          setState(() {
            _isMultiSelectMode = true;
            _selectedIds.add(memory.id);
          });
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? const Color(0xFF667EEA).withOpacity(0.2)
                  : const Color(0xFF6366F1).withOpacity(0.1))
              : (isDark ? const Color(0xFF16213E) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(
                  color: isDark
                      ? const Color(0xFF667EEA)
                      : const Color(0xFF6366F1),
                  width: 2,
                )
              : null,
          boxShadow: isSelected
              ? null
              : [
                  BoxShadow(
                    color:
                        (isDark ? Colors.black : Colors.grey).withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isMultiSelectMode) ...[
              Checkbox(
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedIds.add(memory.id);
                    } else {
                      _selectedIds.remove(memory.id);
                    }
                  });
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              memory.category.icon,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    memory.content,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(memory.category)
                              .withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          memory.category.displayName,
                          style: TextStyle(
                            color: _getCategoryColor(memory.category),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        TimeFormatter.formatRelative(memory.updatedAt),
                        style: TextStyle(
                          color: isDark ? Colors.white38 : Colors.black38,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!_isMultiSelectMode)
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? Colors.white24 : Colors.black26,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultiSelectBar(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16213E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildBarAction(
              icon: Icons.delete_rounded,
              label: '删除',
              color: Colors.red,
              onTap: _selectedIds.isEmpty
                  ? null
                  : () => _showDeleteSelectedDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarAction({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    final isDisabled = onTap == null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isDisabled ? Colors.grey : color,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isDisabled ? Colors.grey : color,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              Icons.psychology_outlined,
              size: 50,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '还没有记忆',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '与 ${widget.role.name} 对话时的重要信息会自动记录在这里',
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.black38,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(MemoryCategory category) {
    switch (category) {
      case MemoryCategory.general:
        return Colors.blueGrey;
      case MemoryCategory.important:
        return Colors.amber;
      case MemoryCategory.preference:
        return Colors.pink;
      case MemoryCategory.relationship:
        return Colors.teal;
      case MemoryCategory.promise:
        return Colors.indigo;
      case MemoryCategory.secret:
        return Colors.purple;
      case MemoryCategory.time:
        return Colors.orange;
      case MemoryCategory.location:
        return Colors.green;
      case MemoryCategory.task:
        return Colors.blue;
      case MemoryCategory.item:
        return Colors.deepOrange;
    }
  }

  void _showAddMemoryDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MemoryEditSheet(
        roleId: widget.role.id,
        onSave: (content, category, _) {
          context.read<MemoryProvider>().addMemory(
                roleId: widget.role.id,
                content: content,
                category: category,
              );
        },
      ),
    );
  }

  void _showEditMemoryDialog(BuildContext context, RoleMemory memory) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MemoryEditSheet(
        memory: memory,
        roleId: memory.roleId,
        onSave: (content, category, _) {
          context.read<MemoryProvider>().updateMemory(
                id: memory.id,
                content: content,
                category: category,
              );
        },
      ),
    );
  }

  void _showDeleteSelectedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除选中的 ${_selectedIds.length} 条记忆吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final memoryProvider = context.read<MemoryProvider>();
              for (final id in _selectedIds) {
                memoryProvider.deleteMemory(id);
              }
              Navigator.pop(context);
              setState(() {
                _isMultiSelectMode = false;
                _selectedIds.clear();
              });
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _showClearAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空记忆'),
        content: Text('确定要清空 ${widget.role.name} 的所有记忆吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              context
                  .read<MemoryProvider>()
                  .deleteAllMemoriesForRole(widget.role.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('清空'),
          ),
        ],
      ),
    );
  }
}

/// 记忆搜索代理
class MemorySearchDelegate extends SearchDelegate<RoleMemory?> {
  @override
  String get searchFieldLabel => '搜索记忆...';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    if (query.isEmpty) {
      return const Center(
        child: Text('输入关键词搜索记忆'),
      );
    }

    final memoryProvider = context.read<MemoryProvider>();
    final contactProvider = context.read<ContactProvider>();

    final allMemories = <RoleMemory>[];
    for (final role in contactProvider.roles) {
      allMemories.addAll(memoryProvider.getMemoriesForRole(role.id));
    }

    final results = allMemories
        .where((m) => m.content.toLowerCase().contains(query.toLowerCase()))
        .toList();

    if (results.isEmpty) {
      return const Center(
        child: Text('未找到相关记忆'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final memory = results[index];
        final role = contactProvider.roles.firstWhere(
          (r) => r.id == memory.roleId,
          orElse: () => ContactRole(id: '', name: '未知角色', description: ''),
        );

        return ListTile(
          leading:
              Text(memory.category.icon, style: const TextStyle(fontSize: 24)),
          title: Text(memory.content),
          subtitle: Text('${role.name} · ${memory.category.displayName}'),
          onTap: () => close(context, memory),
        );
      },
    );
  }
}
