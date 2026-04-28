import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/constants.dart';
import '../services/api_helper.dart';
import '../widgets/glass_panel.dart';

class ContactTab extends StatefulWidget {
  const ContactTab({super.key});

  @override
  State<ContactTab> createState() => _ContactTabState();
}

class _ContactTabState extends State<ContactTab> {
  bool loading = true;
  String error = '';
  String email = '';
  String address = '';
  String phone = '';
  String pageUrl = '';

  @override
  void initState() {
    super.initState();
    fetchContact();
  }

  Future<void> fetchContact() async {
    setState(() {
      loading = true;
      error = '';
    });

    try {
      final data = await ApiHelper.getJson(contactEndpoint);

      if (!mounted) return;

      if (data['success'] == true) {
        final contact = data['data'] as Map<String, dynamic>? ?? {};

        setState(() {
          email = contact['email']?.toString().trim() ?? '';
          address = contact['address']?.toString().trim() ?? '';
          phone = contact['phone']?.toString().trim() ?? '';
          pageUrl = contact['page_url']?.toString().trim() ?? '';
          loading = false;
        });
      } else {
        setState(() {
          error =
              data['message']?.toString() ?? 'Nije moguće učitati kontakt.';
          loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = 'Greška mreže: $e';
        loading = false;
      });
    }
  }

  Widget infoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return GlassPanel(
      padding: const EdgeInsets.all(18),
      radius: 18,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.gold),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.blueText2,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? 'Nije navedeno' : value,
                  style: const TextStyle(
                    color: Colors.white70,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: fetchContact,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: const Color(0xFF1B1408),
              ),
              child: const Text(
                'Pokušaj ponovo',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageLinkCard() {
    if (pageUrl.isEmpty) return const SizedBox.shrink();

    return GlassPanel(
      padding: const EdgeInsets.all(18),
      radius: 18,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.public, color: AppColors.gold),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Web stranica',
                  style: TextStyle(
                    color: AppColors.blueText2,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  pageUrl,
                  style: const TextStyle(
                    color: Colors.white70,
                    height: 1.45,
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
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error.isNotEmpty) {
      return _errorView();
    }

    return RefreshIndicator(
      onRefresh: fetchContact,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          infoCard(icon: Icons.email, title: 'E-mail', value: email),
          const SizedBox(height: 12),
          infoCard(icon: Icons.location_on, title: 'Adresa', value: address),
          const SizedBox(height: 12),
          infoCard(icon: Icons.phone, title: 'Telefon', value: phone),
          if (pageUrl.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildPageLinkCard(),
          ],
        ],
      ),
    );
  }
}