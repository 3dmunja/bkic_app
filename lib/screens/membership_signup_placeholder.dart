import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../core/app_colors.dart';
import '../core/constants.dart';
import '../services/api_helper.dart';
import '../widgets/glass_panel.dart';

class MembershipSignupPlaceholder extends StatefulWidget {
  const MembershipSignupPlaceholder({super.key});

  @override
  State<MembershipSignupPlaceholder> createState() =>
      _MembershipSignupPlaceholderState();
}

class _MembershipSignupPlaceholderState
    extends State<MembershipSignupPlaceholder> {
  final TextEditingController imeController = TextEditingController();
  final TextEditingController prezimeController = TextEditingController();
  final TextEditingController adresaController = TextEditingController();
  final TextEditingController datumRodjenjaController =
      TextEditingController();
  final TextEditingController postanskiBrojController =
      TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController telefonController = TextEditingController();
  final TextEditingController lozinkaController = TextEditingController();
  final TextEditingController potvrdaLozinkeController =
      TextEditingController();

  bool loading = false;
  bool prihvatioGdpr = false;
  bool obscurePassword = true;
  bool obscurePassword2 = true;

  String error = '';
  String success = '';

  @override
  void dispose() {
    imeController.dispose();
    prezimeController.dispose();
    adresaController.dispose();
    datumRodjenjaController.dispose();
    postanskiBrojController.dispose();
    emailController.dispose();
    telefonController.dispose();
    lozinkaController.dispose();
    potvrdaLozinkeController.dispose();
    super.dispose();
  }

  Future<void> _odaberiDatumRodjenja() async {
    FocusScope.of(context).unfocus();

    final now = DateTime.now();
    final initialDate = DateTime(now.year - 18, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Odaberite datum rođenja',
      cancelText: 'Otkaži',
      confirmText: 'Odaberi',
    );

    if (picked == null || !mounted) return;

    final dan = picked.day.toString().padLeft(2, '0');
    final mjesec = picked.month.toString().padLeft(2, '0');
    final godina = picked.year.toString();

    setState(() {
      datumRodjenjaController.text = '$dan.$mjesec.$godina';
    });
  }

  void _otvoriGdprStranicu() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const _SimpleWebViewScreen(
          title: 'Politika privatnosti',
          url: 'https://bkicsaff.dk/privacy-policy/',
        ),
      ),
    );
  }

  String? _validirajEmail(String email) {
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!regex.hasMatch(email)) {
      return 'Unesite ispravnu e-mail adresu.';
    }
    return null;
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();

    final ime = imeController.text.trim();
    final prezime = prezimeController.text.trim();
    final adresa = adresaController.text.trim();
    final datumRodjenja = datumRodjenjaController.text.trim();
    final postanskiBroj = postanskiBrojController.text.trim();
    final email = emailController.text.trim();
    final telefon = telefonController.text.trim();
    final lozinka = lozinkaController.text;
    final potvrda = potvrdaLozinkeController.text;

    if (ime.isEmpty) {
      setState(() {
        error = 'Unesite ime.';
        success = '';
      });
      return;
    }

    if (prezime.isEmpty) {
      setState(() {
        error = 'Unesite prezime.';
        success = '';
      });
      return;
    }

    if (adresa.isEmpty) {
      setState(() {
        error = 'Unesite adresu.';
        success = '';
      });
      return;
    }

    if (postanskiBroj.isEmpty) {
      setState(() {
        error = 'Unesite poštanski broj.';
        success = '';
      });
      return;
    }

    if (email.isEmpty) {
      setState(() {
        error = 'Unesite e-mail adresu.';
        success = '';
      });
      return;
    }

    final emailError = _validirajEmail(email);
    if (emailError != null) {
      setState(() {
        error = emailError;
        success = '';
      });
      return;
    }

    if (telefon.isEmpty) {
      setState(() {
        error = 'Unesite broj telefona.';
        success = '';
      });
      return;
    }

    if (lozinka.isEmpty) {
      setState(() {
        error = 'Unesite lozinku.';
        success = '';
      });
      return;
    }

    if (lozinka.length < 6) {
      setState(() {
        error = 'Lozinka mora imati najmanje 6 karaktera.';
        success = '';
      });
      return;
    }

    if (potvrda.isEmpty) {
      setState(() {
        error = 'Potvrdite lozinku.';
        success = '';
      });
      return;
    }

    if (lozinka != potvrda) {
      setState(() {
        error = 'Lozinke se ne podudaraju.';
        success = '';
      });
      return;
    }

    if (!prihvatioGdpr) {
      setState(() {
        error = 'Morate prihvatiti Politiku privatnosti (GDPR).';
        success = '';
      });
      return;
    }

    setState(() {
      loading = true;
      error = '';
      success = '';
    });

    try {
      final res = await ApiHelper.postJson(
        registerEndpoint,
        body: {
          'name': '$ime $prezime',
          'first_name': ime,
          'last_name': prezime,
          'address': adresa,
          'birth_date': datumRodjenja,
          'postal_code': postanskiBroj,
          'email': email,
          'user_email': email,
          'phone': telefon,
          'password': lozinka,
          'confirm_password': potvrda,
          'gdpr': true,
        },
      );

      final message = res['message']?.toString().trim().isNotEmpty == true
          ? res['message'].toString()
          : 'Registracija je uspješna. Sada se možete prijaviti.';

      if (!mounted) return;

      imeController.clear();
      prezimeController.clear();
      adresaController.clear();
      datumRodjenjaController.clear();
      postanskiBrojController.clear();
      emailController.clear();
      telefonController.clear();
      lozinkaController.clear();
      potvrdaLozinkeController.clear();

      setState(() {
        success = message;
        error = '';
        loading = false;
        prihvatioGdpr = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = 'Greška pri registraciji: $e';
        success = '';
        loading = false;
      });
    }
  }

  InputDecoration _inputDecoration(
    String label, {
    Widget? suffixIcon,
    String? hintText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      filled: true,
      fillColor: const Color(0x22FFFFFF),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0x44FFFFFF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.gold),
      ),
      labelStyle: const TextStyle(color: Colors.white70),
      hintStyle: const TextStyle(color: Colors.white38),
      suffixIconColor: Colors.white70,
    );
  }

  Widget _tekstPolje({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    bool obscureText = false,
    Widget? suffixIcon,
    void Function(String)? onSubmitted,
    bool readOnly = false,
    VoidCallback? onTap,
    String? hintText,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      readOnly: readOnly,
      onTap: onTap,
      onSubmitted: onSubmitted,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(
        label,
        suffixIcon: suffixIcon,
        hintText: hintText,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budi član'),
      ),
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: GlassPanel(
              radius: 22,
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.workspace_premium_outlined,
                    size: 64,
                    color: AppColors.gold,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Registracija članstva',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.blueText2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Napravite svoj račun i postanite član BKIC SAFF zajednice.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  _tekstPolje(
                    controller: imeController,
                    label: 'Ime',
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  _tekstPolje(
                    controller: prezimeController,
                    label: 'Prezime',
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  _tekstPolje(
                    controller: adresaController,
                    label: 'Adresa',
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  _tekstPolje(
                    controller: datumRodjenjaController,
                    label: 'Datum rođenja',
                    readOnly: true,
                    onTap: _odaberiDatumRodjenja,
                    textInputAction: TextInputAction.next,
                    suffixIcon: const Icon(Icons.calendar_today_outlined),
                  ),
                  const SizedBox(height: 16),

                  _tekstPolje(
                    controller: postanskiBrojController,
                    label: 'Poštanski broj',
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  _tekstPolje(
                    controller: emailController,
                    label: 'E-mail',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  _tekstPolje(
                    controller: telefonController,
                    label: 'Telefon',
                    hintText: 'npr. 12345678',
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Broj telefona za kontakt',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _tekstPolje(
                    controller: lozinkaController,
                    label: 'Lozinka',
                    obscureText: obscurePassword,
                    textInputAction: TextInputAction.next,
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _tekstPolje(
                    controller: potvrdaLozinkeController,
                    label: 'Potvrdite lozinku',
                    obscureText: obscurePassword2,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => loading ? null : _register(),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          obscurePassword2 = !obscurePassword2;
                        });
                      },
                      icon: Icon(
                        obscurePassword2
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0x10FFFFFF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0x26FFFFFF),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: prihvatioGdpr,
                          onChanged: (value) {
                            setState(() {
                              prihvatioGdpr = value ?? false;
                            });
                          },
                          activeColor: AppColors.gold,
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Wrap(
                              children: [
                                const Text(
                                  'Prihvatam ',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _otvoriGdprStranicu,
                                  child: const Text(
                                    'Politiku privatnosti (GDPR)',
                                    style: TextStyle(
                                      color: AppColors.gold,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      decoration: TextDecoration.underline,
                                      decorationColor: AppColors.gold,
                                    ),
                                  ),
                                ),
                                const Text(
                                  '.',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (error.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      error,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],

                  if (success.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      success,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.lightGreenAccent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),
                  SizedBox(
                    height: 54,
                    child: FilledButton(
                      onPressed: loading ? null : _register,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: const Color(0xFF1B1408),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                              ),
                            )
                          : const Text(
                              'Registruj se',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      onPressed: loading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0x44FFFFFF)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: const Text(
                        'Nazad',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SimpleWebViewScreen extends StatefulWidget {
  final String title;
  final String url;

  const _SimpleWebViewScreen({
    required this.title,
    required this.url,
  });

  @override
  State<_SimpleWebViewScreen> createState() => _SimpleWebViewScreenState();
}

class _SimpleWebViewScreenState extends State<_SimpleWebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.background)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              _loading = true;
            });
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() {
              _loading = false;
            });
          },
          onWebResourceError: (_) {
            if (!mounted) return;
            setState(() {
              _loading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}