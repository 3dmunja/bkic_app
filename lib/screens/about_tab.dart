import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

import '../core/constants.dart';
import '../services/api_helper.dart';

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
          error = data['message']?.toString() ?? 'Nije moguće učitati stranicu';
          loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = 'Greška mreže: $e';
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