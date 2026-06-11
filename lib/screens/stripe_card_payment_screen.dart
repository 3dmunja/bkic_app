import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

import '../services/auth_service.dart';
import '../widgets/premium_card.dart';

class StripeCardPaymentScreen extends StatefulWidget {
  final int year;

  const StripeCardPaymentScreen({
    super.key,
    required this.year,
  });

  @override
  State<StripeCardPaymentScreen> createState() =>
      _StripeCardPaymentScreenState();
}

class _StripeCardPaymentScreenState extends State<StripeCardPaymentScreen> {
  static const String baseUrl = 'https://bkicsaff.dk/wp-json/bkicsaff/v1';

  bool loading = false;
  bool cardComplete = false;
  String error = '';

  Future<Map<String, dynamic>> _createPaymentIntent({
    required String paymentMethod,
  }) async {
    final token = await AuthService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Korisnik nije prijavljen.');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/payments/create'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'year': widget.year,
        'payment_method': paymentMethod,
      }),
    );

    debugPrint('PAYMENT STATUS: ${response.statusCode}');
    debugPrint('PAYMENT BODY: ${response.body}');

    final decodedRaw = jsonDecode(response.body);

    if (decodedRaw is! Map) {
      throw Exception('Server nije vratio ispravan odgovor.');
    }

    final decoded = Map<String, dynamic>.from(decodedRaw);

    if (response.statusCode != 200 || decoded['success'] != true) {
      throw Exception(
        decoded['message']?.toString() ?? 'Plaćanje nije pokrenuto.',
      );
    }

    final rawData = decoded['data'];

    if (rawData is! Map) {
      throw Exception('Nedostaju podaci za plaćanje.');
    }

    return Map<String, dynamic>.from(rawData);
  }

  Future<void> _confirmPaymentOnServer(String paymentIntentId) async {
    final token = await AuthService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Korisnik nije prijavljen.');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/payments/confirm'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'payment_intent_id': paymentIntentId,
      }),
    );

    debugPrint('CONFIRM STATUS: ${response.statusCode}');
    debugPrint('CONFIRM BODY: ${response.body}');

    final decodedRaw = jsonDecode(response.body);

    if (decodedRaw is! Map) {
      throw Exception('Server nije vratio ispravan confirm odgovor.');
    }

    final decoded = Map<String, dynamic>.from(decodedRaw);

    if (response.statusCode != 200 || decoded['success'] != true) {
      throw Exception(
        decoded['message']?.toString() ??
            'Plaćanje je izvršeno, ali članarina nije ažurirana.',
      );
    }
  }

  Future<void> _payCard() async {
    if (loading) return;

    if (!cardComplete) {
      setState(() {
        error = 'Unesite ispravne podatke kartice.';
      });
      return;
    }

    setState(() {
      loading = true;
      error = '';
    });

    try {
      final data = await _createPaymentIntent(paymentMethod: 'card');
      final clientSecret = data['client_secret']?.toString() ?? '';
      final paymentIntentId = data['payment_intent_id']?.toString() ?? '';

      if (clientSecret.isEmpty) {
        throw Exception('Client secret nedostaje.');
      }

      if (paymentIntentId.isEmpty) {
        throw Exception('PaymentIntent ID nedostaje.');
      }

      await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: clientSecret,
        data: const PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(),
        ),
      );

      await _confirmPaymentOnServer(paymentIntentId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Plaćanje za ${widget.year} je završeno ✅'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context, true);
    } on StripeException catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.error.localizedMessage ?? 'Plaćanje nije završeno.';
        loading = false;
      });

      debugPrint('STRIPE ERROR CODE: ${e.error.code}');
      debugPrint('STRIPE ERROR MESSAGE: ${e.error.localizedMessage}');
      debugPrint('STRIPE ERROR: $e');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
        loading = false;
      });

      debugPrint('PAYMENT ERROR: $e');
    }
  }

  Future<void> _payMobilePay() async {
    if (loading) return;

    setState(() {
      loading = true;
      error = '';
    });

    try {
      final data = await _createPaymentIntent(paymentMethod: 'mobilepay');
      final clientSecret = data['client_secret']?.toString() ?? '';
      final paymentIntentId = data['payment_intent_id']?.toString() ?? '';

      if (clientSecret.isEmpty) {
        throw Exception('Client secret nedostaje.');
      }

      if (paymentIntentId.isEmpty) {
        throw Exception('PaymentIntent ID nedostaje.');
      }

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'BKIC SAFF',
          style: ThemeMode.light,
          returnURL: 'bkicsaff://stripe-redirect',
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      await _confirmPaymentOnServer(paymentIntentId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Plaćanje za ${widget.year} je završeno ✅'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context, true);
    } on StripeException catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.error.localizedMessage ?? 'Plaćanje nije završeno.';
        loading = false;
      });

      debugPrint('STRIPE ERROR CODE: ${e.error.code}');
      debugPrint('STRIPE ERROR MESSAGE: ${e.error.localizedMessage}');
      debugPrint('STRIPE ERROR: $e');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
        loading = false;
      });

      debugPrint('PAYMENT ERROR: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8F5),
        foregroundColor: const Color(0xFF17211D),
        elevation: 0,
        title: Text(
          'Plaćanje članarine ${widget.year}',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            PremiumCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Plaćanje',
                    style: TextStyle(
                      color: Color(0xFF17211D),
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Platite članarinu za ${widget.year} karticom ili putem MobilePaya.',
                    style: const TextStyle(
                      color: Color(0xFF6D756F),
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 18),

                  CardFormField(
                    autofocus: true,
                    enablePostalCode: false,
                    style: CardFormStyle(
                      backgroundColor: Colors.white,
                      textColor: const Color(0xFF17211D),
                      placeholderColor: const Color(0xFF8A928C),
                      borderColor: const Color(0xFFE1E5DF),
                      borderWidth: 1,
                      borderRadius: 16,
                      cursorColor: const Color(0xFF0F4F3A),
                      fontSize: 18,
                    ),
                    onCardChanged: (details) {
                      setState(() {
                        cardComplete = details?.complete ?? false;
                      });
                    },
                  ),

                  if (error.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
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
                        style: const TextStyle(
                          color: Color(0xFFB3261E),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 22),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      onPressed: loading ? null : _payCard,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0F4F3A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
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
                          : Text(
                              'Plati karticom ${widget.year}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton(
                      onPressed: loading ? null : _payMobilePay,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0F4F3A),
                        side: const BorderSide(color: Color(0xFFE1E5DF)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Plati putem MobilePaya',
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
          ],
        ),
      ),
    );
  }
}