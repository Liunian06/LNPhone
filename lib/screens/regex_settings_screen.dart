import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../core/providers/regex_settings_provider.dart';
import '../core/models/regex_rule_model.dart';
import '../widgets/ios_wallpaper.dart';

class RegexSettingsScreen extends StatefulWidget {
  const RegexSettingsScreen({super.key});

  @override
  State<RegexSettingsScreen> createState() => _RegexSettingsScreenState();
}

class _RegexSettingsScreenState extends State<RegexSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<RegexSettingsProvider>();

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF5F5F7),
      body: IOSWallpaper(
        style: WallpaperStyle.dark,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, isDark),
              Expanded(
                child: ReorderableListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: provider.rules.length,
                  onReorder: (oldIndex, newIndex) {
                    provider.reorderRules(oldIndex, newIndex);
                  },
                  itemBuilder: (context, index) {
                    final rule = provider.rules[index];
                    return _buildRuleItem(context, rule, isDark, index);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditRuleDialog(context),
        backgroundColor: const Color(0xFF007AFF),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black87;
    final bgColor = isDark
        ? Colors.white.withValues(alpha: 0.2)
        : Colors.black.withValues(alpha: 0.1);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    CupertinoIcons.back,
                    color: textColor,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '正则设置',
                style: TextStyle(
                  color: textColor,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => _showResetConfirmDialog(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                CupertinoIcons.arrow_counterclockwise,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleItem(
      BuildContext context, RegexRule rule, bool isDark, int index) {
    final textColor = isDark ? Colors.white : Colors.black87;
    final bgColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.05);

    return Container(
      key: ValueKey(rule.id),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          rule.name,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          rule.type == RegexRuleType.regex
              ? '正则: ${rule.pattern}'
              : '替换: ${rule.pattern}',
          style: TextStyle(
            color: textColor.withValues(alpha: 0.6),
            fontSize: 12,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoSwitch(
              value: rule.isEnabled,
              onChanged: (value) {
                context
                    .read<RegexSettingsProvider>()
                    .updateRule(rule.copyWith(isEnabled: value));
              },
              activeColor: const Color(0xFF007AFF),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _showEditRuleDialog(context, rule: rule),
              child: Icon(
                CupertinoIcons.pencil,
                color: textColor.withValues(alpha: 0.6),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Icon(
              Icons.drag_handle,
              color: textColor.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditRuleDialog(BuildContext context, {RegexRule? rule}) {
    final isEditing = rule != null;
    final nameController = TextEditingController(text: rule?.name ?? '');
    final patternController = TextEditingController(text: rule?.pattern ?? '');
    final replacementController =
        TextEditingController(text: rule?.replacement ?? '');
    RegexRuleType type = rule?.type ?? RegexRuleType.regex;

    showCupertinoDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return CupertinoAlertDialog(
            title: Text(isEditing ? '编辑规则' : '新增规则'),
            content: Column(
              children: [
                const SizedBox(height: 16),
                CupertinoTextField(
                  controller: nameController,
                  placeholder: '规则名称',
                ),
                const SizedBox(height: 12),
                CupertinoSlidingSegmentedControl<RegexRuleType>(
                  groupValue: type,
                  children: const {
                    RegexRuleType.regex: Text('正则'),
                    RegexRuleType.replace: Text('替换'),
                  },
                  onValueChanged: (value) {
                    if (value != null) {
                      setState(() => type = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                CupertinoTextField(
                  controller: patternController,
                  placeholder: type == RegexRuleType.regex ? '正则表达式' : '查找内容',
                  maxLines: 3,
                  minLines: 1,
                ),
                const SizedBox(height: 12),
                CupertinoTextField(
                  controller: replacementController,
                  placeholder: '替换内容 (支持 \$1 引用)',
                  maxLines: 3,
                  minLines: 1,
                ),
              ],
            ),
            actions: [
              if (isEditing)
                CupertinoDialogAction(
                  isDestructiveAction: true,
                  onPressed: () {
                    context.read<RegexSettingsProvider>().deleteRule(rule.id);
                    Navigator.pop(context);
                  },
                  child: const Text('删除'),
                ),
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              CupertinoDialogAction(
                onPressed: () {
                  if (nameController.text.isEmpty ||
                      patternController.text.isEmpty) {
                    return;
                  }

                  final newRule = RegexRule(
                    id: rule?.id ?? const Uuid().v4(),
                    name: nameController.text,
                    pattern: patternController.text,
                    replacement: replacementController.text,
                    type: type,
                    isEnabled: rule?.isEnabled ?? true,
                    order: rule?.order ??
                        context.read<RegexSettingsProvider>().rules.length,
                  );

                  if (isEditing) {
                    context.read<RegexSettingsProvider>().updateRule(newRule);
                  } else {
                    context.read<RegexSettingsProvider>().addRule(newRule);
                  }
                  Navigator.pop(context);
                },
                child: const Text('保存'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showResetConfirmDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('重置规则'),
        content: const Text('确定要恢复默认规则吗？所有自定义规则将被删除。'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              context.read<RegexSettingsProvider>().resetToDefault();
              Navigator.pop(context);
            },
            child: const Text('重置'),
          ),
        ],
      ),
    );
  }
}
