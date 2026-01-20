import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../core/theme/app_theme.dart';
import 'roles_tab.dart';
import 'me_tab.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [const RolesTab(), const MeTab()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.chatBackground,
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: const Color(0xFF07C160), // WeChat Green
        unselectedItemColor: context.secondaryTextColor,
        backgroundColor: context.surfaceColor,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person_2_fill),
            label: '角色',
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
