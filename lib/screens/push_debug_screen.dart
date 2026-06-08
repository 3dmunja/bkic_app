import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../services/push_service.dart';

class PushDebugScreen extends StatefulWidget {
  const PushDebugScreen({super.key});

  @override
  State<PushDebugScreen> createState() => _PushDebugScreenState();
}

class _PushDebugScreenState extends State<PushDebugScreen> {
  String permission = 'Loading...';
  String apnsToken = 'Loading...';
  String fcmToken = 'Loading...';
  String savedToken = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadDebugInfo();
  }

  Future<void> _loadDebugInfo() async {
    try {
      final settings = await FirebaseMessaging.instance
          .getNotificationSettings()
          .timeout(const Duration(seconds: 5));

      final apns = await FirebaseMessaging.instance
          .getAPNSToken()
          .timeout(const Duration(seconds: 5), onTimeout: () => 'TIMEOUT');

      final fcm = await FirebaseMessaging.instance
          .getToken()
          .timeout(const Duration(seconds: 8), onTimeout: () => 'TIMEOUT');

      final saved = await PushService.getSavedDeviceToken()
          .timeout(const Duration(seconds: 5), onTimeout: () => 'TIMEOUT');

      setState(() {
        permission = settings.authorizationStatus.name;
        apnsToken = apns ?? 'NULL';
        fcmToken = fcm ?? 'NULL';
        savedToken = saved ?? 'NULL';
      });
    } catch (e) {
      setState(() {
        permission = 'ERROR: $e';
        apnsToken = 'ERROR';
        fcmToken = 'ERROR';
        savedToken = 'ERROR';
      });
    }
  }

  Future<void> _registerAgain() async {
    await PushService.registerCurrentDeviceToken(force: true);
    await _loadDebugInfo();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token registration tried again')),
      );
    }
  }

  Widget _box(String title, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111820),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x33FFFFFF)),
      ),
      child: SelectableText(
        '$title:\n$value',
        style: const TextStyle(color: Colors.white, fontSize: 13),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07110F),
      appBar: AppBar(
        title: const Text('Push Debug'),
        backgroundColor: const Color(0xFF07110F),
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _loadDebugInfo,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _box('Permission', permission),
            _box('APNS Token', apnsToken),
            _box('FCM Token', fcmToken),
            _box('Saved Token', savedToken),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: _registerAgain,
              child: const Text('Register token again'),
            ),
          ],
        ),
      ),
    );
  }
}
