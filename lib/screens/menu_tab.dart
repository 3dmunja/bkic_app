import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../services/api_helper.dart';

import 'about_screen.dart';
import 'admin_events_screen.dart';
import 'admin_mail_screen.dart';
import 'admin_news_screen.dart';
import 'bkic_map_screen.dart';
import 'contact_tab.dart';
import 'events_screen.dart';
import 'faq_screen.dart';
import 'membership_pricing_screen.dart';
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
        title: 'Događaji',
        icon: Icons.event_outlined,
        page: EventsScreen(),
      ),

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
          page: AdminNewsScreen(),
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

    return Container(
      color: const Color(0xFFF7F8F5),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFE1E5DF)),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFFFFFF),
                  Color(0xFFEAF4EF),
                  Color(0xFFFFF6DF),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x10000000),
                  blurRadius: 22,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Menu',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF17211D),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Brz pristup svim BKIC SAFF funkcijama.',
                  style: TextStyle(
                    color: Color(0xFF6D756F),
                    fontSize: 15.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          if (loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(
                  color: Color(0xFF0F4F3A),
                ),
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
      ),
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
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE1E5DF)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF6DF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE1E5DF)),
                ),
                child: Icon(
                  item.icon,
                  color: const Color(0xFFC9A44C),
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(
                    color: Color(0xFF17211D),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF6D756F),
                size: 30,
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
      backgroundColor: const Color(0xFFF7F8F5),
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFFF7F8F5),
        foregroundColor: const Color(0xFF17211D),
        elevation: 0,
      ),
      body: child,
    );
  }
}