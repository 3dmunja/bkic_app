import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_colors.dart';
import '../core/constants.dart';
import '../core/session_scope.dart';
import '../models/membership_model.dart';
import '../services/api_helper.dart';
import '../services/auth_service.dart';
import '../widgets/glass_panel.dart';
import 'login_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  Membership? membership;
  bool loading = true;
  bool loggingOut = false;
  String error = '';
  int? selectedYear;
  bool showMissingYears = false;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    if (!mounted) return;

    setState(() {
      loading = true;
      error = '';
    });

    try {
      final res = await ApiHelper.getJson(
        membershipEndpoint,
        authRequired: true,
      );

      final payload = (res['data'] is Map<String, dynamic>)
          ? Map<String, dynamic>.from(res['data'] as Map<String, dynamic>)
          : Map<String, dynamic>.from(res);

      final parsedMembership = Membership.fromJson(payload);

      if (!mounted) return;

      setState(() {
        membership = parsedMembership;
        selectedYear = parsedMembership.availableYears.isNotEmpty
            ? parsedMembership.availableYears.first
            : (parsedMembership.selectedYear > 0
                ? parsedMembership.selectedYear
                : null);
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = 'Greška pri učitavanju profila: $e';
        loading = false;
      });
    }
  }

  Future<void> _logout() async {
    if (loggingOut) return;

    setState(() {
      loggingOut = true;
    });

    try {
      await AuthService.logout();
    } catch (_) {
      await AuthService.clearToken();
    }

    if (!mounted) return;

    SessionScope.of(context).value++;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  /// 🔥 NY: Åbn WordPress profil
  Future<void> _openEditProfile() async {
    final uri = Uri.parse('https://bkicsaff.dk/uredi-profil-2/');

    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!opened && mounted) {
      _showSoon('Profil-siden kunne ikke åbnes.');
    }
  }

  void _showSoon(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  String _statusLabel(String status) {
    switch (status.trim().toLowerCase()) {
      case 'active':
        return 'Aktivno';
      case 'inactive':
        return 'Neaktivno';
      default:
        return status.isEmpty ? 'Nepoznato' : status;
    }
  }

  String _buildPayUrlForSelectedYear(Membership m) {
    if (m.payUrl.isEmpty || selectedYear == null) {
      return '';
    }

    try {
      final uri = Uri.parse(m.payUrl);
      final updated = uri.replace(
        queryParameters: {
          ...uri.queryParameters,
          'bkic_year': selectedYear.toString(),
        },
      );
      return updated.toString();
    } catch (_) {
      return m.payUrl;
    }
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w900,
        color: AppColors.blueText2,
      ),
    );
  }

  Widget _statusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Color(0xFFF5EFE3),
                fontWeight: FontWeight.w800,
                fontSize: 15.5,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15.5,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _warningBanner(Membership m) {
    if (m.warning.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Text(
              '✔',
              style: TextStyle(
                color: Color(0xFFE6D08F),
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              m.warning,
              style: const TextStyle(
                color: Color(0xFFE6D08F),
                fontWeight: FontWeight.w700,
                fontSize: 15.5,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _membershipOverviewCard(Membership m) {
    return GlassPanel(
      radius: 18,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _warningBanner(m),
          if (m.warning.isNotEmpty) const SizedBox(height: 16),
          _statusRow('Status', _statusLabel(m.status)),
          _statusRow('Tip', m.type.isEmpty ? 'Nije navedeno' : m.type),
          _statusRow(
            'Važi do',
            m.validUntil.isEmpty ? 'Nije navedeno' : m.validUntil,
          ),
          _statusRow(
            'Član od',
            m.memberSince > 0 ? m.memberSince.toString() : 'Nije navedeno',
          ),
          _statusRow('Nedostaje', m.missingCount.toString()),
        ],
      ),
    );
  }

  Widget _profileActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Profil'),
        const SizedBox(height: 8),
        const Text(
          'Uredi profil i kontakt podatke ili promijeni lozinku.',
          style: TextStyle(
            color: Color(0xFFE7DFD2),
            fontSize: 16,
            height: 1.7,
          ),
        ),
        const SizedBox(height: 16),

        /// 🔥 HER ER FIXET KNAP
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _openEditProfile,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: const Color(0xFF1B1408),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Uredi profil',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              _showSoon('Promjena lozinke dolazi uskoro.');
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.text,
              side: const BorderSide(color: Color(0x26FFFFFF)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Zaboravili ste lozinku?',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          child: loggingOut
              ? Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0x26FFFFFF)),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    ),
                  ),
                )
              : OutlinedButton(
                  onPressed: _logout,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.text,
                    side: const BorderSide(color: Color(0x26FFFFFF)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Odjavi se',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error.isNotEmpty) {
      return Center(
        child: Text(error, style: const TextStyle(color: Colors.redAccent)),
      );
    }

    final m = membership!;

    return RefreshIndicator(
      onRefresh: loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlassPanel(
            radius: 26,
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Moj račun',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.blueText2,
                  ),
                ),
                const SizedBox(height: 18),
                _membershipOverviewCard(m),
                const SizedBox(height: 18),
                _profileActions(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}