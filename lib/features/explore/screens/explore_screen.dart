import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Explore', style: AppTextStyles.headlineLarge)),
      body: const Center(
        child: Text('Explore coming soon 🔍',
            style: TextStyle(color: AppColors.textSecondary)),
      ),
    );
  }
}
