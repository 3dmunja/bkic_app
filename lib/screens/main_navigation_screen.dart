import 'package:flutter/material.dart';

import '../core/session_scope.dart';
import '../services/auth_service.dart';
import 'account_screen.dart';
import 'contact_tab.dart';
import 'home/home_tab.dart';
import 'login_screen.dart';
import 'menu_tab.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int currentIndex = 0;
  bool loggingOut = false;

  final List<Widget> pages = const [
    HomeTab(),
    MenuTab(),
    ContactTab(),
    AccountScreen(),
  ];

  final List<String> titles = const [
    'Početna',
    'Menu',
    'Kontakt',
    'Moj račun',
  ];

  Future<void> logout() async {
    if (loggingOut) return;

    setState(() {
      loggingOut = true;
    });

    try {
      await AuthService.logout();
    } catch (_) {
      await AuthService.clearToken();
    }

    if (!mounted) return;

    SessionScope.of(context).value++;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[currentIndex]),
        actions: [
          IconButton(
            onPressed: loggingOut ? null : logout,
            icon: loggingOut
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout),
            tooltip: 'Odjavi se',
          ),
        ],
      ),
      body: pages[currentIndex],
      bottomNavigationBar: NavigationBar(
        height: 74,
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Početna',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_outlined),
            selectedIcon: Icon(Icons.menu),
            label: 'Menu',
          ),
          NavigationDestination(
            icon: Icon(Icons.contact_mail_outlined),
            selectedIcon: Icon(Icons.contact_mail),
            label: 'Kontakt',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_circle_outlined),
            selectedIcon: Icon(Icons.account_circle),
            label: 'Moj račun',
          ),
        ],
      ),
    );
  }
}