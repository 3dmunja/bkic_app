import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/constants.dart';
import '../../services/api_helper.dart';
import '../../services/auth_service.dart';
import '../../widgets/premium_card.dart';
import 'home_hero_section.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  bool isLoggedIn = false;

  bool loadingNews = true;
  String newsError = '';
  List<Map<String, dynamic>> news = [];

  bool loadingEvents = true;
  String eventsError = '';
  List<Map<String, dynamic>> events = [];

  @override
  void initState() {
    super.initState();
    fetchHomeData();
  }

  Future<void> fetchHomeData() async {
    final logged = await AuthService.isLoggedIn();

    if (!mounted) return;

    setState(() {
      isLoggedIn = logged;
    });

    await Future.wait([
      fetchNews(),
      fetchEvents(),
    ]);
  }

  Future<void> fetchNews() async {
    if (!mounted) return;

    setState(() {
      loadingNews = true;
      newsError = '';
    });

    try {
      final res = await ApiHelper.getJson(homeNewsEndpoint);

      final rawList = (res['data'] is List)
          ? List<Map<String, dynamic>>.from(
              (res['data'] as List).map(
                (e) => Map<String, dynamic>.from(e as Map),
              ),
            )
          : <Map<String, dynamic>>[];

      if (!mounted) return;

      setState(() {
        news = rawList;
        loadingNews = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        newsError = 'Greška pri učitavanju vijesti: $e';
        loadingNews = false;
      });
    }
  }

  Future<void> fetchEvents() async {
    if (!mounted) return;

    setState(() {
      loadingEvents = true;
      eventsError = '';
    });

    try {
      final res = await ApiHelper.getJson(
        homeEventsEndpoint,
        includeAuthIfAvailable: true,
      );

      final rawList = (res['data'] is List)
          ? List<Map<String, dynamic>>.from(
              (res['data'] as List).map(
                (e) => Map<String, dynamic>.from(e as Map),
              ),
            )
          : <Map<String, dynamic>>[];

      if (!mounted) return;

      setState(() {
        events = rawList;
        loadingEvents = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        eventsError = 'Greška pri učitavanju događaja: $e';
        loadingEvents = false;
      });
    }
  }

  String _readString(Map<String, dynamic> item, List<String> keys) {
    for (final key in keys) {
      final value = item[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return '';
  }

  int _readInt(
    Map<String, dynamic> item,
    List<String> keys, {
    int fallback = 0,
  }) {
    for (final key in keys) {
      final value = item[key];
      if (value == null) continue;

      if (value is int) return value;

      final parsed = int.tryParse(value.toString().trim());
      if (parsed != null) return parsed;
    }
    return fallback;
  }

  Future<void> _toggleEventRegistration(Map<String, dynamic> item) async {
    final eventId = _readString(item, ['id']);
    if (eventId.isEmpty) return;

    final registered = item['registered'] == true;
    final endpoint =
        registered ? eventUnregisterEndpoint : eventRegisterEndpoint;

    try {
      final res = await ApiHelper.postJson(
        endpoint,
        authRequired: true,
        body: {
          'event_id': eventId,
        },
      );

      final data = res['data'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(res['data'] as Map)
          : <String, dynamic>{};

      final newRegistered = data['registered'] == true;
      final newCount = _readInt(data, ['count']);
      final availabilityLabel = _readString(data, ['availabilityLabel']);
      final isFull = data['isFull'] == true;
      final deadlinePassed = data['deadlinePassed'] == true;
      final canRegister = data['canRegister'] == true;

      if (!mounted) return;

      setState(() {
        final index = events.indexWhere(
          (e) => _readString(e, ['id']) == eventId,
        );

        if (index != -1) {
          final updated = Map<String, dynamic>.from(events[index]);
          updated['registered'] = newRegistered;
          updated['registrationsCount'] = newCount;
          updated['availabilityLabel'] = availabilityLabel;
          updated['isFull'] = isFull;
          updated['deadlinePassed'] = deadlinePassed;
          updated['canRegister'] = canRegister;
          events[index] = updated;
        }
      });

      final message = (res['message'] ?? '').toString();

      if (message.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Greška: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w900,
        color: Color(0xFF17211D),
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String text,
  }) {
    return PremiumCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF6DF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: AppColors.gold,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF17211D),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  text,
                  style: const TextStyle(
                    color: Color(0xFF6D756F),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleNews =
        (!loadingNews && newsError.isEmpty) ? news : <Map<String, dynamic>>[];

    final visibleEvents = (!loadingEvents && eventsError.isEmpty)
        ? events
        : <Map<String, dynamic>>[];

    return Container(
      color: const Color(0xFFF7F8F5),
      child: RefreshIndicator(
        color: const Color(0xFF0F4F3A),
        backgroundColor: Colors.white,
        onRefresh: fetchHomeData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            HomeHeroSection(
              isLoggedIn: isLoggedIn,
              news: visibleNews,
              events: visibleEvents,
              onToggleRegistration: _toggleEventRegistration,
            ),
            const SizedBox(height: 24),
            _sectionTitle('Dobro došli'),
            const SizedBox(height: 12),
            _infoCard(
              icon: Icons.groups_2_outlined,
              title: 'Zajednica',
              text: 'BKIC SAFF okuplja članove zajednice na jednom mjestu.',
            ),
            const SizedBox(height: 12),
            _infoCard(
              icon: Icons.workspace_premium_outlined,
              title: 'Članstvo',
              text: 'U profilu možete vidjeti status članstva.',
            ),
          ],
        ),
      ),
    );
  }
}