import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/constants.dart';
import '../services/api_helper.dart';
import '../widgets/glass_panel.dart';

class AdminMailScreen extends StatefulWidget {
  const AdminMailScreen({super.key});

  @override
  State<AdminMailScreen> createState() => _AdminMailScreenState();
}

class _AdminMailScreenState extends State<AdminMailScreen> {
  final formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final subjectController = TextEditingController();
  final messageController = TextEditingController();

  bool loadingInbox = true;
  bool sending = false;
  String error = '';
  String inboxError = '';
  List<Map<String, dynamic>> inbox = [];

  @override
  void initState() {
    super.initState();
    fetchInbox();
  }

  @override
  void dispose() {
    emailController.dispose();
    subjectController.dispose();
    messageController.dispose();
    super.dispose();
  }

  Future<void> fetchInbox() async {
    setState(() {
      loadingInbox = true;
      inboxError = '';
    });

    try {
      final res = await ApiHelper.getJson(
        '$baseUrl/admin-mail/inbox',
        includeAuthIfAvailable: true,
      );

      final data = res['data'] is List
          ? List<Map<String, dynamic>>.from(
              (res['data'] as List).map(
                (e) => Map<String, dynamic>.from(e as Map),
              ),
            )
          : <Map<String, dynamic>>[];

      if (!mounted) return;

      setState(() {
        inbox = data;
        loadingInbox = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        inboxError = 'Greška pri učitavanju indbakke: $e';
        loadingInbox = false;
      });
    }
  }

  Future<void> sendMail() async {
    if (!formKey.currentState!.validate()) return;

    setState(() {
      sending = true;
      error = '';
    });

    try {
      final res = await ApiHelper.postJson(
        '$baseUrl/admin-mail/send',
        authRequired: true,
        body: {
          'email': emailController.text.trim(),
          'subject': subjectController.text.trim(),
          'message': messageController.text.trim(),
        },
      );

      if (!mounted) return;

      if (res['success'] == true) {
        emailController.clear();
        subjectController.clear();
        messageController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('E-mail je uspješno poslan.'),
          ),
        );
      } else {
        setState(() {
          error = res['message']?.toString() ?? 'E-mail nije poslan.';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = 'Greška pri slanju e-maila: $e';
      });
    } finally {
      if (!mounted) return;

      setState(() {
        sending = false;
      });
    }
  }

  Future<void> deleteMail(String id) async {
    try {
      final res = await ApiHelper.postJson(
        '$baseUrl/admin/mail/delete',
        authRequired: true,
        body: {
          'id': id,
        },
      );

      if (!mounted) return;

      if (res['success'] == true) {
        setState(() {
          inbox.removeWhere((item) => item['id']?.toString() == id);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('E-mail je obrisan.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Greška pri brisanju: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void openMail(Map<String, dynamic> mail) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _AdminMailDetailScreen(
          mail: mail,
          onReplySent: fetchInbox,
          onDeleted: () {
            final id = mail['id']?.toString() ?? '';
            if (id.isNotEmpty) {
              setState(() {
                inbox.removeWhere((item) => item['id']?.toString() == id);
              });
            }
          },
        ),
      ),
    );
  }

  InputDecoration inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: const Color(0x1810A05A),
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIconColor: AppColors.gold,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0x3348A66A)),
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

  Widget field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int minLines = 1,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      minLines: minLines,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),
      decoration: inputDecoration(label, icon),
    );
  }

  Widget _buildInbox() {
    if (loadingInbox) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (inboxError.isNotEmpty) {
      return Column(
        children: [
          Text(
            inboxError,
            style: const TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: fetchInbox,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: const Color(0xFF1B1408),
            ),
            child: const Text('Prøv igen'),
          ),
        ],
      );
    }

    if (inbox.isEmpty) {
      return const Text(
        'Indbakken er tom.',
        style: TextStyle(color: Colors.white70),
      );
    }

    return Column(
      children: inbox.map((mail) {
        final id = mail['id']?.toString() ?? '';
        final from = mail['from']?.toString() ?? '';
        final subject = mail['subject']?.toString() ?? '(bez predmeta)';
        final date = mail['date']?.toString() ?? '';
        final preview = mail['preview']?.toString() ?? '';

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: const Color(0x1810A05A),
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              onTap: () => openMail(mail),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0x3348A66A)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.mail_outline, color: AppColors.gold),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subject,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFE8FFF2),
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            from,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          if (date.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              date,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                          if (preview.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              preview,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white60),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: id.isEmpty ? null : () => deleteMail(id),
                      icon: const Icon(Icons.delete_outline),
                      color: Colors.redAccent,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSendForm() {
    return GlassPanel(
      radius: 24,
      padding: const EdgeInsets.all(18),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nova e-mail poruka',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFFE8FFF2),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pošaljite e-mail članovima ili pojedinačnom korisniku.',
              style: TextStyle(
                color: Colors.white70,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            field(
              controller: emailController,
              label: 'E-mail primaoca',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                final email = value?.trim() ?? '';

                if (email.isEmpty) {
                  return 'E-mail je obavezan.';
                }

                if (!email.contains('@') || !email.contains('.')) {
                  return 'Unesite validan e-mail.';
                }

                return null;
              },
            ),
            const SizedBox(height: 14),
            field(
              controller: subjectController,
              label: 'Predmet',
              icon: Icons.subject_outlined,
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Predmet je obavezan.';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            field(
              controller: messageController,
              label: 'Poruka',
              icon: Icons.message_outlined,
              minLines: 6,
              maxLines: 10,
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Poruka je obavezna.';
                }
                return null;
              },
            ),
            if (error.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                error,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: sending ? null : sendMail,
                icon: sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                        ),
                      )
                    : const Icon(Icons.send_outlined),
                label: Text(
                  sending ? 'Šalje se...' : 'Pošalji e-mail',
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: fetchInbox,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GlassPanel(
              radius: 24,
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Admin Mail',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFE8FFF2),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Fælles indbakke for kontakt@bkicsaff.dk.',
                    style: TextStyle(
                      color: Colors.white70,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildInbox(),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _buildSendForm(),
          ],
        ),
      ),
    );
  }
}

