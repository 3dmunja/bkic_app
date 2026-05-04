import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CheckoutWebViewScreen extends StatefulWidget {
  final String url;
  final String title;

  const CheckoutWebViewScreen({
    super.key,
    required this.url,
    this.title = 'Plaćanje članarine',
  });

  @override
  State<CheckoutWebViewScreen> createState() => _CheckoutWebViewScreenState();
}

class _CheckoutWebViewScreenState extends State<CheckoutWebViewScreen> {
  late final WebViewController controller;
  bool loading = true;
  bool paymentDetected = false;
  bool cancelDetected = false;
  String currentUrl = '';

  @override
  void initState() {
    super.initState();

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final url = request.url;
            final normalized = url.toLowerCase();

            debugPrint('NAV URL: $url');

            if (normalized.startsWith('bkicapp://payment-success')) {
              _paymentSuccess();
              return NavigationDecision.prevent;
            }

            if (normalized.startsWith('bkicapp://payment-cancel')) {
              _paymentCancel();
              return NavigationDecision.prevent;
            }

            if (_isSuccessUrl(normalized)) {
              _paymentSuccess();
              return NavigationDecision.navigate;
            }

            if (_isCancelUrl(normalized)) {
              _paymentCancel();
              return NavigationDecision.navigate;
            }

            return NavigationDecision.navigate;
          },
          onPageStarted: (url) {
            debugPrint('START URL: $url');

            currentUrl = url;
            _checkPaymentResult(url);

            if (mounted) {
              setState(() => loading = true);
            }
          },
          onPageFinished: (url) {
            debugPrint('FINISH URL: $url');

            currentUrl = url;
            _checkPaymentResult(url);

            if (mounted) {
              setState(() => loading = false);
            }
          },
          onWebResourceError: (_) {
            if (mounted) {
              setState(() => loading = false);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  bool _isSuccessUrl(String normalized) {
    return normalized.contains('order-received') ||
        normalized.contains('checkout/order-received') ||
        normalized.contains('kasse/order-received') ||
        normalized.contains('thank-you') ||
        normalized.contains('bkic_success=1') ||
        normalized.contains('payment-success') ||
        normalized.contains('wc_order_received');
  }

  bool _isCancelUrl(String normalized) {
    return normalized.startsWith('bkicapp://payment-cancel') ||
        normalized.contains('payment-cancel') ||
        normalized.contains('cancel_order') ||
        normalized.contains('payment_cancel') ||
        normalized.contains('cancelled');
  }

  void _paymentSuccess() {
    if (paymentDetected || cancelDetected) return;

    paymentDetected = true;

    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Plaćanje je završeno. Ažuriramo status članstva...'),
        ),
      );

      Navigator.pop(context, true);
    });
  }

  void _paymentCancel() {
    if (paymentDetected || cancelDetected) return;

    cancelDetected = true;

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      Navigator.pop(context, false);
    });
  }

  void _checkPaymentResult(String url) {
    final normalized = url.toLowerCase();

    if (normalized.startsWith('bkicapp://payment-success') ||
        _isSuccessUrl(normalized)) {
      _paymentSuccess();
      return;
    }

    if (_isCancelUrl(normalized)) {
      _paymentCancel();
    }
  }

  Future<void> _reload() async {
    if (!mounted) return;

    setState(() => loading = true);
    await controller.reload();
  }

  Future<void> _goBack() async {
    if (paymentDetected) {
      Navigator.pop(context, true);
      return;
    }

    if (cancelDetected) {
      Navigator.pop(context, false);
      return;
    }

    if (await controller.canGoBack()) {
      await controller.goBack();
      return;
    }

    if (!mounted) return;
    Navigator.pop(context, false);
  }

  Future<void> _close() async {
    Navigator.pop(context, paymentDetected);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070604),
      appBar: AppBar(
        backgroundColor: const Color(0xFF11151C),
        foregroundColor: Colors.white,
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBack,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reload,
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _close,
          ),
        ],
      ),
      body: Column(
        children: [
          if (loading) const LinearProgressIndicator(),
          Expanded(
            child: WebViewWidget(controller: controller),
          ),
        ],
      ),
    );
  }
}