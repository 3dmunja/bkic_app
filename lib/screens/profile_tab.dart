import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/constants.dart';
import '../core/session_scope.dart';
import '../models/membership_model.dart';
import '../services/api_helper.dart';
import '../services/auth_service.dart';
import '../widgets/premium_card.dart';
import 'edit_profile_screen.dart';
import 'forgot_password_screen.dart';
import 'login_screen.dart';
import 'stripe_card_payment_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  Membership? membership;
  bool loading = true;
  bool loggingOut = false;
  bool paying = false;
  String error = '';
  int? selectedYear;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Map<String, dynamic> _normalizeMembershipPayload(Map<String, dynamic> raw) {
    final normalized = Map<String, dynamic>.from(raw);

    for (final key in ['user', 'profile', 'member', 'membership', 'customer']) {
      final value = raw[key];

      if (value is Map) {
        normalized.addAll(Map<String, dynamic>.from(value));
      }
    }

    return normalized;
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
          ? Map<String, dynamic>.from(res['data'])
          : Map<String, dynamic>.from(res);

      final parsed = Membership.fromJson(_normalizeMembershipPayload(payload));

      if (!mounted) return;

      setState(() {
        membership = parsed;
        selectedYear =
            parsed.availableYears.isNotEmpty ? parsed.availableYears.first : null;
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

    setState(() => loggingOut = true);

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

  Future<void> _openEditProfile(Membership m) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(membership: m),
      ),
    );

    if (updated == true) {
      await loadData();
    }
  }

  Future<void> _openForgotPassword(Membership m) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ForgotPasswordScreen(
          initialEmail: m.email,
        ),
      ),
    );
  }

  Future<void> _payNative(int year) async {
    if (paying) return;

    setState(() {
      paying = true;
      selectedYear = year;
    });

    try {
      final success = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => StripeCardPaymentScreen(year: year),
        ),
      );

      if (!mounted) return;

      if (success == true) {
        _showMessage('Plaćanje za $year završeno ✅');
        await loadData();
      } else {
        _showMessage('Plaćanje nije završeno.');
      }
    } catch (e) {
      if (!mounted) return;
      _showMessage('Greška pri plaćanju: $e');
    } finally {
      if (mounted) {
        setState(() => paying = false);
      }
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _initials(Membership m) {
    final name = m.fullName.trim();
    if (name.isEmpty) return '?';

    final parts = name.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();

    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }

    return name[0].toUpperCase();
  }

  Widget _profileHeaderCard(Membership m) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4EF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE1E5DF)),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.gold,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Text(
                _initials(m),
                style: const TextStyle(
                  color: Color(0xFF1B1408),
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF17211D),
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  m.emailText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF6D756F),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (m.phone.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    m.phoneText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF6D756F),
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color:
                  m.isActive ? const Color(0xFFEAF4EF) : const Color(0xFFFFF6DF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: m.isActive
                    ? const Color(0xFFBFDCCD)
                    : const Color(0xFFE8D59A),
              ),
            ),
            child: Text(
              m.statusText,
              style: TextStyle(
                color: m.isActive
                    ? const Color(0xFF0F4F3A)
                    : const Color(0xFFC18414),
                fontWeight: FontWeight.w900,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w900,
        color: Color(0xFF17211D),
      ),
    );
  }

  Widget _statusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 115,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Color(0xFF6D756F),
                fontWeight: FontWeight.w800,
                fontSize: 15.5,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF17211D),
                fontSize: 15.5,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBanner(Membership m) {
    final text = m.warning.isNotEmpty
        ? m.warning
        : m.isActive
            ? '✔ Uplata je evidentirana'
            : '✖ Uplata nije evidentirana';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: m.isActive ? const Color(0xFFEAF4EF) : const Color(0xFFFFF6DF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: m.isActive ? const Color(0xFFBFDCCD) : const Color(0xFFE8D59A),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: m.isActive ? const Color(0xFF0F4F3A) : const Color(0xFFC18414),
          fontWeight: FontWeight.w800,
          fontSize: 15.5,
          height: 1.35,
        ),
      ),
    );
  }

  Widget _paymentBox(Membership m) {
    final years = m.availableYears;

    if (years.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8F5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE1E5DF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nedostajuće članarine',
            style: TextStyle(
              color: Color(0xFF17211D),
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Odaberite godinu koju želite platiti.',
            style: TextStyle(
              color: Color(0xFF6D756F),
              fontSize: 14.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          ...years.map((year) {
            final isSelected = selectedYear == year;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFFF6DF) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.gold : const Color(0xFFE1E5DF),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        year.toString().substring(2),
                        style: const TextStyle(
                          color: Color(0xFF1B1408),
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Članarina $year',
                          style: const TextStyle(
                            color: Color(0xFF17211D),
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Plaćanje nije evidentirano',
                          style: TextStyle(
                            color: Color(0xFFC18414),
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton(
                    onPressed: paying ? null : () => _payNative(year),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0F4F3A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    child: paying && isSelected
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Plati',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 4),
          Text(
            'Ukupno nedostaje: ${years.length}',
            style: const TextStyle(
              color: Color(0xFF0F4F3A),
              fontWeight: FontWeight.w800,
              fontSize: 14.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _membershipOverviewCard(Membership m) {
    return PremiumCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Status članstva',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF17211D),
            ),
          ),
          const SizedBox(height: 14),
          _statusBanner(m),
          _paymentBox(m),
          const SizedBox(height: 18),
          _statusRow('Status', m.statusText),
          _statusRow('Tip', m.typeText),
          _statusRow('Član od', m.memberSinceText),
          _statusRow('Plaćeno do', m.validUntilText),
          _statusRow('Nedostaje', m.missingYearsText),
        ],
      ),
    );
  }

  Widget _profileActions(Membership m) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Profil'),
        const SizedBox(height: 8),
        const Text(
          'Uredi profil i kontakt podatke ili promijeni lozinku.',
          style: TextStyle(
            color: Color(0xFF6D756F),
            fontSize: 16,
            height: 1.7,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => _openEditProfile(m),
            icon: const Icon(Icons.person_outline_rounded),
            label: const Text(
              'Uredi profil',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0F4F3A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _openForgotPassword(m),
            icon: const Icon(Icons.lock_reset_rounded),
            label: const Text(
              'Zaboravili ste lozinku?',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0F4F3A),
              side: const BorderSide(color: Color(0xFFE1E5DF)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
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
                    border: Border.all(color: const Color(0xFFE1E5DF)),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Color(0xFF0F4F3A),
                      ),
                    ),
                  ),
                )
              : OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text(
                    'Odjavi se',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFB3261E),
                    side: const BorderSide(color: Color(0xFFFFC9C2)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
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
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF0F4F3A),
        ),
      );
    }

    if (error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFB3261E),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    final m = membership;

    if (m == null) {
      return const Center(
        child: Text(
          'Profil nije pronađen.',
          style: TextStyle(color: Color(0xFF17211D)),
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF0F4F3A),
      backgroundColor: Colors.white,
      onRefresh: loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          PremiumCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _profileHeaderCard(m),
                const Text(
                  'Moj račun',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF17211D),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Pogledaj status članstva, uplati godine koje nedostaju i upravljaj svojim računom.',
                  style: TextStyle(
                    color: Color(0xFF6D756F),
                    fontSize: 16,
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: 18),
                _membershipOverviewCard(m),
                const SizedBox(height: 18),
                _profileActions(m),
              ],
            ),
          ),
        ],
      ),
    );
  }
}