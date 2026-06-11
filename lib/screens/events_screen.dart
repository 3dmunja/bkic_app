import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../services/api_helper.dart';
import 'home/events_section.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  bool loading = true;
  String error = '';
  List<Map<String, dynamic>> events = [];

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    setState(() {
      loading = true;
      error = '';
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
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = 'Greška pri učitavanju događaja: $e';
        loading = false;
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

  int _readInt(Map<String, dynamic> item, List<String> keys, {int fallback = 0}) {
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
    final endpoint = registered ? eventUnregisterEndpoint : eventRegisterEndpoint;

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
      final message = (res['message'] ?? '').toString().trim();

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

      if (message.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Greška: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFCAA25A),
        ),
      );
    }

    if (error.isNotEmpty) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE9E2D5)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 24,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Događaji nisu učitani',
                  style: TextStyle(
                    color: Color(0xFF183B32),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  error,
                  style: const TextStyle(
                    color: Color(0xFF9B3A3A),
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _fetchEvents,
                  child: const Text('Pokušaj ponovo'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      color: const Color(0xFFCAA25A),
      onRefresh: _fetchEvents,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFF7F4EC),
                  Color(0xFFFFFFFF),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              border: Border.all(color: Color(0xFFE6DDCC)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 24,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Događaji',
                  style: TextStyle(
                    color: Color(0xFF183B32),
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 14),
                Text(
                  'Pregled svih nadolazećih događaja i mogućnost prijave.',
                  style: TextStyle(
                    color: Color(0xFF6E6558),
                    fontSize: 16,
                    height: 1.7,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          EventsSection(
            events: events,
            showAsSlider: false,
            onToggleRegistration: _toggleEventRegistration,
          ),
        ],
      ),
    );
  }
}