import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

import 'auth_service.dart';

class PaymentService {
  static const String baseUrl = 'https://bkicsaff.dk/wp-json/bkicsaff/v1';

  static Future<bool> payMembership(int year) async {
    try {
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
          'year': year,
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

      final data = Map<String, dynamic>.from(rawData);
      final clientSecret = data['client_secret']?.toString() ?? '';

      if (clientSecret.isEmpty) {
        throw Exception('Client secret nedostaje.');
      }

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          merchantDisplayName: 'BKIC SAFF',
          paymentIntentClientSecret: clientSecret,
          style: ThemeMode.dark,
          allowsDelayedPaymentMethods: true,
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      debugPrint('PAYMENT SHEET COMPLETED');
      return true;
    } on StripeException catch (e) {
      final code = e.error.code.toString();
      final message = e.error.localizedMessage ?? '';

      debugPrint('STRIPE ERROR CODE: $code');
      debugPrint('STRIPE ERROR MESSAGE: $message');
      debugPrint('STRIPE ERROR: $e');

      if (code.toLowerCase().contains('canceled') ||
          message.toLowerCase().contains('cancel')) {
        return false;
      }

      return false;
    } catch (e) {
      debugPrint('PAYMENT ERROR: $e');
      return false;
    }
  }
}