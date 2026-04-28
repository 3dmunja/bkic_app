import 'dart:async';
import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

class EventsSection extends StatefulWidget {
  final List<dynamic> events;
  final Future<void> Function(Map<String, dynamic> item)? onToggleRegistration;
  final bool showAsSlider;

  const EventsSection({
    super.key,
    required this.events,
    this.onToggleRegistration,
    this.showAsSlider = true,
  });

  @override
  State<EventsSection> createState() => _EventsSectionState();
}

class _EventsSectionState extends State<EventsSection> {
  late final PageController _pageController;
  Timer? _timer;
  int currentIndex = 0;

  final Map<String, bool> _localLoading = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startTimer();
    });
  }

  @override
  void didUpdateWidget(covariant EventsSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.events.length != widget.events.length) {
      _timer?.cancel();
      currentIndex = 0;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        if (_pageController.hasClients && widget.events.isNotEmpty) {
          _pageController.jumpToPage(0);
        }

        _startTimer();
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();

    if (!widget.showAsSlider) return;
    if (widget.events.length <= 1) return;

    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_pageController.hasClients || widget.events.isEmpty) return;

      final next = (currentIndex + 1) % widget.events.length;

      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }

  String _pick(Map<String, dynamic> item, String key) {
    final value = item[key];
    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString().trim();
    }
    return '';
  }

  String _pickFirst(Map<String, dynamic> item, List<String> keys) {
    for (final key in keys) {
      final value = _pick(item, key);
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  int _pickInt(Map<String, dynamic> item, String key, {int fallback = 0}) {
    final value = item[key];

    if (value is int) return value;

    if (value != null) {
      return int.tryParse(value.toString().trim()) ?? fallback;
    }

    return fallback;
  }

  bool _pickBool(Map<String, dynamic> item, String key) {
    final value = item[key];

    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    if (value is num) return value != 0;

    return false;
  }

  String _pickImage(Map<String, dynamic> item) {
    final direct = _pickFirst(item, [
      'imageUrl',
      'image_url',
      'image',
      'thumbnail',
      'featured_image',
      'featuredImage',
    ]);

    if (direct.isNotEmpty && direct.startsWith('http')) {
      return direct;
    }

    final nestedImage = item['image'];

    if (nestedImage is Map) {
      final url = nestedImage['url'];
      if (url != null && url.toString().trim().startsWith('http')) {
        return url.toString().trim();
      }
    }

    return '';
  }

  Color _statusBg(String status) {
    final s = status.toLowerCase();

    if (s.contains('otvoreno')) return const Color(0xFF183320);
    if (s.contains('uskoro')) return const Color(0xFF4C3914);
    if (s.contains('zatvoreno')) return const Color(0xFF442020);
    if (s.contains('popunjeno')) return const Color(0xFF442020);
    if (s.contains('istekao')) return const Color(0xFF4C3914);

    return const Color(0x1AFFFFFF);
  }

  Color _statusTextColor(String status) {
    final s = status.toLowerCase();

    if (s.contains('otvoreno')) return const Color(0xFFD9F6DD);
    if (s.contains('uskoro')) return const Color(0xFFFFE4AA);
    if (s.contains('zatvoreno')) return const Color(0xFFFFD3D1);
    if (s.contains('popunjeno')) return const Color(0xFFFFD3D1);
    if (s.contains('istekao')) return const Color(0xFFFFE4AA);

    return Colors.white;
  }

  Future<void> _handleRegistration(Map<String, dynamic> item) async {
    final eventId = _pick(item, 'id');

    if (eventId.isEmpty) return;

    if (widget.onToggleRegistration == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prijava nije povezana.'),
        ),
      );
      return;
    }

    setState(() {
      _localLoading[eventId] = true;
    });

    try {
      await widget.onToggleRegistration!(item);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Greška: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _localLoading[eventId] = false;
      });
    }
  }

  Widget _eventImage(String imageUrl, bool mobile) {
    final height = mobile ? 160.0 : 190.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: imageUrl.isNotEmpty
          ? Image.network(
              imageUrl,
              width: double.infinity,
              height: height,
              fit: BoxFit.cover,
              cacheWidth: mobile ? 700 : 500,
              errorBuilder: (_, __, ___) {
                return _imageFallback(height);
              },
            )
          : _imageFallback(height),
    );
  }

  Widget _imageFallback(double height) {
    return Container(
      height: height,
      color: const Color(0x14FFFFFF),
      alignment: Alignment.center,
      child: const Icon(
        Icons.event,
        color: Colors.white54,
        size: 34,
      ),
    );
  }

  Widget _eventActionButton({
    required Map<String, dynamic> item,
    required bool registered,
    required bool canRegister,
    required String availabilityLabel,
    required bool isLoading,
  }) {
    if (isLoading) {
      return const SizedBox(
        height: 44,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (registered) {
      return FilledButton(
        onPressed: () => _handleRegistration(item),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF7A1F20),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        child: const Text(
          'Odjavi se',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      );
    }

    if (canRegister) {
      return FilledButton(
        onPressed: () => _handleRegistration(item),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFF0D07A),
          foregroundColor: const Color(0xFF0B0F14),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        child: const Text(
          'Prijavi se',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x1AFFFFFF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        availabilityLabel.isNotEmpty ? availabilityLabel : 'Nije dostupno',
        style: const TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _eventBody({
    required Map<String, dynamic> item,
    required String title,
    required String description,
    required String date,
    required String time,
    required String location,
    required String statusLabel,
    required int count,
    required int maxSeats,
    required bool registered,
    required bool canRegister,
    required String availabilityLabel,
    required bool isLoading,
    bool compact = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x14000000),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title.isNotEmpty ? title : 'Događaj',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
              ),
              if (statusLabel.isNotEmpty) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _statusBg(statusLabel),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: _statusTextColor(statusLabel),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              description,
              maxLines: compact ? 6 : 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white70,
                height: 1.45,
              ),
            ),
          ],
          const SizedBox(height: 10),
          if (date.isNotEmpty)
            Text(
              'Datum: $date',
              style: const TextStyle(color: Colors.white70, fontSize: 12.5),
            ),
          if (time.isNotEmpty)
            Text(
              'Vrijeme: $time',
              style: const TextStyle(color: Colors.white70, fontSize: 12.5),
            ),
          if (location.isNotEmpty)
            Text(
              'Mjesto: $location',
              style: const TextStyle(color: Colors.white70, fontSize: 12.5),
            ),
          const SizedBox(height: 8),
          Text(
            maxSeats > 0 ? 'Prijave: $count / $maxSeats' : 'Prijave: $count',
            style: const TextStyle(color: Colors.white70, fontSize: 12.5),
          ),
          if (registered) ...[
            const SizedBox(height: 8),
            const Text(
              'Već ste prijavljeni',
              style: TextStyle(
                color: AppColors.gold,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ],
          const SizedBox(height: 12),
          _eventActionButton(
            item: item,
            registered: registered,
            canRegister: canRegister,
            availabilityLabel: availabilityLabel,
            isLoading: isLoading,
          ),
        ],
      ),
    );
  }

  Widget _eventCard(dynamic raw, bool mobile, {bool compact = false}) {
    final item = _asMap(raw);

    final eventId = _pick(item, 'id');
    final title = _pick(item, 'title');
    final description = _pickFirst(item, [
      'description',
      'text',
      'content',
    ]);
    final date = _pick(item, 'date');
    final time = _pick(item, 'time');
    final location = _pick(item, 'location');
    final imageUrl = _pickImage(item);
    final statusLabel = _pickFirst(item, [
      'statusLabel',
      'availabilityLabel',
      'status',
    ]);
    final availabilityLabel = _pick(item, 'availabilityLabel');
    final registered = _pickBool(item, 'registered');
    final canRegister = _pickBool(item, 'canRegister');
    final count = _pickInt(item, 'registrationsCount');
    final maxSeats = _pickInt(item, 'maxSeats');
    final isLoading = _localLoading[eventId] == true;

    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0x1A000000),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0x1FFFFFFF)),
        ),
        child: mobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _eventImage(imageUrl, true),
                  const SizedBox(height: 10),
                  _eventBody(
                    item: item,
                    title: title,
                    description: description,
                    date: date,
                    time: time,
                    location: location,
                    statusLabel: statusLabel,
                    count: count,
                    maxSeats: maxSeats,
                    registered: registered,
                    canRegister: canRegister,
                    availabilityLabel: availabilityLabel,
                    isLoading: isLoading,
                    compact: compact,
                  ),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 130,
                    child: _eventImage(imageUrl, false),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _eventBody(
                      item: item,
                      title: title,
                      description: description,
                      date: date,
                      time: time,
                      location: location,
                      statusLabel: statusLabel,
                      count: count,
                      maxSeats: maxSeats,
                      registered: registered,
                      canRegister: canRegister,
                      availabilityLabel: availabilityLabel,
                      isLoading: isLoading,
                      compact: compact,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSlider(bool mobile) {
    return Column(
      children: [
        SizedBox(
          height: mobile ? 510 : 290,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.events.length,
            onPageChanged: (index) {
              setState(() {
                currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return _eventCard(widget.events[index], mobile);
            },
          ),
        ),
        if (widget.events.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.events.length, (index) {
              final active = index == currentIndex;

              return GestureDetector(
                onTap: () {
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active
                        ? const Color(0xFFF0D07A)
                        : const Color(0x40FFFFFF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  Widget _buildList(bool mobile) {
    return Column(
      children: widget.events
          .map(
            (event) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _eventCard(event, mobile, compact: true),
            ),
          )
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.of(context).size.width < 640;

    if (widget.events.isEmpty) {
      return const Text(
        'Trenutno nema događaja.',
        style: TextStyle(color: Colors.white70),
      );
    }

    return widget.showAsSlider ? _buildSlider(mobile) : _buildList(mobile);
  }
}