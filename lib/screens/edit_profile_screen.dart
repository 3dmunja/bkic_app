import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/constants.dart';
import '../models/membership_model.dart';
import '../services/api_helper.dart';
import '../widgets/glass_panel.dart';

class EditProfileScreen extends StatefulWidget {
  final Membership membership;

  const EditProfileScreen({
    super.key,
    required this.membership,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final formKey = GlobalKey<FormState>();

  late final TextEditingController firstNameController;
  late final TextEditingController lastNameController;
  late final TextEditingController emailController;
  late final TextEditingController phoneController;

  bool saving = false;
  String error = '';

  @override
  void initState() {
    super.initState();

    firstNameController = TextEditingController(
      text: widget.membership.firstName,
    );
    lastNameController = TextEditingController(
      text: widget.membership.lastName,
    );
    emailController = TextEditingController(
      text: widget.membership.email,
    );
    phoneController = TextEditingController(
      text: widget.membership.phone,
    );
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> saveProfile() async {
    if (!formKey.currentState!.validate()) return;

    setState(() {
      saving = true;
      error = '';
    });

    try {
      await ApiHelper.postJson(
        updateProfileEndpoint,
        authRequired: true,
        body: {
          'first_name': firstNameController.text.trim(),
          'last_name': lastNameController.text.trim(),
          'email': emailController.text.trim(),
          'phone': phoneController.text.trim(),
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil je uspješno ažuriran.'),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = 'Greška pri spremanju profila: $e';
        saving = false;
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
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1.5,
        ),
      ),
    );
  }

  Widget field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(
        color: Color(0xFF1B1408),
        fontWeight: FontWeight.w800,
        fontSize: 15.5,
      ),
      decoration: inputDecoration(label, icon),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Uredi profil'),
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
                    'Profil',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.blueText2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ažurirajte svoje kontakt podatke.',
                    style: TextStyle(
                      color: Color(0xFFE7DFD2),
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 20),

                  field(
                    controller: firstNameController,
                    label: 'Ime',
                    icon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 14),

                  field(
                    controller: lastNameController,
                    label: 'Prezime',
                    icon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 14),

                  field(
                    controller: emailController,
                    label: 'Email',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
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
                  const SizedBox(height: 14),

                  field(
                    controller: phoneController,
                    label: 'Telefon',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),

                  if (error.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      error,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],

                  const SizedBox(height: 22),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: saving ? null : saveProfile,
                      icon: saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                              ),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(
                        saving ? 'Spremanje...' : 'Spremi promjene',
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