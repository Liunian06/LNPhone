import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import 'scenario_history_screen.dart';
import 'scenario_chat_selector_screen.dart';

/// 奔现应用主界面
class ScenarioMainScreen extends StatelessWidget {
  const ScenarioMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final primaryColor =
        isDark ? const Color(0xFFFF9966) : const Color(0xFFFF5E62);

    return Scaffold(
      appBar: AppBar(
        title: const Text('奔现'),
        centerTitle: true,
        backgroundColor: context.appBarBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios,
              color: context.primaryTextColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        titleTextStyle: TextStyle(
          color: context.primaryTextColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: context.chatBackground,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 发起奔现按钮
              _buildMenuButton(
                context,
                icon: Icons.favorite,
                label: '发起奔现',
                color: primaryColor,
                onTap: () {
                  // 跳转到聊天选择界面
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ScenarioChatSelectorScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 30),
              // 奔现记录按钮
              _buildMenuButton(
                context,
                icon: Icons.history,
                label: '奔现记录',
                color: isDark ? Colors.blue.shade400 : Colors.blue.shade600,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ScenarioHistoryScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: context.primaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
