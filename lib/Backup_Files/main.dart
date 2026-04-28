import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'firebase_options.dart';

const storage = FlutterSecureStorage();
const String baseUrl = 'https://bkicsaff.dk/wp-json/bkicsaff/v1';

const String loginEndpoint = '$baseUrl/auth/login';
const String logoutEndpoint = '$baseUrl/auth/logout';
const String meEndpoint = '$baseUrl/me';
const String pageEndpoint = '$baseUrl/pages';
const String contactEndpoint = '$baseUrl/contact';
const String membershipEndpoint = '$baseUrl/me/membership';
const String homeNewsEndpoint = '$baseUrl/home/news';
const String homeEventsEndpoint = '$baseUrl/home/events';
const String registerDeviceEndpoint = '$baseUrl/devices/register';
const String unregisterDeviceEndpoint = '$baseUrl/devices/unregister';

const String tokenStorageKey = 'token';
const String fcmTokenStorageKey = 'fcm_device_token';
const String lastRegisteredDeviceTokenKey = 'last_registered_device_token';

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

class SessionExpiredException implements Exception {
  final String message;
  const SessionExpiredException([this.message = 'Session udløbet']);

  @override
  String toString() => message;
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiHelper {
  static Future<Map<String, String>> _buildHeaders({
    bool authRequired = false,
    Map<String, String>? headers,
  }) async {
    final map = <String, String>{
      'Accept': 'application/json',
      ...?headers,
    };

    if (authRequired) {
      final token = await storage.read(key: tokenStorageKey);
      if (token == null || token.isEmpty) {
        throw const SessionExpiredException('Ingen gyldig login-session');
      }
      map['Authorization'] = 'Bearer $token';
    }

    return map;
  }

  static Future<Map<String, dynamic>> getJson(
    String url, {
    bool authRequired = false,
    Map<String, String>? headers,
  }) async {
    final response = await http.get(
      Uri.parse(url),
      headers: await _buildHeaders(
        authRequired: authRequired,
        headers: headers,
      ),
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
      headers: await _buildHeaders(
        authRequired: authRequired,
        headers: {
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

    Map<String, dynamic> decoded = <String, dynamic>{};
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
    await _configureForegroundListeners();
    await _syncTokenIfPossible();

    _messaging.onTokenRefresh.listen((token) async {
      debugPrint('FCM token refreshed: $token');
      await storage.write(key: fcmTokenStorageKey, value: token);
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
    if (!Platform.isAndroid && !Platform.isIOS && !Platform.isMacOS) {
      return;
    }

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

    if (Platform.isIOS || Platform.isMacOS) {
      await _messaging.getAPNSToken();
    }

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
    final title =
        message.notification?.title ??
        message.data['title']?.toString() ??
        'BKIC SAFF';

    final body =
        message.notification?.body ??
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

  static Future<void> _syncTokenIfPossible() async {
    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) return;

    debugPrint('Initial FCM token: $token');
    await storage.write(key: fcmTokenStorageKey, value: token);
  }

  static Future<String?> getSavedDeviceToken() async {
    return storage.read(key: fcmTokenStorageKey);
  }

  static Future<String?> getCurrentDeviceToken() async {
    final token = await _messaging.getToken();
    if (token != null && token.isNotEmpty) {
      await storage.write(key: fcmTokenStorageKey, value: token);
      debugPrint('Current FCM token: $token');
      return token;
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

    final lastRegistered = await storage.read(key: lastRegisteredDeviceTokenKey);

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

    await storage.write(
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

    await storage.delete(key: lastRegisteredDeviceTokenKey);
  }
}

class SessionScope extends InheritedNotifier<ValueNotifier<int>> {
  const SessionScope({
    super.key,
    required ValueNotifier<int> notifier,
    required Widget child,
  }) : super(notifier: notifier, child: child);

  static ValueNotifier<int> of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SessionScope>();
    assert(scope != null, 'SessionScope mangler i widget tree');
    return scope!.notifier!;
  }
}

class AppColors {
  static const background = Color(0xFF070604);
  static const panel = Color(0x14FFFFFF);
  static const panelSoft = Color(0x0DFFFFFF);
  static const text = Color(0xFFF6F2EB);
  static const muted = Color(0xFFD7D0C4);
  static const gold = Color(0xFFCAA25A);
  static const gold2 = Color(0xFF9A7B3F);
  static const blueText = Color(0xFFDFE7FF);
  static const blueText2 = Color(0xFFEEF3FF);
  static const line = Color(0x1FFFFFFF);
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ValueNotifier<int> _sessionNotifier = ValueNotifier<int>(0);

  @override
  void dispose() {
    _sessionNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SessionScope(
      notifier: _sessionNotifier,
      child: MaterialApp(
        title: 'BKIC SAFF',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: AppColors.background,
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.gold,
            brightness: Brightness.dark,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF0F1520),
            foregroundColor: Colors.white,
            centerTitle: false,
            elevation: 0,
          ),
          cardTheme: CardThemeData(
            color: AppColors.panel,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: const BorderSide(color: AppColors.line),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0x14FFFFFF),
            labelStyle: const TextStyle(color: Colors.white70),
            hintStyle: const TextStyle(color: Colors.white54),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Color(0x24FFFFFF)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Color(0x30FFFFFF)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: AppColors.gold),
            ),
          ),
        ),
        home: const SplashScreen(),
      ),
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
    checkLogin();
  }

  Future<void> checkLogin() async {
    final loggedIn = await AuthService.isLoggedIn();

    if (loggedIn) {
      try {
        await PushService.registerCurrentDeviceToken();
      } catch (e) {
        debugPrint('Register token on splash fejl: $e');
      }
    }

    await Future.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            loggedIn ? const MainNavigationScreen() : const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF070604),
              Color(0xFF111722),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.shield_outlined,
                size: 70,
                color: AppColors.gold,
              ),
              SizedBox(height: 18),
              Text(
                'BKIC SAFF',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
    this.radius = 22,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 28,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: child,
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
    FocusScope.of(context).unfocus();

    setState(() {
      loading = true;
      error = '';
    });

    try {
      final data = await ApiHelper.postJson(
        loginEndpoint,
        body: {
          'email': emailController.text.trim(),
          'password': passwordController.text,
        },
      );

      if (data['success'] != true) {
        throw ApiException(data['message']?.toString() ?? 'Login fejl');
      }

      final token = data['data']?['token']?.toString();
      if (token == null || token.isEmpty) {
        throw const ApiException('Token mangler i login-respons');
      }

      await AuthService.saveToken(token);
      await PushService.registerCurrentDeviceToken(force: true);

      if (!mounted) return;
      SessionScope.of(context).value++;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => error = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => error = 'Netværksfejl: $e');
    } finally {
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  void openMembership() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MembershipSignupPlaceholder()),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Widget buildGlassCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0x22FFFFFF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 28,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(
              'https://3dmunja.dk/wp-content/uploads/2026/01/Coffe_1.jpeg',
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0x73000000),
                Color(0xB3000000),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: buildGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.lock_outline,
                        size: 74,
                        color: AppColors.gold,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'BKIC SAFF Login',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 29,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Prijavi se na svoj račun',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(labelText: 'E-mail'),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => loading ? null : login(),
                        decoration: const InputDecoration(
                          labelText: 'Adgangskode',
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (error.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            error,
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      SizedBox(
                        height: 52,
                        child: FilledButton(
                          onPressed: loading ? null : login,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFF0D07A),
                            foregroundColor: const Color(0xFF0B0F14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.3,
                                  ),
                                )
                              : const Text(
                                  'Login',
                                  style: TextStyle(fontWeight: FontWeight.w900),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: openMembership,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Color(0x44FFFFFF)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: const Text(
                            'Bliv medlem',
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
        ),
      ),
    );
  }
}

class MembershipSignupPlaceholder extends StatelessWidget {
  const MembershipSignupPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bliv medlem')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: GlassPanel(
              radius: 22,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.workspace_premium_outlined,
                    size: 64,
                    color: AppColors.gold,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Medlemsoprettelse i appen kommer som næste trin',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.blueText2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Vi har nu gjort plads til medlems-flowet. Næste skridt er at koble registrering og betaling direkte til din WordPress-løsning.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: const Color(0xFF1B1408),
                    ),
                    child: const Text('Tilbage'),
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

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int currentIndex = 0;

