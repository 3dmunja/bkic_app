import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../services/api_helper.dart';

import 'about_screen.dart';
import 'admin_events_screen.dart';
import 'admin_mail_screen.dart';
import 'admin_news_screen.dart'; // ✅ NY
import 'bkic_map_screen.dart';
import 'contact_tab.dart';
import 'events_screen.dart';
import 'faq_screen.dart';
import 'membership_pricing_screen.dart';
import 'push_debug_screen.dart';
import 'quiz_screen.dart';
import 'success_screen.dart';

class MenuTab extends StatefulWidget {
  const MenuTab({super.key});

  @override
  State<MenuTab> createState() => _MenuTabState();
}

class _MenuTabState extends State<MenuTab> {
  bool loading = true;
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    try {
      final res = await ApiHelper.getJson(
        meEndpoint,
        includeAuthIfAvailable: true,
      );

      final data =
          res['data'] is Map ? Map<String, dynamic>.from(res['data']) : {};
      final roles = data['roles'] is List ? List.from(data['roles']) : [];

      if (!mounted) return;

      setState(() {
        isAdmin = roles.contains('administrator');
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isAdmin = false;
        loading = false;
      });
    }
  }

  void _openPage(String title, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _MenuPageWrapper(
          title: title,
          child: page,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = <_MenuItem>[
      const _MenuItem(
        title: 'O Nama',
        icon: Icons.info_outline,
        page: AboutScreen(),
      ),
      const _MenuItem(
        title: 'Često postavljana pitanja',
        icon: Icons.help_outline,
        page: FaqScreen(),
      ),
      const _MenuItem(
        title: 'Cjenik članstva',
        icon: Icons.payments_outlined,
        page: MembershipPricingScreen(),
      ),
      const _MenuItem(
        title: 'Kontakt',
        icon: Icons.contact_mail_outlined,
        page: ContactTab(),
      ),
      const _MenuItem(
        title: 'Push Debug',
        icon: Icons.notifications_active_outlined,
        page: PushDebugScreen(),
      ),
      const _MenuItem(
        title: 'Događaji',
        icon: Icons.event_outlined,
        page: EventsScreen(),
      ),

      // ✅ ADMIN SECTIONS
      if (isAdmin)
        const _MenuItem(
          title: 'Događaji Admin',
          icon: Icons.admin_panel_settings_outlined,
          page: AdminEventsScreen(),
        ),

      if (isAdmin)
        const _MenuItem(
          title: 'Vijesti Admin',
          icon: Icons.article_outlined,
          page: AdminNewsScreen(), // ✅ RETTET
        ),

      if (isAdmin)
        const _MenuItem(
          title: 'Admin Mail',
          icon: Icons.mail_outline,
          page: AdminMailScreen(),
        ),

      if (isAdmin)
        const _MenuItem(
          title: 'BKIC Map',
          icon: Icons.map_outlined,
          page: BkicMapScreen(),
        ),

      // ✅ USER SECTIONS
      const _MenuItem(
        title: 'Uspjeh',
        icon: Icons.emoji_events_outlined,
        page: SuccessScreen(),
      ),

      const _MenuItem(
        title: 'Kviz znanja',
        icon: Icons.quiz_outlined,
        page: QuizScreen(),
      ),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Menu',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 22),
        if (loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          )
        else
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _MenuCard(
                item: item,
                onTap: () => _openPage(item.title, item.page),
              ),
            ),
          ),
      ],
    );
  }
}

class _MenuItem {
  final String title;
  final IconData icon;
  final Widget page;

  const _MenuItem({
    required this.title,
    required this.icon,
    required this.page,
  });
}

class _MenuCard extends StatelessWidget {
  final _MenuItem item;
  final VoidCallback onTap;

  const _MenuCard({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF171715),
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0x22FFFFFF)),
          ),
          child: Row(
            children: [
              Icon(
                item.icon,
                color: const Color(0xFFD3B261),
                size: 30,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Colors.white70,
                size: 32,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuPageWrapper extends StatelessWidget {
  final String title;
  final Widget child;

  const _MenuPageWrapper({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF111722),
        foregroundColor: Colors.white,
      ),
      body: child,
    );
  }
}