class _AdminMailDetailScreen extends StatefulWidget {
  final Map<String, dynamic> mail;
  final VoidCallback onReplySent;
  final VoidCallback onDeleted;

  const _AdminMailDetailScreen({
    required this.mail,
    required this.onReplySent,
    required this.onDeleted,
  });

  @override
  State<_AdminMailDetailScreen> createState() => _AdminMailDetailScreenState();
}

class _AdminMailDetailScreenState extends State<_AdminMailDetailScreen> {
  final replyController = TextEditingController();

  bool replying = false;
  bool deleting = false;
  String error = '';

  @override
  void dispose() {
    replyController.dispose();
    super.dispose();
  }

  Future<void> replyMail() async {
    final id = widget.mail['id']?.toString() ?? '';
    final message = replyController.text.trim();

    if (id.isEmpty || message.isEmpty) return;

    setState(() {
      replying = true;
      error = '';
    });

    try {
      final res = await ApiHelper.postJson(
        '$baseUrl/admin/mail/reply',
        authRequired: true,
        body: {
          'id': id,
          'message': message,
        },
      );

      if (!mounted) return;

      if (res['success'] == true) {
        replyController.clear();
        widget.onReplySent();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Odgovor je poslan.'),
          ),
        );
      } else {
        setState(() {
          error = res['message']?.toString() ?? 'Odgovor nije poslan.';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = 'Greška pri slanju odgovora: $e';
      });
    } finally {
      if (!mounted) return;

      setState(() {
        replying = false;
      });
    }
  }

  Future<void> deleteMail() async {
    final id = widget.mail['id']?.toString() ?? '';
    if (id.isEmpty) return;

    setState(() {
      deleting = true;
      error = '';
    });

    try {
      final res = await ApiHelper.postJson(
        '$baseUrl/admin/mail/delete',
        authRequired: true,
        body: {
          'id': id,
        },
      );

      if (!mounted) return;

      if (res['success'] == true) {
        widget.onDeleted();

        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('E-mail je obrisan.'),
          ),
        );
      } else {
        setState(() {
          error = res['message']?.toString() ?? 'E-mail nije obrisan.';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = 'Greška pri brisanju: $e';
      });
    } finally {
      if (!mounted) return;

      setState(() {
        deleting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final from = widget.mail['from']?.toString() ?? '';
    final subject = widget.mail['subject']?.toString() ?? '(bez predmeta)';
    final date = widget.mail['date']?.toString() ?? '';
    final body = widget.mail['body']?.toString() ??
        widget.mail['preview']?.toString() ??
        '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('E-mail'),
        backgroundColor: AppColors.background,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: deleting ? null : deleteMail,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlassPanel(
            radius: 24,
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFE8FFF2),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  from,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (date.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: const TextStyle(color: Colors.white54),
                  ),
                ],
                const SizedBox(height: 18),
                Text(
                  body,
                  style: const TextStyle(
                    color: Colors.white,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          GlassPanel(
            radius: 24,
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Svar',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFE8FFF2),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: replyController,
                  minLines: 5,
                  maxLines: 8,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Skriv svar',
                    filled: true,
                    fillColor: const Color(0x1810A05A),
                    labelStyle: const TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide:
                          const BorderSide(color: Color(0x3348A66A)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppColors.gold,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                if (error.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    error,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: replying ? null : replyMail,
                    icon: replying
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                            ),
                          )
                        : const Icon(Icons.reply_outlined),
                    label: Text(
                      replying ? 'Šalje se...' : 'Pošalji svar',
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
        ],
      ),
    );
  }
}