  final List<Widget> pages = const [
    HomeTab(),
    MenuTab(),
    ContactTab(),
    ProfileTab(),
  ];

  final List<String> titles = const [
    'Forside',
    'Menu',
    'Kontakt',
    'Profil',
  ];

  Future<void> logout() async {
    try {
      await PushService.unregisterCurrentDeviceToken();
      await ApiHelper.postJson(
        logoutEndpoint,
        authRequired: true,
        body: const {},
      );
    } catch (_) {
    } finally {
      await AuthService.clearToken();
      SessionScope.of(context).value++;

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[currentIndex]),
        actions: [
          IconButton(
            onPressed: logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: pages[currentIndex],
      bottomNavigationBar: NavigationBar(
        height: 74,
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Hjem',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_outlined),
            selectedIcon: Icon(Icons.menu),
            label: 'Menu',
          ),
          NavigationDestination(
            icon: Icon(Icons.contact_mail_outlined),
            selectedIcon: Icon(Icons.contact_mail),
            label: 'Kontakt',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  bool loading = true;
  String error = '';
  bool isLoggedIn = false;
  List<dynamic> news = [];
  List<dynamic> events = [];

  @override
  void initState() {
    super.initState();
    loadHome();
  }

  Future<void> loadHome() async {
    setState(() {
      loading = true;
      error = '';
    });

    try {
      final loggedIn = await AuthService.isLoggedIn();

      List<dynamic> fetchedNews = [];
      List<dynamic> fetchedEvents = [];

      if (loggedIn) {
        final results = await Future.wait([
          ApiHelper.getJson(homeNewsEndpoint, authRequired: true),
          ApiHelper.getJson(homeEventsEndpoint, authRequired: true),
        ]);

        final newsData = results[0];
        final eventsData = results[1];

        if (newsData['success'] == true && newsData['data'] is List) {
          fetchedNews = List<dynamic>.from(newsData['data']);
        }

        if (eventsData['success'] == true && eventsData['data'] is List) {
          fetchedEvents = List<dynamic>.from(eventsData['data']);
        }
      }

      if (!mounted) return;
      setState(() {
        isLoggedIn = loggedIn;
        news = fetchedNews;
        events = fetchedEvents;
        loading = false;
      });
    } on SessionExpiredException catch (e) {
      await _handleSessionExpired(e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = 'Kunne ikke hente forsiden: $e';
        loading = false;
      });
    }
  }

  Future<void> _handleSessionExpired(String message) async {
    await AuthService.clearToken();
    await PushService.unregisterCurrentDeviceToken();

    if (!mounted) return;
    SessionScope.of(context).value++;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error.isNotEmpty) {
      return Center(child: Text(error));
    }

    return RefreshIndicator(
      onRefresh: loadHome,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          HomeHeroSection(
            isLoggedIn: isLoggedIn,
            news: news,
            events: events,
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}

class HomeHeroSection extends StatelessWidget {
  final bool isLoggedIn;
  final List<dynamic> news;
  final List<dynamic> events;

  const HomeHeroSection({
    super.key,
    required this.isLoggedIn,
    required this.news,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool mobile = width < 760;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        image: const DecorationImage(
          image: NetworkImage(
            'https://3dmunja.dk/wp-content/uploads/2026/01/Coffe_1.jpeg',
          ),
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: [
              Color(0x22000000),
              Color(0x99000000),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border.all(color: const Color(0x1AFFFFFF)),
        ),
        child: Padding(
          padding: EdgeInsets.all(mobile ? 14 : 18),
          child: mobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isLoggedIn) ...[
                      const HomeTickerCard(),
                      const SizedBox(height: 12),
                      NewsSection(news: news),
                      const SizedBox(height: 12),
                      EventsSection(events: events),
                    ] else ...[
                      _HeroRightCard(isLoggedIn: isLoggedIn),
                    ],
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          const HomeTickerCard(),
                          if (isLoggedIn) ...[
                            const SizedBox(height: 12),
                            NewsSection(news: news),
                            const SizedBox(height: 12),
                            EventsSection(events: events),
                          ],
                        ],
                      ),
                    ),
                    if (!isLoggedIn) ...[
                      const SizedBox(width: 18),
                      Expanded(
                        child: _HeroRightCard(isLoggedIn: isLoggedIn),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

class _HeroRightCard extends StatelessWidget {
  final bool isLoggedIn;

  const _HeroRightCard({required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0x33F0D07A)),
        gradient: const LinearGradient(
          colors: [
            Color(0x1AF0D07A),
            Color(0x127FC8FF),
            Color(0x14FFFFFF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x44000000),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0x22000000),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0x24FFFFFF)),
            ),
            child: const Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10,
              children: [
                Text(
                  'BKIC SAFF',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  'Odense • Naš džemat',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Zajedništvo.\nSnaga naroda.',
            style: TextStyle(
              fontSize: 38,
              height: 1.02,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: 170,
            height: 7,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFF0D07A),
                  Color(0xFF7FC8FF),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Samo ujedinjeni možemo očuvati našu tradiciju i pružiti ruku podrške svakom članu naše zajednice.',
            style: TextStyle(
              color: Colors.white70,
              height: 1.5,
              fontSize: 15.5,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MembershipSignupPlaceholder(),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFF0D07A),
                  foregroundColor: const Color(0xFF0B0F14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                ),
                child: const Text(
                  'Budi član',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              OutlinedButton(
                onPressed: () {
                  final nav = Navigator.of(context);
                  nav.push(
                    MaterialPageRoute(
                      builder: (_) => isLoggedIn
                          ? const ProfileTabStandaloneScreen()
                          : const LoginScreen(),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0x24FFFFFF)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                ),
                child: Text(isLoggedIn ? 'Moj račun' : 'Prijavi se'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ProfileTabStandaloneScreen extends StatelessWidget {
  const ProfileTabStandaloneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: const ProfileTab(),
    );
  }
}

class HomeTickerCard extends StatefulWidget {
  const HomeTickerCard({super.key});

  @override
  State<HomeTickerCard> createState() => _HomeTickerCardState();
}

class _HomeTickerCardState extends State<HomeTickerCard> {
  final ScrollController _scrollController = ScrollController();
  Timer? _timer;

  final List<String> messages = const [
    'Vjera i istina — vjeruj i govori istinu',
    'Zajedništvo — zajedno smo jači',
    'Dijeljenje uspjeha — uspjeh vrijedi kada se dijeli',
    'Dobrodošli u BKIC SAFF, Odense',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoScroll();
    });
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(milliseconds: 35), (_) {
      if (!_scrollController.hasClients) return;

      final max = _scrollController.position.maxScrollExtent;
      if (max <= 0) return;

      final next = _scrollController.offset + 1.1;

      if (next >= max) {
        _scrollController.jumpTo(0);
      } else {
        _scrollController.jumpTo(next);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = [...messages, ...messages];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0x1AFFFFFF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Color(0xFFF0D07A),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: Row(
                children: items.map((text) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 24),
                    child: Row(
                      children: [
                        Text(
                          text,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Text(
                          '•',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HomeSectionContainer extends StatelessWidget {
  final String title;
  final Widget child;

  const HomeSectionContainer({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x33F0D07A)),
        gradient: const LinearGradient(
          colors: [
            Color(0x1AF0D07A),
            Color(0x14FFFFFF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x44000000),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFFF0D07A),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class NewsSection extends StatefulWidget {
  final List<dynamic> news;

  const NewsSection({
    super.key,
    required this.news,
  });

  @override
  State<NewsSection> createState() => _NewsSectionState();
}

class _NewsSectionState extends State<NewsSection> {
  final ScrollController _scrollController = ScrollController();

  String _pickTitle(dynamic item) {
    if (item is Map) {
      return item['titel']?.toString() ?? item['title']?.toString() ?? '';
    }
    return '';
  }

  String _pickText(dynamic item) {
    if (item is Map) {
      return item['tekst']?.toString() ??
          item['text']?.toString() ??
          item['content']?.toString() ??
          '';
    }
    return '';
  }

  String _pickStart(dynamic item) {
    if (item is Map) {
      return item['start']?.toString() ?? item['pocetak']?.toString() ?? '';
    }
    return '';
  }

  String _pickEnd(dynamic item) {
    if (item is Map) {
      return item['slut']?.toString() ?? item['end']?.toString() ?? '';
    }
    return '';
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HomeSectionContainer(
      title: 'Vijesti',
      child: widget.news.isEmpty
          ? const Text(
              'Trenutno nema vijesti.',
              style: TextStyle(color: Colors.white70),
            )
          : ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                child: ListView.separated(
                  controller: _scrollController,
                  shrinkWrap: true,
                  itemCount: widget.news.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = widget.news[index];
                    final title = _pickTitle(item);
                    final text = _pickText(item);
                    final start = _pickStart(item);
                    final end = _pickEnd(item);

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0x22000000),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0x1FFFFFFF)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (start.isNotEmpty || end.isNotEmpty)
                            Text(
                              '${start.isNotEmpty ? "Od: $start" : ""}${start.isNotEmpty && end.isNotEmpty ? "\n" : ""}${end.isNotEmpty ? "Do: $end" : ""}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12.5,
                                height: 1.35,
                              ),
                            ),
                          if (text.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              text,
                              style: const TextStyle(
                                color: Colors.white70,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
    );
  }
}

class EventsSection extends StatefulWidget {
  final List<dynamic> events;

  const EventsSection({
    super.key,
    required this.events,
  });

  @override
  State<EventsSection> createState() => _EventsSectionState();
}

class _EventsSectionState extends State<EventsSection> {
  late final PageController _pageController;
  Timer? _timer;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1);
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant EventsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.events.length != widget.events.length) {
      _timer?.cancel();
      currentIndex = 0;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
      _startTimer();
    }
  }

  void _startTimer() {
    if (widget.events.length <= 1) return;

    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_pageController.hasClients || widget.events.isEmpty) return;

      final next = (currentIndex + 1) % widget.events.length;

      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  String _pick(dynamic item, String key) {
    if (item is Map) {
      return item[key]?.toString() ?? '';
    }
    return '';
  }

  bool _pickBool(dynamic item, String key) {
    if (item is Map) {
      final value = item[key];
      if (value is bool) return value;
      if (value is String) return value.toLowerCase() == 'true';
      if (value is num) return value != 0;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.of(context).size.width < 640;

    return HomeSectionContainer(
      title: 'Događaji',
      child: widget.events.isEmpty
          ? const Text(
              'Trenutno nema događaja.',
              style: TextStyle(color: Colors.white70),
            )
          : Column(
              children: [
                SizedBox(
                  height: mobile ? 520 : 320,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: widget.events.length,
                    onPageChanged: (index) {
                      setState(() {
                        currentIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final e = widget.events[index];
                      final title = _pick(e, 'title');
                      final description = _pick(e, 'description');
                      final date = _pick(e, 'date');
                      final time = _pick(e, 'time');
                      final location = _pick(e, 'location');
                      final imageUrl = _pick(e, 'imageUrl');
                      final detailsUrl = _pick(e, 'detailsUrl');
                      final statusLabel = _pick(e, 'availabilityLabel').isNotEmpty
                          ? _pick(e, 'availabilityLabel')
                          : (_pick(e, 'statusLabel').isNotEmpty
                              ? _pick(e, 'statusLabel')
                              : _pick(e, 'status'));
                      final registered = _pickBool(e, 'registered');
                      final canRegister = _pickBool(e, 'canRegister');

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0x22000000),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0x1FFFFFFF)),
                        ),
                        child: mobile
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _eventImage(imageUrl, 160),
                                  const SizedBox(height: 10),
                                  Expanded(
                                    child: _eventBody(
                                      context: context,
                                      title: title,
                                      description: description,
                                      date: date,
                                      time: time,
                                      location: location,
                                      status: statusLabel,
                                      registered: registered,
                                      canRegister: canRegister,
                                      detailsUrl: detailsUrl,
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  SizedBox(
                                    width: 140,
                                    child: _eventImage(imageUrl, 220),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _eventBody(
                                      context: context,
                                      title: title,
                                      description: description,
                                      date: date,
                                      time: time,
                                      location: location,
                                      status: statusLabel,
                                      registered: registered,
                                      canRegister: canRegister,
                                      detailsUrl: detailsUrl,
                                    ),
                                  ),
                                ],
                              ),
                      );
                    },
                  ),
                ),
                if (widget.events.length > 1) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(widget.events.length, (index) {
                      final active = index == currentIndex;
                      return GestureDetector(
                        onTap: () {
                          _pageController.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: active ? 22 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: active
                                ? const Color(0xFFF0D07A)
                                : const Color(0x40FFFFFF),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _eventImage(String imageUrl, double height) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: imageUrl.isNotEmpty
          ? Image.network(
              imageUrl,
              height: height,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return Container(
                  height: height,
                  color: const Color(0x14FFFFFF),
                  child: const Center(child: Icon(Icons.image_not_supported)),
                );
              },
            )
          : Container(
              height: height,
              color: const Color(0x14FFFFFF),
              child: const Center(child: Icon(Icons.event)),
            ),
    );
  }

  Widget _eventBody({
    required BuildContext context,
    required String title,
    required String description,
    required String date,
    required String time,
    required String location,
    required String status,
    required bool registered,
    required bool canRegister,
    required String detailsUrl,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              runSpacing: 8,
              spacing: 8,
              alignment: WrapAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 220,
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    ),
                  ),
                ),
                if (status.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0x1AFFFFFF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      status,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
              ],
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(
                  color: Colors.white70,
                  height: 1.45,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 10),
            if (date.isNotEmpty)
              Text(
                'Datum: $date',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12.5,
                ),
              ),
            if (time.isNotEmpty)
              Text(
                'Vrijeme: $time',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12.5,
                ),
              ),
            if (location.isNotEmpty)
              Text(
                'Mjesto: $location',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12.5,
                ),
              ),
            const SizedBox(height: 8),
            if (registered)
              const Text(
                'Već ste prijavljeni na događaj.',
                style: TextStyle(
                  color: Color(0xFFF0D07A),
                  fontWeight: FontWeight.w700,
                ),
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: detailsUrl.isEmpty
                      ? null
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Detalji tilkobles næste trin.'),
                            ),
                          );
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFF0D07A),
                    foregroundColor: const Color(0xFF0B0F14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: const Text(
                    'Detalji',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                OutlinedButton(
                  onPressed: canRegister && !registered
                      ? () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Event-prijava kobles næste trin.'),
                            ),
                          );
                        }
                      : null,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: Text(registered ? 'Prijavljen' : 'Prijava'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AboutTab extends StatefulWidget {
  const AboutTab({super.key});

  @override
  State<AboutTab> createState() => _AboutTabState();
}

class _AboutTabState extends State<AboutTab> {
  String content = '';
  bool loading = true;
  String error = '';

  @override
  void initState() {
    super.initState();
    fetchPage();
  }

  Future<void> fetchPage() async {
    try {
      final data = await ApiHelper.getJson('$pageEndpoint/om');

      if (!mounted) return;

      if (data['success'] == true) {
        setState(() {
          content = data['data']?['content']?.toString() ?? '';
          loading = false;
        });
      } else {
        setState(() {
          error = data['message']?.toString() ?? 'Kunne ikke hente siden';
          loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = 'Netværksfejl: $e';
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error.isNotEmpty) {
      return Center(child: Text(error));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Html(data: content),
        ),
      ),
    );
  }
}

class MenuTab extends StatelessWidget {
  const MenuTab({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      {'title': 'Om os', 'icon': Icons.info_outline},
      {'title': 'Medlemskab', 'icon': Icons.workspace_premium_outlined},
      {'title': 'Nyheder', 'icon': Icons.article_outlined},
      {'title': 'Begivenheder', 'icon': Icons.event_outlined},
      {'title': 'Kontakt', 'icon': Icons.contact_mail_outlined},
      {'title': 'Min profil', 'icon': Icons.person_outline},
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Menu',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        ...items.map(
          (item) => Card(
            child: ListTile(
              leading: Icon(item['icon'] as IconData),
              title: Text(item['title'] as String),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${item['title']} kommer næste trin.')),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class ContactTab extends StatefulWidget {
  const ContactTab({super.key});

  @override
  State<ContactTab> createState() => _ContactTabState();
}

class _ContactTabState extends State<ContactTab> {
  bool loading = true;
  String error = '';
  String email = '';
  String address = '';
  String phone = '';

  @override
  void initState() {
    super.initState();
    fetchContact();
  }

  Future<void> fetchContact() async {
    try {
      final data = await ApiHelper.getJson(contactEndpoint);

      if (!mounted) return;

      if (data['success'] == true) {
        final contact = data['data'] as Map<String, dynamic>? ?? {};
        setState(() {
          email = contact['email']?.toString() ?? '';
          address = contact['address']?.toString() ?? '';
          phone = contact['phone']?.toString() ?? '';
          loading = false;
        });
      } else {
        setState(() {
          error =
              data['message']?.toString() ?? 'Kunne ikke hente kontaktinfo';
          loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = 'Netværksfejl: $e';
        loading = false;
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
                    color: AppColors.blueText2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? 'Ikke angivet' : value,
                  style: const TextStyle(color: Colors.white70),
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
      return const Center(child: CircularProgressIndicator());
    }

    if (error.isNotEmpty) {
      return Center(child: Text(error));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        infoCard(icon: Icons.email, title: 'E-mail', value: email),
        const SizedBox(height: 12),
        infoCard(icon: Icons.location_on, title: 'Adresse', value: address),
        const SizedBox(height: 12),
        infoCard(icon: Icons.phone, title: 'Telefon', value: phone),
      ],
    );
  }
}

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  bool loading = true;
  String error = '';
  String name = '';
  String email = '';
  String login = '';
  String membershipStatus = '';
  String membershipType = '';
  String validUntil = '';

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    try {
      final results = await Future.wait([
        ApiHelper.getJson(meEndpoint, authRequired: true),
        ApiHelper.getJson(membershipEndpoint, authRequired: true),
      ]);

      final data = results[0];
      final membership = results[1];

      if (!mounted) return;

      if (data['success'] == true) {
        final user = data['data'] as Map<String, dynamic>? ?? {};
        final membershipData = membership['data'] as Map<String, dynamic>? ?? {};

        setState(() {
          name = user['name']?.toString() ?? '';
          email = user['email']?.toString() ?? '';
          login = user['login']?.toString() ?? '';
          membershipStatus = membershipData['status']?.toString() ?? '';
          membershipType = membershipData['type']?.toString() ?? '';
          validUntil = membershipData['valid_until']?.toString() ?? '';
          loading = false;
        });
      } else {
        setState(() {
          error = data['message']?.toString() ?? 'Kunne ikke hente profil';
          loading = false;
        });
      }
    } on SessionExpiredException catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.message;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = 'Netværksfejl: $e';
        loading = false;
      });
    }
  }

  Widget _titleBar(String title) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: AppColors.blueText2,
          ),
        ),
      ],
    );
  }

  Widget _primaryButton(String title, VoidCallback onTap) {
    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.gold,
        foregroundColor: const Color(0xFF1B1408),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }

  Widget _secondaryButton(String title, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.text,
        side: const BorderSide(color: Color(0x26FFFFFF)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _statusCard() {
    return GlassPanel(
      padding: const EdgeInsets.all(16),
      radius: 14,
      child: DefaultTextStyle(
        style: const TextStyle(color: Color(0xFFFBF7F0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _profileStatusRow('Status', membershipStatus.isEmpty ? 'Ukendt' : membershipStatus),
            const SizedBox(height: 8),
            _profileStatusRow('Type', membershipType.isEmpty ? 'Ikke angivet' : membershipType),
            const SizedBox(height: 8),
            _profileStatusRow('Gyldig til', validUntil.isEmpty ? 'Ikke angivet' : validUntil),
          ],
        ),
      ),
    );
  }

  Widget _profileStatusRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            '$label:',
            style: const TextStyle(
              color: Color(0xFFFBF7F0),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Color(0xFFFBF7F0)),
          ),
        ),
      ],
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return GlassPanel(
      padding: const EdgeInsets.all(16),
      radius: 18,
      child: Row(
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
                    color: AppColors.blueText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error.isNotEmpty) {
      return Center(child: Text(error));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _titleBar('Moj račun'),
              const SizedBox(height: 12),
              const Text(
                'Pogledaj status članstva, uplati godine koje nedostaju i upravljaj svojim računom.',
                style: TextStyle(
                  color: Color(0xFFE7DFD2),
                  fontSize: 16,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 18),
              _statusCard(),
              const SizedBox(height: 20),
              const Text(
                'Profil',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.blueText2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Uredi profil i kontakt podatke ili promijeni lozinku.',
                style: TextStyle(
                  color: Color(0xFFE7DFD2),
                  fontSize: 16,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _primaryButton('Uredi profil', () {
                    _showComingSoon('Redigering af profil kobles næste trin.');
                  }),
                  _secondaryButton('Zaboravili ste lozinku?', () {
                    _showComingSoon('Glemt adgangskode kobles næste trin.');
                  }),
                  _secondaryButton('Odjavi se', () async {
                    try {
                      await PushService.unregisterCurrentDeviceToken();
                      await ApiHelper.postJson(
                        logoutEndpoint,
                        authRequired: true,
                        body: const {},
                      );
                    } catch (_) {
                    } finally {
                      await AuthService.clearToken();
                      if (!mounted) return;
                      SessionScope.of(context).value++;
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (_) => false,
                      );
                    }
                  }),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _infoTile(
          icon: Icons.person,
          title: 'Navn',
          value: name.isEmpty ? 'Ikke angivet' : name,
        ),
        const SizedBox(height: 12),
        _infoTile(
          icon: Icons.alternate_email,
          title: 'Brugernavn',
          value: login.isEmpty ? 'Ikke angivet' : login,
        ),
        const SizedBox(height: 12),
        _infoTile(
          icon: Icons.email,
          title: 'E-mail',
          value: email.isEmpty ? 'Ikke angivet' : email,
        ),
      ],
    );
  }
}