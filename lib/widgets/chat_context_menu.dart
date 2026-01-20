import 'package:flutter/material.dart';

class ChatContextMenu extends StatelessWidget {
  final VoidCallback onCopy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onBacktrack;
  final VoidCallback onMultiSelect;
  final VoidCallback onReply;

  const ChatContextMenu({
    super.key,
    required this.onCopy,
    required this.onEdit,
    required this.onDelete,
    required this.onBacktrack,
    required this.onMultiSelect,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF4C4C4C),
      borderRadius: BorderRadius.circular(8),
      elevation: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 第一行：复制、引用、编辑
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMenuItem(Icons.copy_rounded, '复制', onCopy),
                const SizedBox(width: 24),
                _buildMenuItem(Icons.reply_rounded, '引用', onReply),
                const SizedBox(width: 24),
                _buildMenuItem(Icons.edit_rounded, '编辑', onEdit),
              ],
            ),
            const SizedBox(height: 16),
            // 第二行：删除、回溯、多选
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMenuItem(Icons.delete_outline_rounded, '删除', onDelete),
                const SizedBox(width: 24),
                _buildMenuItem(Icons.restore_rounded, '回溯', onBacktrack),
                const SizedBox(width: 24),
                _buildMenuItem(Icons.checklist_rounded, '多选', onMultiSelect),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        width: 50,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
