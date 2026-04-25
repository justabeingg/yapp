import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Notifications', style: AppTextStyles.headlineLarge)),
      body: const Center(
        child: Text('Notifications coming soon 🔔',
            style: TextStyle(color: AppColors.textSecondary)),
      ),
    );
  }
}
