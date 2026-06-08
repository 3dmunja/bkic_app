import 'dart:async';
import 'package:flutter/material.dart';

class HomeTickerCard extends StatefulWidget {
  const HomeTickerCard({super.key});

  @override
  State<HomeTickerCard> createState() => _HomeTickerCardState();
}

class _HomeTickerCardState extends State<HomeTickerCard> {
  final ScrollController _scrollController = ScrollController();
  Timer? _timer;

  static const List<String> messages = [
    'Vjera i istina — vjeruj i govori istinu',
    'Zajedništvo — zajedno smo jači',
    'Dijeljenje uspjeha — uspjeh vrijedi kada se dijeli',
    'Dobrodošli u BKIC SAFF, Odense',
  ];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoScroll();
    });
  }

  void _startAutoScroll() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(milliseconds: 45), (_) {
      if (!mounted || !_scrollController.hasClients) return;

      final max = _scrollController.position.maxScrollExtent;
      if (max <= 0) return;

      final next = _scrollController.offset + 1.05;

      if (next >= max) {
        _scrollController.jumpTo(0);
      } else {
        _scrollController.jumpTo(next);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildTickerItems() {
    final items = [...messages, ...messages];

    return Row(
      children: items.map((text) {
        return Padding(
          padding: const EdgeInsets.only(right: 26),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                text,
                maxLines: 1,
                softWrap: false,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(width: 14),
              const Text(
                '•',
                style: TextStyle(
                  color: Color(0xFFF0D07A),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0x1810A05A),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0x3348A66A)),
          gradient: const LinearGradient(
            colors: [
              Color(0x3310231B),
              Color(0x1A48A66A),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFF48A66A),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x5548A66A),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ClipRect(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      physics: const NeverScrollableScrollPhysics(),
                      child: _buildTickerItems(),
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: IgnorePointer(
                child: Container(
                  width: 34,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xAA0B1D16),
                        Color(0x000B1D16),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: IgnorePointer(
                child: Container(
                  width: 34,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0x000B1D16),
                        Color(0xAA0B1D16),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}