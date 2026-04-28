import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../core/app_colors.dart';

class ForgotPasswordWebViewScreen extends StatefulWidget {
  const ForgotPasswordWebViewScreen({super.key});

  @override
  State<ForgotPasswordWebViewScreen> createState() =>
      _ForgotPasswordWebViewScreenState();
}

class _ForgotPasswordWebViewScreenState
    extends State<ForgotPasswordWebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;

  static const String forgotPasswordUrl =
      'https://bkicsaff.dk/lost-password/';

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
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
      ..loadRequest(Uri.parse(forgotPasswordUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Zaboravljena lozinka'),
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