import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../providers/auth_provider.dart';

final _usernamesProvider = FutureProvider<List<String>>((ref) async {
  final supabase = ref.watch(supabaseProvider);
  final response = await supabase.rpc('get_random_usernames');
  return List<String>.from(response as List);
});

class UsernamePickerScreen extends ConsumerStatefulWidget {
  const UsernamePickerScreen({super.key});

  @override
  ConsumerState<UsernamePickerScreen> createState() =>
      _UsernamePickerScreenState();
}

class _UsernamePickerScreenState extends ConsumerState<UsernamePickerScreen> {
  String? _selected;
  bool _checking = false;

  Future<void> _onContinue() async {
    if (_selected == null) return;
    setState(() => _checking = true);

    try {
      final supabase = ref.read(supabaseProvider);

      // Check if username is still available right now
      final existing = await supabase
          .from('profiles')
          .select('id')
          .eq('username', _selected!)
          .maybeSingle();

      if (existing != null) {
        // Username was taken — refresh list and notify user
        if (mounted) {
          setState(() => _selected = null);
          ref.invalidate(_usernamesProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('That name was just taken. Here are new ones!'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      // Username is still available — proceed
      if (mounted) context.go('/avatar-picker', extra: _selected);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong. Try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final usernamesAsync = ref.watch(_usernamesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Gap(24),
              Text('Pick your\nYapp name',
                  style: AppTextStyles.displayMedium),
              const Gap(8),
              Text("Anonymous. No one knows it's you.",
                  style: AppTextStyles.bodyMedium),
              const Gap(48),

              usernamesAsync.when(
                loading: () => const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary, strokeWidth: 2),
                  ),
                ),
                error: (e, _) => Expanded(
                  child: Center(
                    child: Text('Failed to load names',
                        style: AppTextStyles.bodyMedium),
                  ),
                ),
                data: (usernames) => Expanded(
                  child: Column(
                    children: [
                      ...usernames.map((name) => _UsernameCard(
                            username: name,
                            isSelected: _selected == name,
                            onTap: () => setState(() => _selected = name),
                          )),
                      const Gap(16),
                      TextButton.icon(
                        onPressed: () {
                          setState(() => _selected = null);
                          ref.invalidate(_usernamesProvider);
                        },
                        icon: const Icon(Icons.shuffle_rounded,
                            color: AppColors.textSecondary, size: 18),
                        label: Text('Shuffle names',
                            style: AppTextStyles.bodyMedium),
                      ),
                    ],
                  ),
                ),
              ),

              const Gap(16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: (_selected == null || _checking)
                      ? null
                      : _onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.border,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _checking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text('Continue →',
                          style: AppTextStyles.labelLarge
                              .copyWith(color: Colors.white)),
                ),
              ),
              const Gap(8),
            ],
          ),
        ),
      ),
    );
  }
}

class _UsernameCard extends StatelessWidget {
  final String username;
  final bool isSelected;
  final VoidCallback onTap;

  const _UsernameCard({
    required this.username,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGlow : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text('@', style: AppTextStyles.bodyMedium),
            Text(username, style: AppTextStyles.headlineMedium),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 22),
          ],
        ),
      ),
    );
  }
}
