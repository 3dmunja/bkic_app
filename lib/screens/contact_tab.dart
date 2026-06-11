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
  bool sending = false;
  String error = '';
  String formError = '';
  String email = '';
  String address = '';
  String phone = '';
  String pageUrl = '';

  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final subjectController = TextEditingController();
  final emailController = TextEditingController();
  final messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchContact();
  }

  @override
  void dispose() {
    nameController.dispose();
    subjectController.dispose();
    emailController.dispose();
    messageController.dispose();
    super.dispose();
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

  Future<void> sendMessage() async {
    if (!formKey.currentState!.validate()) return;

    setState(() {
      sending = true;
      formError = '';
    });

    try {
      final data = await ApiHelper.postJson(
        '$baseUrl/contact/send',
        body: {
          'name': nameController.text.trim(),
          'subject': subjectController.text.trim(),
          'email': emailController.text.trim(),
          'message': messageController.text.trim(),
        },
      );

      if (!mounted) return;

      if (data['success'] == true) {
        nameController.clear();
        subjectController.clear();
        emailController.clear();
        messageController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Poruka je uspješno poslana.'),
          ),
        );
      } else {
        setState(() {
          formError = data['message']?.toString() ?? 'Poruka nije poslana.';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        formError = 'Greška pri slanju poruke: $e';
      });
    } finally {
      if (!mounted) return;

      setState(() {
        sending = false;
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
                    color: Color(0xFF183B32),
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? 'Nije navedeno' : value,
                  style: const TextStyle(
                    color: Color(0xFF6E6558),
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

  InputDecoration inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF8F5EF),
      labelStyle: const TextStyle(color: Color(0xFF6E6558)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE6DDCC)),
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

  Widget _contactForm() {
    return GlassPanel(
      padding: const EdgeInsets.all(18),
      radius: 18,
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pošaljite poruku',
              style: TextStyle(
                color: Color(0xFF183B32),
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ispunite polja ispod. Vaš e-mail ćemo koristiti samo da vam odgovorimo.',
              style: TextStyle(
                color: Color(0xFF6E6558),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: nameController,
              style: const TextStyle(color: Color(0xFF2F302C)),
              decoration: inputDecoration('Ime *'),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Ime je obavezno.';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: subjectController,
              style: const TextStyle(color: Color(0xFF2F302C)),
              decoration: inputDecoration('Predmet'),
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Color(0xFF2F302C)),
              decoration: inputDecoration('E-mail *'),
              validator: (value) {
                final emailValue = (value ?? '').trim();

                if (emailValue.isEmpty) {
                  return 'E-mail je obavezan.';
                }

                if (!emailValue.contains('@') || !emailValue.contains('.')) {
                  return 'Unesite validan e-mail.';
                }

                return null;
              },
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: messageController,
              minLines: 5,
              maxLines: 8,
              style: const TextStyle(color: Color(0xFF2F302C)),
              decoration: inputDecoration('Poruka *'),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Poruka je obavezna.';
                }
                return null;
              },
            ),

            if (formError.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                formError,
                style: const TextStyle(
                  color: Color(0xFF9B3A3A),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],

            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: sending ? null : sendMessage,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: const Color(0xFF1B1408),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Pošalji poruku',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: GlassPanel(
          padding: const EdgeInsets.all(20),
          radius: 22,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF9B3A3A),
                  fontSize: 16,
                  height: 1.5,
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
                    color: Color(0xFF183B32),
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  pageUrl,
                  style: const TextStyle(
                    color: Color(0xFF6E6558),
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
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.gold,
        ),
      );
    }

    if (error.isNotEmpty) {
      return _errorView();
    }

    return RefreshIndicator(
      color: AppColors.gold,
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
          const SizedBox(height: 18),
          _contactForm(),
        ],
      ),
    );
  }
}