import 'package:flutter/material.dart';

import '../core/session_scope.dart';
import '../services/auth_service.dart';
import 'contact_tab.dart';
import 'home/home_tab.dart';
import 'login_screen.dart';
import 'menu_tab.dart';
import 'profile_tab.dart';

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
    ProfileTab(),
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
      backgroundColor: const Color(0xFFF7F8F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8F5),
        foregroundColor: const Color(0xFF17211D),
        elevation: 0,
        centerTitle: false,
        title: Text(
          titles[currentIndex],
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF17211D),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: IconButton(
              onPressed: loggingOut ? null : logout,
              tooltip: 'Odjavi se',
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0F4F3A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(
                    color: Color(0xFFE1E5DF),
                  ),
                ),
              ),
              icon: loggingOut
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF0F4F3A),
                      ),
                    )
                  : const Icon(Icons.logout_rounded),
            ),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: KeyedSubtree(
          key: ValueKey<int>(currentIndex),
          child: pages[currentIndex],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: Color(0xFFE1E5DF),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 20,
              offset: Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            height: 72,
            elevation: 0,
            backgroundColor: Colors.white,
            indicatorColor: Color(0xFFEAF4EF),
            selectedIndex: currentIndex,
            onDestinationSelected: (index) {
              setState(() {
                currentIndex = index;
              });
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(
                  Icons.home_rounded,
                  color: Color(0xFF0F4F3A),
                ),
                label: 'Početna',
              ),
              NavigationDestination(
                icon: Icon(Icons.menu_outlined),
                selectedIcon: Icon(
                  Icons.menu_rounded,
                  color: Color(0xFF0F4F3A),
                ),
                label: 'Menu',
              ),
              NavigationDestination(
                icon: Icon(Icons.contact_mail_outlined),
                selectedIcon: Icon(
                  Icons.contact_mail_rounded,
                  color: Color(0xFF0F4F3A),
                ),
                label: 'Kontakt',
              ),
              NavigationDestination(
                icon: Icon(Icons.account_circle_outlined),
                selectedIcon: Icon(
                  Icons.account_circle_rounded,
                  color: Color(0xFF0F4F3A),
                ),
                label: 'Moj račun',
              ),
            ],
          ),
        ),
      ),
    );
  }
}