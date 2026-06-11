import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../services/api_helper.dart';
import '../services/auth_service.dart';
import 'forgot_password_webview_screen.dart';
import 'login_screen.dart';
import 'profile_tab.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool loading = true;
  bool loggedIn = false;
  Map<String, dynamic> membership = {};

  @override
  void initState() {
    super.initState();
    _loadAccount();
  }

  Future<void> _loadAccount() async {
    final isLoggedIn = await AuthService.isLoggedIn();

    if (!mounted) return;

    if (!isLoggedIn) {
      setState(() {
        loggedIn = false;
        loading = false;
      });
      return;
    }

    try {
      final res = await ApiHelper.getJson(
        membershipEndpoint,
        includeAuthIfAvailable: true,
      );

      if (!mounted) return;

      setState(() {
        loggedIn = true;
        membership =
            res['data'] is Map ? Map<String, dynamic>.from(res['data']) : {};
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        loggedIn = true;
        loading = false;
      });
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  void _open(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  String _read(String key) {
    final value = membership[key];
    return value == null ? '' : value.toString();
  }

  List<dynamic> _readList(String key) {
    final value = membership[key];
    return value is List ? value : [];
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

    if (!loggedIn) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _LoginNoticeCard(),
        ],
      );
    }

    final status = _read('status');
    final warning = _read('warning');
    final validUntil = _read('valid_until');
    final memberSince = _read('member_since');
    final paidYears = _readList('paid_years');
    final missingYears = _readList('missing_years');

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _TitleRow(title: 'Moj račun'),
              const SizedBox(height: 14),
              const Text(
                'Pogledajte status članstva, uplatite godine koje nedostaju i upravljajte svojim računom.',
                style: TextStyle(
                  color: Color(0xFF6E6558),
                  fontSize: 16,
                  height: 1.8,
                ),
              ),
              const SizedBox(height: 18),
              _StatusBox(
                children: [
                  _StatusLine(
                    label: 'Status',
                    value: status == 'active' ? 'Aktivan član' : 'Nije aktivno',
                  ),
                  if (warning.isNotEmpty)
                    _StatusLine(
                      label: 'Članarina',
                      value: warning,
                    ),
                  if (validUntil.isNotEmpty)
                    _StatusLine(
                      label: 'Važi do',
                      value: validUntil,
                    ),
                  if (memberSince.isNotEmpty)
                    _StatusLine(
                      label: 'Član od',
                      value: memberSince,
                    ),
                  _StatusLine(
                    label: 'Plaćeno',
                    value: paidYears.isEmpty ? '—' : paidYears.join(', '),
                  ),
                  _StatusLine(
                    label: 'Nedostaje',
                    value: missingYears.isEmpty ? '—' : missingYears.join(', '),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Profil',
                style: TextStyle(
                  color: Color(0xFF183B32),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Uredite profil i kontakt podatke ili promijenite lozinku.',
                style: TextStyle(
                  color: Color(0xFF6E6558),
                  fontSize: 16,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 18),
              _AccountButton(
                text: 'Uredi profil',
                primary: true,
                onTap: () => _open(const ProfileTab()),
              ),
              const SizedBox(height: 12),
              _AccountButton(
                text: 'Zaboravili ste lozinku?',
                onTap: () => _open(const ForgotPasswordWebViewScreen()),
              ),
              const SizedBox(height: 12),
              _AccountButton(
                text: 'Odjavi se',
                onTap: _logout,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LoginNoticeCard extends StatelessWidget {
  const _LoginNoticeCard();

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _TitleRow(title: 'Prijava'),
          const SizedBox(height: 14),
          const Text(
            'Morate biti prijavljeni da biste pristupili svom računu.',
            style: TextStyle(
              color: Color(0xFF6E6558),
              fontSize: 16,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 18),
          _AccountButton(
            text: 'Prijava',
            primary: true,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8E1D5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _TitleRow extends StatelessWidget {
  final String title;

  const _TitleRow({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF183B32),
        fontSize: 26,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _StatusBox extends StatelessWidget {
  final List<Widget> children;

  const _StatusBox({
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5EF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8E1D5)),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  final String label;
  final String value;

  const _StatusLine({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 95,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Color(0xFF9F7A32),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF2F302C),
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final bool primary;

  const _AccountButton({
    required this.text,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor:
              primary ? const Color(0xFFCAA25A) : const Color(0xFFF8F5EF),
          foregroundColor:
              primary ? const Color(0xFF1B1408) : const Color(0xFF183B32),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color:
                  primary ? Colors.transparent : const Color(0xFFE8E1D5),
            ),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}