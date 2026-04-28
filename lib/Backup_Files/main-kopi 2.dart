import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'firebase_options.dart';

const storage = FlutterSecureStorage();

const String baseUrl = 'https://bkicsaff.dk/wp-json/bkicsaff/v1';
const String loginEndpoint = '$baseUrl/auth/login';
const String logoutEndpoint = '$baseUrl/auth/logout';
const String meEndpoint = '$baseUrl/me';
const String registerDeviceEndpoint = '$baseUrl/devices/register';
const String unregisterDeviceEndpoint = '$baseUrl/devices/unregister';

const String tokenStorageKey = 'token';
const String fcmTokenStorageKey = 'fcm_device_token';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await PushService.init();

  runApp(const MyApp());
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class SessionExpiredException implements Exception {
  final String message;

  const SessionExpiredException([this.message = 'Session udløbet']);

  @override
  String toString() => message;
}

class ApiHelper {
  static Future<Map<String, String>> _headers({
    bool authRequired = false,
    Map<String, String>? extra,
  }) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      ...?extra,
    };

    if (authRequired) {
      final token = await storage.read(key: tokenStorageKey);
      if (token == null || token.isEmpty) {
        throw const SessionExpiredException('Ingen gyldig login-session');
      }
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  static Future<Map<String, dynamic>> getJson(
    String url, {
    bool authRequired = false,
    Map<String, String>? headers,
  }) async {
    final response = await http.get(
      Uri.parse(url),
      headers: await _headers(authRequired: authRequired, extra: headers),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> postJson(
    String url, {
    required Map<String, dynamic> body,
    bool authRequired = false,
    Map<String, String>? headers,
  }) async {
    final response = await http.post(
      Uri.parse(url),
      headers: await _headers(
        authRequired: authRequired,
        extra: {
          'Content-Type': 'application/json',
          ...?headers,
        },
      ),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    final raw = response.body.trim();

    Map<String, dynamic> decoded = {};
    if (raw.isNotEmpty) {
      try {
        final data = jsonDecode(raw);
        if (data is Map<String, dynamic>) {
          decoded = data;
        }
      } catch (_) {}
    }

    if (response.statusCode == 401) {
      throw SessionExpiredException(
        decoded['message']?.toString() ?? 'Ikke autoriseret',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        decoded['message']?.toString() ?? 'HTTP fejl: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }

    if (decoded.isEmpty) {
      throw const ApiException('Tom eller ugyldig serverrespons');
    }

    return decoded;
  }
}

class AuthService {
  static Future<void> saveToken(String token) async {
    await storage.write(key: tokenStorageKey, value: token);
  }

  static Future<String?> getToken() async {
    return storage.read(key: tokenStorageKey);
  }

  static Future<void> clearToken() async {
    await storage.delete(key: tokenStorageKey);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}

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
    await _listenForegroundMessages();
    await _cacheFcmToken();

    _messaging.onTokenRefresh.listen((token) async {
      await storage.write(key: fcmTokenStorageKey, value: token);
      await registerCurrentDeviceToken(force: true);
    });

    _initialized = true;
  }

  static Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidInit);

    await _localNotifications.initialize(settings);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  static Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  static Future<void> _listenForegroundMessages() async {
    FirebaseMessaging.onMessage.listen((message) async {
      await _showForegroundNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('Push opened app: ${message.data}');
    });

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('Opened from terminated state: ${initialMessage.data}');
    }
  }

  static Future<void> _showForegroundNotification(
    RemoteMessage message,
  ) async {
    final title =
        message.notification?.title ??
        message.data['title']?.toString() ??
        'BKIC SAFF';

    final body =
        message.notification?.body ?? message.data['body']?.toString() ?? '';

    const androidDetails = AndroidNotificationDetails(
      'bkic_default',
      'BKIC Notifications',
      channelDescription: 'BKIC SAFF notifikationer',
      importance: Importance.high,
      priority: Priority.high,
    );

    await _localNotifications.show(
      message.hashCode,
      title,
      body,
      const NotificationDetails(android: androidDetails),
      payload: jsonEncode(message.data),
    );
  }

  static Future<void> _cacheFcmToken() async {
    final token = await _messaging.getToken();
    if (token != null && token.isNotEmpty) {
      await storage.write(key: fcmTokenStorageKey, value: token);
    }
  }

  static Future<String?> getSavedDeviceToken() async {
    return storage.read(key: fcmTokenStorageKey);
  }

  static Future<String?> getCurrentDeviceToken() async {
    final token = await _messaging.getToken();
    if (token != null && token.isNotEmpty) {
      await storage.write(key: fcmTokenStorageKey, value: token);
      return token;
    }
    return getSavedDeviceToken();
  }

  static Future<void> registerCurrentDeviceToken({bool force = false}) async {
    final loggedIn = await AuthService.isLoggedIn();
    if (!loggedIn) return;

    final deviceToken = await getCurrentDeviceToken();
    if (deviceToken == null || deviceToken.isEmpty) return;

    final lastRegistered = await storage.read(
      key: 'last_registered_device_token',
    );

    if (!force && lastRegistered == deviceToken) {
      return;
    }

    await ApiHelper.postJson(
      registerDeviceEndpoint,
      authRequired: true,
      body: {
        'platform': 'android',
        'device_token': deviceToken,
        'app_version': '1.0.0',
        'locale': Platform.localeName,
      },
    );

    await storage.write(
      key: 'last_registered_device_token',
      value: deviceToken,
    );
  }

  static Future<void> unregisterCurrentDeviceToken() async {
    final loggedIn = await AuthService.isLoggedIn();
    final deviceToken = await getSavedDeviceToken();

    if (loggedIn && deviceToken != null && deviceToken.isNotEmpty) {
      try {
        await ApiHelper.postJson(
          unregisterDeviceEndpoint,
          authRequired: true,
          body: {
            'device_token': deviceToken,
          },
        );
      } catch (_) {}
    }

    await storage.delete(key: 'last_registered_device_token');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BKIC SAFF',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final loggedIn = await AuthService.isLoggedIn();

    if (loggedIn) {
      try {
        await PushService.registerCurrentDeviceToken();
      } catch (_) {}
    }

    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => loggedIn ? const HomeScreen() : const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'BKIC SAFF',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  String error = '';

  Future<void> login() async {
    setState(() {
      loading = true;
      error = '';
    });

    try {
      final response = await ApiHelper.postJson(
        loginEndpoint,
        body: {
          'email': emailController.text.trim(),
          'password': passwordController.text,
        },
      );

      if (response['success'] != true) {
        throw ApiException(response['message']?.toString() ?? 'Login fejl');
      }

      final token = response['data']?['token']?.toString();
      if (token == null || token.isEmpty) {
        throw const ApiException('Token mangler');
      }

      await AuthService.saveToken(token);
      await PushService.registerCurrentDeviceToken(force: true);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'E-mail'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Adgangskode'),
              onSubmitted: (_) => loading ? null : login(),
            ),
            const SizedBox(height: 16),
            if (error.isNotEmpty)
              Text(error, style: const TextStyle(color: Colors.redAccent)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: loading ? null : login,
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String name = '';
  String email = '';
  String login = '';
  String fcmToken = '';
  String error = '';
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = '';
    });

    try {
      final me = await ApiHelper.getJson(meEndpoint, authRequired: true);
      final token = await PushService.getCurrentDeviceToken() ?? '';

      if (me['success'] != true) {
        throw ApiException(me['message']?.toString() ?? 'Kunne ikke hente profil');
      }

      final user = me['data'] as Map<String, dynamic>? ?? {};

      setState(() {
        name = user['name']?.toString() ?? '';
        email = user['email']?.toString() ?? '';
        login = user['login']?.toString() ?? '';
        fcmToken = token;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> logout() async {
    try {
      await PushService.unregisterCurrentDeviceToken();
      await ApiHelper.postJson(
        logoutEndpoint,
        authRequired: true,
        body: const {},
      );
    } catch (_) {}

    await AuthService.clearToken();

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Future<void> refreshTokenRegistration() async {
    try {
      await PushService.registerCurrentDeviceToken(force: true);
      final token = await PushService.getCurrentDeviceToken() ?? '';
      setState(() {
        fcmToken = token;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Device token registreret')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Fejl: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('BKIC SAFF'),
        actions: [
          IconButton(
            onPressed: refreshTokenRegistration,
            icon: const Icon(Icons.notifications_active),
          ),
          IconButton(
            onPressed: logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: error.isNotEmpty
            ? Text(error)
            : ListView(
                children: [
                  ListTile(
                    title: const Text('Navn'),
                    subtitle: Text(name),
                  ),
                  ListTile(
                    title: const Text('E-mail'),
                    subtitle: Text(email),
                  ),
                  ListTile(
                    title: const Text('Brugernavn'),
                    subtitle: Text(login),
                  ),
                  ListTile(
                    title: const Text('FCM token'),
                    subtitle: SelectableText(
                      fcmToken.isEmpty ? 'Ikke hentet endnu' : fcmToken,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}