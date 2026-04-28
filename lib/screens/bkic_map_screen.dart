import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../core/constants.dart';
import '../services/api_helper.dart';

class BkicMapScreen extends StatefulWidget {
  const BkicMapScreen({super.key});

  @override
  State<BkicMapScreen> createState() => _BkicMapScreenState();
}

class _BkicMapScreenState extends State<BkicMapScreen> {
  static const String endpoint = adminMemberMapEndpoint;

  bool loading = true;
  String error = '';

  int totalPostcodes = 0;
  int totalUsers = 0;

  List<Map<String, dynamic>> items = [];
  List<String> unknown = [];

  @override
  void initState() {
    super.initState();
    fetchMapData();
  }

  Future<void> fetchMapData() async {
    setState(() {
      loading = true;
      error = '';
    });

    try {
      final res = await ApiHelper.getJson(
        endpoint,
        authRequired: true,
      );

      final data = res['data'] is Map
          ? Map<String, dynamic>.from(res['data'] as Map)
          : <String, dynamic>{};

      final rawItems = data['items'];
      final parsedItems = rawItems is List
          ? rawItems
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : <Map<String, dynamic>>[];

      final rawUnknown = data['unknown'];
      final parsedUnknown = rawUnknown is List
          ? rawUnknown.map((e) => e.toString()).toList()
          : <String>[];

      if (!mounted) return;

      setState(() {
        totalPostcodes = _readInt(data, 'total_postcodes');
        totalUsers = _readInt(data, 'total_users');
        items = parsedItems;
        unknown = parsedUnknown;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = 'Greška pri učitavanju BKIC Map: $e';
        loading = false;
      });
    }
  }

  int _readInt(Map<String, dynamic> item, String key) {
    final value = item[key];
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _readString(Map<String, dynamic> item, String key) {
    final value = item[key];
    if (value == null) return '';
    return value.toString().trim();
  }

  double _readDouble(Map<String, dynamic> item, String key) {
    final value = item[key];
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  Color _countColor(int count) {
    if (count >= 15) return const Color(0xFFD32F2F);
    if (count >= 10) return const Color(0xFFF57C00);
    if (count >= 5) return const Color(0xFFFBC02D);
    if (count >= 2) return const Color(0xFF43A047);
    return const Color(0xFF1E88E5);
  }

  Widget _mapBox() {
    final validItems = items.where((item) {
      final lat = _readDouble(item, 'lat');
      final lng = _readDouble(item, 'lng');
      return lat != 0 && lng != 0;
    }).toList();

    if (validItems.isEmpty) {
      return Container(
        height: 280,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF171715),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0x22FFFFFF)),
        ),
        child: const Text(
          'Nema koordinata za prikaz na karti.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    final markers = validItems.map((item) {
      final postcode = _readString(item, 'postcode');
      final city = _readString(item, 'city');
      final count = _readInt(item, 'count');
      final lat = _readDouble(item, 'lat');
      final lng = _readDouble(item, 'lng');
      final color = _countColor(count);

      return Marker(
        point: LatLng(lat, lng),
        width: 72,
        height: 72,
        child: GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: const Color(0xFF171715),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              builder: (_) => Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  '${city.isNotEmpty ? '$postcode – $city' : postcode}\nKorisnika: $count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    height: 1.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            );
          },
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withOpacity(0.85),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ),
        ),
      );
    }).toList();

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: 360,
        child: FlutterMap(
          options: const MapOptions(
            initialCenter: LatLng(56.15, 10.0),
            initialZoom: 6.6,
            minZoom: 5,
            maxZoom: 18,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'dk.bkicsaff.bkic_app',
            ),
            MarkerLayer(markers: markers),
          ],
        ),
      ),
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF171715),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0x22FFFFFF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFFD4AF37), size: 28),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 13.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _postcodeCard(Map<String, dynamic> item) {
    final postcode = _readString(item, 'postcode');
    final city = _readString(item, 'city');
    final count = _readInt(item, 'count');
    final color = _countColor(count);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF171715),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withOpacity(0.22),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.65)),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              '${city.isNotEmpty ? '$postcode – $city' : postcode}\nKorisnika: $count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                height: 1.45,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legend() {
    final rows = [
      {'label': '1', 'color': const Color(0xFF1E88E5)},
      {'label': '2–4', 'color': const Color(0xFF43A047)},
      {'label': '5–9', 'color': const Color(0xFFFBC02D)},
      {'label': '10–14', 'color': const Color(0xFFF57C00)},
      {'label': '15+', 'color': const Color(0xFFD32F2F)},
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: rows.map((row) {
        final label = row['label'] as String;
        final color = row['color'] as Color;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: color.withOpacity(0.18),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color.withOpacity(0.55)),
          ),
          child: Text(
            '$label korisnika',
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
        );
      }).toList(),
    );
  }

  Widget _content() {
    if (loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (error.isNotEmpty) {
      return Text(
        error,
        style: const TextStyle(color: Colors.redAccent, height: 1.5),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _statCard(
              title: 'Poštanski brojevi',
              value: totalPostcodes.toString(),
              icon: Icons.location_city_outlined,
            ),
            const SizedBox(width: 12),
            _statCard(
              title: 'Korisnici',
              value: totalUsers.toString(),
              icon: Icons.people_alt_outlined,
            ),
          ],
        ),
        const SizedBox(height: 14),
        _mapBox(),
        const SizedBox(height: 14),
        _legend(),
        const SizedBox(height: 20),
        const Text(
          'Pregled',
          style: TextStyle(
            color: Color(0xFFC9D4FF),
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          const Text(
            'Nema podataka za prikaz.',
            style: TextStyle(color: Colors.white70),
          )
        else
          ...items.map(_postcodeCard),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: fetchMapData,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text(
            'BKIC Map',
            style: TextStyle(
              color: Color(0xFFD4AF37),
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pregled članova po poštanskom broju.',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 18),
          _content(),
        ],
      ),
    );
  }
}