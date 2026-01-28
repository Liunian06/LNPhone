import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_theme.dart';
import 'wechat_screen.dart';
import 'contacts/roles_tab.dart';
import 'moments_screen.dart';
import 'contacts/me_tab.dart';

/// 微信主界面，包含4个底栏标签：微信、通讯录、发现、我
class WeChatMainScreen extends StatefulWidget {
  const WeChatMainScreen({super.key});

  @override
  State<WeChatMainScreen> createState() => _WeChatMainScreenState();
}

class _WeChatMainScreenState extends State<WeChatMainScreen> {
  int _currentIndex = 0;
  late PageController _pageController;

  final List<Widget> _tabs = [
    const WeChatScreen(),
    const RolesTab(),
    MomentsScreen(),
    const MeTab(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 根据主题模式动态设置状态栏样式
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            context.isDarkMode ? Brightness.light : Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: context.chatBackground,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: _tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        selectedItemColor: AppTheme.wechatGreen, // 微信绿
        unselectedItemColor: context.secondaryTextColor,
        backgroundColor: context.surfaceColor,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.chat_bubble_2_fill),
            label: '聊天',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person_crop_circle_fill),
            label: '通讯录',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.time_solid),
            label: '朋友圈',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person_fill),
            label: '我',
          ),
        ],
      ),
    );
  }
}
