import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../main.dart';
import '../providers/auth_provider.dart';

const _emojis = [
  '🦊',
  '🐺',
  '🦁',
  '🐯',
  '🐻',
  '🦝',
  '🐸',
  '🦄',
  '🐲',
  '👾',
  '🤖',
  '👻',
  '💀',
  '🎭',
  '🔥',
  '⚡',
  '🌊',
  '🌪️',
  '🎯',
  '💣',
  '🧨',
  '🕶️',
  '🗿',
  '🛸',
];

const _avatarColors = [
  Color(0xFFFF3C5F),
  Color(0xFF7C4DFF),
  Color(0xFF00B4D8),
  Color(0xFFFFD60A),
  Color(0xFF00E676),
  Color(0xFFFF9800),
];

const _avatarColorHex = [
  '#FF3C5F',
  '#7C4DFF',
  '#00B4D8',
  '#FFD60A',
  '#00E676',
  '#FF9800',
];

class AvatarPickerScreen extends ConsumerStatefulWidget {
  const AvatarPickerScreen({super.key});

  @override
  ConsumerState<AvatarPickerScreen> createState() => _AvatarPickerScreenState();
}

class _AvatarPickerScreenState extends ConsumerState<AvatarPickerScreen> {
  String _selectedEmoji = '🦊';
  int _selectedColorIndex = 0;
  bool _saving = false;

  Color get _selectedColor => _avatarColors[_selectedColorIndex];
  String get _selectedColorHex => _avatarColorHex[_selectedColorIndex];

  Future<void> _saveProfile(String username) async {
    setState(() => _saving = true);
    try {
      final supabase = ref.read(supabaseProvider);
      final user = supabase.auth.currentUser;
      if (user == null) return;

      await supabase.from('profiles').upsert({
        'id': user.id,
        'username': username,
        'avatar_emoji': _selectedEmoji,
        'avatar_color': _selectedColorHex,
        'is_onboarded': true,
      });

      // Tell the traffic cop — profile saved, update state → router redirects
      await ref.read(authNotifierProvider).profileSaved();
    } catch (e) {
      if (mounted) {
        final error = e.toString();
        final msg = error.contains('duplicate') && error.contains('username')
            ? 'That username was just taken. Go back and pick another.'
            : 'Failed to save profile. Try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.error),
        );
        if (error.contains('duplicate') && error.contains('username')) {
          if (mounted) context.go('/username-picker');
        }
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final username = GoRouterState.of(context).extra as String? ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Gap(24),
              Text('Pick your\nvibe', style: AppTextStyles.displayMedium),
              const Gap(8),
              Text('This is how people see you.',
                  style: AppTextStyles.bodyMedium),
              const Gap(24),
              Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: _selectedColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: _selectedColor, width: 3),
                  ),
                  child: Center(
                    child: Text(_selectedEmoji,
                        style: const TextStyle(fontSize: 42)),
                  ),
                ),
              ),
              const Gap(6),
              Center(
                child: Text('@$username',
                    style: AppTextStyles.username
                        .copyWith(color: AppColors.textSecondary)),
              ),
              const Gap(24),
              Text('Choose emoji', style: AppTextStyles.labelLarge),
              const Gap(10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _emojis.length,
                itemBuilder: (context, i) {
                  final emoji = _emojis[i];
                  final isSelected = _selectedEmoji == emoji;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedEmoji = emoji),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryGlow
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              isSelected ? AppColors.primary : AppColors.border,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child:
                            Text(emoji, style: const TextStyle(fontSize: 24)),
                      ),
                    ),
                  );
                },
              ),
              const Gap(20),
              Text('Choose color', style: AppTextStyles.labelLarge),
              const Gap(12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(_avatarColors.length, (i) {
                  final color = _avatarColors[i];
                  final isSelected = _selectedColorIndex == i;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColorIndex = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check_rounded,
                              color: Colors.white, size: 18)
                          : null,
                    ),
                  );
                }),
              ),
              const Gap(32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saving ? null : () => _saveProfile(username),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text("Let's Yapp 🔥",
                          style: AppTextStyles.labelLarge
                              .copyWith(color: Colors.white)),
                ),
              ),
              const Gap(16),
            ],
          ),
        ),
      ),
    );
  }
}
