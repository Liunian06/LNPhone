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
        width: 280,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Wrap(
          alignment: WrapAlignment.spaceEvenly,
          runSpacing: 12,
          children: [
            _buildMenuItem(Icons.copy_rounded, '复制', onCopy),
            _buildMenuItem(Icons.reply_rounded, '引用', onReply),
            _buildMenuItem(Icons.edit_rounded, '编辑', onEdit),
            _buildMenuItem(Icons.delete_outline_rounded, '删除', onDelete),
            _buildMenuItem(Icons.restore_rounded, '回溯', onBacktrack),
            _buildMenuItem(Icons.checklist_rounded, '多选', onMultiSelect),
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
