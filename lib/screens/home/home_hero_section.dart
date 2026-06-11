import 'package:flutter/material.dart';

import '../login_screen.dart';
import '../membership_signup_placeholder.dart';
import '../profile_tab_standalone_screen.dart';
import 'events_section.dart';
import 'home_ticker_card.dart';
import 'news_section.dart';

class HomeHeroSection extends StatelessWidget {
  final bool isLoggedIn;
  final List<dynamic> news;
  final List<dynamic> events;
  final Future<void> Function(Map<String, dynamic> item)? onToggleRegistration;

  const HomeHeroSection({
    super.key,
    required this.isLoggedIn,
    required this.news,
    required this.events,
    this.onToggleRegistration,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool mobile = width < 760;

    return Container(
      constraints: const BoxConstraints(minHeight: 420),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE1E5DF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ],
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFEAF4EF),
            Color(0xFFFFF6DF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(mobile ? 14 : 18),
        child: mobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isLoggedIn) ...[
                    const _PremiumShell(
                      child: HomeTickerCard(),
                    ),
                    const SizedBox(height: 12),
                    _PremiumSection(
                      title: 'Vijesti',
                      child: NewsSection(news: news),
                    ),
                    const SizedBox(height: 12),
                    _PremiumSection(
                      title: 'Događaji',
                      child: EventsSection(
                        events: events,
                        onToggleRegistration: onToggleRegistration,
                      ),
                    ),
                  ] else ...[
                    _HeroRightCard(isLoggedIn: isLoggedIn),
                  ],
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _PremiumShell(
                          child: HomeTickerCard(),
                        ),
                        if (isLoggedIn) ...[
                          const SizedBox(height: 12),
                          _PremiumSection(
                            title: 'Vijesti',
                            child: NewsSection(news: news),
                          ),
                          const SizedBox(height: 12),
                          _PremiumSection(
                            title: 'Događaji',
                            child: EventsSection(
                              events: events,
                              onToggleRegistration: onToggleRegistration,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!isLoggedIn) ...[
                    const SizedBox(width: 18),
                    Expanded(
                      child: _HeroRightCard(isLoggedIn: isLoggedIn),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _HeroRightCard extends StatelessWidget {
  final bool isLoggedIn;

  const _HeroRightCard({required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE1E5DF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF4EF),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFE1E5DF)),
            ),
            child: const Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10,
              children: [
                Text(
                  'BKIC SAFF',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F4F3A),
                  ),
                ),
                Text(
                  'Odense • Naš džemat',
                  style: TextStyle(color: Color(0xFF6D756F)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const _HeroHeadline(),
          const SizedBox(height: 16),
          const Text(
            'Samo ujedinjeni možemo očuvati našu tradiciju i pružiti ruku podrške svakom članu naše zajednice.',
            style: TextStyle(
              color: Color(0xFF6D756F),
              height: 1.5,
              fontSize: 15.5,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MembershipSignupPlaceholder(),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0F4F3A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                ),
                child: const Text(
                  'Budi član',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => isLoggedIn
                          ? const ProfileTabStandaloneScreen()
                          : const LoginScreen(),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0F4F3A),
                  side: const BorderSide(color: Color(0xFFE1E5DF)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                ),
                child: Text(isLoggedIn ? 'Moj račun' : 'Prijavi se'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroHeadline extends StatelessWidget {
  const _HeroHeadline();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          children: [
            _GoldPulseDot(),
            Text(
              'Zajedništvo.',
              style: TextStyle(
                fontSize: 38,
                height: 1.02,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.7,
                color: Color(0xFF17211D),
              ),
            ),
          ],
        ),
        const Text(
          'Snaga naroda.',
          style: TextStyle(
            fontSize: 38,
            height: 1.02,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.7,
            color: Color(0xFFC9A44C),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: 170,
          height: 7,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: const LinearGradient(
              colors: [
                Color(0xFFC9A44C),
                Color(0xFF0F4F3A),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GoldPulseDot extends StatelessWidget {
  const _GoldPulseDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: const BoxDecoration(
        color: Color(0xFFC9A44C),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x33C9A44C),
            blurRadius: 18,
            spreadRadius: 6,
          ),
        ],
      ),
    );
  }
}

class _PremiumShell extends StatelessWidget {
  final Widget child;

  const _PremiumShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE1E5DF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PremiumSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _PremiumSection({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE1E5DF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: title),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  IconData get icon {
    if (title.toLowerCase().contains('vijesti')) {
      return Icons.article_outlined;
    }
    if (title.toLowerCase().contains('doga')) {
      return Icons.event_available_outlined;
    }
    return Icons.circle;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF6DF),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFE1E5DF)),
          ),
          child: Icon(
            icon,
            color: const Color(0xFFC9A44C),
            size: 19,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF17211D),
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }
}