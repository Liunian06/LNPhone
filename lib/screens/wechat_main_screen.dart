import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
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

  final List<Widget> _tabs = [
    const WeChatScreen(),
    const RolesTab(),
    MomentsScreen(),
    const MeTab(),
  ];

  @override
  Widget build(BuildContext context) {
    // 设置状态栏样式
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFEDEDED),
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: const Color(0xFF07C160), // 微信绿
        unselectedItemColor: Colors.grey,
        backgroundColor: const Color(0xFFF7F7F7),
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
