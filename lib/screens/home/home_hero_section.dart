import 'dart:ui';

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

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        constraints: const BoxConstraints(minHeight: 420),
        decoration: const BoxDecoration(
  color: Color(0xFF111820),
),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0x26FFFFFF)),
            gradient: const LinearGradient(
              colors: [
                Color(0x40232D38),
                Color(0x501A2430),
                Color(0x6010151D),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Stack(
            children: [
              const Positioned.fill(
                child: _SteamOverlay(),
              ),
              Padding(
                padding: EdgeInsets.all(mobile ? 14 : 18),
                child: mobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (isLoggedIn) ...[
                            const _GlassShell(
                              child: HomeTickerCard(),
                            ),
                            const SizedBox(height: 12),
                            _GoldGlassSection(
                              title: 'Vijesti',
                              child: NewsSection(news: news),
                            ),
                            const SizedBox(height: 12),
                            _GoldGlassSection(
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
                                const _GlassShell(
                                  child: HomeTickerCard(),
                                ),
                                if (isLoggedIn) ...[
                                  const SizedBox(height: 12),
                                  _GoldGlassSection(
                                    title: 'Vijesti',
                                    child: NewsSection(news: news),
                                  ),
                                  const SizedBox(height: 12),
                                  _GoldGlassSection(
                                    title: 'Događaji',
                                    child: EventsSection(
                                      events: events,
                                      onToggleRegistration:
                                          onToggleRegistration,
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
            ],
          ),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0x33F0D07A)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 22,
                offset: Offset(0, 12),
              ),
            ],
            gradient: const LinearGradient(
              colors: [
                Color(0x2AF0D07A),
                Color(0x207FC8FF),
                Color(0x18FFFFFF),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            color: Color(0x18FFFFFF),
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
                  color: const Color(0x22000000),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0x24FFFFFF)),
                ),
                child: const Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  children: [
                    Text(
                      'BKIC SAFF',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Odense • Naš džemat',
                      style: TextStyle(color: Colors.white70),
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
                  color: Colors.white70,
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
                      backgroundColor: const Color(0xFFF0D07A),
                      foregroundColor: const Color(0xFF0B0F14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
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
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0x24FFFFFF)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
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
        ),
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
                color: Colors.white,
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
            color: Color(0xFFF0D07A),
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
                Color(0xFFF0D07A),
                Color(0xFF7FC8FF),
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
        color: Color(0xFFF0D07A),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x33F0D07A),
            blurRadius: 18,
            spreadRadius: 6,
          ),
        ],
      ),
    );
  }
}

class _GlassShell extends StatelessWidget {
  final Widget child;

  const _GlassShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0x18FFFFFF),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0x26FFFFFF)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _GoldGlassSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _GoldGlassSection({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0x33F0D07A)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
              gradient: const LinearGradient(
                colors: [
                  Color(0x262A3442),
                  Color(0x1AFFFFFF),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              color: const Color(0x14FFFFFF),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(title: title),
                const SizedBox(height: 12),
                child,
              ],
            ),
          ),
        ),
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
            color: const Color(0x26F0D07A),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0x33F0D07A)),
          ),
          child: Icon(
            icon,
            color: const Color(0xFFF0D07A),
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
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _SteamOverlay extends StatelessWidget {
  const _SteamOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          _steamLine(
            top: 120,
            right: 70,
            width: 170,
            height: 170,
            angle: -0.18,
            opacity: 0.045,
          ),
          _steamLine(
            top: 170,
            right: 120,
            width: 140,
            height: 160,
            angle: 0.15,
            opacity: 0.035,
          ),
          _steamLine(
            top: 210,
            right: 85,
            width: 190,
            height: 190,
            angle: -0.08,
            opacity: 0.03,
          ),
        ],
      ),
    );
  }

  Widget _steamLine({
    required double top,
    double? left,
    double? right,
    required double width,
    required double height,
    required double angle,
    required double opacity,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      child: Transform.rotate(
        angle: angle,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.0),
                Colors.white.withOpacity(opacity),
                Colors.white.withOpacity(0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
    );
  }
}