import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/constants.dart';
import 'api_helper.dart';
import 'push_service.dart';

class AuthService {
  static const FlutterSecureStorage storage = FlutterSecureStorage();

  static Future<bool> login(String email, String password) async {
    final res = await ApiHelper.postJson(
      loginEndpoint,
      body: {
        'email': email.trim(),
        'password': password,
      },
    );

    final token =
        res['data']?['token']?.toString() ??
        res['token']?.toString();

    if (token != null && token.isNotEmpty) {
      await saveToken(token);

      try {
        await PushService.registerCurrentDeviceToken(force: true);
      } catch (_) {
        // Login må gerne lykkes selv hvis push-registrering fejler
      }

      return true;
    }

    return false;
  }

  static Future<void> logout() async {
    try {
      await PushService.unregisterCurrentDeviceToken();
    } catch (_) {
      // Ignorer push-fejl ved logout
    }

    try {
      final token = await getToken();

      if (token != null && token.isNotEmpty) {
        await ApiHelper.postJson(
          logoutEndpoint,
          authRequired: true,
          body: const {},
        );
      }
    } catch (_) {
      // Ignorer server-fejl ved logout
    } finally {
      await clearToken();
    }
  }

  static Future<void> saveToken(String value) async {
    await storage.write(key: tokenStorageKey, value: value);
  }

  static Future<String?> getToken() async {
    return storage.read(key: tokenStorageKey);
  }

  static Future<void> clearToken() async {
    await storage.delete(key: tokenStorageKey);
  }

  static Future<bool> isLoggedIn() async {
    final value = await getToken();
    return value != null && value.isNotEmpty;
  }
}