import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../core/constants.dart';
import 'api_helper.dart';
import 'auth_service.dart';

class PushService {
  PushService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'bkic_default',
    'BKIC Notifications',
    description: 'BKIC SAFF notifikationer',
    importance: Importance.high,
  );

  static Future<void> init() async {
    if (_initialized) return;

    await _initLocalNotifications();
    await _requestPermissions();
    await _configureForegroundListeners();
    await _syncTokenIfPossible();

    _messaging.onTokenRefresh.listen((token) async {
      debugPrint('FCM token refreshed: $token');
      await AuthService.storage.write(key: fcmTokenStorageKey, value: token);
      await registerCurrentDeviceToken(force: true);
    });

    _initialized = true;
  }

  static Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('Local notification clicked: ${response.payload}');
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  static Future<void> _requestPermissions() async {
    if (!Platform.isAndroid && !Platform.isIOS && !Platform.isMacOS) return;

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );

    debugPrint('Push permission status: ${settings.authorizationStatus}');

    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  static Future<void> _configureForegroundListeners() async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint('Foreground push data: ${message.data}');
      await _showForegroundNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Push opened app: ${message.data}');
    });

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('Opened from terminated state: ${initialMessage.data}');
    }
  }

  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    final title = message.notification?.title ??
        message.data['title']?.toString() ??
        'BKIC SAFF';

    final body = message.notification?.body ??
        message.data['body']?.toString() ??
        '';

    const androidDetails = AndroidNotificationDetails(
      'bkic_default',
      'BKIC Notifications',
      channelDescription: 'BKIC SAFF notifikationer',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    await _localNotifications.show(
      message.hashCode,
      title,
      body,
      const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
        macOS: iosDetails,
      ),
      payload: jsonEncode(message.data),
    );
  }

  static Future<bool> _isApnsReadyIfNeeded() async {
    if (!Platform.isIOS && !Platform.isMacOS) return true;

    try {
      final apnsToken = await _messaging.getAPNSToken();

      if (apnsToken == null || apnsToken.isEmpty) {
        debugPrint('APNS token not ready yet.');
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('APNS token check failed: $e');
      return false;
    }
  }

  static Future<void> _syncTokenIfPossible() async {
    try {
      final apnsReady = await _isApnsReadyIfNeeded();
      if (!apnsReady) return;

      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) return;

      debugPrint('Initial FCM token: $token');
      await AuthService.storage.write(key: fcmTokenStorageKey, value: token);
    } catch (e) {
      debugPrint('FCM token sync skipped: $e');
    }
  }

  static Future<String?> getSavedDeviceToken() async {
    return AuthService.storage.read(key: fcmTokenStorageKey);
  }

  static Future<String?> getCurrentDeviceToken() async {
    try {
      final apnsReady = await _isApnsReadyIfNeeded();
      if (!apnsReady) return getSavedDeviceToken();

      final token = await _messaging.getToken();

      if (token != null && token.isNotEmpty) {
        await AuthService.storage.write(key: fcmTokenStorageKey, value: token);
        debugPrint('Current FCM token: $token');
        return token;
      }
    } catch (e) {
      debugPrint('FCM token fetch skipped: $e');
    }

    return getSavedDeviceToken();
  }

  static String _platformName() {
    if (Platform.isIOS) return 'ios';
    if (Platform.isMacOS) return 'macos';
    return 'android';
  }

  static Future<void> registerCurrentDeviceToken({bool force = false}) async {
    final loggedIn = await AuthService.isLoggedIn();
    if (!loggedIn) return;

    final deviceToken = await getCurrentDeviceToken();
    if (deviceToken == null || deviceToken.isEmpty) return;

    final lastRegistered =
        await AuthService.storage.read(key: lastRegisteredDeviceTokenKey);

    if (!force && lastRegistered == deviceToken) {
      debugPrint('Device token already registered.');
      return;
    }

    final response = await ApiHelper.postJson(
      registerDeviceEndpoint,
      authRequired: true,
      body: {
        'platform': _platformName(),
        'device_token': deviceToken,
        'app_version': '1.0.0',
        'locale': Platform.localeName,
      },
    );

    debugPrint('Register device response: $response');

    await AuthService.storage.write(
      key: lastRegisteredDeviceTokenKey,
      value: deviceToken,
    );
  }

  static Future<void> unregisterCurrentDeviceToken() async {
    final deviceToken = await getSavedDeviceToken();
    final loggedIn = await AuthService.isLoggedIn();

    if (loggedIn && deviceToken != null && deviceToken.isNotEmpty) {
      try {
        await ApiHelper.postJson(
          unregisterDeviceEndpoint,
          authRequired: true,
          body: {
            'device_token': deviceToken,
          },
        );
      } catch (e) {
        debugPrint('Unregister token fejl: $e');
      }
    }

    await AuthService.storage.delete(key: lastRegisteredDeviceTokenKey);
  }
}