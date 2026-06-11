import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/session_scope.dart';
import '../services/auth_service.dart';
import '../widgets/premium_card.dart';
import 'forgot_password_screen.dart';
import 'main_navigation_screen.dart';
import 'membership_signup_placeholder.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool loading = false;
  String error = '';
  bool obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        error = 'Unesite e-mail i lozinku.';
      });
      return;
    }

    setState(() {
      loading = true;
      error = '';
    });

    try {
      final success = await AuthService.login(email, password);

      if (!mounted) return;

      if (!success) {
        setState(() {
          error = 'Prijava nije uspjela. Provjerite podatke i pokušajte ponovo.';
          loading = false;
        });
        return;
      }

      SessionScope.of(context).value++;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const MainNavigationScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = 'Greška pri prijavi: $e';
        loading = false;
      });
      return;
    }

    if (!mounted) return;

    setState(() {
      loading = false;
    });
  }

  void _openMembership() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MembershipSignupPlaceholder(),
      ),
    );
  }

  void _openForgotPasswordScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ForgotPasswordScreen(
          initialEmail: emailController.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F5),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF7F8F5),
              Color(0xFFEAF4EF),
              Color(0xFFFFF6DF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: PremiumCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Image.network(
                          'https://bkicsaff.dk/wp-content/uploads/2026/06/BKIC_SAFF_Logo_2.png',
                          height: 92,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'Prijava',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF17211D),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Prijavite se na svoj BKIC SAFF račun',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF6D756F),
                          fontSize: 15.5,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 28),
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(color: Color(0xFF17211D)),
                        decoration: const InputDecoration(
                          labelText: 'E-mail',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => loading ? null : _login(),
                        style: const TextStyle(color: Color(0xFF17211D)),
                        decoration: InputDecoration(
                          labelText: 'Lozinka',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                obscurePassword = !obscurePassword;
                              });
                            },
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (error.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEDEA),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFFFC9C2),
                            ),
                          ),
                          child: Text(
                            error,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFB3261E),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      SizedBox(
                        height: 52,
                        child: FilledButton(
                          onPressed: loading ? null : _login,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF0F4F3A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Prijava',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: _openMembership,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0F4F3A),
                            side: const BorderSide(color: Color(0xFFE1E5DF)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text(
                            'Budi član',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextButton(
                        onPressed: loading ? null : _openForgotPasswordScreen,
                        child: const Text(
                          'Zaboravili ste lozinku?',
                          style: TextStyle(
                            color: Color(0xFF0F4F3A),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}