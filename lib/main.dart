import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'core/session_scope.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'services/push_service.dart';
import 'theme/app_theme.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Stripe publishable key
  // Skift denne til din rigtige Stripe Publishable Key fra Stripe Dashboard
  Stripe.publishableKey =
      'pk_test_51T0VnMGiG2etFJzHJlWO3u7fRkc1zoGqO6wnyFuewqTF6mSUy3nUeOtJi4saJewb1GqGWQnMQHyzNJMyVEIL28W400lZmtQ78H';

  await Stripe.instance.applySettings();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await PushService.init();

  runApp(const MyApp());
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
        debugShowCheckedModeBanner: false,
        title: 'BKIC SAFF',
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}