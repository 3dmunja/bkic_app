import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/constants.dart';
import '../services/api_helper.dart';
import '../widgets/glass_panel.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String initialEmail;

  const ForgotPasswordScreen({
    super.key,
    this.initialEmail = '',
  });

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController emailController;

  bool loading = false;
  String message = '';
  String error = '';

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> sendResetLink() async {
    if (!formKey.currentState!.validate()) return;

    setState(() {
      loading = true;
      message = '';
      error = '';
    });

    try {
      final res = await ApiHelper.postJson(
        forgotPasswordEndpoint,
        body: {
          'email': emailController.text.trim(),
        },
      );

      if (!mounted) return;

      setState(() {
        message = res['message']?.toString() ??
            'Link za promjenu lozinke je poslan na vaš e-mail.';
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = 'Greška: $e';
        loading = false;
      });
    }
  }

  InputDecoration inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      labelStyle: const TextStyle(
        color: Color(0xFF1B1408),
        fontWeight: FontWeight.w700,
      ),
      prefixIconColor: const Color(0xFF1B1408),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: AppColors.gold,
          width: 2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Zaboravili ste lozinku?'),
        backgroundColor: AppColors.background,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlassPanel(
            radius: 26,
            padding: const EdgeInsets.all(18),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Promjena lozinke',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.blueText2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Unesite e-mail adresu. Poslat ćemo vam link za promjenu lozinke.',
                    style: TextStyle(
                      color: Color(0xFFE7DFD2),
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(
                      color: Color(0xFF1B1408),
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: inputDecoration(
                      'Email',
                      Icons.email_outlined,
                    ),
                    validator: (value) {
                      final email = value?.trim() ?? '';

                      if (email.isEmpty) {
                        return 'Email je obavezan.';
                      }

                      if (!email.contains('@') || !email.contains('.')) {
                        return 'Unesite validan email.';
                      }

                      return null;
                    },
                  ),
                  if (message.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      message,
                      style: const TextStyle(
                        color: Color(0xFFBFF3CF),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                  if (error.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      error,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: loading ? null : sendResetLink,
                      icon: loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                              ),
                            )
                          : const Icon(Icons.lock_reset_rounded),
                      label: Text(
                        loading ? 'Šalje se...' : 'Pošalji link',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: const Color(0xFF1B1408),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}