import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

import 'firebase_options.dart';

const String baseUrl = 'https://bkicsaff.dk/wp-json/bkicsaff/v1';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

class PushService {
  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: DarwinInitializationSettings(),
    );

    await _local.initialize(initSettings);

    await _createAndroidChannel();
    await _requestPermissions();
    await _listenForegroundMessages();

    _initialized = true;
  }

  static Future<void> _createAndroidChannel() async {
    const channel = AndroidNotificationChannel(
      'bkic_default',
      'BKIC Notifications',
      description: 'Nyheder og događaji',
      importance: Importance.high,
    );

    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static Future<void> _requestPermissions() async {
    final messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  static Future<void> _listenForegroundMessages() async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final title = message.notification?.title ?? 'BKIC SAFF';
      final body = message.notification?.body ?? '';

      await _local.show(
        message.hashCode,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'bkic_default',
            'BKIC Notifications',
            channelDescription: 'Nyheder og događaji',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: jsonEncode(message.data),
      );
    });
  }

  static Future<String?> getFcmToken() async {
    return FirebaseMessaging.instance.getToken();
  }

  static Future<void> syncDeviceToken({
    required String appToken,
    String platform = 'android',
    String appVersion = '1.0.0',
    String locale = 'da',
  }) async {
    final fcmToken = await getFcmToken();
    if (fcmToken == null || fcmToken.isEmpty) return;

    await http.post(
      Uri.parse('$baseUrl/devices/register'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $appToken',
      },
      body: jsonEncode({
        'platform': platform,
        'device_token': fcmToken,
        'app_version': appVersion,
        'locale': locale,
      }),
    );

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      await http.post(
        Uri.parse('$baseUrl/devices/register'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $appToken',
        },
        body: jsonEncode({
          'platform': platform,
          'device_token': newToken,
          'app_version': appVersion,
          'locale': locale,
        }),
      );
    });
  }
}