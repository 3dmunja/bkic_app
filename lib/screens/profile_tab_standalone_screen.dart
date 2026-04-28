import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import 'profile_tab.dart';

class ProfileTabStandaloneScreen extends StatelessWidget {
  const ProfileTabStandaloneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Moj račun'),
        backgroundColor: AppColors.background,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: const ProfileTab(),
    );
  }
}